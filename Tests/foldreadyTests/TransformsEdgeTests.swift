import Testing
import Foundation
@testable import foldready

private func fixture(_ files: [String: String]) -> String {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-edge-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for (name, content) in files {
        let target = dir.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? content.write(to: target, atomically: true, encoding: .utf8)
    }
    return dir.path
}

private func read(_ root: String, _ path: String) throws -> String {
    try String(contentsOfFile: (root as NSString).appendingPathComponent(path), encoding: .utf8)
}

private func run(_ root: String, apply: Bool = false, tiers: [TransformTier] = [.safe, .review, .manual]) -> PortResult {
    PortEngine.run(root: root, appName: "T", options: PortOptions(tiers: tiers, apply: apply, outDir: nil))
}

@Suite("Transforms edge cases")
struct TransformsEdgeTests {

    @Test("root NavigationStack is wrapped; a nested one is not double-wrapped")
    func nestedStackSingleWrap() throws {
        let root = fixture([
            "Feed.swift": """
            import SwiftUI

            struct Feed: View {
                var body: some View {
                    NavigationStack {
                        NavigationStack {
                            List(1...3, id: \\.self) { Text("A") }
                        }
                    }
                }
            }
            """,
        ])
        let res = run(root)
        let patch = res.plan.patches.first { $0.transformId == "adaptive-navigation" }
        #expect(patch != nil)
        let after = patch!.edits[0].after
        // exactly one split-view wrapper, and the inner stack is untouched
        #expect(after.components(separatedBy: "NavigationSplitView { ").count - 1 == 1)
        #expect(after.components(separatedBy: "NavigationStack {").count - 1 == 2)
    }

    @Test("TabView root is not wrapped")
    func tabViewNotWrapped() throws {
        let root = fixture([
            "Feed.swift": """
            import SwiftUI

            struct Feed: View {
                var body: some View {
                    TabView {
                        NavigationStack { List(1...5, id: \\.self) { Text("A") } }
                        .tabItem { Label("Feed", systemImage: "list") }
                    }
                }
            }
            """,
        ])
        let res = run(root)
        let patch = res.plan.patches.first { $0.transformId == "adaptive-navigation" }
        #expect(patch?.edits.isEmpty == true)
        #expect(patch?.notes.contains(where: { $0.contains("not a bare NavigationStack") }) == true)
    }

    @Test("braces inside strings and comments do not break matching")
    func bracesInCommentsAndStrings() throws {
        let root = fixture([
            "Feed.swift": """
            import SwiftUI

            struct Feed: View {
                // comment with a { brace and } brace
                var body: some View {
                    /* block { comment } */
                    NavigationStack {
                        List(1...3, id: \\.self) { n in
                            Text("brace { inside string")
                        }
                        .navigationTitle("Feed }")
                    }
                }
            }
            """,
        ])
        let res = run(root)
        let patch = res.plan.patches.first { $0.transformId == "adaptive-navigation" }
        let after = patch?.edits.first?.after ?? ""
        #expect(after.contains("NavigationSplitView { NavigationStack {"))
        #expect(after.contains("} detail: { Color.clear }"))
        // the string content survives intact
        #expect(after.contains("brace { inside string"))
        #expect(after.contains("Feed }"))
    }

    @Test("only the first root stack per file is wrapped")
    func oneWrapPerFile() throws {
        let root = fixture([
            "Views.swift": """
            import SwiftUI

            struct One: View {
                var body: some View {
                    NavigationStack { List(1...2, id: \\.self) { Text("A") } }
                }
            }

            struct Two: View {
                var body: some View {
                    NavigationStack { List(1...2, id: \\.self) { Text("B") } }
                }
            }
            """,
        ])
        let res = run(root)
        let patch = res.plan.patches.first { $0.transformId == "adaptive-navigation" }
        #expect(patch?.edits.count == 1)
        #expect(patch?.notes.contains(where: { $0.contains("one wrap per file") }) == true)
    }

    @Test("sidebar insertion targets the right class in a multi-class file")
    func sidebarScopedInsertion() throws {
        let root = fixture([
            "App.swift": """
            import UIKit

            class Other: UIViewController {
                override func viewDidLoad() {
                    super.viewDidLoad()
                }
            }

            class Root: UITabBarController {
                override func viewDidLoad() {
                    super.viewDidLoad()
                }
            }
            """,
        ])
        let res = run(root, apply: true, tiers: [.safe])
        let content = try read(root, "App.swift")
        #expect(content.contains("mode = .tabSidebar"))
        // insertion must be inside Root, after Other's viewDidLoad
        #expect(content.range(of: "mode = .tabSidebar")!.lowerBound > content.range(of: "class Root")!.lowerBound)
        #expect(content.range(of: "class Other")!.lowerBound < content.range(of: "class Root")!.lowerBound)
    }

    @Test("deployment target below iOS 26 wraps the sidebar opt-in in #available")
    func availabilityGuard() throws {
        let root = fixture([
            "project.pbxproj": """
            // !$*UTF8*$!
            {
                IPHONEOS_DEPLOYMENT_TARGET = 15.0;
            }
            """,
            "Root.swift": """
            import UIKit
            class Root: UITabBarController {
                override func viewDidLoad() { super.viewDidLoad() }
            }
            """,
        ])
        let res = run(root, apply: true, tiers: [.safe])
        let content = try read(root, "Root.swift")
        #expect(content.contains("if #available(iOS 26.0, *)"))
    }

    @Test("deployment target 26+ inserts the sidebar opt-in plainly")
    func noAvailabilityGuardOn26() throws {
        let root = fixture([
            "project.pbxproj": """
            { IPHONEOS_DEPLOYMENT_TARGET = 26.0; }
            """,
            "Root.swift": """
            import UIKit
            class Root: UITabBarController {
                override func viewDidLoad() { super.viewDidLoad() }
            }
            """,
        ])
        let res = run(root, apply: true, tiers: [.safe])
        let content = try read(root, "Root.swift")
        #expect(content.contains("mode = .tabSidebar"))
        #expect(!content.contains("#available(iOS 26.0"))
    }

    @Test("UIRequiresFullScreen removed across plist variants")
    func plistVariants() throws {
        let root = fixture([
            "Info.plist": """
            <plist version="1.0"><dict><key>UIRequiresFullScreen</key><true/></dict></plist>
            """,
            "Config/Other.plist": """
            <plist version="1.0">
            <dict>
            \t<key>UIRequiresFullScreen</key>
            \t<false/>
            </dict>
            </plist>
            """,
            "Third.plist": """
            <plist version="1.0"><dict>
            <key>UIRequiresFullScreen</key><string>YES</string>
            </dict></plist>
            """,
        ])
        let res = run(root, apply: true, tiers: [.safe])
        for p in ["Info.plist", "Config/Other.plist", "Third.plist"] {
            let content = try read(root, p)
            #expect(!content.contains("UIRequiresFullScreen"), "still present in \(p)")
        }
    }

    @Test("UIScreen.main.bounds.size frame is replaced")
    func sizeVariantReplaced() throws {
        let root = fixture([
            "View.swift": """
            import SwiftUI
            struct V: View {
                var body: some View {
                    Rectangle().frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
                }
            }
            """,
        ])
        let res = run(root, apply: true, tiers: [.review])
        let content = try read(root, "View.swift")
        #expect(content.contains(".frame(maxWidth: .infinity, maxHeight: .infinity)"))
        #expect(!content.contains("UIScreen.main.bounds.size"))
    }

    @Test("two transforms editing the same file compose in one apply pass")
    func composedPerFileApply() throws {
        let root = fixture([
            "Root.swift": """
            import UIKit

            class Root: UITabBarController {
                override func viewDidLoad() {
                    super.viewDidLoad()
                    let v = UIView().frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                }
            }
            """,
        ])
        let res = run(root, apply: true, tiers: [.safe, .review])
        #expect(res.appliedCount >= 2)
        let content = try read(root, "Root.swift")
        #expect(content.contains("mode = .tabSidebar"))
        #expect(content.contains("maxWidth: .infinity"))
    }
}

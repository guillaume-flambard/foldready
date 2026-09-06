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

private func run(_ root: String, apply: Bool = false) -> PortResult {
    PortEngine.run(root: root, appName: "T", options: PortOptions(apply: apply, outDir: nil))
}

@Suite("Transforms edge cases")
struct TransformsEdgeTests {

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
        let res = run(root, apply: true)
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
        let res = run(root, apply: true)
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
        let res = run(root, apply: true)
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
        let res = run(root, apply: true)
        for p in ["Info.plist", "Config/Other.plist", "Third.plist"] {
            let content = try read(root, p)
            #expect(!content.contains("UIRequiresFullScreen"), "still present in \(p)")
        }
    }

}

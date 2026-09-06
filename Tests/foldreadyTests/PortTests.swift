import Testing
import Foundation
@testable import foldready

private func makeFixture() -> String {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("fr-port-test-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

    let files: [String: String] = [
        "Info.plist": """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0">
        <dict>
        \t<key>CFBundleName</key>
        \t<string>PortMe</string>
        \t<key>UIRequiresFullScreen</key>
        \t<true/>
        </dict>
        </plist>
        """,
        "Root.swift": """
        import UIKit

        class Root: UITabBarController {
            override func viewDidLoad() {
                super.viewDidLoad()
            }
        }
        """,
        "Feed.swift": """
        import SwiftUI

        struct Feed: View {
            var body: some View {
                NavigationStack {
                    List(1...5, id: \\.self) { Text("\\($0)") }
                }
            }
        }
        """,
        "Legacy.swift": """
        import UIKit

        class Legacy: UIViewController {
            override func viewDidLayoutSubviews() {
                let s = UIScreen.main.bounds
                print(s)
            }
        }
        """,
        "AppDelegate.swift": """
        import UIKit

        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {
            var window: UIWindow?
            func application(_ app: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                window = UIWindow(frame: UIScreen.main.bounds)
                window?.rootViewController = Root()
                window?.makeKeyAndVisible()
                return true
            }
        }
        """,
    ]
    for (name, content) in files {
        try? content.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
    return dir.path
}

@Suite("PortEngine")
struct PortEngineTests {

    @Test("a dry run patches only what is provably safe")
    func dryRunPatchesOnlyProvable() {
        let root = makeFixture()
        let result = PortEngine.run(root: root, appName: "PortMe",
            options: PortOptions(apply: false, outDir: nil))
        let ids = result.plan.patches.map(\.transformId)
        #expect(ids.contains("remove-fullscreen"))
        #expect(ids.contains("sidebar-optin"))
        // Structural migrations are work orders now, never regex-generated patches.
        #expect(!ids.contains("adaptive-navigation"))
        #expect(!ids.contains("screen-bounds"))
        #expect(!ids.contains("scene-lifecycle"))
        #expect(result.appliedCount == 0)
        #expect(result.reportPath != nil)
    }

    @Test("the judgement-level work is handed over as a work order")
    func workOrderCoversTheRest() {
        let root = makeFixture()
        let result = PortEngine.run(root: root, appName: "PortMe",
            options: PortOptions(apply: false, outDir: nil))
        let ids = Set(result.workOrder.entries.map(\.id))
        #expect(ids.contains("scene-lifecycle"))
        #expect(ids.contains("adaptive-navigation"))
        for entry in result.workOrder.entries {
            #expect(entry.reference.hasPrefix("https://developer.apple.com/"))
            #expect(!entry.requiredEndState.isEmpty)
        }
        let markdown = result.workOrder.markdown()
        #expect(markdown.contains("xcrun agent skills export"))
        #expect(markdown.contains("Done when"))
    }

    @Test("apply writes the safe edits and touches nothing else")
    func applyWrites() throws {
        let root = makeFixture()
        let result = PortEngine.run(root: root, appName: "PortMe",
            options: PortOptions(apply: true, outDir: nil))
        #expect(result.appliedCount > 0)

        let plist = try String(contentsOfFile: (root as NSString).appendingPathComponent("Info.plist"), encoding: .utf8)
        #expect(!plist.contains("UIRequiresFullScreen"))

        let rootFile = try String(contentsOfFile: (root as NSString).appendingPathComponent("Root.swift"), encoding: .utf8)
        #expect(rootFile.contains("mode = .tabSidebar"))

        // No speculative rewrite of the SwiftUI navigation, and no placeholder delegate.
        let feed = try String(contentsOfFile: (root as NSString).appendingPathComponent("Feed.swift"), encoding: .utf8)
        #expect(!feed.contains("NavigationSplitView"))
        #expect(!FileManager.default.fileExists(atPath: (root as NSString).appendingPathComponent("SceneDelegate.swift")))
    }

    @Test("the score improves after applying the safe edits")
    func scoreImproves() throws {
        let root = makeFixture()
        let before = AuditEngine.run(root: root, appName: "PortMe")
        _ = PortEngine.run(root: root, appName: "PortMe", options: PortOptions(apply: true, outDir: nil))
        let after = AuditEngine.run(root: root, appName: "PortMe")
        #expect(after.totalScore > before.totalScore)
    }
}

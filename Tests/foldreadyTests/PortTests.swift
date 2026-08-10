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

    @Test("dry run produces patches for every triggered transform")
    func dryRunDetectsTransforms() {
        let root = makeFixture()
        let result = PortEngine.run(root: root, appName: "PortMe", options: PortOptions(tiers: [.safe, .review, .manual], apply: false, outDir: nil))
        let ids = result.plan.patches.map(\.transformId)
        #expect(ids.contains("remove-fullscreen"))
        #expect(ids.contains("sidebar-optin"))
        #expect(ids.contains("adaptive-navigation"))
        #expect(ids.contains("screen-bounds"))
        #expect(ids.contains("scene-lifecycle"))
        #expect(result.appliedCount == 0)
        #expect(result.reportPath != nil)
    }

    @Test("apply writes edits and new files to the tree")
    func applyWrites() throws {
        let root = makeFixture()
        let result = PortEngine.run(root: root, appName: "PortMe", options: PortOptions(tiers: [.safe, .review], apply: true, outDir: nil))
        #expect(result.appliedCount > 0)

        let plist = try String(contentsOfFile: (root as NSString).appendingPathComponent("Info.plist"), encoding: .utf8)
        #expect(!plist.contains("UIRequiresFullScreen"))

        let rootFile = try String(contentsOfFile: (root as NSString).appendingPathComponent("Root.swift"), encoding: .utf8)
        #expect(rootFile.contains("mode = .tabSidebar"))

        let feed = try String(contentsOfFile: (root as NSString).appendingPathComponent("Feed.swift"), encoding: .utf8)
        #expect(feed.contains("NavigationSplitView"))

        let sceneExists = FileManager.default.fileExists(atPath: (root as NSString).appendingPathComponent("SceneDelegate.swift"))
        #expect(sceneExists)
    }

    @Test("re-audit score improves after applying safe+review ports")
    func scoreImproves() throws {
        let root = makeFixture()
        let before = AuditEngine.run(root: root, appName: "PortMe")
        _ = PortEngine.run(root: root, appName: "PortMe", options: PortOptions(tiers: [.safe, .review], apply: true, outDir: nil))
        let after = AuditEngine.run(root: root, appName: "PortMe")
        #expect(after.totalScore > before.totalScore)
    }
}

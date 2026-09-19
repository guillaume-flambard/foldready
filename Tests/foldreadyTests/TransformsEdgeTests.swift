import Testing
import Foundation
@testable import foldready

private func fixture(_ files: [String: String]) -> String {
    let dir = TestTemporaryDirectory.make("edge")
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

    @Test("Default port preserves navigation at every deployment target", arguments: ["15.0", "26.0", "27.1"])
    func navigationIsOptional(target: String) throws {
        let source = "import UIKit\nclass Root: UITabBarController { override func viewDidLoad() { super.viewDidLoad() } }"
        let root = fixture(["Root.swift": source,
                            "project.pbxproj": "{ IPHONEOS_DEPLOYMENT_TARGET = \(target); }"])
        let result = run(root, apply: true)
        #expect(try read(root, "Root.swift") == source)
        #expect(!result.plan.patches.contains { $0.transformId == "sidebar-optin" })
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

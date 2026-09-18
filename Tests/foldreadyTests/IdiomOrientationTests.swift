import Testing
import Foundation
@testable import foldready

/// Writes a tree of files, creating intermediate directories, and returns its root path.
/// Copied from `DuoSurfaceTests.swift`, where the helpers are file-private.
private func writeTree(_ files: [String: String], in parent: URL) -> String {
    for (path, content) in files {
        let url = parent.appendingPathComponent(path)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
    return parent.path
}

private func tempTree() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-idiom-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Suite("Idiom and orientation")
struct IdiomOrientationTests {

    @Test func idiomBranchingIsItsOwnCheck() {
        let root = writeTree(["App/View.swift": """
        import UIKit
        let i = UIDevice.current.userInterfaceIdiom
        """], in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(result.findings.contains { $0.check == "idiom" })
        #expect(!result.findings.contains { $0.check == "adaptive-geometry"
            && $0.message.contains("idiom") })
    }

    @Test func portraitOnlyPlistIsReportedByTheOrientationCheck() {
        let root = writeTree(["App/Info.plist": """
        <key>UISupportedInterfaceOrientations</key>
        <array><string>UIInterfaceOrientationPortrait</string></array>
        """, "App/View.swift": "import SwiftUI\nstruct V: View { var body: some View { Text(\"x\") } }\n"],
            in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")
        let finding = result.findings.first { $0.check == "orientation" }
        #expect(finding?.file == "App/Info.plist")
    }

    @Test func aPortraitCapablePlistProducesNoOrientationFinding() {
        let root = writeTree(["App/Info.plist": """
        <key>UISupportedInterfaceOrientations</key>
        <array>
          <string>UIInterfaceOrientationPortrait</string>
          <string>UIInterfaceOrientationLandscapeLeft</string>
        </array>
        """, "App/View.swift": "import SwiftUI\nstruct V: View { var body: some View { Text(\"x\") } }\n"],
            in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(!result.findings.contains { $0.check == "orientation" })
    }

    @Test func aSourceOrientationBranchMakesTheCheckApplicableWithoutAPlist() {
        // Task 4 ruled: no plist but a source `interfaceOrientation` branch is an orientation
        // site, so the check applies and the branch is attributed to it.
        let root = writeTree(["App/View.swift": """
        import UIKit
        let o = windowScene.interfaceOrientation
        """], in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(result.outcomes.contains { $0.key == "orientation" },
            "a source orientation branch is an orientation site")
        #expect(result.findings.contains { $0.check == "orientation" && $0.file == "App/View.swift" })
    }
}

/// The navigation and state checks read whole-file tokens, so a preview block that holds a
/// `NavigationView` or a `List` must not reach them.
@Suite("Preview scoring")
struct PreviewScoringTests {

    @Test func aPreviewNavigationViewDoesNotLowerTheScore() {
        let root = writeTree(["App/View.swift": """
        import SwiftUI
        struct V: View { var body: some View { Text("x") } }
        #Preview {
            NavigationView { Text("preview") }
        }
        """], in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(!result.findings.contains { $0.check == "navigation" })
    }

    @Test func aPreviewedListAddsNoStateFinding() {
        let root = writeTree(["App/View.swift": """
        import SwiftUI
        struct V: View { var body: some View { Text("x") } }
        #Preview {
            List { Text("preview") }
        }
        """], in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(!result.findings.contains { $0.check == "state" })
    }
}

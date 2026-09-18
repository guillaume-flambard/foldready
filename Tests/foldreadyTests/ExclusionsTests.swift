import Testing
import Foundation
@testable import foldready

/// Writes a tree of files, creating intermediate directories, and returns its root path.
/// Copied from `IdiomOrientationTests.swift`, where the helpers are file-private.
private func writeTree(_ files: [String: String], in parent: String) -> String {
    let base = URL(fileURLWithPath: parent)
    for (path, content) in files {
        let url = base.appendingPathComponent(path)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
    return base.path
}

private func tempTree() -> String {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-exclusions-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url.path
}

@Suite("Exclusions")
struct ExclusionsTests {

    @Test func configIncludeForcesAFileBackIntoScope() {
        let root = tempTree()
        writeTree(["App/Generated.generated.swift":
            "import SwiftUI\nlet s = UIScreen.main.bounds\n"], in: root)
        let without = AuditEngine.run(root: root, appName: "App")
        #expect(!without.findings.contains { $0.file == "App/Generated.generated.swift" })

        var policy = GatePolicy.empty
        policy.include = ["App/Generated.generated.swift"]
        let with = AuditEngine.run(root: root, appName: "App", policy: policy)
        #expect(with.findings.contains { $0.file == "App/Generated.generated.swift" })
    }

    @Test func configExcludeDropsAShippingFile() {
        let root = tempTree()
        writeTree(["App/View.swift": "import SwiftUI\nlet s = UIScreen.main.bounds\n"], in: root)
        var policy = GatePolicy.empty
        policy.exclude = ["App/View.swift"]
        let result = AuditEngine.run(root: root, appName: "App", policy: policy)
        #expect(result.stats.exclusions.byConfig == 1)
    }

    @Test func policyAtTheRootIsReadWithoutAPassedPolicy() {
        let root = tempTree()
        writeTree([
            ".foldready.json": #"{ "exclude": ["App/View.swift"] }"#,
            "App/View.swift": "import SwiftUI\nlet s = UIScreen.main.bounds\n"
        ], in: root)
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(result.stats.exclusions.byConfig == 1)
    }
}

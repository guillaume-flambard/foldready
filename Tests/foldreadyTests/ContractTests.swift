import Testing
import Foundation
@testable import foldready

/// A small iOS-shaped tree written under `parent`, so the same sources can be audited
/// from two different checkout paths.
private func writeFixture(in parent: URL) -> String {
    let dir = parent.appendingPathComponent("DemoApp", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

    let files: [String: String] = [
        "Info.plist": """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0">
        <dict>
        \t<key>UIRequiresFullScreen</key>
        \t<true/>
        </dict>
        </plist>
        """,
        "Feed.swift": """
        import SwiftUI

        struct Feed: View {
            var body: some View {
                NavigationStack {
                    List(1...5, id: \\.self) { Text("\\($0)") }
                        .frame(width: 320, height: 480)
                }
            }
        }
        """,
        "Legacy.swift": """
        import UIKit

        final class Legacy: UIViewController {
            func layout() {
                let w = UIScreen.main.bounds.width
                _ = w
            }
        }
        """
    ]
    for (name, content) in files {
        try? content.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
    return dir.path
}

private func tempParent() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-contract-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Suite("Result contract")
struct ContractTests {

    @Test("The same tree audited from two checkout paths yields an identical payload")
    func pathIndependence() throws {
        let a = writeFixture(in: tempParent())
        let b = writeFixture(in: tempParent())
        #expect(a != b)

        let ra = AuditEngine.run(root: a, appName: "DemoApp")
        let rb = AuditEngine.run(root: b, appName: "DemoApp")

        let ja = try JSONSerialization.data(
            withJSONObject: JSONReport.comparablePayload(ra), options: [.sortedKeys])
        let jb = try JSONSerialization.data(
            withJSONObject: JSONReport.comparablePayload(rb), options: [.sortedKeys])
        #expect(ja == jb)
    }

    @Test("No finding leaks an absolute host path")
    func relativePaths() {
        let root = writeFixture(in: tempParent())
        let result = AuditEngine.run(root: root, appName: "DemoApp")
        for finding in result.findings {
            guard let file = finding.file else { continue }
            #expect(!file.hasPrefix("/"))
            #expect(!file.contains(root))
        }
        let rendered = JSONReport.render(result)
        #expect(!rendered.contains(root))
    }

    @Test("Repeated audits produce the same ordering")
    func deterministicOrdering() {
        let root = writeFixture(in: tempParent())
        let first = AuditEngine.run(root: root, appName: "DemoApp").findings
        let second = AuditEngine.run(root: root, appName: "DemoApp").findings
        #expect(first.count == second.count)
        for (a, b) in zip(first, second) {
            #expect(a.check == b.check)
            #expect(a.severity == b.severity)
            #expect(a.file == b.file)
            #expect(a.line == b.line)
            #expect(a.message == b.message)
        }
    }

    @Test("The payload carries the schema version and stable check identity")
    func schemaShape() throws {
        let root = writeFixture(in: tempParent())
        let payload = JSONReport.payload(AuditEngine.run(root: root, appName: "DemoApp"))
        #expect(payload["schema_version"] as? Int == resultSchemaVersion)
        #expect(payload["foldready_version"] as? String == foldreadyVersion)

        let checks = try #require(payload["checks"] as? [[String: Any]])
        let keys = checks.compactMap { $0["key"] as? String }
        #expect(Set(keys).count == keys.count, "check keys must be unique")
        #expect(keys.contains("adaptive-layout"))
        for check in checks {
            let reference = check["reference"] as? String ?? ""
            #expect(reference.hasPrefix("https://developer.apple.com/"),
                    "every scored check cites an Apple source")
        }
    }

    @Test("Weights sum to 1 with and without the visual check")
    func weightsSumToOne() {
        let root = writeFixture(in: tempParent())
        let sum = AuditEngine.run(root: root, appName: "DemoApp")
            .outcomes.reduce(0.0) { $0 + $1.weight }
        #expect(abs(sum - 1.0) < 0.0001)
    }

    @Test("Weights serialise without binary float noise")
    func weightSerialisation() {
        let root = writeFixture(in: tempParent())
        let rendered = JSONReport.render(AuditEngine.run(root: root, appName: "DemoApp"))
        #expect(!rendered.contains("0.3500000000000000"))
        #expect(rendered.contains("\"weight\" : 0.35"))
    }
}

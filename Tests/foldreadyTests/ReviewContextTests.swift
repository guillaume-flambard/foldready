import Foundation
import Testing
@testable import foldready

@Suite("Human review boundaries")
struct ReviewContextTests {
    private func result(with findings: [Finding] = []) -> AuditResult {
        AuditResult(root: "/private/source", appName: "<Example>", generatedAt: Date(),
            totalScore: 100, outcomes: [], findings: findings, blockers: [],
            stats: AuditStats(swiftFiles: 2, uiFiles: 1, excludedFiles: 1,
                swiftuiFiles: 1, uikitFiles: 0, xibOrStoryboard: 0, infoPlists: 0,
                failedFiles: 1), hoursEstimate: 0)
    }

    @Test("A perfect source score and no findings do not establish reviewed or tested status")
    func emptyDoesNotMeanPassed() throws {
        let audit = result()
        let payload = JSONReport.payload(audit)
        let review = try #require(payload["review"] as? [String: Any])
        #expect(review["status"] as? String == "awaiting_human_review")
        #expect(review["effort_status"] as? String == "unvalidated_estimate")
        let checks = try #require(review["runtime_checks"] as? [[String: String]])
        #expect(!checks.isEmpty)
        #expect(checks.allSatisfy { $0["status"] == "not_tested" })
        let html = HTMLReport.render(audit)
        #expect(html.contains("Runtime validation: not tested"))
        #expect(html.contains("1 unreadable"))
        #expect(html.contains("contract v5"))
        #expect(html.contains("Unvalidated heuristic hours"))
        #expect(html.contains("&lt;Example&gt;"))
        #expect(!html.contains(audit.root))
    }

    @Test("Even high confidence screenshot signals retain unknown priority and cause")
    func screenshotIsNotRuntimeProof() throws {
        let finding = Finding(check: "captured-layout", severity: .major,
            message: "<margin>", file: "capture.png", line: nil, confidence: .high)
        let audit = result(with: [finding])
        let rows = try #require(JSONReport.payload(audit)["findings"] as? [[String: Any]])
        let row = try #require(rows.first)
        #expect(row["evidence_kind"] as? String == "screenshot_signal")
        let review = try #require(row["review"] as? [String: Any])
        #expect(review["human_priority"] is NSNull)
        #expect(review["runtime_status"] as? String == "not_tested")
        #expect((review["next_step"] as? String)?.contains("image provenance") == true)
        #expect(review["check_evidence"] == nil, "Missing check evidence must not be invented")
        #expect(HTMLReport.render(audit).contains("&lt;margin&gt;"))
    }

    @Test("Finding evidence reuses the check and preserves location and confidence")
    func existingEvidence() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Fixtures/ContractApp").path
        let audit = AuditEngine.run(root: root, appName: "ContractApp")
        #expect(!audit.findings.isEmpty)
        for finding in audit.findings {
            let context = ReviewContext.finding(finding, in: audit)
            if let outcome = audit.outcomes.first(where: { $0.key == finding.check }) {
                #expect(context["check_evidence"] as? String == outcome.detail)
                #expect(context["reference"] as? String == outcome.reference)
            }
            #expect(!(context["next_step"] as? String ?? "").isEmpty)
        }
    }

    @Test("Work order loading retains incompatible or missing versions for comparison guard")
    func workOrderVersion() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        for version in ["\"schema_version\":4,", ""] {
            try "{\(version)\"app\":\"Example\",\"score\":100,\"entries\":[]}"
                .write(to: url, atomically: true, encoding: .utf8)
            let order = try #require(WorkOrder.load(path: url.path))
            #expect(order.schemaVersion != resultSchemaVersion)
        }
    }
}

import Testing
import Foundation
@testable import foldready

private func tempDir() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-gate-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// A result with the given total and per-check scores, built without touching the disk.
private func result(total: Double, checks: [(String, Double)],
                    blockers: [Blocker] = []) -> AuditResult {
    let outcomes = checks.map { key, score in
        CheckOutcome(key: key, title: key, weight: 1.0 / Double(checks.count),
            score: score / 100, detail: "", signals: [:], reference: Reference.modernizeUIKit,
            findings: [Finding(check: key, severity: .major, message: "\(key) finding",
                file: "Sources/\(key).swift", line: 3)])
    }
    return AuditResult(root: "/tmp/app", appName: "App", generatedAt: Date(),
        totalScore: total, outcomes: outcomes,
        findings: Finding.deterministicOrder(outcomes.flatMap { $0.findings }),
        blockers: blockers,
        stats: AuditStats(swiftFiles: 3, uiFiles: 3, excludedFiles: 0, swiftuiFiles: 2,
            uikitFiles: 1, xibOrStoryboard: 0, infoPlists: 1),
        hoursEstimate: 4)
}

private let sceneBlocker = Blocker(id: Blockers.sceneLifecycleMissing,
    title: "No UIScene lifecycle", consequence: "does not launch",
    reference: Reference.sceneLifecycle, file: nil, stopsLaunch: true)

private func writePolicy(_ json: String, in dir: URL) -> String {
    let path = dir.appendingPathComponent(GatePolicy.defaultFileName).path
    try? json.write(toFile: path, atomically: true, encoding: .utf8)
    return path
}

@Suite("Gate policy")
struct GateTests {

    @Test("No configuration means no policy: the gate reports and passes")
    func noPolicy() throws {
        let dir = tempDir()
        let policy = try GatePolicy.load(path: dir.appendingPathComponent(GatePolicy.defaultFileName).path)
        #expect(policy == nil)

        let outcome = GateEngine.evaluate(result: result(total: 12, checks: [("scene", 0)]),
            baseline: nil, policy: .empty)
        #expect(outcome.exitCode == .pass)
        #expect(outcome.policyConfigured == false)
        #expect(outcome.rules.isEmpty)
    }

    @Test("Score floor passes and breaches")
    func floor() throws {
        let dir = tempDir()
        let path = writePolicy(#"{ "min_score": 60 }"#, in: dir)
        let policy = try #require(try GatePolicy.load(path: path))

        let pass = GateEngine.evaluate(result: result(total: 72, checks: [("scene", 100)]),
            baseline: nil, policy: policy)
        #expect(pass.exitCode == .pass)

        let fail = GateEngine.evaluate(result: result(total: 41, checks: [("scene", 20)]),
            baseline: nil, policy: policy)
        #expect(fail.exitCode == .breach)
        let breach = try #require(fail.breaches.first)
        #expect(breach.name == "score floor")
        #expect(breach.expected == ">= 60")
        #expect(breach.actual == "41")
        #expect(!breach.findings.isEmpty, "a breach names the findings responsible")
    }

    @Test("Total regression is measured against the committed baseline")
    func totalRegression() throws {
        let dir = tempDir()
        let baselinePath = dir.appendingPathComponent("baseline.json").path
        try Baseline.serialise(result(total: 70, checks: [("scene", 100), ("navigation", 40)]))
            .write(toFile: baselinePath, atomically: true, encoding: .utf8)
        let baseline = try #require(try Baseline.load(path: baselinePath))
        #expect(baseline.score == 70)
        #expect(baseline.checkScores["navigation"] == 40)

        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "max_total_regression": 0 }"#, in: dir)))

        let dropped = GateEngine.evaluate(
            result: result(total: 64, checks: [("scene", 100), ("navigation", 10)]),
            baseline: baseline, policy: policy)
        #expect(dropped.exitCode == .breach)
        #expect(dropped.breaches.first?.actual == "dropped 6")

        let held = GateEngine.evaluate(
            result: result(total: 71, checks: [("scene", 100), ("navigation", 45)]),
            baseline: baseline, policy: policy)
        #expect(held.exitCode == .pass)
    }

    @Test("A frozen check regresses even when the total holds")
    func perCheckRegression() throws {
        let dir = tempDir()
        let baselinePath = dir.appendingPathComponent("baseline.json").path
        try Baseline.serialise(result(total: 70, checks: [("scene", 100), ("navigation", 40)]))
            .write(toFile: baselinePath, atomically: true, encoding: .utf8)
        let baseline = try #require(try Baseline.load(path: baselinePath))

        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "no_regression_checks": ["scene"] }"#, in: dir)))

        // Same total, scene traded against navigation.
        let outcome = GateEngine.evaluate(
            result: result(total: 70, checks: [("scene", 60), ("navigation", 80)]),
            baseline: baseline, policy: policy)
        #expect(outcome.exitCode == .breach)
        #expect(outcome.breaches.first?.name == "check 'scene' no regression")
    }

    @Test("Regression rules are skipped, not failed, when no baseline exists")
    func missingBaseline() throws {
        let dir = tempDir()
        #expect(try Baseline.load(path: dir.appendingPathComponent("absent.json").path) == nil)

        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "max_total_regression": 0, "no_regression_checks": ["scene"] }"#, in: dir)))
        let outcome = GateEngine.evaluate(result: result(total: 55, checks: [("scene", 50)]),
            baseline: nil, policy: policy)
        #expect(outcome.exitCode == .pass)
        #expect(outcome.rules.allSatisfy { $0.skippedReason != nil })
    }

    @Test("A malformed baseline is an error, not a silent pass")
    func malformedBaseline() throws {
        let dir = tempDir()
        let path = dir.appendingPathComponent("baseline.json").path
        try "not json at all".write(toFile: path, atomically: true, encoding: .utf8)
        #expect(throws: Baseline.LoadError.self) { try Baseline.load(path: path) }
    }

    @Test("A malformed policy is an error, not a silent pass")
    func malformedPolicy() throws {
        let dir = tempDir()
        let path = writePolicy("{ oops", in: dir)
        #expect(throws: GatePolicy.LoadError.self) { try GatePolicy.load(path: path) }
    }

    @Test("Severity ceiling fails on findings at or above the configured level")
    func severityCeiling() throws {
        let dir = tempDir()
        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "max_severity": "major" }"#, in: dir)))
        let outcome = GateEngine.evaluate(result: result(total: 90, checks: [("scene", 90)]),
            baseline: nil, policy: policy)
        #expect(outcome.exitCode == .breach)
        #expect(outcome.breaches.first?.name == "severity ceiling")
    }

    @Test("An unknown check key in the policy is reported, not ignored")
    func unknownCheckKey() throws {
        let dir = tempDir()
        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "no_regression_checks": ["not-a-check"] }"#, in: dir)))
        let outcome = GateEngine.evaluate(result: result(total: 90, checks: [("scene", 90)]),
            baseline: nil, policy: policy)
        #expect(outcome.exitCode == .breach)
    }

    @Test("A baseline from another scoring version is not compared")
    func staleBaselineVersion() throws {
        let dir = tempDir()
        let path = dir.appendingPathComponent("baseline.json").path
        // A v1 baseline: same shape, previous scoring.
        try #"{ "schema_version": 1, "score": 70, "checks": [{"key": "navigation", "score": 40}] }"#
            .write(toFile: path, atomically: true, encoding: .utf8)
        let baseline = try #require(try Baseline.load(path: path))
        #expect(baseline.schemaVersion == 1)

        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "max_total_regression": 0, "no_regression_checks": ["navigation"] }"#, in: dir)))
        let outcome = GateEngine.evaluate(
            result: result(total: 40, checks: [("navigation", 0)]),
            baseline: baseline, policy: policy)

        #expect(outcome.exitCode == .pass, "a rebalance is not a regression")
        #expect(outcome.rules.allSatisfy { $0.skippedReason != nil })
        #expect(outcome.rules.contains { $0.skippedReason?.contains("--write-baseline") == true })
    }

    @Test("A blocker fails a policy that forbids blockers")
    func forbidBlockers() throws {
        let dir = tempDir()
        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "forbid_blockers": true }"#, in: dir)))
        let blocked = GateEngine.evaluate(
            result: result(total: 90, checks: [("navigation", 100)], blockers: [sceneBlocker]),
            baseline: nil, policy: policy)
        #expect(blocked.exitCode == .breach)
        #expect(blocked.breaches.first?.name == "no blockers")

        let clean = GateEngine.evaluate(
            result: result(total: 12, checks: [("navigation", 0)]),
            baseline: nil, policy: policy)
        #expect(clean.exitCode == .pass, "a low score is not a blocker")
    }

    @Test("Exit codes separate a failing app from a broken pipeline")
    func exitCodes() {
        #expect(GateExit.pass.rawValue == 0)
        #expect(GateExit.error.rawValue == 1)
        #expect(GateExit.breach.rawValue == 2)
    }
}

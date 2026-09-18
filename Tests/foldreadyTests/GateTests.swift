import Testing
import Foundation
@testable import foldready

private func tempDir() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-gate-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// Writes a tree of files, creating intermediate directories, and returns its root path.
/// Copied from `IdiomOrientationTests.swift`, where the helpers are file-private.
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
        .appendingPathComponent("fr-gate-tree-\(UUID().uuidString)", isDirectory: true)
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

    @Test("Findings below the configured confidence do not trip the severity ceiling")
    func minConfidenceIgnoresLowerConfidenceFindings() throws {
        // The idiom check emits a minor finding at medium confidence: a gate set to act on
        // high confidence only must ignore it, and say that it did.
        let root = writeTree(["App/View.swift":
            "import UIKit\nlet i = UIDevice.current.userInterfaceIdiom\n"], in: tempTree())
        var policy = GatePolicy.empty
        policy.maxSeverity = .minor
        policy.minConfidence = .high
        let result = AuditEngine.run(root: root, appName: "App", policy: policy)
        #expect(result.findings.contains { $0.check == "idiom" && $0.confidence == .medium })

        let outcome = GateEngine.evaluate(result: result, baseline: nil, policy: policy)
        #expect(outcome.exitCode == .pass)
        let ceiling = try #require(outcome.rules.first { $0.name == "severity ceiling" })
        #expect(ceiling.passed)
        #expect(ceiling.actual.contains("ignored 1 below high confidence"),
            "a gate that passed by ignoring a finding says so: \(ceiling.actual)")
    }

    @Test("An absent min_confidence still acts on every finding, whatever its confidence")
    func absentMinConfidenceActsOnEveryFinding() throws {
        // The same tree the confidence filter ignores: with no `min_confidence` the medium
        // finding trips the ceiling exactly as it did before confidence existed.
        let root = writeTree(["App/View.swift":
            "import UIKit\nlet i = UIDevice.current.userInterfaceIdiom\n"], in: tempTree())
        var policy = GatePolicy.empty
        policy.maxSeverity = .minor
        let result = AuditEngine.run(root: root, appName: "App", policy: policy)

        let outcome = GateEngine.evaluate(result: result, baseline: nil, policy: policy)
        #expect(outcome.exitCode == .breach)
        let ceiling = try #require(outcome.breaches.first { $0.name == "severity ceiling" })
        #expect(ceiling.findings.contains { $0.check == "idiom" })
        #expect(!ceiling.actual.contains("ignored"), "an unconfigured gate ignores nothing: \(ceiling.actual)")
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

        // The rebalance is not a regression, so the regression rules skip. The stale contract
        // is its own failing rule: a silent pass on an incomparable number is what the
        // `Score changes are declared` requirement forbids.
        #expect(outcome.exitCode == .breach)
        #expect(outcome.breaches.map(\.name) == ["baseline-contract"])
        #expect(outcome.breaches.first?.actual == "baseline schema_version 1")
        #expect(outcome.rules.filter { $0.name != "baseline-contract" }
            .allSatisfy { $0.skippedReason != nil })
        #expect(outcome.rules.contains { $0.skippedReason?.contains("--write-baseline") == true })
    }

    @Test("A baseline from a different contract is named, and a matching one passes")
    func baselineContract() throws {
        let dir = tempDir()
        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "max_total_regression": 0 }"#, in: dir)))

        // A v4 baseline against this v5 engine.
        let stalePath = dir.appendingPathComponent("stale.json").path
        try #"{ "schema_version": 4, "score": 70, "checks": [] }"#
            .write(toFile: stalePath, atomically: true, encoding: .utf8)
        let stale = try #require(try Baseline.load(path: stalePath))
        let failed = GateEngine.evaluate(result: result(total: 90, checks: [("navigation", 100)]),
            baseline: stale, policy: policy)
        let rule = try #require(failed.rules.first { $0.name == "baseline-contract" })
        #expect(!rule.passed)
        #expect(rule.expected == "baseline schema_version \(resultSchemaVersion)")
        #expect(rule.actual == "baseline schema_version 4")

        // A baseline written by this contract matches and passes.
        let matchPath = dir.appendingPathComponent("match.json").path
        try Baseline.serialise(result(total: 70, checks: [("navigation", 40)]))
            .write(toFile: matchPath, atomically: true, encoding: .utf8)
        let matching = try #require(try Baseline.load(path: matchPath))
        #expect(matching.schemaVersion == resultSchemaVersion)
        let passed = GateEngine.evaluate(result: result(total: 90, checks: [("navigation", 100)]),
            baseline: matching, policy: policy)
        #expect(passed.rules.first { $0.name == "baseline-contract" }?.passed == true)
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

    @Test("A forbid_blockers policy with a stale baseline does not breach on baseline-contract")
    func staleBaselineDoesNotFireWithoutRegressionPolicy() throws {
        let dir = tempDir()
        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "forbid_blockers": true }"#, in: dir)))

        // A v4 baseline against this v5 engine: real, but a policy that never compares
        // against it must not fail on it.
        let stalePath = dir.appendingPathComponent("stale.json").path
        try #"{ "schema_version": 4, "score": 70, "checks": [] }"#
            .write(toFile: stalePath, atomically: true, encoding: .utf8)
        let stale = try #require(try Baseline.load(path: stalePath))

        let outcome = GateEngine.evaluate(
            result: result(total: 90, checks: [("navigation", 100)]),
            baseline: stale, policy: policy)
        #expect(outcome.exitCode == .pass)
        #expect(!outcome.rules.contains { $0.name == "baseline-contract" })
    }

    @Test("A min_confidence-only policy is not empty, and gates on severity alone")
    func minConfidenceOnlyIsNotReportOnly() throws {
        let dir = tempDir()
        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "min_confidence": "high" }"#, in: dir)))
        #expect(!policy.isEmpty)
        #expect(policy.comparesAgainstBaseline == false)

        let outcome = GateEngine.evaluate(result: result(total: 90, checks: [("scene", 90)]),
            baseline: nil, policy: policy)
        #expect(outcome.policyConfigured)
    }

    @Test("The snake_case min_confidence file key decodes, and garbage fails loudly")
    func minConfidenceFileKey() throws {
        let dir = tempDir()
        // The real `.foldready.json` spelling: snake_case, as the loader converts it.
        let policy = try #require(try GatePolicy.load(
            path: writePolicy(#"{ "min_confidence": "high" }"#, in: dir)))
        #expect(policy.minConfidence == .high)

        // Typed as `Confidence?`, so a garbage value is a load error, not a silent fallback.
        let bad = writePolicy(#"{ "min_confidence": "HIGH" }"#, in: dir)
        #expect(throws: GatePolicy.LoadError.self) { try GatePolicy.load(path: bad) }
    }

    @Test("Exit codes separate a failing app from a broken pipeline")
    func exitCodes() {
        #expect(GateExit.pass.rawValue == 0)
        #expect(GateExit.error.rawValue == 1)
        #expect(GateExit.breach.rawValue == 2)
    }
}

import Foundation

/// Process exit codes for `foldready gate`.
///
/// CI cannot act on a single non-zero code: a failing app and a broken pipeline need
/// different responses, and conflating them trains teams to ignore the gate.
enum GateExit: Int32 {
    /// Policy satisfied, or no policy configured.
    case pass = 0
    /// The invocation itself failed: unreadable tree, malformed baseline or config.
    case error = 1
    /// The audit ran and at least one policy rule was violated.
    case breach = 2
}

/// Readiness policy, read from the audited repository. Every field is optional; an absent
/// configuration means "no policy": the gate reports the score and exits `pass`.
struct GatePolicy: Decodable, Sendable {
    /// Fail when the total score is below this value.
    var minScore: Double?
    /// Fail when the total score dropped from the baseline by more than this many points.
    /// `0` means no regression at all is tolerated.
    var maxTotalRegression: Double?
    /// Check keys frozen against regression: fail when any of them scores below its
    /// baseline value, even if the total holds.
    var noRegressionChecks: [String]?
    /// Fail when any finding is at or above this severity.
    var maxSeverity: Severity?
    /// Fail when the app has any blocker, independently of the score. A team can enforce
    /// "must launch" without also enforcing a quality bar.
    var forbidBlockers: Bool?
    /// Path to the baseline file, relative to the audited repository.
    var baseline: String?
    /// Act only on findings at or above this confidence. Reserved for `audit-fidelity`,
    /// which introduces per-finding confidence; parsed here so a repository can adopt the
    /// key before that change lands.
    var minConfidence: String?

    static let empty = GatePolicy()

    var isEmpty: Bool {
        minScore == nil && maxTotalRegression == nil
            && (noRegressionChecks?.isEmpty ?? true) && maxSeverity == nil
            && forbidBlockers != true
    }

    /// Default config file name, looked up at the root of the audited repository.
    static let defaultFileName = ".foldready.json"
    /// Default baseline file name, looked up at the root of the audited repository.
    static let defaultBaselineName = ".foldready-baseline.json"

    enum LoadError: Error, CustomStringConvertible {
        case malformed(path: String, underlying: String)

        var description: String {
            switch self {
            case .malformed(let path, let underlying):
                return "config '\(path)' is not valid FoldReady policy JSON: \(underlying)"
            }
        }
    }

    /// Loads the policy from `path`, or returns `nil` when the file does not exist.
    /// Throws only when a file exists and cannot be understood: a typo in a policy must
    /// not silently disable the gate.
    static func load(path: String) throws -> GatePolicy? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        guard let data = FileManager.default.contents(atPath: path) else {
            throw LoadError.malformed(path: path, underlying: "unreadable")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(GatePolicy.self, from: data)
        } catch {
            throw LoadError.malformed(path: path, underlying: "\(error)")
        }
    }
}

/// A previously accepted result, committed to the audited repository so that an accepted
/// regression is a reviewable diff rather than a hidden server-side state change.
struct Baseline: Sendable {
    let schemaVersion: Int
    let foldreadyVersion: String
    let generatedAt: String
    let score: Double
    /// Per-check score, keyed by the stable check key, on the same 0-100 scale as the
    /// JSON contract.
    let checkScores: [String: Double]

    enum LoadError: Error, CustomStringConvertible {
        case malformed(path: String, reason: String)

        var description: String {
            switch self {
            case .malformed(let path, let reason):
                return "baseline '\(path)' is not a valid FoldReady result: \(reason)"
            }
        }
    }

    static func load(path: String) throws -> Baseline? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        guard let data = FileManager.default.contents(atPath: path),
              let raw = try? JSONSerialization.jsonObject(with: data),
              let obj = raw as? [String: Any] else {
            throw LoadError.malformed(path: path, reason: "not a JSON object")
        }
        guard let score = obj["score"] as? Double ?? (obj["score"] as? Int).map(Double.init) else {
            throw LoadError.malformed(path: path, reason: "missing numeric 'score'")
        }
        var scores: [String: Double] = [:]
        for check in (obj["checks"] as? [[String: Any]] ?? []) {
            guard let key = check["key"] as? String else { continue }
            if let s = check["score"] as? Double { scores[key] = s }
            else if let s = check["score"] as? Int { scores[key] = Double(s) }
        }
        return Baseline(
            schemaVersion: (obj["schema_version"] as? Int) ?? 0,
            foldreadyVersion: (obj["foldready_version"] as? String) ?? "unknown",
            generatedAt: (obj["generated_at"] as? String) ?? "unknown",
            score: score,
            checkScores: scores)
    }

    /// Serialised form of a result, for `--write-baseline`.
    static func serialise(_ result: AuditResult) -> String {
        JSONReport.render(result)
    }
}

/// One evaluated policy rule. Carries expected and actual values plus the findings that
/// explain the breach, so the gate can print why a build failed without the reader
/// having to re-run the audit.
struct RuleResult: Sendable {
    let name: String
    let expected: String
    let actual: String
    let passed: Bool
    let findings: [Finding]
    /// Set when a rule could not be evaluated (for example regression with no baseline).
    let skippedReason: String?

    init(name: String, expected: String, actual: String, passed: Bool,
         findings: [Finding] = [], skippedReason: String? = nil) {
        self.name = name
        self.expected = expected
        self.actual = actual
        self.passed = passed
        self.findings = findings
        self.skippedReason = skippedReason
    }
}

struct GateOutcome: Sendable {
    let rules: [RuleResult]
    let policyConfigured: Bool
    let baselineDescription: String?

    var breaches: [RuleResult] { rules.filter { !$0.passed } }
    var exitCode: GateExit { breaches.isEmpty ? .pass : .breach }
}

enum GateEngine {

    static func evaluate(result: AuditResult, baseline: Baseline?, policy: GatePolicy) -> GateOutcome {
        var rules: [RuleResult] = []

        // A baseline from a different scoring version would report a regression that is an
        // artefact of the rebalance, not a change in the app.
        let comparable: Baseline?
        if let baseline, baseline.schemaVersion != resultSchemaVersion {
            comparable = nil
        } else {
            comparable = baseline
        }
        let staleBaseline = baseline != nil && comparable == nil
        let staleReason: String? = staleBaseline
            ? "baseline was written by contract v\(baseline?.schemaVersion ?? 0); this engine "
                + "emits v\(resultSchemaVersion). Rewrite it with --write-baseline."
            : nil

        if policy.forbidBlockers == true {
            rules.append(RuleResult(
                name: "no blockers",
                expected: "none",
                actual: result.blockers.isEmpty ? "none"
                    : result.blockers.map(\.title).joined(separator: ", "),
                passed: result.blockers.isEmpty))
        }

        if let floor = policy.minScore {
            let worst = result.outcomes
                .filter { $0.score < 1.0 }
                .sorted { $0.weight * (1 - $0.score) > $1.weight * (1 - $1.score) }
                .prefix(3)
                .flatMap(\.findings)
            rules.append(RuleResult(
                name: "score floor",
                expected: ">= \(fmt(floor))",
                actual: fmt(result.totalScore),
                passed: result.totalScore >= floor,
                findings: result.totalScore >= floor ? [] : Finding.deterministicOrder(Array(worst))))
        }

        if let tolerance = policy.maxTotalRegression {
            if let baseline = comparable {
                let drop = baseline.score - result.totalScore
                rules.append(RuleResult(
                    name: "total regression",
                    expected: "drop <= \(fmt(tolerance)) from baseline \(fmt(baseline.score))",
                    actual: drop > 0 ? "dropped \(fmt(drop))" : "gained \(fmt(-drop))",
                    passed: drop <= tolerance,
                    findings: drop <= tolerance ? [] : regressedCheckFindings(result: result, baseline: baseline)))
            } else {
                rules.append(RuleResult(
                    name: "total regression",
                    expected: "drop <= \(fmt(tolerance))",
                    actual: staleBaseline ? "baseline from another scoring version" : "no baseline",
                    passed: true,
                    skippedReason: staleReason ?? "no baseline file yet"))
            }
        }

        for key in (policy.noRegressionChecks ?? []) {
            guard let outcome = result.outcomes.first(where: { $0.key == key }) else {
                rules.append(RuleResult(
                    name: "check '\(key)' no regression",
                    expected: "check present",
                    actual: "unknown check key",
                    passed: false,
                    skippedReason: "no check with key '\(key)' in this FoldReady version"))
                continue
            }
            let current = (outcome.score * 100).rounded()
            guard let baseline = comparable, let was = baseline.checkScores[key] else {
                rules.append(RuleResult(
                    name: "check '\(key)' no regression",
                    expected: "no drop",
                    actual: "no baseline",
                    passed: true,
                    skippedReason: staleReason ?? "no baseline value for '\(key)'"))
                continue
            }
            rules.append(RuleResult(
                name: "check '\(key)' no regression",
                expected: ">= \(fmt(was))",
                actual: fmt(current),
                passed: current >= was,
                findings: current >= was ? [] : outcome.findings))
        }

        if let ceiling = policy.maxSeverity {
            let offenders = result.findings.filter { $0.severity <= ceiling }
            rules.append(RuleResult(
                name: "severity ceiling",
                expected: "no finding at or above \(ceiling.rawValue)",
                actual: offenders.isEmpty ? "none" : "\(offenders.count) finding(s)",
                passed: offenders.isEmpty,
                findings: offenders))
        }

        let baselineDescription = baseline.map {
            "\($0.generatedAt) (foldready \($0.foldreadyVersion), contract v\($0.schemaVersion))"
        }
        return GateOutcome(rules: rules, policyConfigured: !policy.isEmpty,
            baselineDescription: baselineDescription)
    }

    /// Findings of the checks that lost points against the baseline: what a reader needs
    /// to understand a total regression.
    private static func regressedCheckFindings(result: AuditResult, baseline: Baseline) -> [Finding] {
        var out: [Finding] = []
        for outcome in result.outcomes {
            guard let was = baseline.checkScores[outcome.key] else { continue }
            if (outcome.score * 100).rounded() < was { out.append(contentsOf: outcome.findings) }
        }
        return Finding.deterministicOrder(out)
    }

    static func fmt(_ d: Double) -> String {
        d == d.rounded() ? String(Int(d)) : String(format: "%.1f", d)
    }
}

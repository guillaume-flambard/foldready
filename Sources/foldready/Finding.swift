import Foundation

enum Severity: String, Comparable, Codable, Sendable {
    case critical
    case major
    case minor
    case info

    private static let order: [Severity: Int] = [.critical: 0, .major: 1, .minor: 2, .info: 3]

    static func < (lhs: Severity, rhs: Severity) -> Bool {
        order[lhs]! < order[rhs]!
    }
}

/// How sure the audit is that a finding is real, independent of how bad it would be if true.
///
/// Severity is "how bad if true"; confidence is "how sure we are". They are separate because
/// a context-dependent signal can be severe and uncertain at once, and a team should be able
/// to fail a build on the certain ones without silencing the rest.
enum Confidence: String, Comparable, Codable, Sendable {
    case high
    case medium
    case low

    private static let order: [Confidence: Int] = [.high: 0, .medium: 1, .low: 2]

    /// Inverted against `order` so `high` is the greatest: a gate comparing against a
    /// minimum keeps the strongest findings.
    static func < (lhs: Confidence, rhs: Confidence) -> Bool {
        order[lhs]! > order[rhs]!
    }
}

struct Finding: Sendable {
    let check: String
    let severity: Severity
    let message: String
    /// Repository-relative path. Never absolute: the result must be identical whatever
    /// the checkout path of the machine that ran the audit.
    let file: String?
    /// 1-based line number.
    let line: Int?
    /// How sure the audit is this finding is real. Defaults to `.high`: the strongest
    /// claim, so an unlabelled site behaves exactly as before confidence existed.
    ///
    /// `var`, not `let`: a stored `let` with a default is omitted from the synthesised
    /// memberwise initialiser, which would leave later checks no way to set the level.
    var confidence: Confidence = .high

    /// Total order over findings, so two audits of the same tree emit the same list in
    /// the same order regardless of file system enumeration order. `Array.sorted` is not
    /// stable, so ties must be broken by the payload itself rather than by input order.
    static func deterministicOrder(_ findings: [Finding]) -> [Finding] {
        findings.sorted { a, b in
            if a.severity != b.severity { return a.severity < b.severity }
            if a.check != b.check { return a.check < b.check }
            let fa = a.file ?? "", fb = b.file ?? ""
            if fa != fb { return fa < fb }
            let la = a.line ?? 0, lb = b.line ?? 0
            if la != lb { return la < lb }
            return a.message < b.message
        }
    }
}

struct FileContent: Sendable {
    let path: String
    let content: String
}

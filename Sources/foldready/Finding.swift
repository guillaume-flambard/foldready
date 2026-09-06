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

struct Finding: Sendable {
    let check: String
    let severity: Severity
    let message: String
    /// Repository-relative path. Never absolute: the result must be identical whatever
    /// the checkout path of the machine that ran the audit.
    let file: String?
    /// 1-based line number.
    let line: Int?

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

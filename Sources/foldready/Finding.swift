import Foundation

enum Severity: String, Comparable {
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
    let file: String?
    let line: Int?
}

struct FileContent: Sendable {
    let path: String
    let content: String
}

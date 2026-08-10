import Foundation

enum TransformTier: String, Comparable, Sendable {
    case safe
    case review
    case manual

    private static let order: [TransformTier: Int] = [.safe: 0, .review: 1, .manual: 2]
    static func < (lhs: TransformTier, rhs: TransformTier) -> Bool { order[lhs]! < order[rhs]! }
}

struct FileEdit: Sendable {
    let path: String
    let before: String
    let after: String
}

struct Patch: Sendable {
    let transformId: String
    let title: String
    let tier: TransformTier
    let edits: [FileEdit]
    let newFiles: [String: String]
    let notes: [String]

    var diff: String {
        var out = ""
        for edit in edits where edit.before != edit.after {
            out += Diff.unified(edit)
        }
        for (path, content) in newFiles.sorted(by: { $0.key < $1.key }) {
            out += "--- a/\(path)\n+++ b/\(path)\n@@ -0,0 +1,\(content.components(separatedBy: .newlines).count) @@\n"
            for line in content.components(separatedBy: .newlines) {
                out += "+\(line)\n"
            }
        }
        return out
    }

    var isNoop: Bool {
        edits.allSatisfy { $0.before == $0.after } && newFiles.isEmpty && notes.isEmpty
    }
}

struct TransformInput {
    let root: String
    let swiftFiles: [FileContent]
    let plists: [FileContent]
}

struct PortPlan {
    let patches: [Patch]
    let skippedNotes: [String]
}

struct PortResult {
    let appName: String
    let plan: PortPlan
    let applied: Bool
    let appliedCount: Int
    let reportPath: String?
}

enum Diff {
    static func unified(_ edit: FileEdit) -> String {
        let a = edit.before.components(separatedBy: .newlines)
        let b = edit.after.components(separatedBy: .newlines)
        let (removed, added) = minimalEdit(a, b)
        let header = "--- a/\(edit.path)\n+++ b/\(edit.path)\n"
        var i = 0, j = 0
        var hunks: [String] = []
        var cur: [String] = []
        var startA = 1, startB = 1

        while i < a.count || j < b.count {
            if i < a.count, j < b.count, a[i] == b[j] {
                if !cur.isEmpty {
                    hunks.append(hunk(cur, startA, startB))
                    cur = []
                }
                i += 1; j += 1
                startA = i + 1; startB = j + 1
            } else if j < b.count, added.contains(j) {
                if cur.isEmpty { startA = i + 1; startB = j + 1 }
                cur.append("+\(b[j])")
                j += 1
            } else if i < a.count, removed.contains(i) {
                if cur.isEmpty { startA = i + 1; startB = j + 1 }
                cur.append("-\(a[i])")
                i += 1
            } else {
                if !cur.isEmpty { hunks.append(hunk(cur, startA, startB)); cur = [] }
                i += 1; j += 1
                startA = i + 1; startB = j + 1
            }
        }
        if !cur.isEmpty { hunks.append(hunk(cur, startA, startB)) }
        return header + hunks.joined(separator: "\n") + "\n"
    }

    private static func hunk(_ lines: [String], _ startA: Int, _ startB: Int) -> String {
        let minus = lines.filter { $0.hasPrefix("-") }.count
        let plus = lines.filter { $0.hasPrefix("+") }.count
        let ctx = lines.filter { !$0.hasPrefix("-") && !$0.hasPrefix("+") }.count
        return "@@ -\(startA),\(minus + ctx) +\(startB),\(plus + ctx) @@\n" + lines.joined(separator: "\n")
    }

    // Minimal line edit: longest common subsequence based remove/add sets.
    private static func minimalEdit(_ a: [String], _ b: [String]) -> (removed: Set<Int>, added: Set<Int>) {
        let n = a.count, m = b.count
        var dp = [[Int]](repeating: [Int](repeating: 0, count: m + 1), count: n + 1)
        for i in stride(from: n - 1, through: 0, by: -1) {
            for j in stride(from: m - 1, through: 0, by: -1) {
                dp[i][j] = a[i] == b[j] ? dp[i + 1][j + 1] + 1 : max(dp[i + 1][j], dp[i][j + 1])
            }
        }
        var removed = Set<Int>(), added = Set<Int>()
        var i = 0, j = 0
        while i < n && j < m {
            if a[i] == b[j] { i += 1; j += 1 }
            else if dp[i + 1][j] >= dp[i][j + 1] { removed.insert(i); i += 1 }
            else { added.insert(j); j += 1 }
        }
        while i < n { removed.insert(i); i += 1 }
        while j < m { added.insert(j); j += 1 }
        return (removed, added)
    }
}

import Foundation

/// What the audit refuses to score, and why.
///
/// Measured on the twenty-app corpus (2026-09-06): 92% of the frame findings were
/// icon-sized, one `UIScreen.main` finding was actually `XCUIScreen.main` inside a
/// snapshot helper, and six were inside preview blocks. A density metric built on that
/// would be a density of noise.
enum Exclusions {

    /// Density of offending UI files at which the layout check halves. Calibrated on the
    /// twenty-app corpus (2026-09-06); see docs/result-contract.md.
    static let layoutDensityHalfPoint: Double = 0.03

    /// Share of UI files that must read size classes or effective geometry for the
    /// geometry check to credit full coverage. Same corpus, same date.
    static let geometryCoverageAnchor: Double = 0.02

    /// A frame this small in both dimensions is a control with an intrinsic size — an
    /// avatar, a badge, a spinner — not something that should reflow.
    static let iconPointLimit: Double = 100

    private static let excludedPathFragments = [
        "/tests/", "/test/", "tests/", "/testing/", "uitests", "snapshots/", "snapshot/",
        "/pods/", "/carthage/", "/vendor/", "/vendored/", "/thirdparty/", "/third_party/",
        "/.build/", "/deriveddata/", "/node_modules/", "/fixtures/", "/mocks/"
    ]

    private static let excludedFileSuffixes = [
        "tests.swift", "test.swift", "spec.swift", "snapshothelper.swift",
        ".generated.swift", "mock.swift", "mocks.swift"
    ]

    /// True when the file is not shipping UI code: tests, snapshots, generated code, or a
    /// vendored dependency.
    static func isExcludedPath(_ path: String) -> Bool {
        let lower = "/" + path.lowercased()
        if excludedPathFragments.contains(where: { lower.contains($0) }) { return true }
        return excludedFileSuffixes.contains { lower.hasSuffix($0) }
    }

    /// True when the file participates in the UI: the denominator of every density check.
    static func isUIFile(_ file: FileContent) -> Bool {
        guard !isExcludedPath(file.path) else { return false }
        return file.content.contains("import SwiftUI") || file.content.contains("import UIKit")
    }

    private static let frameLiteral = try? NSRegularExpression(
        pattern: #"\.frame\(\s*width:\s*(\d+(?:\.\d+)?)\s*,\s*height:\s*(\d+(?:\.\d+)?)"#)

    /// A hardcoded frame that is a real reflow problem, i.e. not icon-sized.
    /// Returns nil when the line has no literal frame at all.
    static func isScorableFrame(line: String) -> Bool? {
        guard let regex = frameLiteral else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let w = Range(match.range(at: 1), in: line),
              let h = Range(match.range(at: 2), in: line),
              let width = Double(line[w]), let height = Double(line[h]) else { return nil }
        return max(width, height) > iconPointLimit
    }

    /// `UIScreen.main` with a word boundary on both sides: `XCUIScreen.main` is a different
    /// symbol and must not match.
    static let screenMain = try? NSRegularExpression(pattern: #"(?<![A-Za-z0-9_])UIScreen\.main\b"#)
    static let screenMainBounds = try? NSRegularExpression(
        pattern: #"(?<![A-Za-z0-9_])UIScreen\.main\.bounds\b"#)

    static func matches(_ regex: NSRegularExpression?, _ line: String) -> Bool {
        guard let regex else { return false }
        return regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
    }

    /// Line indices (0-based) that sit inside a preview block. Cheap brace matching from
    /// the declaration line: a preview is a leaf, so it does not need a real parser.
    static func previewLines(in content: String) -> Set<Int> {
        let lines = content.components(separatedBy: .newlines)
        var inside = Set<Int>()
        var depth = 0
        var active = false
        for (index, line) in lines.enumerated() {
            if !active,
               line.contains("#Preview") || line.contains(": PreviewProvider")
                || line.range(of: #"static var previews\s*:"#, options: .regularExpression) != nil {
                active = true
                depth = 0
            }
            if active {
                inside.insert(index)
                depth += line.filter { $0 == "{" }.count
                depth -= line.filter { $0 == "}" }.count
                if depth <= 0 && line.contains("}") { active = false }
            }
        }
        return inside
    }
}

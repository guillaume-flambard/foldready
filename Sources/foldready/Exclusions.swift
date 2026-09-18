import Foundation

/// Why a file was kept out of scoring. The reasons are reported separately, so an aggressive
/// `exclude` list in the audited repository is visible rather than folded into one opaque
/// count.
enum ExclusionReason: Sendable {
    /// Test targets, snapshot directories, fixtures and mocks.
    case tests
    /// Vendored or built dependencies: Pods, Carthage, node_modules, DerivedData.
    case vendored
    /// Machine-generated source, e.g. `.generated.swift`.
    case generated
    /// Dropped by the audited repository's own `.foldready.json` `exclude` list.
    case config
}

/// How many files each exclusion rule dropped, carried on `AuditStats` so the result states
/// what the audit refused to score and why.
struct ExclusionReport: Sendable, Equatable {
    var tests: Int = 0
    var vendored: Int = 0
    var generated: Int = 0
    var byConfig: Int = 0
}

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

    private static let testsPathFragments = [
        "/tests/", "/test/", "tests/", "/testing/", "uitests", "snapshots/", "snapshot/",
        "/fixtures/", "/mocks/"
    ]

    private static let vendoredPathFragments = [
        "/pods/", "/carthage/", "/vendor/", "/vendored/", "/thirdparty/", "/third_party/",
        "/.build/", "/deriveddata/", "/node_modules/"
    ]

    private static let testsFileSuffixes = [
        "tests.swift", "test.swift", "spec.swift", "snapshothelper.swift",
        "mock.swift", "mocks.swift"
    ]

    private static let generatedFileSuffixes = [".generated.swift"]

    /// True when the file is not shipping UI code: tests, snapshots, generated code, or a
    /// vendored dependency. The default rule set, with no repository policy applied.
    static func isExcludedPath(_ path: String) -> Bool {
        isExcludedPath(path, policy: .empty) != nil
    }

    /// The reason `path` is excluded under the built-in rules plus the repository policy, or
    /// nil when it is in scope. An `include` entry beats both the built-in rules and an
    /// `exclude` entry: an explicitly included path is always audited.
    static func isExcludedPath(_ path: String, policy: GatePolicy) -> ExclusionReason? {
        if matchesAny(policy.include, path) { return nil }
        if matchesAny(policy.exclude, path) { return .config }
        return defaultExclusion(for: path)
    }

    /// A configured pattern matches by case-insensitive substring, the same shape as the
    /// built-in fragments, so an entry can name a file or a whole directory.
    private static func matchesAny(_ patterns: [String]?, _ path: String) -> Bool {
        guard let patterns, !patterns.isEmpty else { return false }
        let lower = path.lowercased()
        return patterns.contains { !$0.isEmpty && lower.contains($0.lowercased()) }
    }

    private static func defaultExclusion(for path: String) -> ExclusionReason? {
        let lower = "/" + path.lowercased()
        if generatedFileSuffixes.contains(where: { lower.hasSuffix($0) }) { return .generated }
        if testsFileSuffixes.contains(where: { lower.hasSuffix($0) }) { return .tests }
        if vendoredPathFragments.contains(where: { lower.contains($0) }) { return .vendored }
        if testsPathFragments.contains(where: { lower.contains($0) }) { return .tests }
        return nil
    }

    /// True when the file participates in the UI: the denominator of every density check.
    static func isUIFile(_ file: FileContent, policy: GatePolicy = .empty) -> Bool {
        guard isExcludedPath(file.path, policy: policy) == nil else { return false }
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

    /// The `UIInterfaceOrientation*` values in the first `UISupportedInterfaceOrientations`
    /// array of a plist, in file order. Empty when the key is absent or its array holds no
    /// values, which is how a caller tells "not declared" from "declared and not locked".
    static func declaredOrientations(in plist: String) -> [String] {
        guard let arrayRegex = orientationArray, let valueRegex = orientationValue else { return [] }
        let range = NSRange(plist.startIndex..., in: plist)
        guard let match = arrayRegex.firstMatch(in: plist, range: range),
              let body = Range(match.range(at: 1), in: plist) else { return [] }
        let array = String(plist[body])
        let arrayRange = NSRange(array.startIndex..., in: array)
        return valueRegex.matches(in: array, range: arrayRange).compactMap { stringMatch in
            Range(stringMatch.range(at: 1), in: array).map { String(array[$0]) }
        }
    }

    /// True when a plist declares supported interface orientations and every one is portrait.
    /// A portrait-only array is the lock that stops the app adapting to a wider canvas; any
    /// landscape value makes it false. A plist with no key also returns false, so
    /// `declaredOrientations(in:)` is how the caller distinguishes the two.
    static func orientationLock(in plist: String) -> Bool {
        let declared = declaredOrientations(in: plist)
        guard !declared.isEmpty else { return false }
        return declared.allSatisfy { portraitOrientations.contains($0) }
    }

    private static let orientationArray = try? NSRegularExpression(
        pattern: #"<key>\s*UISupportedInterfaceOrientations\s*</key>\s*<array>(.*?)</array>"#,
        options: [.dotMatchesLineSeparators])
    private static let orientationValue = try? NSRegularExpression(
        pattern: #"<string>\s*([A-Za-z]+)\s*</string>"#)

    private static let portraitOrientations: Set<String> = [
        "UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown"
    ]
}

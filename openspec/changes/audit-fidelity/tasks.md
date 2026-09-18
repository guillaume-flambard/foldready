# audit-fidelity — implementation plan

> **For agentic workers:** execute task by task, in order. Steps use checkbox (`- [ ]`)
> syntax for tracking. Run `./Scripts/check.sh` before every commit.

**Goal:** replace line-based matching with a dependency-free Swift lexer, promote interface
idiom and interface orientation to scored checks, and give every finding a confidence level
the gate can act on.

**Architecture:** a new `SwiftLexer.swift` blanks comments and string-literal contents while
preserving line numbers and brace depth. Every check consumes `LexedFile` instead of raw
text. Exclusions become configurable through `.foldready.json`, which the audit now reads.
`Finding` gains `confidence`, and `GatePolicy.minConfidence` (declared but unread since
`readiness-gate`) starts filtering. The contract moves to v5, the release to 0.5.0.

**Tech Stack:** Swift 6.0 package, no new dependency. `Testing` framework. Python scripts
under `Scripts/` for the sourcing and golden guards.

**Spec:** `openspec/changes/audit-fidelity/specs/audit/checks/spec.md`
**Design:** `openspec/changes/audit-fidelity/design.md`

## Global Constraints

- No new package dependency. `swift-syntax` is explicitly out of scope; `Package.swift` must
  not change.
- Every scored check carries a non-empty `reference` beginning `https://developer.apple.com/`.
  `Scripts/sourcing-check.py` fails the build otherwise.
- The deterministic finding order is severity, check key, file, line, message. Any new field
  is added to `Finding` only if it does not disturb that order.
- Result paths are repository-relative; findings never contain an absolute path.
- `resultSchemaVersion` becomes `5`; `foldreadyVersion` becomes `"0.5.0"`.
- Applicable weights sum to 1.0: adaptive-layout 0.35, navigation 0.20, adaptive-geometry 0.15,
  build-toolchain 0.10, state 0.10, idiom 0.10, orientation 0.10 (captured-layout 0.20 only
  with screenshots).
- `./Scripts/check.sh` must end `==> all checks passed`.

---

## Task 1: The Swift lexer

**Files:**
- Create: `Sources/foldready/SwiftLexer.swift`
- Test: `Tests/foldreadyTests/LexerTests.swift`

**Interfaces:**
- Consumes: `FileContent { path: String, content: String }` (existing, `Finding.swift`).
- Produces:
  - `struct LexedLine: Sendable { let number: Int; let code: String; let depth: Int }`
  - `struct LexedFile: Sendable { let path: String; let lines: [LexedLine]; let previewRanges: [ClosedRange<Int>]; let failed: Bool; func contains(_ token: String) -> Bool; func matches(_ regex: NSRegularExpression?) -> Bool }`
  - `enum SwiftLexer { static func lex(_ file: FileContent) -> LexedFile }`

- [x] **Step 1: Write the failing lexer tests**

```swift
import Testing
import Foundation
@testable import foldready

private func lexed(_ source: String) -> LexedFile {
    SwiftLexer.lex(FileContent(path: "App/View.swift", content: source))
}

@Suite("Lexer")
struct LexerTests {

    @Test func lineCommentIsDropped() {
        let file = lexed("let a = 1 // UIScreen.main.bounds\n")
        #expect(!file.matches(Exclusions.screenMainBounds))
    }

    @Test func nestedBlockCommentIsDropped() {
        let source = """
        /* outer /* inner UIScreen.main.bounds */ still */
        let a = 1
        """
        #expect(!lexed(source).matches(Exclusions.screenMainBounds))
    }

    @Test func stringLiteralContentsAreDropped() {
        let file = lexed("let s = \"UIScreen.main.bounds\"\n")
        #expect(!file.matches(Exclusions.screenMainBounds))
    }

    @Test func multilineStringContentsAreDropped() {
        let source = """
        let s = \"\"\"
        UIScreen.main.bounds
        \"\"\"
        """
        #expect(!lexed(source).matches(Exclusions.screenMainBounds))
    }

    @Test func rawStringContentsAreDropped() {
        let file = lexed("let s = #\"UIScreen.main.bounds\"#\n")
        #expect(!file.matches(Exclusions.screenMainBounds))
    }

    @Test func interpolationIsRealCode() {
        let file = lexed("let s = \"\\(UIScreen.main.bounds.width)\"\n")
        #expect(file.matches(Exclusions.screenMainBounds))
    }

    @Test func escapedQuoteDoesNotEndTheString() {
        let source = "let s = \"a \\\" UIScreen.main.bounds\"\n"
        #expect(!lexed(source).matches(Exclusions.screenMainBounds))
    }

    @Test func codeAfterACommentSurvives() {
        let file = lexed("let a = 1 // note\nlet b = UIScreen.main.bounds\n")
        #expect(file.matches(Exclusions.screenMainBounds))
    }

    @Test func lineNumbersSurviveCommentStripping() {
        let file = lexed("let a = 1 // note\nlet b = UIScreen.main.bounds\n")
        let line = file.lines.first { $0.code.contains("UIScreen.main.bounds") }
        #expect(line?.number == 2)
    }

    @Test func unterminatedBlockCommentFailsTheFile() {
        let file = lexed("/* never closed\nlet a = UIScreen.main.bounds\n")
        #expect(file.failed)
    }

    @Test func previewBodyIsRecordedAsARange() {
        let source = """
        struct A: View { var body: some View { Text("a") } }
        #Preview {
            Text("b")
        }
        """
        let file = lexed(source)
        #expect(!file.previewRanges.isEmpty)
    }

    @Test func braceInsideAStringDoesNotBreakPreviewTracking() {
        let source = """
        #Preview {
            Text("}")
        }
        struct After: View { var body: some View { Text("x") } }
        """
        let file = lexed(source)
        let after = file.lines.first { $0.code.contains("struct After") }
        #expect(after != nil)
        #expect(!(file.previewRanges.last?.contains((after?.number ?? 0) - 1) ?? false))
    }
}
```

- [x] **Step 2: Run the tests and confirm they fail**

Run: `swift test --filter Lexer`
Expected: FAIL — `cannot find 'SwiftLexer' in scope`.

- [x] **Step 3: Implement the lexer**

```swift
import Foundation

/// One source line after lexing: comments gone, string literals blanked to spaces, and the
/// brace depth at the start of the line.
struct LexedLine: Sendable {
    /// 1-based line number in the original file.
    let number: Int
    /// The code on this line, with comment and string-literal contents replaced by spaces so
    /// column offsets and token boundaries survive.
    let code: String
    /// Brace nesting depth at the start of this line.
    let depth: Int
}

/// A Swift file viewed through the lexer rather than as raw text.
///
/// This is a lexer, not a syntax tree. It cannot tell that a match sits in a test helper
/// nested in a shipping file; declaration-scope attribution is a recorded follow-up. What it
/// does guarantee is that a match inside a comment or inside the literal text of a string is
/// never seen by a check, which is where the demonstrated false positives came from.
struct LexedFile: Sendable {
    let path: String
    let lines: [LexedLine]
    /// 0-based line ranges inside a `#Preview { ... }` or `PreviewProvider` body.
    let previewRanges: [ClosedRange<Int>]
    /// True when the lexer reached EOF inside an unterminated block comment or string. Such a
    /// file is excluded from scoring rather than scored clean.
    let failed: Bool

    func contains(_ token: String) -> Bool {
        lines.contains { $0.code.contains(token) }
    }

    func matches(_ regex: NSRegularExpression?) -> Bool {
        Exclusions.matches(regex, lines.map(\.code).joined(separator: "\n"))
    }

    func isPreview(line number: Int) -> Bool {
        previewRanges.contains { $0.contains(number - 1) }
    }
}

enum SwiftLexer {

    static func lex(_ file: FileContent) -> LexedFile {
        let scalars = Array(file.content)
        var code: [Character] = Array(repeating: " ", count: scalars.count)
        var failed = false
        var i = 0
        var depth = 0
        // Depth at the start of each 0-based line.
        var depths: [Int] = []
        var lineDepths: [Int] = []
        var currentDepth = 0

        func isNewline(_ index: Int) -> Bool {
            index < scalars.count && scalars[index] == "\n"
        }

        while i < scalars.count {
            let c = scalars[i]
            if c == "\n" {
                lineDepths.append(currentDepth)
                i += 1
                continue
            }
            // Line comment
            if c == "/" && i + 1 < scalars.count && scalars[i + 1] == "/" {
                while i < scalars.count && scalars[i] != "\n" { i += 1 }
                continue
            }
            // Block comment, which nests in Swift
            if c == "/" && i + 1 < scalars.count && scalars[i + 1] == "*" {
                var nest = 1
                i += 2
                while i < scalars.count && nest > 0 {
                    if scalars[i] == "/" && i + 1 < scalars.count && scalars[i + 1] == "*" {
                        nest += 1; i += 2
                    } else if scalars[i] == "*" && i + 1 < scalars.count && scalars[i + 1] == "/" {
                        nest -= 1; i += 2
                    } else {
                        if scalars[i] == "\n" { lineDepths.append(currentDepth) }
                        i += 1
                    }
                }
                if nest > 0 { failed = true }
                continue
            }
            // Raw string: #"..."#
            if c == "#", i + 1 < scalars.count, scalars[i + 1] == "\"" {
                i += 1
                while i < scalars.count {
                    if scalars[i] == "\"" && i + 1 < scalars.count && scalars[i + 1] == "#" {
                        i += 2; break
                    }
                    if scalars[i] == "\n" { lineDepths.append(currentDepth) }
                    i += 1
                }
                continue
            }
            // Strings, single-line and multiline
            if c == "\"" {
                let multiline = scalars.count > i + 2 && scalars[i + 1] == "\""
                    && scalars[i + 2] == "\""
                i += multiline ? 3 : 1
                var terminated = false
                while i < scalars.count {
                    if multiline && scalars[i] == "\"", i + 2 < scalars.count,
                       scalars[i + 1] == "\"", scalars[i + 2] == "\"" {
                        i += 3; terminated = true; break
                    }
                    if !multiline && scalars[i] == "\\" {
                        i += 2; continue
                    }
                    if !multiline && scalars[i] == "\"" {
                        i += 1; terminated = true; break
                    }
                    // Interpolation is real code: copy it through.
                    if scalars[i] == "\\", i + 1 < scalars.count, scalars[i + 1] == "(" {
                        var nest = 1
                        code[i] = "\\"; code[i + 1] = "("
                        i += 2
                        while i < scalars.count && nest > 0 {
                            if scalars[i] == "(" { nest += 1 }
                            if scalars[i] == ")" { nest -= 1 }
                            if scalars[i] == "\n" { lineDepths.append(currentDepth) }
                            code[i] = scalars[i]
                            i += 1
                        }
                        continue
                    }
                    if scalars[i] == "\n" { lineDepths.append(currentDepth) }
                    i += 1
                }
                if !terminated { failed = true }
                continue
            }
            if c == "{" { currentDepth += 1 }
            if c == "}" { currentDepth -= 1 }
            code[i] = c
            i += 1
        }

        // Split the blanked code back into lines, keeping 1-based numbers.
        let text = String(code)
        let rawLines = text.components(separatedBy: "\n")
        var lines: [LexedLine] = []
        var observedDepths = lineDepths
        if observedDepths.count < rawLines.count {
            observedDepths.append(contentsOf: Array(repeating: 0,
                count: rawLines.count - observedDepths.count))
        }
        for (index, lineText) in rawLines.enumerated() {
            lines.append(LexedLine(number: index + 1, code: lineText,
                                   depth: index < observedDepths.count ? observedDepths[index] : 0))
        }

        let previewRanges = previewRanges(in: lines)
        return LexedFile(path: file.path, lines: lines, previewRanges: previewRanges,
                         failed: failed)
    }

    /// Line ranges (0-based, inclusive) inside a `#Preview` macro body or a
    /// `PreviewProvider` conformance body. Brace counting runs on lexed lines, so a brace
    /// inside a string or comment can no longer break it.
    private static func previewRanges(in lines: [LexedLine]) -> [ClosedRange<Int>] {
        var ranges: [ClosedRange<Int>] = []
        var index = 0
        while index < lines.count {
            let code = lines[index].code
            let starts = code.contains("#Preview")
                || code.contains(": PreviewProvider")
                || code.range(of: #"static var previews\s*:"#, options: .regularExpression) != nil
            guard starts else { index += 1; continue }
            let start = index
            var depth = 0
            var opened = false
            while index < lines.count {
                for character in lines[index].code {
                    if character == "{" { depth += 1; opened = true }
                    if character == "}" { depth -= 1 }
                }
                if opened && depth <= 0 { break }
                index += 1
            }
            ranges.append(start...min(index, lines.count - 1))
            index += 1
        }
        return ranges
    }
}
```

- [x] **Step 4: Run the tests and confirm they pass**

Run: `swift test --filter Lexer`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add Sources/foldready/SwiftLexer.swift Tests/foldreadyTests/LexerTests.swift
git commit -m "feat: lex Swift files so comments and strings cannot be scored"
```

---

## Task 2: Findings carry confidence

**Files:**
- Modify: `Sources/foldready/Finding.swift`
- Test: `Tests/foldreadyTests/ConfidenceTests.swift`

**Interfaces:**
- Produces: `enum Confidence: String, Comparable, Codable, Sendable` with `high`, `medium`,
  `low`; `Finding` gains `let confidence: Confidence`.
- Consumes: nothing new.

- [x] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
@testable import foldready

@Suite("Confidence")
struct ConfidenceTests {

    @Test func orderIsHighThenMediumThenLow() {
        #expect(Confidence.high > Confidence.medium)
        #expect(Confidence.medium > Confidence.low)
    }

    @Test func aFindingCarriesConfidenceAndDefaultsToHigh() {
        let finding = Finding(check: "adaptive-layout", severity: .major,
                              message: "m", file: "A.swift", line: 1)
        #expect(finding.confidence == .high)
    }

    @Test func gateFiltersBelowTheConfiguredConfidence() throws {
        let policy = try JSONDecoder().decode(GatePolicy.self,
            from: Data(#"{"minConfidence":"high"}"#.utf8))
        #expect(policy.minConfidence == "high")
    }
}
```

- [x] **Step 2: Run it and confirm it fails**

Run: `swift test --filter Confidence`
Expected: FAIL — no `Confidence` type, no `confidence` property.

- [x] **Step 3: Implement**

Add to `Sources/foldready/Finding.swift`:

```swift
/// How sure the audit is that a finding is real, independent of how bad it would be if true.
///
/// Severity is "how bad if true"; confidence is "how sure we are". They are separate because
/// a context-dependent signal can be severe and uncertain at once, and a team should be able
/// to fail a build on the certain ones without silencing the rest.
enum Confidence: String, Comparable, Codable, Sendable {
    case high
    case medium
    case low

    private var order: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    static func < (lhs: Confidence, rhs: Confidence) -> Bool { lhs.order > rhs.order }
}
```

Add `let confidence: Confidence` to `Finding`, and an initialiser parameter
`confidence: Confidence = .high` so existing call sites keep compiling with the strongest
claim; each check then sets its level explicitly in later tasks.

- [x] **Step 4: Run the tests and confirm they pass**

Run: `swift test --filter Confidence`
Expected: PASS. Then `swift test` — the whole suite must still pass.

- [x] **Step 5: Commit**

```bash
git add Sources/foldready/Finding.swift Tests/foldreadyTests/ConfidenceTests.swift
git commit -m "feat: give every finding a confidence level"
```

---

## Task 3: Checks read lexed files

**Files:**
- Modify: `Sources/foldready/AuditEngine.swift`
- Modify: `Sources/foldready/Exclusions.swift`
- Test: `Tests/foldreadyTests/LexerTests.swift` (add a case)

**Interfaces:**
- Consumes: `LexedFile`, `SwiftLexer.lex` from Task 1.
- Produces: `AuditEngine.run` lexes each UI file once and every check consumes `[LexedFile]`;
  `Exclusions.previewLines(in:)` is deleted.

- [x] **Step 1: Write the failing test**

Add to `LexerTests.swift`:

```swift
@Suite("Lexed checks")
struct LexedCheckTests {

    @Test func aSymbolOnlyInACommentDoesNotScore() {
        let root = tempTree()
        writeTree(["App/View.swift": """
        import SwiftUI
        // UIScreen.main.bounds
        struct View1: View { var body: some View { Text("x") } }
        """], in: root)
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(!result.findings.contains { $0.message.contains("UIScreen.main.bounds") })
    }
}
```

Reuse the `tempTree`/`writeTree` helpers from `DuoSurfaceTests.swift` (they are file-private;
copy them into `LexerTests.swift` or promote them to a small shared test helper file).

- [x] **Step 2: Run it and confirm it fails**

Run: `swift test --filter LexedCheckTests`
Expected: FAIL — the comment still produces a finding.

- [x] **Step 3: Implement**

In `AuditEngine.run`, after `let uiFiles = allSwift.filter { Exclusions.isUIFile($0) }`, add:

```swift
let lexed = uiFiles.map { SwiftLexer.lex($0) }
let scorable = lexed.filter { !$0.failed }
```

Change each check signature from `uiFiles: [FileContent]` to `lexed: [LexedFile]` and replace
line loops with `for line in file.lines { guard !file.isPreview(line: line.number) else { continue } ... }`,
matching on `line.code`. Delete `Exclusions.previewLines(in:)` and its call sites. Report the
failed count: add `failedFiles: Int` to `AuditStats` and set it from `lexed.count - scorable.count`,
so an unlexable file is visible rather than silently clean.

- [x] **Step 4: Run the full suite and confirm it passes**

Run: `swift test`
Expected: PASS. The golden fixture may shift; that is Task 7's job.

- [x] **Step 5: Surface the unlexable count**

The spec's `File that fails to lex` scenario requires the count to be stated. It already
appears in `stats`, but the human report must show it too. Add to `HTMLReport`'s summary cards
a row `Files the lexer could not read` shown only when `stats.failedFiles > 0`, and add a test
asserting that a tree containing an unterminated block comment produces a report whose HTML
contains the failed count, and whose audit produces no finding for the affected file.

Run: `swift test`
Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add Sources/foldready/AuditEngine.swift Sources/foldready/Exclusions.swift Sources/foldready/HTMLReport.swift Tests/foldreadyTests/LexerTests.swift
git commit -m "feat: score lexed lines, and report files the lexer could not finish"
```

---

## Task 4: Interface idiom and orientation as scored checks

**Files:**
- Modify: `Sources/foldready/AuditEngine.swift`
- Modify: `Sources/foldready/Reference.swift`
- Modify: `Sources/foldready/Exclusions.swift`
- Test: `Tests/foldreadyTests/IdiomOrientationTests.swift`

**Interfaces:**
- Consumes: `[LexedFile]` from Task 3, `[FileContent]` plists.
- Produces: checks `idiom` (baseWeight 0.10) and `orientation` (baseWeight 0.10); the
  `userInterfaceIdiom`/`interfaceOrientation` findings move off `adaptive-geometry`;
  `adaptive-geometry` baseWeight becomes 0.15.

- [x] **Step 1: Write the failing tests**

```swift
import Testing
import Foundation
@testable import foldready

@Suite("Idiom and orientation")
struct IdiomOrientationTests {

    @Test func idiomBranchingIsItsOwnCheck() {
        let root = tempTree()
        writeTree(["App/View.swift": """
        import UIKit
        let i = UIDevice.current.userInterfaceIdiom
        """], in: root)
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(result.findings.contains { $0.check == "idiom" })
        #expect(!result.findings.contains { $0.check == "adaptive-geometry"
            && $0.message.contains("idiom") })
    }

    @Test func portraitOnlyPlistIsReportedByTheOrientationCheck() {
        let root = tempTree()
        writeTree(["App/Info.plist": """
        <key>UISupportedInterfaceOrientations</key>
        <array><string>UIInterfaceOrientationPortrait</string></array>
        """, "App/View.swift": "import SwiftUI\nstruct V: View { var body: some View { Text(\"x\") } }\n"],
            in: root)
        let result = AuditEngine.run(root: root, appName: "App")
        let finding = result.findings.first { $0.check == "orientation" }
        #expect(finding?.file == "App/Info.plist")
    }

    @Test func aPortraitCapablePlistProducesNoOrientationFinding() {
        let root = tempTree()
        writeTree(["App/Info.plist": """
        <key>UISupportedInterfaceOrientations</key>
        <array>
          <string>UIInterfaceOrientationPortrait</string>
          <string>UIInterfaceOrientationLandscapeLeft</string>
        </array>
        """, "App/View.swift": "import SwiftUI\nstruct V: View { var body: some View { Text(\"x\") } }\n"],
            in: root)
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(!result.findings.contains { $0.check == "orientation" })
    }
}
```

- [x] **Step 2: Run them and confirm they fail**

Run: `swift test --filter IdiomOrientation`
Expected: FAIL — no `idiom` or `orientation` check exists.

- [x] **Step 3: Implement**

Add to `Reference.swift`:

```swift
/// Interface idiom: Apple directs apps to branch on size class rather than idiom.
static let interfaceIdiom =
    "https://developer.apple.com/documentation/uikit/uidevice/userinterfaceidiom"

/// Supported interface orientations, the Info.plist key that locks an app to a shape.
static let interfaceOrientations =
    "https://developer.apple.com/documentation/bundleresources/information-property-list/uisupportedinterfaceorientations"
```

Add `static func orientationLock(in plist: String) -> Bool` to `Exclusions`: true when a
`UISupportedInterfaceOrientations` array contains only portrait values.

In `AuditEngine`, remove the idiom/orientation branch from `adaptiveGeometry`, set its
`baseWeight` to 0.15, and add:

```swift
private static func idiom(lexed: [LexedFile]) -> CheckResult { ... }
private static func orientation(lexed: [LexedFile], plists: [FileContent]) -> CheckResult { ... }
```

`idiom` scores a file clean when it does not branch on `userInterfaceIdiom`, and emits a
`minor` finding at `confidence: .medium` when it does. `orientation` reports a locked plist as
`major` at `confidence: .high` with the plist path, and is `nil` (not applicable) when no plist
declares orientations. Append both to the results array.

- [x] **Step 4: Run the suite and confirm it passes**

Run: `swift test --filter IdiomOrientation` then `swift test`
Expected: PASS, and `adaptive-geometry` no longer emits idiom findings.

- [x] **Step 5: Commit**

```bash
git add Sources/foldready/AuditEngine.swift Sources/foldready/Reference.swift Sources/foldready/Exclusions.swift Tests/foldreadyTests/IdiomOrientationTests.swift
git commit -m "feat: score interface idiom and orientation, including the plist lock"
```

---

## Task 5: Configurable exclusions, reported by reason

**Files:**
- Modify: `Sources/foldready/Exclusions.swift`
- Modify: `Sources/foldready/Gate/Policy.swift`
- Modify: `Sources/foldready/AuditEngine.swift`
- Modify: `Sources/foldready/main.swift`
- Test: `Tests/foldreadyTests/ExclusionsTests.swift`

**Interfaces:**
- Consumes: `GatePolicy` (existing).
- Produces: `GatePolicy.exclude: [String]?`, `GatePolicy.include: [String]?`;
  `ExclusionReport { tests, vendored, generated, byConfig: Int }` carried on `AuditStats`;
  `AuditEngine.run(root:appName:screenshots:policy:)`.

- [x] **Step 1: Write the failing tests**

```swift
import Testing
import Foundation
@testable import foldready

@Suite("Exclusions")
struct ExclusionsTests {

    @Test func configIncludeForcesAFileBackIntoScope() {
        let root = tempTree()
        writeTree(["App/Generated.generated.swift":
            "import SwiftUI\nlet s = UIScreen.main.bounds\n"], in: root)
        let without = AuditEngine.run(root: root, appName: "App")
        #expect(!without.findings.contains { $0.file == "App/Generated.generated.swift" })

        var policy = GatePolicy.empty
        policy.include = ["App/Generated.generated.swift"]
        let with = AuditEngine.run(root: root, appName: "App", policy: policy)
        #expect(with.findings.contains { $0.file == "App/Generated.generated.swift" })
    }

    @Test func configExcludeDropsAShippingFile() {
        let root = tempTree()
        writeTree(["App/View.swift": "import SwiftUI\nlet s = UIScreen.main.bounds\n"], in: root)
        var policy = GatePolicy.empty
        policy.exclude = ["App/View.swift"]
        let result = AuditEngine.run(root: root, appName: "App", policy: policy)
        #expect(result.stats.exclusions.byConfig == 1)
    }
}
```

- [x] **Step 2: Run them and confirm they fail**

Run: `swift test --filter ExclusionsTests`
Expected: FAIL — `GatePolicy` has no `exclude`/`include`, `run` has no `policy:`.

- [x] **Step 3: Implement**

- `GatePolicy`: add `var exclude: [String]?` and `var include: [String]?` (both `convertFromSnakeCase`
  friendly).
- `Exclusions`: add `static func isExcludedPath(_ path: String, policy: GatePolicy) -> ExclusionReason?`
  returning `.tests`, `.vendored`, `.generated`, `.config`, or nil; keep the old single-argument
  form for the default set.
- `AuditStats`: add `let exclusions: ExclusionReport` with the four counts.
- `AuditEngine.run(root:appName:screenshots:policy: GatePolicy = .empty)`: load the policy at the
  root when the caller passes none, and thread it into `isUIFile`.
- `main.swift`: load `.foldready.json` from the audited root before the audit and pass it in, for
  the audit, verify and gate paths.

- [x] **Step 4: Run the suite and confirm it passes**

Run: `swift test`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add Sources/foldready/Exclusions.swift Sources/foldready/Gate/Policy.swift Sources/foldready/AuditEngine.swift Sources/foldready/main.swift Tests/foldreadyTests/ExclusionsTests.swift
git commit -m "feat: exclude by configuration and report every exclusion by reason"
```

---

## Task 6: The gate acts on confidence

**Files:**
- Modify: `Sources/foldready/Gate/Policy.swift`
- Test: `Tests/foldreadyTests/GateTests.swift`

**Interfaces:**
- Consumes: `Confidence` from Task 2, `minConfidence` (existing but unread).
- Produces: gate rules filter findings below the configured confidence; a `confidence`
  rule result names how many were ignored.

- [x] **Step 1: Write the failing test**

```swift
@Test func minConfidenceIgnoresLowerConfidenceFindings() throws {
    // A medium-confidence idiom finding must not fail a gate configured for high only.
    let root = tempTree()
    writeTree(["App/View.swift":
        "import UIKit\nlet i = UIDevice.current.userInterfaceIdiom\n"], in: root)
    var policy = GatePolicy.empty
    policy.maxSeverity = .minor
    policy.minConfidence = "high"
    let result = AuditEngine.run(root: root, appName: "App", policy: policy)
    let evaluated = Gate.evaluate(result: result, policy: policy, baseline: nil)
    #expect(evaluated.passed)
}
```

- [x] **Step 2: Run it and confirm it fails**

Run: `swift test --filter minConfidence`
Expected: FAIL — the medium finding still trips `maxSeverity`.

- [x] **Step 3: Implement**

In the severity rule, filter `result.findings` by
`Confidence(rawValue: policy.minConfidence ?? "") ?? .low` before comparing severity, and
include the ignored count in the rule's `actual` string.

- [x] **Step 4: Run the suite and confirm it passes**

Run: `swift test --filter Gate`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add Sources/foldready/Gate/Policy.swift Tests/foldreadyTests/GateTests.swift
git commit -m "feat: let the gate act only on findings at the configured confidence"
```

---

## Task 7: Contract v5 — versions, reports, docs, golden

**Files:**
- Modify: `Sources/foldready/Version.swift`
- Modify: `Sources/foldready/JSONReport.swift`
- Modify: `Sources/foldready/HTMLReport.swift`
- Modify: `Tests/Fixtures/ContractApp/` (add an idiom branch and a portrait plist)
- Modify: `Tests/Fixtures/contract-golden.json` (regenerate)
- Modify: `docs/result-contract.md`
- Modify: `README.md`
- Modify: `docs/roadmap.md`

**Interfaces:**
- Produces: `schema_version` 5; findings carry `confidence`; checks include `idiom` and
  `orientation`; stats include exclusion reasons and failed files.

- [x] **Step 1: Bump the version and extend the fixture**

Set `resultSchemaVersion = 5` and `foldreadyVersion = "0.5.0"`. Add a `userInterfaceIdiom`
branch to `Tests/Fixtures/ContractApp/Feed.swift`, or a portrait-only plist, so the v5 golden
exercises the new keys.

- [x] **Step 2: Emit the new fields**

In `JSONReport.payload`, add `"confidence": f.confidence.rawValue` to each finding dict, and
the exclusion/failed counts to `stats`. In `HTMLReport`, render confidence beside severity and
state the exclusion breakdown.

- [x] **Step 3: Make the gate name a baseline from a different contract**

The `Score changes are declared` requirement has a second scenario: when a team upgrades, the
gate must report that the baseline was produced by a different contract version. `Baseline`
already loads `schemaVersion`; nothing compares it. Add, in `Gate.evaluate`, a check that emits
a rule result `baseline-contract` which fails only when `baseline.schemaVersion != resultSchemaVersion`,
naming both versions in `expected`/`actual`. Write the test first: a baseline JSON written with
`schema_version: 4` against a v5 audit must produce a failing `baseline-contract` rule whose
`actual` names 4; a matching baseline must pass.

Run: `swift test --filter baselineContract`
Expected: FAIL, then PASS after the implementation.

- [x] **Step 4: Regenerate the golden and update the docs**

Run: `python3 Scripts/contract-golden.py --update`
Then update `docs/result-contract.md` (version 5, the two checks, the confidence field, the
exclusion reasons, the `baseline-contract` rule, a `## Version 5` section stating v4 baselines
are not comparable), the README engine paragraph, and `docs/roadmap.md` Phase 3.

- [x] **Step 5: Run the full check**

Run: `./Scripts/check.sh`
Expected: `==> all checks passed`.

- [x] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: contract v5 — lexed attribution, idiom and orientation checks, confidence"
```

---

## Task 8: Record the change and close it out

**Files:**
- Modify: `openspec/changes/audit-fidelity/tasks.md` (this file)
- Modify: `docs/roadmap.md`

- [x] **Step 1: Tick the tasks** as each completes.
- [x] **Step 2: Note the deferred work.** Add a line stating declaration-scope attribution is a
  follow-up and that the index regeneration is issue #6.
- [x] **Step 3: Run `openspec validate audit-fidelity --strict`** and `./Scripts/check.sh`.
- [x] **Step 4: Commit.**

```bash
git add openspec/changes/audit-fidelity/tasks.md docs/roadmap.md
git commit -m "openspec: record audit-fidelity progress and its deferred scope"
```

---

## Deferred scope

This change is closed at contract v5. The following work is deliberately not done here and is
recorded so the repository does not read as more complete than it is.

- **Declaration-scope attribution.** What shipped is a lexer, not a parser. It guarantees a
  match inside a comment or the literal text of a string never reaches a check, and that a file
  it cannot finish is reported as unlexable rather than scored clean. It cannot yet tell that a
  match sits inside a real type body versus a nested test helper or a debug-only branch. A real
  Swift syntax tree (declaration-scope attribution) is a deferred follow-up, deliberately out of
  this change's scope.
- **Index re-audit under v5 (issue #6).** The published index in `web/lib/index-data.ts` still
  carries the older contract's per-app check keys and stays labelled historical on the site. The
  re-audit needs the twenty audited app checkouts, which live outside this repository and are
  handed to the scanner as arguments; the audited results are then turned into the published
  index by `Scripts/generate-index.py`. It is tracked as issue #6 and is not a code gap.
- **Objective-C and build settings.** The scanner reads `.swift` and `.plist` files only; a
  `.m` or `.h` target is not analysed at all rather than analysed textually. Resolving build
  settings or the linked SDK is not attempted; that remains a runtime question for the Duo
  simulator work in Phase 4.

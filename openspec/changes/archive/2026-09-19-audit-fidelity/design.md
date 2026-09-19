## Context

The gate in `readiness-gate` lets a team fail a build on a FoldReady score. That raises the
bar on the score itself, and the score is currently produced by line-based text matching:
`line.contains("UIScreen.main.bounds")`, `line.contains("userInterfaceIdiom")`, a regex over
`.frame(width:height:)`. Text matching cannot tell a flagged symbol in shipping code from the
same symbol in a comment, a string literal, a `#Preview` block, a test fixture, or a vendored
dependency.

The repository already measured this. Three findings on the twenty-app corpus were noise of
exactly that kind: one `UIScreen.main` was actually `XCUIScreen.main` inside a snapshot
helper, six occurrences sat inside preview blocks, and 92% of the frame findings were
icon-sized controls that should not reflow. `Exclusions.swift` grew two workarounds for it: a
path/suffix exclusion list, and `previewLines(in:)`, a brace counter that starts from a line
containing `#Preview` and hopes no brace appears inside a string on the way.

The check coverage is narrower than Apple's own list. The WWDC26 session "Modernize your UIKit
app" names four audit areas for resizability: scene lifecycle, main-screen references,
interface-idiom checks, and interface-orientation checks. FoldReady scores the first two as
first-class checks. Idiom and orientation exist only as a small penalty inside the
`adaptive-geometry` check, where the finding key is `adaptive-geometry` and the check cannot
distinguish "branches on idiom" from "reads no size classes at all" in the score. The plists
are not read for orientation at all, although `UISupportedInterfaceOrientations` is where an
app actually locks itself to portrait.

Three facts constrain the work:

1. The proposal names "a Swift syntax parsing dependency". That is the obvious way to get real
   attribution, but `swift-syntax` is a large package whose version is tied to the toolchain,
   it slows the first build, and it would restructure every check at once. The demonstrated
   false positives do not need an AST to fix.
2. `GatePolicy` already declares `minConfidence: String?`, with a comment naming this change,
   and nothing reads it. The configuration surface for confidence exists; the per-finding data
   does not.
3. `Scripts/check.sh` enforces that every scored check cites Apple documentation, and that
   `Tests/Fixtures/contract-golden.json` matches the audit of `Tests/Fixtures/ContractApp`. Any
   change to attribution or weights changes that golden and the published index.

The repository currently reports `resultSchemaVersion = 4` and `foldreadyVersion = "0.4.0"`.

## Goals / Non-Goals

**Goals:**

- Make a comment, a string literal, or a preview block incapable of lowering a score.
- Make an unlexable file visible as unlexable instead of silently clean.
- Promote interface-idiom and interface-orientation to first-class scored checks with their own
  keys and Apple references, and read the orientation keys from Info.plist.
- Give every finding a confidence level, and let the gate act only on findings at or above a
  configured confidence.
- Keep the exclusions configurable in the audited repository and reported by reason.

**Non-Goals:**

- A Swift syntax tree. This change ships a lexer, and the spec is rewritten to say so rather
  than to claim a parser it does not have. Declaration-scope attribution (is this match inside
  a real type body or a nested test helper) is recorded as a follow-up, not built here.
- Objective-C. The scanner reads `.swift` and `.plist` files only, so a `.m` or `.h` target
  is not analysed at all rather than analysed textually.
- Making the audit resolve build settings or the linked SDK. That stays a runtime question.
- Re-auditing the public index in this change. The index regeneration is blocked on the twenty
  app checkouts, which live outside this repository; it is tracked as issue #6.

## Decisions

**A lexer, not a parser.** The change adds `Sources/foldready/SwiftLexer.swift`: a single pass
over a `.swift` file that drops `//` comments, nested `/* */` block comments, and the literal
text of `"..."`, `"""..."""` and `#"..."#` strings, while keeping string interpolation
(`\(...)`) because that is real code. It emits one `LexedLine` per source line carrying the
code with comment and string contents blanked to spaces, plus the brace depth at that line.
Line numbers and column offsets survive, so a finding still points at the right `file:line`. A
file whose lexer reaches EOF inside an unterminated block comment or raw string is marked
`failed` and excluded from scoring, and the count of failed files is reported. This kills the
two demonstrated false-positive classes without a dependency.

**The spec's "syntax tree" wording is corrected.** The `audit/checks` requirement currently
reads "Occurrences MUST be attributed using a Swift syntax tree rather than line matching."
That overstates what ships. The requirement is rewritten to the behaviour that is actually
true and testable: a match inside a comment, a string literal, or a preview block is not
scored; a file that cannot be lexed is reported and excluded rather than scored clean. The
proposal's "Package.swift: a Swift syntax parsing dependency" impact line is removed for the
same reason.

**`previewLines` becomes lexer-backed scope tracking.** `Exclusions.previewLines` disappears.
The lexer records, from the lexed stream, the line ranges of `#Preview { ... }` macro bodies
and `PreviewProvider` conformance bodies, so a brace inside a string can no longer break the
matcher or leak a preview's contents into the score. Existing callers consume the lexed
version.

**Confidence is a second axis, not a replacement for severity.** `Finding` gains
`confidence: Confidence` with `high`, `medium` and `low`. Severity stays "how bad if true";
confidence is "how sure the audit is". `high` is a lexed occurrence in a shipping file whose
meaning does not depend on unseen context: `UIScreen.main.bounds`, a literal frame above
`iconPointLimit`, a plist orientation lock. `medium` is a real
match whose interpretation depends on context the audit cannot see: a `userInterfaceIdiom`
branch may be deliberate, a custom bar may be intentional. `low` is the floor a gate falls back
to when no confidence is configured, and the level reserved for heuristic matches that survive
without being scored. Keeping severity preserves the report's existing styling and the `maxSeverity` rule.

**Exclusions move into `.foldready.json`, which the audit now reads.** The spec requires the
exclusions to be configurable in the audited repository and reported. The policy file the gate
already reads is the natural home: two new optional keys, `exclude` and `include`, add or
force-include path patterns beside the built-in defaults. This makes the audit depend on the
policy file, not only the gate, so `AuditEngine.run` gains a configuration parameter and each
caller (`main.swift`, `Scripts/contract-golden.py`'s invocation, the action) passes the
repository's policy when one exists. Reporting becomes per-reason: the result states how many
files were dropped as tests, as vendored dependencies, as generated code, and by configuration,
instead of a single `excluded_files` count.

**The weights are redistributed, not inflated.** `adaptive-geometry` drops from `0.35` to
`0.15` and keeps its size-class coverage half. Interface idiom becomes the check `idiom` at
`0.10` and interface orientation becomes the check `orientation` at `0.10`. The applicable
total stays `1.0`: `adaptive-layout 0.35`, `navigation 0.20`, `adaptive-geometry 0.15`,
`build-toolchain 0.10`, `state 0.10`, `idiom 0.10`, `orientation 0.10`, plus `captured-layout
0.20` when screenshots are supplied. The split reuses weight the old combined check held
rather than raising the denominator for every app.

**The contract moves to v5 and the release to 0.5.0.** Two scored keys change, findings gain a
field the gate acts on, and every published score shifts. Adding an optional field alone would
not normally bump the version, but `minConfidence` changing gate behaviour is a meaning change,
and v4 baselines are not comparable to v5 scores. `resultSchemaVersion` becomes `5` and
`foldreadyVersion` becomes `"0.5.0"`. The release notes name the affected checks, as the
`audit/checks` requirement demands.

**The gate reads `minConfidence` at last.** The policy key that has been parsed and ignored
since `readiness-gate` starts filtering: a finding below the configured confidence appears in
the report, with its confidence, and does not fail the build. Severity rules are unchanged.

## Risks / Trade-offs

**A lexer is not a parser, and the change says so.** It cannot tell that a match sits in a test
helper nested inside an otherwise shipping file, and it does not resolve declaration scope. The
mitigation is honesty plus scope: the design and the spec name the limit, the follow-up issue
carries the declaration-scope work, and the matched-line rules stay conservative.

**A wrong lexer is worse than no lexer.** An unterminated block comment or a raw-string
delimiter the lexer mis-reads could blank out real code and hide a finding. The mitigation is
that a file the lexer cannot finish is marked `failed` and excluded from scoring rather than
scored clean, plus a test per lexer construct (line comment, nested block comment, single-line
string, multiline string, raw string, interpolation, escaped quote) asserting the code that
survives and the code that is dropped.

**The audit now reads a file the audited repository controls.** Feeding a repository-supplied
`exclude` list to the audit lets a team exclude its own worst files by configuration. The
mitigation is that exclusions are reported per reason and by path count in the result, so an
aggressive list is visible in the report and in the gate output rather than silent.

**Two checks where one existed moves scores that a reader may have just gotten used to.** The
index already carries a historical label and issue #6 tracks its regeneration. The README and
`docs/result-contract.md` state the v5 incompatibility, and the gate keeps printing the baseline
version so a mismatch is visible.

**Confidence is a judgement encoded as an enum.** The rule for what is `high` is written down
in the design and enforced by tests, but a future check author can still pick the wrong level.
The mitigation is that `minConfidence` is opt-in: with no policy key, the gate behaves exactly
as it does today, so a mis-set confidence costs nothing until a team chooses to act on it.

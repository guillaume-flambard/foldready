## Why

The gate in `readiness-gate` lets a team fail a build on a FoldReady score. That raises
the bar on the score itself: today it comes from line-based text matching over `.swift`
files, which cannot tell a hardcoded frame in shipping code from one in a `#Preview`, a
test fixture, or a vendored dependency. A false positive that turns a build red is the
fastest way to get the tool removed.

The check coverage is also narrower than Apple's own list. The WWDC26 session "Modernize
your UIKit app" names four audit areas for resizability: scene lifecycle, main-screen
references, interface-idiom checks, and interface-orientation checks. FoldReady scores the
first two as first-class checks; idiom and orientation exist only as a small penalty
buried inside the adaptive-layout check, invisible in the report and absent from the
plists, where `UISupportedInterfaceOrientations` actually locks an app down.

## What Changes

- Swift files are lexed rather than matched line by line, so a flagged symbol inside a
  comment or the literal text of a string cannot be scored. A lexer, not a syntax tree:
  declaration-scope attribution is a follow-up, and the specs say so.
- Preview blocks, test targets, vendored dependencies, and generated code are excluded
  from scoring by default, configurable through `.foldready.json`, and reported by reason.
- Interface idiom and interface orientation become first-class scored checks with their
  own keys and references, including the plist orientation keys, instead of a hidden
  penalty.
- Findings gain a confidence level, and the gate can be configured to act only on
  high-confidence findings.

## Capabilities

### New Capabilities

- `audit/checks`: what the audit measures, how occurrences are attributed, and which code
  is excluded from scoring.

### Modified Capabilities

<!-- audit/result-contract gains a confidence field once readiness-gate lands; recorded
     here so the version bump is not forgotten. -->

## Impact

- `Sources/foldready/AuditEngine.swift`: lexing layer, two new checks, plist orientation read,
  exclusion rules.
- `Sources/foldready/SwiftLexer.swift`: new. A dependency-free lexer; no `swift-syntax`.
- `Sources/foldready/Exclusions.swift`, `Finding.swift`, `Gate/Policy.swift`, `JSONReport.swift`,
  `HTMLReport.swift`, `Version.swift`: confidence, exclusions by reason, `minConfidence` read,
  contract v5.
- Scores change for every app in the index, so the published data must be regenerated under v5
  and the result contract version bumped. The regeneration is blocked on the external corpus
  and is tracked as issue #6.

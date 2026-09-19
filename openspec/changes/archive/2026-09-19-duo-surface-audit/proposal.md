## Why

Apple's [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)
names interaction surfaces the scanner does not read at all. The audit today covers
adaptive layout, geometry, navigation and state preservation, and it already detects
`userInterfaceIdiom` and `interfaceOrientation` in `AuditEngine.swift`. It has no notion of
reserved regions, arrangement views, vertical bars, or camera-facing direction, although
Apple describes all four as things a custom-layout app has to handle.

The same page states a hard requirement that is checkable from source on this machine,
today, with no simulator: building with Xcode 27.1 or later is what makes an app use all of
the inner display. Below that, the app does not extend under the status bar and camera. The
Duo simulator in Device Hub needs Xcode 27.1 as well, so until it ships the only Duo facts
FoldReady can verify are static, and this one is static.

The window is short. Preorders open 16 October, availability opens 23 October. Between the
launch and the first Duo-specific buyer conversation, a report that says "not covered" next
to four named Apple surfaces is a weaker artefact than one that lists them with the runtime
check that would settle each.

## What Changes

- The audit recognizes four Duo interaction surfaces as advisory findings: reserved regions
  (division and occlusion), arrangement views, vertical bars, and camera direction.
- Advisory findings carry a file, a line, an Apple reference and the runtime check that
  would confirm or dismiss them. They never change the score or the verdict.
- A scored `build-toolchain` check reads the project file's `objectVersion` and
  `LastUpgradeCheck` and reports the Xcode 27.1 build floor Apple documents.
- The runtime checklist gains the surface checks that stayed advisory, so the human review
  deliverable and the scanner report list the same open questions.
- The result contract moves to v4: a new advisory array, a new build block, and one new
  scored check key.

## Capabilities

### New Capabilities

- `audit/duo-surfaces`: which iPhone Duo surfaces the audit recognizes, how they are
  reported, and why they never move the score.
- `audit/build-floor`: the Xcode 27.1 build requirement as a source-readable signal.

### Modified Capabilities

- `audit/result-contract`: the payload gains an advisory array and a build block, and the
  version moves to 4.
- `audit/checks`: two check registry entries and their references.

## Impact

- `Sources/foldready/AuditEngine.swift`: four surface detectors plus the build-toolchain
  check.
- `Sources/foldready/Reference.swift`: Apple references for the new checks.
- `Sources/foldready/JSONReport.swift`, `Sources/foldready/HTMLReport.swift`: the advisory
  section and the build block.
- `Sources/foldready/Version.swift`: `resultSchemaVersion` to 4.
- `docs/result-contract.md`: version 4, the advisory array, the build block.
- `Tests/Fixtures/contract-golden.json` and the contract tests: the golden payload changes.
- `docs/readiness-review.md`: the runtime matrix references the same surface list.
- Published baselines in the index carry a new check key, so they are rewritten once,
  deliberately, under v4.

## 1. Project toolchain signal

- [x] 1.1 Add a `project.pbxproj` reader that extracts `objectVersion` and every
      `LastUpgradeCheck` value, with the file that carries it.
- [x] 1.2 Add the `build-toolchain` check to the check registry with its weight and its
      Apple reference, and record the Xcode 27.1 generation as a named constant.
- [x] 1.3 Write the finding text around the display consequence Apple documents, and state
      that `LastUpgradeCheck` can be stale.
- [x] 1.4 Handle the no-project and no-value paths without a score penalty.
- [x] 1.5 Tests: at the floor, below the floor, stale value present, no project file.

## 2. Surface detectors

- [x] 2.1 Reserved regions: match container-relative geometry that never queries
      `reservedRegions`, for SwiftUI and UIKit.
- [x] 2.2 Arrangement views: match hand-rolled multi-pane layouts and suggest
      `ArrangementView` or `UIArrangementViewController`.
- [x] 2.3 Vertical bars: match direct `UIToolbar`, `UINavigationBar` and `UITabBar`
      construction, and bar items declared with a title and no icon.
- [x] 2.4 Camera direction: match capture configuration that does not consult the camera
      position or the active display.
- [x] 2.5 Cap each surface at one finding per file and record the collapsed occurrence count.
- [x] 2.6 Tests, one fixture per surface plus a negative fixture that must produce nothing.

## 3. Contract v4

- [x] 3.1 Add the `advisory` array and the `build` block to `JSONReport.swift`, keeping
      `checks` and the score computation untouched by advisory findings.
- [x] 3.2 Add the Duo surfaces section to `HTMLReport.swift`, separate from the scored
      checks and labelled as questions rather than defects.
- [x] 3.3 Set `resultSchemaVersion` to 4 in `Version.swift` and update
      `docs/result-contract.md` with the version, the advisory array, the build block and a
      statement of what an advisory finding is not.
- [x] 3.4 Regenerate `Tests/Fixtures/contract-golden.json` and update the contract tests,
      including the byte-identical test across working directories.
- [ ] 3.5 Regenerate the six demo reports and rewrite the published baselines once,
      deliberately, and record the new scores in the change. BLOCKED (needs the audited app checkouts): the 20 apps behind `web/lib/index-data.ts` live outside this repository and are passed to `Scripts/build-index.sh` as arguments, so the index cannot be regenerated from this tree. The published index still carries v3 checks keys (`nav`, `layout`, `geometry`, `state`, no `build-toolchain`) and is labelled historical until the source apps are re-audited. No `*.foldready-baseline.json` file exists in the repository to rewrite. Re-run `Scripts/build-index.sh <repo1>...` once the corpus is available, then record the new scores here.

## 4. Runtime checklist alignment

- [x] 4.1 Feed the surface names into the list of runtime checks still needed, using one
      vocabulary shared with `docs/readiness-review.md`.
- [x] 4.2 Extend the runtime matrix in `docs/readiness-review.md` with a camera and
      reserved-regions line so the free report and the paid deliverable agree.
- [x] 4.3 Add a `Scripts/check.sh` rule that fails when a surface detector has no Apple
      reference.

## 5. Documentation

- [x] 5.1 Rewrite the README `Apple announcements` section against the current Apple pages,
      with the checked date, the six technology talks, the design kits and the workshops,
      and the Xcode 27.1 build and simulator requirements.
- [x] 5.2 Document the new checks in the README engine paragraph, keeping the standing
      caveat that a source scan cannot confirm a defect.
- [x] 5.3 State the contract v4 baseline rewrite in the README CI section.

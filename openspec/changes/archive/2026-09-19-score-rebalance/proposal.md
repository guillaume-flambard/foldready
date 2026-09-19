## Why

The score was designed before anyone had measured it. Twenty well-known open-source iOS
apps were audited on 2026-09-06 (IceCubesApp, isowords, Home Assistant, Bitwarden,
Element, OpenFind, MovieSwiftUI, Delta Chat, Signal, NetNewsWire, Firefox, Dime, Eigen,
WordPress, DuckDuckGo, Wikipedia, Kickstarter, Open Food Facts, Nextcloud,
MochiDiffusion). The corpus says the instrument does not work:

- **The score does not discriminate.** 49 to 92, median 61, standard deviation 10.7. Two
  A grades, nine B, nine C, no D, no F. Eighteen of twenty apps sit inside a 27-point
  band, so the ranking tells almost nobody anything.
- **The heaviest check is a constant.** `navigation`, at weight 0.25, scores exactly 40
  for eighteen of twenty apps. It reports that an app does not use `NavigationSplitView`,
  which is true of nearly every shipping iOS app today. A quarter of the score moves
  everyone down by the same amount and separates no one.
- **`state` has two values.** 30 or 70, never 100; seventeen of twenty score exactly 70,
  the "there are view models" fallback. Weight 0.08 spent on almost no information.
- **The real discriminator is the framework ratio.** Correlation between the total and the
  SwiftUI share of files is +0.64, and `framework` has the widest spread of any check.
  So the score is largely a proxy for SwiftUI adoption, which is an architecture
  preference, not a readiness fact. Worse, it is measurably perverse: on the work-order
  fixture, adopting the UIScene lifecycle (which is not optional) added one UIKit file and
  dropped the check from 50 to 40. The tool penalised the required fix.
- **`adaptive-layout` saturates on large codebases.** Its score correlates +0.36 with file
  count and −0.45 with its own finding count. Signal scores 100 with 22 offending files;
  WordPress scores 98 with 119. The denominator is every Swift file, so a big app dilutes
  real problems to nothing, while Dime (94 files, 36 `UIScreen.main.bounds` reads) scores
  0. Separately, 92% of the frame findings across the corpus are icon-sized
  (<= 100pt in both dimensions): capsules, avatars, badges, spinners.

What the corpus also shows is where the information actually is: five well-known apps have
no scene lifecycle detected, and three have `UIRequiresFullScreen=true`. Those are binary,
verifiable, consequential facts, and today they are averaged into a number that reads as
"53 out of 100".

## What Changes

- **Blocking facts leave the average.** No scene lifecycle, and `UIRequiresFullScreen`,
  become a `blockers` list with a verdict, reported before the score. An app built against
  the iOS 27 SDK without the scene lifecycle does not launch; that is not a percentage.
- **The framework-ratio check is removed.** It measures an architecture preference, it
  dominates the ranking, and it punishes the one migration that is mandatory.
- **`navigation` becomes proportional** over the app's root navigation containers instead
  of a three-value ladder, so partial adoption is visible and the check can vary.
- **`adaptive-layout` is renormalised**: the denominator becomes the files that contain UI
  layout code, the numerator becomes offending files rather than raw occurrences, and the
  false-positive classes the corpus exposed are excluded (icon-sized frames, preview
  blocks, test and snapshot paths, and `XCUIScreen.main`, which the current pattern
  matches for lack of a left word boundary).
- **`state` becomes proportional** over the views that actually hold scroll or selection
  state.
- **Weights are reallocated** across the four checks that remain, and the grade bands are
  recalibrated against the corpus so that grades separate real differences.
- **The result contract goes to version 2.** Scoring changes invalidate committed
  baselines, which is exactly what the contract's own rules say must bump it.

## Capabilities

### New Capabilities

- `audit/scoring`: what the quality score measures, how each check is normalised, and the
  rule that keeps a check in the score at all.
- `audit/verdict`: blocking facts, how they are reported, and how they interact with the
  quality score and the gate.

## Impact

- `Sources/foldready/AuditEngine.swift`: check normalisation, removal of `framework`,
  exclusion rules, blockers.
- `Sources/foldready/JSONReport.swift`, `docs/result-contract.md`: contract v2, `blockers`,
  removal of the `framework` check key.
- `Sources/foldready/Gate/Policy.swift`: a policy can require the absence of blockers.
- `Sources/foldready/HTMLReport.swift`: blockers shown above the score.
- `Sources/foldready/Port/WorkOrder.swift`: blocking entries first.
- Committed baselines produced by contract v1 no longer compare; the gate must say so
  rather than silently comparing across scoring versions.
- `web/lib/data.ts` and the index: every published score changes.
- `audit-fidelity` keeps the syntax-tree work and the idiom/orientation checks; the
  false-positive exclusions it listed move here, because the renormalised
  `adaptive-layout` is meaningless without them.

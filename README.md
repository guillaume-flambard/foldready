# FoldReady

Free, local source analysis for iOS apps, plus scoped human readiness reviews for iPhone Duo.
The scanner identifies candidate issues, supports CI policies and prepares work orders.
It does not certify device compatibility. Scores and effort estimates are heuristics.

## Apple announcements, checked 18 September 2026

- [iPhone Duo](https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/) has 5.4-inch outer and 7.6-inch inner displays with the same aspect ratio, and ships with iOS 27.1. Preorders open Friday 16 October; availability opens Friday 23 October, with 28 more countries on 30 October. Split View puts two apps side by side on iPhone for the first time, including two windows of the same app.
- [Apple Developer](https://developer.apple.com/iphone-duo/) has the Xcode 27.1 beta available for download. Apple states that an app must be built with Xcode 27.1 or later to use all of the available screen space; in earlier versions it does not extend under the status bar and camera. The iPhone Duo simulator in Device Hub also requires Xcode 27.1, which Apple says is coming later this month.
- [Prepare your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo): existing apps run without recompilation; the linked SDK affects screen usage. Standard navigation adapts automatically and sidebar placement is optional. Apple calls out four surfaces for custom layouts: reserved regions for the fold and the cameras, arrangement views, bars that the system stacks vertically on the side of the display, and camera-facing direction when the active display changes. Apple directs apps away from `UIDevice.userInterfaceIdiom` and `UIInterfaceOrientation` for layout decisions.
- [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) is a dedicated HIG page, and Apple Design Resources now publishes [Figma and Sketch design kits](https://developer.apple.com/design/resources/).
- Six technology talks cover the platform: [design](https://developer.apple.com/videos/play/tech-talks/111466/), [preparation](https://developer.apple.com/videos/play/tech-talks/111461/), [bars](https://developer.apple.com/videos/play/tech-talks/111462/), [adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/), [multiple displays and scenes](https://developer.apple.com/videos/play/tech-talks/111464/) and [camera](https://developer.apple.com/videos/play/tech-talks/111465/). Apple runs iPhone Duo workshops worldwide.

## Product and offer

- **Free CLI:** source signals, optional screenshot heuristics, JSON/HTML reports, CI policies and work orders.
- **$349 human readiness review:** one app revision and up to three agreed critical journeys. Reviewed source findings, build/SDK assumptions, available screenshots reviewed in context, prioritized remediation and a Duo test checklist. One follow-up review within the same scope in 30 days.
- **Corrections and validation:** quoted after review, with explicit environments and acceptance criteria. A later Duo simulator pass is scoped separately, subject to tool availability and a buildable app. Physical-device testing is not included in the review.

Agree access, scope and delivery date before starting. No guaranteed App Store featuring,
blanket compatibility claim, or automatic launch-day promise. See [delivery scope](docs/readiness-review.md).

## Usage

An experimental XCTest continuity prototype now lives alongside the scanner. It compares
three synthetic journeys under real simulator rotation with an explicit test suite:

```sh
swift build
./.build/debug/foldready continuity Examples/continuity-demo/continuity-demo.xcodeproj
```

See the [experiment guide](docs/continuity-experiment.md), [timed benchmark protocol](docs/continuity-benchmark.md)
and [unpublished pilot brief](docs/continuity-pilot.md). Duo folding is explicitly unsupported.
Injected defects return exit code 2; human time savings and customer demand remain unvalidated.

```sh
swift build
./.build/debug/foldready <local-source-directory> --name App --json --open
./.build/debug/foldready gate <local-source-directory> --write-baseline
./.build/debug/foldready port <local-source-directory>   # review proposals first
./.build/debug/foldready verify <local-source-directory> --build
```

`port --apply` applies proposed edits. It no longer inserts optional sidebar placement.
The remaining automatic proposal removes `UIRequiresFullScreen`; review its relevance
before applying it. Structural changes are work orders for a developer or coding agent.
Static verification only reports whether source signals changed.

The engine checks adaptive layout, geometry, standard navigation, state preservation and the
Xcode build floor. The build floor reads `LastUpgradeCheck` from `project.pbxproj`: Apple
requires Xcode 27.1 or later to use all of the available screen space on iPhone Duo, and below
it the app does not extend under the status bar and camera. That value records the last Xcode
upgrade and can be stale, so a gap is a prompt to confirm the toolchain that actually builds
the app, not proof a shipped binary fails.

The report also raises advisory questions for the four Duo surfaces Apple names for custom
layouts: reserved regions (the fold and the cameras), arrangement views, bars the system stacks
vertically on the side, and camera direction when the active display changes. These are
questions, not defects: they never change the score or a gate verdict, and each one names the
runtime check that would settle it.

Potential lifecycle and full-screen opt-out blockers are reported separately. Source scans
cannot resolve every build setting, generated declaration or Objective-C implementation;
confirm potential blockers in the target build. The linked SDK is not inferred from the
source score. A legacy app's migration requirement is not proof its shipped binary fails.

With `--with-screenshots <directory>`, the report adds uniform-margin heuristics.
Margins may reflect intentional design or system compatibility presentation. They are
not proof of a hardcoded layout. `verify --build` captures one simulator launch screenshot,
prefers a Duo device type if installed, and records the selected device/runtime and linked
SDK in `capture.json`. It does not exercise poses, transitions or critical journeys.
Reports always carry a list of runtime checks still needed.

The older `Scripts/capture.sh` helper also captures a selected simulator, not a Duo test
matrix. Its device/runtime defaults are generic and may need local overrides.

## CI and result contract

[Contract v4](docs/result-contract.md) adds the scored build floor, so every weight shifted and
v3 scores are not comparable. Rewrite baselines deliberately after review. The Duo surface
questions sit in a separate `advisory` array outside the score: they cannot turn a gate red,
and an empty advisory list does not make a passing run. Existing website rankings and reports
are labelled historical until the source apps are re-audited.

Policy lives in `.foldready.json`; no policy means report-only:

```json
{
  "min_score": 60,
  "max_total_regression": 0,
  "no_regression_checks": ["adaptive-layout"],
  "baseline": ".foldready-baseline.json"
}
```

`forbid_blockers` can reject potential blockers pending human confirmation. It is not a
runtime launch assertion. Exit codes: 0 policy passed, 2 policy breach, 1 execution error.
The GitHub Action is defined in [action.yml](action.yml).

One line adds it to a workflow. Pin `@v0` to follow patches, or `@v0.4.0` to freeze:

```yaml
- uses: guillaume-flambard/foldready@v0
```

The action builds its own pinned source on a macOS runner, so the code that produces the
score is the code at the ref the workflow pinned. No policy file means report-only; add
`.foldready.json` and commit a baseline to make it fail the build.

## Development

```sh
./Scripts/check.sh
cd web
npm run dev
```

The Next.js site exports to `web/out`. Its design tokens are defined in
`design/ds-package/`; preserve that system when editing styles. Public website:
https://foldready.memolabs.dev. This repository change does not itself publish the site.

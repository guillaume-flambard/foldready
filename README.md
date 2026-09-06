# FoldReady

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

Readiness gate for iOS apps on a resizable canvas: score a source tree, fail the build
when it regresses, and hand the remaining work to the tool that should do it.
**Open source and independent** — the readiness check should not be a black box, and
every check cites the Apple source it is derived from.

`foldready <path>` runs 7 static checks and emits a 0-100 score with an HTML report, a
machine-readable [result contract](docs/result-contract.md) and an effort estimate.
`foldready gate <path>` enforces a readiness policy in CI. Xcode 27 ships Apple's own
app modernization agent skill, which edits the code with the build graph and the type
checker; FoldReady measures, gates and verifies, and writes that skill a work order.

## Checks

| Weight | Check | What it looks for |
|---|---|---|
| 25% | Adaptive navigation / sidebar | `NavigationSplitView`, `.adaptiveSidebar()`, `tabBarController.sidebar` |
| 22% | Adaptive layout | Hardcoded `.frame(width:height:)`, `UIScreen.main.bounds`, deprecated `UIScreen.main` |
| 15% | UIScene lifecycle | Required when building against the iOS 27 SDK: without it the app does not launch (TN3187) |
| 12% | Adaptive geometry | size classes, `didUpdateEffectiveGeometry`, `GeometryReader` |
| 10% | SwiftUI vs UIKit | SwiftUI adapts to geometry; UIKit needs the sidebar opt-in |
| 8% | Resizable presentation opt-in | `UIRequiresFullScreen=true` opts the app out of a resizable scene |
| 8% | State preservation | `@SceneStorage`, restoration, view models that survive a resize |

Scores are proportional to the codebase (occurrences relative to file count), so a large
app with a handful of hardcoded frames is not unfairly failed. Each check carries the
Apple source it is derived from, printed next to the check in the report: a scored check
with no Apple source fails the repository's own check script.

## Usage

```sh
swift build
./.build/debug/foldready <path-to-ios-repo> [--name "App"] [--json] [--open]
```

Outputs `foldready-report.html` (and `result.json` with `--json`) into the audited
folder by default, or into `--out <dir>`.

## Visual grading (captured layout)

A 10% "Captured layout" check is added when screenshots are supplied. It detects
letterboxing: uniform near-black/white margin bands around the app content, the exact
signature of a portrait app rendered on the wider iPhone Fold canvas.

```sh
# 1. Capture (needs an .xcodeproj in the repo; simulator build, no signing)
./Scripts/capture.sh <repo> --name "App" --out shots

# 2. Audit with the visual check
./.build/debug/foldready <repo> --with-screenshots shots --name "App" --open

# Standalone screenshot analysis
./.build/debug/foldready visual shots
```

The pixel engine (`Sources/foldready/VisualAnalysis.swift`) is unit-tested against
synthetic full-screen vs letterboxed images. The iPhone Fold simulator device type
ships with Xcode 27; `capture.sh` targets the widest available device until then.

## What the score means

Apple told developers to stop targeting fixed sizes and orientations and to handle "a
dynamic range of sizes and aspect ratios"
([WWDC26, Modernize your UIKit app](https://developer.apple.com/videos/play/wwdc2026/278/)).
Two things follow, and only one of them is optional:

- **Hard requirement**: the UIScene lifecycle. An app built against the iOS 27 SDK
  without it does not launch. Apps already shipped, and apps still built against the
  iOS 26 SDK, keep working — the App Store floor is Xcode 26 / iOS 26 since 28 April
  2026, and Apple has not published an iOS 27 SDK date yet.
- **The part the score measures**: how well the app uses the room it is given. The apps
  that look right on a wide canvas are the ones that adopted split-view sidebars, size
  classes and adaptive layout.

Grade bands: A >= 75, B >= 60, C >= 45, D >= 30, F < 30. Risk: low / medium / high.

## Readiness gate (CI)

`foldready gate` audits a tree, evaluates the repository's policy, and communicates the
verdict through the exit code: `0` pass, `2` policy breach, `1` the run itself failed.
A failing app and a broken pipeline are different problems, so they get different codes.

```sh
./.build/debug/foldready gate <repo>                   # report only, exits 0
./.build/debug/foldready gate <repo> --write-baseline  # accept the current score
```

Policy lives in `.foldready.json` at the audited repository. Every field is optional,
and an absent file means "no policy": the gate reports the score and does not fail the
build.

```json
{
  "min_score": 60,
  "max_total_regression": 0,
  "no_regression_checks": ["scene", "full-screen"],
  "max_severity": "critical",
  "baseline": ".foldready-baseline.json"
}
```

The baseline is a committed file, not a hosted service: accepting a lower score is a
reviewable diff in the pull request that causes it, and CI never needs an account or
network access.

### GitHub Action

```yaml
- uses: guillaume-flambard/foldready@v1
  with:
    path: .
```

On a pull request it reports the score, the base score and the delta, uploads the HTML
report as a job artifact, and fails the job when the policy is breached. It runs on a
macOS runner and builds the pinned action source with the runner's Swift — nothing is
fetched at run time. Add `fetch-depth: 0` to `actions/checkout` to get the score delta.
Full input list in [action.yml](action.yml).

## Porting: what FoldReady writes, and what it hands over

Xcode 27 ships Apple's `uikit-app-modernization` agent skill (exportable with
`xcrun agent skills export`). It migrates the scene lifecycle, converts main-screen
reads to trait and scene lookups, and replaces orientation checks with size classes —
inside the project, with the type checker. A pattern matcher cannot beat that, and
FoldReady no longer tries.

The split is by provability:

| FoldReady writes | FoldReady hands over |
|---|---|
| Remove `UIRequiresFullScreen` from Info.plist | Scene lifecycle migration |
| UIKit tab bar sidebar opt-in (gated by `#available`) | Fixed screen geometry reads |
| | Root navigation that cannot become a sidebar |
| | Size-class-driven layout |
| | State preservation across a resize |

```sh
./.build/debug/foldready port <repo> [--apply] [--out <dir>]
./.build/debug/foldready verify <repo> [--work-order <file>] [--build]
```

`port` writes the safe patches plus `work-order.md` and `work-order.json`. Each entry
states where the work is, the required end state, the Apple source the requirement comes
from, and the condition FoldReady re-evaluates. Hand `work-order.md` to Apple's skill or
any other coding agent; then `verify` reports each entry as fixed, unchanged or
regressed, alongside the score delta.

`verify --build` also closes the visual loop: it builds the app for the widest available
simulator (in-process pipeline mirroring `Scripts/capture.sh`), captures a screenshot,
and adds the "Captured layout" pixel check to the re-score. Without a buildable
`.xcodeproj` it degrades to the static re-score.

The checks target the **public** iOS 27 contract. The internal `foldState` and
`angleDegrees` strings are not public API and are treated as info-only, never as a port
target.

## Web app (Next.js)

The marketing + product site implements the design system v2 (Space Grotesk /
Inter / JetBrains Mono, ink + screen blue + ready green, dark/light):

- `/` — landing (hero gauge, proof strip, offering, pricing, objections)
- `/ranking` — Fold-Ready Index (sort + grade filter, driven by `web/lib/data.ts`)
- `/report/[slug]` — dynamic Fold-Ready report per audited app (gauge, check
  breakdown, findings, remediation roadmap)
- `/components` — the 12-component catalog with dark/light toggle

```sh
cd web
npm install
npm run dev        # http://localhost:3000
npm run build      # static export to web/out/
```

Static export: `output: "export"`, deployable to GitHub Pages / Vercel / any host.
App data lives in `web/lib/data.ts`; the CLI audit JSON can seed it via
`Scripts/aggregate-index.py` (currently writes the legacy `web-legacy/data.js`).

**Live**: https://foldready.memolabs.dev (primary, Coolify/nginx serving `web/out`)
and https://guillaume-flambard.github.io/foldready/ (GitHub Pages). The repo root
Dockerfile builds the web static export for Coolify.

Legacy static v1 site (report HTML per app) is preserved in `web-legacy/`, rebuilt
by `Scripts/build-index.sh`:

```sh
./Scripts/build-index.sh <repo1> <repo2> ...
```

## Design system

The authoritative design system lives in `design/ds-package/` — the exported Open
Design package: `DESIGN.md` (tokens), `DESIGN-HANDOFF.md` (implementation contract),
`DESIGN-MANIFEST.json` (machine-readable map), `colors_and_type.css` (canonical token
CSS), the 5 screens, `preview/` cards and `ui_kits/app/` (token-bound component demos).

The web app consumes the same tokens: colors are identical, and the canonical
radius/spacing/motion names (`--r-container`, `--sp-*`, `--t-fast`…) are declared in
`web/app/globals.css`. Reconcile any drift against `design/ds-package/` before
changing a color. The design prompt used to generate the system is in
`design/DESIGN-SYSTEM-PROMPT.md`.

## Contributing

Open source, PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the rules —
the short version: new checks, transforms, and edge-case tests are the most useful;
stay anchored on the **public** iOS 27 contract; never break code silently; keep
`./Scripts/check.sh` green.

## Product

The CLI is the entry product: pay-per-audit reports that open the door to fixed-price
porting contracts for enterprise iOS apps. Brand and assets in `brand/`.

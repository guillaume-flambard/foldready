# FoldReady

Fold-Ready audit CLI: score how an iOS app will look on the iPhone Fold (Sept 2026),
then ship the report that sells the porting contract.

`foldready <path>` scans an iOS source tree, runs 7 static checks against the iOS 27
foldable requirements, and emits a 0-100 Fold-Ready Score with an HTML report and an
effort estimate in hours.

## Checks

| Weight | Check | What it looks for |
|---|---|---|
| 20% | Adaptive layout | Hardcoded `.frame(width:height:)`, `UIScreen.main.bounds` |
| 10% | Parallel View opt-in | `UIRequiresFullScreen=true` blocks the auto-adaptation layer |
| 20% | Adaptive navigation / sidebar | `NavigationSplitView`, `.adaptiveSidebar()`, `tabBarController.sidebar` |
| 10% | UIScene lifecycle | Scene lifecycle is mandatory on iOS 27 |
| 15% | Fold state handling | `foldState`, `angleDegrees`, `didUpdateEffectiveGeometry`, `GeometryReader` |
| 10% | State preservation | `@SceneStorage`, restoration, view models that survive a fold |
| 15% | SwiftUI vs UIKit | SwiftUI adapts to geometry; UIKit needs the sidebar opt-in |

Scores are proportional to the codebase (occurrences relative to file count), so a large
app with a handful of hardcoded frames is not unfairly failed.

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

Parallel View keeps every app running on the iPhone Fold without crashing. The score
measures how good it looks: the apps that get featured at launch are the ones that
adopted split-view sidebars and adaptive layout, not the ones that merely survive.

Grade bands: A >= 75, B >= 60, C >= 45, D >= 30, F < 30. Risk: low / medium / high.

## Fold-Ready Index

The public ranking of well-known open-source iOS apps by Fold-Ready Score lives in
`web/`. Rebuild it after any change:

```sh
./Scripts/build-index.sh <repo1> <repo2> ...   # re-audits and regenerates web/
```

Current lineup: MochiDiffusion 91 (A), IceCubesApp 78 (A), isowords 78 (A),
MovieSwiftUI 69 (B), Dime 59 (C), Open Food Facts 48 (C). Each card links to the
full report. Serve `web/` statically (GitHub Pages or `python3 -m http.server`).

## Product

The CLI is the entry product: pay-per-audit reports that open the door to fixed-price
porting contracts for enterprise iOS apps. Brand and assets in `brand/`.

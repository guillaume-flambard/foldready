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

## Porting engine

Beyond the audit, `foldready` generates and applies porting patches. The engine runs
7 transforms, each gated by a confidence tier, and closes the loop: audit → port →
re-score.

```sh
./.build/debug/foldready port <repo> [--tiers srm] [--apply] [--out <dir>]
./.build/debug/foldready verify <repo>            # re-audit after a port
```

| Tier | Transforms |
|---|---|
| safe | Remove `UIRequiresFullScreen` (Info.plist) · UIKit tab bar → sidebar opt-in |
| review | Migrate to `UIScene` lifecycle (manifest + SceneDelegate) · replace `UIScreen.main.bounds` · wrap root `NavigationStack` in `NavigationSplitView` |
| manual | `@SceneStorage` state preservation · de-hardcode fixed frames (guidance + snippets) |

Dry run by default: writes a `porting-report.md` with unified diffs per transform.
`--apply` writes edits to the working tree. The verification loop is the point: a
ported fixture goes 20/100 → 51/100 with the safe + review tiers applied.

The transforms target the **public** iOS 27 contract (scene lifecycle mandate,
Parallel View opt-in, adaptive layout, `NavigationSplitView` + `.adaptiveSidebar`).
The internal `foldState`/`angleDegrees` strings are NOT public API and are treated as
info-only, never as a port target.

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

Legacy static v1 site (report HTML per app) is preserved in `web-legacy/`, rebuilt
by `Scripts/build-index.sh`:

```sh
./Scripts/build-index.sh <repo1> <repo2> ...
```

## Product

The CLI is the entry product: pay-per-audit reports that open the door to fixed-price
porting contracts for enterprise iOS apps. Brand and assets in `brand/`.

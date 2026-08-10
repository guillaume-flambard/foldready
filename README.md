# FoldReady

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

Fold-Ready audit CLI: score how an iOS app will look on the iPhone Fold (Sept 2026),
then ship the report that sells the porting contract. **Open source and independent** —
the readiness check should not be a black box.

`foldready <path>` scans an iOS source tree, runs 7 static checks against the iOS 27
foldable requirements, and emits a 0-100 Fold-Ready Score with an HTML report and an
effort estimate in hours.

## Checks

| Weight | Check | What it looks for |
|---|---|---|
| 25% | Adaptive navigation / sidebar | `NavigationSplitView`, `.adaptiveSidebar()`, `tabBarController.sidebar` |
| 22% | Adaptive layout | Hardcoded `.frame(width:height:)`, `UIScreen.main.bounds`, deprecated `UIScreen.main` |
| 15% | UIScene lifecycle | Scene lifecycle is mandatory on iOS 27 (TN3187) |
| 12% | Adaptive geometry | size classes, `didUpdateEffectiveGeometry`, `GeometryReader` |
| 10% | SwiftUI vs UIKit | SwiftUI adapts to geometry; UIKit needs the sidebar opt-in |
| 8% | Parallel View opt-in | `UIRequiresFullScreen=true` blocks the auto-adaptation layer |
| 8% | State preservation | `@SceneStorage`, restoration, view models that survive a resize |

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
./.build/debug/foldready verify <repo> [--build]   # re-audit after a port
```

`verify --build` closes the visual loop: it builds the app for the widest available
simulator (in-process pipeline mirroring `Scripts/capture.sh`), captures a screenshot,
and adds the "Captured layout" pixel check to the re-score. Without a buildable
`.xcodeproj` it degrades to the static re-score.

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

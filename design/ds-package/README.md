# FoldReady — Design System Package

## Product overview

FoldReady is a developer tool that scores and ports iOS apps for the iPhone
Fold. It runs a static + captured-layout audit against the iOS 27 foldable
requirements, returns a 0–100 **Fold-Ready Score** with an A–F grade, estimates
the port in hours, and offers a paid porting service. Three product surfaces:

1. **Landing** (`landing-page.html`) — marketing, pricing tiers, objection handling.
2. **Fold-Ready Index** (`index-ranking.html`) — independent rankings of
   open-source iOS apps, sortable and grade-filtered.
3. **Report** (`report-page.html`) — the per-app audit: hero gauge, grade stamp,
   weighted check breakdown, findings with `file:line`, remediation roadmap.

This package is the reusable design system for that product: engineering-grade
Apple HIG crossed with terminal precision. Dark Ink canvas, layered panels with
1px hairlines, Screen Blue as the single vivid accent for focus, Ready Green for
the check and passing grades, Space Grotesk display over Inter body with
JetBrains Mono carrying every number.

## Source context

Generated from **Master Prompt Foldready Design System Paste** (source project
`f22e9531-a0a1-424c-901c-e5fd6e68464e`). All tokens were extracted verbatim from
the copied source screens (`components.html` is the fullest `:root` reference).
The preserved screens remain unmodified at the project root. Full trace:
[`context/provenance.md`](context/provenance.md) ·
[`context/source-context.md`](context/source-context.md).

## Package contents

| Path | What it is |
|---|---|
| `DESIGN.md` | The rule book — context, voice, color, type, spacing, layout, motion, components, anti-patterns, package map |
| `colors_and_type.css` | **Paste-ready token file** — dark + light, fonts, radius, spacing, motion |
| `SKILL.md` | Agent-facing workflow (Claude-style package) |
| `preview/` | Focused review cards (manifest below) |
| `ui_kits/app/` | Applied interface kit + README |
| `assets/` | `mark.svg` (Hinge Check mark) · `hinge-check-tile.svg` · `favicon.svg` |
| `build/icons/` | Runtime stroke icons: arrow-right, refresh, download, scan, layout, port |
| `fonts/` | Font load contract (Google Fonts) |
| `context/` | Provenance + source context notes |
| Root screens | `components.html` · `report-page.html` · `index-ranking.html` · `landing-page.html` (preserved source) · `index.html` (launcher) |

## Preview manifest

Review cards in `preview/` (each binds the shared token file):

| Card | Inspects |
|---|---|
| `preview/index.html` | Gallery + preserved-source list |
| `preview/colors-primary.html` | Dark/light palettes, grade bands A–F, usage rules |
| `preview/typography-specimens.html` | Display/body/data/caption ramp |
| `preview/spacing-tokens.html` | 4px spacing scale, radius set, motion contract, live gauge |
| `preview/components-buttons.html` | Buttons, chips, gauge, check bars, score/stat cards, table |
| `preview/brand-assets.html` | Preserved mark, check tile, favicon, wordmark lockup, icons |
| `preview/surfaces.html` | Report, Index, Landing, Catalog rendered from preserved files |

## Preserved assets, build & fonts

- `assets/` — the Hinge Check mark and derived brand SVGs, extracted
  byte-for-byte from the source screens and served as real files.
- `build/icons/` — the stroke icon set used across the product.
- `fonts/` — the Google Fonts load contract (no local binaries existed in the
  source; the README documents how to self-host later).

## ui_kits/app/

`ui_kits/app/index.html` is a working applied kit — an audit workspace with
nav, hero gauge, stat cards, weighted check bars, findings, and the confident
empty state, all bound to `colors_and_type.css` with a persisted theme toggle.
Reuse guidance: [`ui_kits/app/README.md`](ui_kits/app/README.md).

## Reuse workflow

1. Read `DESIGN.md`, then `SKILL.md`.
2. Paste `colors_and_type.css` into the first `<style>` of the new artifact.
3. Match component shapes from `components.html` / `preview/components-buttons.html`.
4. Keep numbers monospaced + tabular; one vivid accent per view; grade chips
   carry a letter.
5. Verify against the interaction-state and anti-pattern rules in `SKILL.md`.

## Review workflow

Start at `preview/index.html`. Then: `colors-primary.html` →
`typography-specimens.html` → `spacing-tokens.html` → `components-buttons.html`
→ `brand-assets.html` → `surfaces.html`, finishing with `ui_kits/app/index.html`
to see the system applied.

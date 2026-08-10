# FoldReady Design System — Provenance

Where every token, component, and rule in this package came from. The source
project's copied HTML files are the ground truth for the visual language; this
file records what was extracted, where, and what was deliberately preserved.

## Source

- Source project id: `f22e9531-a0a1-424c-901c-e5fd6e68464e`
- Source project name: Master Prompt Foldready Design System Paste
- New design-system project id: `f49dbfb9-cba7-41e0-995f-eb5523605ac4`
- New design-system id: `user:master-prompt-foldready-design-system-paste`
- Source skill / design system: (none)
- Linked source dir: `/Users/memo/projects/foldready`

## Copied source files (preserved, unmodified)

These are the source evidence. They remain at the project root and are treated
as immutable reference implementations:

| File | Role in the package |
|---|---|
| `components.html` | 12-component catalog, dark + light, full token reference |
| `report-page.html` | Applied surface: fold-ready audit report for IceCubesApp |
| `index-ranking.html` | Applied surface: Fold-Ready Index (sortable, grade-filtered) |
| `landing-page.html` | Applied surface: marketing landing with pricing |
| `index.html` | Deliverable launcher / overview |
| `DESIGN.md` | Token + rule file (extended in this package) |

## Token extraction

All CSS custom properties, type scales, spacing, radius, motion timings, and
grade bands were read verbatim from the `<style>` blocks of the copied files
(principally `components.html`, which carries the most complete `:root`
including `--ink2`, `--checkink`, and the light theme override).

Canonical token file: `colors_and_type.css` (dark + light, self-contained,
paste-ready).

## Preserved assets

- `assets/mark.svg` — the Hinge Check mark lockup, extracted byte-for-byte from
  the inline SVG reused across every screen (`nav`, footer, cards).
- `assets/hinge-check-tile.svg` — the green check on its ink-safe tile
  (empty-state mark).
- `build/icons/*.svg` — stroke icons extracted from the source: arrow-right,
  refresh (re-run audit), download, and the three offering icons (static audit,
  captured-layout, porting), plus the check glyph.

## Fonts

The three families (Space Grotesk 500/700, Inter 400–700, JetBrains Mono 500/700)
are loaded from Google Fonts with the exact URL used in the source. Fallback
stacks are preserved. No local font binaries exist in the source, so `fonts/`
documents the load contract rather than shipping `.woff2` files.

## Derivation rules

- Every hex value in this package comes from the source `:root` blocks. No new
  colors were invented.
- Component shapes, radius, spacing, motion, copy tone, and the "one vivid
  accent" / "one filled mark" constraints are inferred from the rendered source
  screens, not from the DESIGN.md prose alone.
- Grade colors travel with letters (A–F); a grade is never conveyed by color
  alone anywhere in the package.

## Known gaps (no source evidence)

- No raster imagery (product shots, avatars, screenshots) existed in the source
  project; the product is typographic + geometric by design, so none are added.
- No font binaries; the Google Fonts contract is documented instead.
- No brand guidelines file beyond DESIGN.md; the logo usage rule ("the Hinge
  Check mark always ships on its ink tile") is extracted from DESIGN.md and the
  inline SVG.

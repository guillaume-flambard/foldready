---
name: foldready-design-system
description: FoldReady design system. Build and review FoldReady artifacts — the fold-ready audit report, the Fold-Ready Index, the landing page, pricing, and any marketing or tool UI — using the paste-ready token file, the 12-component catalog, and the voice rules. Use whenever a task mentions FoldReady, fold-ready scores, iPhone Fold audits, or when the active project is this design-system package.
user-invocable: true
---

# FoldReady Design System — SKILL

## What is inside

- `DESIGN.md` — the rule book: color (dark + light), type, spacing, radius,
  layout, motion, voice & copy, components, anti-patterns.
- `colors_and_type.css` — paste-ready token file. Dark is the default identity;
  light binds via `:root[data-theme="light"]`.
- `components.html` — preserved 12-component catalog on dark + light.
- `preview/` — focused review cards for every foundation.
- `ui_kits/app/` — an applied interface kit with a working theme toggle.
- `assets/` + `build/icons/` — preserved brand mark, check tile, favicon, and
  runtime stroke icons.
- `context/provenance.md` — the token-to-source trace.

## Source context

The package is generated from **Master Prompt Foldready Design System Paste**
(source id `f22e9531-a0a1-424c-901c-e5fd6e68464e`). FoldReady is a developer
tool that scores and ports iOS apps for the iPhone Fold: a static + captured-
layout audit returns a 0–100 Fold-Ready Score, an A–F grade, a port estimate in
hours, and a remediation roadmap. Three surfaces ship: the landing page
(marketing + pricing), the Fold-Ready Index (sortable open-source rankings), and
the per-app report (hero gauge, weighted checks, findings, roadmap). All tokens
were extracted verbatim from the copied screens; see `context/provenance.md`.

## When to use

- Building any FoldReady surface: report, index, landing, pricing, marketing.
- Reusing a FoldReady component: gauge, score card, check bar, finding row,
  stat card, button, chip, grade chip, table, report shell, landing hero, nav,
  empty state.
- Reviewing or editing an existing FoldReady artifact.

## How to use

1. Read `DESIGN.md` for the rules, then `SKILL.md` sections below.
2. Paste `colors_and_type.css` verbatim into the first `<style>` of any new
   artifact. Bind tokens — never introduce hex outside the palette.
3. Match component shapes from `components.html` / `preview/components-buttons.html`.
4. Keep numbers JetBrains Mono + tabular everywhere. One vivid accent per view.
   Grade chips always carry a letter.
5. Apply the interaction contract (below) and the voice rules (below).
6. Review via `preview/index.html`, then `ui_kits/app/index.html`.

## Design-system highlights

- **Color.** Ink `#0F172A` canvas (never pure black); panels `#1E293B` /
  `#24344D`; hairlines `rgba(226,232,240,.14)`. Exactly two accents: Screen
  Blue `#0EA5E9` (focus, open screen, needle) and Ready Green `#22C55E` (the
  check, passing grades, zero risk). Light variant swaps canvas to Paper
  `#FBFBFE` and darkens text to Ink.
- **Grade bands.** A `#22C55E` → F `#EF4444`, each with a light-theme text
  value. Grade = letter + color, never color alone.
- **Type.** Space Grotesk 500/700 display (−0.03em ≥32px), Inter 400–700 body
  (15–17px, 1.5–1.6), JetBrains Mono 500/700 for every number. Extreme scale
  contrast is the differentiator.
- **Shape & spacing.** Containers 14px, buttons 11px, chips 999px; 4px spacing
  base (4·8·12·16·24·32·48·64). Dark-mode depth is structural: layered panels +
  1px hairlines, no drop shadows.
- **Motion.** 120–200ms ease-out, fade + 4–8px slide; gauge lands once on a
  spring (`cubic-bezier(.16,1,.3,1)`); `prefers-reduced-motion` respected.
- **The score is the hero.** Big, monospaced, colored by grade band — a 96px
  score next to a 13px caption is welcome.

## Interaction-state contract

- Focus ring: Screen Blue `2px` outline, `2px` offset, on every
  keyboard-reachable element.
- Hover moves the background (panel → panel2, blue → sky); it never dims the
  foreground toward `--dim`.
- Primary button hover swaps to Sky; text stays `--on-accent`.
- Disabled is the only state allowed to reduce contrast (`opacity:.45`).

## Voice

Measured nouns, no unverifiable adjectives; numbers carry the claim; no
exclamation marks, no emoji, no urgency theater. Preferred vocabulary:
*measured, port estimate, captured-layout pass, featured ready, 7.8in inner
display, weighted check, file:line, receipts*.

## Anti-patterns to avoid

Gradient washes · glassmorphism · emoji as icons · default shadow stacks ·
centered gradient-underlined heroes · skeuomorphic folds · decorative motion ·
rhetorical marketing copy · invented metrics (use honest, labeled placeholders
or real audit data) · `#000000` · dim text under 12px.

## Verify before delivery

- Numbers monospaced + tabular everywhere.
- Exactly one vivid accent per view; no competing Screen Blue.
- Grade = letter + color, never color alone.
- No `#000000`, no purple/teal/pink, no gradients on text, no neon glow.
- Text contrast never drops on hover/focus.
- The Hinge Check mark ships on its ink tile, never recolored.

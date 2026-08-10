# FoldReady — Design System v2

A developer tool that scores and ports iOS apps for the iPhone Fold. The system
is engineering-grade Apple HIG crossed with terminal precision and editorial
restraint: a spec sheet stamped with a passing grade. Quiet, exact, confident.
Every element must look machine-checked.

## Personality

FoldReady speaks like a calibrated instrument, not a marketing department. It
is the report a staff engineer writes at the end of a long night: specific,
measured, and free of adjectives it cannot back up. The interface hides nothing
and dresses up nothing — scores are monospaced and tabular because they are
measurements, panels stack on panels instead of floating on shadows because
depth here is structural, and the single vivid accent (Screen Blue) is rationed
so that when it appears, it means focus, the open screen, or the moving needle.
The green check is the only filled mark in the system, and it means exactly one
thing: ready. Nothing bounces, nothing spins, nothing pleads for attention; the
product's confidence comes from the numbers themselves.

### Logo usage rule

The Hinge Check mark always ships on its ink tile, at any size, on any surface — never recolor the green check, never strip the tile.

---

## 0. Product context

FoldReady is a developer tool that scores and ports iOS apps for the iPhone
Fold. It runs a static + captured-layout audit against the iOS 27 foldable
requirements, returns a 0–100 Fold-Ready Score with an A–F grade, estimates the
port in hours, and offers a paid porting service. Three product surfaces exist:

1. **Landing** (`landing-page.html`) — marketing, pricing tiers, objection
   handling. Goal: get the app scored.
2. **Index** (`index-ranking.html`) — an independent ranking of open-source iOS
   apps, sortable and grade-filtered. Goal: prove the measurement is real.
3. **Report** (`report-page.html`) — the per-app audit: hero gauge, grade stamp,
   weighted check breakdown, findings with `file:line`, remediation roadmap
   ordered by effort. Goal: make the fix list unambiguous.

The audience is iOS engineers and product owners, not designers. Every word is
specific and measurable; there is no marketing froth because the numbers carry
the confidence.

---

## 2. Voice & copy

FoldReady speaks like a calibrated instrument, not a marketing department. It
is the report a staff engineer writes at the end of a long night. Rules
extracted from the shipped copy:

- **Measured nouns, no unverifiable adjectives.** "A static + pixel audit that
  scores your app 0–100… estimates the port in hours" — not "powerful", "modern",
  "blazing".
- **Numbers carry the claim.** Scores, hours, file:line and weights appear in
  copy wherever a claim is made ("34 hardcoded frames · 6 UIScreen.main.bounds
  reads across 424 files").
- **Weighted honesty.** Checks carry explicit weights (`w 0.20`); pricing owns
  its caveats ("Findings cite file:line, not vibes").
- **One short active headline, one mechanical payoff.** "Your iOS app, ready for
  the iPhone Fold." / "A measurement, a plan, and a ship date." / "Pay for the
  port, not the guesswork."
- **Objections get data-backed answers**, each ending on a measured fact.
- **No exclamation marks, no emoji, no urgency theater.** Deadpan confidence.

Preferred vocabulary: *measured, port estimate, captured-layout pass, featured
ready, 7.8in inner display, weighted check, remediation roadmap, file:line,
receipts*. Avoid: *vibes, magic, seamless, game-changing*.

---

## 1. Color — dark (default identity)

| Token | Value | Role |
|---|---|---|
| `--ink` | `#0F172A` | Primary canvas. Never pure black. |
| `--ink2` | `#0B1220` | Deeper inset / focus-plate tone. |
| `--panel` | `#1E293B` | Cards, containers, secondary surface. |
| `--panel2` | `#24344D` | Hover fill, raised inset on panel. |
| `--slate1` | `#334155` | Borders, track, bezel. |
| `--slate2` | `#475569` | Stronger structural line, icon base. |
| `--blue` | `#0EA5E9` | **The one vivid accent.** Focus, active, links, open screen, needle. |
| `--sky` | `#7DD3FC` | Hover / highlight state of Screen Blue. |
| `--green` | `#22C55E` | **Ready only.** The check, a passing score, zero risk. |
| `--checkink` | `#052E16` | Checkmark stroke on the green tile. |
| `--txt` | `#E2E8F0` | Primary text on Ink. |
| `--dim` | `#94A3B8` | Secondary / caption text (never below 12px). |
| `--line` | `rgba(226,232,240,.14)` | 1px hairlines and dividers. |

Rules: exactly two accents (Screen Blue, Ready Green). No gradients on text,
no neon glow, no purple/teal/pink, no `#000000` anywhere.

### Grade bands (semantic — color + letter always travel together)

| Grade | Dark | Light (text use) | Meaning |
|---|---|---|---|
| A | `#22C55E` | `#15803D` | Ready, featured-grade |
| B | `#84CC16` | `#4D7C0F` | Good, some polish |
| C | `#FACC15` | `#A16207` | Functional, not at home |
| D | `#F97316` | `#C2410C` | Visibly squeezed |
| F | `#EF4444` | `#B91C1C` | Needs a real port |

## 2. Color — light variant

| Token | Value |
|---|---|
| `--bg` | `#FBFBFE` (Paper) |
| `--panel` | `#FFFFFF` |
| `--panel2` | `#F1F5F9` |
| `--txt` | `#0F172A` (Ink as text) |
| `--dim` | `#475569` |
| `--line` | `rgba(15,23,42,.12)` |
| `--blue` / `--green` | unchanged (semantic) |
| Elevation | Very soft, low-opacity shadows only (dark mode: none). |

## 3. Typography

| Role | Family | Notes |
|---|---|---|
| Display / headlines | Space Grotesk | 500/700, tracking `-0.03em` to `-0.04em` on ≥32px |
| Body / UI | Inter | 400/500/600, 15–17px, line-height 1.5–1.6 |
| Data / scores / code | JetBrains Mono | **All numbers are monospaced + tabular.** Scores, percents, hours, `file:line` |

Fallbacks: display → `Inter Tight, ui-sans-serif, system-ui, sans-serif`;
body → `-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
mono → `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`.

Hierarchy is the differentiator: extreme scale contrast (a 96px score next to a
13px caption is welcome). Never sit in the safe middle.

## 4. Shape, spacing, density

- Radius: containers 14px (12–16 allowed) · buttons 11px (10–14) · chips `999px`.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48, 64. 4px half-steps for icons only.
- Density 6–7/10: information-dense like a spec sheet, never cramped.
- Elevation: dark = no drop shadows. Depth from layered panels + 1px hairlines
  (panel on ink, card on panel). Light = soft low-opacity shadows allowed.

## 5. Layout

- 12-column grid desktop, 4-column mobile. Content max-width 1040–1120px.
- Left-aligned labels; tabular numbers right-aligned in tables and metrics.
- The score is always the hero element: big, monospaced, colored by grade band.

## 6. Motion

- 120–200ms, `ease-out`. State changes fade + 4–8px slide.
- Gauges and progress animate on a spring when a value lands; nothing spins
  forever, nothing bounces. Motion reads as a measurement, not a game.
- Respect `prefers-reduced-motion`.

## 7. Iconography

- Stroke-based, 1.5–2px stroke, rounded caps, consistent optical size.
- The only filled icon in the system is the green check mark.

## 8. Accessibility

- Body `#E2E8F0` on `#0F172A` (≥12.5:1). Never put `#94A3B8` text under 12px.
- Grade conveyed by letter (A–F) *and* color; never color alone.
- Focus ring: Screen Blue, 2px ring, 2px offset. Everything keyboard-reachable.
- Dynamic-type friendly to 200%; nothing breaks at 200% scale.

## 9. Component inventory

1. Score gauge — arc, monospaced value, grade color, needle on load.
2. Score card — app name, grade chip, risk, hours, weak-check chips, report link.
3. Check bar — segmented 10-step bar, one per foldable check.
4. Finding row — severity chip, check, message, `file:line` in mono.
5. Stat card — metric label + large monospaced value.
6. Button — primary = Screen Blue on Ink; secondary = ghost + hairline.
7. Chip / pill — severity, weak check, tags; grade chips carry a letter.
8. Table — hairline rows, monospaced right-aligned cells.
9. Report page shell — mark lockup, hero score, grade stamp, breakdown,
   findings, remediation roadmap ordered by effort.
10. Landing page — hero gauge, proof strip of app scores, three-column
    offering, pricing cards, objection block, footer.
11. Nav — mark + wordmark left, links, one primary CTA right.
12. Empty / "no weak checks" state — confident, never empty.

## 10. Anti-patterns

These are hard "never" rules, each backed by a visible failure mode in the
source project or its guardrails:

- **No purple/indigo gradients, glassmorphism, frosted blur, emoji, or "AI"
  vibes.** FoldReady is ink, hairline, and one measured accent.
- **No default shadow stacks, no soft blobs, no centered gradient-underlined
  hero.** Depth in dark mode comes from layered panels + 1px hairlines, never
  drop shadows.
- **No skeuomorphic folds or literal "paper fold" 3D.** The mark reads as a
  folded device only in flat geometric strokes.
- **Numbers are monospaced and tabular EVERYWHERE** or the system is broken.
  Scores, percents, hours, weights, file:line — all JetBrains Mono, all tabular.
- **Exactly one vivid accent per view.** If two things compete for Screen Blue,
  one of them is wrong. Screen Blue = focus / open screen / needle. Ready Green
  = the check and passing grades only. Never use either as decoration.
- **Never put `#94A3B8` (dim) text below 12px**, and never convey a grade by
  color alone — letter + color always travel together.
- **No `#000000` anywhere.** The darkest surface is Ink `#0F172A`.
- **No empty states that apologize.** The "no weak checks" state is confident:
  a green tile, a direct statement, one action.

## 11. Package map

| Path | Content |
|---|---|
| `colors_and_type.css` | Paste-ready token file (dark + light, type, radius, spacing, motion) |
| `assets/` | Preserved brand: `mark.svg`, `hinge-check-tile.svg`, `favicon.svg` |
| `build/icons/` | Runtime stroke icons extracted from the source SVGs |
| `preview/` | Focused review cards: colors, typography, spacing/radius, components, brand, surfaces |
| `ui_kits/app/` | Applied interface kit with theme toggle, components, and screen surfaces |
| `context/provenance.md` | Where every token came from |
| Root screens | Preserved source: `components.html`, `report-page.html`, `index-ranking.html`, `landing-page.html` |

Usage: read this DESIGN.md, paste `colors_and_type.css` into the first `<style>`,
bind tokens, then match component shapes from `components.html`.

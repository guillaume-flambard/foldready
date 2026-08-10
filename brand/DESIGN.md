# Design System: FoldReady

## 1. Visual Theme & Atmosphere

A developer tool that audits and ports iOS apps for the iPhone Fold. The mark
reads as the device: a book-style screen split by the hinge, with a green ready
check on the open half. Square, geometric, confident. Density moderate (6/10),
motion restrained (4/10). The atmosphere is precise and engineering-like, like a
passing grade stamped on a spec. Works on light and dark surfaces: the mark sits
on its own ink tile, so it never needs a background behind it.

## 2. Color Palette & Roles

- **Ink** (#0F172A) — Primary dark surface and wordmark color on light
- **Panel** (#1E293B) — Secondary surface, closed screen half
- **Slate** (#334155) / (#475569) — Frame and bezel tones
- **Screen Blue** (#0EA5E9) — The primary accent: open screen, links, focus
- **Sky** (#7DD3FC) — Lighter accent, inner screen highlight
- **Ready Green** (#22C55E) — The check: passed, ready, zero risk
- **Check Ink** (#052E16) — Stroke on the green check for contrast on the tile

Constraints: exactly two accents (screen blue, ready green). No gradients on
text, no neon glow, no pure black. The green only ever means "ready".

## 3. Wordmark

`foldready`, one word, lowercase, weight 700, sans-serif system stack
(-apple-system, Segoe UI, system-ui). Tight tracking (-0.5px). The mark ships
alone, the lockup (mark + wordmark) ships for headers, and the favicon is the
mark trimmed to its ink tile.

## 4. Usage Rules

- Never recolor the green check: ready is always green.
- The mark keeps its ink tile in every context, including favicon.
- Minimum mark size 16px (favicon), lockup minimum 96px wide.
- Light surfaces get the ink wordmark; dark surfaces may use screen white.

## 5. Assets

- `logo.svg` — canonical mark on ink tile
- `logo-lockup.svg` — mark + wordmark, horizontal
- `favicon.svg` + `png/favicon-16.png`, `png/favicon-32.png` — browser favicon
- `png/apple-touch-icon-180.png` — iOS home screen
- `png/logo-512.png`, `png/logo-1024.png` — store / social renders
- `svg/` — all 8 concept sources; 02 Hinge Check is the chosen direction

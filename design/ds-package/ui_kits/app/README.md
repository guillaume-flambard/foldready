# FoldReady — Applied UI Kit (`ui_kits/app/`)

A working, applied interface kit built on the FoldReady token file
(`colors_and_type.css`). It reflects the source project's audit workspace: a
page that scores an iOS app for the iPhone Fold.

## Structure & component files

| File | Content |
|---|---|
| `index.html` | The kit — nav (11), hero gauge (01), stat cards (05), weighted check bars (03), finding rows (04), empty / no-weak-checks state (12); buttons (06) and chips (07) throughout; persisted theme toggle |
| `components/score-card.html` | Reusable score card (02) + stat card (05) component demo, token-bound |
| `../../colors_and_type.css` | The token file the kit binds (dark + light) |
| `../../assets/mark.svg` | Brand mark used in the nav |

## Source basis

Mirrors `report-page.html` (the fold-ready report surface) and the component
catalog `components.html` in the project root. The demo data (IceCubesApp,
78 / A, 214h, 37 findings) is the real audited app from the source. Dark is the
default identity; the light variant binds via `:root[data-theme="light"]`.

## Usage workflow

1. Copy `index.html` (and `components/score-card.html` when you need the
   index's app **PreviewCard**) and keep the relative links to
   `colors_and_type.css` and `assets/mark.svg` (adjust paths for your target).
2. Replace the demo values (score, grade, hours, findings, check scores, app
   name) with your audit data. Numbers stay JetBrains Mono + tabular.
3. Keep the interaction contract — focus ring Screen Blue, hover lifts the
   background and never dims the text, exactly one primary CTA per viewport.
4. The theme toggle persists under the `fr-theme` `localStorage` key shared by
   all FoldReady artifacts.

## Design notes

- One vivid accent per view: Screen Blue in the hero CTA, Ready Green in the
  gauge, grade chip, and ready chips. No competing blues.
- The **Sidebar** check bar (weak, 40) is a first-class component: any score
  card or check bar can carry a weak/ready chip.
- The gauge arc springs once on load (`cubic-bezier(.16,1,.3,1)`); respect
  `prefers-reduced-motion`.
- Depth is structural — panels on ink with 1px hairlines, no drop shadows.

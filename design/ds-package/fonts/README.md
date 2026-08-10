# FoldReady — Fonts

No local font binaries existed in the source project; the three families are
loaded from Google Fonts with the exact URL used across every preserved screen:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;700&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
```

## Family contract

| Role | Family | Weights | Fallback stack |
|---|---|---|---|
| Display / headlines | Space Grotesk | 500, 700 | `'Inter Tight', ui-sans-serif, system-ui, sans-serif` |
| Body / UI | Inter | 400, 500, 600, 700 | `-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif` |
| Data / scores / code | JetBrains Mono | 500, 700 | `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace` |

## Rules

- All numbers are JetBrains Mono with `font-variant-numeric: tabular-nums`.
- Display letter-spacing: `-0.03em` at ≥ 32px, `-0.02em` below.
- Caption labels: Inter 600, `+0.08em` uppercase, `--dim`.
- Never substitute a non-listed family. Ship the declared fallback stack when a
  face is not web-loadable.

To self-host later, drop `.woff2` files in this folder and swap the `@font-face`
sources in `colors_and_type.css`; keep the stacks above unchanged.

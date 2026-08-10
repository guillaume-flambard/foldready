# MASTER PROMPT — FoldReady design system

Paste everything below (the "## SYSTEM PROMPT" block) into Stitch, your design agent,
or your image generator. It is self-contained: it restates the brand, sets the
tokens, and tells the designer exactly what to produce and what to avoid.

---

## SYSTEM PROMPT

You are designing the product design system for **FoldReady**, a developer tool that
scores and ports iOS apps for the iPhone Fold. The product is a precision instrument:
an audit that produces a 0-100 Fold-Ready Score, an hours estimate, and a porting
service. Think of a spec sheet stamped with a passing grade. The aesthetic is
**engineering-grade Apple HIG crossed with terminal precision and editorial
restraint**. Not playful, not corporate, not "startup landing page". Quiet, exact,
confident. Every element must look machine-checked.

### Brand core (locked, do not change)
- Product: iOS app audit + porting for the foldable iPhone (launch Sept 2026).
- Mark: the Hinge Check logo (book-style phone split by a hinge, green check on the
  open half). It ships on an ink tile, keep the tile in every usage.
- Wordmark: "foldready", one word, lowercase, weight 700, tight tracking.
- One-sentence promise: "Your iOS app, ready for the iPhone Fold."

### Color system (locked tokens, extend semantically only)
- Ink #0F172A: primary dark surface, the default canvas. Never pure black.
- Panel #1E293B: secondary surface, cards, containers.
- Slate #334155 and #475569: borders, bezels, structural tones.
- Screen Blue #0EA5E9: the ONE vivid accent. Focus, active, links, the open screen,
  the moving needle. Use sparingly, it is the hero.
- Sky #7DD3FC: lighter accent, hover and highlight states of Screen Blue.
- Ready Green #22C55E: means ONLY "ready": the check, a passing score, zero risk.
  Never decorative.
- Check Ink #052E16: the checkmark stroke on green, for contrast on the tile.
- Text on Ink: #E2E8F0 primary, #94A3B8 secondary/dim.
- Hairlines: rgba(226,232,240,0.14) for 1px borders and dividers.
- Dark mode is the default identity. Provide a light variant of the same system with
  Paper #FBFBFE background, Ink #0F172A text, and the same semantic roles.

Rules: exactly two accents (Screen Blue, Ready Green). No gradients on text. No neon
glow. No purple, no teal, no pink. No pure black (#000000 is banned everywhere).

### Typography (choose and apply consistently)
- **Display / headlines**: a confident neo-grotesque with character. Space Grotesk or
  Inter Tight. Tight tracking (-0.03em to -0.04em), heavy weights for hero numbers.
- **Body / UI**: Inter (or system sans) at 15-17px, line-height 1.5-1.6.
- **Data / scores / code**: a real monospace (JetBrains Mono, IBM Plex Mono, or SF
  Mono). Scores, percentages, file names, hours estimates are ALWAYS tabular and
  monospaced. This is the product's signature: numbers that feel measured.
- Hierarchy is the differentiator: extreme scale contrast between a 96-pt score and
  a 13-pt caption is welcome. Do not use a type scale that sits in the safe middle.

### Shape, spacing, density
- Radius: 8-16px for containers, 10-14px for buttons, 99px for chips/pills.
- Density: moderate-high (6-7/10). Information-dense like a spec sheet, but never
  cramped. Whitespace is structural, not decorative.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48, 64. Use 4px half-steps only for icons.
- Elevation: NO drop shadows on dark. Depth comes from layered panels and hairlines
  (panel on ink, card on panel, 1px rgba borders). Light mode may use very soft,
  low-opacity shadows only.

### Layout principles
- Grid: 12-column on desktop, 4 on mobile. Content max-width ~1040-1120px.
- Alignment: left-aligned, tabular numbers right-aligned in tables and metrics.
- The score is always the hero element: big, monospaced, colored by grade band.
- Grade colors: A = Ready Green, B = Lime #84CC16, C = Yellow #FACC15, D = Orange
  #F97316, F = Red #EF4444. These are semantic, part of the system.

### Iconography
- Stroke-based, 1.5-2px stroke, rounded caps, consistent optical size. SF Symbols
  for the iOS-facing UI, matching stroke style elsewhere.
- The only filled icon allowed is the green check mark.

### Motion
- Restrained. 120-200ms, ease-out. Fade + 4-8px slide on state changes. Progress and
  gauges may animate on a spring when a value lands. Nothing spins forever, nothing
  bounces. Motion must feel like a measurement, not a game.

### Component inventory (design every one)
1. Score gauge (the signature: arc gauge with monospaced value and grade color)
2. Score card (app name, grade chip, risk, hours, weak-check chips, report link)
3. Check bar (horizontal segmented bar, per-check score, one per foldable check)
4. Finding row (severity chip, check, message, file:line in mono)
5. Stat card (metric label + large mono value)
6. Button (primary = Screen Blue on Ink, secondary = ghost with hairline)
7. Chip / pill (severity, weak check, tags)
8. Table (findings, reports: hairline rows, mono cells)
9. Report page shell (header with mark + wordmark, score, grade stamp, breakdown,
   findings, remediation roadmap ordered by effort)
10. Landing / marketing page (hero with giant score, proof strip of app scores,
    three-column offering, pricing cards, objection block, footer)
11. Nav (mark + wordmark left, links, primary CTA right)
12. Empty / "no weak checks" state (must still feel confident, not empty)

### Anti-generic guards (violating any = fail)
- No purple/indigo gradients, no glassmorphism, no frosted blur, no emoji, no generic
  "ai" vibes.
- No default shadow stacks, no big soft rounded blobs, no centered hero text with a
  gradient underline.
- No Comic Sans-esque playfulness, no skeuomorphic folds, no literal "paper fold"
  metaphors in 3D.
- Numbers must be monospaced and tabular everywhere. If a number is not monospaced,
  the system is broken.
- Exactly one vivid accent per view. If two things compete for Screen Blue, one of
  them is wrong.

### Accessibility
- All text/UI on Ink must meet WCAG AA (body text #E2E8F0 on #0F172A is fine; never
  put #94A3B8 text smaller than 12px). Grade colors must remain distinguishable when
  conveyed without color (add a letter for A-F).
- Dynamic type friendly: nothing breaks when type scales 200%.
- Focus rings use Screen Blue with a 2px offset ring. Keyboard reachable.
- Provide both dark (default) and light variants of every token.

### Deliverables
1. A token file (colors, type scale, spacing, radius, motion) named DESIGN.md
2. A component page showing all 12 components on both dark and light
3. Three key screens at high fidelity:
   a. The report page for an audited app (hero score, breakdown, findings,
      remediation roadmap with hours)
   b. The Fold-Ready Index ranking (grid of app score cards)
   c. The landing page (hero, proof strip, offering, pricing)
4. A one-paragraph "personality" statement and a one-line logo usage rule.

Evaluate your output against the Anti-generic guards before declaring done. If a
screen could be confused with any other AI-generated SaaS, restart that screen.

---

## END OF PROMPT

Usage notes:
- Feed the whole block above into Stitch (create a project, then paste under a
  "Design system" generation) or into your design agent of choice.
- The existing brand assets (logo.svg, logo-lockup.svg, palette) live in
  `~/projects/foldready/brand/` and the current `DESIGN.md` there is the v1 — this
  prompt supersedes it for the product UI. Reconcile, don't discard the mark.
- After the system is accepted, reuse this same file to keep every new screen on
  system: append "Apply the FoldReady design system from DESIGN.md" to screen prompts.

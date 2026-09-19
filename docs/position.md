# FoldReady, where the product stands

Written 19 September 2026. This is an analysis, not a plan of record. The plan is
[roadmap.md](roadmap.md); this document exists to state what the product is worth today, what
competes with it, and what has to change before the offer means anything.

Read it as a position, not a promotion. Where something is unproven, it says unproven.

## What ships today

Working, released and green:

- `foldready 0.5.0`, contract v5. A dependency-free Swift lexer, so a symbol inside a comment,
  a string literal or a `#Preview` block cannot lower a score, and a file that cannot be
  lexed is reported rather than scored clean.
- Seven scored checks: adaptive layout 0.35, navigation 0.20, adaptive geometry 0.15,
  build floor 0.10, state 0.10, interface idiom 0.10, interface orientation 0.10. Each
  carries an Apple reference enforced by `Scripts/check.sh`.
- A confidence level on every finding, and a gate that can act only on findings at or above a
  configured `min_confidence`.
- Exclusions configurable in `.foldready.json` and reported by reason (tests, vendored,
  generated, by configuration).
- Four advisory Duo surface questions (reserved regions, arrangement views, vertical bars,
  camera direction) which never affect the score and each name the runtime check that would
  settle them.
- A versioned result contract (`schema_version` 5) with a committed golden payload, a `gate`
  subcommand with committed baselines and distinct exit codes, and a GitHub Action published
  at `guillaume-flambard/foldready@v0`.
- A public site with an index of twenty apps audited from source under contract v5, and the
  archive of superseded scores labelled historical.
- A scoped human deliverable, [readiness-review.md](readiness-review.md).

Unproven, and stated as such wherever it appears:

- The offer. Zero reviews sold, zero buyers interviewed, zero conversations recorded.
- The continuity prototype. Human time savings, customer demand and Duo folding are all
  unmeasured. Reports say so.
- The effort heuristics. The hours printed next to findings are estimated from the corpus,
  never from a real review under a real clock.

## What competes with it

The commercial question is not whether FoldReady works. It is what someone would pay for
that they cannot get free.

Apple ships `uikit-app-modernization` as an exportable agent skill in Xcode 27. It was read
in full and compared entry by entry against a real FoldReady work order on 19 September. The
findings:

- It edits. It replaces `UIScreen.main`, migrates the scene lifecycle, handles orientation
  branches and safe-area assumptions, and writes the code. In Swift and, unlike FoldReady,
  in Objective-C.
- It does not judge. There is no score, no per-check weighting, no baseline, no CI gate, no
  report a third party can read. Apple has no interest in failing a developer's build.
- It does not cover state preservation at all. A developer following the skill alone would
  never be told their scroll and selection state dies on a resize.
- It covers a surface FoldReady scores nowhere: safe-area insets, including the assumption
  that insets are symmetric, which is precisely a foldable failure mode.

So the durable half is a verdict, not an edit. An edit is a commodity the moment the
platform vendor ships one. A verdict with a baseline, a documented rule set and an auditable
reference is not, at least not while the vendor declines to do it.

That last clause is an inference about Apple's incentives, not a proven moat. A platform
vendor does not fail a developer's build; that is a role constraint, not a technical one.
It could change. What is verified is narrower: today, no Apple tool produces a score, a
baseline or a CI gate. Treat the durability as structural and contingent, not permanent.

The threat is not that Apple's skill is better. It is that a developer who installs it will
conclude they no longer need anything else, because they were never buying a verdict to
begin with. That is a positioning problem, not a feature gap.

## What the numbers actually say

Contract v5 raised every score in the published index. Open Food Facts moved 21 to 76,
isowords 13 to 51, Dime 6 to 43. The range went from 6-65 to 43-79 and no app now grades
below C.

Nothing in those apps changed. The rise is contract shape:

- Adaptive geometry lost its purity half and now returns 100 for any app that reads no size
  classes at all (isowords, "0 of 99 UI file(s) read size classes").
- The two new checks are near-free points for most trees: idiom scores 95-100 almost
  everywhere, orientation 100 wherever a plist already declares both orientations.

This is recorded in `docs/result-contract.md` and the corpus, and the site says it plainly.
The honesty is real, and it is not the whole problem. Documenting the movement does not
undo its effect: a number that rises 55 points without the code changing cannot be sold as
evidence of readiness, because the first serious buyer to look closely will find exactly
that. Explanation is not a fix for a number that is being asked to do a job it cannot do.

The conclusion is that the score has to change role. It is an entry point and a
prioritisation tool, never the proof. What a buyer pays for is the explanation and the order
of work: which findings deserve an intervention, why, and what still has to be verified by
running the app. That deliverable survives the score moving, because it does not depend on
the number being meaningful across releases.

## What is actually blocked

- The Duo simulator. Xcode 27.0 is installed and ships no iPhone Duo device type and only
  the iOS 26.5 runtime. Apple states the Duo simulator in Device Hub needs Xcode 27.1,
  coming later this month. So `verify --build` on Duo has no target, and the report still
  cannot say "tested on these devices, this runtime, this SDK". This blocks on Apple, not on
  this machine.
- Nothing else. The work-order handoff against Apple's exported skill was verified and
  closed (issue #5). The index re-audit under v5 was completed and the caveat removed
  (issue #6).

The one issue left open is the contributor index, #1.

## Four ways to reposition

These are the real options. They cost different amounts and reach different buyers.

### A. The CI gate, sold to teams

The asset Apple cannot copy: `foldready gate` fails a build when the score regresses. A lead
carrying three apps into Duo wants an automatic guardrail, not a tool a human remembers to
run. Sell per seat or per repository rather than once.

Longest sales cycle, and the one with the highest ceiling. No teams are in reach today.

### B. The human review, narrowed to the panic window

Stop selling source analysis as a product. Sell a dated answer: what blocks this app before
23 October, in what order, evidenced. The scanner becomes the instrument that makes the
review fast and defensible, which is what it already is.

A single developer, an app shipping soon, a fixed date. This is a hypothesis, and the
document says elsewhere that no developer has been interviewed. Nothing recorded so far
establishes that this buyer exists, that the launch date creates pressure they feel, or
that they have budget. The hypothesis is specific enough to be tested and cheap enough to
falsify, which is its only current merit.

The shortest route, and the only one that tests the actual bet.

### C. The safe-area check

Add the surface where Apple and FoldReady diverge, with real corpus signal: `safeAreaInsets`
appears in 230 files of the twenty-app corpus, `safeAreaLayoutGuide` in 262, and there are
concrete asymmetric-assumption sites (`openfind` decides a device has a notch from
`safeAreaInsets.left > 0 || safeAreaInsets.right > 0`).

This adds technical legitimacy and closes a genuine gap. It does not add a euro, and it does
not make FoldReady better than Apple, only more complete.

### D. A device test harness once the simulator lands

Nobody does this today because it cannot exist before 23 October. It is a bet on Apple's
shipping date, not on anything within control.

## The recommendation

B, with A as a later move.

Do not start by rebuilding the site. Start by producing one short sample of the actual
delivery, from an audit that already exists: three evidenced findings on one app, their
priority order, and what remains to be verified by running the app. Then talk to developers
with that sample in hand, asking how they handle the problem today and whether they would
buy this intervention on their own app.

The value to test is not detection. It is the diagnosis and prioritisation time saved,
stated without promising hardware compatibility that cannot be verified. That framing holds
even with no Duo simulator, so it is not blocked by Apple.

The reason is not that B is the strongest product. It is that B is the only option that
tests whether anyone wants this at all, and that question is currently unanswered. Options A,
C and D all improve a product whose demand has never been confirmed. Adding capability to an
unconfirmed product is the expensive mistake this position exists to avoid.

The sample must be produced with the scanner as it stands, without writing a line of code.
If producing it first requires improving the tool, that is the signal to stop rather than to
open a new technical workstream. The same test applies to the conversations: if they reveal
no urgency and no budget, the honest move is to stop the bet, not to convert the absence of
demand into more engineering.

## What has to be true before the offer is real

1. One short sample deliverable exists, produced from an existing audit with no new code.
2. Developers of apps shipping near launch have been asked how they handle this today, and
   whether they would pay for the intervention, rather than shown a score.
3. One review has been sold with access, scope and delivery date agreed first.
4. Its actual hours have been recorded against the printed estimate, which tells whether the
   heuristics were worth anything as a sales argument.

Until those are true, any claim the site makes about value is a hypothesis. The standing
constraints in [roadmap.md](roadmap.md) still hold: the product measures and Apple's tooling
edits; a scanner score never establishes a defect; no App Store enforcement date is
invented; every scored check carries a reference.

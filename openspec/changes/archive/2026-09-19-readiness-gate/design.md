## Context

The codebase is a 1977-line Swift 6 package: `AuditEngine` (416 lines) walks the tree,
reads files as text, and runs seven line-based checks; `Port/Transforms` (412 lines) does
comment- and string-aware lexing to rewrite what it can; `VisualAnalysis` detects
letterboxing in screenshots. There is no syntax tree, no build-graph awareness, and no
Objective-C support. Results are consumed by three Python scripts and a hand-edited
`web/lib/data.ts`.

Three external constraints shape the design:

1. Apple ships `uikit-app-modernization` in Xcode 27, exportable with
   `xcrun agent skills export`. It has project context and a type checker. Regex
   transforms cannot match it on structural edits.
2. UIScene becomes mandatory when an app builds against the iOS 27 SDK: without it the
   app does not launch. The App Store SDK floor is iOS 26 since 2026-04-28; the iOS 27
   floor is expected on the same annual cadence but is not published, so the deadline
   FoldReady cites must be the launch-crash, not an invented App Store date.
3. Apple's own audit list for resizability names four areas: scene lifecycle, main-screen
   references, interface-idiom checks, and interface-orientation checks. FoldReady scores
   the first two as first-class checks and folds the other two into a small penalty inside
   the adaptive-layout check, where they are invisible to a reader.

The repository has 1 star, 1 fork, no pull requests, and one open "good first issue"
since 2026-08-10. Nothing is bottlenecked on capability.

## Goals / Non-Goals

**Goals:**

- Make the score a contract other systems can depend on, versioned and documented.
- Make FoldReady run on every pull request instead of once per sales conversation.
- Make the port engine a producer of work orders for agents rather than a competitor to
  Apple's skill.
- Make every scored claim traceable to an Apple source, enforced by the check script.

**Non-Goals:**

- Rewriting the audit on SwiftSyntax. Worth doing, but it is a separate change with its
  own risk; the contract must land first so a parser swap does not break consumers.
- Objective-C support, a hosted scoring service, billing, or authentication.
- Beating Apple's skill at editing code.
- Any claim about App Store enforcement dates Apple has not published.

## Decisions

**The gate is a subcommand, not a new binary.** `foldready gate` reuses `AuditEngine` and
adds only policy evaluation. A second binary would double the release surface for a few
hundred lines of comparison logic.

**Exit codes distinguish breach from error.** CI cannot act on a single non-zero code: a
failing app and a broken pipeline need different responses, and conflating them trains
teams to ignore the gate.

**The baseline is a committed file, not a hosted service.** It keeps the tool
self-contained and free of an account, it makes an accepted regression a reviewable diff,
and it removes any need for network access in CI. The cost is that a stale baseline is
the team's problem; the gate mitigates it by printing the baseline's commit and date.

**Absent configuration means no policy.** A tool that fails the build on first install
gets removed on first install. The gate reports and exits zero until someone opts in.

**Distribution is a GitHub Action, not a Homebrew formula.** The action is one line of
YAML in a repository the buyer already has; a formula still requires someone to decide to
install a stranger's Swift binary. The action is also the only channel that puts the
score in front of reviewers repeatedly rather than once.

**Transforms split by provability, not by a three-tier confidence label.** The current
safe/review/manual tiering invites shipping "review" patches that a regex cannot justify.
Two states are honest: FoldReady can prove this edit is safe, or it writes a work order.

**The work order cites the platform requirement, not the FoldReady transform.** That is
what makes it executable by Apple's skill or any other agent, and what keeps it valid if
FoldReady's internals change.

**Sourcing is enforced in `Scripts/check.sh`.** A rule that lives only in a document is a
rule that a contributor breaks in good faith. A scored check without a reference field
fails the build.

**Idiom and orientation checks are promoted in a later change.** They belong to audit
fidelity, and they change scores; mixing a scoring change into the contract change makes
the first baseline comparisons meaningless.

## Risks / Trade-offs

**The contract freezes design mistakes.** Publishing keys and weights makes them
expensive to change. Mitigated by versioning from day one and by keeping weights explicit
in the payload so consumers can recompute rather than trust the total.

**A GitHub Action is a support surface.** Fork pull requests, missing tokens, self-hosted
runners, and macOS runner minutes all become issues someone has to answer. Accepted: the
alternative is no distribution at all.

**Ceding editing to Apple shrinks the visible product.** The demo "audit, patch, re-score"
loop is what impresses in thirty seconds. The counter is that the loop is about to be
outclassed by a free official tool, and a measurement layer that survives the comparison
is worth more than a demo that loses it.

**Regex-based audit still produces false positives.** A hardcoded frame inside a preview
provider or a test fixture is not a readiness problem. Until a syntax tree lands, the gate
can fail builds for the wrong reason, which is the fastest way to lose a team's trust.
Mitigated by shipping the gate with no default policy and by making per-check regression
opt-in, so the first thing a team sees is a number rather than a red build.

**Sourcing enforcement is a one-way door on copy.** Removing the Parallel View claim
weakens the current pitch, which leans on "your app survives but looks bad". The
replacement premise is stronger and verifiable: without UIScene, an app built against the
iOS 27 SDK does not launch at all.

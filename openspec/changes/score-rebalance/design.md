## Context

The corpus is twenty shallow clones of well-known open-source iOS apps, audited on
2026-09-06 with contract v1. It is the first evidence anyone has about how this score
behaves, and it is unflattering in a specific, fixable way: the checks that carry weight do
not vary, and the check that varies should not carry weight.

Measurements that drive every decision below:

| check | weight | distinct values / 20 | note |
|---|---|---|---|
| navigation | 0.25 | 3 | 40 for 18 apps |
| adaptive-layout | 0.22 | 12 | median 96, corr +0.36 with file count, −0.45 with its own findings |
| scene | 0.15 | 3 | the hard requirement, buried in the average |
| fold-state | 0.12 | 10 | the second most informative |
| framework | 0.10 | 20 | corr +0.64 with the total; penalises the mandatory migration |
| full-screen | 0.08 | 2 | rare but decisive and true |
| state | 0.08 | 2 | 70 for 17 apps |

Total: min 49, median 61, max 92, standard deviation 10.7, no D and no F.

## Goals / Non-Goals

**Goals:**

- The blocking facts are impossible to miss and impossible to average away.
- Every remaining scored check varies across the corpus.
- Nothing in the score rewards or punishes a UI framework choice.
- The same density of problems scores the same whatever the codebase size.
- The rebalanced score is measured against the same twenty apps before it ships.

**Non-Goals:**

- Syntax-tree parsing. `audit-fidelity` keeps that; this change takes only the exclusions
  the renormalised layout check cannot work without.
- Grading on a curve. Bands are calibrated so the corpus spreads, but each band keeps an
  absolute meaning: two apps with the same grade behave comparably whenever they were run.
- Any new check. The corpus is evidence about the checks that exist.

## Decisions

**Blockers are a list, not a percentage.** "No scene lifecycle" means the app does not
launch when built against the iOS 27 SDK. Expressing that as `scene: 20` inside a weighted
mean is the single worst thing the current design does: it converts a binary consequence
into 12 points of a total that reads as a school mark. Five apps in the corpus are in this
state, and no reader of a "53/100" would guess it.

**The framework check is deleted, not reweighted.** Three independent reasons, all
measured: it is the dominant discriminator (+0.64 with the total), it scores an
architecture preference rather than a behaviour, and on the work-order fixture it fell from
50 to 40 when the app adopted the mandatory scene lifecycle, because that adds a UIKit
file. A check that punishes the required fix cannot be repaired by a smaller weight.

**Proportional beats laddered.** `navigation` and `state` are three- and two-value ladders,
which is why they are flat. Both become proportions over the sites they are about: root
navigation containers that can become a sidebar, and stateful views that preserve their
state. Partial adoption becomes visible, which is also what makes a regression gate useful.

**The layout denominator becomes UI files, and the numerator becomes offending files.**
Occurrences over all Swift files is why Signal scores 100 with 22 offending files. Counting
files over UI files makes the check a density that a large codebase cannot dilute, and
bounds it naturally in [0, 1].

**Exclusions come with this change, not with `audit-fidelity`.** 92% of frame findings in
the corpus are icon-sized; a density metric built on that noise would be a density of
noise. Icon frames, preview blocks, test and vendored paths, and the `XCUIScreen.main`
mis-match (the pattern has no left word boundary) are excluded here because the new
normalisation depends on them.

**Not-applicable redistributes.** An app with no list or scroll view is not bad at state
preservation; it has no state to preserve. Scoring it as a failure is how the current
design produces its 70-for-everyone fallback. A not-applicable check drops out and its
weight is spread over the rest.

**Anchors are calibrated, and the calibration is written down.** The geometry check needs a
target for "enough size-class awareness for an app this size". Any such anchor is a choice,
so it is picked from the corpus distribution and recorded in the contract document with the
date and the corpus it came from, rather than hidden in the source as a constant.

**Contract v2, and baselines refuse to cross versions.** The contract's own rule says a
scoring change bumps the version. A gate that compared a v2 result against a v1 baseline
would report a regression that is an artefact of the rebalance, so the comparison is
skipped with a stated reason instead.

## Risks / Trade-offs

**Every published score changes.** The index, the six report pages and any baseline a team
has committed are invalidated at once. That is the cost of having measured; the alternative
is publishing numbers we now know do not separate anything.

**Deleting a check loses the only reason some apps scored differently.** After removing
`framework`, the corpus may compress rather than spread. The rebalance is therefore not
finished until the new distribution is measured on the same twenty apps, and the weights
and bands are set from that measurement rather than from this document.

**Proportional checks are noisier on small apps.** A three-file app with one bad root
container scores 0 on navigation. Reporting the denominator alongside the score in the
check detail is the mitigation, so a reader can see the sample size.

**The corpus is twenty open-source apps.** They skew towards mature, long-lived projects
and away from the enterprise apps FoldReady is meant to sell to. The calibration is honest
about that: it is the best evidence available, not a representative sample of the market.

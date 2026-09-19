# FoldReady roadmap

Plan of record, updated 19 September 2026. The immediate objective is one paid manual
review, delivered with evidence and explicit coverage. The scanner is the instrument used
in that review. Customer demand and delivery effort remain unproven.

This replaces the launch-calendar sequence. A simulator, a new check, a platform for CI
or a new score calibration is not a prerequisite for a source review sold as such.
No Apple availability date is assumed by this plan.

## Verified repository state

- Engine version 0.5.0, result contract v5, seven possible source checks. Actual weights
  are normalized over applicable checks. Optional screenshot analysis adds a check.
- Findings have locations where available, confidence and static evidence labels.
- The existing local gate uses configured policies and versioned baselines. It does not
  establish a runtime defect or device compatibility.
- The index contains twenty v5 source audits. The large score changes across contracts
  are documented in [result-contract.md](result-contract.md); they are not app improvements.
- The continuity prototype exists. It does not establish Duo folding support, time savings
  or demand for this offer.

## Required to deliver the first review

1. Keep generated outputs honest. Separate source or screenshot signals, hypotheses,
   recorded runtime observations and coverage gaps. Show confidence, available evidence,
   the next verification and an explicitly unvalidated tool order. Preserve v5 scoring
   and gate behavior. Optional review metadata is documented in the result contract.
2. Prepare one example review under [readiness-review.md](readiness-review.md). Record
   source revision, relevant target, scanner version, scope and excluded areas. A reviewer
   confirms applicability and assigns priorities from journey impact, not score thresholds.
3. Agree a pilot with one buyer: access, one app revision, up to three journeys, delivery
   date and payment terms. Validate willingness to pay; neither prospects nor a listed
   price prove demand. The example, prospect list and offer preparation are separate work.
4. Deliver the reviewed findings, next actions and coverage matrix. Every unexecuted test
   stays not tested. If access or a build is unavailable, name the limitation and its impact
   on conclusions. A source-only delivery must have been agreed as such.
5. Record actual review time separately from correction time and scanner hour estimates.
   Complete the agreed follow-up. Success is a delivered, paid review with measured hours,
   not a higher score or a newly published feature.

Technical exit checks: `Scripts/check.sh` passes; the golden payload changes only by
additive review metadata; existing gate and scoring tests pass. No deployment or publication
is needed to make these changes reviewable.

## Deferred until buyer evidence justifies them

- New checks, safe-area detection, broader language coverage or a syntax tree.
- A commercial CI platform or hosted accounts. Maintain the existing local gate.
- A Duo harness, expanded simulator automation or more continuity features.
- Further score calibration. Do not change weights to make the index look better.
- More index entries, visual redesign or launch-calendar marketing.

An available runtime can support a separately agreed validation pass. It is not grounds to
claim that untested journeys, configurations or devices passed.

## Standing constraints

- A static score is a versioned summary, never a readiness threshold or an observed defect.
- Compare scores only under compatible contract, engine and coverage. Retain historical
  results as historical; a contract change is not an improvement in an app.
- Tool order and human priority are separate. A reviewer records the reason for priority,
  dismissed hypotheses and any optional improvements.
- Hours are unvalidated until compared with measured work; never promise delivery from them.
- Preserve existing contract keys, gate semantics and check references. Follow the contract
  policy for any future schema or scoring change.
- No invented Apple dates, device certification, prospect contact or publication as part
  of this implementation task.

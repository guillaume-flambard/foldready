# Continuity benchmark protocol

The decision threshold is at least 50 percent less human preparation time, with equivalent
detection and no increase in false failures. This repository supplies the comparison fixtures
and evidence collection. A timed participant session has not yet been conducted.

## Experimental controls

Use the same Mac, simulator, fixture revision and three journeys for both approaches.
Record the `source_sha256` from a completed full run. The participant must understand XCTest
and must not have authored the fixture faults. Show requirements, actions and expected outcomes,
but withhold defect locations. Keep raw measurements even when the generated approach loses.

For form, prepare explicit first; for cart, generated first; for draft, draw the order and record it.
Reuse the same recorder, build products and device setup. Count common installation once and
report it separately. Do not count simulator boot or compilation as human preparation.

Preparation starts when requirements are handed over. It ends when the scenario definitions
or explicit XCTest cases execute and the participant has checked the initial output. Include
editing, debugging, documentation lookup and assistance. Use the provided explicit suite as
a reference after the timed session, not as a copy-and-paste shortcut during it.

Diagnosis starts when an unfamiliar failing report is shown. It ends when the participant
identifies the violated invariant and reproduces the problem. Do not count time fixing the app.
Record learning effects, retries and tools used. Diagnosis is reported separately; it is not
subtracted from preparation to manufacture a gain.

## Timing input

Copy [the complete timing template](continuity-timings.template.json) into a private measurement file.
It contains twelve rows: each of the three journeys,
both approaches and both tasks. Replace all placeholders with observations. An incomplete file,
wrong source digest, missing notes or nonpositive timing is rejected.

```json
{
  "schema_version": 1,
  "source_sha256": "digest-from-result.json",
  "observer": "person-who-timed-the-session",
  "protocol": "docs/continuity-benchmark.md, with deviations recorded in notes",
  "measurements": [
    {
      "journey": "form",
      "approach": "generated",
      "task": "preparation",
      "seconds": null,
      "notes": "Record order, start/end, assistance, retries and raw timing reference"
    }
  ]
}
```

Allowed approaches: `generated`, `explicit`. Tasks: `preparation`, `diagnosis`.
Import with `--timings FILE` on a full simulator run. The exact timing data is retained in
the output report and explicitly marked self-reported. It is not independently verified.

Savings = `1 - total_generated_preparation / total_explicit_preparation`.
Negative savings remain negative. No missing observations are replaced with estimates.

## Decision

- Continue technical evaluation only with all three journeys, both approaches, passing fixed
  fixtures and every intended failure detected consistently on at least three repetitions.
- If those conditions and valid paired timings are present, savings of 0.5 or more pass the
  technical gate; anything lower produces `stop`.
- Missing timings, partial runs or an execution error leave the gate `not_evaluated`.
- A technical pass on injected faults is permission to test the product hypothesis with customers,
  not evidence of recurring demand or Duo support.

Keep a session ledger with participant, fixture digest, dates, method order, preparation and
diagnosis observations. Store customer material privately, outside the public repository.

## Commercial decision dates

Reference fixtures and comparison method: before 18 September 2026. Timed comparison target:
before 25 September, within five working days and 200 EUR external expense, excluding device purchase.
Before 29 September: five qualified conversations and two written commitments for paid pilots.
These are targets, not completed milestones or scheduled automations.

If the SDK cannot drive the required Duo transitions, do not promise Duo automation. If the
technical gain is absent, stop this implementation path. If prospects have another urgent problem,
revisit the target before expanding the product.

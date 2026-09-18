# Readiness review delivery scope

Offer updated 18 September 2026 against Apple's iPhone Duo announcement and developer sessions.

## Intake and agreement

The $349 review covers one app, one source revision and up to three critical journeys.
Record the owner, revision, supported platforms, target SDK, build instructions, access
constraints, available screenshots and business impact of each journey. Agree the delivery
date after confirming access. A request through the website opens an email draft and takes
no payment.

## Deliverable

For each item, record its category, location where available, evidence, consequence and
recommended action. Use three distinct categories:

1. Source signal: potential issue requiring confirmation, including SDK-conditioned migration requirements.
2. Observed defect: reproducible on a recorded app build and named environment, with steps, expected/actual behavior and screenshot or recording.
3. Optional improvement: a design decision, such as sidebar placement, with its expected benefit.

Include a prioritized plan, clearly labelled effort assumptions and test coverage table.
A scanner score alone never establishes a defect. If the app cannot be built, record that
limitation; do not present source review as runtime testing.

## Runtime matrix

All rows start as **not tested**. Record actual evidence before changing a row to passed
or failed. Mark a row not applicable only with a reason.

| Journey | App revision/build and linked SDK | Environment/runtime | Configuration | Result and evidence |
|---|---|---|---|---|
| Agreed journey | To record | To record | Outer display | Not tested |
| Agreed journey | To record | To record | Inner display | Not tested |
| Agreed journey | To record | To record | Open/close transition | Not tested |
| Agreed journey | To record | To record | Partial fold and rotation | Not tested |
| Agreed journey | To record | To record | Split View | Not tested |
| Agreed journey | To record | To record | Reserved regions | Not tested |
| Agreed journey | To record | To record | Arrangement views | Not tested |
| Agreed journey | To record | To record | Vertical bars | Not tested |
| Agreed journey | To record | To record | Camera direction | Not tested |

The last four rows carry the same surface names the scanner uses in its advisory findings
(`Reserved regions`, `Arrangement views`, `Vertical bars`, `Camera direction`), so a question
raised in the report has a row here that settles it. They are rows, not verdicts: a scanner
advisory is a question about the source, and only a recorded run turns it into evidence.

Check interactive controls against asymmetric safe areas, camera and hinge regions.
Check navigation, input, selection and scroll state across transitions. Do not add a
sidebar solely to increase a score. Do not require custom reserved-region APIs where
standard containers already provide the needed behavior.

## Included and follow-on work

The review includes source analysis, available screenshots reviewed in context, a test
plan and one follow-up review of the same scope within 30 days. Corrections and a later
Duo simulator pass are separately scoped and quoted, subject to tool availability and a
buildable app. Physical-device testing is not included. Do not promise App Store featuring
or full compatibility outside recorded test coverage.

Sources: [Apple tools and availability](https://developer.apple.com/iphone-duo/),
[preparation guidance](https://developer.apple.com/videos/play/tech-talks/111461/),
[adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/).

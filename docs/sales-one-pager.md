# FoldReady — one-page review example (unpaid sample)

**As of 25 October 2026.** This is an *illustration of the deliverable*, not a customer review or a pass on iPhone Duo. Source: [the full IceCubesApp sample](sample-review.md), prepared 19 September 2026. A future paid review must pin a fresh revision and re-run the scanner.

## What a team gets

A scoped assessment of **one app revision and up to three agreed critical journeys**: source findings reviewed by a human, consequence and priority by journey, a test matrix distinguishing observed results from untested hypotheses, and a prioritized work order. **$349** is the *unvalidated listed review price*, subject to access and scope agreement. A follow-up review within 30 days is included; code changes, simulator testing and physical-device testing are **not** included by default.

- **Free self-service:** local Swift scanner, JSON/HTML evidence, opt-in CI regression gate via the [GitHub Action](../action.yml).
- **Paid value to validate:** a person groups redundant signals, discards false positives, explains business-relevant impact and tells the team exactly what should be verified on a real app build.
- **Not sold:** compatibility certification, automatic remediation, App Store approval, verified ROI or a guaranteed number of engineering hours.

## Example: IceCubesApp (Mastodon client)

*Historical source snapshot; exact commit **not recorded**. Scanner 0.5.0 / contract v5; 274 UI files scored, 154 excluded; **no iPhone Duo build or runtime observations**. These are code-level hypotheses, not demonstrated defects.*

| Investigation | Evidence reported in the sample | Reviewer action / next proof |
| --- | --- | --- |
| Window geometry (review first) | `SceneDelegate.swift` stores `UIScreen.main.bounds`, falls back to it and polls window width. Six reported hits represent **one potential root cause**, not six defects. | Review actual scene / window lifecycle. On a pinned build, open then unfold and check whether layouts use stale dimensions. |
| Hidden wide-screen UI (review second) | `AppView.swift` combines a regular horizontal size class **and** an iPad/Mac idiom test to show a secondary column. | Confirm the received size class in the unfolded app before changing the device-idiom condition. |
| Scroll and selection continuity (review third) | The scanner flags 55 state-related files, including **at least one demonstrated false positive** caused by an enum case containing `List(`. | Test one critical timeline and account-list journey through resize; keep or dismiss the other flags only after review. |

The legacy scanner index score was 67/100 under v5. **Scores are not cross-version comparisons and do not mean “67% compatible”.** The recorded scanner estimate of 70 hours was unvalidated and is neither this review's price nor a remediation quote.

## Runtime evidence (all still NOT TESTED)

For an actual client build, agree the journeys, then record app revision, linked SDK, device/runtime, pose, steps, expected/actual result, and an artifact or log reference. Coverage should include closed, open, transition, rotation, partial fold, Split View, reserved regions, vertical bars and camera direction *only where actually exercised*. Unexecuted rows remain **not tested**. Simulation is not physical-device certification.

## Practical handoff

1. Agree one source revision, three journeys, scope, access, handover date and payment terms before running a review.
2. Run FoldReady, inspect source and screenshot evidence, group duplicate causes, dismiss misleading findings with reasons.
3. Assign human priorities based on journey consequence, not the score or automated “hours”.
4. Deliver concise findings, a proposed fix order, CI policy if useful, and a runtime-test matrix with no invented passes.
5. Time the actual assessment and request one paid validation before expanding the product.

**Apple context (confirmed 25 October 2026):** [Xcode 27.1 and Device Hub](https://developer.apple.com/news/?id=kkphp5qo) support Duo simulation. Apple's **App Resizability** skill supports SwiftUI and UIKit; FoldReady complements it with an independent audit/CI trail rather than claiming to outperform Apple's code edits. [Apple's iPhone Duo preparation talk](https://developer.apple.com/videos/play/tech-talks/111461/).

**Contact / scope:** [FoldReady website](https://foldready.memolabs.dev) — request a review; no payment is collected by the website today.

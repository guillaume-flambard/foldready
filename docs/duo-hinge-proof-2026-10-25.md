# First demonstrated iPhone Duo hinge continuity — synthetic fixture

**25 October 2026 · Completed and visually verified on a hosted iPhone Duo simulator.**
This is **not** a third-party application audit, physical-device test, full device-compatibility statement, nor evidence that a customer has paid for FoldReady.

**Reproduce:** [Merged PR #22](https://github.com/guillaume-flambard/foldready/pull/22), [CI run #40228317331](https://github.com/guillaume-flambard/foldready/actions/runs/40228317331) (all checks passed), [11-file evidence artifact](https://github.com/guillaume-flambard/foldready/actions/runs/40228317331/artifacts/12612177610) (**14-day retention**). [Probe implementation](../Scripts/probe_duo_hinge.py), [pinned runner workflow](../.github/workflows/duo-appium-hinge-pilot.yml), [evidence acceptance protocol](duo-runtime-evidence-protocol.md).

## Environment and evidence identity

| Property | Observed |
| --- | --- |
| OS/device | **iOS 27.1 iPhone Duo simulator**, UUID `4C56FCAC-377C-469C-B415-8ABBC4375CBA` |
| Toolchain | Xcode **27.1**, pinned Appium **3.7.0**, XCUITest driver **12.20.0** |
| App | **synthetic UIKit** `ContinuityDemo` form / fixed variant, `dev.memolabs.ContinuityDemo` |
| GitHub merge/test context | PR #22 head `2066bd2df79dc2c15cfbf8b2c9015557954230de`; runtime manifest records the ephemeral PR merge SHA `f16380da3e921ffcfb442d4522f96f15cbc4c771` |
| Evidence timestamp | `2026-10-25T20:10:16.589427+00:00` from `hinge-evidence.json` |
| Outcome | `passed_synthetic_fold_unfold_continuity` and `passed_synthetic_simulator` |

## Actual closed → open → closed result

| Step | **Measured** hinge angle | Selected display ID | **Observed** app window (points) | Form state |
| --- | ---: | ---: | --- | --- |
| Closed start | **0°** | **1** (cover) | **466 × 678** | `name = Ada` |
| Opened | **180°** | **3** (inner) | **951 × 669** | `name = Ada` |
| Reclosed | **0°** | **1** (cover) | **466 × 678** | `name = Ada` |

This was not a rotation test. Appium set simulated hinge angles through the provider's commands, independently read back the sensor value, switched to the active display, then **read the running app's accessible state and window geometry**. The initial closed window returned after closing. Each pose captured a real PNG of the selected display.

Three screenshots were downloaded **and visually inspected**. All show the real synthetic fixture with the `Ada` value on screen. PNG screenshot pixel dimensions are **1398 × 2034** (closed), **2852 × 2006** (opened), **1398 × 2034** (reclosed). Window geometry in the above table uses UIKit points and is intentionally not equated with screenshot pixels.

### Artifact integrity record

| Archived evidence file | SHA-256 |
| --- | --- |
| `hinge-evidence.json` | `15e110bd74b33c33925f61108fa1d6dd62d20cec163b4e68d99027b8b2f11d19` |
| `hinge-client.log` | `86382413c5b691ab295979d1d1dd953d26227f5041967b3a3e9f33b0e6b612b2` |
| `duo-before-closed.png` | `c69e7e43d288e0ba92d48dc4b6dc836f68c603f1175b77a157c5c4cd5e57dfa1` |
| `duo-opened.png` | `afc57bb07518e60fb8745c4f11748d4b2e2bdcdf977adb7c8693e6c9b1c93ca0` |
| `duo-reclosed.png` | `c194edff2609f6c4fc0f24328a5cc8941edbaa6d6fc7ace5972d4fac135dbb57` |

These hashes preserve artifact identity, **not storage**. The proof screenshots are in the [short-lived GitHub artifact](https://github.com/guillaume-flambard/foldready/actions/runs/40228317331/artifacts/12612177610). Do not imply they remain downloadable after retention expires; re-run the workflow on a compatible runner if necessary. No customer source or private screenshot appears in this evidence.

## Proof boundaries

**Verified:** simulator test app boot, foreground form action, `name = Ada` preservation, hinge angle readback at both extremes, switch between outer and inner display, changed app geometry and reversion to original geometry.

**Still not tested:** partial hinge poses, interrupted text entry/keyboard focus during motion, selection/scroll, multi-column navigation, Split View, multiple scenes, physical Duo hardware, third-party clients, long-term regression/flakiness, App Store review compliance. A successful **single synthetic fixture run** does not prove the overall FoldReady scanner detects these failures or that a customer will pay.

**Commercial claim permitted:** “FoldReady has an automated, evidence-checked iPhone Duo simulator continuity proof of concept on a synthetic UIKit form.” **Not permitted:** “Certified iPhone Duo-compatible apps”, “all adaptive journeys verified”, “customer case study” or “universal automated remediation”.

## Next evidence gate

Extend the synthetic fixture to **one scroll/selection journey and one adaptive multi-column journey**, preserving selection and navigation through hinge changes, and probe an intermediate hinge angle if Appium supports it reliably. Prioritize verified before/after state and visible actions over a long but untrusted screenshot catalog. Then pilot on **one authorized app revision** with explicit confidentiality rules, quote and actual operator hours. The [scope and sales offer](sales-one-pager.md) remain unvalidated commercially.

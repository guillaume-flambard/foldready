# iPhone Duo — reproducible continuity evidence protocol (v1, evidence-gated)

**Status (25 October 2026):** A [completed Appium Duo simulator run #40228317331](https://github.com/guillaume-flambard/foldready/actions/runs/40228317331) **verified a synthetic UIKit form during actual hinge closed (0°) → open (180°) → reclosed (0°)**. The app showed `name = Ada` across both displays and measured different window geometries; three real screenshots and sensor readings are archived. See the [verified evidence record](duo-hinge-proof-2026-10-25.md), [merged PR #22](https://github.com/guillaume-flambard/foldready/pull/22) and [issue #9](https://github.com/guillaume-flambard/foldready/issues/9). **Not tested:** actual client apps, partial folding, navigation/scroll, Split View or physical hardware.

**Hinge controls are now exercised in FoldReady:** [Appium XCUITest's official Duo guide](https://appium.github.io/appium-xcuitest-driver/12.19/guides/duo/) documents hinge-angle extensions; our pinned XCUITest driver **12.20.0** ran them successfully with **independent angle readback, window changes, state assertions and screenshots**. A set-angle command by itself is insufficient; all those checks remain mandatory. The result is confined to this synthetic form on an iOS 27.1 simulator.

**Environment update (25 October, 17:22 UTC):** iOS 27.1 runtime `24A94425` was installed, and an actual iPhone Duo simulator instance `FD909981-4733-435D-939C-1B4B2F7D1E70` completed CoreSimulator boot successfully. A GUI pose transition and any app launch **have not been observed**. The first-run preflight was the only completed step. Read the dated [preflight addendum](duo-preflight-2026-10-25.md) before attempting the protocol.

Companion: [review delivery scope](readiness-review.md), [research decision](market-and-offer-2026-10-25.md).

## A. First-run prerequisites (all must be explicitly recorded)

| Field | Evidence to capture | Never infer from |
| --- | --- | --- |
| `app_name`, `app_commit`, `bundle_id` | Version-control SHA and app ID used in launch | Name on the website, unrelated index clone |
| `scheme`, `configuration` | Exact Xcode scheme and Debug/Release | Existence of an Xcode project |
| `linked_sdk`, `xcode_build` | Actual build log/binary metadata and `xcodebuild -version` | README `LastUpgradeCheck`, current global SDK listing |
| `runtime`, `device_type`, `device_id` | Booted simulator details, Device Hub session | `simctl list devicetypes` alone |
| `journey`, `pose`, `steps`, `expected` | Agreed before execution | Post-hoc interpretation of images |
| `actual`, `result`, `artifact` | Capture from the named executable, date and operator | Static scanner score |
| `source_signals` | Detector IDs + inspected source locations and dismissals | Broad "X findings = X bugs" assumption |

Record **human setup time**, human review time, simulator execution time, fixes time and build time separately. No arbitrary “saved hours” or defect count inflation.

## B. Three small journeys on a synthetic demo

The first demo must be a **pinned, buildable fixture** (e.g. an app built specifically with a form, a list with persistent selection, and an adaptive detail pane). It need not pretend to represent a customer's app. Record injected failures as **synthetic**, not discovered. Use the current `Examples/continuity-demo` only if it builds under the verified SDK/runtime and can exercise the required behaviors; its existing rotation experiment does **not** exercise Duo folding.

1. **Form/draft:** type text, place caret and keyboard, close→open, open→partial fold, rotate, optionally Split View. Verify text, focus, available Save action and absence of occlusion.
2. **List/details:** select an item, scroll to a known record, change pose and return. Verify same selection/scroll state where requirements say it must survive, and absence of lost navigation.
3. **Navigation/actions:** show primary/secondary columns on larger canvas, use toolbar actions and overflow while keyboard is shown. Confirm accessible controls under asymmetric safe areas and vertical bars. Optional scene creation only if supported and explicitly part of fixture.

Test only configurations the environment really supports; `not_tested` and `not_applicable` (with reason) are valid outcomes, not failures.

## C. Pose matrix — initial state, all Not tested

| Journey | Closed outer | Open inner | Open→close transition | Partially folded | Rotation | Split View | Keyboard | Vertical bar/overflow |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Form and draft | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested |
| List selection | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested |
| Navigation/actions | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested |

Camera direction, scene accessories, hinge interaction and additional windows are **conditional** tests for apps actually using those features. Do not call them universal blockers. System navigation is expected to adapt automatically in many well-structured apps; test the risky custom surface rather than manufacture feature demands. [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo), [bars](https://developer.apple.com/videos/play/tech-talks/111462/), [multiple scenes](https://developer.apple.com/videos/play/tech-talks/111464/).

## D. Evidence record template (not an actual result)

Each row can be saved as private JSON (or translated to the [review worksheet](readiness-review.md)). Example intentionally **not tested**:

```json
{
  "evidence_schema": 1,
  "id": "form-open-close-001",
  "app": {
    "name": "Synthetic continuity fixture",
    "commit": null,
    "bundle_id": null,
    "linked_sdk": null
  },
  "environment": {
    "xcode_build": null,
    "runtime": null,
    "device_type": "iPhone Duo",
    "device_id": null,
    "controller": "Device Hub GUI"
  },
  "journey": "Form draft",
  "pose": "open_to_closed",
  "steps": ["Enter a draft", "Open the device", "Close the device", "Inspect the text and focus"],
  "expected": "Draft persists and its action remains reachable",
  "actual": null,
  "result": "not_tested",
  "evidence": [],
  "reason": "No open/close transition was executed on this app revision",
  "operator": null,
  "executed_at": null
}
```

### State transitions are evidence-gated

- `not_tested` ⇒ no `actual`, no executed timestamp, no assertion of passing.
- `passed` or `failed` ⇒ nonempty app commit, binary/SDK, runtime, actual observation, operator, date and at least one **real** image/video/test-log artifact identifier; repeatable steps recorded.
- `not_applicable` ⇒ a reason tied to scope and app capability.
- Failed observations must identify **expected vs observed**, not merely a screenshot with an interpreted score.
- Failures on synthetic injected fixtures must stay labelled “synthetic”; do not market as real-world app bugs.
- A passing observation for one build/pose **never** implies “certified compatible on all iPhone Duos”.
- Do not upload customer code or private runtime screenshots to this public repo. Store sensitive artifacts in the approved client environment.

## E. Minimal technical validation sequence

1. **Preflight:** confirm disk space and target architecture; list installed simulator runtimes/devices; install an appropriate **supported** runtime only after safe resource check. A device type without a runtime is not launchable evidence.
2. **Boot and provenance:** create/select an iPhone Duo instance, boot, log UUID, runtime and Xcode. For pose control use either manual Device Hub or version-pinned Appium/WDA hinge calls, with **hinge read-back plus app-geometry confirmation**; rotation alone is not a fold.
3. **Fixture:** pin a small repo revision and build with Xcode 27.1. Check the **linked SDK on the actual app build**. Avoid upgrading a customer project without consent.
4. **Manual test:** follow journey steps; capture before and after at named poses. Log system bar, reserved regions and scroll/selection changes. Repeat unexpectedly failing flows before diagnosing.
5. **Reconcile static scan:** for each candidate, identify reproduction or dismissal and impact on user journey. Store detector confidence separately from outcome.
6. **Report:** retain all not-tested rows; highlight 1–3 human-reviewed work orders, even if no bug is found. Record actual time/cost. Compare against [sample review](sample-review.md).

## F. Scope boundaries and resources

- Apple's [three-step guide](https://developer.apple.com/iphone-duo/prepare/) explicitly recommends the simulator and resized-window testing **after** its source skill.
- Apple demonstrates manual pose controls in [Device Hub](https://developer.apple.com/videos/play/tech-talks/111461/). Independently, Appium now provides [supported-in-driver hinge commands](https://appium.github.io/appium-xcuitest-driver/12.19/guides/duo/), not a built-in `simctl` hinge flag.
- [XCTest UI testing](https://developer.apple.com/documentation/xcode/testing) already validated a synthetic foreground interaction in FoldReady CI. [Appium's set-angle reference](https://appium.github.io/appium-xcuitest-driver/12.19/reference/execute-methods/#mobile-setsimulatedhingeangle) warns that asynchronous hinge commands must be followed by angle read-back, display selection and actual layout verification.
- [Maestro](https://maestro.dev/) and [BrowserStack](https://www.browserstack.com/app-automate) are candidates for reusable user journeys, but Duo pose and device availability must be empirically verified per provider.
- [App Store screenshot specs](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) list Duo resolutions and a future requirement. App Store assets are a **separate optional deliverable** from functional validation; actual app screenshots must comply with [2.3.3](https://developer.apple.com/help/app-review/guideline-reference/2-3-3-screenshots).

## G. First real fold/unfold pilot — validated on synthetic form; extend only with new evidence

Use Xcode 27.1+, XCUITest driver 12.17.0+ and WebDriverAgent 16.14.2+, pinned by exact versions; capture app revision, SDK, simulator UUID and initial hinge reading.

1. **Closed (0°):** select the outer display via `mobile: listDisplays` / `currentDisplayId`, set `name = Ada` in the *synthetic fixture*, verify its UI and capture evidence.
2. **Open (180°):** call `mobile: setSimulatedHingeAngle` with `angle: 180`; poll `mobile: getSimulatedHingeAngle` and wait for a **real window/layout change**. Select the inner display, assert the same `name = Ada` and capture the screen.
3. **Close again (0°):** request 0°, read back the actual angle, select the outer display and confirm state and controls remain accessible.
4. Record before/after geometry, angle and active display separately from API return codes. Fail closed if any are missing; do not relabel rotation as a hinge operation.

Appium's extension has only been tested by its maintainers on a **simulator**, not proven here on a physical Duo. Further poses, Split View, keyboard, camera and physical-device observations stay `not_tested` until independently executed. No private customer source or screenshots belong in public workflow artifacts.

**Exit gate:** one recorded working fixture with at least the form or list pose transition, evidence artifacts, machine/app provenance, and clear “not tested” remaining rows. Until then, the runtime-validation offer is **not** a verified shipped capability.

# iPhone Duo simulator preflight — 25 October 2026

**Evidence status:** environment inventory performed via Memo Bridge on the owner's Mac on 25 October 2026. **No app has been launched or tested on iPhone Duo**, and no screenshots/videos of a journey were captured. This is the evidence-gated starting point for [the readiness review](readiness-review.md), not a compatibility result.

## Apple capabilities (public, not local test claims)

- [Apple Developer, 5 October 2026](https://developer.apple.com/news/?id=kkphp5qo): Xcode 27.1 development support and Device Hub for Duo pose and orientation simulation.
- [Apple Tech Talk: Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/): open, close, rotate and fold controls in Device Hub; App Resizability skill now supports both SwiftUI and UIKit.
- [Apple iPhone Duo preparation](https://developer.apple.com/iphone-duo/prepare/): resizable simulator, iPhone mirroring and Duo simulator are distinct testing surfaces; do not substitute a generic resize for all fold transitions.

## Actual Mac inventory

| Command run | Recorded output / finding | Interpretation |
| --- | --- | --- |
| `xcodebuild -version` | `Xcode 27.1`; build `27A9275` | Installed Xcode major/minor supports the Duo SDK/tooling. |
| `xcode-select -p` | `/Applications/Xcode.app/Contents/Developer` | Active Xcode toolchain path. |
| `xcodebuild -showsdks` | `iphoneos27.1`, `iphonesimulator27.1` | SDK **installed**; not equivalent to having a usable simulator runtime. |
| `xcrun simctl list runtimes` | One visible iOS runtime: `iOS 27.0 (27.0 - 24A434)` | **No iOS 27.1 runtime verified**. |
| `xcrun simctl list devicetypes` | Contains `iPhone Duo (com.apple.CoreSimulator.SimDeviceType.iPhone-Duo)` | Device **type** installed; not evidence of a created/bootable instance. |
| `xcrun simctl list devices available` | `== Devices ==` followed by `-- iOS 27.0 --` and **no device rows** | **No available simulator device instance**, Duo or otherwise. |

All commands were read-only; outputs are a dated snapshot. The fact that the Duo device type is installed **does not prove that Device Hub can run a Duo configuration on this machine**. Check GUI availability separately; do not use the presence of a device-type string as a passing test.

## Next safe actions before runtime validation

1. Check Xcode Settings → Platforms for a usable **iOS 27.1 or later simulator runtime** and available storage. On this 16 GB RAM Mac, avoid booting multiple simulators or starting an unapproved multi-GB download; budget disk and runtime resources first.
2. Install/download the appropriate supported runtime if necessary, verifying integrity and storage. Use Device Hub to create or select iPhone Duo and confirm it **boots** with the intended iOS runtime.
3. Pin one small, buildable test fixture commit; record the build target, `SDKROOT`, linked SDK, build configuration, app build identifier and simulator details. Native iPhone Duo screenshots should be captured in the supported Xcode workflow, not approximated by arbitrary geometry.
4. Capture launch and the three agreed user journeys with step-by-step expected and actual observations, each pose and transitions, and links to screenshots/recordings in a local/private artifact store.
5. Reconcile each observed defect with source signals and false positives; only then update the `passed` / `failed` fields in a report.

## Initial coverage matrix

All rows below are **not tested**, including any states supported in principle by Apple's tooling. A “pass” needs a specific app revision/build, linked SDK, device/runtime, test steps and recorded evidence. More granular journey-by-journey records belong in the final pilot worksheet.

| Surface | Current status | Reason |
| --- | --- | --- |
| Outer display / closed pose | Not tested | No simulator instance and no app build run |
| Inner display / unfolded | Not tested | Same |
| Open / close transition | Not tested | Same |
| Partially folded pose / hinge interactions | Not tested | Same |
| Rotation | Not tested | Same |
| Split View and secondary window/scene | Not tested | Same |
| Asymmetric safe areas / reserved regions | Not tested | Same |
| Vertical bars / custom arrangement views | Not tested | Same |
| Camera-facing display / camera controls | Not tested | Same |
| Scroll position, selection, draft entry during transition | Not tested | Same |

## Definition of progress

The environment is **partially provisioned** (SDK and device type present, runtime/device not usable yet). This document clears the *inventory* work but **does not complete issue #9**. The issue should remain open until a real, reproducible example journey and evidence ledger exist. Do not auto-close issue #9 from the PR.

Do not equate `foldready verify --build` taking one launch screenshot with testing all these poses; that is currently outside the scanner's demonstrated scope.

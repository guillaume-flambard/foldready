# Real execution evidence: iOS 27 UIKit scene lifecycle

**Reproducible synthetic-app case study — 25 October 2026. Not a customer audit, not a paid project, not an iPhone Duo fold/compatibility certificate.**

**Context.** Our small [UIKit continuity-demo fixture](../Examples/continuity-demo/App/App.swift) originally created a `UIWindow(frame: UIScreen.main.bounds)` inside `UIApplicationDelegate`, without an iOS scene manifest. It was built with Xcode 27.1 / iOS 27.1 SDK for the **iPhone Duo simulator**.

## Observed before/after

| Phase | Reproducible result | Evidence |
| --- | --- | --- |
| Before correction | **Build succeeded** and `simctl launch` returned a PID; the outer display screenshot was the iOS SpringBoard with the installed app icon, not a running app UI. | [Early raw-smoke run #40217707208](https://github.com/guillaume-flambard/foldready/actions/runs/40217707208) — screenshot artifact. |
| Foreground gate added | Genuine XCUITest **failed**: app crashed; fixture heading/button were not found; one test recorded six assertion/test failures. | [Failing run #40218638250](https://github.com/guillaume-flambard/foldready/actions/runs/40218638250), `ExplicitTests.testDuoForegroundJourney` output and `.xcresult`. |
| Technical fix | Replaced the legacy `AppDelegate` window with `SceneDelegate` and `UIWindow(windowScene:)`; added `UIApplicationSceneManifest` to bundled `Info.plist`. | [Merged PR #18](https://github.com/guillaume-flambard/foldready/pull/18), diff and build manifest check. |
| After correction | **1 XCUITest passed, 0 failures** in 15 seconds. Foreground heading visible, `step1` button tapped, `name` changed to **Ada**, and window geometry available. Both simulator display PNGs and test bundle retained. | [Success run #40219952552](https://github.com/guillaume-flambard/foldready/actions/runs/40219952552) and [earlier equivalent run #40219790904](https://github.com/guillaume-flambard/foldready/actions/runs/40219790904). |

## Root cause and remediation

UIKit applications linked against the current iOS 27 SDK need a scene-based lifecycle. A source-only review can detect a suspicious legacy window entrypoint, but only an **executed app build with a foreground UI assertion** distinguishes a real startup failure from a harmless source pattern. The fixture fix was a deliberate SDK migration, not a novel Duo-only layout detector.

Apple: [Transitioning to the UIKit scene-based life cycle](https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle) and [preparing for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/).

## What the report does NOT prove

- The Duo's hinge **was never moved** in the successful foreground test. Two screenshots from different display IDs in the **same closed pose** are not a fold/unfold transition.
- The inner display screenshot was black in that pose; it is not evidence that a real app fails on the inner screen.
- Device-rotation testing [failed its geometry assertion](https://github.com/guillaume-flambard/foldready/actions/runs/40220878657): accepting `XCUIDevice.shared.orientation` did not change app window dimensions. The [PR #20](https://github.com/guillaume-flambard/foldready/pull/20) was closed without merging.
- A new [Appium hinge experiment PR #22](https://github.com/guillaume-flambard/foldready/pull/22) is **experimental**; its success must be verified from actual logs/artifacts before claiming fold continuity.
- No external app, customer repo, purchase, real hardware or saved engineering hours were involved.
- Historical GitHub Action artifacts have limited retention (14 days); PR links, fixture source, test scripts and CI logs remain the re-execution reference.

## Why this matters for a product team

A readiness report should present the **app revision and SDK**, the *observed* symptom, a defensible root-cause hypothesis, the small source change, a concrete acceptance test, the **real test result**, and unexecuted rows labelled `not_tested`. A score cannot replace the record.

This is an example of FoldReady's evidence process, **not evidence of customer demand**. [See the $349 source-only review scope](sales-one-pager.md) to distinguish the current paid hypothesis from separately scoped execution, testing and code changes.

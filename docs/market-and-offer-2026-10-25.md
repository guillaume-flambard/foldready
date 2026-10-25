# FoldReady — product research and launch decision (25 October 2026)

**Decision type:** product hypothesis and go-to-market plan, **not** a claim of commercial traction.  
**Evidence cutoff:** 25 October 2026. **Owner's repo reality:** Swift CLI v0.5.0, contract v5, source checks, JSON/HTML reports, GitHub Action, 20 historical source audits, scoped $349 human review, experimental XCTest continuity comparison. No documented paying client, no Duo pose test evidence. See [roadmap](roadmap.md), [sample review](sample-review.md), [Mac preflight](duo-preflight-2026-10-25.md) and [prospects](prospects-2026-10-25.md).

## Executive decision

**Lead with a focused human diagnosis supported by the free scanner, not with an “iPhone Duo compatibility score”.** Sell a reproducible answer to: **“Which critical app journeys might fail when the available canvas changes, what have you really tested, and what do we fix first?”** Keep source-only review separate from observable runtime validation. Win one paying pilot and measure actual delivery time before building a SaaS, extending scoring or promising an automated fold harness.

iPhone Duo is a timely door-opener; the defensible product category, if validated, is **adaptive iOS release evidence** (iPhone Duo, iPad window resizing, iPhone Mirroring and future form factors). Apple itself advocates using traits / scene geometry rather than hardware detection. This broader category is a **strategic hypothesis**, not proof of a larger paying market. [Apple preparation guide](https://developer.apple.com/iphone-duo/prepare/).

### Evidence hierarchy

- **Confirmed by Apple:** Xcode 27.1 and Device Hub support open/close/fold/rotate tests. The Xcode **App Resizability** skill finds many source issues and proposes fixes in SwiftUI and UIKit, but Apple explicitly tells developers to check what it misses, then test resizing. [Apple preparation guide](https://developer.apple.com/iphone-duo/prepare/), [Apple Tech Talk](https://developer.apple.com/videos/play/tech-talks/111461/).
- **Confirmed by Apple:** The UI changes across poses and Split View; asymmetric safe areas, reserved regions, vertical toolbar content/overflow, scene transitions, and state continuity warrant intentional review. Existing apps can run without recompilation; full inner-screen behavior depends on the linked SDK. [HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo), [adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/), [vertical bars](https://developer.apple.com/videos/play/tech-talks/111462/), [multiple scenes](https://developer.apple.com/videos/play/tech-talks/111464/).
- **Early evidence, not representative market data:** Contemporary reviews report inconsistent third-party app optimization and black bars or awkward layouts. No review identifies FoldReady's buyers or proves their willingness to pay. [WIRED review](https://www.wired.com/review/apple-iphone-duo), [Tom's Guide reviewer synthesis](https://www.tomsguide.com/phones/iphones/polished-but-rough-the-common-flaws-in-the-iphone-duo-found-by-nine-different-reviewers).
- **Community signal, self-selected:** Some iOS developers worry about device-idiom conditionals and adaptation cost; others expect native frameworks to manage it or do not expect enough Duo users to justify work yet. [r/iOSProgramming discussion](https://www.reddit.com/r/iOSProgramming/comments/1wbxxj3/iphone_duo_is_official_how_much_work_is_this/). Do **not** treat opinions or votes as a market-size estimate.
- **Owner's demonstrated evidence:** Only source scans, historical human sample, CI gate and synthetic rotation prototype exist. The Mac had Xcode 27.1 and a Duo simulator *device type* but no iOS 27.1 runtime or available simulator instance on 25 October. **No Duo pass may be claimed.** [Actual preflight](duo-preflight-2026-10-25.md).

## Competitive landscape: what FoldReady should NOT rebuild

| Alternative | What it already provides | What FoldReady might add, conditionally | Evidence |
| --- | --- | --- | --- |
| [Duo App Support](https://duoappsupport.com/) (independent tracker) | Public per-app **claimed** support status: unverified, not optimized, limited, fully supported. Snapshot on 25 October: 622 unverified, 11 unoptimized, 3 limited, 14 fully supported **as classified by that site**. | FoldReady should **not** build another unsupported crowd leaderboard; its value hypothesis is source-linked diagnoses, named app-build/pose evidence and an actual owner. Tracker classifications alone are not test artifacts and may become stale. | [Live tracker](https://duoappsupport.com/) |
| Apple App Resizability + Xcode/Device Hub | Finds many layout patterns, recommends edits, lets developer see and test poses. **Free platform-native solution.** | Written evidence matrix, reviewed impact on actual business journeys, versioned regression policy, independent sign-off of *what was or was not tested*. | [Apple](https://developer.apple.com/iphone-duo/prepare/) |
| Apple XCTest / XCUITest and Swift Testing | Existing iOS unit, integration, UI and performance test foundations. | A reproducible **test plan and acceptance worksheet** that integrates existing tests; not another UI-runner. | [Apple Xcode testing](https://developer.apple.com/documentation/xcode/testing) |
| [Maestro](https://maestro.dev/) | Open-source human-readable YAML E2E flows for iOS/Android/web and cloud execution. | Duo-specific **manual pose coverage and proof linkage** when normal tap-flow tools don't exercise the hinge. **No claim that Maestro cannot test Duo** without investigation. | [Maestro](https://maestro.dev/) |
| [BrowserStack App Automate](https://www.browserstack.com/app-automate) | Appium/XCUITest test execution on large real-device clouds. | Thin, auditable plan and source diagnosis; **not** competing on cloud device fleet. Actual iPhone Duo fleet availability unverified. | [BrowserStack](https://www.browserstack.com/app-automate) |
| [Bitrise](https://bitrise.io/) | Mobile build/test/distribution CI and release infrastructure. | App-specific readiness evidence and gate that can fit into a team's existing CI. | [Bitrise](https://bitrise.io/) |
| [Applitools](https://applitools.com/platform-pricing/) / [Percy](https://percy.io/blog/app-visual-testing) | Visual regression platforms and screenshot comparisons; execution/coverage vary by product. | Link visual results to pose/scene states, actual severity and suggested remediation. No “AI visual diff” until a proven sample exists. | Vendor documentation |
| A native iOS agency / experienced in-house team | Knows code, can run simulator, write fixes and perform QA. | Only value if independent analysis or a subcontracted repeatable QA package saves **measured** time; this may be **zero**, a commercial risk. | Test in [agency discovery](pilot-outreach.md) |

**Hard moat check:** Apple already detects source issues and helps fix them. A generic scanner, magic 0–100 score, custom device simulator, CI service, or claims of “certified Duo compatibility” are poor differentiators. FoldReady must show **better prioritization and trustworthy reporting, not more numbers**. The repo's changing score contracts and false positives make this especially important ([sample review](sample-review.md)).

**Conspicuous contemporary reports:** [9to5Mac's 21 October review](https://9to5mac.com/2026/10/21/iphone-duo-review/) demonstrates visual differences across binaries built with iOS 26, 27 and 27.1. [Les Numériques, 23 October](https://www.lesnumeriques.com/telephone-portable/iphone-duo-ses-deux-ecrans-reservent-une-mauvaise-surprise-aux-premiers-acheteurs-n263659.html) reports issues with several French-use apps, while [Numerama](https://www.numerama.com/tech/2355747-test-de-liphone-duo-le-produit-apple-le-plus-cool-depuis-10-ans.html) reports examples predating release. These are **dated observations on reviewer builds**; do not use them as enduring claims or unsolicited public bug accusations. A pilot offer should ask the current app owner to validate the exact shipped build and workflow, not assume a review's screenshot is still reproducible.

## Jobs-to-be-done and segments

| Segment / use case | Trigger | Buyer hypothesis | Sales friction | Priority |
| --- | --- | --- | --- | --- |
| Small established iOS app with custom navigation, editor, camera or media surfaces | Existing users can encounter broken continuity or clips after SDK rebuild | Founder / maintainer | May fix itself with Apple's skill; $349 is not established willingness to pay | **First individual pilot** |
| Native iOS agency with 3+ client apps | Needs consistent review handoff, test plan, QA evidence without another internal process | iOS tech lead / delivery manager | Already sells QA; product must complement rather than lecture | **First partner interviews** |
| B2B product with revenue-critical form or purchase flow | Keyboard, draft, selection or checkout progress interrupted on resize | Product lead / CTO | Requires access to private repo, legal/security approvals | Later once pilot proven |
| Camera/media editing or custom multi-scene app | Hinge, scene accessory, custom bars, camera direction | Specialist team | Requires deeper expertise and a real Duo setup | Later specialist offer |
| Indie app with low Duo usage | Wants screenshots / badge, maybe no code risk | Solo developer | Tiny available budget; likely Apple tooling enough | Low priority |
| Mobile teams outside native iOS | React Native / Flutter adaptive layout validation | Mobile lead | Current scanner reads Swift/Plist, not Dart/JS; do not sell source coverage | Explicitly out of scope |

### Concrete risk matrix to discuss with customers

| Risk | User-visible consequence to investigate | Evidence required | Apple technical reference |
| --- | --- | --- | --- |
| Wrong viewport / main screen assumption | Cropped or off-center UI after unfold or Split View | App build, source call site, pose and actual UI capture | [Preparation](https://developer.apple.com/iphone-duo/prepare/) |
| State / navigation continuity | Form draft, selection or scroll lost when a window changes size | Start state, steps for fold/unfold, after-state screenshot / log | [HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) |
| Asymmetric safe-area / hinge / camera | Important tap target hidden, overlay collides with reserved area | Recorded runtime pose and interactive control location | [Adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/) |
| Vertical bar / overflow | Core action disappears in overflow, controls lose priority | Closed / open / keyboard transition with visible action list | [Vertical bars](https://developer.apple.com/videos/play/tech-talks/111462/) |
| Multi-window / Split View | Wrong document/session, unexpected scene creation or failed second window | Named scene, window creation outcome, state isolation | [Scenes](https://developer.apple.com/videos/play/tech-talks/111464/) |
| SDK and build assumptions | Rendered area differs from assumed capabilities | Linked SDK from **actual built binary**, compiler version and runtime | [Preparation](https://developer.apple.com/videos/play/tech-talks/111461/) |
| Store listing / screenshot preparation | Incorrect dimensions or assets that don't show the app actually running | Screenshots of real app on correct device/simulator; source and asset check | [Specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [2.3.3](https://developer.apple.com/help/app-review/guideline-reference/2-3-3-screenshots) |

**Screenshot nuance:** Apple's specifications state that starting **April 2027**, Duo screenshots are required for apps using the **iOS 27.1 SDK or later**; October App Store Connect notes use broader language. Re-check submission criteria then, do not promise an automatic review rejection or claim every app must immediately ship assets. Exact Apple sizes: outer **1398×2034** or **2034×1398**; inner **2007×2853** or **2853×2007**. Supplying Duo screenshots now can add a product-page badge, but is **not** a verified conversion uplift.

## Proposed offer ladder (hypotheses, not measured prices)

1. **Free — FoldReady Source Baseline.** Public repo/CLI + local JSON/HTML report and opt-in GitHub Action. No customer code upload required. A *score is not a compatibility verdict*. Purpose: trust, transparent methodology and low-friction entry.
2. **$349 — Human Risk Review (sellable with current verified capabilities).** One app/target revision, up to **three selected critical journeys**, human triage/dismissal of source findings, priority by user impact, SDK/build assumptions, specific test checklist, documented blind spots and one follow-up review under existing 30-day terms. **Source + supplied screenshots only** unless separately agreed. No simulator pass, no fixes, no device certification, no instant turnaround promise. Source access and date agreed before payment. **This is the existing repo offer and an unvalidated price hypothesis.**
3. **Scoped quote — Duo Continuity Validation (NOT available as proven service yet).** Only after a reproducible local device+runtime is bootable: execute agreed journeys across supported poses, record app SHA, linked SDK, actual runtime, steps, expected/observed result and media evidence. Distinguish simulator from physical device. Pricing, duration and feasibility assessed case by case. Not every pose is scriptable with XCUITest; start with **manual Device Hub**.
4. **Scoped quote — Fix-and-Verify Sprint (NOT included in $349).** Developer implements agreed high-impact issues; regression tests and before/after evidence on a named build. For in-house/agency teams, FoldReady can supply a work order and check; do not imply the tool auto-fixes every issue or accepts a runtime failure as solved when only a string changed.

**Discard for now:** a monthly subscription, automatic paid “certification”, physical test farm, an invented single-device crowd benchmark, generic screenshot generator, unsupported React Native source scoring, an “AI-powered compatibility percentage,” and a big backend/hosting build. They add scope without buyer evidence.

## What the sales website must demonstrate

- A **concrete three-finding example** above the fold or one click away, from [IceCubesApp](sample-review.md). Label it historical, source-only, no pinned SHA and no Duo runtime test. Show one dismissed false positive to demonstrate review discipline.
- A buyer-friendly contrast: **free scanner finds candidates → human validates relevance → separately scoped tests can reproduce behavior → team fixes with acceptance evidence**.
- A privacy-led workflow: run the scanner locally, share a redacted report or schedule a private source review; never suggest sharing client secrets publicly.
- A single CTA matching actual capacity: **Request the $349 source review**. The form opens a *mail draft* and must not claim submission or payment. Option to discuss a validation/fix quote without selling absent test coverage.
- A clear “what is excluded” line before the CTA. Link official Apple SDK / screenshot guidance; never use fear that an app will be universally rejected.
- Use retained design tokens and no new visual toolkit just to restyle an unvalidated offering.

## Execution sequence and falsification gates

**Immediate code/docs:** Publish this researched decision; update marketing copy and add a publicly accessible sample link. Preserve existing contract v5, scoring and CI semantics. Do **not** create a new scoring check on the strength of a source string. The website is a static export; compile it in CI.

**Instrumentation/credibility:** Reproduce **one** fully evidenced Duo simulator journey on a small fixture, after confirming installed runtime, available disk, pose control and real app build. Record manual setup friction and time. Evaluate third-party existing XCUITest/Maestro or visual libraries **before** creating a runner. No “tested” statuses until evidence exists.

**Demand test:** Interview at least **5** relevant contacts selected from researched agency/indie list; record whether they already solve the problem, which artifact they need and whether they can authorize a $349 **source-only** paid pilot. No conversion or outreach event until it happened. Attempt **one paid review** and record preparation/review/test/follow-up hours separately; if access, legal/security or runtime needs dominate, revise scope/pricing rather than silently expanding service.

**Stop/reconsider triggers:**
- 5 qualified interviews show **zero willingness to pay** for source-only diagnosis, and all want execution/fixes → switch to a **fix-and-verify consulting package** if the skills/environment are proven; don't build recurring SaaS.
- Human source review requires more hours than the $349 offer can sustainably cover → quote narrower scope or change pricing after measurement.
- Automated hinge controls now exist in [Appium XCUITest](https://appium.github.io/appium-xcuitest-driver/12.19/guides/duo/) (12.17.0+); **they are not yet exercised in FoldReady CI**. Require angle read-back, active-display switching and actual app state continuity before claiming automation. If they fail in our pinned environment, fall back to manual Device Hub instead of faking a fold through rotation.
- New Apple tooling already produces equivalent third-party audit artifacts → focus on the real client workflow or stop, not a duplicative feature.

## Research sources (primary and differentiated)

1. [Apple — Three steps to prepare](https://developer.apple.com/iphone-duo/prepare/) (SDK, new skill, resize and simulator).
2. [Apple — Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) (continuity, hinge and layouts).
3. [Apple — Prepare your app Tech Talk](https://developer.apple.com/videos/play/tech-talks/111461/) (SDK 27.1, Device Hub, safe areas).
4. [Apple — Adaptive layouts Tech Talk](https://developer.apple.com/videos/play/tech-talks/111463/) (arrangement and reserved regions).
5. [Apple — Vertical bars Tech Talk](https://developer.apple.com/videos/play/tech-talks/111462/) (actions/overflow/priority).
6. [Apple — Multi-display and scenes Tech Talk](https://developer.apple.com/videos/play/tech-talks/111464/) (second window, hinge, accessories).
7. [Apple — Store screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).
8. [Apple — Screenshot review policy 2.3.3](https://developer.apple.com/help/app-review/guideline-reference/2-3-3-screenshots).
9. [Apple — App Store Connect October notes](https://developer.apple.com/help/app-store-connect/release-notes/).
10. [Apple — Xcode UI and testing](https://developer.apple.com/documentation/xcode/testing).
11. [Apple — iPhone Duo launch developer showcase](https://www.apple.com/newsroom/2026/10/developers-bring-incredible-new-app-experiences-to-iphone-duo/) (proof some teams *already* invested).
12. [Maestro](https://maestro.dev/) and [Maestro open source](https://github.com/mobile-dev-inc/maestro).
13. [BrowserStack App Automate](https://www.browserstack.com/app-automate).
14. [Bitrise](https://bitrise.io/) and [2026 mobile development report](https://bitrise.io/reports/state-of-mobile-development-2026).
15. [Applitools](https://applitools.com/platform-pricing/) / [Percy](https://percy.io/blog/app-visual-testing).
16. [WIRED iPhone Duo review](https://www.wired.com/review/apple-iphone-duo) and [Tom's Guide review synthesis](https://www.tomsguide.com/phones/iphones/polished-but-rough-the-common-flaws-in-the-iphone-duo-found-by-nine-different-reviewers).
17. [r/iOSProgramming developers' early discussion](https://www.reddit.com/r/iOSProgramming/comments/1wbxxj3/iphone_duo_is_official_how_much_work_is_this/) (low-confidence demand signal, not market sampling).

18. [Appium XCUITest driver 12.19 — Duo automation](https://appium.github.io/appium-xcuitest-driver/12.19/guides/duo/) (hinge angle get/set, display routing; documentation updated 19 October 2026, simulator-only validated by provider).

**Evidence update, 25 October:** FoldReady [PR #18](https://github.com/guillaume-flambard/foldready/pull/18) fixed the synthetic UIKit fixture's missing iOS 27 `UIScene` lifecycle and verified a real foreground form interaction on a Duo simulator with XCUITest (1 test, 0 failures). This is **not** the same as an open/close continuity test, a client app review, or paid demand. A follow-on [rotation test PR #20](https://github.com/guillaume-flambard/foldready/pull/20) is under evaluation; do not count it as executed until its CI passes.

**Result of research:** no verified source proves an unoccupied SaaS niche, an appropriate $349 margin, recurring buyers, or an independently reproducible fold bug. The strongest actionable hypothesis is **client-specific evidence + priority + optional remediation**, validated through actual paid work.
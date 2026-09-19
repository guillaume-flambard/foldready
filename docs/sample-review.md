# Sample review: IceCubesApp

This is a worked example of the $349 readiness review, produced from a scanner run that
already existed. No code was written to make it. It exists so a developer can see the shape
of the deliverable before deciding whether to buy it. It is a sample, not a delivered
review: there is no buyer, no agreed journey and no runtime pass, so the fields a delivered
review fills in are marked as such below.

The app is IceCubesApp (Dimillian/IceCubesApp), an open-source Mastodon client. The audit is
of the source at a shallow clone, contract v5 of the result format. The score at the time of
writing is 67/100, grade B, and the app has no launch blockers: it adopts the UIScene
lifecycle, so nothing here is about the app failing to start.

What follows is three findings out of 78 the scanner reported. The other 75 are not withheld
to look thorough. They are either duplicates of these, low-value, or wrong, and the last
section says which.

## Recorded alongside the score

| Field | Value |
|---|---|
| App and target | IceCubesApp, Swift iOS client |
| Source revision | Not recorded: the index audit ran against a shallow clone |
| Engine and contract | foldready 0.5.0, result contract v5 |
| Score | 67/100, grade B |
| Coverage | 274 UI files scored, 154 files excluded, unreadable files not recorded |
| Findings reported | 78 |
| Prepared | 19 September 2026 |

The score is a versioned summary, not a readiness threshold. It describes this app under
this contract, engine and coverage, and nothing outside that envelope. An earlier audit of
the same app, recorded 10 August 2026 in a format that carries no contract version, reports
78 and grade A. The two numbers are not comparable and this document does not treat the
difference as a change in the app.

## Intake, for a real review

A paid review agrees these before work starts. They are all open here because the sample has
no buyer.

- App owner and one source revision.
- Supported platforms and target SDK.
- Build instructions and access constraints.
- Available screenshots.
- Up to three critical journeys and the business impact of each.

## How to read this

A finding is not a defect. It is a source signal with a location and a consequence, and it
needs a human to decide whether it matters. Every finding below states what was seen, why it
is worth attention, what the change would be, and what only running the app can settle.
Nothing here is a claim that the app fails on iPhone Duo. No Duo build has been run, and no
Duo simulator exists yet to run it on.

Items are sorted into the three delivery categories. There are no observed defects in this
sample, because no app build was run.

## Runtime matrix

All rows start as not tested. A row changes only with a named build, environment, steps and
recorded result. The agreed journeys for this sample are the timeline, the account lists and
the sidebar.

| Journey | App revision/build and linked SDK | Environment/runtime | Configuration | Result and evidence |
|---|---|---|---|---|
| Timeline, account lists, sidebar | To record | To record | Outer display | Not tested |
| Timeline, account lists, sidebar | To record | To record | Inner display | Not tested |
| Timeline, account lists, sidebar | To record | To record | Open/close transition | Not tested |
| Timeline, account lists, sidebar | To record | To record | Partial fold and rotation | Not tested |
| Timeline, account lists, sidebar | To record | To record | Split View | Not tested |
| Timeline, account lists, sidebar | To record | To record | Reserved regions | Not tested |
| Timeline, account lists, sidebar | To record | To record | Arrangement views | Not tested |
| Timeline, account lists, sidebar | To record | To record | Vertical bars | Not tested |
| Timeline, account lists, sidebar | To record | To record | Camera direction | Not tested |

## Finding 1: the scene delegate freezes a screen size and then polls to keep it

**Category:** source signal, requiring confirmation.
**Source:** `Packages/DesignSystem/Sources/DesignSystem/SceneDelegate.swift`, lines 11, 12,
44, 45, 66, 70. Check `adaptive-layout`, six findings, all confidence high.
**Evidence:** six reads of `UIScreen.main.bounds` in one file, reported as six findings.
**Priority: first.** This is the only finding that a foldable would expose as a visible wrong
behavior rather than a missed improvement.

**Hypothesis.** One root cause with three parts, not six independent reads.

The two stored properties are initialized from the main screen:

```swift
public private(set) var windowWidth: CGFloat = UIScreen.main.bounds.size.width
public private(set) var windowHeight: CGFloat = UIScreen.main.bounds.size.height
```

That value is captured when the object is constructed, before any window exists. On a
foldable, the width at that moment is the width of whatever pose the device was in.

`setup()` then overwrites it from the real window, with the main screen as fallback:

```swift
windowWidth = window?.bounds.size.width ?? UIScreen.main.bounds.size.width
```

And a static observer task re-reads the window every 100 milliseconds forever, again falling
back to the main screen:

```swift
private static let observer = Task { @MainActor in
  while true {
    try? await Task.sleep(for: .seconds(0.1))
    for delegate in observedSceneDelegate {
      let newWidth = delegate.window?.bounds.size.width ?? UIScreen.main.bounds.size.width
      ...
```

The polling loop looks like it follows resizes, which makes it worse than a static value
rather than better. When the window is available it works. When it is not, it silently falls
back to the main screen, which reports the display the device was in when the read happened.
An app opened on the outer display, or opened before the window is attached, can hold a width
from the closed pose and keep it while appearing to track changes. The three parts are also
one design: a stored size, a fallback, and a poll, all replacing something the system already
provides.

There is a second, separate problem in the same file at line 21:

```swift
window = windowScene.keyWindow
```

A scene delegate is meant to create its window from the scene it was handed, not to reach for
one that already exists. `UIApplication.shared.windows.keyWindow`-style access is the pattern
Apple's own guidance removes, and the scene delegate is the one place where the correct
replacement is unambiguous.

**Next action.** Drive `windowWidth` and `windowHeight` from the actual `UIWindowScene` and
its trait collection, create the window with `UIWindow(windowScene:)`, and replace the
polling task with a trait-change registration or the scene's resize callbacks. This is one
change in one file, not six line edits. The scanner could not say that because it reports
locations, not causes.

**Runtime result: not tested.** Whether the wrong size is observable depends on when the
scene is constructed relative to window attachment, which a source read cannot determine.
Confirm on a buildable app: open on the outer display, unfold, and watch whether any layout
that uses these values lags or sticks at the closed width.

**Human decision.** Retained as first priority. A delivered review records the reviewer, the
review date, the validated priority and the journey-impact rationale here; the sample has no
buyer and no agreed journey, so that decision is open.

## Finding 2: a sidebar layout is gated on device idiom while the correct gate is already present

**Category:** source signal, requiring confirmation.
**Source:** `IceCubesApp/App/Main/AppView.swift`, lines 44 and 45. Check `idiom`,
confidence medium.
**Evidence:** layout branching on `UIDevice.current.userInterfaceIdiom`.
**Priority: second.** Real and cheap to fix, but the consequence is a missed layout, not a
broken one.

**Hypothesis.** The view already reads the size class, and combines it with an idiom check:

```swift
if horizontalSizeClass == .regular
  && (UIDevice.current.userInterfaceIdiom == .pad
    || UIDevice.current.userInterfaceIdiom == .mac),
  appAccountsManager.currentClient.isAuth,
  userPreferences.showiPadSecondaryColumn
{
  Divider().edgesIgnoringSafeArea(.all)
  notificationsSecondaryColumn
}
```

`horizontalSizeClass == .regular` already expresses "there is room for a second column". The
idiom clause adds a device-family condition on top of it. A few lines later the same pattern
decides which tab set is offered:

```swift
if UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact {
  return [SidebarSections.iosTabs]
} else if UIDevice.current.userInterfaceIdiom == .vision {
  return [SidebarSections.visionOSTabs]
}
```

On an unfolded phone-shaped foldable, the inner display is large but the idiom is still
`.phone`. The size-class check would pass and the idiom check would not, so the app would
withhold the secondary column and the wide tab set on exactly the display that has room for
them. The app has already built the layout. The idiom check is the only thing stopping it
from appearing.

This is the specific shape worth naming: the app is not badly written, it is written for the
devices that existed when it was written. `TabView` with `.tabViewStyle(.sidebarAdaptable)`,
`TabSection` and `Tab(role:)` are already the modern APIs, so the bars themselves are in good
shape.

**Next action.** Drop the idiom clause from the layout conditions and let the size class
decide. Keep any idiom check that genuinely concerns a device family rather than available
space.

**Runtime result: not tested.** Whether a regular size class is actually reported on the Duo
inner display for this app is unknown, as is whether the third condition
(`showiPadSecondaryColumn`) is a user preference named for the iPad that should be renamed or
reused. Confirm on a buildable app on the inner display.

**Human decision.** Retained as second priority, pending the runtime question above. Reviewer
and date to record on delivery.

## Finding 3: scroll and selection state is not preserved anywhere

**Category:** source signal, requiring confirmation. This is also the candidate for an
optional improvement: dropping it is a legitimate outcome.
**Source:** 55 files, of which `IceCubesApp/App/Router/AppRegistry.swift` and
`Packages/Timeline/Sources/Timeline/View/TimelineListView.swift` are representative. Check
`state`, confidence high.
**Evidence:** `state` scored 5 out of 100, "3 of 58 stateful view file(s) preserve state".
**Priority: third.** The largest number, the weakest per-item claim, and the one I would
spend the least on until the first two are done.

**Hypothesis.** The check rests on a whole-file rule. If a file contains a list or scroll view
and does not contain `@SceneStorage`, `restorationIdentifier`,
`preservesSelectionInNavigationStack`, `scrollPosition(` or `NSUserActivity`, it is flagged.
That rule is why the count is 55, and the count is why this finding needs a caveat rather
than a list.

Some of the 55 are unambiguously real: a timeline that loses its scroll position when the
scene changes shape is a visible loss, and this is the app's main surface.

Some are not. `AppRegistry.swift` is an `extension View` that wires environment objects, and
it contains no list and no scroll view. It is flagged because the rule looks for the text
`List(`, which it finds at line 118 inside `case .accountsList(let accounts):`. That is an
enum case name, not a list view. The rule cannot tell the two apart, so it flagged a 321-line
file over a substring. That is a false positive, and it is mine, not the app's.

It is worth attention anyway. Apple's own modernization tooling does not cover state
preservation at all. Of the four surfaces it handles (main screen, orientation, scene
lifecycle, safe area) none is about surviving a resize. So this is a surface where the app
has a genuine gap and no free tool will tell it.

**Next action.** Not 55 edits. Decide per surface whether the scroll position and selection
should survive a width change, then adopt `scrollPosition`, `@SceneStorage` or the navigation
selection binding where the answer is yes. Start with the timeline and the account lists,
where the loss is most visible, and stop there if the rest is not felt.

**Runtime result: not tested.** Which of the 55 are felt is unknown. Scroll a timeline, unfold
or resize, and see whether the position survives. That is a five-minute test on a buildable
app and it replaces the whole list.

**Human decision.** Retained as third priority with an explicit caveat: the count is not a
work estimate. Reviewer and date to record on delivery.

## Dismissed hypotheses, and why

These were reviewed and set aside. Recording them with a reason is part of the deliverable,
not a disclaimer.

- **Six findings for one cause.** Finding 1 is reported as six, because the scanner reports
  locations. Dismissed as separate items; retained as one cause. The count overstates the
  work.
- **The 55 count for state.** Finding 3 is a whole-file rule over a codebase-wide pattern, not
  55 defects, and at least one of the 55 is demonstrably not one. A list of 55 would look like
  thoroughness and be misleading.
- **A scale read that is not a layout problem.** `Packages/StatusKit/Sources/StatusKit/Editor/
  Components/MediaPickerPanelView.swift:303` uses `UIScreen.main.scale` to size a photo
  thumbnail request. The replacement exists, but the consequence is a slightly wrong thumbnail
  on a display-scale change, not a layout defect. Technically in scope, practically near the
  bottom.
- **Four advice-only surfaces.** The scanner raises 16 advisory questions about reserved
  regions and arrangement views (files such as `TimelineView.swift:63` and
  `MediaUIView.swift:17`). These never affect the score and are questions, not findings:
  custom geometry with no reserved-region query may be correct, and an arrangement view may
  not be the right shape for the pane. Useful as a checklist for a runtime pass, useless as a
  work item. The runtime matrix gives each of them a row that can settle it.

## Coverage and limitations

- What the scanner reads: Swift source and property lists. A target written in Objective-C is
  not analyzed at all.
- What it does not do: resolve build settings or the linked SDK.
- What it has no model of: what a file does. It cannot tell a header banner from a test
  fixture, which is the source of both the false positive above and the inflated counts.
- Exclusions: 154 files excluded from this audit; unreadable files not recorded.
- Screenshots, if any, are read as context and cannot establish behavior or cause.
- No runtime result exists for any row of the matrix above.

## Effort

- Scanner estimate for this app: 70 hours. This is an unvalidated heuristic, not a quote and
  not a delivery commitment.
- Actual review hours for this sample: not recorded. A delivered review records actual review
  hours separately from the scanner estimate.

## What this sample cost

Produced from an existing audit with no new code. The three findings come from reading the
scanner's output and then reading the flagged source, which is the work the review sells: the
scanner locates candidates, the review decides which ones matter, in what order, and what has
to be checked on a running app.

If producing this had required improving the scanner first, that would have been the signal to
stop and not to open a new development effort.

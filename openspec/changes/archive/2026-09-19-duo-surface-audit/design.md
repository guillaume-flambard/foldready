## Context

`AuditEngine` walks a source tree, reads files as text, and runs line-based checks. Two of
them already match Apple's resizability list (`userInterfaceIdiom` and `interfaceOrientation`
at `AuditEngine.swift:309`). A third, `UIRequiresFullScreen` in `Blocker.swift`, is reported
as a potential blocker and can be removed by a port transform.

Apple's iPhone Duo preparation page adds a second list that the engine does not read:

1. Reserved regions. A division (the fold) or an occlusion (the inner camera, and always the
   outer camera). Framework views adjust themselves; custom views must query
   `reservedRegions` and lay out around the result.
2. Arrangement views. `ArrangementView` in SwiftUI and `UIArrangementViewController` in
   UIKit with `.split` and `.overlay` styles, for apps that place two panes themselves.
3. Vertical bars. On Duo the system stacks navigation bars, toolbars and tab bars on the
   side of the display in some poses. Items are drawn as icons when vertical, and an item
   that has a title but no icon is never presented vertically. Direct construction of
   `UIToolbar`, `UINavigationBar` or `UITabBar` is called out as wrong.
4. Camera direction. An app can capture from the outer camera, the inner camera and the
   rear camera, and open, close or rotate can change which display the app is on while the
   camera points the opposite way.

The same page carries one hard build constraint: Xcode 27.1 or later is required to use all
of the available screen space. In earlier versions the app does not extend under the status
bar and camera. The Duo simulator in Device Hub also requires Xcode 27.1, and is not
available yet.

The repository currently reports `resultSchemaVersion = 3` and `foldreadyVersion = "0.4.0"`.

## Goals / Non-Goals

**Goals:**

- Give a reader of the report a complete list of the Duo surfaces Apple names, each with the
  runtime test that would settle it.
- Turn the one Duo requirement that is verifiable without a simulator into a scored check.
- Keep the score stable for the four surfaces, so this change does not invalidate a baseline
  twice in one release cycle.
- Feed the same surface list into the human review deliverable.

**Non-Goals:**

- Claiming that any surface finding is a defect. Source alone cannot show that a custom view
  draws under the fold or that a toolbar item disappears.
- Detecting Objective-C. Out of scope until `audit-fidelity` lands a parser.
- Simulating Duo poses. That belongs to the Device Hub work once Xcode 27.1 ships.
- Inventing a weight for a signal that cannot be verified. See the decisions below.

## Decisions

**The four surfaces are advisory, not scored.** A `GeometryReader` that never queries
`reservedRegions` may be perfectly correct if the view never draws near the hinge. A custom
tab bar may be intentional. Scoring these would produce exactly the false positives that
`audit-fidelity` exists to reduce, and would turn a build red on a guess. Advisory findings
are reported, referenced and listed in the runtime checklist, and they carry zero weight.

**The build floor is scored.** `objectVersion` and `LastUpgradeCheck` are literal values in
`project.pbxproj`, not inferences. The check is deterministic, it has an Apple reference, and
it is the only Duo-specific fact a team can act on before the simulator exists. It is a
proxy, and the report says so: a project can be built by a newer Xcode without its
`LastUpgradeCheck` moving, so a stale value is a prompt to confirm, not proof of failure.
That is the same honesty `Blocker.swift` already applies to `UIRequiresFullScreen`.

**Advisory findings live in their own payload section.** Folding them into `checks` with a
zero weight would make the score computation read as if they mattered. A separate `advisory`
array states the contract plainly: these are questions, and `checks` is the verdict.

**The contract moves to 4 in this change, not in a follow-up.** A new scored check key
changes the payload, the golden fixture and every published baseline. Bundling the advisory
array into the same bump means the index is rewritten once. The alternative, shipping
advisory findings under v3 and bumping for the scored check later, rewrites the same files
twice and teaches consumers to ignore version numbers.

**Ordering against `audit-fidelity` is by value, not by dependency.** `audit-fidelity` adds
a parser and a confidence field; this change adds checks that would benefit from both. It
does not require them, because the surface detectors are conservative line and token
matches whose findings are advisory by construction, and the build floor reads a plist and a
project file rather than Swift. Whichever lands first, the later one rebases its contract
version on the other.

**The runtime matrix is the shared artefact.** `docs/readiness-review.md` already carries a
per-journey matrix with outer display, inner display, transition, partial fold and Split
View rows. The scanner's advisory list must name the same surfaces, so a buyer who reads the
free report and then buys the review sees continuity rather than two vocabularies.

## Risks / Trade-offs

**Advisory findings can be read as defects anyway.** Mitigated by the section heading, by the
reference field, and by the sentence in `docs/result-contract.md` that states what an
advisory finding is not.

**The build floor can be wrong in the team's favour or against it.** A stale
`LastUpgradeCheck` understates readiness; a project opened once in Xcode 27.1 to browse, then
built in CI with 26.6, overstates it. The report prints the raw values it read, so a reader
can judge the claim instead of trusting the check.

**Four new detectors widen the surface for noise.** They are advisory, so they cannot fail a
build, but they can still make a report harder to read. Mitigated by capping each surface to
one finding per file and stating the count rather than listing every call site.

**Contract churn.** This is the second version bump in the same uncommitted body of work.
Consumers that pinned v3 must rewrite baselines. The change says so in the README and in
`docs/result-contract.md`, and the gate continues to print the baseline commit and date so a
stale baseline is visible.

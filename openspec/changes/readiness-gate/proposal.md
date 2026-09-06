## Why

FoldReady was designed as an audit-plus-port tool: score an iOS source tree, then emit
patches that fix it. Xcode 27 removes the second half of that value. Apple's WWDC26
session "Modernize your UIKit app" ships an official app-modernization agent skill
(`uikit-app-modernization`, exportable with `xcrun agent skills export`) that converts
`mainScreen` calls to trait/scene lookups, replaces orientation checks with size-class
checks, migrates apps to the scene lifecycle, and annotates what needs a human. It runs
inside the project, with the build graph and the type checker. Seven regex transforms
cannot beat that, and should not try.

What Apple does not ship is a *verdict*. The official skill fixes what you point it at;
it does not tell you how ready the app is, whether the last merge made it worse, or how
you compare to the app you lose deals against. That is the durable half of FoldReady,
and today it is trapped in a one-shot CLI invocation and a hand-curated web table.

Timing supports the shift rather than a launch scramble. The iPhone Fold is announced
on 2026-09-09 and ships 2026-09-18, but the forcing function for enterprise budget is
the App Store SDK floor: uploads must be built with the iOS 26 SDK since 2026-04-28,
and the iOS 27 SDK floor is expected on the same annual cadence in spring 2027 (Apple
has not published that date yet). UIScene is mandatory once an app builds against the
iOS 27 SDK, and an app without it does not launch at all. So the work teams must do is
dated, recurring, and verifiable, which is a gate, not a one-off script.

## What Changes

- The audit result becomes a versioned, documented contract (`schema_version`, stable
  check keys, per-check score and weight, findings with file and line) instead of an
  ad-hoc JSON blob consumed only by our own scripts.
- A `foldready gate` subcommand exits non-zero on a policy breach: score below a floor,
  score regression against a stored baseline, or any finding above a severity
  threshold. Baselines are committed files, so the gate is reviewable in a PR.
- A published GitHub Action wraps the gate, posts the score delta as a PR comment, and
  uploads the report as a build artifact. This is the distribution channel: a marketplace
  action is installable in one line, unlike a Swift package a stranger has to build.
- `foldready port` stops presenting itself as the fix engine. It keeps the safe,
  mechanical transforms, and for everything else it emits a work order the official
  Apple skill can execute, plus the exact `xcrun`/agent invocation to run it. FoldReady
  measures and verifies; Apple's skill edits.
- Every public claim in the report and the site is sourced or dropped. The current copy
  asserts a system-level "Parallel View" adaptation layer as fact; that is a single
  leaker report from June 2026, never confirmed by Apple. A tool whose pitch is "the
  readiness check should not be a black box" cannot ship unsourced claims.

## Capabilities

### New Capabilities

- `audit/result-contract`: the versioned machine-readable audit result, its stability
  guarantees, and the rules for adding or reweighting a check without breaking consumers.
- `gate/policy`: readiness policy evaluation (floor, regression, severity) with a
  committed baseline and process exit codes for CI.
- `ci/github-action`: the packaged action that runs the gate on a pull request and
  reports the score delta back to the PR.
- `port/work-order`: the handoff artifact that describes remaining non-mechanical work
  in a form Apple's app-modernization skill (or any coding agent) can execute, and that
  `verify` can re-score afterwards.
- `evidence/sourcing`: the rule that every readiness claim in reports and site copy
  carries an Apple-authoritative citation, and how unconfirmed rumor is labelled.

### Modified Capabilities

<!-- None: this change introduces the first specs in the repo. -->

## Impact

- `Sources/foldready/main.swift`: new `gate` subcommand, `--baseline` flag on `audit`.
- `Sources/foldready/JSONReport.swift`: schema version, stable keys, findings shape.
- `Sources/foldready/Port/PortEngine.swift`, `Port/Transforms.swift`: transforms that
  are not provably safe become work-order entries instead of patches.
- New `action.yml` plus a composite or Docker action at the repo root, and a release tag
  scheme (`v1`, `v1.2.3`) for marketplace consumers.
- `web/lib/data.ts` and `Scripts/aggregate-*.py`: read the versioned contract.
- `README.md`, `web/` copy: sourcing pass, removal of the Parallel View assertion.
- Docs debt: the report contract becomes public API, so a breaking change needs a
  schema version bump and a migration note.

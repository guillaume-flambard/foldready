# FoldReady result contract

`result.json` is FoldReady's public interface. CI gates, the ranking site and third-party
consumers read it, so its shape is a contract rather than an implementation detail.

**Current version: `schema_version` 5.**

Produce it with `foldready <path> --json`, or with `foldready gate <path> --json`, which
adds a `gate` object to the same payload.

## Compatibility rules

- Adding an optional field does **not** bump `schema_version`.
- Removing a field, renaming a key, or changing the meaning of an existing field **does**.
- A change to how an existing check scores also bumps it, because it invalidates committed
  baselines. Such a release names the affected checks in its notes.
- A check `key` is stable across title, weight and scoring changes, and is never reused for
  a different check once retired.
- Findings never contain the absolute path of the machine that produced them.
- Two audits of the same tree, with the same FoldReady version and no screenshots, produce
  identical output apart from `generated_at`.

Version 1 was the first versioned contract. Version 2 rebalanced the score against a
measured corpus; a v1 baseline is not comparable with a v2 result, and the gate says so
rather than reporting the rebalance as a regression.

## Top level

| Field | Type | Meaning |
|---|---|---|
| `schema_version` | integer | Contract version. `5` today. |
| `foldready_version` | string | Engine that produced the result. |
| `app` | string | App name, from `--name` or the folder name. |
| `generated_at` | string | ISO 8601 timestamp. The only field that changes between two runs of an unchanged tree. |
| `score` | number | Total, 0-100, rounded. Equal to the weighted sum of the checks. |
| `grade` | string | `A` >= 85, `B` >= 65, `C` >= 45, `D` >= 25, `F` below 25. Absolute meanings, not ranks: A adapts on every axis measured; B adapts on most; C reads the scene somewhere; D barely; F not at all. On the calibration corpus this gives A=0, B=1, C=4, D=10, F=5. |
| `risk` | string | `high` whenever a blocker stops launch, else `low` (>= 70), `medium` (45-69), `high` (< 45). |
| `estimated_porting_hours` | number | Effort estimate, rounded to the half hour. |
| `blockers` | array | Binary facts with a consequence, outside the score. See below. |
| `score_is_provisional` | boolean | True when the app opted out of a resizable scene, so the quality score describes code that never gets the canvas. |
| `stats` | object | `swift_files`, `ui_files`, `excluded_files`, `swiftui_files`, `uikit_files`, `xib_or_storyboard`, `info_plists`, `failed_files`, and one count per exclusion reason: `excluded_tests`, `excluded_vendored`, `excluded_generated`, `excluded_by_config`. |
| `build` | object | Literal toolchain values read from `project.pbxproj`. See below. |
| `checks` | array | One entry per check, see below. |
| `findings` | array | Located problems, see below. |
| `advisory` | array | Duo surface questions. Never scored. See below. |

## `checks[]`

| Field | Type | Meaning |
|---|---|---|
| `key` | string | Stable identity. Use this, never the title. |
| `title` | string | Human label. May change between releases. |
| `weight` | number | Contribution to the total. Weights sum to 1. |
| `score` | number | 0-100 for this check. |
| `reference` | string | Apple source the requirement is derived from. |
| `detail` | string | One-line summary of what was counted. |
| `signals` | object | The raw counts behind the score: numerator, denominator, and whatever else the check weighed. Emitted so a future rebalance can be calibrated from stored results instead of re-auditing a corpus. |

`score` (total) = sum of `check.score * check.weight`, to rounding. Weights are reported so
a consumer can recompute the total and detect a reweighting instead of mistaking it for a
change in the audited app.

Current keys and base weights: `adaptive-layout` 0.35, `navigation` 0.20,
`adaptive-geometry` 0.15, `build-toolchain` 0.10, `state` 0.10, `idiom` 0.10,
`orientation` 0.10, plus `captured-layout` 0.20 when screenshots are supplied. A check that
does not apply to an app — no lists to preserve state in, no navigation container to adapt,
no Xcode project file to read, no orientation declared anywhere — drops out entirely and its
weight is spread over the rest, so the reported weights always sum to 1.

## `build`

Literal values read from `project.pbxproj`. Nothing here is inferred: the engine reads the
strings an Xcode project already records and reports them.

| Field | Type | Meaning |
|---|---|---|
| `object_versions` | array | Every `objectVersion` value found, ascending. |
| `last_upgrade_check` | array | One entry per `LastUpgradeCheck`, with `file` and integer `value`. |
| `xcode_27_1_generation` | integer | `2710`, the generation the `build-toolchain` check compares against. |
| `note` | string | States that `LastUpgradeCheck` records the last Xcode upgrade and can be stale. |

`LastUpgradeCheck` is written when a project is opened in a newer Xcode, so it can be stale
in either direction: a project last opened in Xcode 26.6 understates an app whose CI builds
with 27.1, and a single browse in 27.1 overstates one still built with 26.6. A
`build-toolchain` gap is a prompt to confirm the toolchain that actually builds the app,
not proof that a shipped binary fails.

## `blockers[]`

Binary, verifiable facts with a stated consequence. They are reported before the score and
never contribute a weighted percentage, because averaging "this app does not launch" into a
number turns a consequence into a school mark.

| Field | Type | Meaning |
|---|---|---|
| `id` | string | `scene-lifecycle-missing` or `full-screen-opt-out`. |
| `title` | string | Short label. |
| `consequence` | string | What happens to the app. |
| `reference` | string | Apple source. |
| `stops_launch` | boolean | Conditional consequence if the source signal is confirmed and the relevant SDK requirement applies; not an observed launch failure. |
| `file` | string, optional | Where it was found, when the fact is a declaration. |

## How each check is computed

- **`adaptive-layout`** — `1 / (1 + d/0.03)` where `d` is the share of UI files reading
  fixed screen geometry or declaring a frame larger than a control. A soft decay rather
  than a share (which was near-constant on the corpus) or a threshold (which put a cliff at
  the anchor). 3% of UI files affected halves the check.
- **`adaptive-geometry`** — coverage only. Size-class and effective-geometry reads against a
  target of 2% of UI files. An app that reads no geometry receives full credit: standard
  containers can adapt without explicit geometry code, so the absence of a read is a missing
  signal rather than a defect. Device-idiom and interface-orientation branching are no longer
  folded in here; they are scored by the `idiom` and `orientation` checks.
- **`navigation`**: standard navigation sites divided by standard plus legacy sites. NavigationStack, NavigationSplitView, TabView and UIKit navigation containers receive credit without a sidebar. Legacy NavigationView is a review signal, not an observed defect.
- **`state`** — stateful view files that preserve scroll or selection, over stateful view
  files. Near zero across the corpus today: a frontier signal at a low weight, not a
  broken check.
- **`idiom`** — share of UI files free of `UIDevice.current.userInterfaceIdiom` branching. A
  branch describes a device, not the canvas the scene actually receives, which a resizable
  scene is free to reshape. The finding is `medium` confidence because a deliberate
  phone-only screen is invisible to a source scan.
- **`orientation`** — supported interface orientations, read from `Info.plist` and from
  source. A plist that declares only portrait orientations is a `major`, `high`-confidence
  finding: it locks the app to one shape, so it cannot use the wider canvas. A source branch
  on `interfaceOrientation` is a `minor`, `high`-confidence finding. The check does not apply
  when no plist declares orientations and no source branches on one.

### Calibration

The anchors above (`0.03` and `0.02`) and the grade bands were calibrated on a corpus of
twenty well-known open-source iOS apps audited on **2026-09-06**: IceCubesApp, isowords,
Home Assistant, Bitwarden, Element, OpenFind, MovieSwiftUI, Delta Chat, Signal,
NetNewsWire, Firefox, Dime, Eigen, WordPress, DuckDuckGo, Wikipedia, Kickstarter, Open Food
Facts, Nextcloud, MochiDiffusion. Anchors are choices, so they are recorded here with their
corpus and date rather than left as bare constants in the source.

The measurement itself is committed as `docs/calibration-corpus.json`: per app, the
superseded v2 score, the current v5 score and every check's raw signals. A future rebalance
can be simulated from that file without re-cloning twenty repositories.

The corpus was re-audited under **contract v5 on 2026-09-19**. Every app's score rose (the
range moved from 6 to 65 up to 43 to 79). The rise is mostly a change of contract shape, not
a change in the apps, and it is worth stating plainly because a reader comparing the two
measurements would otherwise draw the wrong conclusion:

- **Adaptive geometry stopped penalising zero reads.** Through v4 the check was half
  coverage and half purity, so an app that read no size class at all scored low. In v5 it is
  coverage-only and keeps the "absence is not scored zero" guard, so the same app now scores
  100. isowords scores 100 on "0 of 99 UI file(s) read size classes"; MovieSwiftUI 100 on
  "0 of 91"; Dime 100 on "0 of 80"; Open Food Facts 100 on "0 of 102". Those were among the
  lowest-scoring apps before.
- **The two new checks default high.** Interface idiom scores 95 to 100 for almost every
  tree, because few apps branch on `userInterfaceIdiom`; orientation scores 100 wherever a
  plist declares both orientations. Weight moved from adaptive-geometry (0.35 to 0.15) into
  those two checks (0.10 each), so the weight that used to discriminate now mostly does not.

The activation precedes, and is not, a claim that these apps became more ready for iPhone
Duo.

## `findings[]`

| Field | Type | Meaning |
|---|---|---|
| `check` | string | The `key` of the check that produced it. |
| `severity` | string | `critical`, `major`, `minor`, `info`. How bad the finding would be if true. |
| `confidence` | string | `high`, `medium`, `low`. How sure the audit is the finding is real, independent of severity. A match whose meaning depends on context the audit cannot see is `medium` or `low`, never `high`. |
| `message` | string | What is wrong and what to do instead. |
| `file` | string, optional | Repository-relative path. Absent for project-wide findings; a screenshot finding carries the image file name. |
| `line` | integer, optional | 1-based. |

Findings are ordered by severity, then check key, file, line and message, so a diff between
two runs shows real changes rather than file system enumeration order. `confidence` is not
part of that order: it is a second axis the gate can filter on, not a sort key.

## `advisory[]`

Duo surface questions raised by the source. Each entry names file, 1-based `line`, the
surface, the Apple source, and the runtime check that would confirm or dismiss it. At most
one entry per file and surface is emitted; `collapsed` states how many occurrences in that
file it stands for.

| Field | Type | Meaning |
|---|---|---|
| `surface` | string | `Reserved regions`, `Arrangement views`, `Vertical bars`, `Camera direction`. |
| `message` | string | The signal, in plain words. |
| `file` | string | Repository-relative path. |
| `line` | integer | 1-based line of the first occurrence. |
| `collapsed` | integer | Occurrences in this file represented by this entry. |
| `reference` | string | Apple source. |
| `runtime_check` | string | The test that would settle the question. |
| `requires_confirmation` | boolean | Always true. |
| `evidence_kind` | string | Always `static_signal`. |

An advisory entry is **not a defect** and **not a score input**: it never contributes to
`score`, to any `check.score`, or to a `gate` verdict, and a run whose advisory list is
empty is not thereby a passing run. The four surfaces exist because a custom layout has to
handle them and the source alone cannot tell whether it already does. Surface names are
shared with the runtime matrix in [readiness-review.md](readiness-review.md).

## `gate` (only from `foldready gate --json`)

| Field | Type | Meaning |
|---|---|---|
| `passed` | boolean | Whether every rule passed. |
| `policy_configured` | boolean | False when no policy file was found: the run is reporting only. |
| `rules[]` | array | `name`, `expected`, `actual`, `passed`, and `skipped_reason` when a rule could not be evaluated. |

The exit code carries the same verdict: `0` pass, `2` policy breach, `1` execution error.

When a baseline is loaded, the rules include `baseline-contract`: it fails when the
baseline's `schema_version` differs from the engine's, naming both versions in `expected` and
`actual`. Regression rules skip a baseline from another contract rather than report the
rebalance as a regression; the `baseline-contract` failure is what tells the team to rewrite
it. The severity ceiling can also be configured with `min_confidence`: findings below that
level are reported but do not fail the build, and the rule's `actual` states how many were
ignored. `min_confidence` is a `high`/`medium`/`low` level; any other value is a load error.

## Changing the contract

A pull request that changes the emitted JSON must update this document in the same commit.
`Scripts/check.sh` compares the audit of `Tests/Fixtures/ContractApp` against
`Tests/Fixtures/contract-golden.json` and fails when they diverge without this file
changing.

## Version history

### 1 (unreleased)

First versioned contract.

- snake_case keys throughout; the absolute `root` path is no longer emitted.
- `reference` added to every check.
- Findings ordered deterministically.
- Scoring change: when screenshots are supplied, `captured-layout` is no longer scaled
  along with the other checks. Weights previously summed to 0.99, which slightly
  understated scores for audits run with `--with-screenshots` or `verify --build`.
  Static audits are unaffected.

### 2 (unreleased)

Rebalanced against the twenty-app corpus, after measuring that the previous scoring did not
discriminate (range 49-92, median 61, no D and no F, and a +0.64 correlation with the
SwiftUI share of files).

- Blocking facts left the score: `scene` and `full-screen` are now `blockers`.
- The `framework` check is removed. It measured an architecture preference, it dominated
  the ranking, and it dropped when an app adopted the mandatory scene lifecycle.
- `navigation` is binary, `adaptive-layout` is a soft density over UI files,
  `adaptive-geometry` splits coverage and purity, `state` is a proportion.
- Icon-sized frames, preview blocks, test and vendored paths, and `XCUIScreen.main` no
  longer produce scored findings.
- `signals`, `blockers`, `score_is_provisional`, `stats.ui_files` and
  `stats.excluded_files` added; `stats.swift_files` now counts every Swift file while the
  checks are measured over `ui_files`.
- Grade bands recalibrated. On the corpus the spread went from 43 points to 59, the
  standard deviation from 10.7 to 15.2, and the correlation with the SwiftUI share from
  +0.64 to -0.11.
- Baselines written by contract v1 are not comparable; the gate skips regression rules and
  says so rather than reporting a rebalance as a regression.

## Version 3 (0.4.0, 11 September 2026)

Navigation and geometry scores changed following Apple's Duo developer sessions. Version 2
baselines are not comparable. The historical calibration above describes v2, not a fresh
v3 corpus run. Grades express heuristic source scores, never device compatibility.

- Standard navigation no longer loses points for lacking a sidebar. Sidebar insertion is
  removed from the default port plan. Legacy navigation work orders allow standard stacks.
- An app with no explicit geometry logic is no longer penalized for delegating to the system.
- `evidence` contains `summary`, `duo_runtime_verified` (always false), `sdk_status`
  (`unresolved`), `runtime_checks_required` and Apple `references`.
- Each finding and blocker adds `requires_confirmation: true` and `evidence_kind`:
  `static_signal`, or `screenshot_signal` for captured-layout findings. These are not
  observed defects. Uniform margins do not establish their cause.
- `verify --build` records capture provenance separately in `capture.json`; one launch
  screenshot does not verify Duo journeys or poses. A missing build remains static-only.
- Existing `blockers`, `stops_launch`, `risk`, and `score_is_provisional` are conservative
  source assessments with conditional consequences. The engine does not resolve the
  linked SDK, build settings, generated declarations or Objective-C lifecycle code.

Sources: [Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)
and [adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/).

## Version 4 (0.4.0, 18 September 2026)

Apple's preparation guidance states that below Xcode 27.1 an app does not extend under the
status bar and camera on iPhone Duo, and names four surfaces a custom layout must handle.
Version 3 baselines are not comparable with v4 results: one check was added, so every
weight shifted and every committed baseline must be rewritten deliberately.

- New scored check `build-toolchain` (base weight 0.10): `Xcode 27.1 build floor`. It reads
  `LastUpgradeCheck` from `project.pbxproj` and passes at the Xcode 27.1 generation
  (`2710`). It does not apply, and costs nothing, when there is no project file or no
  recorded value.
- New top-level `build` block carrying the literal values read.
- New top-level `advisory` array for the four Duo surfaces. It is outside the score by
  construction, so a surface detector can never turn a build red.
- `evidence.runtime_checks_required` now appends one check per surface found in the source.
- The historical calibration above describes v2. Grades express heuristic source scores,
  never device compatibility.

Sources: [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo),
[reserved regions](https://developer.apple.com/documentation/swiftui/geometryproxy/reservedregions(kind:options:layoutdirectionbehavior:)),
[arrangement views](https://developer.apple.com/documentation/swiftui/arrangementview),
and [vertical bars](https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarverticaledge).

## Version 5 (0.5.0, 19 September 2026)

Scoring changed and two checks were added, so **v4 baselines are not comparable with v5
results**. A gate presented with a v4 baseline fails a `baseline-contract` rule naming both
versions rather than comparing an incomparable number. Regenerate the baseline with
`foldready gate <path> --write-baseline`.

- Every finding carries `confidence` (`high`, `medium`, `low`), a second axis independent of
  `severity`. A finding whose meaning depends on context the audit cannot see is never
  `high`; the `idiom` branch finding is `medium` because a phone-only screen is invisible to a
  source scan.
- New scored check `idiom` (base weight 0.10). Device-idiom branching is attributed to this
  key rather than to `adaptive-geometry`.
- New scored check `orientation` (base weight 0.10). It reads
  `UISupportedInterfaceOrientations` in `Info.plist` as well as source `interfaceOrientation`
  branches; a portrait-only plist is a `major` finding. It does not apply when no plist
  declares orientations and no source branches on one.
- `adaptive-geometry` drops to base weight 0.15 and is coverage-only. The device-branching
  half moved to the two checks above. An app with no geometry read still receives full credit,
  because the absence of a read is a missing signal rather than a defect.
- Matches are attributed from a lexed view of each `.swift` file, so a symbol that appears only
  in a comment or in the literal text of a string is no longer scored. A file the lexer cannot
  finish is excluded and counted in `stats.failed_files` rather than scored clean. This is a
  lexer, not a syntax tree: declaration scope is not resolved.
- `stats` gains `failed_files` and one count per exclusion reason: `excluded_tests`,
  `excluded_vendored`, `excluded_generated`, `excluded_by_config`. The reasons do not sum to
  `excluded_files`: a non-UI Swift file that no rule excluded is in neither.
- `exclude` and `include` path patterns in `.foldready.json` are read by the audit itself, so a
  repository's own exclusions are reported by reason and an `include` entry always beats them.
- `min_confidence` in `.foldready.json` is now typed. A value other than `high`, `medium` or
  `low` is a load error rather than a silent fallback that makes the gate permissive.
- The historical calibration above describes v2. Grades express heuristic source scores, never
  device compatibility.

Sources: [Modernize your UIKit app](https://developer.apple.com/videos/play/wwdc2026/278/),
[UIDevice.userInterfaceIdiom](https://developer.apple.com/documentation/uikit/uidevice/userinterfaceidiom),
and [UISupportedInterfaceOrientations](https://developer.apple.com/documentation/bundleresources/information-property-list/uisupportedinterfaceorientations).

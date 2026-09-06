# FoldReady result contract

`result.json` is FoldReady's public interface. CI gates, the ranking site and third-party
consumers read it, so its shape is a contract rather than an implementation detail.

**Current version: `schema_version` 2.**

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
| `schema_version` | integer | Contract version. `2` today. |
| `foldready_version` | string | Engine that produced the result. |
| `app` | string | App name, from `--name` or the folder name. |
| `generated_at` | string | ISO 8601 timestamp. The only field that changes between two runs of an unchanged tree. |
| `score` | number | Total, 0-100, rounded. Equal to the weighted sum of the checks. |
| `grade` | string | `A` >= 85, `B` >= 65, `C` >= 45, `D` >= 25, `F` below 25. Absolute meanings, not ranks: A adapts on every axis measured; B adapts on most; C reads the scene somewhere; D barely; F not at all. On the calibration corpus this gives A=0, B=1, C=4, D=10, F=5. |
| `risk` | string | `high` whenever a blocker stops launch, else `low` (>= 70), `medium` (45-69), `high` (< 45). |
| `estimated_porting_hours` | number | Effort estimate, rounded to the half hour. |
| `blockers` | array | Binary facts with a consequence, outside the score. See below. |
| `score_is_provisional` | boolean | True when the app opted out of a resizable scene, so the quality score describes code that never gets the canvas. |
| `stats` | object | `swift_files`, `ui_files`, `excluded_files`, `swiftui_files`, `uikit_files`, `xib_or_storyboard`, `info_plists`. |
| `checks` | array | One entry per check, see below. |
| `findings` | array | Located problems, see below. |

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

Current keys and base weights: `adaptive-layout` 0.35, `adaptive-geometry` 0.35,
`navigation` 0.20, `state` 0.10, plus `captured-layout` 0.20 when screenshots are
supplied. A check that does not apply to an app — no lists to preserve state in, no
navigation container to adapt — drops out entirely and its weight is spread over the
rest, so the reported weights always sum to 1.

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
| `stops_launch` | boolean | True when the app does not run at all. |
| `file` | string, optional | Where it was found, when the fact is a declaration. |

## How each check is computed

- **`adaptive-layout`** — `1 / (1 + d/0.03)` where `d` is the share of UI files reading
  fixed screen geometry or declaring a frame larger than a control. A soft decay rather
  than a share (which was near-constant on the corpus) or a threshold (which put a cliff at
  the anchor). 3% of UI files affected halves the check.
- **`adaptive-geometry`** — half coverage, half purity. Coverage is size-class and
  effective-geometry reads against a target of 2% of UI files; purity is those reads
  against reads plus device-idiom or orientation branching. An app that branches on nothing
  is scored on coverage alone rather than punished for an absence.
- **`navigation`** — binary: has the app adopted any container that can become a sidebar.
  Across the corpus this is 1 for two apps and 0 for eighteen, so there is nothing to
  grade; it is reported as the capability it is, at a weight that says it matters.
- **`state`** — stateful view files that preserve scroll or selection, over stateful view
  files. Near zero across the corpus today: a frontier signal at a low weight, not a
  broken check.

### Calibration

The anchors above (`0.03` and `0.02`) and the grade bands were calibrated on a corpus of
twenty well-known open-source iOS apps audited on **2026-09-06**: IceCubesApp, isowords,
Home Assistant, Bitwarden, Element, OpenFind, MovieSwiftUI, Delta Chat, Signal,
NetNewsWire, Firefox, Dime, Eigen, WordPress, DuckDuckGo, Wikipedia, Kickstarter, Open Food
Facts, Nextcloud, MochiDiffusion. Anchors are choices, so they are recorded here with their
corpus and date rather than left as bare constants in the source.

The measurement itself is committed as `docs/calibration-corpus.json`: per app, the v1 and
v2 score and every check's raw signals. A future rebalance can be simulated from that file
without re-cloning twenty repositories.

## `findings[]`

| Field | Type | Meaning |
|---|---|---|
| `check` | string | The `key` of the check that produced it. |
| `severity` | string | `critical`, `major`, `minor`, `info`. |
| `message` | string | What is wrong and what to do instead. |
| `file` | string, optional | Repository-relative path. Absent for project-wide findings; a screenshot finding carries the image file name. |
| `line` | integer, optional | 1-based. |

Findings are ordered by severity, then check key, file, line and message, so a diff between
two runs shows real changes rather than file system enumeration order.

## `gate` (only from `foldready gate --json`)

| Field | Type | Meaning |
|---|---|---|
| `passed` | boolean | Whether every rule passed. |
| `policy_configured` | boolean | False when no policy file was found: the run is reporting only. |
| `rules[]` | array | `name`, `expected`, `actual`, `passed`, and `skipped_reason` when a rule could not be evaluated. |

The exit code carries the same verdict: `0` pass, `2` policy breach, `1` execution error.

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

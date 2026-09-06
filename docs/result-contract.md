# FoldReady result contract

`result.json` is FoldReady's public interface. CI gates, the ranking site and third-party
consumers read it, so its shape is a contract rather than an implementation detail.

**Current version: `schema_version` 1.**

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

Version 1 is the first versioned contract. Pre-1 output used camelCase keys and carried an
absolute `root` path; both are gone.

## Top level

| Field | Type | Meaning |
|---|---|---|
| `schema_version` | integer | Contract version. `1` today. |
| `foldready_version` | string | Engine that produced the result. |
| `app` | string | App name, from `--name` or the folder name. |
| `generated_at` | string | ISO 8601 timestamp. The only field that changes between two runs of an unchanged tree. |
| `score` | number | Total, 0-100, rounded. Equal to the weighted sum of the checks. |
| `grade` | string | `A` >= 75, `B` >= 60, `C` >= 45, `D` >= 30, `F` below 30. |
| `risk` | string | `low` (>= 61), `medium` (30-60), `high` (< 30). |
| `estimated_porting_hours` | number | Effort estimate, rounded to the half hour. |
| `stats` | object | `swift_files`, `swiftui_files`, `uikit_files`, `xib_or_storyboard`, `info_plists`. |
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

`score` (total) = sum of `check.score * check.weight`, to rounding. Weights are reported so
a consumer can recompute the total and detect a reweighting instead of mistaking it for a
change in the audited app.

Current keys: `adaptive-layout`, `full-screen`, `navigation`, `scene`, `fold-state`,
`state`, `framework`, and `captured-layout` when screenshots are supplied. With
screenshots, `captured-layout` takes 0.10 and the other seven are scaled to 0.90 so the
weights still sum to 1.

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

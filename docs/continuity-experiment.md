# Continuity experiment

FoldReady can compare generated transition scenarios with an explicit XCTest suite on a local demo.
This is an experimental demo protocol, not an adapter for arbitrary customer projects.
It does not change the scanner's score or historical JSON contract.

## Run

Requirements: macOS, Xcode with an available iOS simulator, the Xcode-provided `/usr/bin/python3`,
and Swift. No third-party Python packages or project generators are required.

```sh
swift build
.build/debug/foldready continuity Examples/continuity-demo/continuity-demo.xcodeproj
```

Default: three journeys, broken and fixed variants, generated and explicit approaches,
three repetitions, portrait-to-landscape rotation. This schedules 108 cases:
36 controls without transition and 72 cases with a transition at a declared checkpoint.
Expected fixture results: 30 functional failures and 78 passes. There are five failing
checkpoints, each reproduced three times by each approach.

For a shorter run:

```sh
.build/debug/foldready continuity Examples/continuity-demo/continuity-demo.xcodeproj \
  --journeys form --approaches generated --repetitions 1
```

Options:

| Option | Meaning |
|---|---|
| `--journeys form,cart,draft` | Unique comma-separated demo journeys |
| `--variants broken,fixed` | Fixture variants |
| `--approaches generated,explicit` | Suites to compare |
| `--repetitions 3` | Between 1 and 10 |
| `--transition rotate` | Currently the only executed transition |
| `--transition duo-fold` | Capability unavailable; returns non-executed cases without building |
| `--device UDID` | Explicit available iOS simulator; otherwise first available iPad |
| `--out DIRECTORY` | Parent of a new unique run directory |
| `--timings FILE` | Paired human timing observations using the benchmark protocol |

The simulator runs the demo app only. XCTest changes its orientation. The app uses synthetic
values and local counters, with no network, purchase, order backend, account or production data.
It is installed with a dedicated `dev.memolabs.ContinuityDemo` bundle identifier.

## What is tested

| Journey | Actions | Preserved values | Deliberate defect on rotation |
|---|---|---|---|
| Form | Enter Ada; enter delivery details | Name and delivery details | Name is cleared |
| Cart | Add one item; place an order | Quantity and order count | Submitted order count increases again |
| Draft | Write; save | Body and save count | Body is cleared |

The buttons populate fixed synthetic values. This isolates lifecycle continuity from keyboard,
validation, networking and payment behavior. The cart checks a visible submission counter;
it does not establish that a production backend prevents duplicate orders.

Each case starts from clean fixture state in portrait. Cases sharing a journey and variant
reuse the app process through an explicit fixture reset; changing either launches the app again.
Preconditions must match the declared
expected values before the transition. A failed precondition is an execution error. A verified
rotation followed by changed values is a functional failure. The fixed variant keeps the
same controller state during the layout transition.

After checking the transition, the test completes any remaining actions and checks the final
values too. A case must preserve both checkpoint and completion invariants to pass.

`journeys.json` declares the generated checkpoints and invariant values. The explicit suite
spells out actions and expectations independently. Both share device interaction and evidence
recording, so this comparison tests scenario generation, not independence from XCTest defects.
The current reproduction is one checkpoint and one transition; arbitrary sequence reduction
and automatic discovery of business invariants are not implemented.

## Evidence contract, version 1

Every run creates `result.json`, `summary.md`, build/test logs and, after test execution,
an `xcresult` bundle plus exported attachments. New run directories prevent stale evidence reuse.

| Status | Meaning |
|---|---|
| `passed` | Preconditions, requested transition and invariant observations are present and agree |
| `functional_failure` | Preconditions passed; observed invariant values differ after the transition |
| `execution_error` | Setup, evidence or XCTest harness could not support a business verdict |
| `not_executed` | Requested capability unavailable or no record was produced |

Cases contain identity, variant, approach, checkpoint, repetition, requested/actual transitions,
before/expected/observed values, reproduction steps, elapsed execution time and available attachments.
The environment records Xcode, SDK, simulator UDID/runtime, built bundle metadata and a source digest.
No screenshot heuristic determines a business verdict. Duplicate, missing and contradictory
records cannot become successes.

Exit codes: `0` all selected cases passed; `1` execution/evidence error; `2` functional failure;
`3` incomplete or unsupported run. An expected injected defect still returns `2`.
`comparison.matches_fixture_ground_truth` tells whether these outcomes match the fixture design.
XCTest treats expected injected defects as measured data; XCTest assertion failures indicate a
broken harness. This keeps fixture detection separate from execution health.

`duo_runtime_verified` is always false in this prototype. Rotation on an iPad is evidence about
that environment only. A simulated geometry change is not a physical hinge test.

## Verification and limits

```sh
python3 -m unittest discover -s Tests/continuity -v
./Scripts/check.sh
```

The fast checks cover evidence integrity, exit statuses, missing capabilities, paired comparisons,
timing validation and preservation of unfavorable results. Simulator execution is separate because
it is slower and requires a local runtime.

Human preparation and diagnosis timing are initially `not_measured`. Execution duration,
line counts and amount of generated code cannot prove a 50 percent preparation gain.
See [benchmark protocol](continuity-benchmark.md). No commercial validation is implied by
passing synthetic fixtures.

## Sources

- [Apple: XCUIDevice orientation](https://developer.apple.com/documentation/xcuiautomation/xcuidevice/orientation).
- [Apple: XCTest attachments](https://developer.apple.com/documentation/xctest/adding-attachments-to-tests-activities-and-issues).
- Installed Xcode help: `xcrun xcresulttool export attachments --help` and `--schema`.
- Installed Xcode help: `xcodebuild -help`; emitted `.xctestrun` files define the target environment format.
- [Apple: prepare for iPhone Duo](https://developer.apple.com/iphone-duo/). The future adapter must
  verify actual SDK/runtime availability and automation before adding support.

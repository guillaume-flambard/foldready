## Purpose

Turn a one-off readiness score into a policy a team can enforce on every merge: a floor,
a no-regression rule, and a severity ceiling, evaluated against a baseline that lives in
the repository and is reviewed like any other file.

## ADDED Requirements

### Requirement: Gate command with policy exit codes

FoldReady MUST provide a `gate` subcommand that audits a tree, evaluates the configured
policy, and communicates the verdict through the process exit code: `0` for pass, a
distinct non-zero code for a policy breach, and a different non-zero code for an
execution error such as an unreadable tree or a malformed baseline.

#### Scenario: Policy satisfied

- **WHEN** the audited tree meets every configured rule
- **THEN** the command exits `0` and prints the score and the margin to each rule

#### Scenario: Policy breached

- **WHEN** at least one rule is violated
- **THEN** the command exits with the breach code and prints, for each violated rule,
  the expected value, the actual value, and the findings responsible

#### Scenario: Broken invocation

- **WHEN** the baseline file is malformed or the tree cannot be read
- **THEN** the command exits with the error code, which differs from the breach code, so
  that CI can distinguish a failing app from a broken pipeline

### Requirement: Committed baseline

The baseline MUST be a file in the audited repository containing the previous accepted
result. `gate` MUST compare against that file and MUST NOT reach the network or a hosted
service to resolve a baseline.

#### Scenario: Reviewing an accepted regression

- **WHEN** a team deliberately accepts a lower score
- **THEN** updating the baseline file is a reviewable diff in the pull request that
  causes it

#### Scenario: First run with no baseline

- **WHEN** no baseline file exists
- **THEN** the regression rule is skipped, the floor and severity rules still apply, and
  the command prints the command that writes the initial baseline

### Requirement: Regression detection per check

The regression rule MUST be evaluable on the total score and on individual check keys,
so a team can freeze a check it has already fixed without blocking on the total.

#### Scenario: Total holds but a fixed check regresses

- **WHEN** the total score is unchanged but a check the team had brought to full marks
  drops
- **THEN** the gate reports that check as a breach if per-check regression is enabled for it

### Requirement: Configuration in the audited repository

Policy MUST be configurable by a file in the audited repository, with command-line flags
overriding it. An absent configuration MUST mean "no policy": the gate reports the score
and exits `0`.

#### Scenario: Adoption without configuration

- **WHEN** a team runs the gate before writing any configuration
- **THEN** the run succeeds, prints the score, and does not fail the build

### Requirement: Human-readable and machine-readable output

`gate` MUST emit the full audit result as JSON on request, in addition to its
human-readable summary, so a CI job can both fail the build and publish the numbers.

#### Scenario: CI needs both

- **WHEN** the gate runs with the JSON output flag
- **THEN** the JSON conforms to the audit result contract and the exit code still
  reflects the policy verdict

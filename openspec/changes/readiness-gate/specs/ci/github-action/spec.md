## Purpose

Make FoldReady installable in one line of workflow YAML, and make its verdict visible
where the decision is made: in the pull request. Distribution, not capability, is the
current bottleneck.

## ADDED Requirements

### Requirement: Published action interface

The repository MUST expose an `action.yml` at its root with documented inputs covering
at minimum the path to audit, the app name, the policy configuration or baseline path,
and whether a breach fails the job. It MUST expose outputs for the score, the grade, and
the path to the generated report.

#### Scenario: Single-step adoption

- **WHEN** a maintainer adds the action to a workflow with only the path input
- **THEN** the job audits the tree, publishes the report, and does not fail the build
  unless a policy is configured

#### Scenario: Downstream steps consume the score

- **WHEN** a later workflow step reads the action's outputs
- **THEN** the score and grade are available as strings without parsing the log

### Requirement: Pull request score delta

When run on a pull request, the action MUST report the score on the head commit, the
score on the base, and the delta.

#### Scenario: Regression introduced by a pull request

- **WHEN** the head score is below the base score
- **THEN** the action surfaces the delta and the checks responsible for it

#### Scenario: Fork pull request without write access

- **WHEN** the workflow token cannot write to the pull request
- **THEN** the action still publishes the report as a job artifact and writes the summary
  to the job step summary instead of failing

### Requirement: No unpinned network dependency at run time

The action MUST run from a pinned, released FoldReady version and MUST NOT fetch an
unpinned toolchain or script at run time.

#### Scenario: Reproducible run months later

- **WHEN** a workflow pinned to a released action tag runs long after that release
- **THEN** it produces the same score as it did on release day for the same source tree

### Requirement: Release tags for consumers

Releases MUST publish both an immutable version tag and a moving major tag, so consumers
can choose between pinning exactly and following patches.

#### Scenario: Consumer follows the major tag

- **WHEN** a patch release is published
- **THEN** workflows referencing the major tag pick it up without editing their YAML, and
  workflows referencing the exact version do not change

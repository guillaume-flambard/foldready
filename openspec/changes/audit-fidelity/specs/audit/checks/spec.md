## Purpose

Define what the readiness audit measures and what it deliberately ignores, so that a score
is defensible enough for a team to fail a build on it.

## ADDED Requirements

### Requirement: Syntax-aware attribution

Occurrences MUST be attributed using a Swift syntax tree rather than line matching. A
match inside a comment, a string literal, or a disabled compilation branch MUST NOT be
scored.

#### Scenario: Symbol named in a comment

- **WHEN** a file mentions a flagged symbol only in a comment or documentation block
- **THEN** the audit produces no scored finding for that file

#### Scenario: File that fails to parse

- **WHEN** a Swift file cannot be parsed
- **THEN** the audit reports it as unparsed, excludes it from scoring, and states how many
  files were excluded, rather than silently scoring it as clean

### Requirement: Non-shipping code is excluded from scoring

Preview blocks, test targets, vendored dependency directories, and generated files MUST be
excluded from the score by default. Exclusions MUST be reported in the result, and MUST be
configurable in the audited repository.

#### Scenario: Hardcoded frame in a preview

- **WHEN** a fixed frame appears only inside a preview block
- **THEN** it does not lower the score, and appears at most as an informational finding

#### Scenario: Vendored dependency

- **WHEN** a repository vendors a third-party framework that is not resizable
- **THEN** its files are excluded from scoring and the exclusion is visible in the result

### Requirement: Idiom and orientation are first-class checks

Interface-idiom checks and interface-orientation checks MUST each be a scored check with
its own stable key, weight, and Apple reference. The orientation check MUST also read the
supported-orientation keys in Info.plist, not only Swift source.

#### Scenario: App locked to portrait in its plist

- **WHEN** an app declares only portrait orientations in Info.plist
- **THEN** the orientation check reports it as a finding with the plist path, and the check
  score reflects it

#### Scenario: Layout branching on idiom

- **WHEN** layout decisions branch on the user-interface idiom
- **THEN** the idiom check reports each site and recommends size classes, with the finding
  attributed to the idiom check key rather than to adaptive layout

### Requirement: Findings carry confidence

Every finding MUST carry a confidence level. A finding whose interpretation depends on
context the audit cannot see MUST NOT be reported as high confidence.

#### Scenario: Gate configured for high confidence only

- **WHEN** a team configures the gate to act only on high-confidence findings
- **THEN** lower-confidence findings appear in the report and do not fail the build

### Requirement: Score changes are declared

A release that changes how any existing check scores MUST state the change in the release
notes and bump the result contract version, so committed baselines are not silently
invalidated.

#### Scenario: Team upgrades FoldReady

- **WHEN** a team upgrades to a release whose scoring changed
- **THEN** the release notes name the affected checks, and the gate reports that the
  baseline was produced by a different contract version

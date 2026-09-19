# audit/duo-surfaces Specification

## Purpose
Read the four iPhone Duo interaction surfaces Apple names in its preparation guidance, and
report each one as a question with the runtime test that would settle it, without pretending
a source match proves a defect.

## Requirements

### Requirement: Recognition of the four Duo surfaces

The audit MUST recognize four iPhone Duo interaction surfaces: reserved regions, arrangement
views, vertical bars, and camera direction. Each recognized occurrence MUST produce an
advisory finding that carries the file, a 1-based line, the surface name, an Apple reference,
and the runtime check that would confirm or dismiss it.

#### Scenario: Custom layout without a reserved-region query

- **WHEN** a file uses container-relative geometry, such as a `GeometryReader` or a custom
  `UIView` layout pass, and never calls `reservedRegions`
- **THEN** the audit emits an advisory finding naming the reserved-regions surface and the
  pose test that would settle it

#### Scenario: Two panes placed by the app

- **WHEN** a file builds a multi-pane layout itself, such as a fixed two-column stack or a
  hand-rolled split container, instead of an arrangement view or a split view
- **THEN** the audit emits an advisory finding naming the arrangement-views surface

#### Scenario: A bar constructed directly

- **WHEN** a file instantiates `UIToolbar`, `UINavigationBar` or `UITabBar` directly
- **THEN** the audit emits an advisory finding naming the vertical-bars surface, because
  Apple directs an app to set items on the view controller's existing bar

#### Scenario: A bar item with a title and no icon

- **WHEN** a toolbar or navigation item is declared with a title and no image or system item
- **THEN** the audit emits an advisory finding stating that Apple never presents such an item
  vertically

#### Scenario: Camera capture without a facing decision

- **WHEN** a file configures a capture session or a device input and does not consult the
  camera position or the active display
- **THEN** the audit emits an advisory finding naming the camera-direction surface

### Requirement: Advisory findings carry no score

Advisory findings MUST NOT contribute to the readiness score, to any check score, or to the
gate verdict. The payload MUST expose them in an `advisory` array distinct from `checks`.

#### Scenario: The score is unchanged

- **WHEN** the same tree is audited with and without the surface detectors enabled
- **THEN** every score, the grade, and the gate exit code are identical

#### Scenario: The gate ignores advisory findings

- **WHEN** the policy forbids blockers and the audit reports only advisory findings
- **THEN** the gate exits `0`

### Requirement: Bounded surface reporting

The audit MUST report at most one advisory finding per file and surface, and MUST state the
number of occurrences it collapsed.

#### Scenario: A surface appears many times

- **WHEN** a file matches a surface on twenty lines
- **THEN** the audit reports one finding for that file and surface and states that twenty
  occurrences were collapsed into it

### Requirement: Advisory findings reach the runtime checklist

Every surface that produced an advisory finding MUST also appear in the report's list of
runtime checks still needed, using the same surface name.

#### Scenario: Report and checklist agree

- **WHEN** a report contains an advisory finding for vertical bars
- **THEN** the list of runtime checks still needed contains a vertical-bars entry

### Requirement: Reference for every surface

Every surface detector MUST carry an Apple reference to the preparation guidance or the
corresponding technology talk, and a check script rule MUST fail the build when a surface is
added without one.

#### Scenario: A surface without a source

- **WHEN** a detector is added and its reference field is empty
- **THEN** `Scripts/check.sh` fails

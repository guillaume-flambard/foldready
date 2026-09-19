# audit/build-floor Specification

## Purpose
Turn Apple's Xcode 27.1 build requirement for iPhone Duo into a source-readable, scored
check, so a team can act on the one Duo fact that needs no simulator.

## Requirements

### Requirement: Read the project toolchain generation

The audit MUST read `objectVersion` and `LastUpgradeCheck` from every `project.pbxproj` in
the tree and MUST report the values it read, without inferring a build configuration the
source does not state.

#### Scenario: Values present

- **WHEN** a project file records `LastUpgradeCheck = 2600`
- **THEN** the report states `2600` and the file it came from

#### Scenario: Values absent

- **WHEN** no project file is present, or it records no upgrade value
- **THEN** the check reports that it could not read a toolchain generation and does not
  penalize the score for the absence

### Requirement: Score the Xcode 27.1 build floor

The audit MUST provide a scored check keyed `build-toolchain`. When the observed upgrade
value is below the Xcode 27.1 generation, the check MUST report a gap, and its reference
MUST be Apple's preparation guidance. The check MUST carry a documented weight in the check
registry and that weight MUST appear in the report payload.

#### Scenario: Below the floor

- **WHEN** the highest observed upgrade value is below the Xcode 27.1 generation
- **THEN** the check reports a gap, the score is reduced by the documented weight, and the
  finding cites Apple's statement that an earlier Xcode does not extend the app under the
  status bar and camera

#### Scenario: At or above the floor

- **WHEN** an observed upgrade value is at or above the Xcode 27.1 generation
- **THEN** the check scores full marks

### Requirement: State the ambiguity of the signal

The report MUST state that `LastUpgradeCheck` records the last time Xcode upgraded the
project and can be stale, so that a stale value is a prompt to confirm the build toolchain
rather than proof that a shipped binary fails.

#### Scenario: A reader sees the caveat

- **WHEN** the check reports a gap
- **THEN** the finding or its reference text states that the value can be stale and that the
  build toolchain should be confirmed

### Requirement: Name the requirement in plain words

The finding text MUST name the concrete consequence Apple documents: below Xcode 27.1 the
app does not use all of the inner display and does not extend under the status bar and
camera.

#### Scenario: The consequence is legible without the reference

- **WHEN** a reader sees only the finding text
- **THEN** the text states the display consequence, not just a version number

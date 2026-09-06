## Purpose

Stop competing with Apple's app-modernization agent skill and start feeding it. FoldReady
keeps the transforms it can prove safe, and hands everything else to the official skill
as a precise, verifiable work order, then re-scores the result.

## ADDED Requirements

### Requirement: Confidence split between patch and work order

Each transform MUST be classified as either mechanically safe or requiring judgement. A
safe transform MAY emit a patch. A transform requiring judgement MUST NOT emit a patch;
it MUST emit a work-order entry instead.

#### Scenario: Mechanical fix

- **WHEN** the audit finds a plist key that must simply be removed
- **THEN** FoldReady emits a patch for it

#### Scenario: Structural migration

- **WHEN** the audit finds an app lifecycle that must migrate to the scene lifecycle
- **THEN** FoldReady emits a work-order entry rather than a regex-generated patch

### Requirement: Work order is agent-executable

A work-order entry MUST name the file and line, the check `key` that produced it, the
required end state, the Apple-authoritative reference for that requirement, and an
acceptance condition FoldReady can re-evaluate. The full work order MUST be emitted as
one file that can be handed to a coding agent as its task input.

#### Scenario: Handing off to the official skill

- **WHEN** a developer passes the work order to Apple's app-modernization skill
- **THEN** each entry is actionable without reading FoldReady's source, and states what
  "done" means

#### Scenario: Handing off to any other agent

- **WHEN** the work order is given to a coding agent that has never seen FoldReady
- **THEN** the entries remain executable, because they cite the platform requirement
  rather than a FoldReady-internal transform name

### Requirement: Verification closes the loop

`verify` MUST re-audit after work-order execution and report, per entry, whether its
acceptance condition is now met, distinguishing "fixed", "unchanged", and "regressed".

#### Scenario: Partial execution

- **WHEN** an agent completes some entries and skips others
- **THEN** `verify` reports the per-entry status and the resulting score delta, rather
  than only a new total

### Requirement: Honest positioning of the port engine

Documentation and report copy MUST describe FoldReady as the measurement and verification
layer, and MUST point to Apple's app-modernization skill as the tool that performs
non-mechanical edits.

#### Scenario: A reader asks who fixes the code

- **WHEN** a reader consults the README or a generated report
- **THEN** the division of labour is stated explicitly, with a link to the Apple session
  that ships the skill

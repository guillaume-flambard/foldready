## Purpose

FoldReady sells a verdict about someone else's codebase. Its own claims about the
platform must therefore be traceable to Apple, and anything that is not confirmed must be
labelled as unconfirmed rather than asserted.

## ADDED Requirements

### Requirement: Every check cites an authoritative reference

Each check MUST carry a reference to Apple documentation, a WWDC session, or a technical
note that establishes the requirement it measures. The reference MUST appear in the
generated report next to the check.

#### Scenario: Reader challenges a low score

- **WHEN** a developer disputes a check
- **THEN** the report shows the Apple reference the check is derived from, so the dispute
  is about the code rather than about FoldReady's authority

#### Scenario: A check has no authoritative source

- **WHEN** a proposed check cannot cite an Apple source
- **THEN** it MUST NOT contribute to the score, and MAY appear only as an informational
  finding

### Requirement: Unconfirmed platform behaviour is labelled

Any statement about behaviour Apple has not confirmed MUST be labelled as unconfirmed
where it appears, with its source and date. It MUST NOT be used as a premise for a score
or for a pricing claim.

#### Scenario: System-level adaptation layer

- **WHEN** copy refers to a system-level side-by-side adaptation layer for unmodified apps
- **THEN** it is presented as an unconfirmed press report with its date, or removed,
  because Apple has not documented such a layer

### Requirement: Internal symbols are never treated as API

Strings discovered in shipping frameworks that Apple has not published as API MUST be
treated as informational only, never as a port target and never as a scored requirement.

#### Scenario: Undocumented fold-state symbols

- **WHEN** the audit encounters undocumented fold-state or hinge-angle symbols
- **THEN** it reports them as informational and does not recommend adopting them

### Requirement: Sourcing is checked, not remembered

The repository's check script MUST fail when a scored check lacks a reference, so the
rule survives contributors who never read this spec.

#### Scenario: Contributor adds a scored check without a source

- **WHEN** a pull request adds a weighted check with no reference field
- **THEN** the check script fails with a message naming the check

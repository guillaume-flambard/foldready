## Purpose

Define the machine-readable audit result as a public contract, so that CI gates,
the ranking site, and third-party consumers can depend on FoldReady scores without
reading Swift source or guessing at key names.

## ADDED Requirements

### Requirement: Versioned result schema

The JSON result MUST carry a `schema_version` integer field. A change that removes a
field, renames a key, or changes the meaning of an existing field MUST increment it.
Adding an optional field MUST NOT increment it.

#### Scenario: Consumer reads a known version

- **WHEN** a consumer reads a result whose `schema_version` matches the version it was
  written against
- **THEN** every field it depends on is present with the documented meaning

#### Scenario: Consumer reads a newer version

- **WHEN** a consumer reads a result whose `schema_version` is higher than it supports
- **THEN** the result still parses as JSON, and the consumer can detect the mismatch
  from `schema_version` alone without inspecting other fields

### Requirement: Stable check identity

Every check MUST expose a stable `key` that does not change when its title, weight, or
scoring logic is revised. Weights MUST be reported per check alongside the score, so a
consumer can recompute the total and detect a reweighting.

#### Scenario: A check is reweighted

- **WHEN** a check's weight changes between two FoldReady releases
- **THEN** the check `key` is unchanged, both results report their own weights, and a
  consumer comparing them can attribute the total delta to the reweighting rather than
  to a code change in the audited app

#### Scenario: A check is retired

- **WHEN** a check is removed from the engine
- **THEN** its `key` is never reused for a different check, and the removal increments
  `schema_version`

### Requirement: Locatable findings

Every finding MUST carry a repository-relative file path, a 1-based line number, a
severity, the `key` of the check that produced it, and a message. Paths MUST NOT contain
the absolute path of the machine that ran the audit.

#### Scenario: Finding rendered in a pull request

- **WHEN** a CI consumer renders a finding
- **THEN** it can construct a link to the exact file and line in the repository without
  post-processing the path

#### Scenario: Audit run on two machines

- **WHEN** the same commit is audited on two machines with different checkout paths
- **THEN** the findings are byte-identical apart from timestamps

### Requirement: Deterministic results

Two audits of the same source tree with the same FoldReady version and no screenshots
MUST produce identical scores and an identical, stably ordered findings list.

#### Scenario: Repeated audit of an unchanged tree

- **WHEN** the same tree is audited twice
- **THEN** the two results differ only in the generation timestamp

### Requirement: Documented contract

The repository MUST contain a document describing every field of the result, the current
`schema_version`, and the compatibility rules above. A pull request that changes the
emitted JSON MUST update that document in the same commit.

#### Scenario: Contract drift

- **WHEN** a pull request changes the shape of the emitted JSON without updating the
  contract document
- **THEN** the repository's own check script fails

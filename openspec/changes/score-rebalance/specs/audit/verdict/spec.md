## Purpose

Keep the facts that decide whether an app works at all out of the average that describes
how well it looks, so a consequential, binary finding cannot be diluted into a number.

## ADDED Requirements

### Requirement: Blocking facts are reported as blockers, not as a score

A blocker is a binary, verifiable condition with a stated consequence. The result MUST
report blockers as their own list, each with an identifier, the consequence, the Apple
source, and the location where it was found. A blocker MUST NOT contribute a weighted
percentage to the quality score.

#### Scenario: App without the scene lifecycle

- **WHEN** no scene lifecycle is detected
- **THEN** the result reports a blocker stating that an app built against the iOS 27 SDK
  without the scene lifecycle does not launch, and the quality score does not include a
  "scene" percentage

#### Scenario: App that opts out of resizable presentation

- **WHEN** `UIRequiresFullScreen` is true
- **THEN** the result reports a blocker naming the plist file, because the app has
  declined the canvas the quality score is about

#### Scenario: No blocker

- **WHEN** neither condition holds
- **THEN** the blockers list is empty and the reader is shown the quality score alone

### Requirement: The verdict is stated before the score

The human report and the command-line summary MUST show the blockers before the quality
score, and MUST NOT present a quality grade as the headline when a blocker is present.

#### Scenario: Reading a blocked report

- **WHEN** an app has a blocker and a high quality score
- **THEN** the report leads with the blocker, and the grade is presented as conditional on
  it being resolved

### Requirement: Quality score is qualified when the app opted out

When the app opts out of resizable presentation, the quality score MUST be reported as
provisional, because the layout it measures never gets the canvas.

#### Scenario: Full-screen opt-out with a good layout score

- **WHEN** `UIRequiresFullScreen` is true and the quality checks score well
- **THEN** the result marks the score provisional and states that it only applies once the
  opt-out is removed

### Requirement: The gate can require the absence of blockers

Gate policy MUST support failing on any blocker, independently of the score floor, so a
team can enforce "must launch" without also enforcing a quality bar.

#### Scenario: Policy that only forbids blockers

- **WHEN** a policy forbids blockers and sets no score floor
- **THEN** an app with a blocker fails the gate, and an app with a low quality score and no
  blocker passes

### Requirement: Blockers lead the work order

Work-order entries derived from blockers MUST be ordered before quality entries.

#### Scenario: Handing over a blocked app

- **WHEN** an app has both a blocker and quality findings
- **THEN** the first entry of the work order is the blocker

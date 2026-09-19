## Purpose

Define what the quality score measures and how each check is normalised, so that the
number separates apps that genuinely differ instead of ranking them by architecture
preference or by codebase size.

## ADDED Requirements

### Requirement: A check must carry information to keep its weight

Every scored check MUST vary across a corpus of real apps. A check that returns the same
value for the large majority of a reference corpus MUST be reweighted, made continuous, or
removed; it MUST NOT keep a large weight.

#### Scenario: A check is flat across the corpus

- **WHEN** a check returns one value for at least three quarters of the reference corpus
- **THEN** it is not scored at its current weight: it is either made continuous, reduced to
  a blocker, or removed

#### Scenario: Adding a check

- **WHEN** a new scored check is proposed
- **THEN** its spread across the reference corpus is measured before its weight is set

### Requirement: The score measures readiness, not architecture preference

A scored check MUST NOT score an app on its choice of UI framework. Readiness is what the
app does with a resizable scene, and both UIKit and SwiftUI can do it.

#### Scenario: A mature UIKit app that adapts

- **WHEN** a UIKit app opts into sidebar placement and derives layout from size classes
- **THEN** it can reach the top grade, with no penalty for not being SwiftUI

#### Scenario: Adopting the scene lifecycle

- **WHEN** an app adopts the scene lifecycle, adding a UIKit scene delegate file
- **THEN** no check scores lower than before as a result

### Requirement: Layout normalisation is independent of codebase size

The adaptive-layout check MUST be normalised against the files that contain UI layout
code, and MUST count offending files rather than raw occurrences, so a large codebase
cannot dilute real problems and a small one is not punished for the same density.

#### Scenario: Large app with real problems

- **WHEN** an app of several thousand files has dozens of files reading fixed screen
  geometry
- **THEN** the check does not score near the maximum

#### Scenario: Two apps with the same density

- **WHEN** two apps of very different sizes have the same proportion of offending UI files
- **THEN** they score the same on this check

### Requirement: Findings that are not readiness problems are excluded from scoring

The following MUST NOT contribute to the score: frames whose declared width and height are
both small enough to be an icon or control, code inside preview blocks, files under test,
snapshot or vendored dependency paths, and matches of `UIScreen.main` that are part of a
longer identifier such as `XCUIScreen.main`.

#### Scenario: Icon-sized frame

- **WHEN** a view declares a frame of 16 by 16 points
- **THEN** it produces no scored finding, because a control with an intrinsic size is not a
  reflow problem

#### Scenario: XCUIScreen in a snapshot helper

- **WHEN** a UI test helper calls `XCUIScreen.main.screenshot()`
- **THEN** no finding is produced: the pattern requires a word boundary on both sides, and
  the path is a test path

#### Scenario: Preview block

- **WHEN** a fixed frame appears inside a preview block
- **THEN** it produces no scored finding

### Requirement: Navigation is measured proportionally

The navigation check MUST score the proportion of the app's root navigation containers
that can become a sidebar, rather than returning one value for "has any" and another for
"has none".

#### Scenario: Partial adoption

- **WHEN** an app has adopted a sidebar-capable container for some of its root navigation
  and not the rest
- **THEN** the check scores between the extremes, in proportion to the adoption

#### Scenario: UIKit sidebar opt-in

- **WHEN** an app opts into tab bar sidebar placement in UIKit
- **THEN** it counts as adopted, exactly as a SwiftUI split view does

### Requirement: State preservation is measured proportionally

The state check MUST score the proportion of views that hold scroll or selection state and
preserve it, rather than returning a fallback value for the presence of view models.

#### Scenario: Some lists preserve state

- **WHEN** half of an app's list and scroll views preserve their state
- **THEN** the check scores in proportion, not at a fixed fallback

#### Scenario: No stateful views

- **WHEN** an app has no list or scroll views
- **THEN** the check is not applicable and its weight is redistributed across the other
  checks rather than scored as a failure

### Requirement: Grades are calibrated against the corpus and stated absolutely

Grade bands MUST be set so that the reference corpus spreads across them, and each band
MUST have a stated meaning in terms of what the app does, not in terms of its rank.

#### Scenario: Publishing a grade

- **WHEN** a report shows a grade
- **THEN** the grade's meaning is stated in terms of behaviour, and two apps with the same
  grade behave comparably regardless of when they were audited

### Requirement: Scoring changes are versioned and comparisons refuse to cross versions

A change to how any check scores MUST bump the result contract version. The gate MUST NOT
compare a result against a baseline produced by a different scoring version; it MUST report
the mismatch instead.

#### Scenario: Baseline from the previous scoring version

- **WHEN** a repository holds a baseline written by an earlier contract version
- **THEN** regression rules are skipped with a stated reason, and the gate prints the
  command that writes a fresh baseline

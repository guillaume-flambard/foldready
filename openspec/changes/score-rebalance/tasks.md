## 1. Exclusions the new normalisation depends on

- [x] 1.1 Give the `UIScreen.main` pattern a left word boundary so `XCUIScreen.main` no
      longer matches, with a test.
- [x] 1.2 Exclude test, snapshot, UI-test and vendored dependency paths from scoring, and
      report how many files were excluded.
- [x] 1.3 Exclude preview blocks from scored findings.
- [x] 1.4 Stop scoring frames whose declared width and height are both icon-sized; keep
      them as informational findings only.

## 2. Blockers

- [x] 2.1 Add a blocker model: identifier, consequence, Apple reference, location.
- [x] 2.2 Detect the two blockers (no scene lifecycle, `UIRequiresFullScreen`) and remove
      both from the weighted checks.
- [x] 2.3 Report blockers before the score in the CLI summary and the HTML report; mark the
      quality score provisional under a full-screen opt-out.
- [x] 2.4 Emit `blockers` in the JSON result and document it.
- [x] 2.5 Gate policy: `forbid_blockers`, independent of the score floor.
- [x] 2.6 Order blocker-derived work-order entries first.

## 3. Continuous checks

- [x] 3.1 `navigation`: proportion of root navigation containers that can become a sidebar,
      counting the UIKit sidebar opt-in equally; report the denominator in the detail.
- [x] 3.2 `adaptive-layout`: offending UI files over UI files.
- [x] 3.3 `adaptive-geometry`: coverage of size-class and effective-geometry reads, and
      purity against idiom and orientation branching.
- [x] 3.4 `state`: preserved stateful views over stateful views.
- [x] 3.5 Remove the framework-ratio check.
- [x] 3.6 Not-applicable checks drop out and redistribute their weight; weights still sum
      to 1 with and without the visual check.

## 4. Calibration on the corpus

- [x] 4.1 Re-audit the twenty apps with the new engine and record the distribution.
- [x] 4.2 Set the geometry anchor from the corpus and write it into the contract document
      with its date and corpus.
- [x] 4.3 Set the weights from the measured spread, not from the proposal's guesses.
- [x] 4.4 Recalibrate the grade bands so the corpus spreads, and state each band's meaning
      in terms of behaviour.
- [x] 4.5 Record the before and after distribution in the repository, so the next rebalance
      starts from evidence rather than from memory.

## 5. Contract v2

- [x] 5.1 Bump `schema_version` to 2; document `blockers`, the removed `framework` key and
      the new check semantics.
- [x] 5.2 The gate skips regression rules against a baseline from another scoring version,
      with a stated reason and the command to rewrite the baseline.
- [x] 5.3 Regenerate the golden fixture and update the consumers.
- [ ] 5.4 PENDING: update `web/lib/data.ts`, the report pages and the index copy to the new
      scores and the blocker verdict. The check keys changed (`parallel`/`scene`/`fold`/
      `framework` are gone, `blockers` is new), so this is a component refactor, not a
      number swap. Until it lands, the published site shows superseded v1 scores.

## 6. Tests

- [x] 6.1 A UIKit app that adapts can reach the top grade; adopting the scene lifecycle
      lowers no check.
- [x] 6.2 Two apps of very different sizes with the same offending density score the same.
- [x] 6.3 Icon frames, previews, test paths and `XCUIScreen.main` produce no scored finding.
- [x] 6.4 A not-applicable check redistributes its weight and the weights still sum to 1.
- [x] 6.5 Blockers are reported, ordered first in the work order, and enforceable by policy.
- [x] 6.6 A v1 baseline against a v2 result skips the regression rules with a reason.

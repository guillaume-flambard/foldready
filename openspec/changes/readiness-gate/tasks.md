## 1. Result contract

- [x] 1.1 Add `schema_version` and per-check `key`, `weight`, `score` to the JSON payload
      in `JSONReport.swift`, keeping the human report unchanged.
- [x] 1.2 Make findings carry repository-relative paths, 1-based lines, severity, and the
      producing check key; strip absolute paths at the boundary.
- [x] 1.3 Add a test that audits a fixture from two different working directories and
      asserts byte-identical findings apart from the timestamp.
- [x] 1.4 Write `docs/result-contract.md` describing every field, the current version, and
      the compatibility rules.
- [x] 1.5 Add a `Scripts/check.sh` step that fails when the emitted fixture JSON differs
      from a committed golden file without a contract-document change in the same commit.
- [x] 1.6 Update `Scripts/extract-scores.py`, `aggregate-ports.py`, and `aggregate-index.py`
      to read the versioned payload.

## 2. Gate

- [x] 2.1 Add the `gate` subcommand to `main.swift` with `--baseline`, `--config`, and a
      JSON output flag.
- [x] 2.2 Implement policy evaluation: score floor, total regression, per-check regression,
      severity ceiling.
- [x] 2.3 Define and document exit codes: pass, policy breach, execution error.
- [x] 2.4 Implement baseline read and write, including the "no baseline yet" path that
      prints the command to create one.
- [x] 2.5 Print, for each rule, expected value, actual value, and the findings responsible.
- [x] 2.6 Tests: pass, floor breach, regression breach, per-check regression, missing
      baseline, malformed baseline, no configuration.

## 3. GitHub Action

- [x] 3.1 Write `action.yml` with documented inputs and the score, grade, and report-path
      outputs.
- [x] 3.2 Implement the action so it runs a pinned released FoldReady with no run-time
      fetch of an unpinned toolchain.
- [x] 3.3 On pull requests, audit base and head and report the delta; fall back to the job
      step summary when the token cannot write to the pull request.
- [x] 3.4 Upload the HTML report as a job artifact.
- [x] 3.5 Add a release workflow producing an immutable version tag and a moving major tag.
- [x] 3.6 Dogfood the action on this repository against a fixture app, and on one public
      app already in the index.

## 4. Work orders

- [x] 4.1 Reclassify the seven transforms into provably safe versus work order; delete the
      three-tier labelling from `PortModels.swift`.
- [x] 4.2 Emit `work-order.md` with file, line, check key, required end state, Apple
      reference, and acceptance condition per entry.
- [x] 4.3 Extend `verify` to report per-entry fixed / unchanged / regressed alongside the
      score delta.
- [ ] 4.4 BLOCKED (needs Xcode 27): verify the handoff end to end against Apple's exported
      app-modernization skill on a fixture, and record what it does and does not complete.
      This machine runs Xcode 26.6, where `xcrun agent skills export` does not exist
      (`xcrun agent` resolves to the MCP stdio bridge). Re-run once Xcode 27 is installed;
      the work order and `verify --work-order` are in place and tested against a fixture.
- [x] 4.5 Rewrite the README porting section around the measurement-versus-editing split,
      linking the WWDC26 session.

## 5. Sourcing pass

- [x] 5.1 Add a required reference field to every scored check and surface it in the HTML
      report next to the check.
- [x] 5.2 Add the `Scripts/check.sh` step that fails when a weighted check has no reference.
- [x] 5.3 Remove or label the Parallel View assertion in `README.md` and in the web copy;
      replace the premise with the UIScene launch requirement.
- [x] 5.4 Re-read the landing, ranking, and report copy for any other unsourced platform
      claim and fix it in the same pass.

## 6. Release

- [x] 6.1 Regenerate the six demo reports against the new contract and refresh
      `web/lib/data.ts`. Re-audited 2026-09-06 from fresh shallow clones: every score is
      unchanged (92/72/76/63/56/50), confirming the contract change moved no static score.
      IceCubesApp upstream grew (424 -> 428 Swift files, 214 -> 215.5 h) and two repo
      attributions were wrong (MochiDiffusion, Dime); both corrected.
- [ ] 6.2 Tag a release, publish the action, and add the one-line install snippet to the
      README and the site.
- [ ] 6.3 Replace the "good first issue" placeholder with issues drawn from these tasks, so
      the fork and any future contributor have something scoped to take.

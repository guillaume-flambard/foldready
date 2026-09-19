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
- [x] 4.4 Verify the handoff against Apple's exported app-modernization skill and record what
      it does and does not complete. DONE 2026-09-19 on Xcode 27.0 (27A266a), which *does*
      ship `xcrun agent skills export` (the earlier blocker said 26.6; that machine is gone).
      Exported 10 skills; `uikit-app-modernization` is the counterpart. Ran `foldready port`
      on a real corpus app (Open Food Facts, score 76) and compared its one work order and
      four entries against the skill's four task references. FINDINGS, carried into issue #5:
      (a) the `state` entry has NO counterpart in the skill, whose tasks are UIScreen,
      orientation, scene lifecycle and safe area only; (b) the two `adaptive-layout` entries
      are no more precise than the skill's own decision tree, and the window-frame entry
      duplicates the scene-lifecycle entry, since `UIWindow(frame: UIScreen.main.bounds)` is
      resolved BY the scene migration; (c) the skill covers a whole surface FoldReady does not
      score at all, safe-area insets (hardcoded 20/44/34/49 offsets, `topLayoutGuide`,
      assumptions of symmetric insets), which on a foldable is a real bug class; (d) the skill
      edits Swift AND Objective-C, while FoldReady reads `.swift` and `.plist` only. The
      division of labour is confirmed rather than assumed: FoldReady identifies and verifies,
      Apple's skill edits. The Duo simulator itself is still absent: Xcode 27.0 ships no
      iPhone Duo device type and only the iOS 26.5 runtime, so `verify --build` on Duo remains
      blocked until Apple publishes it.
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
- [x] 6.2 Tag a release, publish the action, and add the one-line install snippet to the
      README and the site. Tagged `v0.4.0` on 2026-09-18; the release workflow verified the
      tag against the binary, published the release and moved the `v0` major tag to the same
      commit, so `uses: guillaume-flambard/foldready@v0` resolves. The snippet is in the
      README CI section and on the landing page's free-scanner card, with a `snippet` style
      built from the existing tokens.
- [x] 6.3 Replace the "good first issue" placeholder with issues drawn from these tasks, so
      the fork and any future contributor have something scoped to take. The placeholder
      (#1) is now an index of the real work; scoped issues are #4 (audit-fidelity),
      #5 (verify the work order against Apple's exported skill) and #6 (regenerate the
      public index under contract v4).

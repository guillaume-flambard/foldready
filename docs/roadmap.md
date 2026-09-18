# FoldReady roadmap

Plan of record, written 18 September 2026 against Apple's published iPhone Duo dates:
preorders open 16 October, availability opens 23 October, Xcode 27.1 and the Duo simulator
in Device Hub arrive by the end of September.

This document is the order of work from today to the first paid readiness review. Each
phase states its entry condition, its exit condition and what it does not do.

## Where the project stands

Shipped and working:

- A Swift scanner that audits local source and reports a readiness score with per-check
  findings.
- A versioned result contract (`schema_version` 5), documented in
  [result-contract.md](result-contract.md), with a committed golden payload.
- A `gate` subcommand with committed baselines, per-rule reporting and distinct exit codes.
- A GitHub Action that audits base and head on a pull request and posts the score delta.
- A public site that renders the index from real audits.
- A scoped human deliverable, described in [readiness-review.md](readiness-review.md).

Built but unvalidated:

- The continuity prototype. It measures journey state across rotation under a real
  simulator. Human time savings, customer demand and Duo folding are all unproven, and the
  README says so.
- The offer itself. Zero reviews sold, zero buyers interviewed.

Blocked on Apple:

- The Duo simulator in Device Hub requires Xcode 27.1, which is not installed on this
  machine.
- Verifying the work-order handoff against Apple's exported `uikit-app-modernization` skill
  needs `xcrun agent skills export`, which does not exist before Xcode 27.

## Phase 0. Land the working tree

Entry: the tree carries an uncommitted body of work across four openspec changes.

Work:

1. Audit `git status` and split the diff into reviewable commits by change: continuity
   prototype and its docs, evidence sourcing, contract v3, web refresh, CI and release
   workflows.
2. Confirm `./Scripts/check.sh` passes on the final commit.
3. Push and confirm the action reports on itself.

Exit: `git status` is clean except for files this roadmap adds, and CI is green on the
branch.

Does not do: any new capability. This phase exists because everything below is easier to
review and revert when the starting point is a commit rather than a diff.

## Phase 1. Duo surface audit (18 to 25 September)

Entry: Phase 0 complete.

Work: the `duo-surface-audit` change in full. Four advisory surface detectors, one scored
`build-toolchain` check, contract v4, runtime checklist alignment, README refresh.

Exit: `openspec validate duo-surface-audit --strict` passes, tasks are closed, the six demo
reports are regenerated under v4, published baselines are rewritten once, and the README
`Apple announcements` section carries the current date and the six technology talks.

Why first: it is the only work that converts an Apple requirement into a checkable product
fact before the simulator exists, and it is the material a buyer reads in the five weeks
before launch.

## Phase 2. Release and distribution (25 September to 2 October)

Entry: Phase 1 merged. **Done 18 September, ahead of the window.**

Work:

1. Tag the release, publish the action, and add the one-line install snippet to the README
   (readiness-gate task 6.2). `v0.4.0` tagged and published; the release workflow moved the
   `v0` major tag to the same commit, so `uses: guillaume-flambard/foldready@v0` resolves.
   The snippet is in the README and on the landing page.
2. Replace the placeholder "good first issue" with scoped issues drawn from the open tasks
   (readiness-gate task 6.3). Issues #4, #5 and #6; #1 is now an index of them.
3. Version the release in `Version.swift` and the changelog. `Version.swift` reads `0.4.0`
   and the release workflow enforces tag-against-binary; no changelog file exists in this
   repository, GitHub release notes are generated from the commit range.

Exit: a stranger can add one line to a workflow and get a score on a pull request without
speaking to anyone. **Met:** pin `@v0`, no policy file means report-only.

Does not do: promotion. Distribution first, so any attention lands on something that works
unattended.

## Phase 3. Audit fidelity (October, first half)

Entry: the contract is stable at v4 and baselines exist.

Work: `audit-fidelity` ships contract v5. A dependency-free Swift lexer replaces line
matching, so a comment or a string literal cannot lower a score and a file that cannot be
lexed is reported rather than scored clean. Preview, test, vendored and generated code are
excluded by default, configurable in `.foldready.json`, and reported by reason. Interface
idiom and interface orientation become first-class scored checks, and the orientation check
reads the `Info.plist` keys as well as source. Every finding carries a confidence level, and
the gate can act on findings at or above a configured `min_confidence`.

A full Swift syntax tree is explicitly out of scope: the demonstrated false positives are all
comments and strings, and declaration-scope attribution is a recorded follow-up. The index
re-audit under v5 remains blocked on the twenty app checkouts (issue #6).

Exit: a red gate means a real finding, the false-positive paths named in the
`audit-fidelity` design are closed by test, and the index is re-audited under the new
version.

Why here and not earlier: the four Duo surfaces are advisory, so they tolerate line-based
matching. A scored check that can fail a build does not, and the gate must not be trusted
until attribution is lexed rather than textual.

## Phase 4. The launch window (16 to 23 October)

Entry: Xcode 27.1 and the Duo simulator are available, or the date has passed without them.

Work:

1. Install Xcode 27.1 and complete readiness-gate task 4.4: run the work order through
   Apple's exported skill on a fixture and record what it does and does not complete.
2. Run the scanner's own fixture app through `verify --build` on the Duo simulator and
   record the device, runtime and linked SDK in `capture.json`.
3. Refresh the site and the README for availability day, with the launch dates and the
   documented Xcode floor.
4. Re-audit the index under the v5 contract and publish the new scores.

Exit: the report can say "tested against these device types, on this runtime, with this SDK"
rather than "not tested".

Does not do: physical-device testing, which is out of the offer.

## Phase 5. First paid review

Entry: at least one app that a stranger owns gets a scored report they can read.

Work:

1. Run the scanner on target apps and use the report as the opening of a conversation, not
   as a finished deliverable.
2. Sell one review at the published price, with access, scope and delivery date agreed
   before starting.
3. Deliver against `readiness-review.md`: categorized findings, the runtime matrix filled
   with recorded evidence, a prioritized plan and the 30-day follow-up.
4. Record what the review actually cost in hours, against the effort heuristics the scanner
   printed.

Exit: one review delivered, paid, and the hour estimate compared with reality.

## Phase 6. Proof and honesty

Entry: one review delivered.

Work:

1. Publish an anonymised version of that review, with the buyer's consent, as the only
   credible sales asset this product can have.
2. Correct the effort heuristics in `AuditEngine.swift` against the measured hours, under a
   contract version bump.
3. Delete or fix anything the index cannot support. The site already labels pre-v3 rankings
   historical; keep that discipline.

Exit: the site's claims are each traceable to a delivered review or an Apple source.

## Standing constraints

- The product measures; Apple's tooling edits. Do not rebuild the port engine that
  `readiness-gate` deliberately demoted.
- A scanner score never establishes a defect. Any copy that implies otherwise is a bug.
- No claim about an App Store enforcement date Apple has not published.
- Every scored check carries a reference, enforced by `Scripts/check.sh`.
- Duo folding stays explicitly unsupported until the simulator work in Phase 4 replaces
  that line with a recorded result.

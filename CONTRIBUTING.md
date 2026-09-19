# Contributing to FoldReady

FoldReady provides source evidence for a scoped human review of iOS apps. The immediate
focus is the first paid review, as defined in [the roadmap](docs/roadmap.md).

## What's most useful right now

- Fix misleading outputs and retain evidence, confidence and coverage limits.
- Protect the versioned result contract and existing gate behavior.
- Test false positives and clearly separate static acceptance from runtime observations.
- Keep website claims consistent with the review's measured coverage.

New checks, port transforms and platform expansion are deferred until buyer evidence
justifies them.

## Getting started

```sh
git clone https://github.com/guillaume-flambard/foldready.git
cd foldready
swift build
swift test
./Scripts/check.sh  # build + tests + web build
```

## Rules

1. **Never break code silently.** A transform's output must build or be clearly
   gated for human review (dry-run patch by default).
2. **Anchored on the public contract.** `UIScreen.main`, idiom, orientation and
   internal strings are antipatterns; size classes and effective geometry are the
   answers.
3. **Numbers are monospaced and tabular.** The FoldReady design system is not
   negotiable on this point.
4. **Tests travel with the change.** Run `./Scripts/check.sh` before pushing.
5. Write a commit message that states the *why*, not just the *what*.

## Working with the CLI

- `foldready <repo>` — audit (score, findings, hours estimate)
- `foldready port <repo> [--tiers srm] [--apply]` — generate/apply porting patches
- `foldready verify <repo> [--build]` — re-score after a port

## License

MIT. By contributing you agree to license your contribution under the same
terms.

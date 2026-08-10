# Contributing to FoldReady

FoldReady audits and ports iOS apps for the iPhone Fold. It is built on the
**public** iOS 27 contract (UIScene lifecycle mandate, Parallel View opt-in,
adaptive layout, `NavigationSplitView` + `.adaptiveSidebar`). The internal
`foldState` / `angleDegrees` strings are NOT public API and are never a port
target — contributions that rely on them are rejected.

## What's most useful right now

- **New audit checks**: signals that a real codebase trips, backed by a
  `Sources/foldready/AuditEngine.swift` check + a unit test fixture.
- **New or improved port transforms** in `Sources/foldready/Port/Transforms.swift`:
  safe, review, or manual tier; never break code silently; always produce a
  reviewable diff.
- **Edge-case tests** in `Tests/foldreadyTests/` for the lexer and transforms.
- **Web** (`web/`): the Next.js app, design-system fidelity, accessibility.

## Getting started

```sh
git clone https://github.com/guillaume-flambard/foldready.git
cd foldready
swift build
swift test          # 17 tests, all green
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

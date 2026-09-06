#!/usr/bin/env python3
"""Fail when a check can reach the score without citing an Apple source.

The rule (openspec/specs/evidence/sourcing): a check that contributes to the score must
cite Apple documentation, a WWDC session, or a technical note. A rule that lives only in a
document is a rule a contributor breaks in good faith, so it is enforced here.

Two guards:
  1. every `CheckOutcome(...)` construction passes a `reference:` argument;
  2. every reference constant in Reference.swift points at developer.apple.com.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ENGINE = ROOT / "Sources" / "foldready" / "AuditEngine.swift"
REFERENCES = ROOT / "Sources" / "foldready" / "Reference.swift"


def constructions(source: str):
    """Yield (line number, argument text) for each CheckOutcome(...) call."""
    for match in re.finditer(r"CheckOutcome\(", source):
        depth, i = 1, match.end()
        while i < len(source) and depth:
            if source[i] == "(":
                depth += 1
            elif source[i] == ")":
                depth -= 1
            i += 1
        yield source[: match.start()].count("\n") + 1, source[match.end(): i]


def main() -> int:
    failures = []

    source = ENGINE.read_text()
    for line, args in constructions(source):
        if "reference:" not in args:
            failures.append(f"{ENGINE.relative_to(ROOT)}:{line}: CheckOutcome without a reference")

    for line_no, line in enumerate(REFERENCES.read_text().splitlines(), 1):
        for url in re.findall(r'"(https?://[^"]+)"', line):
            if not url.startswith("https://developer.apple.com/"):
                failures.append(
                    f"{REFERENCES.relative_to(ROOT)}:{line_no}: '{url}' is not an Apple source")

    if failures:
        print("sourcing check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        print("\nEvery scored check cites Apple. Add the source to "
              "Sources/foldready/Reference.swift and pass it to the check.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

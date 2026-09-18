#!/usr/bin/env python3
"""Fail when a check can reach the score without citing an Apple source.

The rule (openspec/specs/evidence/sourcing): a check that contributes to the score must
cite Apple documentation, a WWDC session, or a technical note. A rule that lives only in a
document is a rule a contributor breaks in good faith, so it is enforced here.

Two guards:
  1. every `CheckOutcome(...)` construction passes a `reference:` argument;
  2. every reference constant in Reference.swift points at developer.apple.com.

A third guard covers the advisory Duo surfaces (openspec/changes/duo-surface-audit): every
surface named in DuoSurfaces.reference(for:) must map to a Reference constant. Advisory
findings do not score, but they still make a claim about the platform, so the claim cites Apple.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ENGINE = ROOT / "Sources" / "foldready" / "AuditEngine.swift"
REFERENCES = ROOT / "Sources" / "foldready" / "Reference.swift"
SURFACES = ROOT / "Sources" / "foldready" / "DuoSurfaces.swift"


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

    # Advisory surfaces: every surface that can produce a finding must reach Reference.
    surface_source = SURFACES.read_text()
    if "func reference(for surface: String) -> String" not in surface_source:
        failures.append(
            f"{SURFACES.relative_to(ROOT)}: reference(for:) is missing; a surface without a "
            "source is a platform claim nobody checked")
    else:
        for line_no, line in enumerate(surface_source.splitlines(), 1):
            if "Reference." not in line:
                continue
            for constant in re.findall(r"Reference\.([A-Za-z0-9_]+)", line):
                if f"static let {constant}" not in REFERENCES.read_text():
                    failures.append(
                        f"{SURFACES.relative_to(ROOT)}:{line_no}: Reference.{constant} is not "
                        "declared in Reference.swift")

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

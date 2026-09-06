#!/usr/bin/env python3
"""Audit the contract fixture and compare the payload against the committed golden file.

The result JSON is FoldReady's public interface (docs/result-contract.md). This guard
fails the build when the emitted shape drifts, so a change to the contract is always a
deliberate, reviewed act rather than a side effect.

    Scripts/contract-golden.py            # compare (exit 1 on drift)
    Scripts/contract-golden.py --update   # rewrite the golden file
"""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FIXTURE = ROOT / "Tests" / "Fixtures" / "ContractApp"
GOLDEN = ROOT / "Tests" / "Fixtures" / "contract-golden.json"
BINARY = ROOT / ".build" / "debug" / "foldready"

# Fields that legitimately differ between two runs of the same tree.
VOLATILE = ("generated_at", "foldready_version")


def audit() -> dict:
    out_dir = ROOT / ".build" / "contract-golden"
    subprocess.run(
        [str(BINARY), str(FIXTURE), "--name", "ContractApp", "--json", "--out", str(out_dir)],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    payload = json.loads((out_dir / "result.json").read_text())
    for field in VOLATILE:
        payload.pop(field, None)
    return payload


def main() -> int:
    if not BINARY.exists():
        print(f"contract golden: {BINARY} not built — run swift build first", file=sys.stderr)
        return 1

    current = audit()

    if "--update" in sys.argv:
        GOLDEN.write_text(json.dumps(current, indent=2, sort_keys=True) + "\n")
        print(f"contract golden: rewrote {GOLDEN.relative_to(ROOT)}")
        return 0

    if not GOLDEN.exists():
        print(f"contract golden: {GOLDEN.relative_to(ROOT)} missing — "
              f"run Scripts/contract-golden.py --update", file=sys.stderr)
        return 1

    expected = json.loads(GOLDEN.read_text())
    if current == expected:
        return 0

    print("contract golden: the emitted result no longer matches the golden file.",
          file=sys.stderr)
    for key in sorted(set(expected) | set(current)):
        if expected.get(key) != current.get(key):
            print(f"  field '{key}' changed", file=sys.stderr)
    print("\nIf this is intended: update docs/result-contract.md (bump schema_version when "
          "a field was removed, renamed, or changed meaning, or when scoring changed), then "
          "run Scripts/contract-golden.py --update.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())

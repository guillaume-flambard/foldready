#!/usr/bin/env python3
"""Validate the completeness and INTERNAL consistency of a Duo hinge proof.

This is not an app compatibility certificate and does not validate arbitrary
screenshot content. A valid bundle still requires independent visual review
of the PNGs and the Appium/WDA execution logs.
"""
from __future__ import annotations

from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import struct
import sys

WINDOW = re.compile(r"^Window: ([1-9][0-9]*) x ([1-9][0-9]*)$")
PNG_HEADER = b"\x89PNG\r\n\x1a\n"
PROOF_SEQUENCE = [("initial_closed", 0), ("opened", 180), ("reclosed", 0)]


def require(condition: bool, explanation: str) -> None:
    if not condition:
        raise ValueError(explanation)


def window(text: object) -> tuple[int, int]:
    match = WINDOW.fullmatch(text) if isinstance(text, str) else None
    require(match is not None, f"Bad window geometry: {text!r}")
    assert match
    return int(match.group(1)), int(match.group(2))


def png_info(path: Path) -> tuple[int, int, str]:
    require(path.is_file(), f"Missing evidence screenshot: {path.name}")
    data = path.read_bytes()
    require(len(data) > 1024, f"Screenshot too small to be credible: {path.name}")
    require(data[:8] == PNG_HEADER and data[12:16] == b"IHDR", f"Invalid PNG header: {path.name}")
    require(struct.unpack(">I", data[8:12])[0] == 13, f"Invalid PNG IHDR length: {path.name}")
    width, height = struct.unpack(">II", data[16:24])
    require(width > 0 and height > 0, f"Invalid screenshot dimensions: {path.name}")
    return width, height, hashlib.sha256(data).hexdigest()


def validate(proof_directory: Path) -> dict:
    proof = proof_directory / "hinge-evidence.json"
    require(proof.is_file(), "Missing hinge-evidence.json")
    document = json.loads(proof.read_text())
    require(document.get("status") == "passed_synthetic_fold_unfold_continuity",
            "Run was not completed and positively verified")
    require(document.get("fold_unfold_transition") == "passed_synthetic_simulator",
            "No real synthetic simulator transition marked passed")
    require(document.get("physical_device") == "not_tested" and
            document.get("customer_app") == "not_tested",
            "Do not extrapolate a synthetic simulator run to clients or hardware")
    require(document.get("device") == "iPhone Duo" and document.get("runtime") == "iOS 27.1",
            "Unexpected simulator or OS")
    sha = document.get("source_sha")
    require(isinstance(sha, str) and bool(re.fullmatch(r"[a-f0-9]{40}", sha)),
            "Missing or invalid executable code revision provenance")
    dt = document.get("recorded_utc")
    require(isinstance(dt, str) and datetime.fromisoformat(dt.replace("Z", "+00:00")).tzinfo is not None,
            "Missing UTC timestamp")
    displays = document.get("displays")
    require(isinstance(displays, list) and len(displays) >= 2, "No actual two-display inventory")
    candidates: list[tuple[int, int]] = []
    for display in displays:
        require(isinstance(display, dict) and isinstance(display.get("id"), int),
                "Malformed display identifier")
        metrics = display.get("metrics") or {}
        width, height = metrics.get("widthPixels"), metrics.get("heightPixels")
        require(isinstance(width, int) and isinstance(height, int) and width > 0 and height > 0,
                "Missing real display pixel dimensions")
        candidates.append((width * height, display["id"]))
    candidates.sort()
    cover_id, inner_id = candidates[0][1], candidates[-1][1]
    require(cover_id != inner_id, "Both stages resolve to the same display")
    # Preserve the source provider's display IDs; never hardcode id 1 or 3.

    rows = document.get("before_after")
    require(isinstance(rows, list) and len(rows) == 3,
            "Need exactly three observed stages (closed/open/reclosed)")
    parsed: list[tuple[int, int]] = []
    checksums: dict[str, str] = {}
    for i, ((name, expected_angle), row) in enumerate(zip(PROOF_SEQUENCE, rows)):
        require(isinstance(row, dict), f"Stage {i} is not a record")
        require(row.get("stage") == name and row.get("requested_angle") == expected_angle,
                f"Stage order/request mismatch at {name}")
        sensor = row.get("sensor_angle")
        require(not isinstance(sensor, bool) and isinstance(sensor, (int, float)) and
                abs(sensor - expected_angle) <= 10,
                f"No observed hinge readback at {name}: {sensor!r}")
        expected_display = cover_id if i != 1 else inner_id
        require(row.get("selected_display") == expected_display,
                f"Wrong display at {name} (expected {expected_display})")
        require(row.get("name") == "Ada", f"Form value was not preserved at {name}")
        geometry = window(row.get("geometry"))
        parsed.append(geometry)
        filename = row.get("evidence")
        require(isinstance(filename, str) and filename == {
            "initial_closed": "duo-before-closed.png",
            "opened": "duo-opened.png",
            "reclosed": "duo-reclosed.png",
        }[name], f"Unexpected screenshot filename at {name}")
        width, height, digest = png_info(proof_directory / filename)
        pixels = width * height
        target_area = next(area for area, ident in candidates if ident == expected_display)
        require(abs(pixels / target_area - 1.0) < 0.01,
                f"PNG resolution does not match selected display at {name}")
        checksums[filename] = digest
    require(parsed[0] != parsed[1], "Window never actually changed during opening")
    require(parsed[2] == parsed[0], "Original window geometry not restored")
    result = {
        "validated": "synthetic_duo_hinge_bundle_internal_consistency",
        "source_sha": sha,
        "stages": [x[0] for x in PROOF_SEQUENCE],
        "screenshots_sha256": checksums,
        "limits": ["synthetic_fixture_only", "simulator_only", "no_visual_semantic_validation",
                   "no_customer_or_device_certification"],
    }
    return result


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: validate_duo_hinge_evidence.py DIR", file=sys.stderr)
        return 2
    try:
        report = validate(Path(sys.argv[1]))
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"INVALID EVIDENCE: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2))
    print("Bundle is internally consistent. Visual review still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Fail-closed INTERNAL evidence check for the synthetic Duo list journey.

The selected row, actual table scroll offset, hinge sensor readback, changing
UI window geometry, and three matching PNGs are required. Visual semantic
inspection is separate. This is never a physical-device or client-app verdict.
"""
from __future__ import annotations

from datetime import datetime
import json
from pathlib import Path
import re
import sys

from validate_duo_hinge_evidence import png_info, require, window

STAGES = [
    ("initial_closed", 0, "duo-list-initial_closed.png"),
    ("opened", 180, "duo-list-opened.png"),
    ("reclosed", 0, "duo-list-reclosed.png"),
]


def validate(path: Path) -> dict:
    filename = path / "list-evidence.json"
    require(filename.is_file(), "Missing list-evidence.json")
    obj = json.loads(filename.read_text())
    require(obj.get("status") == "passed_synthetic_list_hinge_continuity",
            "List execution did not actually pass")
    require(obj.get("fold_unfold_transition") == "passed_synthetic_simulator",
            "No simulator hinge proof")
    require(obj.get("customer_app") == "not_tested" and obj.get("physical_device") == "not_tested",
            "Cannot infer a customer/hardware result")
    require(obj.get("journey") == "synthetic_uitableview_selection", "Unexpected test journey")
    require(obj.get("device") == "iPhone Duo" and obj.get("runtime") == "iOS 27.1",
            "Unexpected simulator environment")
    require(isinstance(obj.get("source_sha"), str) and
            re.fullmatch(r"[0-9a-f]{40}", obj["source_sha"]) is not None,
            "Missing source revision")
    ts = obj.get("recorded_utc")
    require(isinstance(ts, str) and datetime.fromisoformat(ts.replace("Z", "+00:00")).tzinfo,
            "Missing timezone-aware run timestamp")

    displays = obj.get("displays")
    require(isinstance(displays, list) and len(displays) >= 2, "Need both Duo display inventories")
    area = []
    for display in displays:
        require(isinstance(display, dict) and isinstance(display.get("id"), int),
                "Invalid display identifier")
        m = display.get("metrics") or {}
        w, h = m.get("widthPixels"), m.get("heightPixels")
        require(isinstance(w, int) and isinstance(h, int) and w > 0 and h > 0,
                "Missing display dimensions")
        area.append((w * h, display["id"]))
    area.sort()
    cover, inner = area[0][1], area[-1][1]
    require(cover != inner, "Cannot verify a transition with one display")

    rows = obj.get("before_after")
    require(isinstance(rows, list) and len(rows) == 3, "Require exactly three distinct hinge poses")
    geometries = []
    digests = {}
    for i, (row, (name, target, screenshot)) in enumerate(zip(rows, STAGES)):
        require(isinstance(row, dict) and row.get("stage") == name and
                row.get("requested_angle") == target, "Incorrect stage order/request")
        sensor = row.get("sensor_angle")
        require(not isinstance(sensor, bool) and isinstance(sensor, (int, float)) and
                abs(sensor - target) <= 10, f"Angle was not actually read back at {name}")
        display = cover if i != 1 else inner
        require(row.get("selected_display") == display, f"Wrong active display at {name}")
        require(row.get("selection") == "Item 70", f"Lost selected row at {name}")
        offset = row.get("scroll_offset")
        require(not isinstance(offset, bool) and isinstance(offset, (int, float)) and
                offset >= 100, f"List was not actually scrolled at {name}")
        geometries.append(window(row.get("geometry")))
        require(row.get("evidence") == screenshot, "Missing or unexpectedly named screenshot")
        w, h, digest = png_info(path / screenshot)
        size = next(a for a, ident in area if ident == display)
        require(abs((w * h) / size - 1.0) < 0.01,
                f"Screenshot pixels do not match active display at {name}")
        digests[screenshot] = digest

    require(geometries[0] != geometries[1], "Opening did not resize the app window")
    require(geometries[0] == geometries[2], "Closing did not restore initial window")
    return {
        "validated": "synthetic_duo_list_selection_and_scroll_consistency",
        "source_sha": obj["source_sha"],
        "stages": [x[0] for x in STAGES],
        "screenshots_sha256": digests,
        "limits": ["synthetic_UIKit_list_only", "programmatic_scroll_to_row",
                   "simulator_only", "visual_review_required",
                   "not_customer_or_hardware_certification"],
    }


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: validate_duo_list_evidence.py DIR", file=sys.stderr)
        return 2
    try:
        result = validate(Path(sys.argv[1]))
    except (ValueError, TypeError, KeyError, json.JSONDecodeError) as exc:
        print(f"INVALID LIST EVIDENCE: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2))
    print("List report internally consistent; visual review still mandatory.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Exercise actual UIKit table scroll + row selection across Duo simulated hinge.

Requires the pinned Appium/WDA server from the existing Duo workflow. This is a
synthetic selected-row continuity test, not a finger-gesture or customer-app test.
"""
from __future__ import annotations

from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import sys
import time

import probe_duo_hinge as p

PROOF = Path(os.environ["DUO_PROOF_DIR"])
PROOF.mkdir(parents=True, exist_ok=True)
evidence = {
    "schema_version": 1,
    "journey": "synthetic_uitableview_selection",
    "source_sha": os.environ.get("GITHUB_SHA"),
    "fixture": "synthetic 80-row UIKit UITableView",
    "device": "iPhone Duo",
    "runtime": "iOS 27.1",
    "driver": "appium-xcuitest-driver@12.20.0",
    "status": "execution_error",
    "before_after": [],
    "fold_unfold_transition": "not_tested",
    "physical_device": "not_tested",
    "customer_app": "not_tested",
}


def read_list_state() -> tuple[str, int, str]:
    end = time.monotonic() + 35
    error = None
    while time.monotonic() < end:
        try:
            selected = p.attr(p.element("listSelected"), "value")
            offset_raw = p.attr(p.element("listOffset"), "value")
            geometry = p.attr(p.element("geometry"), "label")
            require = re.fullmatch(r"Window: ([1-9]\d*) x ([1-9]\d*)", geometry)
            offset = int(offset_raw)
            if selected == "Item 70" and offset >= 100 and require:
                return selected, offset, geometry
            error = f"selected={selected!r}, offset={offset}, geometry={geometry!r}"
        except (ValueError, RuntimeError, AssertionError) as exc:
            error = str(exc)
        time.sleep(1)
    raise AssertionError(f"List selection/scroll did not survive hinge: {error}")


def stage(name: str, target: int, display: int) -> dict:
    measured = p.set_angle(target)
    p.select_display(display)
    selected, offset, geometry = read_list_state()
    filename = f"duo-list-{name}.png"
    p.save_screen(filename)
    row = {
        "stage": name, "requested_angle": target, "sensor_angle": measured,
        "selected_display": display, "selection": selected,
        "scroll_offset": offset, "geometry": geometry, "evidence": filename,
    }
    evidence["before_after"].append(row)
    print("Verified list:", json.dumps(row), flush=True)
    return row


def main() -> None:
    try:
        caps = {
            "platformName": "iOS",
            "appium:automationName": "XCUITest",
            "appium:deviceName": "iPhone Duo",
            "appium:platformVersion": "27.1",
            "appium:udid": os.environ["DUO_UDID"],
            "appium:app": os.environ["DUO_APP_PATH"],
            "appium:noReset": True,
            "appium:showXcodeLog": True,
            "appium:wdaLaunchTimeout": 300000,
            "appium:wdaConnectionTimeout": 180000,
            "appium:wdaStartupRetries": 1,
            "appium:newCommandTimeout": 240,
        }
        print("Starting synthetic list Appium session...", flush=True)
        value = p.request("POST", "/session",
                          {"capabilities": {"alwaysMatch": caps, "firstMatch": [{}]}},
                          timeout=480)
        if not isinstance(value, dict) or not value.get("sessionId"):
            raise RuntimeError(f"No Appium session: {value!r}")
        p.session = str(value["sessionId"])
        cover, inner, displays = p.displays()
        evidence["displays"] = displays

        if abs(p.angle()) > p.TOLERANCE:
            p.set_angle(0)
        p.select_display(cover)
        p.session_cmd("POST", f"/element/{p.element('openListDemo')}/click", {})
        p.session_cmd("POST", f"/element/{p.element('listJumpTo70')}/click", {})
        p.session_cmd("POST", f"/element/{p.element('listItem-70')}/click", {})
        selected, offset, geometry = read_list_state()
        p.save_screen("duo-list-initial_closed.png")
        evidence["before_after"].append({
            "stage": "initial_closed", "requested_angle": 0, "sensor_angle": p.angle(),
            "selected_display": cover, "selection": selected,
            "scroll_offset": offset, "geometry": geometry,
            "evidence": "duo-list-initial_closed.png",
        })
        opened = stage("opened", 180, inner)
        closed = stage("reclosed", 0, cover)
        first = evidence["before_after"][0]
        if opened["geometry"] == first["geometry"]:
            raise AssertionError("No observed app-window resize on hinge opening")
        if closed["geometry"] != first["geometry"]:
            raise AssertionError("Original app-window geometry not restored")
        evidence["status"] = "passed_synthetic_list_hinge_continuity"
        evidence["fold_unfold_transition"] = "passed_synthetic_simulator"
        print("Synthetic Duo list-selection continuity PASSED", flush=True)
    except Exception as exc:
        evidence["status"] = "failed_or_unsupported"
        evidence["error"] = f"{type(exc).__name__}: {exc}"
        print("LIST PROBE FAILED:", evidence["error"], file=sys.stderr, flush=True)
        raise
    finally:
        evidence["recorded_utc"] = datetime.now(timezone.utc).isoformat()
        (PROOF / "list-evidence.json").write_text(json.dumps(evidence, indent=2) + "\n")
        if p.session:
            try:
                p.session_cmd("DELETE", "")
            except Exception as exc:
                print(f"List Appium cleanup: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()

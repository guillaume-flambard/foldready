#!/usr/bin/env python3
"""Evidence-gated synthetic iPhone Duo hinge continuity probe using Appium 3/WDA.

No third-party Python dependencies. NEVER promote a successful hinge command
to a passing transition without angle readback, display/window changes and UI
state verification. Requires a *synthetic* local .app, never client source.
"""
from __future__ import annotations

import base64
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ENDPOINT = os.environ.get("APPIUM_URL", "http://127.0.0.1:4723").rstrip("/")
BUNDLE = "dev.memolabs.ContinuityDemo"
OUTPUT = Path(os.environ["DUO_PROOF_DIR"])
UDID = os.environ["DUO_UDID"]
APP = os.environ["DUO_APP_PATH"]
TOLERANCE = 10.0

OUTPUT.mkdir(parents=True, exist_ok=True)
record = {
    "schema_version": 1,
    "fixture": "synthetic UIKit form, never client source",
    "source_sha": os.environ.get("GITHUB_SHA"),
    "device": "iPhone Duo",
    "runtime": "iOS 27.1",
    "simulator_udid": UDID,
    "driver": "appium-xcuitest-driver@12.20.0",
    "status": "execution_error",
    "before_after": [],
    "fold_unfold_transition": "not_tested",
    "physical_device": "not_tested",
    "customer_app": "not_tested",
}
session = None


def request(method: str, path: str, body: object | None = None, timeout: int = 180) -> object:
    encoded = None if body is None else json.dumps(body).encode()
    req = Request(
        ENDPOINT + path,
        data=encoded,
        headers={"Content-Type": "application/json"},
        method=method,
    )
    try:
        with urlopen(req, timeout=timeout) as res:
            payload = json.loads(res.read())
    except HTTPError as err:
        detail = err.read(3000).decode("utf-8", "replace")
        raise RuntimeError(f"Appium {method} {path}: HTTP {err.code}: {detail}") from err
    except (URLError, TimeoutError) as err:
        raise RuntimeError(f"Appium {method} {path}: timed out or unreachable: {err}") from err
    if not isinstance(payload, dict) or "value" not in payload:
        raise RuntimeError(f"Unexpected Appium W3C response for {path}: {str(payload)[:400]}")
    if isinstance(payload["value"], dict) and payload["value"].get("error"):
        raise RuntimeError(f"Appium {path}: {payload['value']}")
    return payload["value"]


def session_cmd(method: str, suffix: str, body: object | None = None) -> object:
    assert session
    return request(method, f"/session/{session}{suffix}", body)


def execute(script: str, args: list[object] | None = None) -> object:
    return session_cmd("POST", "/execute/sync", {"script": script, "args": args or []})


def angle() -> float:
    value = execute("mobile: getSimulatedHingeAngle")
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise RuntimeError(f"Invalid hinge readback: {value!r}")
    return float(value)


def set_angle(target: int) -> float:
    # Command submission is not proof of movement. Poll the sensor independently.
    execute("mobile: setSimulatedHingeAngle", [{"angle": target}])
    deadline = time.monotonic() + 40
    observed = None
    while time.monotonic() < deadline:
        observed = angle()
        if abs(observed - target) <= TOLERANCE:
            time.sleep(2)  # permit scene/layout transition after hinge reading
            return observed
        time.sleep(1)
    raise AssertionError(f"Hinge failed to reach {target}; sensor reads {observed}")


def displays() -> tuple[int, int, list[dict]]:
    values = execute("mobile: listDisplays")
    if not isinstance(values, list) or len(values) < 2:
        raise AssertionError(f"Expected Duo cover and inner displays, got {values}")
    dims = []
    for item in values:
        metrics = item.get("metrics") or {}
        width, height = metrics.get("widthPixels"), metrics.get("heightPixels")
        if not isinstance(width, (int, float)) or not isinstance(height, (int, float)):
            raise AssertionError(f"Display has no native pixel dimensions: {item}")
        dims.append((int(width * height), item["id"]))
    dims.sort()
    return dims[0][1], dims[-1][1], values


def select_display(display_id: int) -> None:
    session_cmd("POST", "/appium/settings", {"settings": {"currentDisplayId": display_id}})


def element(accessibility_id: str) -> str:
    result = session_cmd("POST", "/element", {"using": "accessibility id", "value": accessibility_id})
    if not isinstance(result, dict):
        raise AssertionError(f"Invalid element {accessibility_id}: {result!r}")
    result_id = result.get("element-6066-11e4-a52e-4f735466cecf") or result.get("ELEMENT")
    if not result_id:
        raise AssertionError(f"Missing WebDriver element ID for {accessibility_id}: {result!r}")
    return result_id


def attr(identifier: str, name: str) -> str:
    return str(session_cmd("GET", f"/element/{identifier}/attribute/{name}"))


def state() -> tuple[str, str]:
    deadline = time.monotonic() + 35
    failure = None
    while time.monotonic() < deadline:
        try:
            name = attr(element("name"), "value")
            geometry = attr(element("geometry"), "label")
            if name == "Ada" and geometry.startswith("Window: "):
                return name, geometry
            failure = f"name={name!r}, geometry={geometry!r}"
        except (RuntimeError, AssertionError) as e:
            failure = str(e)
        time.sleep(1.5)
    raise AssertionError(f"Visible form state not preserved/retrievable: {failure}")


def save_screen(name: str) -> None:
    data = session_cmd("GET", "/screenshot")
    if not isinstance(data, str):
        raise RuntimeError("Appium screenshot payload is not base64")
    blob = base64.b64decode(data, validate=True)
    if len(blob) < 1024 or not blob.startswith(b"\x89PNG\r\n\x1a\n"):
        raise AssertionError("No real PNG frame returned by selected display")
    (OUTPUT / name).write_bytes(blob)


def stage(label: str, target: int, display_id: int) -> dict:
    actual = set_angle(target)
    # Display selection NEVER changes automatically when the Duo folds.
    select_display(display_id)
    value, geometry = state()
    save_screen(f"duo-{label}.png")
    item = {
        "stage": label, "requested_angle": target, "sensor_angle": actual,
        "selected_display": display_id, "name": value,
        "geometry": geometry, "evidence": f"duo-{label}.png",
    }
    record["before_after"].append(item)
    print("Verified:", json.dumps(item), flush=True)
    return item


def main() -> None:
    global session
    try:
        capabilities = {
            "platformName": "iOS",
            "appium:automationName": "XCUITest",
            "appium:deviceName": "iPhone Duo",
            "appium:platformVersion": "27.1",
            "appium:udid": UDID,
            "appium:app": APP,
            "appium:noReset": True,
            "appium:wdaLaunchTimeout": 300000,
            "appium:showXcodeLog": True,
            "appium:wdaStartupRetries": 1,
            "appium:wdaStartupRetryInterval": 5000,
            "appium:wdaConnectionTimeout": 180000,
            "appium:newCommandTimeout": 240,
        }
        print("Establishing WebDriverAgent session (cold start may compile WDA)...", flush=True)
        value = request("POST", "/session", {"capabilities": {"alwaysMatch": capabilities, "firstMatch": [{}]}}, timeout=480)
        if not isinstance(value, dict) or not value.get("sessionId"):
            raise RuntimeError(f"Appium session not established: {str(value)[:400]}")
        session = str(value["sessionId"])
        print("Appium session established", flush=True)

        outer, inner, screen_list = displays()
        record["displays"] = screen_list
        # First ensure a known closed pose; do not infer one from pixels alone.
        initial_angle = angle()
        if abs(initial_angle) > TOLERANCE:
            set_angle(0)
        select_display(outer)
        click_target = element("step1")
        session_cmd("POST", f"/element/{click_target}/click", {})
        name, geometry = state()
        save_screen("duo-before-closed.png")
        record["before_after"].append({
            "stage": "initial_closed", "requested_angle": 0, "sensor_angle": angle(),
            "selected_display": outer, "name": name,
            "geometry": geometry, "evidence": "duo-before-closed.png",
        })

        opened = stage("opened", 180, inner)
        closed = stage("reclosed", 0, outer)
        initial_geometry = record["before_after"][0]["geometry"]
        if opened["geometry"] == initial_geometry:
            raise AssertionError("Hinge sensor changed but app window geometry did not")
        if closed["geometry"] != initial_geometry:
            raise AssertionError("Reclosed scene did not restore original geometry")
        record["status"] = "passed_synthetic_fold_unfold_continuity"
        record["fold_unfold_transition"] = "passed_synthetic_simulator"
        print("Synthetic Duo hinge state-continuity proof PASSED", flush=True)
    except Exception as exc:
        record["status"] = "failed_or_unsupported"
        record["error"] = f"{type(exc).__name__}: {exc}"
        print("HINGE PROBE FAILED:", record["error"], file=sys.stderr, flush=True)
        raise
    finally:
        record["recorded_utc"] = datetime.now(timezone.utc).isoformat()
        (OUTPUT / "hinge-evidence.json").write_text(json.dumps(record, indent=2) + "\n")
        if session:
            try:
                session_cmd("DELETE", "")
            except Exception as exc:
                print(f"Appium session cleanup: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()

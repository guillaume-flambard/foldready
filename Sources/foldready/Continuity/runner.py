#!/usr/bin/env python3
"""Local XCTest measurement harness. No network, production data or score contract."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import time
import uuid

STATUSES = {"passed", "functional_failure", "execution_error", "not_executed"}
JOURNEYS = {"form", "cart", "draft"}


class Parser(argparse.ArgumentParser):
    def error(self, message):
        self.print_usage(sys.stderr)
        self.exit(1, "error: " + message + "\n")


def selection(value, allowed):
    values = value.split(",")
    if not values or len(values) != len(set(values)) or not set(values) <= set(allowed):
        raise argparse.ArgumentTypeError("Choose unique values from " + ",".join(sorted(allowed)))
    return values


def load_spec(project):
    spec = json.loads((project.parent / "journeys.json").read_text())
    if spec.get("schema_version") != 1 or {j["id"] for j in spec["journeys"]} != JOURNEYS:
        raise ValueError("Expected demo journeys.json schema 1 with form, cart and draft")
    if len(spec["journeys"]) != 3:
        raise ValueError("Duplicate journeys")
    for journey in spec["journeys"]:
        points = journey["checkpoints"]
        if not points or len({p["id"] for p in points}) != len(points):
            raise ValueError("Missing or duplicate checkpoints")
        for point in points:
            if not point["id"] or "/" in point["id"] or point["id"] == "control":
                raise ValueError("Invalid checkpoint identifier")
            if not point["steps"] or not all(s in ("step1", "step2") for s in point["steps"]):
                raise ValueError("Invalid demo actions")
            if not point["expected"] or not all(isinstance(k, str) and isinstance(v, str)
                                                 for k, v in point["expected"].items()):
                raise ValueError("Invariants must contain nonempty string maps")
            if type(point["broken_fails"]) is not bool:
                raise ValueError("Fixture ground truth must be a boolean")
    return spec


def planned_cases(spec, journeys, variants, approaches, repetitions, transition):
    cases = []
    for approach in approaches:
        for journey in spec["journeys"]:
            if journey["id"] not in journeys:
                continue
            control = dict(journey["checkpoints"][-1], id="control", broken_fails=False)
            for variant in variants:
                for repetition in range(1, repetitions + 1):
                    for point in [control] + journey["checkpoints"]:
                        checkpoint = point["id"]
                        cases.append({
                            "id": "/".join([approach, journey["id"], variant, checkpoint, str(repetition)]),
                            "approach": approach, "journey": journey["id"], "variant": variant,
                            "checkpoint": checkpoint, "repetition": repetition,
                            "requested_transition": "none" if checkpoint == "control" else transition,
                            "expected": point["expected"],
                            "final_expected": control["expected"],
                            "expected_status": "functional_failure" if variant == "broken" and point["broken_fails"] else "passed",
                            "status": "not_executed", "actual_transitions": [], "attachments": [],
                            "reason": "XCTest has not produced evidence for this case"
                        })
    return cases


def merge_records(cases, records):
    """Fail closed: incomplete, duplicate or inconsistent evidence cannot produce a pass."""
    indexed = {c["id"]: c for c in cases}
    seen = set()
    errors = []
    protected = ("approach", "journey", "variant", "checkpoint", "repetition", "expected", "final_expected", "requested_transition")
    for record in records:
        case_id = record.get("id")
        if case_id not in indexed:
            errors.append("Unexpected case attachment: " + str(case_id))
            continue
        case = indexed[case_id]
        if case_id in seen:
            case.update(status="execution_error", reason="Duplicate case evidence")
            errors.append("Duplicate evidence: " + case_id)
            continue
        seen.add(case_id)
        problem = None
        if any(record.get(k) != case[k] for k in protected):
            problem = "Evidence does not match planned case"
        elif record.get("status") not in STATUSES:
            problem = "Invalid case status"
        elif record["status"] in ("passed", "functional_failure"):
            if record.get("before") != case["expected"]:
                problem = "Preconditions are not proven"
            elif not isinstance(record.get("observed"), dict) or set(record["observed"]) != set(case["expected"]):
                problem = "Missing observed invariants"
            elif not isinstance(record.get("final_observed"), dict) or set(record["final_observed"]) != set(case["final_expected"]):
                problem = "Missing completion invariants"
            elif case["requested_transition"] == "rotate" and (
                record.get("actual_transitions") != ["rotate-portrait-to-landscape"] or
                not record.get("geometry_before") or not record.get("geometry_after") or
                record["geometry_before"] == record["geometry_after"]
            ):
                problem = "Window transition is not proven"
            elif case["requested_transition"] == "none" and record.get("actual_transitions") != []:
                problem = "Control unexpectedly performed a transition"
            elif (record["observed"] == case["expected"] and record["final_observed"] == case["final_expected"]) != (record["status"] == "passed"):
                problem = "Status contradicts observed invariants"
        if problem:
            case.update(status="execution_error", reason=problem)
            errors.append(case_id + ": " + problem)
        else:
            # Do not let evidence rewrite fixture ground truth or identity.
            for key in ("status", "reason", "before", "observed", "final_observed", "actual_transitions", "geometry_before",
                        "geometry_after", "duration_seconds", "reproduction", "attachments"):
                if key in record:
                    case[key] = record[key]
    return errors


def comparison(cases):
    full = bool(cases) and all(c["status"] in ("passed", "functional_failure") for c in cases)
    mismatches = [c["id"] for c in cases if c["status"] != c["expected_status"]]
    groups = {}
    for c in cases:
        groups.setdefault((c["journey"], c["variant"], c["checkpoint"], c["repetition"]), {})[c["approach"]] = c["status"]
    paired = bool(groups) and all(set(v) == {"generated", "explicit"} for v in groups.values())
    equivalent = full and paired and all(v["generated"] == v["explicit"] for v in groups.values())
    repeats = {}
    for c in cases:
        repeats.setdefault((c["approach"], c["journey"], c["variant"], c["checkpoint"]), []).append(c)
    failures = [v for v in repeats.values() if v[0]["expected_status"] == "functional_failure"]
    repeatable = bool(failures) and all(
        len(v) >= 3 and all(c["status"] == "functional_failure" for c in v) and
        len({json.dumps([c.get("observed"), c.get("final_observed")], sort_keys=True) for c in v}) == 1 for v in failures)
    reference_matrix = ({c["journey"] for c in cases} == JOURNEYS and
                        {c["variant"] for c in cases} == {"broken", "fixed"} and
                        {c["approach"] for c in cases} == {"generated", "explicit"} and
                        all(len(v) >= 3 for v in repeats.values()))
    return {
        "all_cases_executed": full, "matches_fixture_ground_truth": full and not mismatches,
        "full_reference_matrix": reference_matrix,
        "mismatched_case_ids": mismatches, "paired_approaches": paired,
        "equivalent_detection": equivalent, "failures_reproduced_at_least_three_times": repeatable,
        "false_failures": sum(c["expected_status"] == "passed" and c["status"] == "functional_failure" for c in cases),
        "preparation_savings_fraction": None, "human_preparation_time": "not_measured",
        "human_diagnosis_time": "not_measured", "technical_gate": "not_evaluated",
        "reason": "Execution timing is not human preparation timing. A timed independent benchmark is required."
    }


def evaluate_timings(result, measurements, source_sha256, journeys):
    """Import paired, human-recorded timings; never infer preparation effort from execution."""
    if measurements.get("schema_version") != 1 or measurements.get("source_sha256") != source_sha256:
        raise ValueError("Timing file must use schema 1 and match the measured source_sha256")
    if not measurements.get("observer") or not measurements.get("protocol"):
        raise ValueError("Timing file requires an observer and protocol reference")
    totals = {"generated": {"preparation": 0.0, "diagnosis": 0.0},
              "explicit": {"preparation": 0.0, "diagnosis": 0.0}}
    expected = {(j, a, t) for j in journeys for a in totals for t in ("preparation", "diagnosis")}
    seen = set()
    for row in measurements["measurements"]:
        key = (row["journey"], row["approach"], row["task"])
        seconds = row["seconds"]
        if key not in expected or key in seen or isinstance(seconds, bool) or not isinstance(seconds, (int, float)):
            raise ValueError("Timing rows must uniquely cover each journey, approach and task")
        if not math.isfinite(seconds) or seconds <= 0:
            raise ValueError("Timing seconds must be finite and positive")
        if not row.get("notes"):
            raise ValueError("Timing rows require notes including any assistance or retries")
        seen.add(key)
        totals[row["approach"]][row["task"]] += seconds
    if seen != expected:
        raise ValueError("Incomplete paired timing measurements")
    savings = 1 - totals["generated"]["preparation"] / totals["explicit"]["preparation"]
    result.update(preparation_savings_fraction=savings, human_preparation_time="self_reported",
                  human_diagnosis_time="self_reported", human_seconds=totals,
                  timing_observer=measurements["observer"], timing_protocol=measurements["protocol"])
    eligible = (result["full_reference_matrix"] and set(journeys) == JOURNEYS and result["matches_fixture_ground_truth"] and
                result["equivalent_detection"] and result["failures_reproduced_at_least_three_times"] and
                result["false_failures"] == 0)
    result["technical_gate"] = ("passed" if savings >= .5 else "stop") if eligible else "not_evaluated"
    result["reason"] = ("Paired human timings, self-reported; no claim of independent validation" if eligible
                        else "Detection, full demo coverage or three-run reproducibility requirements not met")


def exit_code(report):
    statuses = {c["status"] for c in report["cases"]}
    if report["execution_errors"] or "execution_error" in statuses:
        return 1
    if "not_executed" in statuses or not statuses:
        return 3
    if "functional_failure" in statuses:
        return 2
    return 0


def run_command(command, log=None, timeout=120):
    if log:
        with log.open("w") as stream:
            completed = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
        return completed.returncode, ""
    completed = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, timeout=timeout)
    if completed.returncode:
        raise RuntimeError("Command failed: " + " ".join(command) + "\n" + completed.stderr[-2000:])
    return completed.returncode, completed.stdout


def configure_tests(data, environment):
    count = 0
    # Xcode emits v1 for schemes without a test plan, v2 for test configurations.
    if "ContinuityUITests" in data:
        data["ContinuityUITests"].setdefault("EnvironmentVariables", {}).update(environment)
        count += 1
    for configuration in data.get("TestConfigurations", []):
        for target in configuration.get("TestTargets", []):
            if target.get("BlueprintName") == "ContinuityUITests":
                target.setdefault("EnvironmentVariables", {}).update(environment)
                count += 1
    if count != 1:
        raise ValueError("Expected exactly one ContinuityUITests target in xctestrun")


def collect_records(bundle, out):
    export = out / "attachments"
    run_command(["xcrun", "xcresulttool", "export", "attachments", "--path", str(bundle),
                 "--output-path", str(export)], timeout=120)
    records = []
    for path in export.iterdir():
        if not path.is_file() or path.name == "manifest.json":
            continue
        try:
            record = json.loads(path.read_text())
        except (UnicodeError, ValueError):
            continue
        if isinstance(record, dict) and record.get("record_type") == "foldready-continuity-case":
            record["attachments"] = [str(path.relative_to(out))]
            records.append(record)
    # The xcresult manifest retains the names of screenshots even when filenames are UUIDs.
    manifest = json.loads((export / "manifest.json").read_text())
    def walk(node):
        if isinstance(node, list):
            for child in node:
                yield from walk(child)
        elif isinstance(node, dict):
            yield node
            for child in node.values():
                yield from walk(child)
    for item in walk(manifest):
        name = item.get("suggestedHumanReadableName", "")
        filename = item.get("exportedFileName", "")
        for record in records:
            prefix = "evidence-" + record["id"].replace("/", "_")
            if name.startswith(prefix) and filename and (export / filename).is_file():
                record["attachments"].append(str((export / filename).relative_to(out)))
    return records


def write_report(report, out):
    report["comparison"] = comparison(report["cases"])
    if report.get("timing_measurements"):
        try:
            evaluate_timings(report["comparison"], report["timing_measurements"],
                             report["environment"].get("source_sha256"),
                             sorted({c["journey"] for c in report["cases"]}))
        except (ValueError, KeyError, TypeError) as error:
            report["execution_errors"].append("Invalid timing evidence: " + str(error))
    if report["execution_errors"]:
        report["comparison"]["technical_gate"] = "not_evaluated"
    report["counts"] = dict(Counter(c["status"] for c in report["cases"]))
    report["exit_code"] = exit_code(report)
    (out / "result.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    lines = ["# Continuity experiment", "", "Duo runtime verified: false", "",
             "Cases: " + json.dumps(report["counts"], sort_keys=True),
             "Technical gate: " + report["comparison"]["technical_gate"] + ". " + report["comparison"]["reason"], "",
             "| Case | Status | Detail |", "|---|---|---|"]
    for case in report["cases"]:
        lines.append("| " + " | ".join(str(case.get(k, "")).replace("|", "\\|").replace("\n", " ")
                                      for k in ("id", "status", "reason")) + " |")
    if report["execution_errors"]:
        lines += ["", "Execution errors:"] + ["- " + e for e in report["execution_errors"]]
    (out / "summary.md").write_text("\n".join(lines) + "\n")
    print("Cases:", report["counts"])
    print("Comparison:", json.dumps(report["comparison"], sort_keys=True))
    print("Report:", out / "result.json", flush=True)
    return report["exit_code"]


def main(argv=None):
    parser = Parser(description="Experimental local XCTest continuity comparison; demo protocol only.")
    parser.add_argument("project", type=Path, help="Path to continuity-demo.xcodeproj")
    parser.add_argument("--journeys", type=lambda v: selection(v, JOURNEYS), default=["form", "cart", "draft"])
    parser.add_argument("--variants", type=lambda v: selection(v, {"broken", "fixed"}), default=["broken", "fixed"])
    parser.add_argument("--approaches", type=lambda v: selection(v, {"generated", "explicit"}), default=["generated", "explicit"])
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument("--transition", choices=["rotate", "duo-fold"], default="rotate")
    parser.add_argument("--device", help="Available iOS simulator UDID; default: first available iPad")
    parser.add_argument("--timings", type=Path, help="Paired human measurements following docs/continuity-benchmark.md")
    parser.add_argument("--out", type=Path, default=Path(".build/continuity"), help="Parent for a unique run directory")
    args = parser.parse_args(argv)
    if not 1 <= args.repetitions <= 10:
        parser.error("--repetitions must be between 1 and 10")
    project = args.project.expanduser().resolve()
    if not (project / "project.pbxproj").is_file():
        parser.error("Project does not contain project.pbxproj")
    try:
        spec = load_spec(project)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    out = args.out.expanduser().resolve() / run_id
    out.mkdir(parents=True)
    report = {
        "schema_version": 1, "kind": "continuity-experiment", "run_id": run_id,
        "duo_runtime_verified": False, "environment": {"project": str(project),
            "runner_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}, "execution_errors": [],
        "cases": planned_cases(spec, args.journeys, args.variants, args.approaches, args.repetitions, args.transition)
    }
    if args.transition == "duo-fold":
        for case in report["cases"]:
            case["reason"] = "Duo folding automation is not implemented or verified; no scenarios executed"
        return write_report(report, out)
    start = time.monotonic()
    try:
        if args.timings:
            report["timing_measurements"] = json.loads(args.timings.expanduser().read_text())
        _, xcode = run_command(["xcodebuild", "-version"])
        _, sdk = run_command(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"])
        _, raw = run_command(["xcrun", "simctl", "list", "devices", "available", "--json"])
        devices = [(runtime, device) for runtime, entries in json.loads(raw)["devices"].items()
                   if ".iOS-" in runtime for device in entries if device.get("isAvailable")]
        chosen = next(((r, d) for r, d in devices if d["udid"] == args.device), None) if args.device else next(
            ((r, d) for r, d in devices if d["name"].startswith("iPad")), None)
        if not chosen:
            raise ValueError("No matching available iOS simulator; pass --device UDID")
        runtime, device = chosen
        report["environment"].update(xcode=xcode.strip(), sdk=sdk.strip(), simulator=device, runtime=runtime)
        digest = hashlib.sha256()
        inputs = sorted(list((project.parent / "App").glob("*.swift")) +
                        list((project.parent / "UITests").glob("*.swift")) +
                        list(project.rglob("*")) + [project.parent / "journeys.json"])
        for path in inputs:
            if path.is_file() and "xcuserdata" not in path.parts:
                digest.update(str(path.relative_to(project.parent)).encode())
                digest.update(path.read_bytes())
        report["environment"]["source_sha256"] = digest.hexdigest()
        derived = out / "build"
        print("Building XCTest demo on", device["name"], "Log:", out / "build.log", flush=True)
        code, _ = run_command(["xcodebuild", "build-for-testing", "-project", str(project),
                              "-scheme", "ContinuityDemo", "-destination", "id=" + device["udid"],
                              "-derivedDataPath", str(derived), "CODE_SIGNING_ALLOWED=NO"], out / "build.log", 600)
        if code:
            raise RuntimeError("Build failed; see build.log (exit " + str(code) + ")")
        built_info = derived / "Build/Products/Debug-iphonesimulator/ContinuityDemo.app/Info.plist"
        info = plistlib.loads(built_info.read_bytes())
        report["environment"]["build"] = {key: info.get(key) for key in (
            "CFBundleIdentifier", "CFBundleVersion", "DTSDKName", "DTXcodeBuild")}
        test_files = list((derived / "Build/Products").glob("*.xctestrun"))
        if len(test_files) != 1:
            raise ValueError("Expected a single built xctestrun")
        data = plistlib.loads(test_files[0].read_bytes())
        configure_tests(data, {"FR_SPEC": json.dumps(spec), "FR_JOURNEYS": ",".join(args.journeys),
                              "FR_VARIANTS": ",".join(args.variants), "FR_REPETITIONS": str(args.repetitions)})
        # Keep alongside the original so __TESTROOT__ resolves to the built products.
        configured = test_files[0].parent / "continuity-configured.xctestrun"
        configured.write_bytes(plistlib.dumps(data))
        bundle = out / "tests.xcresult"
        command = ["xcodebuild", "test-without-building", "-xctestrun", str(configured),
                   "-destination", "id=" + device["udid"], "-resultBundlePath", str(bundle),
                   "-parallel-testing-enabled", "NO", "-test-timeouts-enabled", "NO",
                   "-maximum-test-execution-time-allowance", "1800"]
        command += ["-only-testing:ContinuityUITests/" + a.title() + "Tests/testMatrix" for a in args.approaches]
        print("Running", len(report["cases"]), "cases. Log:", out / "test.log", flush=True)
        code, _ = run_command(command, out / "test.log", 3600)
        report["environment"]["xcodebuild_test_exit_code"] = code
        if code:
            report["execution_errors"].append("XCTest harness failed; see test.log (exit " + str(code) + ")")
        report["execution_errors"] += merge_records(report["cases"], collect_records(bundle, out))
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        report["execution_errors"].append(str(error))
    report["wall_seconds"] = time.monotonic() - start
    return write_report(report, out)


if __name__ == "__main__":
    sys.exit(main())

import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import sys

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("continuity_runner", ROOT / "Sources/foldready/Continuity/runner.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.spec = runner.load_spec(ROOT / "Examples/continuity-demo/continuity-demo.xcodeproj")
        self.cases = runner.planned_cases(self.spec, ["form", "cart", "draft"], ["broken", "fixed"],
                                          ["generated", "explicit"], 3, "rotate")

    def evidence(self, case):
        record = copy.deepcopy(case)
        record["status"] = case["expected_status"]
        record["before"] = copy.deepcopy(case["expected"])
        record["observed"] = copy.deepcopy(case["expected"])
        record["final_observed"] = copy.deepcopy(case["final_expected"])
        if record["status"] == "functional_failure":
            record["observed"][next(iter(record["observed"]))] = "injected defect"
        record["geometry_before"] = "Window: 100 x 200"
        record["geometry_after"] = "Window: 200 x 100"
        record["actual_transitions"] = [] if case["checkpoint"] == "control" else ["rotate-portrait-to-landscape"]
        return record

    def completed(self):
        records = [self.evidence(c) for c in self.cases]
        self.assertEqual(runner.merge_records(self.cases, records), [])
        return runner.comparison(self.cases)

    def test_full_matrix_and_ground_truth(self):
        self.assertEqual(len(self.cases), 108)
        result = self.completed()
        self.assertTrue(result["matches_fixture_ground_truth"])
        self.assertTrue(result["equivalent_detection"])
        self.assertTrue(result["failures_reproduced_at_least_three_times"])
        self.assertEqual(result["false_failures"], 0)
        self.assertEqual(result["technical_gate"], "not_evaluated")
        self.assertIsNone(result["preparation_savings_fraction"])

    def test_missing_evidence_is_not_a_pass(self):
        runner.merge_records(self.cases, [self.evidence(self.cases[0])])
        self.assertEqual(self.cases[1]["status"], "not_executed")
        self.assertFalse(runner.comparison(self.cases)["all_cases_executed"])

    def test_duplicate_evidence_is_execution_error(self):
        record = self.evidence(self.cases[0])
        self.assertTrue(runner.merge_records(self.cases, [record, record]))
        self.assertEqual(self.cases[0]["status"], "execution_error")

    def test_failed_precondition_is_not_functional_failure(self):
        record = self.evidence(self.cases[1])
        record["before"]["name"] = ""
        self.assertTrue(runner.merge_records(self.cases, [record]))
        self.assertEqual(self.cases[1]["status"], "execution_error")

    def test_rotation_requires_geometry_evidence(self):
        record = self.evidence(self.cases[1])
        record["geometry_after"] = record["geometry_before"]
        self.assertTrue(runner.merge_records(self.cases, [record]))
        self.assertEqual(self.cases[1]["status"], "execution_error")

    def test_result_cannot_claim_pass_with_wrong_values(self):
        record = self.evidence(self.cases[1])
        record["status"] = "passed"
        self.assertTrue(runner.merge_records(self.cases, [record]))

    def test_record_cannot_rewrite_expected_values(self):
        record = self.evidence(self.cases[1])
        record["expected"] = record["observed"]
        self.assertTrue(runner.merge_records(self.cases, [record]))

    def test_completion_only_failure_is_reported(self):
        record = self.evidence(self.cases[0])
        record["final_observed"]["name"] = "lost during completion"
        record["status"] = "functional_failure"
        self.assertEqual(runner.merge_records(self.cases, [record]), [])
        self.assertEqual(self.cases[0]["status"], "functional_failure")
        self.assertEqual(runner.comparison(self.cases)["false_failures"], 1)

    def test_missing_completion_evidence_cannot_pass(self):
        record = self.evidence(self.cases[0])
        del record["final_observed"]
        self.assertTrue(runner.merge_records(self.cases, [record]))

    def test_unknown_records_are_not_silently_ignored(self):
        self.assertTrue(runner.merge_records(self.cases, [{"id": "unknown"}]))

    def test_exit_codes(self):
        for status, expected in [("passed", 0), ("functional_failure", 2), ("execution_error", 1), ("not_executed", 3)]:
            self.assertEqual(runner.exit_code({"cases": [{"status": status}], "execution_errors": []}), expected)
        self.assertEqual(runner.exit_code({"cases": [{"status": "passed"}], "execution_errors": ["XCTest crash"]}), 1)

    def test_unavailable_duo_runs_no_commands_and_never_passes(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as tmp, patch.object(runner, "run_command") as command:
            code = runner.main([str(ROOT / "Examples/continuity-demo/continuity-demo.xcodeproj"),
                                "--transition", "duo-fold", "--out", tmp])
            command.assert_not_called()
            self.assertEqual(code, 3)
            report = json.loads(next(Path(tmp).glob("*/result.json")).read_text())
            self.assertFalse(report["duo_runtime_verified"])
            self.assertEqual(report["counts"], {"not_executed": 108})

    def measurements(self, generated=40):
        return {"schema_version": 1, "source_sha256": "abc", "observer": "test-fixture",
                "protocol": "test fixture, not a real measurement", "measurements": [
                    {"journey": j, "approach": a, "task": task,
                     "seconds": generated if a == "generated" else 100, "notes": "test fixture"}
                    for j in sorted(runner.JOURNEYS) for a in ("generated", "explicit")
                    for task in ("preparation", "diagnosis")]}

    def test_unfavorable_timings_are_preserved_and_stop_gate(self):
        result = self.completed()
        runner.evaluate_timings(result, self.measurements(120), "abc", sorted(runner.JOURNEYS))
        self.assertLess(result["preparation_savings_fraction"], 0)
        self.assertEqual(result["technical_gate"], "stop")

    def test_positive_gate_requires_matching_evidence(self):
        result = self.completed()
        runner.evaluate_timings(result, self.measurements(), "abc", sorted(runner.JOURNEYS))
        self.assertEqual(result["technical_gate"], "passed")
        result["equivalent_detection"] = False
        runner.evaluate_timings(result, self.measurements(), "abc", sorted(runner.JOURNEYS))
        self.assertEqual(result["technical_gate"], "not_evaluated")

    def test_invalid_timing_inputs_rejected(self):
        for value in (0, -1, float("nan"), True):
            with self.assertRaises(ValueError):
                runner.evaluate_timings(self.completed(), self.measurements(value), "abc", sorted(runner.JOURNEYS))
        with self.assertRaises(ValueError):
            runner.evaluate_timings(self.completed(), self.measurements(), "other-build", sorted(runner.JOURNEYS))

    def test_broken_only_matrix_cannot_pass_technical_gate(self):
        self.completed()
        result = runner.comparison([c for c in self.cases if c["variant"] == "broken"])
        runner.evaluate_timings(result, self.measurements(), "abc", sorted(runner.JOURNEYS))
        self.assertEqual(result["technical_gate"], "not_evaluated")

    def test_different_failures_are_not_reproducible(self):
        self.completed()
        self.cases[1]["observed"] = {"name": "a different fault", "details": ""}
        self.assertFalse(runner.comparison(self.cases)["failures_reproduced_at_least_three_times"])

    def test_argument_error_does_not_use_functional_failure_code(self):
        with self.assertRaises(SystemExit) as error:
            runner.main(["missing-project"])
        self.assertEqual(error.exception.code, 1)

    def test_xctestrun_formats(self):
        for data in ({"ContinuityUITests": {}}, {"TestConfigurations": [{"TestTargets": [{"BlueprintName": "ContinuityUITests"}]}]}):
            runner.configure_tests(data, {"FR_JOURNEYS": "cart"})
            self.assertIn("cart", str(data))
        with self.assertRaises(ValueError):
            runner.configure_tests({}, {})


if __name__ == "__main__":
    unittest.main()

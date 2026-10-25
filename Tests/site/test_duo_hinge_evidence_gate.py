"""Offline regression checks for hinge proof completeness and false-pass resistance.

Synthetic small PNG headers are used solely to test metadata validation. They
are NOT runtime screenshots and do not substitute for visual artifact review.
"""
from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "Scripts" / "validate_duo_hinge_evidence.py"
SPEC = importlib.util.spec_from_file_location("foldready_hinge_verifier", SCRIPT)
assert SPEC and SPEC.loader
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)


class HingeEvidenceGateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.records = [
            ("initial_closed", 0, 11, "Window: 466 x 678", "duo-before-closed.png", 1398, 2034),
            ("opened", 180, 44, "Window: 951 x 669", "duo-opened.png", 2852, 2006),
            ("reclosed", 0, 11, "Window: 466 x 678", "duo-reclosed.png", 1398, 2034),
        ]
        for _, _, _, _, name, width, height in self.records:
            # Not actual screenshots; metadata-only PNG test doubles.
            self.root.joinpath(name).write_bytes(
                checker.PNG_HEADER + struct.pack(">I", 13) + b"IHDR" +
                struct.pack(">II", width, height) + b"\x08\x06\x00\x00\x00" + b"\x00" * 1300
            )
        self.evidence = {
            "schema_version": 1,
            "status": "passed_synthetic_fold_unfold_continuity",
            "fold_unfold_transition": "passed_synthetic_simulator",
            "source_sha": "a" * 40,
            "recorded_utc": datetime.now(timezone.utc).isoformat(),
            "runtime": "iOS 27.1",
            "device": "iPhone Duo",
            "physical_device": "not_tested",
            "customer_app": "not_tested",
            "displays": [
                {"id": 44, "metrics": {"widthPixels": 2007, "heightPixels": 2853}},
                {"id": 11, "metrics": {"widthPixels": 1398, "heightPixels": 2034}},
            ],
            "before_after": [
                {"stage": stage, "requested_angle": angle,
                 "sensor_angle": angle, "selected_display": display,
                 "name": "Ada", "geometry": geometry, "evidence": file}
                for stage, angle, display, geometry, file, _, _ in self.records
            ]
        }
        self.save()

    def save(self):
        self.root.joinpath("hinge-evidence.json").write_text(json.dumps(self.evidence))

    def test_accepts_consistent_three_stage_synthetic_report(self):
        result = checker.validate(self.root)
        self.assertEqual(len(result["screenshots_sha256"]), 3)
        self.assertIn("simulator_only", result["limits"])

    def test_command_ack_cannot_replace_angle_readback(self):
        self.evidence["before_after"][1]["sensor_angle"] = 0
        self.save()
        with self.assertRaisesRegex(ValueError, "hinge readback"):
            checker.validate(self.root)

    def test_rejects_lost_form_state(self):
        self.evidence["before_after"][2]["name"] = ""
        self.save()
        with self.assertRaisesRegex(ValueError, "not preserved"):
            checker.validate(self.root)

    def test_rejects_wrong_active_display(self):
        self.evidence["before_after"][1]["selected_display"] = 11
        self.save()
        with self.assertRaisesRegex(ValueError, "Wrong display"):
            checker.validate(self.root)

    def test_rejects_no_geometry_change(self):
        self.evidence["before_after"][1]["geometry"] = "Window: 466 x 678"
        self.save()
        with self.assertRaisesRegex(ValueError, "never actually changed"):
            checker.validate(self.root)

    def test_rejects_missing_or_mismatched_screenshot(self):
        self.root.joinpath("duo-opened.png").unlink()
        with self.assertRaisesRegex(ValueError, "Missing evidence"):
            checker.validate(self.root)
        self.root.joinpath("duo-opened.png").write_bytes(
            checker.PNG_HEADER + struct.pack(">I", 13) + b"IHDR" +
            struct.pack(">II", 1398, 2034) + b"\x08\x06\x00\x00\x00" + b"\x00" * 1300
        )
        with self.assertRaisesRegex(ValueError, "resolution"):
            checker.validate(self.root)

    def test_rejects_false_hardware_claims(self):
        self.evidence["physical_device"] = "passed"
        self.save()
        with self.assertRaisesRegex(ValueError, "extrapolate"):
            checker.validate(self.root)

    def test_rejects_status_on_failed_execution(self):
        self.evidence["status"] = "execution_error"
        self.save()
        with self.assertRaisesRegex(ValueError, "not completed"):
            checker.validate(self.root)


if __name__ == "__main__":
    unittest.main()

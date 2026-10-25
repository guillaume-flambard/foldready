"""Offline contract tests for iPhone Duo list-selection hinge evidence."""
from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[2] / "Scripts"
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("foldready_list_evidence", SCRIPTS / "validate_duo_list_evidence.py")
assert spec and spec.loader
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)
from validate_duo_hinge_evidence import PNG_HEADER


class ListHingeReportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.rows = [
            {"stage": "initial_closed", "requested_angle": 0, "sensor_angle": 0,
             "selected_display": 12, "selection": "Item 70", "scroll_offset": 2720,
             "geometry": "Window: 466 x 678", "evidence": "duo-list-initial_closed.png"},
            {"stage": "opened", "requested_angle": 180, "sensor_angle": 180,
             "selected_display": 33, "selection": "Item 70", "scroll_offset": 2300,
             "geometry": "Window: 951 x 669", "evidence": "duo-list-opened.png"},
            {"stage": "reclosed", "requested_angle": 0, "sensor_angle": 0,
             "selected_display": 12, "selection": "Item 70", "scroll_offset": 2600,
             "geometry": "Window: 466 x 678", "evidence": "duo-list-reclosed.png"},
        ]
        dims = [(1398, 2034), (2852, 2006), (1398, 2034)]
        for row, (w, h) in zip(self.rows, dims):
            self.root.joinpath(row["evidence"]).write_bytes(
                PNG_HEADER + struct.pack(">I", 13) + b"IHDR" + struct.pack(">II", w, h)
                + b"\x08\x06\x00\x00\x00" + b"\x00" * 1300
            )
        self.document = {
            "status": "passed_synthetic_list_hinge_continuity",
            "journey": "synthetic_uitableview_selection",
            "device": "iPhone Duo", "runtime": "iOS 27.1",
            "source_sha": "a" * 40,
            "recorded_utc": datetime.now(timezone.utc).isoformat(),
            "fold_unfold_transition": "passed_synthetic_simulator",
            "physical_device": "not_tested",
            "customer_app": "not_tested",
            "displays": [
                {"id": 12, "metrics": {"widthPixels": 1398, "heightPixels": 2034}},
                {"id": 33, "metrics": {"widthPixels": 2007, "heightPixels": 2853}},
            ],
            "before_after": self.rows,
        }
        self.save()

    def save(self):
        (self.root / "list-evidence.json").write_text(json.dumps(self.document))

    def test_valid_bundle_passes(self):
        report = validator.validate(self.root)
        self.assertEqual(len(report["screenshots_sha256"]), 3)

    def test_rejects_no_observed_hinge_angle(self):
        self.rows[1]["sensor_angle"] = 0
        self.save()
        with self.assertRaisesRegex(ValueError, "read back"):
            validator.validate(self.root)

    def test_rejects_selection_loss(self):
        self.rows[2]["selection"] = "none"
        self.save()
        with self.assertRaisesRegex(ValueError, "Lost selected"):
            validator.validate(self.root)

    def test_rejects_non_scrolled_list(self):
        self.rows[1]["scroll_offset"] = 0
        self.save()
        with self.assertRaisesRegex(ValueError, "not actually scrolled"):
            validator.validate(self.root)

    def test_rejects_static_window(self):
        self.rows[1]["geometry"] = self.rows[0]["geometry"]
        self.save()
        with self.assertRaisesRegex(ValueError, "did not resize"):
            validator.validate(self.root)

    def test_rejects_missing_screenshot(self):
        (self.root / "duo-list-opened.png").unlink()
        with self.assertRaisesRegex(ValueError, "Missing"):
            validator.validate(self.root)

    def test_rejects_false_customer_or_hardware_result(self):
        self.document["customer_app"] = "passed"
        self.save()
        with self.assertRaisesRegex(ValueError, "customer/hardware"):
            validator.validate(self.root)


if __name__ == "__main__":
    unittest.main()

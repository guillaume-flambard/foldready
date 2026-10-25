"""Offline unit coverage for the evidence-gated Duo Appium probe.

No Appium, device, simulator or network is required.
"""
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

PROBE = Path(__file__).resolve().parents[2] / "Scripts" / "probe_duo_hinge.py"


class HingeProbeOfflineTests(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory()
        self.addCleanup(self.workspace.cleanup)
        with patch.dict(os.environ, {
            "DUO_PROOF_DIR": self.workspace.name,
            "DUO_UDID": "synthetic-no-device",
            "DUO_APP_PATH": "/not-an-app",
        }):
            spec = importlib.util.spec_from_file_location("foldready_hinge_probe_tested", PROBE)
            assert spec and spec.loader
            self.probe = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(self.probe)

    def test_resolves_displays_by_native_pixel_area_not_hardcoded_ids(self):
        sample = [
            {"id": 91, "metrics": {"widthPixels": 2007, "heightPixels": 2853}},
            {"id": 33, "metrics": {"widthPixels": 1398, "heightPixels": 2034}},
        ]
        with patch.object(self.probe, "execute", return_value=sample):
            cover, inner, recorded = self.probe.displays()
        self.assertEqual((cover, inner), (33, 91))
        self.assertEqual(recorded, sample)

    def test_refuses_single_or_unidentified_display(self):
        with patch.object(self.probe, "execute", return_value=[
            {"id": 1, "metrics": {"widthPixels": 1398, "heightPixels": 2034}}
        ]):
            with self.assertRaises(AssertionError):
                self.probe.displays()
        with patch.object(self.probe, "execute", return_value=[
            {"id": 1, "metrics": {}}, {"id": 3, "metrics": {}}
        ]):
            with self.assertRaises(AssertionError):
                self.probe.displays()

    def test_no_hinge_pass_from_command_ack_without_sensor_readback(self):
        with patch.object(self.probe, "execute", return_value=None), \
             patch.object(self.probe, "angle", side_effect=[0, 45, 90, 180]), \
             patch.object(self.probe.time, "sleep"):
            self.assertEqual(self.probe.set_angle(180), 180.0)

    def test_rejects_invalid_sensor_result(self):
        with patch.object(self.probe, "execute", return_value=True):
            with self.assertRaises(RuntimeError):
                self.probe.angle()

    def test_w3c_error_reply_fails_closed(self):
        response = io.BytesIO(json.dumps({
            "value": {"error": "session not created", "message": "WDA unavailable"}
        }).encode())
        with patch.object(self.probe, "urlopen", return_value=response):
            with self.assertRaises(RuntimeError):
                self.probe.request("POST", "/session", {"capabilities": {}})

    def test_stage_records_state_only_after_actual_readback_and_capture(self):
        with patch.object(self.probe, "set_angle", return_value=180), \
             patch.object(self.probe, "select_display") as selector, \
             patch.object(self.probe, "state", return_value=("Ada", "Window: 700 x 1100")), \
             patch.object(self.probe, "save_screen") as screenshot:
            result = self.probe.stage("opened", 180, 99)
        self.assertEqual(result["sensor_angle"], 180)
        self.assertEqual(result["name"], "Ada")
        self.assertEqual(result["geometry"], "Window: 700 x 1100")
        selector.assert_called_once_with(99)
        screenshot.assert_called_once_with("duo-opened.png")
        self.assertEqual(self.probe.record["before_after"], [result])


if __name__ == "__main__":
    unittest.main()

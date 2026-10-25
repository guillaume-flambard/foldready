"""Offline tests for the public FoldReady host's evidence-aware smoke checker."""
from __future__ import annotations

import importlib.util
from pathlib import Path
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "Scripts" / "check-public-site.py"
SPEC = importlib.util.spec_from_file_location("foldready_site_smoke", SCRIPT)
assert SPEC and SPEC.loader
site = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(site)


class SiteSmokeTests(unittest.TestCase):
    def test_current_headline_example_and_stylesheet(self):
        page = """<html><head><link rel="stylesheet" href="/_next/static/css/test.css"></head>
        <body><h1>Know what breaks when your iPhone app resizes.</h1>
        <h2>Fewer false alarms. Clearer decisions.</h2></body></html>"""
        document, problems = site.inspect_home(page)
        self.assertEqual(problems, [])
        self.assertEqual(document.stylesheets, ["/_next/static/css/test.css"])

    def test_historical_site_is_rejected(self):
        page = "<h1>Find resize risks before your users do.</h1>"
        _, problems = site.inspect_home(page)
        self.assertTrue(any("expected H1" in msg for msg in problems))

    def test_unquoted_runtime_validation_is_not_mistaken_for_published_offer(self):
        page = """<select><option>Human source review — $349</option>
        <option>Discuss Duo runtime testing or fixes — quote</option></select>"""
        self.assertEqual(site.inspect_request_page(page), [])

    def test_missing_source_review_or_runtime_scope_is_rejected(self):
        page = "<select><option>Compatibility certified — $349</option></select>"
        self.assertEqual(len(site.inspect_request_page(page)), 2)


if __name__ == "__main__":
    unittest.main()

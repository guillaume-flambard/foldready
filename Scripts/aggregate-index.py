#!/usr/bin/env python3
"""Aggregate foldready result.json files into web/data.js for the Fold-Ready Index."""
import json
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
DATA = BASE / "web" / "data.js"
REPORTS = BASE / "web" / "reports"

apps = []
for rdir in sorted(REPORTS.iterdir()):
    rj = rdir / "result.json"
    if not rj.exists():
        continue
    data = json.loads(rj.read_text())
    checks = {c["key"]: c["score"] for c in data["checks"]}
    top = [f for f in data["findings"] if f["severity"] in ("critical", "major")]
    apps.append({
        "name": data["app"],
        "score": data["score"],
        "grade": data["grade"],
        "risk": data["risk"],
        "hours": data["estimatedPortingHours"],
        "swiftFiles": data["stats"]["swiftFiles"],
        "checks": checks,
        "findings": len(top),
        "report": f"reports/{data['app']}/foldready-report.html",
    })

apps.sort(key=lambda a: (-a["score"], a["name"]))
DATA.write_text("window.FOLDREADY_APPS = " + json.dumps(apps, indent=2) + ";\n")
print(f"wrote {len(apps)} apps to {DATA}")

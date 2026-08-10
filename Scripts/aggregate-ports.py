#!/usr/bin/env python3
"""Aggregate web/public/ports/*/porting-report.json into web/lib/ports-data.json."""
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
PUB = BASE / "web" / "public" / "ports"
OUT = BASE / "web" / "lib" / "ports-data.json"

data = {}
for pdir in sorted(PUB.iterdir()):
    rj = pdir / "porting-report.json"
    if not rj.exists():
        continue
    rep = json.loads(rj.read_text())
    data[pdir.name] = {
        "app": rep.get("app", pdir.name),
        "hasPatch": (pdir / "port.patch").exists(),
        "transforms": [
            {"id": t["id"], "title": t["title"], "tier": t["tier"],
             "files": t["files"], "edits": t["edits"], "newFiles": t["newFiles"],
             "hasPatch": (pdir / "patches" / f"{t['id']}.patch").exists()}
            for t in rep.get("patches", [])
        ],
    }

OUT.write_text(json.dumps(data, indent=2) + "\n")
print(f"wrote {len(data)} port plans to {OUT}")

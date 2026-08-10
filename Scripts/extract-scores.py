#!/usr/bin/env python3
"""Extract the re-audited scores from the demo apps' result.json and print TS rows."""
import json

REPOS = {
    "icecubesapp": "/var/folders/p3/1nb2tr357hs_8vc786h_thnw0000gn/T/opencode/IceCubesApp",
    "movieswiftui": "/var/folders/p3/1nb2tr357hs_8vc786h_thnw0000gn/T/opencode/fr-index/MovieSwiftUI",
    "mochidiffusion": "/var/folders/p3/1nb2tr357hs_8vc786h_thnw0000gn/T/opencode/fr-index/MochiDiffusion",
    "isowords": "/var/folders/p3/1nb2tr357hs_8vc786h_thnw0000gn/T/opencode/fr-index/isowords",
    "dime": "/var/folders/p3/1nb2tr357hs_8vc786h_thnw0000gn/T/opencode/fr-index/Dime",
    "openfoodfacts": "/var/folders/p3/1nb2tr357hs_8vc786h_thnw0000gn/T/opencode/fr-index/openfoodfacts-ios",
}
NAMES = {
    "icecubesapp": "IceCubesApp",
    "movieswiftui": "MovieSwiftUI",
    "mochidiffusion": "MochiDiffusion",
    "isowords": "isowords",
    "dime": "Dime",
    "openfoodfacts": "Open Food Facts",
}
KEYMAP = {
    "adaptive": "adaptive-layout",
    "parallel": "full-screen",
    "nav": "navigation",
    "scene": "scene",
    "fold": "fold-state",
    "state": "state",
    "framework": "framework",
}

for slug, repo in REPOS.items():
    d = json.load(open(repo + "/foldready-report/result.json"))
    c = {k["key"]: int(k["score"]) for k in d["checks"]}
    checks = ", ".join(f"{k}: {c.get(KEYMAP[k], 0)}" for k in KEYMAP)
    findings = len([f for f in d["findings"] if f["severity"] in ("critical", "major")])
    print(f'{NAMES[slug]}|{slug}|{d["score"]}|{d["grade"]}|{d["risk"]}|{d["estimatedPortingHours"]}|{d["stats"]["swiftFiles"]}|{findings}|{checks}')

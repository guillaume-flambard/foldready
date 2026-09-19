#!/usr/bin/env python3
"""Generate web/lib/index-data.ts from FoldReady result files.

The published index used to be hand-edited, which is how it ended up carrying two wrong
repository attributions and scores from a superseded contract. The facts now come from
audits: run the CLI over the corpus, point this script at the results, commit the diff.

    foldready <repo> --name <slug> --json --out out-<slug>
    Scripts/generate-index.py out-*/result.json

Prose (summaries, roadmaps) stays in web/lib/data.ts and is derived from these facts.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "web" / "lib" / "index-data.ts"

# The editorial part: which apps are in the index, and how they are named and linked.
CATALOG = {
    "icecubesapp": ("IceCubesApp", "Dimillian/IceCubesApp"),
    "isowords": ("isowords", "pointfreeco/isowords"),
    "mochidiffusion": ("MochiDiffusion", "MochiDiffusion/MochiDiffusion"),
    "movieswiftui": ("MovieSwiftUI", "Dimillian/MovieSwiftUI"),
    "dime": ("Dime", "rarfell/dimeApp"),
    "openfoodfacts": ("Open Food Facts", "openfoodfacts/openfoodfacts-ios"),
    "wordpress": ("WordPress", "wordpress-mobile/WordPress-iOS"),
    "signal": ("Signal", "signalapp/Signal-iOS"),
    "duckduckgo": ("DuckDuckGo", "duckduckgo/iOS"),
    "firefox": ("Firefox", "mozilla-mobile/firefox-ios"),
    "homeassistant": ("Home Assistant", "home-assistant/iOS"),
    "bitwarden": ("Bitwarden", "bitwarden/ios"),
    "kickstarter": ("Kickstarter", "kickstarter/ios-oss"),
    "eigen": ("Artsy Eigen", "artsy/eigen"),
    "wikipedia": ("Wikipedia", "wikimedia/wikipedia-ios"),
    "nextcloud": ("Nextcloud", "nextcloud/ios"),
    "element": ("Element", "element-hq/element-ios"),
    "deltachat": ("Delta Chat", "deltachat/deltachat-ios"),
    "netnewswire": ("NetNewsWire", "Ranchero-Software/NetNewsWire"),
    "openfind": ("OpenFind", "aheze/OpenFind"),
}

CHECK_ALIAS = {
    "adaptive-layout": "layout",
    "adaptive-geometry": "geometry",
    "navigation": "nav",
    "state": "state",
    "idiom": "idiom",
    "orientation": "orientation",
}

# Reasons a check can be absent from the audit. They are carried through to the
# page so a missing check reads as "not applicable", never as a silent zero.
NOT_APPLICABLE = {
    "idiom": "Not applicable: no UI file branches on the device idiom.",
    "orientation": "Not applicable: no orientation plist and no orientation branch to measure.",
}

SUPPORTED_SCHEMA = 5
MAX_FINDINGS = 14


def ts(value) -> str:
    return json.dumps(value, ensure_ascii=False)


def main(paths) -> int:
    apps = []
    for path in paths:
        data = json.loads(pathlib.Path(path).read_text())
        if data.get("schema_version") != SUPPORTED_SCHEMA:
            print(f"{path}: contract v{data.get('schema_version')}, expected "
                  f"v{SUPPORTED_SCHEMA}", file=sys.stderr)
            return 1
        slug = data["app"]
        if slug not in CATALOG:
            print(f"{path}: '{slug}' is not in the catalog, skipping", file=sys.stderr)
            continue
        name, repo = CATALOG[slug]

        checks = {}
        details = {}
        for check in data["checks"]:
            alias = CHECK_ALIAS.get(check["key"])
            if not alias:
                continue
            checks[alias] = round(check["score"])
            details[alias] = check["detail"]

        # A check the audit could not measure (no orientation plist and no
        # orientation branch, say) is reported as not applicable at 100 rather
        # than omitted, so the page never renders an unknown number as a zero.
        for alias in CHECK_ALIAS.values():
            if alias not in checks:
                checks[alias] = 100
                details[alias] = NOT_APPLICABLE[alias]

        findings = [
            {
                "severity": f["severity"],
                "check": f["check"],
                "message": f["message"],
                "file": f.get("file", "app-wide") + (f":{f['line']}" if f.get("line") else ""),
            }
            for f in data["findings"][:MAX_FINDINGS]
        ]

        apps.append({
            "name": name,
            "slug": slug,
            "repo": repo,
            "score": round(data["score"]),
            "grade": data["grade"],
            "risk": data["risk"],
            "hours": data["estimated_porting_hours"],
            "uiFiles": data["stats"]["ui_files"],
            "excludedFiles": data["stats"]["excluded_files"],
            "findingCount": len(data["findings"]),
            "provisional": data.get("score_is_provisional", False),
            "blockers": [
                {"id": b["id"], "title": b["title"], "consequence": b["consequence"],
                 "reference": b["reference"], "stopsLaunch": b["stops_launch"],
                 **({"file": b["file"]} if b.get("file") else {})}
                for b in data.get("blockers", [])
            ],
            "checks": checks,
            "details": details,
            "findings": findings,
        })

    apps.sort(key=lambda a: (-a["score"], a["name"]))

    body = ",\n".join("  " + ts(a) for a in apps)
    OUT.write_text(
        "// GENERATED by Scripts/generate-index.py from FoldReady result files.\n"
        "// Do not edit by hand: re-run the audits and regenerate.\n"
        f"// Contract v{SUPPORTED_SCHEMA}.\n\n"
        "import type { AppScore } from \"./data\";\n\n"
        f"export const INDEX_APPS: AppScore[] = [\n{body},\n];\n")
    print(f"wrote {len(apps)} apps to {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))

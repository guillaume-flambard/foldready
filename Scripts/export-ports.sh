#!/usr/bin/env bash
# export-ports.sh — generate downloadable port patches for the demo apps.
#
#   ./Scripts/export-ports.sh <repo>[:<slug>] [<repo>[:<slug>] ...]
#
# Runs `foldready port` (dry run, all tiers) per repo and copies the patch +
# report into web/public/ports/<slug>/ and regenerates web/lib/ports-data.json.
set -euo pipefail

BIN="$(cd "$(dirname "$0")/.." && pwd)/.build/debug/foldready"
WEB="$(cd "$(dirname "$0")/.." && pwd)/web"
PUB="$WEB/public/ports"

[[ -x "$BIN" ]] || { echo "build foldready first: swift build" >&2; exit 1; }
mkdir -p "$PUB"

for spec in "$@"; do
  repo="${spec%%:*}"
  slug="${spec##*:}"
  if [[ "$repo" == "$spec" ]]; then slug="$(basename "$repo" | tr '[:upper:]' '[:lower:]')"; fi
  name="$(basename "$repo")"
  staging="$(mktemp -d)"
  "$BIN" port "$repo" --name "$name" --tiers srm --json --out "$staging" >/dev/null 2>&1 || true
  if [[ -f "$staging/porting-report.json" ]]; then
    rm -rf "$PUB/$slug"
    mkdir -p "$PUB/$slug"
    [[ -f "$staging/porting-report.md" ]] && cp "$staging/porting-report.md" "$PUB/$slug/"
    cp "$staging/porting-report.json" "$PUB/$slug/"
    [[ -f "$staging/port.patch" ]] && cp "$staging/port.patch" "$PUB/$slug/"
    echo "exported $slug ($name)"
  else
    echo "no port plan for $repo"
  fi
  rm -rf "$staging"
done

python3 "$(dirname "$0")/aggregate-ports.py"
echo "ports -> $PUB"

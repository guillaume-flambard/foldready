#!/usr/bin/env bash
# build-index.sh — re-audit the demo apps and rebuild the public Fold-Ready Index.
#
#   ./Scripts/build-index.sh <repo1> [<repo2> ...]
#
# Each <repo> must be an iOS source tree. The index page lives in web/.
set -euo pipefail

BIN="$(cd "$(dirname "$0")/.." && pwd)/.build/debug/foldready"
WEB="$(cd "$(dirname "$0")/.." && pwd)/web-legacy"
REPORTS="$WEB/reports"
BRAND="$REPORTS/_brand"

if [[ $# -lt 1 ]]; then
  echo "usage: build-index.sh <repo1> [<repo2> ...]" >&2
  exit 1
fi
[[ -x "$BIN" ]] || { echo "build foldready first: swift build" >&2; exit 1; }
rm -rf "$REPORTS"
mkdir -p "$BRAND"
if [[ ! -f "$BRAND/logo-64.png" ]]; then
  rsvg-convert -w 64 -h 64 -o "$BRAND/logo-64.png" "$(cd "$(dirname "$0")/.." && pwd)/brand/logo.svg" 2>/dev/null \
    || cp "$(cd "$(dirname "$0")/.." && pwd)/brand/logo.svg" "$BRAND/logo-64.png"
fi

for repo in "$@"; do
  name=$(basename "$repo")
  echo "=== $name ==="
  "$BIN" "$repo" --name "$name" --json >/dev/null
  if [[ -d "$repo/foldready-report" ]]; then
    cp -R "$repo/foldready-report" "$REPORTS/$name"
  fi
done

python3 "$(dirname "$0")/aggregate-index.py"
echo "index rebuilt -> $WEB/index.html"

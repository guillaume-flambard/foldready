#!/usr/bin/env bash
# build-index.sh — re-audit the corpus and rebuild the published index.
#
#   ./Scripts/build-index.sh <repo1> [<repo2> ...]
#
# Each <repo> must be an iOS source tree whose directory name is the index slug
# (see CATALOG in generate-index.py). Reports are written OUTSIDE the audited
# trees, into a scratch directory, and then generate-index.py turns them into
# web/lib/index-data.ts. The results are kept so a future rebalance can be
# re-derived without re-cloning the corpus.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.build/debug/foldready"
OUT="${FOLDREADY_INDEX_OUT:-$ROOT/.build/index-out}"

if [[ $# -lt 1 ]]; then
  echo "usage: build-index.sh <repo1> [<repo2> ...]" >&2
  exit 1
fi
[[ -x "$BIN" ]] || { echo "build foldready first: swift build" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT"

for repo in "$@"; do
  name=$(basename "$repo")
  echo "=== $name ==="
  "$BIN" "$repo" --name "$name" --json --out "$OUT/$name" >/dev/null
done

python3 "$ROOT/Scripts/generate-index.py" "$OUT"/*/result.json
echo "index rebuilt from $(ls -d "$OUT"/*/ | wc -l | tr -d ' ') audits -> web/lib/index-data.ts"

#!/usr/bin/env bash
# check.sh — fast local verification: Swift build + tests, then the web build.
# Run before committing. Exits non-zero on any failure.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> swift build"
swift build
echo "==> swift test"
swift test

if [[ -d web ]]; then
  echo "==> web build (next)"
  (cd web && npx next build >/tmp/foldready-web-build.log 2>&1) \
    || { tail -20 /tmp/foldready-web-build.log; echo "web build FAILED" >&2; exit 1; }
fi

echo "==> all checks passed"

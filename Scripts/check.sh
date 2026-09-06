#!/usr/bin/env bash
# check.sh — fast local verification: Swift build + tests, the contract guards, then the
# web build. Run before committing. Exits non-zero on any failure.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> swift build"
swift build
echo "==> swift test"
swift test

# Every scored check must cite an Apple source (openspec/specs/evidence/sourcing).
# The runtime test asserts the emitted references; this catches a new check at the source,
# before anyone runs it.
echo "==> sourcing (every check cites Apple)"
python3 Scripts/sourcing-check.py

# The result JSON is a public contract (docs/result-contract.md): drift must be deliberate.
echo "==> result contract (golden)"
python3 Scripts/contract-golden.py

# A regenerated golden without a contract-document change is the mistake this catches.
if git rev-parse --git-dir >/dev/null 2>&1; then
  changed=$(git diff --name-only HEAD -- Tests/Fixtures/contract-golden.json)
  doc=$(git diff --name-only HEAD -- docs/result-contract.md)
  if [[ -n "$changed" && -z "$doc" ]]; then
    echo "contract-golden.json changed but docs/result-contract.md did not." >&2
    echo "Document the change (and bump schema_version if a field or a score moved)." >&2
    exit 1
  fi
fi

if [[ -d web ]]; then
  echo "==> web build (next)"
  (cd web && npx next build >/tmp/foldready-web-build.log 2>&1) \
    || { tail -20 /tmp/foldready-web-build.log; echo "web build FAILED" >&2; exit 1; }
fi

echo "==> all checks passed"

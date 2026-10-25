#!/usr/bin/env bash
# Retry *only* transient Next.js Google-font build failures for GitHub Pages.
# Preserve actual compile failures and never change production typography.
set -euo pipefail

attempts=3
delay="${FOLDREADY_FONT_RETRY_SLEEP_SECONDS:-5}"
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

for attempt in $(seq 1 "$attempts"); do
  echo "==> Next.js Pages build ($attempt/$attempts)"
  set +e
  npm run build 2>&1 | tee "$log"
  exit_code=${PIPESTATUS[0]}
  set -e

  if [[ "$exit_code" -eq 0 ]]; then
    echo "==> Pages build succeeded on attempt $attempt"
    exit 0
  fi

  # Fail immediately on TypeScript, webpack, import, dependency, or other
  # non-font errors. The last attempt always returns the original exit code.
  if ! grep -Eq 'next/font|nextFontGoogleFontLoader|fonts\.googleapis\.com|Failed to fetch.*font' "$log"; then
    echo "Pages build failed for a non-font reason; not retrying." >&2
    exit "$exit_code"
  fi

  if [[ "$attempt" -eq "$attempts" ]]; then
    echo "Pages build still fails after $attempts font-only attempts." >&2
    exit "$exit_code"
  fi
  echo "Transient Google font loader error; retrying after ${delay}s." >&2
  sleep "$delay"
done

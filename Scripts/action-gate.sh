#!/usr/bin/env bash
# action-gate.sh — the body of the FoldReady GitHub Action.
#
# Audits the head, measures the base on a pull request, evaluates the policy, and reports
# the verdict where the decision is made: the pull request, the job summary, and the exit
# code. Everything it runs is either the pinned FoldReady binary or a tool preinstalled on
# the runner; nothing is fetched.
set -uo pipefail

BIN="${FOLDREADY_BIN:?FOLDREADY_BIN not set}"
TARGET="${INPUT_PATH:-.}"
NAME="${INPUT_NAME:-}"
FAIL_ON_BREACH="${INPUT_FAIL_ON_BREACH:-true}"
COMMENT_ON_PR="${INPUT_COMMENT_ON_PR:-true}"

WORK="$(mktemp -d)"
OUT="$WORK/head"
mkdir -p "$OUT"

args=("gate" "$TARGET" "--out" "$OUT" "--json")
[[ -n "$NAME" ]] && args+=("--name" "$NAME")
[[ -n "${INPUT_CONFIG:-}" ]] && args+=("--config" "$INPUT_CONFIG")
[[ -n "${INPUT_BASELINE:-}" ]] && args+=("--baseline" "$INPUT_BASELINE")

# The gate prints its human summary, then the JSON payload. Keep both: the log is for the
# person reading the failed job, the JSON is for everything downstream.
set -o pipefail
"$BIN" "${args[@]}" > "$WORK/gate.out" 2>"$WORK/gate.err"
GATE_EXIT=$?
cat "$WORK/gate.out"
cat "$WORK/gate.err" >&2

if [[ $GATE_EXIT -eq 1 ]]; then
  echo "::error::FoldReady could not run (malformed config or baseline, or unreadable path)."
  exit 1
fi

# Split the JSON payload (it starts at the first line that is exactly "{").
JSON="$WORK/result.json"
awk 'f{print} /^\{$/{if(!f){f=1; print}}' "$WORK/gate.out" > "$JSON"

read_json() {
  python3 -c "import json,sys;d=json.load(open('$JSON'));print(${1})" 2>/dev/null || echo ""
}

SCORE="$(read_json "d['score']")"
GRADE="$(read_json "d['grade']")"
PASSED="$(read_json "str(d.get('gate',{}).get('passed',True)).lower()")"
REPORT="$OUT/foldready-report.html"

{
  echo "score=$SCORE"
  echo "grade=$GRADE"
  echo "passed=$PASSED"
  [[ -f "$REPORT" ]] && echo "report-path=$REPORT"
} >> "$GITHUB_OUTPUT"

# --- Pull request delta -----------------------------------------------------------
# Audit the base commit in a detached worktree. Best effort: a shallow clone or a missing
# base is a reason to skip the delta, never a reason to fail the job.
BASE_SCORE=""
DELTA=""
if [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  BASE_SHA="$(python3 -c "import json,os;print(json.load(open(os.environ['GITHUB_EVENT_PATH']))['pull_request']['base']['sha'])" 2>/dev/null || echo "")"
  if [[ -n "$BASE_SHA" ]] && git -C "$GITHUB_WORKSPACE" cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
    BASE_TREE="$WORK/base"
    if git -C "$GITHUB_WORKSPACE" worktree add --detach "$BASE_TREE" "$BASE_SHA" >/dev/null 2>&1; then
      BASE_OUT="$WORK/base-report"
      base_args=("$BASE_TREE/$TARGET" "--out" "$BASE_OUT" "--json")
      [[ -n "$NAME" ]] && base_args+=("--name" "$NAME")
      if "$BIN" "${base_args[@]}" >/dev/null 2>&1 && [[ -f "$BASE_OUT/result.json" ]]; then
        BASE_SCORE="$(python3 -c "import json;print(json.load(open('$BASE_OUT/result.json'))['score'])")"
        DELTA="$(python3 -c "print(round($SCORE - $BASE_SCORE, 1))")"
      elif [[ ! -d "$BASE_TREE/$TARGET" ]]; then
        echo "note: '$TARGET' does not exist on the base commit — no delta to report."
      else
        echo "note: the base commit could not be audited — reporting the head score only."
      fi
      git -C "$GITHUB_WORKSPACE" worktree remove --force "$BASE_TREE" >/dev/null 2>&1
    else
      echo "note: could not check out the base commit (shallow clone?) — skipping the delta."
      echo "      add 'fetch-depth: 0' to actions/checkout to get a score delta."
    fi
  fi
fi

{
  [[ -n "$BASE_SCORE" ]] && echo "base-score=$BASE_SCORE"
  [[ -n "$DELTA" ]] && echo "delta=$DELTA"
} >> "$GITHUB_OUTPUT"

# --- Reporting --------------------------------------------------------------------
summary() {
  echo "### FoldReady — ${NAME:-$TARGET}"
  echo
  if [[ -n "$DELTA" ]]; then
    direction="no change"
    python3 -c "import sys; sys.exit(0 if $DELTA > 0 else 1)" && direction="up $DELTA"
    python3 -c "import sys; sys.exit(0 if $DELTA < 0 else 1)" && direction="**down ${DELTA#-}**"
    echo "**$SCORE/100 ($GRADE)** — base $BASE_SCORE, $direction."
  else
    echo "**$SCORE/100 ($GRADE)**"
  fi
  echo
  if [[ "$GATE_EXIT" -eq 2 ]]; then
    echo "Readiness policy breached:"
    echo
    echo '```'
    grep -E "^  (FAIL|pass|skip)" "$WORK/gate.out" || true
    echo '```'
  fi
  echo
  echo "<sub>Every check cites the Apple source it is derived from; see the uploaded report.</sub>"
}

summary >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

if [[ "$COMMENT_ON_PR" == "true" && "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  PR_NUMBER="$(python3 -c "import json,os;print(json.load(open(os.environ['GITHUB_EVENT_PATH']))['pull_request']['number'])" 2>/dev/null || echo "")"
  if [[ -n "$PR_NUMBER" ]]; then
    if ! summary | gh pr comment "$PR_NUMBER" --body-file - 2>"$WORK/comment.err"; then
      echo "note: could not comment on the pull request (fork PR, or missing pull-requests"
      echo "      write permission). The score is in the job summary instead."
    fi
  fi
fi

if [[ "$GATE_EXIT" -eq 2 && "$FAIL_ON_BREACH" == "true" ]]; then
  echo "::error::FoldReady readiness policy breached."
  exit 1
fi

exit 0

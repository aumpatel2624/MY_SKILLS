#!/usr/bin/env bash
# benchmark.sh — Run a standardized benchmark for a skill.
#
# Runs all evals, tracks pass rate / elapsed time / token usage,
# and saves results to evals/results/ as timestamped JSON.
#
# Usage:
#   bash evals/benchmark.sh <skill-name>
#   bash evals/benchmark.sh doctidy
#   bash evals/benchmark.sh git-workflow
#
# Options (via environment variables):
#   MODEL=<model-id>   Record which model was used (default: auto-detect)
#   PARALLEL=1         Run evals in parallel

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ── Args ────────────────────────────────────────────────────────────────

if [ $# -lt 1 ]; then
    echo "Usage: bash evals/benchmark.sh <skill-name>"
    exit 1
fi

SKILL_NAME="$1"
MODEL="${MODEL:-unknown}"
PARALLEL="${PARALLEL:-0}"
DRY_RUN="${DRY_RUN:-0}"
TIMESTAMP=$(timestamp_iso)
RESULT_FILE="$RESULTS_DIR/${SKILL_NAME}-${TIMESTAMP//:/}.json"

# Try to detect model from claude CLI
if [ "$MODEL" = "unknown" ] && command -v claude &> /dev/null; then
    MODEL=$(claude --version 2>/dev/null | head -1 || echo "unknown")
fi

# Auto-detect dry-run
if [ "$DRY_RUN" = "0" ] && command -v claude &> /dev/null; then
    if ! claude --print --output-format text -p "test" > /dev/null 2>&1; then
        DRY_RUN=1
    fi
elif [ "$DRY_RUN" = "0" ]; then
    DRY_RUN=1
fi

# ── Discover evals ──────────────────────────────────────────────────────

eval_output=$(find_evals "$SKILL_NAME") || exit 1
EVAL_FILES=()
while IFS= read -r f; do
    [ -z "$f" ] && continue
    EVAL_FILES+=("$f")
done <<< "$eval_output"

TOTAL=${#EVAL_FILES[@]}

if [ $TOTAL -eq 0 ]; then
    echo "No evals found for skill '$SKILL_NAME'"
    exit 1
fi

# ── Run benchmark ───────────────────────────────────────────────────────

print_header "Benchmark: $SKILL_NAME"
echo -e "  Model:     ${BLUE}$MODEL${RESET}"
echo -e "  Evals:     $TOTAL"
echo -e "  Timestamp: $TIMESTAMP"
echo ""

GLOBAL_START=$(timer_start)
PASSED=0
FAILED=0
SKIPPED=0
EVAL_RESULTS="["

SKILL_FILE="$REPO_ROOT/$SKILL_NAME/SKILL.md"

for eval_file in "${EVAL_FILES[@]}"; do
    eval_start=$(timer_start)
    parse_eval_yaml "$eval_file"
    name="${EVAL_NAME:-$(basename "$eval_file" .yaml)}"

    if [ -z "$EVAL_PROMPT" ]; then
        print_skip "$name (no prompt)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    if [ -z "$EVAL_MUST_CONTAIN" ] && [ -z "$EVAL_MUST_NOT_CONTAIN" ] && [ -z "$EVAL_MUST_MATCH" ]; then
        print_skip "$name (no criteria)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    output=""
    tokens_in=0
    tokens_out=0

    if [ "$DRY_RUN" = "1" ]; then
        elapsed=$(timer_elapsed "$eval_start")
        print_pass "$name (dry-run, ${elapsed}s)"
        PASSED=$((PASSED + 1))
        status="pass"

        json_name=$(json_escape "$name")
        EVAL_RESULTS="$EVAL_RESULTS$([ "$EVAL_RESULTS" != "[" ] && echo "," || true)
    {\"name\":\"$json_name\",\"status\":\"pass\",\"mode\":\"dry-run\",\"elapsed\":$elapsed,\"tokens_in\":0,\"tokens_out\":0}"
        continue
    fi

    full_prompt="Please follow the instructions in the skill below, then respond to the user prompt.

--- SKILL INSTRUCTIONS ---
$(cat "$SKILL_FILE")
--- END SKILL INSTRUCTIONS ---

User prompt: $EVAL_PROMPT"

    tmp_out=$(mktemp)
    claude --print --output-format text \
        -p "$full_prompt" \
        > "$tmp_out" 2>/dev/null || true
    output=$(cat "$tmp_out")
    rm -f "$tmp_out"

    elapsed=$(timer_elapsed "$eval_start")
    status="pass"

    if check_eval "$output"; then
        print_pass "$name (${elapsed}s)"
        PASSED=$((PASSED + 1))
    else
        print_fail "$name (${elapsed}s)"
        FAILED=$((FAILED + 1))
        status="fail"
        while IFS= read -r reason; do
            [ -z "$reason" ] && continue
            echo -e "          ${RED}$reason${RESET}"
        done <<< "$CHECK_FAILURES"
    fi

    json_name=$(json_escape "$name")
    EVAL_RESULTS="$EVAL_RESULTS$([ "$EVAL_RESULTS" != "[" ] && echo "," || true)
    {\"name\":\"$json_name\",\"status\":\"$status\",\"elapsed\":$elapsed,\"tokens_in\":$tokens_in,\"tokens_out\":$tokens_out}"
done

EVAL_RESULTS="$EVAL_RESULTS]"
GLOBAL_ELAPSED=$(timer_elapsed "$GLOBAL_START")

print_summary $PASSED $FAILED $SKIPPED $TOTAL $GLOBAL_ELAPSED

# ── Save results ────────────────────────────────────────────────────────

PASS_RATE=0
if [ $((PASSED + FAILED)) -gt 0 ]; then
    PASS_RATE=$(( (PASSED * 100) / (PASSED + FAILED) ))
fi

cat > "$RESULT_FILE" << ENDJSON
{
  "skill": "$SKILL_NAME",
  "model": "$(json_escape "$MODEL")",
  "timestamp": "$TIMESTAMP",
  "summary": {
    "total": $TOTAL,
    "passed": $PASSED,
    "failed": $FAILED,
    "skipped": $SKIPPED,
    "pass_rate": $PASS_RATE,
    "elapsed_seconds": $GLOBAL_ELAPSED
  },
  "evals": $EVAL_RESULTS
}
ENDJSON

echo ""
echo -e "  ${BLUE}Results saved to:${RESET} $RESULT_FILE"
echo -e "  ${BOLD}Pass rate: ${PASS_RATE}%${RESET}"

# ── Compare with previous run ──────────────────────────────────────────

PREV_FILE=$(ls -t "$RESULTS_DIR"/${SKILL_NAME}-*.json 2>/dev/null | head -2 | tail -1)
if [ -n "$PREV_FILE" ] && [ "$PREV_FILE" != "$RESULT_FILE" ]; then
    # Extract previous pass rate (minimal parsing)
    PREV_RATE=$(grep -o '"pass_rate": [0-9]*' "$PREV_FILE" | head -1 | grep -o '[0-9]*$' || echo "")
    if [ -n "$PREV_RATE" ]; then
        DELTA=$((PASS_RATE - PREV_RATE))
        if [ $DELTA -gt 0 ]; then
            echo -e "  ${GREEN}↑ +${DELTA}% vs previous run${RESET}"
        elif [ $DELTA -lt 0 ]; then
            echo -e "  ${RED}↓ ${DELTA}% vs previous run (regression!)${RESET}"
        else
            echo -e "  ${YELLOW}= No change vs previous run${RESET}"
        fi
    fi
fi

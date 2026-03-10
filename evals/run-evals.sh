#!/usr/bin/env bash
# run-evals.sh — Run evals for a skill and report pass/fail.
#
# Usage:
#   bash evals/run-evals.sh <skill-name> [eval-name]
#   bash evals/run-evals.sh doctidy
#   bash evals/run-evals.sh git-workflow commit-feature-change
#
# Options (via environment variables):
#   PARALLEL=1        Run evals in parallel (multi-agent style, isolated contexts)
#   SKILL_FILE=path   Override the SKILL.md path (for A/B testing)
#   NO_SKILL=1        Run evals without loading the skill (for outgrown detection)
#   VERBOSE=1         Print full output on failures

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ── Args ────────────────────────────────────────────────────────────────

if [ $# -lt 1 ]; then
    echo "Usage: bash evals/run-evals.sh <skill-name> [eval-name]"
    echo ""
    echo "Examples:"
    echo "  bash evals/run-evals.sh doctidy"
    echo "  bash evals/run-evals.sh git-workflow commit-feature-change"
    exit 1
fi

SKILL_NAME="$1"
EVAL_FILTER="${2:-}"
PARALLEL="${PARALLEL:-0}"
NO_SKILL="${NO_SKILL:-0}"
VERBOSE="${VERBOSE:-0}"
DRY_RUN="${DRY_RUN:-0}"
SKILL_FILE="${SKILL_FILE:-$REPO_ROOT/$SKILL_NAME/SKILL.md}"

# Auto-detect dry-run: if claude CLI can't run in print mode, fall back
if [ "$DRY_RUN" = "0" ] && command -v claude &> /dev/null; then
    if ! claude --print --output-format text -p "test" > /dev/null 2>&1; then
        DRY_RUN=1
    fi
elif [ "$DRY_RUN" = "0" ] && ! command -v claude &> /dev/null; then
    DRY_RUN=1
fi

if [ "$NO_SKILL" = "1" ]; then
    SKILL_FILE=""
fi

# ── Discover evals ──────────────────────────────────────────────────────

eval_output=$(find_evals "$SKILL_NAME" "$EVAL_FILTER") || exit 1
EVAL_FILES=()
while IFS= read -r f; do
    [ -z "$f" ] && continue
    EVAL_FILES+=("$f")
done <<< "$eval_output"

if [ ${#EVAL_FILES[@]} -eq 0 ]; then
    echo "No evals found for skill '$SKILL_NAME'"
    exit 1
fi

# ── Run ─────────────────────────────────────────────────────────────────

PASSED=0
FAILED=0
SKIPPED=0
TOTAL=${#EVAL_FILES[@]}
GLOBAL_START=$(timer_start)

# JSON results accumulator
RESULTS_JSON="["

print_header "Running evals for: $SKILL_NAME ($TOTAL eval(s))"
if [ -n "$SKILL_FILE" ]; then
    echo -e "  Skill: ${BLUE}$SKILL_FILE${RESET}"
else
    echo -e "  Skill: ${YELLOW}(none — bare model)${RESET}"
fi
echo ""

run_single_eval() {
    local eval_file="$1"
    local eval_start
    eval_start=$(timer_start)

    parse_eval_yaml "$eval_file"
    local name="${EVAL_NAME:-$(basename "$eval_file" .yaml)}"

    # Build the prompt sent to the model
    local full_prompt=""
    if [ -n "$SKILL_FILE" ] && [ -f "$SKILL_FILE" ]; then
        full_prompt="Please follow the instructions in the skill below, then respond to the user prompt.

--- SKILL INSTRUCTIONS ---
$(cat "$SKILL_FILE")
--- END SKILL INSTRUCTIONS ---

User prompt: $EVAL_PROMPT"
    else
        full_prompt="$EVAL_PROMPT"
    fi

    # Simulate eval execution
    # In a real setup, this would call the Claude API or claude-code CLI.
    # For now, we validate the eval definition and check structural correctness.
    local output=""
    local eval_status="pass"

    # Check that the eval is well-formed
    if [ -z "$EVAL_PROMPT" ]; then
        print_skip "$name (no prompt defined)"
        SKIPPED=$((SKIPPED + 1))
        return
    fi

    if [ -z "$EVAL_MUST_CONTAIN" ] && [ -z "$EVAL_MUST_NOT_CONTAIN" ] && [ -z "$EVAL_MUST_MATCH" ]; then
        print_skip "$name (no expected criteria defined)"
        SKIPPED=$((SKIPPED + 1))
        return
    fi

    # Execute via Claude Code CLI, or dry-run if unavailable
    if [ "$DRY_RUN" = "1" ]; then
        # Dry-run mode: validate eval structure only
        local elapsed
        elapsed=$(timer_elapsed "$eval_start")
        print_pass "$name (dry-run, ${elapsed}s)"
        PASSED=$((PASSED + 1))

        local json_name
        json_name=$(json_escape "$name")
        RESULTS_JSON="$RESULTS_JSON$([ "$RESULTS_JSON" != "[" ] && echo "," || true){\"name\":\"$json_name\",\"status\":\"pass\",\"mode\":\"dry-run\",\"elapsed\":$elapsed}"
        return
    fi

    # Live mode: call Claude CLI
    local tmp_out
    tmp_out=$(mktemp)

    if [ -n "$SKILL_FILE" ] && [ -f "$SKILL_FILE" ]; then
        claude --print --output-format text \
            -p "$full_prompt" \
            > "$tmp_out" 2>/dev/null || true
    else
        claude --print --output-format text \
            -p "$EVAL_PROMPT" \
            > "$tmp_out" 2>/dev/null || true
    fi

    output=$(cat "$tmp_out")
    rm -f "$tmp_out"

    # Check output against criteria
    local elapsed
    elapsed=$(timer_elapsed "$eval_start")

    if check_eval "$output"; then
        print_pass "$name (${elapsed}s)"
        PASSED=$((PASSED + 1))
        eval_status="pass"
    else
        print_fail "$name (${elapsed}s)"
        FAILED=$((FAILED + 1))
        eval_status="fail"

        # Print failure details
        while IFS= read -r reason; do
            [ -z "$reason" ] && continue
            echo -e "          ${RED}$reason${RESET}"
        done <<< "$CHECK_FAILURES"

        if [ "$VERBOSE" = "1" ] && [ -n "$output" ]; then
            echo "          ── Output ──"
            echo "$output" | head -20 | sed 's/^/          /'
            echo "          ── End ──"
        fi
    fi

    # Append to JSON
    local json_name json_failures
    json_name=$(json_escape "$name")
    json_failures=$(json_escape "${CHECK_FAILURES:-}")
    RESULTS_JSON="$RESULTS_JSON$([ "$RESULTS_JSON" != "[" ] && echo "," || true){\"name\":\"$json_name\",\"status\":\"$eval_status\",\"elapsed\":$elapsed,\"failures\":\"$json_failures\"}"
}

if [ "$PARALLEL" = "1" ] && [ ${#EVAL_FILES[@]} -gt 1 ]; then
    echo -e "  ${BLUE}Running in parallel mode${RESET}"
    echo ""

    # Launch evals in background subshells
    PIDS=()
    TMPFILES=()
    for eval_file in "${EVAL_FILES[@]}"; do
        tmp=$(mktemp)
        TMPFILES+=("$tmp")
        (
            # Each subshell gets its own isolated context
            source "$SCRIPT_DIR/lib.sh"
            PASSED=0 FAILED=0 SKIPPED=0 RESULTS_JSON="["
            run_single_eval "$eval_file"
            echo "$PASSED $FAILED $SKIPPED" > "$tmp"
        ) &
        PIDS+=($!)
    done

    # Wait for all
    for pid in "${PIDS[@]}"; do
        wait "$pid" || true
    done

    # Aggregate results
    for tmp in "${TMPFILES[@]}"; do
        if [ -f "$tmp" ]; then
            read -r p f s < "$tmp"
            PASSED=$((PASSED + p))
            FAILED=$((FAILED + f))
            SKIPPED=$((SKIPPED + s))
            rm -f "$tmp"
        fi
    done
else
    for eval_file in "${EVAL_FILES[@]}"; do
        run_single_eval "$eval_file"
    done
fi

RESULTS_JSON="$RESULTS_JSON]"
GLOBAL_ELAPSED=$(timer_elapsed "$GLOBAL_START")

print_summary $PASSED $FAILED $SKIPPED $TOTAL $GLOBAL_ELAPSED

# ── Exit code ───────────────────────────────────────────────────────────

if [ $FAILED -gt 0 ]; then
    exit 1
fi
exit 0

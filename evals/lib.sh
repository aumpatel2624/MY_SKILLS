#!/usr/bin/env bash
# lib.sh — Shared utilities for the evals framework.
# Sourced by run-evals.sh, benchmark.sh, comparator.sh, and outgrown-check.sh.

set -euo pipefail

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="$REPO_ROOT/evals/results"
mkdir -p "$RESULTS_DIR"

# ── YAML Parser (minimal, handles our eval format) ──────────────────────

# Parse a simple YAML file into shell variables.
# Usage: parse_eval_yaml <file>
# Sets: EVAL_NAME, EVAL_DESCRIPTION, EVAL_TYPE, EVAL_PROMPT,
#       EVAL_MUST_CONTAIN (newline-separated), EVAL_MUST_NOT_CONTAIN,
#       EVAL_MUST_MATCH, EVAL_TAGS, EVAL_FIXTURES
parse_eval_yaml() {
    local file="$1"
    EVAL_NAME=""
    EVAL_DESCRIPTION=""
    EVAL_TYPE=""
    EVAL_PROMPT=""
    EVAL_MUST_CONTAIN=""
    EVAL_MUST_NOT_CONTAIN=""
    EVAL_MUST_MATCH=""
    EVAL_TAGS=""
    EVAL_FIXTURES=""

    local current_section=""
    local current_list=""

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Top-level scalar fields
        if [[ "$line" =~ ^name:[[:space:]]*(.*) ]]; then
            EVAL_NAME="${BASH_REMATCH[1]//\"/}"
            current_section=""
        elif [[ "$line" =~ ^description:[[:space:]]*(.*) ]]; then
            EVAL_DESCRIPTION="${BASH_REMATCH[1]//\"/}"
            current_section=""
        elif [[ "$line" =~ ^type:[[:space:]]*(.*) ]]; then
            EVAL_TYPE="${BASH_REMATCH[1]//\"/}"
            current_section=""
        elif [[ "$line" =~ ^prompt:[[:space:]]*(.*) ]]; then
            EVAL_PROMPT="${BASH_REMATCH[1]//\"/}"
            current_section=""
        elif [[ "$line" =~ ^[[:space:]]*must_contain: ]]; then
            current_section="must_contain"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]*must_not_contain: ]]; then
            current_section="must_not_contain"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]*must_match: ]]; then
            current_section="must_match"
            current_list=""
        elif [[ "$line" =~ ^tags:[[:space:]]*\[(.*)\] ]]; then
            EVAL_TAGS="${BASH_REMATCH[1]}"
            current_section=""
        elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
            local value="${BASH_REMATCH[1]//\"/}"
            case "$current_section" in
                must_contain)
                    EVAL_MUST_CONTAIN="${EVAL_MUST_CONTAIN}${EVAL_MUST_CONTAIN:+$'\n'}$value"
                    ;;
                must_not_contain)
                    EVAL_MUST_NOT_CONTAIN="${EVAL_MUST_NOT_CONTAIN}${EVAL_MUST_NOT_CONTAIN:+$'\n'}$value"
                    ;;
                must_match)
                    EVAL_MUST_MATCH="${EVAL_MUST_MATCH}${EVAL_MUST_MATCH:+$'\n'}$value"
                    ;;
                fixtures)
                    EVAL_FIXTURES="${EVAL_FIXTURES}${EVAL_FIXTURES:+$'\n'}$value"
                    ;;
            esac
        elif [[ "$line" =~ ^fixtures: ]]; then
            current_section="fixtures"
        elif [[ "$line" =~ ^expected: ]]; then
            current_section=""  # expected: is a parent, children set section
        fi
    done < "$file"
}

# ── Eval Checker ────────────────────────────────────────────────────────

# Check eval output against expected criteria.
# Usage: check_eval <output_text>
# Returns: 0 if all checks pass, 1 otherwise.
# Sets: CHECK_FAILURES (newline-separated list of failure reasons)
check_eval() {
    local output="$1"
    CHECK_FAILURES=""
    local failed=0

    # must_contain checks
    if [ -n "$EVAL_MUST_CONTAIN" ]; then
        while IFS= read -r expected; do
            [ -z "$expected" ] && continue
            if [[ "$output" != *"$expected"* ]]; then
                CHECK_FAILURES="${CHECK_FAILURES}${CHECK_FAILURES:+$'\n'}MISSING: expected output to contain: \"$expected\""
                failed=1
            fi
        done <<< "$EVAL_MUST_CONTAIN"
    fi

    # must_not_contain checks
    if [ -n "$EVAL_MUST_NOT_CONTAIN" ]; then
        while IFS= read -r unexpected; do
            [ -z "$unexpected" ] && continue
            if [[ "$output" == *"$unexpected"* ]]; then
                CHECK_FAILURES="${CHECK_FAILURES}${CHECK_FAILURES:+$'\n'}UNWANTED: output should not contain: \"$unexpected\""
                failed=1
            fi
        done <<< "$EVAL_MUST_NOT_CONTAIN"
    fi

    # must_match (regex) checks
    if [ -n "$EVAL_MUST_MATCH" ]; then
        while IFS= read -r pattern; do
            [ -z "$pattern" ] && continue
            if ! echo "$output" | grep -qE "$pattern"; then
                CHECK_FAILURES="${CHECK_FAILURES}${CHECK_FAILURES:+$'\n'}NO MATCH: output did not match pattern: /$pattern/"
                failed=1
            fi
        done <<< "$EVAL_MUST_MATCH"
    fi

    return $failed
}

# ── Reporting ───────────────────────────────────────────────────────────

print_pass() {
    echo -e "  ${GREEN}✓ PASS${RESET}  $1"
}

print_fail() {
    echo -e "  ${RED}✗ FAIL${RESET}  $1"
}

print_skip() {
    echo -e "  ${YELLOW}⊘ SKIP${RESET}  $1"
}

print_header() {
    echo ""
    echo -e "${BOLD}$1${RESET}"
    echo "$(printf '%.0s─' {1..60})"
}

print_summary() {
    local passed=$1 failed=$2 skipped=$3 total=$4 elapsed=$5
    echo ""
    echo "$(printf '%.0s─' {1..60})"
    echo -e "${BOLD}Results:${RESET} ${GREEN}$passed passed${RESET}, ${RED}$failed failed${RESET}, ${YELLOW}$skipped skipped${RESET} — $total total (${elapsed}s)"
}

# ── JSON helpers ────────────────────────────────────────────────────────

# Minimal JSON output without requiring jq
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    echo "$s"
}

# Get current timestamp in ISO 8601
timestamp_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date
}

# Get elapsed time in seconds
timer_start() {
    date +%s
}

timer_elapsed() {
    local start=$1
    local now
    now=$(date +%s)
    echo $(( now - start ))
}

# ── Eval Discovery ─────────────────────────────────────────────────────

# Find all eval YAML files for a skill.
# Usage: find_evals <skill_name> [specific_eval_name]
find_evals() {
    local skill="$1"
    local specific="${2:-}"
    local eval_dir="$REPO_ROOT/$skill/evals"

    if [ ! -d "$eval_dir" ]; then
        echo "ERROR: No evals directory found at $eval_dir" >&2
        return 1
    fi

    if [ -n "$specific" ]; then
        local found=0
        for f in "$eval_dir"/*.yaml "$eval_dir"/*.yml; do
            [ -f "$f" ] || continue
            local basename
            basename="$(basename "$f" .yaml)"
            basename="${basename%.yml}"
            # Strip leading number prefix for matching (e.g., 01-basic-trigger -> basic-trigger)
            local stripped="${basename#[0-9][0-9]-}"
            if [ "$basename" = "$specific" ] || [ "$stripped" = "$specific" ]; then
                echo "$f"
                found=1
            fi
        done
        if [ $found -eq 0 ]; then
            echo "ERROR: No eval matching '$specific' found in $eval_dir" >&2
            return 1
        fi
    else
        for f in "$eval_dir"/*.yaml "$eval_dir"/*.yml; do
            [ -f "$f" ] || continue
            echo "$f"
        done
    fi
}

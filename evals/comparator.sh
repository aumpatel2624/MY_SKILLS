#!/usr/bin/env bash
# comparator.sh — A/B test two skill versions (or skill vs. no skill).
#
# Runs evals twice — once with version A, once with version B — and
# compares results. By default, A = current SKILL.md, B = no skill.
#
# Usage:
#   bash evals/comparator.sh <skill-name>                    # skill vs. bare model
#   bash evals/comparator.sh <skill-name> <alt-skill-path>   # skill vs. alternate version
#
# The comparator runs both versions blind and reports which performed better.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ── Args ────────────────────────────────────────────────────────────────

if [ $# -lt 1 ]; then
    echo "Usage: bash evals/comparator.sh <skill-name> [alt-skill-path]"
    echo ""
    echo "Examples:"
    echo "  bash evals/comparator.sh doctidy                     # skill vs. no skill"
    echo "  bash evals/comparator.sh doctidy /path/to/v2/SKILL.md  # v1 vs. v2"
    exit 1
fi

SKILL_NAME="$1"
ALT_SKILL="${2:-}"
DRY_RUN="${DRY_RUN:-0}"

# Auto-detect dry-run
if [ "$DRY_RUN" = "0" ] && command -v claude &> /dev/null; then
    if ! claude --print --output-format text -p "test" > /dev/null 2>&1; then
        DRY_RUN=1
    fi
elif [ "$DRY_RUN" = "0" ]; then
    DRY_RUN=1
fi

VERSION_A_LABEL="with skill"
VERSION_B_LABEL="without skill (bare model)"
SKILL_A="$REPO_ROOT/$SKILL_NAME/SKILL.md"
SKILL_B=""

if [ -n "$ALT_SKILL" ]; then
    VERSION_B_LABEL="alternate version"
    SKILL_B="$ALT_SKILL"
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

# ── Run A ───────────────────────────────────────────────────────────────

print_header "A/B Comparator: $SKILL_NAME"
echo -e "  Version A: ${BLUE}$VERSION_A_LABEL${RESET} ($SKILL_A)"
echo -e "  Version B: ${BLUE}$VERSION_B_LABEL${RESET} ${SKILL_B:+($SKILL_B)}"
echo -e "  Evals:     $TOTAL"
echo ""

echo -e "${BOLD}── Version A: $VERSION_A_LABEL ──${RESET}"
A_START=$(timer_start)
A_PASSED=0
A_FAILED=0
A_SKIPPED=0

for eval_file in "${EVAL_FILES[@]}"; do
    parse_eval_yaml "$eval_file"
    name="${EVAL_NAME:-$(basename "$eval_file" .yaml)}"

    if [ -z "$EVAL_PROMPT" ] || { [ -z "$EVAL_MUST_CONTAIN" ] && [ -z "$EVAL_MUST_NOT_CONTAIN" ] && [ -z "$EVAL_MUST_MATCH" ]; }; then
        print_skip "$name"
        A_SKIPPED=$((A_SKIPPED + 1))
        continue
    fi

    if [ "$DRY_RUN" = "1" ]; then
        print_pass "$name (dry-run)"
        A_PASSED=$((A_PASSED + 1))
        continue
    fi

    output=""
    full_prompt="Please follow the instructions in the skill below, then respond to the user prompt.

--- SKILL INSTRUCTIONS ---
$(cat "$SKILL_A")
--- END SKILL INSTRUCTIONS ---

User prompt: $EVAL_PROMPT"
    output=$(claude --print --output-format text -p "$full_prompt" 2>/dev/null || true)

    if check_eval "$output"; then
        print_pass "$name"
        A_PASSED=$((A_PASSED + 1))
    else
        print_fail "$name"
        A_FAILED=$((A_FAILED + 1))
    fi
done

A_ELAPSED=$(timer_elapsed "$A_START")

# ── Run B ───────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}── Version B: $VERSION_B_LABEL ──${RESET}"
B_START=$(timer_start)
B_PASSED=0
B_FAILED=0
B_SKIPPED=0

for eval_file in "${EVAL_FILES[@]}"; do
    parse_eval_yaml "$eval_file"
    name="${EVAL_NAME:-$(basename "$eval_file" .yaml)}"

    if [ -z "$EVAL_PROMPT" ] || { [ -z "$EVAL_MUST_CONTAIN" ] && [ -z "$EVAL_MUST_NOT_CONTAIN" ] && [ -z "$EVAL_MUST_MATCH" ]; }; then
        print_skip "$name"
        B_SKIPPED=$((B_SKIPPED + 1))
        continue
    fi

    if [ "$DRY_RUN" = "1" ]; then
        print_pass "$name (dry-run)"
        B_PASSED=$((B_PASSED + 1))
        continue
    fi

    output=""
    if [ -n "$SKILL_B" ]; then
        full_prompt="Please follow the instructions in the skill below, then respond to the user prompt.

--- SKILL INSTRUCTIONS ---
$(cat "$SKILL_B")
--- END SKILL INSTRUCTIONS ---

User prompt: $EVAL_PROMPT"
    else
        full_prompt="$EVAL_PROMPT"
    fi
    output=$(claude --print --output-format text -p "$full_prompt" 2>/dev/null || true)

    if check_eval "$output"; then
        print_pass "$name"
        B_PASSED=$((B_PASSED + 1))
    else
        print_fail "$name"
        B_FAILED=$((B_FAILED + 1))
    fi
done

B_ELAPSED=$(timer_elapsed "$B_START")

# ── Comparison ──────────────────────────────────────────────────────────

echo ""
echo "$(printf '%.0s═' {1..60})"
echo -e "${BOLD}  A/B COMPARISON RESULTS${RESET}"
echo "$(printf '%.0s═' {1..60})"
echo ""

A_RATE=0
B_RATE=0
if [ $((A_PASSED + A_FAILED)) -gt 0 ]; then
    A_RATE=$(( (A_PASSED * 100) / (A_PASSED + A_FAILED) ))
fi
if [ $((B_PASSED + B_FAILED)) -gt 0 ]; then
    B_RATE=$(( (B_PASSED * 100) / (B_PASSED + B_FAILED) ))
fi

printf "  %-30s %s\n" "Version A ($VERSION_A_LABEL):" "${A_PASSED} passed, ${A_FAILED} failed (${A_RATE}%) — ${A_ELAPSED}s"
printf "  %-30s %s\n" "Version B ($VERSION_B_LABEL):" "${B_PASSED} passed, ${B_FAILED} failed (${B_RATE}%) — ${B_ELAPSED}s"
echo ""

DELTA=$((A_RATE - B_RATE))
if [ $DELTA -gt 0 ]; then
    echo -e "  ${GREEN}★ Version A wins by +${DELTA}% pass rate${RESET}"
    echo -e "  The skill is providing measurable value."
elif [ $DELTA -lt 0 ]; then
    echo -e "  ${RED}★ Version B wins by +$((-DELTA))% pass rate${RESET}"
    if [ -z "$ALT_SKILL" ]; then
        echo -e "  ${YELLOW}The bare model outperforms the skill — consider retiring it.${RESET}"
    else
        echo -e "  ${YELLOW}The alternate version performs better.${RESET}"
    fi
else
    echo -e "  ${YELLOW}★ Tie — both versions have the same pass rate.${RESET}"
    if [ -z "$ALT_SKILL" ]; then
        echo -e "  ${YELLOW}The skill may not be adding value. Review qualitatively.${RESET}"
    fi
fi
echo ""

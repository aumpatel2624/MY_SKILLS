#!/usr/bin/env bash
# outgrown-check.sh — Detect if the base model has outgrown a skill.
#
# Runs all evals WITHOUT loading the skill. If the bare model passes
# most evals, the skill's techniques may have been absorbed into the
# model's default behavior — the skill is no longer necessary.
#
# Usage:
#   bash evals/outgrown-check.sh <skill-name>
#
# Thresholds (via environment variables):
#   OUTGROWN_THRESHOLD=80   Percentage at which the skill is considered outgrown (default: 80)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ── Args ────────────────────────────────────────────────────────────────

if [ $# -lt 1 ]; then
    echo "Usage: bash evals/outgrown-check.sh <skill-name>"
    exit 1
fi

SKILL_NAME="$1"
OUTGROWN_THRESHOLD="${OUTGROWN_THRESHOLD:-80}"
DRY_RUN="${DRY_RUN:-0}"

# Auto-detect dry-run
if [ "$DRY_RUN" = "0" ] && command -v claude &> /dev/null; then
    if ! claude --print --output-format text -p "test" > /dev/null 2>&1; then
        DRY_RUN=1
    fi
elif [ "$DRY_RUN" = "0" ]; then
    DRY_RUN=1
fi

# ── Run evals without skill ─────────────────────────────────────────────

print_header "Model-Outgrown Check: $SKILL_NAME"
echo -e "  Threshold: ${BOLD}${OUTGROWN_THRESHOLD}%${RESET} (bare model pass rate triggers outgrown signal)"
echo ""

# First, run WITH skill for baseline
echo -e "${BOLD}── With skill loaded ──${RESET}"
SKILL_PASSED=0
SKILL_FAILED=0
SKILL_SKIPPED=0
SKILL_FILE="$REPO_ROOT/$SKILL_NAME/SKILL.md"

eval_output=$(find_evals "$SKILL_NAME") || exit 1
EVAL_FILES=()
while IFS= read -r f; do
    [ -z "$f" ] && continue
    EVAL_FILES+=("$f")
done <<< "$eval_output"

TOTAL=${#EVAL_FILES[@]}

for eval_file in "${EVAL_FILES[@]}"; do
    parse_eval_yaml "$eval_file"
    name="${EVAL_NAME:-$(basename "$eval_file" .yaml)}"

    if [ -z "$EVAL_PROMPT" ] || { [ -z "$EVAL_MUST_CONTAIN" ] && [ -z "$EVAL_MUST_NOT_CONTAIN" ] && [ -z "$EVAL_MUST_MATCH" ]; }; then
        print_skip "$name"
        SKILL_SKIPPED=$((SKILL_SKIPPED + 1))
        continue
    fi

    if [ "$DRY_RUN" = "1" ]; then
        print_pass "$name (dry-run)"
        SKILL_PASSED=$((SKILL_PASSED + 1))
        continue
    fi

    output=""
    full_prompt="Please follow the instructions in the skill below, then respond to the user prompt.

--- SKILL INSTRUCTIONS ---
$(cat "$SKILL_FILE")
--- END SKILL INSTRUCTIONS ---

User prompt: $EVAL_PROMPT"
    output=$(claude --print --output-format text -p "$full_prompt" 2>/dev/null || true)

    if check_eval "$output"; then
        print_pass "$name"
        SKILL_PASSED=$((SKILL_PASSED + 1))
    else
        print_fail "$name"
        SKILL_FAILED=$((SKILL_FAILED + 1))
    fi
done

# Then, run WITHOUT skill
echo ""
echo -e "${BOLD}── Without skill (bare model) ──${RESET}"
BARE_PASSED=0
BARE_FAILED=0
BARE_SKIPPED=0

for eval_file in "${EVAL_FILES[@]}"; do
    parse_eval_yaml "$eval_file"
    name="${EVAL_NAME:-$(basename "$eval_file" .yaml)}"

    if [ -z "$EVAL_PROMPT" ] || { [ -z "$EVAL_MUST_CONTAIN" ] && [ -z "$EVAL_MUST_NOT_CONTAIN" ] && [ -z "$EVAL_MUST_MATCH" ]; }; then
        print_skip "$name"
        BARE_SKIPPED=$((BARE_SKIPPED + 1))
        continue
    fi

    if [ "$DRY_RUN" = "1" ]; then
        print_pass "$name (dry-run)"
        BARE_PASSED=$((BARE_PASSED + 1))
        continue
    fi

    output=""
    output=$(claude --print --output-format text -p "$EVAL_PROMPT" 2>/dev/null || true)

    if check_eval "$output"; then
        print_pass "$name"
        BARE_PASSED=$((BARE_PASSED + 1))
    else
        print_fail "$name"
        BARE_FAILED=$((BARE_FAILED + 1))
    fi
done

# ── Analysis ────────────────────────────────────────────────────────────

echo ""
echo "$(printf '%.0s═' {1..60})"
echo -e "${BOLD}  OUTGROWN ANALYSIS${RESET}"
echo "$(printf '%.0s═' {1..60})"
echo ""

SKILL_RATE=0
BARE_RATE=0
if [ $((SKILL_PASSED + SKILL_FAILED)) -gt 0 ]; then
    SKILL_RATE=$(( (SKILL_PASSED * 100) / (SKILL_PASSED + SKILL_FAILED) ))
fi
if [ $((BARE_PASSED + BARE_FAILED)) -gt 0 ]; then
    BARE_RATE=$(( (BARE_PASSED * 100) / (BARE_PASSED + BARE_FAILED) ))
fi

echo "  With skill:    ${SKILL_PASSED}/${TOTAL} passed (${SKILL_RATE}%)"
echo "  Without skill: ${BARE_PASSED}/${TOTAL} passed (${BARE_RATE}%)"
echo ""

if [ $BARE_RATE -ge "$OUTGROWN_THRESHOLD" ]; then
    echo -e "  ${YELLOW}⚠ OUTGROWN SIGNAL${RESET}"
    echo -e "  The bare model passes ${BARE_RATE}% of evals (threshold: ${OUTGROWN_THRESHOLD}%)."
    echo -e "  The model may have absorbed this skill's techniques."
    echo ""
    echo "  Recommendations:"
    echo "    1. Review evals qualitatively — are bare-model outputs as good?"
    echo "    2. If yes, consider retiring the skill."
    echo "    3. If no, add harder evals that test the skill's unique value."
elif [ $BARE_RATE -ge $(( OUTGROWN_THRESHOLD - 20 )) ]; then
    echo -e "  ${YELLOW}⊘ APPROACHING OUTGROWN${RESET}"
    echo -e "  The bare model passes ${BARE_RATE}% — getting close to the ${OUTGROWN_THRESHOLD}% threshold."
    echo "  Monitor on next model update."
else
    echo -e "  ${GREEN}✓ SKILL STILL VALUABLE${RESET}"
    echo -e "  The bare model only passes ${BARE_RATE}% — the skill adds clear value."
    DELTA=$((SKILL_RATE - BARE_RATE))
    if [ $DELTA -gt 0 ]; then
        echo -e "  Skill advantage: +${DELTA}% pass rate."
    fi
fi
echo ""

#!/usr/bin/env bash
# analyze-diff.sh
# Produces a structured summary of current git changes.
# Run this at the start of the workflow to get a clear picture.
# Usage: bash scripts/analyze-diff.sh
#
# Works on: macOS, Linux, Windows (Git Bash / WSL)
# Windows users: use analyze-diff.bat (CMD) or analyze-diff.ps1 (PowerShell)

set -euo pipefail

SEPARATOR="========================================"
SECTION_LINE="--- %s ---"

section() {
    echo ""
    printf "$SECTION_LINE\n" "$1"
}

run_git() {
    local output
    output=$("$@" 2>&1) || true
    if [ -z "$output" ]; then
        echo "(no output)"
    else
        echo "$output"
    fi
}

echo ""
echo "$SEPARATOR"
echo "  GIT DIFF ANALYSIS"
echo "$SEPARATOR"

# Check we are inside a git repo before running anything
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo ""
    echo "ERROR: Not inside a git repository. Navigate to your project first."
    exit 1
fi

section "CURRENT BRANCH"
run_git git branch --show-current

section "STATUS SUMMARY"
run_git git status --short

section "FILES CHANGED (unstaged)"
run_git git diff --name-status

section "FILES CHANGED (staged)"
run_git git diff --cached --name-status

section "CHANGE STATS (unstaged)"
run_git git diff --stat

section "CHANGE STATS (staged)"
run_git git diff --cached --stat

section "RECENT COMMITS (last 5)"
run_git git log --oneline -5

section "STAGED DIFF (preview)"
run_git git diff --cached

section "UNSTAGED DIFF (preview)"
run_git git diff

echo ""
echo "$SEPARATOR"
echo "  END OF ANALYSIS"
echo "$SEPARATOR"

---
name: git-workflow
description: "Use this skill whenever the user wants help with git: committing changes, naming branches, writing commit messages, pushing code, staging files, or preparing a PR. Trigger on phrases like: commit my changes, create a branch, what should I name this branch, help me with git, write a commit message, push my code, review my diff, stage my changes, prepare a pull request, or what branch should I use. This skill runs the complete workflow: inspect the diff, pick the right branch name and target, write a conventional commit message, and output copy-paste-ready commands. Built for a 3-branch repo: development, staging, and production."
---

# Git Workflow Skill

End-to-end git assistant: **diff analysis → branch naming → commit message → ready commands**.

Branch hierarchy: `feature branches` → `development` → `staging` → `production`

---

## How to Use This Skill

Work through these five steps in order. Each step tells you when to open a reference file for full detail.

---

## Step 1 — Inspect the Repository

Run the analysis script for a full structured snapshot, or run the git commands manually.

**macOS / Linux / Git Bash / WSL:**
```bash
bash scripts/analyze-diff.sh
```

**Windows — Command Prompt:**
```cmd
scripts\analyze-diff.bat
```

**Windows — PowerShell:**
```powershell
.\scripts\analyze-diff.ps1
```

Or run the git commands directly:
```bash
git status                  # which files changed
git diff                    # unstaged changes (full diff)
git diff --cached           # already staged changes
git branch --show-current   # current branch name
git log --oneline -5        # recent commit context
```

Determine three things:
1. **What** changed — which files, which components, which logic
2. **Why** it changed — feature, bug fix, refactor, config, etc.
3. **Scope** — is this one coherent change, or multiple unrelated things?

> If the diff contains mixed, unrelated changes → read `references/edge-cases.md` before continuing.

---

## Step 2 — Choose and Create the Branch

> Full naming rules, patterns, anti-patterns, and examples: **`references/branch-naming.md`**

Quick decision table:

| Change type          | Branch prefix | Merges into   |
|----------------------|---------------|---------------|
| New feature          | `feat/`       | `development` |
| Bug fix (non-urgent) | `fix/`        | `development` |
| Critical prod fix    | `hotfix/`     | `production`  |
| Refactor / cleanup   | `chore/`      | `development` |
| Documentation        | `docs/`       | `development` |
| CI / build / tooling | `ci/`         | `development` |
| Staging-only fix     | `fix/`        | `staging`     |
| Performance          | `perf/`       | `development` |

Branch name format: `<prefix>/<short-descriptive-slug>`
Rules: lowercase · hyphens only · max 40 chars · no ticket numbers unless requested

---

## Step 3 — Write the Commit Message

> Full spec, all types, real-world examples: **`references/commit-messages.md`**

Format (Conventional Commits):
```
<type>(<scope>): <imperative summary — max 72 chars>

<body: what changed and why — omit for trivial changes>

<footer: BREAKING CHANGE or Closes #N — omit if not applicable>
```

Types: `feat` · `fix` · `hotfix` · `chore` · `refactor` · `docs` · `style` · `test` · `ci` · `perf` · `revert`

Core rules:
- Imperative mood in subject: "add" not "added", "fix" not "fixed"
- No trailing period on subject line
- Body explains *what and why*, never *how*
- One blank line between subject, body, and footer

---

## Step 4 — Output the Commands

Give the user a complete, copy-paste-ready block. Fill in the actual branch name and commit message.

```bash
# 1. Create and switch to branch (skip if already on a feature branch)
git checkout -b feat/your-branch-name

# 2. Stage changes
git add .                          # everything
git add path/to/specific/file.js   # selective
git add -p                         # interactive (for mixed changes)

# 3. Commit (single-line)
git commit -m "feat(scope): short summary here"

# 3. Commit (multi-line, when body is needed)
git commit -m "feat(scope): short summary here

Body paragraph explaining what changed and why.
Keep lines under 72 chars.

Closes #42"

# 4. Push and set upstream
git push -u origin feat/your-branch-name
```

> For hotfix flows (prod fix + backport): read **`references/hotfix-flow.md`**

---

## Step 5 — Present a Clear Summary

Always close your response with:

1. **Branch name** — state it clearly, with a one-sentence reason for the choice
2. **Full commit message** — verbatim, formatted, ready to copy
3. **Commands block** — the complete sequence filled in with real values
4. **Next step** — e.g. "Open a PR: `feat/login` → `development`"

---

## Reference Files

| File | Read when |
|------|-----------|
| `references/branch-naming.md` | Need full naming rules, edge cases, or real examples |
| `references/commit-messages.md` | Need full commit spec, scope guidance, or examples |
| `references/hotfix-flow.md` | Dealing with a critical production fix |
| `references/edge-cases.md` | Mixed changes, already on wrong branch, empty diff, first commit |
| `scripts/analyze-diff.sh` | macOS / Linux / Git Bash / WSL |
| `scripts/analyze-diff.bat` | Windows — Command Prompt |
| `scripts/analyze-diff.ps1` | Windows — PowerShell |

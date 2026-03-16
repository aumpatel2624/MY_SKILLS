---
name: git-workflow
description: "Use this skill whenever the user wants help with git: committing changes, naming branches, writing commit messages, updating the changelog, pushing code, staging files, or preparing a PR. Trigger on phrases like: commit my changes, create a branch, what should I name this branch, help me with git, write a commit message, push my code, review my diff, stage my changes, prepare a pull request, update the changelog, or what branch should I use. This skill runs the complete workflow: first verify the project builds error-free, then inspect the diff, pick the right branch name and target, write a conventional commit message, update CHANGELOG.md, and output copy-paste-ready commands. All branches merge into development only (hotfixes target production but must be backported to development). If no development branch exists, ask the user to create one. Built for a 3-branch repo: development, staging, and production."
---

# Git Workflow Skill

End-to-end git assistant: **diff analysis → branch naming → commit message → changelog update → ready commands**.

Branch hierarchy: `feature branches` → `development` → `staging` → `production`

---

## Mandatory Rule — Development Branch Only

> **All branches MUST merge into `development`.** This is non-negotiable.
>
> - `feat/`, `fix/`, `chore/`, `docs/`, `ci/`, `perf/`, `test/`, `style/`, `revert/` → **always merge into `development`**
> - `hotfix/` → merges into `production` **but must be immediately backported to `development`** (see `references/hotfix-flow.md`)
> - **Never merge directly into `staging` or `production`** (except hotfixes to production)
> - If the repository does not have a `development` branch, **stop and ask the user to create one** before proceeding. Do not continue the workflow without it.

---

## How to Use This Skill

Work through these seven steps in order. Each step tells you when to open a reference file for full detail.

---

## Step 0 — Verify the Project Builds

**Before touching git at all**, confirm the project is in a working state. Run the project's build/compile/lint commands to ensure there are no errors.

Common build commands (adapt to the project's stack):
```bash
# Node.js / JavaScript / TypeScript
npm run build          # or: yarn build, pnpm build
npm run lint           # or: npx eslint .
npm test               # run tests if available

# Python
python -m py_compile main.py   # syntax check
pytest                          # run tests if available
flake8 .                        # lint

# Go
go build ./...
go test ./...

# Rust
cargo build
cargo test

# Java / Kotlin
./gradlew build        # or: mvn compile
./gradlew test         # or: mvn test

# Generic — check for a Makefile, package.json scripts, or CI config
```

**If the build fails or tests fail:**
1. **Do not proceed** with branching or committing
2. Tell the user what failed and help them fix the issues first
3. Re-run the build to confirm the fix
4. Only then continue to Step 1

> The goal: never commit broken code. Every commit on `development` should be buildable and pass tests.

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
| Critical prod fix    | `hotfix/`     | `production` *(then backport to `development`)* |
| Refactor / cleanup   | `chore/`      | `development` |
| Documentation        | `docs/`       | `development` |
| CI / build / tooling | `ci/`         | `development` |
| Performance          | `perf/`       | `development` |
| Test changes         | `test/`       | `development` |

> **No exceptions**: every branch merges into `development` unless it is a `hotfix/` (which targets `production` but must be backported to `development` immediately).
> If there is no `development` branch in the repo, **ask the user to create one first**.

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

## Step 4 — Update the CHANGELOG

> Full format rules, section ordering, and examples: **`references/changelog-format.md`**

Locate the project's `CHANGELOG.md`. Search from the repository root. If no `CHANGELOG.md` exists, create one at the repo root following the [Keep a Changelog](https://keepachangelog.com/) format.

Add an entry under the `## [Unreleased]` section. If there is no `[Unreleased]` section, add one at the top of the changelog (below the title and preamble).

Pick the correct subsection based on the change type:

| Commit type                    | Changelog section |
|--------------------------------|-------------------|
| `feat`                         | `### Added`       |
| `fix`, `hotfix`                | `### Fixed`       |
| `refactor`, `perf`             | `### Changed`     |
| `chore` (dep removal), `revert`| `### Removed`     |
| `chore` (dep upgrade/config)   | `### Changed`     |
| `docs`                         | `### Changed`     |
| `style`, `test`, `ci`          | Skip — no user-facing impact |

Entry rules:
- Write from the **user's perspective** — describe the effect, not the code
- Start with a verb in past tense: "Added", "Fixed", "Removed", "Updated"
- One bullet per logical change
- Reference issue/PR numbers where applicable: `(#42)`
- Keep entries concise — one or two sentences max

If the change has no user-facing impact (e.g., `style`, `test`, `ci`), **skip the changelog update** and note this to the user.

---

## Step 5 — Output the Commands

Give the user a complete, copy-paste-ready block. Fill in the actual branch name, commit message, and changelog entry.

```bash
# 1. Create and switch to branch (skip if already on a feature branch)
git checkout -b feat/your-branch-name

# 2. Update CHANGELOG.md (add entry under [Unreleased])
# Edit CHANGELOG.md — add your entry under the correct subsection

# 3. Stage changes (including CHANGELOG.md)
git add .                          # everything
git add path/to/specific/file.js CHANGELOG.md  # selective
git add -p                         # interactive (for mixed changes)

# 4. Commit (single-line)
git commit -m "feat(scope): short summary here"

# 4. Commit (multi-line, when body is needed)
git commit -m "feat(scope): short summary here

Body paragraph explaining what changed and why.
Keep lines under 72 chars.

Closes #42"

# 5. Push and set upstream
git push -u origin feat/your-branch-name
```

> For hotfix flows (prod fix + backport): read **`references/hotfix-flow.md`**

---

## Step 6 — Present a Clear Summary

Always close your response with:

1. **Build status** — confirm the project builds and tests pass (from Step 0)
2. **Branch name** — state it clearly, with a one-sentence reason for the choice
3. **Full commit message** — verbatim, formatted, ready to copy
4. **CHANGELOG entry** — the exact line(s) to add, and under which section
5. **Commands block** — the complete sequence filled in with real values
6. **Next step** — e.g. "Open a PR: `feat/login` → `development`" (always target `development`)

---

## Reference Files

| File | Read when |
|------|-----------|
| `references/branch-naming.md` | Need full naming rules, edge cases, or real examples |
| `references/commit-messages.md` | Need full commit spec, scope guidance, or examples |
| `references/changelog-format.md` | Need full changelog format rules, section guidance, or examples |
| `references/hotfix-flow.md` | Dealing with a critical production fix |
| `references/edge-cases.md` | Mixed changes, already on wrong branch, empty diff, first commit |
| `scripts/analyze-diff.sh` | macOS / Linux / Git Bash / WSL |
| `scripts/analyze-diff.bat` | Windows — Command Prompt |
| `scripts/analyze-diff.ps1` | Windows — PowerShell |

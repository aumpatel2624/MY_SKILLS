# Edge Cases Reference

Handles situations that don't fit the standard workflow.

---

## 1. Mixed / Unrelated Changes in the Same Diff

**Symptom**: `git diff` shows changes that belong to different features or concerns — e.g., a login bug fix and a new settings page in the same working tree.

**Why it matters**: Each commit should represent one logical change. Mixed commits make `git log` confusing, make reverts risky, and break changelog generation.

**Solution — split using interactive staging:**
```bash
# Stage only the files for the first logical change
git add src/auth/login.js

# Commit just that change
git commit -m "fix(auth): correct redirect after failed login"

# Then stage and commit the second change
git add src/settings/SettingsPage.jsx src/settings/settings.css
git commit -m "feat(settings): add user preferences page"
```

**For changes within the same file, use patch staging:**
```bash
git add -p src/utils/helpers.js
# Git will show you each hunk — press y to stage, n to skip
```

**Signs you need to split:**
- Your commit message needs "and" to be accurate
- Changes touch completely different areas of the codebase
- One set of changes should go to a different branch

---

## 2. Already on the Wrong Branch

**Symptom**: The user has been working on `development`, `staging`, or `production` directly, or on a poorly named branch like `test` or `johns-work`.

> **Remember**: All feature work must merge into `development`. If the user is trying to commit directly to `staging` or `production`, redirect them to create a proper feature branch that targets `development`.

**Option A — move uncommitted changes to a new branch:**
```bash
# Changes are still unstaged — just create the branch
git checkout -b feat/correct-branch-name

# Git automatically carries your unstaged/staged changes with you
```

**Option B — move committed changes to a new branch:**
```bash
# Find the commit hash where the branch should have diverged
git log --oneline

# Create the correct branch at the current HEAD
git checkout -b feat/correct-branch-name

# Reset the original branch back to where it should be
git checkout development
git reset --hard <hash-before-your-commits>
```

**Option C — rename a bad branch:**
```bash
git branch -m old-bad-name feat/proper-name
git push origin feat/proper-name
git push origin --delete old-bad-name
```

---

## 3. Empty Diff (Nothing to Commit)

**Symptom**: `git status` shows clean, `git diff` shows nothing.

**Possible causes and solutions:**

| Cause | How to check | Fix |
|-------|-------------|-----|
| Changes already staged | `git diff --cached` | Proceed with `git commit` |
| Changes already committed | `git log --oneline -3` | Nothing to do — already done |
| Files are gitignored | `git check-ignore -v <file>` | Add to `.gitignore` intentionally or update it |
| Saved in wrong location | Check filesystem | Save to the right place |

---

## 4. First Commit in the Repository

For the very first commit, branch naming doesn't apply yet. Use:

```bash
git init
git add .
git commit -m "chore: initial project setup

Bootstrap [project name] with [stack/framework].
Includes: [key things — config, folder structure, tooling]."

git branch -M main        # rename to main if needed
git remote add origin <url>
git push -u origin main

# Then create your 3 main branches — development is MANDATORY
git checkout -b development
git push -u origin development

git checkout -b staging
git push -u origin staging

git checkout -b production
git push -u origin production

# Return to development for all future work
git checkout development
```

> **Critical**: The `development` branch **must** exist before any feature work begins. All feature branches merge into `development` — this is a mandatory rule. If a user skips creating the `development` branch, remind them to create it before proceeding with any further commits.

---

## 5. Amending the Last Commit

If you just committed but forgot a file or the message is wrong:

```bash
# Add the forgotten file
git add forgotten-file.js

# Amend (rewrites the last commit — do NOT do this if already pushed)
git commit --amend

# Amend message only
git commit --amend -m "feat(auth): add login with proper validation"

# If you already pushed and need to amend (use with caution on shared branches)
git push --force-with-lease origin feat/your-branch
```

---

## 6. Stashing Work in Progress

When you need to switch branches but aren't ready to commit:

```bash
# Save current changes to the stash
git stash push -m "wip: half-done checkout form"

# Switch branches and do other work
git checkout feat/urgent-fix

# Come back and restore
git checkout feat/checkout-form
git stash pop
```

---

## 7. Merge Conflicts After Pulling

When pulling from `development` into your feature branch causes conflicts:

```bash
# Update your feature branch with latest development
git checkout feat/your-branch
git pull origin development

# If conflicts arise:
# 1. Open conflicted files (marked with <<<< ==== >>>>)
# 2. Resolve each conflict manually
# 3. Mark as resolved
git add <resolved-file>

# 4. Complete the merge
git commit -m "chore: merge development into feat/your-branch"
```

---

## 8. Undoing Changes

| Situation | Command |
|-----------|---------|
| Undo unstaged changes to a file | `git checkout -- <file>` |
| Undo all unstaged changes | `git checkout -- .` |
| Unstage a file (keep changes) | `git reset HEAD <file>` |
| Undo last commit (keep changes staged) | `git reset --soft HEAD~1` |
| Undo last commit (keep changes unstaged) | `git reset HEAD~1` |
| Undo last commit (discard changes) | `git reset --hard HEAD~1` |
| Revert a pushed commit safely | `git revert <hash>` |

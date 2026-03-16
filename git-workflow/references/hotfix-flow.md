# Hotfix Flow Reference

A hotfix is a **critical bug fix that must go directly to production** without waiting for the normal development → staging → production cycle. Use this only when a bug is actively harming users in production.

> **Important**: Hotfix is the **only** branch type that merges into `production`. All other branches merge into `development` — no exceptions. After deploying a hotfix, you **must** backport it to `development` immediately (Phase 2 below is not optional).

---

## When to Use a Hotfix

Use `hotfix/` when all three of these are true:
1. The bug is in **production** right now
2. It is actively causing harm (data loss, payments failing, users locked out, security vulnerability)
3. It **cannot wait** for the next regular release cycle

For everything else — even urgent-feeling bugs — use `fix/` → `development`.

---

## Full Hotfix Sequence

### Phase 1 — Fix and Deploy to Production

```bash
# 1. Always branch from production, not from development
git checkout production
git pull origin production
git checkout -b hotfix/brief-description-of-issue

# 2. Make the fix (keep it minimal — only fix the exact issue)

# 3. Stage and commit
git add .
git commit -m "hotfix(scope): fix brief description

Explain what was broken and exactly what was changed to fix it.
Keep the scope of this commit narrow."

# 4. Push the hotfix branch
git push -u origin hotfix/brief-description-of-issue

# 5. Open a PR: hotfix/* → production
# After review and approval:
git checkout production
git merge --no-ff hotfix/brief-description-of-issue
git tag -a v1.2.1 -m "hotfix: fix payment gateway timeout"
git push origin production --tags
```

### Phase 2 — Backport to Development (MANDATORY — Do Not Skip)

After the hotfix is live on production, **you must** bring the fix back to `development` so it is not lost when the next release is cut. This step is mandatory — skipping it will cause the fix to be missing from future releases.

```bash
# Option A: merge the hotfix branch into development (simplest)
git checkout development
git pull origin development
git merge --no-ff hotfix/brief-description-of-issue
git push origin development

# Option B: cherry-pick (when you only want specific commits)
git checkout development
git pull origin development
git cherry-pick <commit-hash-of-the-fix>
git push origin development

# Clean up
git branch -d hotfix/brief-description-of-issue
git push origin --delete hotfix/brief-description-of-issue
```

### Phase 3 — Update Staging

```bash
git checkout staging
git pull origin staging
git merge --no-ff hotfix/brief-description-of-issue
git push origin staging
```

---

## Hotfix Commit Message Pattern

```
hotfix(<scope>): <what was broken and now fixed>

What was happening in production vs. what should happen.
What was changed to fix it (keep scope minimal).
Any side effects or things to monitor post-deploy.

Closes #N
```

Example:
```
hotfix(auth): prevent session expiry from logging users out mid-upload

Token expiry check ran at request start. Sessions could expire
during long uploads, losing user data. Now refreshes tokens
with less than 5 minutes remaining on each request.

Closes #391
```

---

## Hotfix vs. Fix Decision Guide

| Scenario | Branch | Target | Backport? |
|----------|--------|--------|-----------|
| Login broken in production right now | `hotfix/` | `production` | Yes — must backport to `development` |
| Payment page showing wrong total in prod | `hotfix/` | `production` | Yes — must backport to `development` |
| Security vulnerability in prod | `hotfix/` | `production` | Yes — must backport to `development` |
| Bug found in testing on staging | `fix/` | `development` | N/A — already targets `development` |
| Bug reported by user, not urgent | `fix/` | `development` | N/A — already targets `development` |
| Feature that regressed in dev | `fix/` | `development` | N/A — already targets `development` |

---

## Version Tagging After a Hotfix

```bash
# Patch bump: v2.4.0 becomes v2.4.1
git tag -a v<major>.<minor>.<patch+1> -m "hotfix: <brief description>"
git push origin --tags
```

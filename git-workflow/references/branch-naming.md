# Branch Naming Reference

## Format

```
<prefix>/<descriptive-slug>
```

Both parts are **required**. Never use a bare branch name like `login-fix` or `new-feature`.

---

## Prefix Reference

| Prefix    | Use for                                                      | Default merge target |
|-----------|--------------------------------------------------------------|----------------------|
| `feat/`   | New features, new pages, new API endpoints, new UI           | `development`        |
| `fix/`    | Bug fixes, broken behavior, incorrect output                 | `development`        |
| `hotfix/` | Critical bugs in production that can't wait for dev cycle    | `production`         |
| `chore/`  | Dependency updates, config changes, refactors, cleanup       | `development`        |
| `docs/`   | README, API docs, inline comments, changelogs                | `development`        |
| `ci/`     | GitHub Actions, Dockerfile, build scripts, deploy configs    | `development`        |
| `perf/`   | Performance improvements, query optimization, caching        | `development`        |
| `test/`   | Adding or fixing tests (no production code changes)          | `development`        |
| `style/`  | Formatting, linting fixes, whitespace (no logic change)      | `development`        |
| `revert/` | Reverting a prior commit or set of commits                   | `development`        |

---

## Slug Rules

- **Lowercase only** — no CamelCase, no UPPERCASE
- **Hyphens to separate words** — no underscores, no spaces
- **Max 40 characters total** (including prefix and slash)
- **Descriptive but concise** — a new reader should understand the change at a glance
- **Verb-noun or noun-noun pattern** — leads with the action or subject
- **No ticket numbers by default** — add them only if the team convention requires it (e.g., `feat/JIRA-123-user-auth`)

---

## Good Examples

```
feat/user-authentication
feat/checkout-flow
feat/dark-mode-toggle
feat/email-verification
feat/admin-dashboard

fix/cart-total-calculation
fix/login-redirect-loop
fix/null-pointer-profile-page
fix/broken-image-upload

hotfix/payment-gateway-timeout
hotfix/session-token-expiry
hotfix/critical-sql-injection

chore/upgrade-react-18
chore/remove-deprecated-api-calls
chore/migrate-to-typescript
chore/clean-up-unused-components

docs/api-authentication-guide
docs/deployment-readme
docs/contributing-guide

ci/add-github-actions-deploy
ci/fix-docker-build-cache
ci/add-staging-env-vars

perf/lazy-load-product-images
perf/cache-user-sessions
```

---

## Bad Examples (and why)

| Bad                        | Problem                          | Good alternative           |
|----------------------------|----------------------------------|----------------------------|
| `new-feature`              | No prefix, vague                 | `feat/user-profile`        |
| `fix`                      | No slug at all                   | `fix/login-redirect`       |
| `Feature/UserAuth`         | CamelCase, wrong casing          | `feat/user-auth`           |
| `feat/fixed_login_bug`     | Wrong prefix, uses underscores   | `fix/login-redirect`       |
| `johns-branch`             | Named after person, not work     | `feat/payment-integration` |
| `wip`                      | Meaningless                      | `feat/checkout-wip`        |
| `feat/this-is-a-very-long-branch-name-that-exceeds-forty-characters` | Too long | `feat/checkout-address-form` |
| `HOTFIX-PROD-URGENT`       | All caps, no slug separator      | `hotfix/payment-crash`     |

---

## 3-Branch Merge Strategy

```
feat/*, fix/*, chore/*, docs/*, ci/*, perf/* 
    └──→  development  (integration & dev testing)
              └──→  staging  (QA, UAT, pre-release)
                       └──→  production  (live)

hotfix/*
    └──→  production  (emergency deploy)
              └──→  development  (backport — see hotfix-flow.md)
```

**Never commit directly to `development`, `staging`, or `production`.**
Always work on a short-lived feature branch and merge via pull request.

---

## Deciding the Target Branch

In most cases the target is `development`. Use these exceptions:

- **`staging`** — fix a bug that only manifests in the staging environment and is not present in dev
- **`production`** — only via `hotfix/` branches for critical issues; must be backported

---

## When There's Already a Branch

If the user is already on a descriptive feature branch (`feat/user-auth`), stay on it — don't create another. Only create a new branch if they're on `development`, `staging`, `production`, or `main`.

If they're on a bad branch name (e.g., `test` or `johns-branch`), gently suggest renaming:
```bash
git branch -m johns-branch feat/payment-integration
git push origin -u feat/payment-integration
git push origin --delete johns-branch
```

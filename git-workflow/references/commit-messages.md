# Commit Message Reference

This skill uses the [Conventional Commits](https://www.conventionalcommits.org/) specification.
It is machine-readable, generates clean changelogs, and signals intent clearly to reviewers.

---

## Full Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

Only `<type>` and `<subject>` are required. Body and footer are optional but valuable for non-trivial changes.

---

## Type Reference

| Type       | Use for                                                                 |
|------------|-------------------------------------------------------------------------|
| `feat`     | A new feature, capability, page, or API endpoint                        |
| `fix`      | A bug fix — something was broken, now it works                          |
| `hotfix`   | Emergency fix deployed directly to production                           |
| `chore`    | Maintenance — deps, config, tooling, build scripts, no logic change     |
| `refactor` | Code restructure with no external behavior change                       |
| `docs`     | Documentation only — README, comments, changelogs, guides               |
| `style`    | Formatting, whitespace, linting — zero logic change                     |
| `test`     | Adding, fixing, or reorganizing tests — no production code              |
| `ci`       | Changes to CI/CD — GitHub Actions, Dockerfile, deploy scripts           |
| `perf`     | Performance improvement — caching, query optimization, lazy loading     |
| `revert`   | Reverting a previous commit                                             |

---

## Scope

The scope is the **subsystem, module, or area** the change affects. It goes in parentheses after the type.

- Keep it short: one word or a short hyphenated name
- Use the feature area, not the file name
- Omit if the change is truly cross-cutting

Good scopes: `auth`, `cart`, `api`, `payments`, `profile`, `db`, `ui`, `nav`, `config`, `jobs`, `email`

Bad scopes: `UserAuthenticationService.js`, `components`, `utils`, `stuff`

---

## Subject Line Rules

- **Imperative mood**: "add" not "added", "fix" not "fixes", "remove" not "removed"
- **Max 72 characters** — reviewers and git log truncate beyond this
- **No trailing period**
- **Lowercase after the colon** — `feat(auth): add login` not `feat(auth): Add Login`
- **Specific and descriptive** — avoid vague words like "update", "change", "misc", "various"

---

## Body Rules

Write a body when the subject alone does not tell the full story. Explain:
- **What** changed (more detail than the subject)
- **Why** it was necessary (what problem it solves)
- **What the impact is** (side effects, trade-offs, what to watch for)

Do NOT explain how — the code does that.

- Wrap lines at 72 characters
- Use plain paragraphs; bullet points are fine for lists of changes
- Separate from subject with one blank line

---

## Footer Rules

Use the footer for:
- `Closes #N` or `Fixes #N` — auto-closes GitHub/GitLab issues
- `Refs #N` — references without closing
- `BREAKING CHANGE: <description>` — signals a breaking API change
- `Co-authored-by: Name <email>` — for pair commits

---

## Real-World Examples

### Simple feature
```
feat(auth): add email verification on signup

Users must now verify their email before accessing the dashboard.
Verification link expires after 24 hours.

Closes #88
```

### Bug fix with context
```
fix(cart): correct subtotal when percentage discount applied

Discount was being applied after tax calculation, resulting in
incorrect totals displayed at checkout. Fixed ordering so discount
applies to pre-tax subtotal only.

Closes #104
```

### Hotfix (production emergency)
```
hotfix(payments): add retry logic for Stripe timeout errors

Silent payment failures occurring on slow connections. Added
3-attempt exponential backoff (500ms, 1s, 2s) with user feedback
on each retry. Failures after 3 attempts surface a clear error.

BREAKING CHANGE: PaymentService.charge() is now async
Closes #217
```

### Refactor (no behavior change)
```
refactor(api): extract auth middleware into standalone module

Moved JWT validation logic out of route handlers and into
/middleware/auth.js. No behavior change — all routes continue
to work identically. Simplifies adding auth to new routes.
```

### Chore (dependency update)
```
chore(deps): upgrade React from 17 to 18

Migrated to React 18's createRoot API. Updated all render calls.
Enables future use of concurrent features (Suspense, transitions).
```

### Breaking change with migration note
```
feat(api): require API version header on all requests

All requests must now include `X-API-Version: 2` header.
Requests without the header return 400 Bad Request.

BREAKING CHANGE: clients without the version header will fail.
Migration: add `X-API-Version: 2` to all API calls.
```

### Docs only
```
docs(readme): update local development setup instructions

Added step for configuring .env.local, clarified Node version
requirement (18+), and added troubleshooting for M1 Macs.
```

### Revert
```
revert: revert "feat(dark-mode): add system preference detection"

This reverts commit a3f8d21. The system preference detection
is causing a flash of unstyled content on first load. Will
revisit after the hydration refactor in #301.
```

---

## Checklist Before Committing

- [ ] Subject is in imperative mood
- [ ] Subject is under 72 characters
- [ ] No trailing period on subject
- [ ] Type matches the actual nature of the change
- [ ] Scope is meaningful and concise (or omitted)
- [ ] Body explains what and why (not how)
- [ ] Breaking changes have a `BREAKING CHANGE:` footer
- [ ] Relevant issue numbers are referenced in footer

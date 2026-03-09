# Changelog Format Reference

This skill follows the [Keep a Changelog](https://keepachangelog.com/) specification.
It is human-readable, groups changes by type, and pairs naturally with Conventional Commits.

---

## File Location

The changelog lives at the **repository root** as `CHANGELOG.md`. If it doesn't exist, create it.

---

## Full Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- New feature description (#42)

### Fixed
- Bug fix description (#51)

## [1.2.0] - 2026-02-15

### Added
- Previous release features...

### Changed
- Previous release changes...
```

---

## Sections

Each version or `[Unreleased]` block uses these subsections. Only include subsections that have entries — omit empty ones.

| Section        | Use for                                                          |
|----------------|------------------------------------------------------------------|
| `### Added`    | New features, capabilities, endpoints, pages                     |
| `### Changed`  | Changes to existing functionality, refactors, dep upgrades, docs |
| `### Deprecated` | Features that will be removed in a future release             |
| `### Removed`  | Features, deps, or files that were deleted                       |
| `### Fixed`    | Bug fixes — something was broken, now it works                   |
| `### Security` | Vulnerability fixes or security-related changes                  |

---

## Mapping Commit Types to Sections

| Commit type                     | Changelog section   | Include? |
|---------------------------------|---------------------|----------|
| `feat`                          | `### Added`         | Yes      |
| `fix`, `hotfix`                 | `### Fixed`         | Yes      |
| `refactor`, `perf`              | `### Changed`       | Yes      |
| `chore` (dep upgrade, config)   | `### Changed`       | Yes      |
| `chore` (dep removal)           | `### Removed`       | Yes      |
| `docs`                          | `### Changed`       | Yes      |
| `revert`                        | `### Removed`       | Yes      |
| `style`, `test`, `ci`           | —                   | No — no user-facing impact |

---

## Entry Rules

- **User perspective** — describe the effect on the user, not the code change
- **Past tense verb** — start each entry with "Added", "Fixed", "Removed", "Updated", "Improved"
- **One bullet per logical change** — don't combine unrelated items
- **Reference issues/PRs** — append `(#42)` or `(#42, #51)` at the end when applicable
- **Concise** — one or two sentences max per entry
- **No code details** — the commit message has the technical details; the changelog is for humans

---

## Good Examples

### Feature
```markdown
### Added
- Added email verification step during user signup (#88)
- Added dark mode toggle to user preferences page
```

### Bug fix
```markdown
### Fixed
- Fixed incorrect subtotal display when percentage discount applied at checkout (#104)
- Fixed login redirect loop when session cookie expired
```

### Refactor / performance
```markdown
### Changed
- Improved product image loading speed with lazy loading and CDN caching
- Reorganized auth middleware into standalone module for easier reuse
```

### Dependency update
```markdown
### Changed
- Updated React from 17 to 18 with createRoot API migration
```

### Removal
```markdown
### Removed
- Removed deprecated v1 API endpoints (replaced by v2 in release 1.3.0)
```

### Security
```markdown
### Security
- Fixed SQL injection vulnerability in search endpoint (#217)
```

---

## Bad Examples (and why)

| Bad entry | Problem | Good alternative |
|-----------|---------|------------------|
| "Refactored auth module" | Too vague, code-focused | "Reorganized auth middleware for easier reuse" |
| "Updated helpers.js" | File name, not user impact | "Fixed date formatting in order confirmation emails" |
| "Various bug fixes" | Not specific | List each fix as a separate bullet |
| "Changed the thing" | Meaningless | Describe what actually changed for the user |
| "feat(auth): add login" | Commit message format, not changelog | "Added user login with email and password" |

---

## The [Unreleased] Section

All new changelog entries go under `## [Unreleased]` until a release is cut. When releasing:

1. Replace `## [Unreleased]` with `## [X.Y.Z] - YYYY-MM-DD`
2. Add a fresh empty `## [Unreleased]` section above it
3. Determine version bump:
   - **Major** — breaking changes
   - **Minor** — new features (backwards-compatible)
   - **Patch** — bug fixes only

---

## Creating a New CHANGELOG.md

If the project has no changelog, create one at the repo root:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- <your first entry here>
```

---

## Checklist Before Committing

- [ ] Entry is under `## [Unreleased]`
- [ ] Correct subsection (`Added`, `Fixed`, `Changed`, etc.)
- [ ] Written from user perspective, not code perspective
- [ ] Starts with past-tense verb
- [ ] Issue/PR numbers referenced where applicable
- [ ] No duplicate entries for the same change
- [ ] Empty subsections removed

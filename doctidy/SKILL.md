# doctidy

> Like `tidy` for HTML — but for your entire docs folder.  
> Scans your codebase, understands it, and reorganizes your markdown into a clean, logical, non-redundant structure.

---

## When to Trigger
- "tidy my docs"
- "run doctidy"
- "organize my docs"
- "clean up the docs folder"
- "restructure my documentation"

---

## Execution Steps

### Step 1 — Scan the Codebase
```bash
# High-level project structure
find . -maxdepth 3 \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/dist/*' -not -path '*/.next/*' \
  -not -path '*/build/*' -not -path '*/__pycache__/*' \
  | sort

# Identify tech stack
cat package.json 2>/dev/null || cat pom.xml 2>/dev/null || \
cat build.gradle 2>/dev/null || cat pyproject.toml 2>/dev/null

# Read ALL existing docs
for f in $(find ./docs -name "*.md"); do
  echo "===== $f ====="; cat "$f"; echo ""
done
```

### Step 2 — Analyze & Plan

1. **Tech stack** — language, framework, deployment
2. **Project type** — API, web app, CLI, library, monorepo
3. **Each doc's purpose** — one-line summary per file
4. **Redundancies** — overlapping content across files
5. **Dead files** — temp, scratch, zero-value docs
6. **Gaps** — missing docs based on what the codebase actually does

### Step 3 — Target Structure
```
docs/
├── README.md
├── getting-started/
│   ├── installation.md
│   ├── environment.md
│   └── quickstart.md
├── architecture/
│   ├── overview.md
│   ├── tech-stack.md
│   ├── data-structures.md
│   ├── api-contract.md
│   └── diagrams.md
├── guides/
│   ├── development.md
│   ├── testing.md
│   ├── deployment.md
│   └── troubleshooting.md
├── reference/
│   ├── api.md
│   ├── changelog.md
│   └── collections/
└── planning/
    └── archive/
```

### Step 4 — Reorganize

| Action | When |
|--------|------|
| ✅ Move | Correct content, wrong location |
| ✅ Merge | Redundant files with overlapping content |
| ✅ Rename | Needs `lowercase-hyphenated.md` convention |
| 📦 Archive | Temp, scratch, duplicate → `docs/_archive/` |

Always use `git mv` to preserve history.

### Step 5 — Merge Redundant Content

Read both files, synthesize unique content, write one clean result. Never just concatenate — rewrite for clarity.

### Step 6 — Write docs/README.md

- One-paragraph project description inferred from codebase
- Full TOC with relative links
- Quick-start snippet

### Step 7 — Report
```
## doctidy complete ✓

### New Structure
[tree docs/]

### Merged
### Archived
### Renamed & Moved
### Created
```

---

## Quality Rules

- No `ALL_CAPS` filenames → `lowercase-hyphenated.md`
- No temp/draft files in final structure
- Every file must add unique value
- Max depth: 2 levels (`docs/category/file.md`)
- Non-markdown files → `docs/reference/collections/`
- Always `git mv` inside git repos
- Never hard-delete — archive when uncertain

## Safety Rules

- Show dry-run before any destructive action
- Default: move to `docs/_archive/`, not `rm`
- Run `git status` after to confirm clean state
- Never touch files outside `docs/` unless asked

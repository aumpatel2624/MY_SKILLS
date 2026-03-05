# Claude Code & Antigravity Skills

A collection of reusable skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Antigravity](https://antigravity.dev). Skills are prompt-driven workflows that extend your AI assistant with repeatable, structured capabilities.

## Available Skills

| Skill | Description | Trigger phrases |
|-------|-------------|-----------------|
| **doctidy** | Scans your codebase and reorganizes your markdown docs into a clean, logical, non-redundant structure. | `run doctidy`, `tidy my docs`, `organize my docs` |
| **git-workflow** | End-to-end git assistant: diff analysis, branch naming, commit messages, and copy-paste-ready commands. Built for a 3-branch repo (development/staging/production). | `commit my changes`, `create a branch`, `write a commit message`, `help me with git` |

## Installation

### Claude Code

1. **Clone this repo** into your Claude Code skills directory:

   ```bash
   git clone <repo-url> ~/.claude/skills
   ```

   Or copy individual skill folders into `~/.claude/skills/`.

2. **Register skills in your `CLAUDE.md`** (global or per-project):

   Open `~/.claude/CLAUDE.md` (create it if it doesn't exist) and add trigger instructions for each skill:

   ```markdown
   ## Skills
   When the user says "run doctidy" or "tidy my docs", read and follow the instructions in ~/.claude/skills/doctidy/SKILL.md before doing anything else.

   When the user asks for help with git (committing, branching, commit messages, pushing code), read and follow the instructions in ~/.claude/skills/git-workflow/SKILL.md before doing anything else.
   ```

3. **Use it.** Start a Claude Code session and say any of the trigger phrases.

### Antigravity

1. **Clone this repo** into your preferred location:

   ```bash
   git clone <repo-url> ~/skills
   ```

2. **Register skills in your Antigravity instructions file.** Add the same trigger-to-SKILL.md mappings shown above to your Antigravity system prompt or instructions configuration, adjusting paths as needed.

3. **Use it.** Trigger any skill by using its trigger phrases in your Antigravity session.

## Skill Structure

Each skill follows this layout:

```
skill-name/
├── SKILL.md              # Main instructions (entry point)
├── scripts/              # Helper scripts (optional)
└── references/           # Detailed reference docs (optional)
```

- **`SKILL.md`** — The core file. Contains step-by-step instructions that the AI follows when the skill is triggered.
- **`scripts/`** — Shell scripts or utilities the skill may invoke.
- **`references/`** — Supplementary docs loaded on-demand for deeper guidance.

## Creating Your Own Skills

1. Create a new folder under `skills/`:
   ```bash
   mkdir skills/my-skill
   ```

2. Write a `SKILL.md` with:
   - **Trigger phrases** — when should this skill activate?
   - **Step-by-step instructions** — what should the AI do?
   - **Quality/safety rules** — any guardrails or constraints.

3. Register it in your `CLAUDE.md` with a trigger-to-path mapping.

## Tips

- Keep `SKILL.md` files self-contained — the AI reads them at trigger time.
- Use `references/` for detailed content that should only be loaded when needed (keeps context lean).
- Skills work best when they have clear trigger phrases and unambiguous step-by-step instructions.
- You can scope skills globally (`~/.claude/CLAUDE.md`) or per-project (`.claude/CLAUDE.md` in the repo root).

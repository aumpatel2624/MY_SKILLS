# Claude Code & Antigravity Skills

A collection of reusable skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Antigravity](https://antigravity.dev). Skills are prompt-driven workflows that extend your AI assistant with repeatable, structured capabilities.

## Available Skills

| Skill | Description | Trigger phrases |
|-------|-------------|-----------------|
| **doctidy** | Scans your codebase and reorganizes your markdown docs into a clean, logical, non-redundant structure. | `run doctidy`, `tidy my docs`, `organize my docs` |
| **git-workflow** | End-to-end git assistant: diff analysis, branch naming, commit messages, changelog updates, and copy-paste-ready commands. Built for a 3-branch repo (development/staging/production). | `commit my changes`, `create a branch`, `write a commit message`, `help me with git`, `update the changelog` |

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
├── evals/                # Eval test cases (YAML)
│   ├── 01-basic-test.yaml
│   └── 02-edge-case.yaml
├── scripts/              # Helper scripts (optional)
└── references/           # Detailed reference docs (optional)
```

- **`SKILL.md`** — The core file. Contains step-by-step instructions that the AI follows when the skill is triggered. Should include YAML frontmatter with `name` and `description` for reliable triggering.
- **`evals/`** — Test cases that verify the skill works as expected. See [Evals Framework](#evals-framework).
- **`scripts/`** — Shell scripts or utilities the skill may invoke.
- **`references/`** — Supplementary docs loaded on-demand for deeper guidance.

## Evals Framework

Every skill includes evals (tests) that verify Claude produces the right output for a given prompt. The framework supports:

| Capability | Command | Description |
|---|---|---|
| **Run evals** | `bash evals/run-evals.sh <skill>` | Run all evals for a skill, report pass/fail |
| **Benchmark** | `bash evals/benchmark.sh <skill>` | Track pass rate, elapsed time, and token usage over time |
| **A/B compare** | `bash evals/comparator.sh <skill>` | Compare skill vs. bare model (or two skill versions) |
| **Outgrown check** | `bash evals/outgrown-check.sh <skill>` | Detect if the base model has absorbed the skill |

```bash
# Run all evals (requires claude CLI; use DRY_RUN=1 for structure validation)
bash evals/run-evals.sh doctidy
bash evals/run-evals.sh git-workflow

# Benchmark and save results to evals/results/
bash evals/benchmark.sh git-workflow

# A/B test: does the skill actually help?
bash evals/comparator.sh doctidy

# Has the model outgrown this skill?
bash evals/outgrown-check.sh doctidy
```

Evals use a simple YAML format — see [`evals/README.md`](evals/README.md) for the full spec.

### Methodology

The recommended workflow for skill development:

1. **Write evals** — define test prompts and expected outcomes
2. **Benchmark** — measure pass rate, time, and tokens
3. **A/B test** — compare skill vs. no skill to prove value
4. **Optimize descriptions** — tune frontmatter for reliable triggering
5. **Iterate** — re-run evals after changes to catch regressions

## Creating Your Own Skills

1. Create a new folder under the repo root:
   ```bash
   mkdir my-skill
   ```

2. Write a `SKILL.md` with:
   - **YAML frontmatter** — `name` and `description` with trigger phrases for reliable activation.
   - **Trigger phrases** — when should this skill activate?
   - **Step-by-step instructions** — what should the AI do?
   - **Quality/safety rules** — any guardrails or constraints.

3. Add evals in `my-skill/evals/`:
   ```yaml
   name: basic-trigger
   description: Skill activates on trigger phrase
   type: capability  # or encoded_preference
   prompt: "your trigger phrase here"
   expected:
     must_contain:
       - "expected output string"
     must_not_contain:
       - "unwanted output string"
   tags: [trigger, basic]
   ```

4. Register it in your `CLAUDE.md` with a trigger-to-path mapping.

5. Run evals to verify: `bash evals/run-evals.sh my-skill`

## Tips

- Keep `SKILL.md` files self-contained — the AI reads them at trigger time.
- Always include YAML frontmatter with a detailed `description` — this helps with trigger reliability.
- Use `references/` for detailed content that should only be loaded when needed (keeps context lean).
- Write evals for every skill — they catch regressions and prove the skill adds value.
- Run `bash evals/outgrown-check.sh <skill>` after model updates to check if a skill is still needed.
- You can scope skills globally (`~/.claude/CLAUDE.md`) or per-project (`.claude/CLAUDE.md` in the repo root).

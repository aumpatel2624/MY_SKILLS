# Contributing

Thanks for your interest in contributing to this skills collection! This guide covers how to add new skills, improve existing ones, and submit your changes.

## Getting Started

1. Fork and clone the repo
2. Create a branch from `main`:
   ```bash
   git checkout -b feat/your-skill-name
   ```
3. Make your changes
4. Submit a pull request

## Adding a New Skill

1. Create a folder under the repo root:
   ```bash
   mkdir my-skill
   ```

2. Add a `SKILL.md` at the root of your skill folder. This is the entry point that the AI reads at trigger time. It should include:
   - **Trigger phrases** -- when should this skill activate?
   - **Step-by-step execution instructions** -- what should the AI do?
   - **Quality/safety rules** -- any guardrails or constraints.

3. Optionally add supporting directories:
   ```
   my-skill/
   ├── SKILL.md              # Required: main instructions
   ├── scripts/              # Optional: helper scripts
   └── references/           # Optional: detailed reference docs
   ```

4. Update `README.md` to add your skill to the "Available Skills" table.

5. Update `CHANGELOG.md` with your addition under the `[Unreleased]` section.

## Improving an Existing Skill

- Read the existing `SKILL.md` and any reference files before making changes.
- Keep changes focused -- one PR per concern.
- If you're changing behavior, update the relevant reference docs too.

## Skill Guidelines

- **Keep `SKILL.md` self-contained.** The AI reads it at trigger time with no prior context.
- **Use `references/` for detail.** Long specs, examples, and edge cases belong in reference files that get loaded on demand.
- **Filenames:** Use `lowercase-hyphenated.md` for all markdown files.
- **Max depth:** Skills should be at most 2 levels deep (`skill/references/file.md`).
- **Scripts:** Include cross-platform variants (`.sh`, `.bat`, `.ps1`) when possible, as demonstrated in `git-workflow/scripts/`.

## Commit Messages

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <imperative summary>
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`

Examples:
- `feat(doctidy): add support for RST files`
- `docs(readme): add installation instructions for Antigravity`
- `fix(git-workflow): correct hotfix merge target`

## Pull Requests

- Target the `main` branch.
- Keep PRs small and focused.
- Include a short description of what changed and why.
- Make sure the README and CHANGELOG are updated if applicable.

## Code of Conduct

Be kind, constructive, and respectful. We're all here to make better tools.

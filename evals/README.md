# Evals Framework

A testing and benchmarking framework for Claude Code skills. Brings software engineering rigor — **write evals → benchmark → A/B test → optimize descriptions → iterate** — to skill authoring.

## Quick Start

```bash
# Run all evals for a skill
bash evals/run-evals.sh doctidy

# Run a single eval
bash evals/run-evals.sh git-workflow commit-feature-change

# Benchmark mode (tracks pass rate, tokens, time)
bash evals/benchmark.sh doctidy

# A/B compare skill vs. no skill (or two versions)
bash evals/comparator.sh git-workflow

# Check if the base model has outgrown a skill
bash evals/outgrown-check.sh doctidy
```

## Concepts

### Eval Files

Each skill has an `evals/` directory containing YAML eval definitions:

```
skill-name/
├── SKILL.md
├── evals/
│   ├── 01-basic-trigger.yaml
│   ├── 02-edge-case.yaml
│   └── fixtures/          # test files referenced by evals
│       └── sample-repo/
```

### Eval YAML Format

```yaml
name: descriptive-test-name
description: What this eval tests
type: capability | preference   # skill category

prompt: "The user message that triggers the skill"

# Optional: files to set up before running
fixtures:
  - source: fixtures/sample-repo/
    dest: /tmp/eval-workspace/

# What a good result looks like
expected:
  must_contain:
    - "string that must appear in output"
  must_not_contain:
    - "string that should NOT appear"
  must_match:
    - "regex pattern to match"
  exit_code: 0

# Optional: tags for filtering
tags: [trigger, basic, regression]
```

### Benchmark Mode

Runs all evals for a skill and records:
- **Pass rate** — percentage of evals that pass
- **Elapsed time** — per-eval and total
- **Token usage** — input/output tokens per eval (when available)
- **Model version** — for tracking across updates

Results are saved to `evals/results/` as timestamped JSON files for trend analysis.

### A/B Comparator

Runs evals twice — once with the skill loaded, once without (or with an alternate version) — and compares outputs using a blind judge prompt. Useful for:
- Validating that a skill actually improves output quality
- Comparing two versions of a skill after edits
- Detecting when a skill is no longer needed

### Model-Outgrown Detection

Runs evals **without** the skill loaded. If the base model passes most evals on its own, the skill's techniques may have been absorbed into the model's default behavior — signaling the skill may no longer be necessary.

## Adding Evals to a Skill

1. Create `your-skill/evals/` directory
2. Add YAML eval files (see format above)
3. Optionally add `fixtures/` for test files
4. Run `bash evals/run-evals.sh your-skill` to verify

## Results & Regression Tracking

Benchmark results are saved to `evals/results/`:

```
evals/results/
├── doctidy-2026-03-10T12:00:00Z.json
├── git-workflow-2026-03-10T12:00:00Z.json
└── ...
```

Compare results across runs to catch regressions after model updates or skill edits.

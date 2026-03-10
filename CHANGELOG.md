# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **evals framework**: eval runner, benchmark mode, A/B comparator, and model-outgrown detection with shared utilities and YAML-based eval definitions
- **doctidy** evals: 7 test cases covering trigger recognition, codebase scanning, target structure, safety/archival, merge behavior, report output, and naming conventions
- **git-workflow** evals: 10 test cases covering trigger recognition, branch naming, conventional commits, imperative mood, changelog updates, copy-paste commands, hotfix detection, three-branch model, summary output, and changelog skip logic
- **doctidy** skill: added YAML frontmatter with `name` and `description` for reliable trigger matching
- **git-workflow** skill: added CHANGELOG.md update step to the workflow (Step 4) with commit-type-to-section mapping and skip logic for non-user-facing changes
- **git-workflow** skill: added `references/changelog-format.md` reference doc with full Keep a Changelog spec, examples, and checklist

### Changed

- Updated README with evals framework documentation, methodology section, and revised skill creation guide
- Updated CONTRIBUTING guide to require evals for new skills and include frontmatter guidelines

## [1.0.0] - 2026-03-05

### Added

- **doctidy** skill: scans your codebase and reorganizes markdown docs into a clean, logical, non-redundant structure. Trigger with "run doctidy", "tidy my docs", or "organize my docs".
- **git-workflow** skill: end-to-end git assistant covering diff analysis, branch naming, commit messages, and copy-paste-ready commands. Built for a 3-branch repo (development/staging/production).
  - Cross-platform analysis scripts (`.sh`, `.bat`, `.ps1`)
  - Reference docs for branch naming, commit messages, hotfix flows, and edge cases
- Project README with installation instructions for Claude Code and Antigravity

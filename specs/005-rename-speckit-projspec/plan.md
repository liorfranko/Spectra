# Implementation Plan: Rename SpecKit to ProjSpec

**Branch**: `005-rename-speckit-projspec` | **Date**: 2026-01-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-rename-speckit-projspec/spec.md`

## Summary

Rename all "speckit" references to "projspec" throughout the Claude Code plugin system. This is a pure refactoring task involving file renames, directory restructuring, and content updates across ~49 files with 320+ occurrences. No functional changes—only naming consistency.

## Technical Context

**Language/Version**: Bash 5.x (scripts), Markdown (commands/agents/skills)
**Primary Dependencies**: Claude Code plugin system, Git
**Storage**: N/A (file-based configuration only)
**Testing**: Manual verification via command execution
**Target Platform**: macOS/Linux with Claude Code CLI
**Project Type**: Plugin/configuration refactoring
**Performance Goals**: N/A (no runtime performance impact)
**Constraints**: All commands must remain functional after rename
**Scale/Scope**: ~49 files, 320+ content references, 3 directory renames

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: PASS (Template constitution detected—no specific gates defined)

The constitution file contains placeholder content only. This feature is a straightforward rename/refactor with:
- No new architectural decisions
- No new dependencies
- No new patterns or abstractions
- No runtime behavior changes

## Project Structure

### Documentation (this feature)

```text
specs/005-rename-speckit-projspec/
├── plan.md              # This file
├── research.md          # Phase 0 output (minimal—no research needed)
├── data-model.md        # Phase 1 output (file inventory)
├── quickstart.md        # Phase 1 output (verification steps)
├── contracts/           # Phase 1 output (rename mapping)
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

**Current Structure (Before):**
```text
speckit/
├── .claude-plugin/
│   └── marketplace.json      # name: "speckit"
├── plugins/
│   └── speckit/
│       ├── .claude-plugin/
│       │   └── plugin.json   # name: "speckit"
│       ├── commands/         # 14 command files
│       ├── agents/           # 6 agent files
│       ├── templates/        # 5 template files (reference /speckit.*)
│       ├── scripts/          # 6 bash scripts (speckit comments)
│       ├── hooks/            # hooks.json
│       └── memory/           # constitution.md, context.md
├── README.md                 # speckit references
├── TESTING.md                # speckit references
└── VERIFICATION.md           # speckit references

.claude/commands/
├── speckit.analyze.md
├── speckit.checklist.md
├── speckit.clarify.md
├── speckit.constitution.md
├── speckit.implement.md
├── speckit.learn.md
├── speckit.plan.md
├── speckit.review-pr.md
├── speckit.specify.md
├── speckit.tasks.md
├── speckit.taskstoissues.md
├── speckit.checkpoint.md
```

**Target Structure (After):**
```text
projspec/
├── .claude-plugin/
│   └── marketplace.json      # name: "projspec"
├── plugins/
│   └── projspec/
│       ├── .claude-plugin/
│       │   └── plugin.json   # name: "projspec"
│       ├── commands/         # 14 command files (updated content)
│       ├── agents/           # 6 agent files
│       ├── templates/        # 5 template files (reference /projspec.*)
│       ├── scripts/          # 6 bash scripts (projspec comments)
│       ├── hooks/            # hooks.json
│       └── memory/           # constitution.md, context.md
├── README.md                 # projspec references
├── TESTING.md                # projspec references
└── VERIFICATION.md           # projspec references

.claude/commands/
├── projspec.analyze.md
├── projspec.checklist.md
├── projspec.clarify.md
├── projspec.constitution.md
├── projspec.implement.md
├── projspec.learn.md
├── projspec.plan.md
├── projspec.review-pr.md
├── projspec.specify.md
├── projspec.tasks.md
├── projspec.taskstoissues.md
├── projspec.checkpoint.md
```

**Structure Decision**: Plugin directory rename from `speckit/` to `projspec/` with nested plugin rename from `plugins/speckit/` to `plugins/projspec/`. All `.claude/commands/` files renamed with `projspec.` prefix.

## Complexity Tracking

> No violations—this is a straightforward rename operation with no new complexity.

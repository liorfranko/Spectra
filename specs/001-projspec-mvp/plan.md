# Implementation Plan: ProjSpec MVP

**Branch**: `001-projspec-mvp` | **Date**: 2026-01-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-projspec-mvp/spec.md`

## Summary

ProjSpec is a spec-driven development workflow orchestrator for Claude Code. The MVP provides a minimal Python CLI for initialization and status reporting, combined with Claude Code commands that contain the workflow logic. Each spec runs in an isolated git worktree with state persisted in YAML files. The system guides developers through phases (new → spec → plan → tasks → implement → review → archive) with context injection between tasks.

## Technical Context

**Language/Version**: Python 3.11+
**Primary Dependencies**: pydantic, pyyaml, rich, pytest
**Storage**: YAML files (state.yaml, config.yaml, workflow.yaml) - no database
**Testing**: pytest with unit, integration, and E2E tests (E2E uses `claude -p`)
**Target Platform**: CLI tool for macOS/Linux (Windows support optional)
**Project Type**: Single project - Python package + Claude Code plugin
**Performance Goals**: Worktree creation <30 seconds, context loading <5 seconds
**Constraints**: Must work offline (except Claude Code commands), minimal dependencies
**Scale/Scope**: Single developer workflow, 1-10 concurrent specs per project

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Note**: Project constitution is not yet customized. Proceeding with general best practices:

| Gate | Status | Notes |
|------|--------|-------|
| Library-First | PASS | projspec is a standalone installable package |
| CLI Interface | PASS | CLI with init/status commands, text I/O |
| Test-First | PENDING | Tests will be written before implementation |
| Simplicity | PASS | Minimal Python, logic in Claude Code commands |

## Project Structure

### Documentation (this feature)

```text
specs/001-projspec-mvp/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── state-schema.yaml
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
src/
└── projspec/
    ├── __init__.py      # Package metadata, version
    ├── cli.py           # Click/argparse CLI: init, status
    ├── models.py        # Pydantic models: SpecState, TaskState, Config
    └── state.py         # State loading utilities

tests/
├── unit/
│   ├── test_models.py   # Pydantic model validation
│   └── test_state.py    # State loading/saving
├── integration/
│   └── test_cli.py      # CLI command integration
└── e2e/
    ├── runner.py        # ClaudeRunner for `claude -p`
    └── test_workflow.py # Full workflow E2E tests

.claude/
└── plugins/
    └── projspec/
        ├── plugin.json          # Plugin manifest
        └── commands/
            ├── init.md          # /projspec.init
            ├── status.md        # /projspec.status
            ├── new.md           # /projspec.new
            ├── spec.md          # /projspec.spec
            ├── plan.md          # /projspec.plan
            ├── tasks.md         # /projspec.tasks
            ├── implement.md     # /projspec.implement
            ├── review.md        # /projspec.review
            ├── resume.md        # /projspec.resume
            ├── next.md          # /projspec.next
            └── archive.md       # /projspec.archive

pyproject.toml           # Package configuration (uv)
```

**Structure Decision**: Single project layout with src/ for Python package and .claude/plugins/ for Claude Code commands. This keeps the minimal Python CLI separate from the prompt-driven workflow logic.

## Component Architecture

### 1. Python CLI (Minimal)

The Python CLI handles only bootstrap and reporting:

```
projspec init    → Creates .projspec/ structure
projspec status  → Displays active specs with progress
```

All workflow logic lives in Claude Code commands.

### 2. Claude Code Plugin

Commands are markdown files that guide Claude through phases:

| Command | Purpose | Key Actions |
|---------|---------|-------------|
| `/projspec.init` | Initialize | Run `projspec init`, show next steps |
| `/projspec.new <name>` | Create spec | Generate ID, create worktree, create state.yaml |
| `/projspec.spec` | Define spec | Read brief.md, create spec.md, update phase |
| `/projspec.plan` | Create plan | Read spec.md, create plan.md, update phase |
| `/projspec.tasks` | Generate tasks | Read plan.md, add tasks to state.yaml |
| `/projspec.implement` | Execute task | Find next task, load context, guide implementation |
| `/projspec.review` | Review impl | Compare spec vs implementation, generate report |
| `/projspec.resume` | Continue work | Find current state, continue appropriate phase |
| `/projspec.archive` | Complete spec | Merge to main, cleanup worktree |

### 3. State Management

State flows through YAML files:

```
User → Claude Command → Read state.yaml → Execute phase → Write state.yaml
```

State is always persisted immediately (implicit checkpointing).

### 4. Git Worktree Integration

Each spec gets isolated worktree:

```
main branch (project root)
├── worktrees/
│   └── spec-{id}-{name}/   # Isolated worktree
└── .projspec/
    └── specs/active/{id}/   # Spec metadata
```

## Complexity Tracking

No constitution violations to justify - design follows minimal Python + Claude-driven principles from PRD.

## Implementation Approach

### Build Order

1. **Python Foundation** (P1)
   - pyproject.toml with dependencies
   - Pydantic models for state/config
   - State loading utilities
   - CLI with init/status commands

2. **Claude Code Plugin Structure** (P1)
   - plugin.json manifest
   - Default phase templates
   - Commands: init, status, new

3. **Core Workflow Commands** (P1)
   - Commands: spec, plan, tasks
   - State transitions
   - Phase validation

4. **Implementation Commands** (P1)
   - Command: implement
   - Task dependency resolution
   - Context injection
   - Summary generation

5. **Lifecycle Commands** (P2)
   - Commands: resume, next, review, archive
   - Worktree cleanup
   - Branch merging

6. **Testing** (Throughout)
   - Unit tests for models/state
   - Integration tests for CLI
   - E2E tests using ClaudeRunner

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Git worktree complexity | Use simple git commands, handle errors gracefully |
| Claude -p for E2E tests | Tests are optional, manual testing fallback |
| State corruption | Validate YAML on read, atomic writes |
| Context token limits | Keep summaries concise, load only relevant files |

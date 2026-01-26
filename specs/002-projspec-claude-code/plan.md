# Implementation Plan: ProjSpec - Spec-Driven Development Toolkit for Claude Code

**Branch**: `002-projspec-claude-code` | **Date**: 2026-01-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-projspec-claude-code/spec.md`

## Summary

ProjSpec is a clean reimplementation of GitHub's spec-kit for Mac/Linux and Claude Code only. The system provides spec-driven development workflow through:
- A Python CLI (`projspec`) for initialization and status commands
- Bash scripts for feature management, worktree creation, and context updates
- Markdown templates for specifications, plans, and tasks
- Command prompt templates (in `.specify/templates/commands/`) for Claude Code workflows
- **Git worktrees for complete feature isolation** (each feature gets its own working directory)

The goal is full spec-kit workflow compatibility with cleaner, more modular code that serves as a foundation for future experimentation.

**Note**: No Claude Code plugin is included. Commands are implemented as prompt templates that can be loaded into Claude Code sessions via the Read tool or copied directly.

**Key Enhancement**: Unlike basic branching, ProjSpec creates a dedicated git worktree for each feature. This provides:
- Complete filesystem isolation between features
- Ability to work on multiple features simultaneously
- No stashing/switching overhead
- Clean separation of in-progress work

## Technical Context

**Language/Version**: Python 3.11+ (CLI), Bash 4.0+ (scripts), Markdown (templates/commands)
**Primary Dependencies**: typer, rich, pydantic, platformdirs (matching spec-kit's CLI stack)
**Storage**: Filesystem - markdown files and YAML/JSON for configuration
**Testing**: pytest for Python CLI, bash test assertions for scripts
**Target Platform**: Mac (macOS 12+) and Linux (Ubuntu 20.04+, common distros)
**Project Type**: Single project - CLI + bash scripts + prompt templates
**Performance Goals**: All commands complete within 30 seconds (SC-008)
**Constraints**: No Windows support, Claude Code only (no other AI agents)
**Scale/Scope**: Single developer workflow, individual projects
**Git Strategy**: Worktrees by default - each feature gets `worktrees/NNN-feature-name/` directory

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution template has not been customized for this project. For this feature, we establish the following principles based on the specification requirements:

| Gate | Status | Notes |
|------|--------|-------|
| Spec-Kit Compatibility | ✅ PASS | Same commands, templates, and workflows as spec-kit |
| Single Responsibility | ✅ PASS | Each command in isolated file/module (CQ-002) |
| Mac/Linux Only | ✅ PASS | No Windows support required |
| Claude Code Only | ✅ PASS | No multi-agent support required |
| Modular Architecture | ✅ PASS | Extensible for future workflow additions (CQ-005) |

## Project Structure

### Documentation (this feature)

```text
specs/002-projspec-claude-code/
├── plan.md              # This file
├── research.md          # Phase 0 output - technology decisions
├── data-model.md        # Phase 1 output - entity definitions
├── quickstart.md        # Phase 1 output - validation scenarios
├── contracts/           # Phase 1 output - API contracts (CLI interface)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Python CLI package
src/projspec_cli/
├── __init__.py
├── __main__.py          # Entry point
├── cli.py               # Main CLI commands (init, status, version, check)
├── models/
│   ├── __init__.py
│   ├── config.py        # Project configuration model
│   └── feature.py       # Feature/spec state model
├── services/
│   ├── __init__.py
│   ├── init.py          # Project initialization logic
│   └── status.py        # Status display logic
└── utils/
    ├── __init__.py
    ├── git.py           # Git utilities
    └── paths.py         # Path resolution utilities

# Bash scripts (copied to .specify/scripts/bash/ on init)
scripts/
├── common.sh            # Shared utility functions
├── check-prerequisites.sh  # Validation script
├── create-new-feature.sh   # Worktree/branch/feature creation
├── setup-plan.sh        # Plan initialization
├── archive-feature.sh   # Merge and cleanup worktree
└── update-agent-context.sh # Agent context refresh

# Templates (copied to .specify/templates/ on init)
templates/
├── spec-template.md         # Feature specification template
├── plan-template.md         # Implementation plan template
├── tasks-template.md        # Task breakdown template
├── checklist-template.md    # Quality checklist template
├── agent-file-template.md   # CLAUDE.md template
└── commands/                # Command prompt templates for Claude Code
    ├── analyze.md           # Cross-artifact consistency check
    ├── checklist.md         # Generate quality checklist
    ├── clarify.md           # Resolve spec ambiguities
    ├── constitution.md      # Create/update constitution
    ├── implement.md         # Execute tasks sequentially
    ├── plan.md              # Generate implementation plan
    ├── specify.md           # Create feature specification
    ├── tasks.md             # Generate task breakdown
    └── taskstoissues.md     # Convert tasks to GitHub issues

# Tests
tests/
├── unit/
│   ├── test_cli.py
│   ├── test_models.py
│   └── test_services.py
├── integration/
│   ├── test_init.py
│   └── test_workflow.py
└── conftest.py
```

**Structure Decision**: Single project structure with Python CLI as the core, bash scripts for git/worktree operations, and command prompt templates for Claude Code workflows. This mirrors spec-kit's architecture while reducing complexity by removing Windows/PowerShell, multi-agent support, and plugin packaging.

## Complexity Tracking

> No constitution violations - design follows established spec-kit patterns simplified for single-platform, single-agent target.

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| CLI Stack | typer + rich + pydantic | Proven stack from spec-kit, minimal dependencies |
| Shell Scripts | Bash only | Mac/Linux target, no PowerShell needed |
| Command Delivery | Prompt templates (no plugin) | Simpler distribution, no plugin installation required |
| State Storage | YAML files | Human-readable, git-friendly, spec-kit compatible |
| Git Isolation | Worktrees by default | Complete filesystem isolation, parallel feature work, no stash/switch overhead |

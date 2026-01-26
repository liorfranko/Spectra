# Research: ProjSpec MVP

**Date**: 2026-01-26
**Feature**: 001-projspec-mvp

## Overview

This document captures research decisions for implementing ProjSpec MVP. The PRD provided extensive technical details, so most decisions were pre-determined.

---

## R1: CLI Framework Choice

**Decision**: Use Python's built-in `argparse` (no external CLI framework)

**Rationale**:
- The CLI is minimal (only `init` and `status` commands)
- PRD explicitly states "minimal Python CLI"
- Avoids adding dependencies like Click or Typer
- argparse is sufficient for simple subcommand parsing

**Alternatives Considered**:
- Click: More ergonomic but adds dependency for 2 commands
- Typer: Type-hint based but overkill for this scope
- Rich CLI: Would couple Rich output with CLI parsing

---

## R2: Package Manager

**Decision**: Use `uv` as package manager with pyproject.toml

**Rationale**:
- PRD specifies "pyproject.toml (using uv)"
- uv is fast and handles both deps and virtual environments
- Modern Python packaging standards

**Alternatives Considered**:
- Poetry: Heavier, slower than uv
- pip + requirements.txt: Less modern, no lock file

---

## R3: State File Format

**Decision**: YAML with Pydantic validation

**Rationale**:
- PRD specifies YAML for state.yaml and config.yaml
- Pydantic ensures type safety and validation
- Human-readable, easy to edit manually if needed
- pyyaml is a lightweight dependency

**Alternatives Considered**:
- JSON: Less readable, no comments
- TOML: Good for config but less natural for nested state

---

## R4: Git Worktree Strategy

**Decision**: Use git CLI commands directly (subprocess)

**Rationale**:
- PRD shows direct git commands in Claude Code commands
- Git worktree is a simple, stable interface
- No need for GitPython library (adds complexity)
- Claude can read/parse git command output

**Alternatives Considered**:
- GitPython: Adds dependency, abstraction not needed
- pygit2: C bindings, overkill for worktree operations

---

## R5: ID Generation

**Decision**: UUID hex prefix (8 characters)

**Rationale**:
- PRD example: `python -c "import uuid; print(uuid.uuid4().hex[:8])"`
- Short enough to be readable in branch names
- Long enough for uniqueness (16 million combinations)
- Standard library, no dependencies

**Alternatives Considered**:
- Incrementing IDs: Collision risk with parallel work
- Full UUID: Too long for branch names
- nanoid: Adds dependency

---

## R6: Phase Template Storage

**Decision**: Markdown files in `.projspec/phases/`

**Rationale**:
- PRD design: phases are markdown that guide Claude
- Easy to customize per project
- Version controlled with the project
- Claude Code can read and follow markdown instructions

**Alternatives Considered**:
- YAML with embedded prompts: Less readable
- Python files: Counter to "Claude-driven" principle

---

## R7: Test Strategy

**Decision**: Three-tier testing with pytest

**Rationale**:
- PRD specifies pytest
- Unit tests for models/state (fast, no I/O)
- Integration tests for CLI (subprocess, temp dirs)
- E2E tests with ClaudeRunner (optional, `claude -p`)

**Alternatives Considered**:
- Only unit tests: Misses CLI behavior
- Only E2E: Slow, flaky, expensive

---

## R8: Claude Code Plugin Structure

**Decision**: Commands in `.claude/plugins/projspec/commands/`

**Rationale**:
- PRD shows this structure explicitly
- Follows Claude Code plugin conventions
- Commands are self-contained markdown files
- plugin.json defines metadata and command list

**Alternatives Considered**:
- Single large command file: Harder to maintain
- Skills instead of commands: Commands are user-invoked, skills are automatic

---

## R9: Error Handling Strategy

**Decision**: Fail fast with clear messages

**Rationale**:
- CLI should show Rich-formatted errors
- Claude Code commands should explain errors and suggest fixes
- No silent failures - always update user
- Validate early (before side effects)

**Alternatives Considered**:
- Auto-recovery: Too complex for MVP
- Silent ignore: Poor UX, hidden bugs

---

## R10: Context Injection Approach

**Decision**: Read full files, include in Claude context

**Rationale**:
- PRD: Claude loads spec.md, plan.md, task summaries
- Simple file reading, no complex chunking
- Trust Claude to handle context within limits
- Summaries are kept to 3-5 bullets to minimize size

**Alternatives Considered**:
- Vector search: Overkill for MVP scope
- Summarization: Already using task summaries

---

## Summary

All major technical decisions were informed by the detailed PRD. The implementation follows:

1. **Minimal Python**: argparse CLI, Pydantic models, YAML files
2. **Claude-Driven**: All workflow logic in markdown commands
3. **Git-Native**: Direct git commands for worktrees
4. **Test-Covered**: pytest with unit/integration/E2E tiers

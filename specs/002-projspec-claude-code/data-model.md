# Data Model: ProjSpec Entities

**Feature**: 002-projspec-claude-code
**Date**: 2026-01-26

## Entity Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Project                                  │
│  (has config.yaml in .specify/)                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │  Feature    │    │  Feature    │    │  Feature    │          │
│  │  001-...    │    │  002-...    │    │  003-...    │          │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘          │
│         │                  │                  │                  │
│    ┌────┴────┐        ┌────┴────┐        ┌────┴────┐            │
│    │  Tasks  │        │  Tasks  │        │  Tasks  │            │
│    │ T001... │        │ T001... │        │ T001... │            │
│    └─────────┘        └─────────┘        └─────────┘            │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     Constitution                          │   │
│  │  (governs all features)                                   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. Project Configuration

**File**: `.specify/config.yaml`

```yaml
# Project metadata
project:
  name: string                    # Project name
  version: string                 # ProjSpec version used
  created: datetime               # ISO 8601 timestamp

# Feature settings
features:
  directory: string               # Default: "specs"
  numbering:
    digits: int                   # Default: 3 (001, 002, ...)
    start: int                    # Default: 1

# Git integration (worktrees are always used)
git:
  main_branch: string             # Default: "main"
  worktree_dir: string            # Default: "worktrees" - where worktrees are created

# Claude Code integration
claude:
  context_file: string            # Default: "CLAUDE.md"
  auto_update_context: bool       # Default: true
```

**Validation Rules**:
- `project.name` is required, non-empty string
- `features.numbering.digits` must be 1-5
- `git.main_branch` defaults to "main" if not specified

---

## 2. Feature

**Directory**: `specs/NNN-feature-name/`

A feature represents a unit of work with its own specification, plan, and tasks.

### Feature State (state.yaml)

```yaml
# Feature identification
id: string                        # "001", "002", etc.
name: string                      # "feature-name" (slug)
full_name: string                 # "001-feature-name"
description: string               # Original feature description

# Lifecycle
phase: enum                       # new | spec | plan | tasks | implement | review | complete
created: datetime                 # ISO 8601 timestamp
updated: datetime                 # Last modification time

# Git integration (worktree-based)
branch: string                    # "001-feature-name" (branch name)
worktree_path: string             # "worktrees/001-feature-name" (relative to repo root)
worktree_status: enum             # active | archived | pruned

# Tasks (when phase >= tasks)
tasks:
  - id: string                    # "T001", "T002", etc.
    name: string                  # Brief task name
    description: string           # Detailed description
    status: enum                  # pending | in_progress | completed | skipped
    priority: enum                # P1 | P2 | P3
    depends_on: list[string]      # List of task IDs
    context_files: list[string]   # Relevant source files
    summary: string | null        # Completion summary (3-5 bullets)
    started: datetime | null      # When work began
    completed: datetime | null    # When completed/skipped
```

**Phase Transitions**:
```
new → spec → plan → tasks → implement → review → complete
 │                                                    │
 └─ Can jump back for revisions, but typically linear ┘
```

**Validation Rules**:
- `id` must match `^\d{3}$` pattern
- `name` must match `^[a-z0-9-]+$` pattern
- `phase` must be valid enum value
- Tasks can only have `in_progress` status if all `depends_on` are `completed`

---

## 3. Specification Document

**File**: `specs/NNN-feature-name/spec.md`

```markdown
# Feature Specification: {Feature Title}

**Feature Branch**: `{NNN-feature-name}`
**Created**: {date}
**Status**: Draft | Review | Approved

## Overview
[Feature summary]

## User Scenarios & Testing *(mandatory)*

### User Story N - {Title} (Priority: P1|P2|P3)
[Description]

**Why this priority**: [Justification]
**Independent Test**: [How to test in isolation]

**Acceptance Scenarios**:
1. **Given** [context], **When** [action], **Then** [result]
...

---

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: [Requirement]
...

### Key Entities
- **Entity**: [Description]
...

## Success Criteria *(mandatory)*
- **SC-001**: [Measurable outcome]
...

## Assumptions
[List of assumptions]

## Out of Scope
[Explicit exclusions]
```

---

## 4. Implementation Plan

**File**: `specs/NNN-feature-name/plan.md`

```markdown
# Implementation Plan: {Feature Title}

**Branch**: `{NNN-feature-name}` | **Date**: {date} | **Spec**: [spec.md](./spec.md)

## Summary
[Technical approach summary]

## Technical Context
**Language/Version**: [...]
**Primary Dependencies**: [...]
**Storage**: [...]
**Testing**: [...]
**Target Platform**: [...]

## Constitution Check
| Gate | Status | Notes |
...

## Project Structure
### Documentation (this feature)
[File tree]

### Source Code (repository root)
[File tree]

## Complexity Tracking
[Only if constitution violations need justification]
```

---

## 5. Task List

**File**: `specs/NNN-feature-name/tasks.md`

```markdown
# Tasks: {Feature Title}

**Branch**: `{NNN-feature-name}` | **Generated**: {date}

## Phase 0: Setup
- [ ] [T001] [P1] Setup project infrastructure
  - [context files]

## Phase 1: Foundation
- [ ] [T002] [P1] [US1] Implement core data models
  - depends_on: T001
  - [context files]

## Phase 2: User Stories (P1)
- [ ] [T003] [P1] [US1] {Task description}
  - depends_on: T002
  - [context files]

## Phase 3: User Stories (P2/P3)
...

## Phase 4: Polish
- [ ] [T0XX] [P2] Add error handling and edge cases
- [ ] [T0XX] [P3] Documentation and cleanup
```

**Task ID Format**: `TNNN` where NNN is sequential within the feature
**Flags**:
- `[P]` - Can be parallelized (no blocking dependencies)
- `[US#]` - References user story number

---

## 6. Constitution

**File**: `.specify/memory/constitution.md`

```markdown
# {Project Name} Constitution

## Core Principles

### I. {Principle Name}
{Description}

### II. {Principle Name}
{Description}

...

## Governance
[Rules about how constitution is maintained]

**Version**: {X.Y.Z} | **Ratified**: {date} | **Last Amended**: {date}
```

---

## 7. Session State

**Directory**: `.specify/sessions/`

Tracks work across terminal sessions.

```yaml
# .specify/sessions/{date}-{session-id}-session.md
session_id: string               # UUID
started: datetime
last_active: datetime
feature: string                  # Current feature (NNN-name)
task: string | null              # Current task (TNNN)
notes: string                    # Session notes/context
```

---

## State Transitions

### Feature Lifecycle

```
┌─────────┐  specify   ┌─────────┐   plan   ┌─────────┐
│   new   │ ─────────▶ │  spec   │ ───────▶ │  plan   │
└─────────┘            └─────────┘          └─────────┘
                                                  │
                                                  ▼ tasks
                                            ┌─────────┐
                                            │  tasks  │
                                            └─────────┘
                                                  │
                                                  ▼ implement
┌─────────┐  archive   ┌─────────┐  review ┌─────────────┐
│complete │ ◀───────── │ review  │ ◀────── │  implement  │
└─────────┘            └─────────┘         └─────────────┘
```

### Task Lifecycle

```
┌─────────┐  start    ┌─────────────┐  complete  ┌───────────┐
│ pending │ ────────▶ │ in_progress │ ─────────▶ │ completed │
└─────────┘           └─────────────┘            └───────────┘
     │                       │
     │ skip                  │ skip
     ▼                       ▼
┌─────────┐           ┌─────────┐
│ skipped │           │ skipped │
└─────────┘           └─────────┘
```

---

## File Organization Summary

```
project-root/                        # Main repository (usually on main branch)
├── .git/                            # Git database (shared by all worktrees)
├── .specify/
│   ├── config.yaml                  # Project configuration
│   ├── memory/
│   │   └── constitution.md          # Project governance
│   ├── scripts/
│   │   └── bash/
│   │       ├── common.sh
│   │       ├── check-prerequisites.sh
│   │       ├── create-new-feature.sh
│   │       ├── setup-plan.sh
│   │       └── update-agent-context.sh
│   ├── sessions/
│   │   └── {date}-{id}-session.md
│   └── templates/
│       ├── spec-template.md
│       ├── plan-template.md
│       ├── tasks-template.md
│       └── checklist-template.md
├── specs/                           # SHARED: Specs are accessible from all worktrees
│   ├── 001-feature-a/
│   │   ├── state.yaml               # Feature state
│   │   ├── spec.md                  # Specification
│   │   ├── plan.md                  # Implementation plan
│   │   ├── research.md              # Technology decisions
│   │   ├── data-model.md            # Entity definitions
│   │   ├── quickstart.md            # Validation scenarios
│   │   ├── contracts/               # API contracts
│   │   └── tasks.md                 # Task breakdown
│   └── 002-feature-b/
│       └── ...
├── worktrees/                       # Feature worktrees (isolated working directories)
│   ├── 001-feature-a/               # Worktree for feature 001
│   │   ├── .git                     # Git worktree link file (not a directory)
│   │   ├── .specify -> ../../.specify  # Symlink to shared config
│   │   ├── specs -> ../../specs     # Symlink to shared specs
│   │   ├── src/                     # Feature-specific source code
│   │   └── tests/                   # Feature-specific tests
│   └── 002-feature-b/               # Worktree for feature 002
│       └── ...
├── CLAUDE.md                        # Agent context (auto-updated)
└── src/                             # Main branch source code
```

**Key Points**:
- Each feature gets its own worktree in `worktrees/NNN-feature-name/`
- `specs/` and `.specify/` are shared via symlinks in each worktree
- Source code changes are isolated to each worktree
- Claude Code should be opened in the worktree directory for feature work

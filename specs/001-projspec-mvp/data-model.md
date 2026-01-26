# Data Model: ProjSpec MVP

**Date**: 2026-01-26
**Feature**: 001-projspec-mvp

## Overview

ProjSpec uses YAML files for all persistent state. Pydantic models provide validation and type safety. All models are defined in `src/projspec/models.py`.

---

## Entity: TaskState

Represents an atomic unit of implementation work within a spec.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | string | yes | - | Unique task identifier (e.g., "task-001") |
| name | string | yes | - | Human-readable task name |
| description | string | no | "" | Detailed task description |
| status | enum | yes | "pending" | One of: pending, in_progress, completed, skipped |
| depends_on | list[string] | no | [] | List of task IDs that must complete first |
| context_files | list[string] | no | [] | Glob patterns for relevant source files |
| summary | string | null | null | 3-5 bullet summary after completion |

### Validation Rules

- `id` must be unique within the spec
- `status` must be one of the allowed values
- `depends_on` must reference valid task IDs within the same spec
- `summary` should only be set when status is "completed"

### State Transitions

```
pending → in_progress → completed
            ↓
          skipped
```

---

## Entity: SpecState

Represents a feature being developed through the workflow.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| spec_id | string | yes | - | 8-character hex ID |
| name | string | yes | - | Kebab-case spec name |
| phase | enum | yes | "new" | Current workflow phase |
| created_at | datetime | yes | - | ISO 8601 timestamp |
| branch | string | yes | - | Git branch name (spec/{id}-{name}) |
| worktree_path | string | yes | - | Relative path to worktree |
| tasks | list[TaskState] | no | [] | Tasks for implementation phase |

### Validation Rules

- `spec_id` must be exactly 8 hex characters
- `name` must be valid for git branch names (no spaces, special chars)
- `phase` must be one of: new, spec, plan, tasks, implement, review
- `branch` must match pattern `spec/{spec_id}-{name}`
- `worktree_path` must match pattern `worktrees/spec-{spec_id}-{name}`

### Phase Transitions

```
new → spec → plan → tasks → implement → review
```

Phase can only move forward (no going back to previous phases).

---

## Entity: Config

Global project configuration.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| version | string | yes | "1.0" | Configuration schema version |
| project.name | string | no | cwd name | Project display name |
| project.description | string | no | "" | Project description |
| worktrees.base_path | string | no | "./worktrees" | Directory for worktrees |
| context.always_include | list[string] | no | ["CLAUDE.md"] | Files to always include in context |

### Validation Rules

- `version` must be a valid semver-like string
- `worktrees.base_path` must be a valid relative path
- `context.always_include` entries must be valid file paths/globs

---

## Entity: Workflow

Defines the sequence of phases for the project.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| workflow.name | string | yes | "default" | Workflow identifier |
| workflow.phases | list[string] | yes | see default | Ordered list of phase names |

### Default Value

```yaml
workflow:
  name: default
  phases:
    - spec
    - plan
    - tasks
    - implement
    - review
```

### Validation Rules

- All phase names must correspond to files in `.projspec/phases/`
- Phase order must start with "spec" (after "new" which is implicit)

---

## File Locations

### Active Spec State
```
.projspec/specs/active/{spec_id}/state.yaml
```

### Completed Spec State
```
.projspec/specs/completed/{spec_id}/state.yaml
```

### Global Config
```
.projspec/config.yaml
```

### Workflow Config
```
.projspec/workflow.yaml
```

---

## Example State File

```yaml
# .projspec/specs/active/abc12345/state.yaml
spec_id: abc12345
name: user-auth
phase: implement
created_at: 2026-01-26T10:30:00Z
branch: spec/abc12345-user-auth
worktree_path: worktrees/spec-abc12345-user-auth

tasks:
  - id: task-001
    name: Create user model
    description: |
      Create the User model with fields for authentication.
      Include email validation and password hashing.
    status: completed
    depends_on: []
    context_files:
      - src/models/
    summary: |
      - Created User model in src/models/user.py
      - Fields: id, email, password_hash, created_at
      - Added email uniqueness constraint

  - id: task-002
    name: Implement registration endpoint
    status: in_progress
    depends_on:
      - task-001
    context_files:
      - src/api/
      - src/models/user.py
    summary: null

  - id: task-003
    name: Add authentication middleware
    status: pending
    depends_on:
      - task-001
    context_files:
      - src/middleware/
    summary: null
```

---

## Relationships

```
Project
  └── Config (1:1)
  └── Workflow (1:1)
  └── Specs (1:many)
        └── Tasks (1:many)
```

- A project has one config and one workflow
- A project can have many specs (but typically 1-10)
- Each spec can have many tasks (typically 5-20)
- Tasks within a spec can depend on other tasks in the same spec

# Data Model: Split Implement Command into Agent and Direct Modes

**Feature**: Split Implement Command into Agent and Direct Modes
**Date**: 2026-01-27

## Overview

This data model defines the entities involved in the dual-mode implementation command. The primary entities are the Execution Mode (determining how tasks are processed) and Task (the unit of work). These entities are conceptual—they don't persist to a database but are represented in the command's runtime state and in the tasks.md file structure.

---

## Core Entities

### 1. Execution Mode

**Description**: The method by which tasks are executed during implementation. This is determined at command invocation time based on flags.

**Identifier Pattern**: Not applicable (single instance per invocation)

**Storage Location**: Runtime state only (not persisted)

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| mode_type | enum | Yes | The execution mode: `"agent"` or `"direct"` |
| parallel_support | boolean | Yes | Whether parallel task execution is supported. `true` for agent mode, `false` for direct mode |
| context_isolation | boolean | Yes | Whether each task gets fresh context. `true` for agent mode, `false` for direct mode |
| selected_via | enum | Yes | How the mode was selected: `"flag"` or `"default"` |

**Mode Type Enum Values**:
- `agent` - Tasks executed via spawned agents with isolated context
- `direct` - Tasks executed sequentially in current conversation context

**Selection Via Enum Values**:
- `flag` - User explicitly provided `--agent` or `--direct`
- `default` - No flag provided, using default (agent mode)

**Derived Behaviors by Mode**:

| Behavior | Agent Mode | Direct Mode |
|----------|------------|-------------|
| Task spawning | Uses Task tool for each task | No spawning, inline execution |
| Parallel execution | Supported via simultaneous spawns | Not supported, runs sequentially |
| Context per task | Fresh isolated context | Shared conversation context |
| Memory usage | Lower (each agent starts fresh) | Higher (context accumulates) |

**Validation Rules**:
- mode_type must be either "agent" or "direct"
- If parallel_support is true, mode_type must be "agent"
- If context_isolation is true, mode_type must be "agent"

---

### 2. Task

**Description**: A unit of work defined in tasks.md to be implemented. Tasks are parsed from the task file and executed according to the selected execution mode.

**Identifier Pattern**: `T###` (e.g., T001, T012, T099)

**Storage Location**: `specs/{feature-id}/tasks.md`

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| task_id | string | Yes | Unique identifier in format T### (e.g., T001) |
| description | string | Yes | What the task accomplishes |
| parallel_marker | boolean | No | Whether task can run in parallel (indicated by [P] in tasks.md). Default: false |
| status | enum | Yes | Current completion state |
| files | string[] | No | List of file paths to create or modify |
| phase | string | No | The implementation phase (e.g., "Setup", "Core", "Polish") |
| user_story | string | No | Associated user story ID if applicable (e.g., "US1") |
| dependencies | string[] | No | Task IDs that must complete before this task |

**Status Enum Values**:
- `pending` - Task has not been started (represented as `- [ ]` in tasks.md)
- `in_progress` - Task is currently being executed
- `completed` - Task has been successfully implemented and committed (represented as `- [X]` in tasks.md)
- `failed` - Task execution failed
- `skipped` - Task was skipped by user choice

**State Transitions**:

```
pending → in_progress → completed
                     ↘ failed → (retry) → in_progress
                              ↘ (skip) → skipped
```

**Transition Rules**:
- `pending` → `in_progress`: Task execution begins
- `in_progress` → `completed`: Task implementation succeeds and is committed
- `in_progress` → `failed`: Task implementation encounters an error
- `failed` → `in_progress`: User chooses to retry the task
- `failed` → `skipped`: User chooses to skip the task

**Validation Rules**:
- task_id must match pattern `T\d{3}` (T followed by 3 digits)
- description must be non-empty
- If parallel_marker is true, task can only run in parallel with other [P] tasks in the same batch
- status transitions must follow the state machine rules
- files array, if present, should contain valid relative file paths

---

### 3. Commit

**Description**: A git commit created after a task is completed. Each task produces exactly one commit.

**Identifier Pattern**: Git SHA (40 hex characters)

**Storage Location**: Git repository history

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| sha | string | Yes | Git commit SHA |
| task_id | string | Yes | The task ID this commit implements |
| message | string | Yes | Commit message in format `[T###] Description` |
| author | string | Yes | Commit author |
| co_author | string | Yes | Co-authored-by trailer (Claude) |
| timestamp | datetime | Yes | When the commit was created |

**Validation Rules**:
- message must start with `[T###]` format (single task ID only)
- message must NOT contain multiple task IDs or ranges
- co_author trailer must be present
- Each task_id should appear in exactly one commit

**Invalid Message Formats** (from spec):
- `[T001-T005]` - Ranges not allowed
- `[T001, T002]` - Multiple IDs not allowed
- `[T001-T005, T010]` - Mixed formats not allowed

---

### 4. Implementation Session

**Description**: A single execution of the implement command, tracking overall progress.

**Identifier Pattern**: Not explicitly identified (implicit in execution)

**Storage Location**: Runtime state only

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| mode | ExecutionMode | Yes | The selected execution mode |
| total_tasks | integer | Yes | Total number of tasks to implement |
| completed_tasks | integer | Yes | Number of tasks successfully completed |
| failed_tasks | integer | Yes | Number of tasks that failed |
| skipped_tasks | integer | Yes | Number of tasks skipped |
| commits_created | integer | Yes | Number of git commits created |
| start_time | datetime | Yes | When implementation started |
| end_time | datetime | No | When implementation completed (null if in progress) |

**Invariants**:
- `completed_tasks + failed_tasks + skipped_tasks <= total_tasks`
- `commits_created == completed_tasks` (one commit per completed task)
- After successful completion: `completed_tasks + skipped_tasks == total_tasks`

---

## Relationships

```
┌─────────────────────┐
│ Implementation      │
│ Session             │
└─────────┬───────────┘
          │ uses
          ▼
┌─────────────────────┐      determines     ┌─────────────────────┐
│ Execution Mode      │ ─────────────────── │ Task (n)            │
│ (agent | direct)    │    how to process   └─────────┬───────────┘
└─────────────────────┘                               │ produces
                                                      ▼ (1:1)
                                            ┌─────────────────────┐
                                            │ Commit              │
                                            └─────────────────────┘
```

**Relationship Details**:

| Relationship | Cardinality | Description |
|--------------|-------------|-------------|
| Session → Mode | 1:1 | Each session has exactly one execution mode |
| Session → Task | 1:n | A session processes multiple tasks |
| Mode → Task | affects | Mode determines how tasks are executed |
| Task → Commit | 1:1 | Each completed task produces exactly one commit |

**Cascade Behavior**:
- If session is aborted, remaining tasks stay in pending status
- Completed tasks retain their commits even if session is aborted
- Failed tasks do not produce commits

---

## File Format Specifications

### tasks.md Format

**File Extension**: `.md`
**Location**: `specs/{feature-id}/tasks.md`

**Structure**:
```markdown
# Implementation Tasks: {Feature Name}

## Phase: Setup
- [ ] [T001] Create project structure
- [ ] [T002] Configure dependencies

## Phase: Core
- [ ] [T003] [US1] Implement primary feature
- [ ] [T004] [P] [US1] Add supporting service
- [ ] [T005] [P] [US1] Add data validation

## Phase: Polish
- [ ] [T006] Add documentation
```

**Task Line Format**:
```
- [ ] [T###] [Optional markers] Description
```

**Markers**:
| Marker | Meaning |
|--------|---------|
| `[P]` | Task can run in parallel with other [P] tasks in same batch |
| `[US#]` | Task is associated with user story number |

**Status Representation**:
| Checkbox | Status |
|----------|--------|
| `- [ ]` | pending |
| `- [X]` or `- [x]` | completed |

---

## Validation Rules Summary

| Entity | Rule | Error Action |
|--------|------|--------------|
| Execution Mode | Cannot specify both --agent and --direct | ERROR: Display message and exit |
| Task | task_id must be unique within tasks.md | ERROR: Halt implementation |
| Task | description cannot be empty | ERROR: Skip task with warning |
| Task | files must exist or be creatable | WARN: Log missing files, proceed |
| Commit | message must have single task ID | ERROR: Validation failure |
| Commit | count must equal completed task count | WARN: Display mismatch warning |
| Session | Git working directory must be clean | ERROR: Halt before starting |

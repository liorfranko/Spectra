---
description: "Execute the implementation plan by processing tasks from tasks.md"
user-invocable: true
---

# Implement Command

Execute the implementation plan by processing and executing all tasks defined in tasks.md. This command reads the task list, spawns agents for each task, tracks progress, and handles task dependencies and blocked tasks.

## Prerequisites

Before running this command, ensure that:

1. **tasks.md exists** - The task file must be generated from the planning phase
2. **Dependencies are resolved** - Blocked tasks will be skipped until their dependencies complete

Run prerequisite check:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-tasks
```

If prerequisites are not met, run `/speckit.tasks` first to generate the task file.

## Workflow

### Step 1: Check Prerequisites and Load Tasks

<!-- T039: Implement task loading and prerequisite validation -->
- Validate tasks.md exists and is properly formatted
- Parse task entries with their statuses, dependencies, and metadata
- Build dependency graph for execution ordering
- Identify tasks ready for execution (not blocked, not completed)

### Step 2: Execute Tasks and Update Status

<!-- T040: Implement task execution with agent spawning -->
- For each ready task, spawn an implementation agent
- Pass task context, acceptance criteria, and file references to agent
- Monitor agent execution and capture results
- Update task status in tasks.md (pending -> in_progress -> completed)
- Handle task failures with appropriate error reporting

### Step 3: Track Progress and Report

<!-- T041: Implement progress tracking and reporting -->
- Display real-time progress as tasks complete
- Show summary statistics (completed, pending, blocked, failed)
- Generate completion report when all tasks finish
- Update any cross-references in related artifacts

### Step 4: Handle Blocked Tasks

<!-- T042: Implement blocked task resolution -->
- Detect newly unblocked tasks as dependencies complete
- Re-evaluate blocked tasks after each completion
- Report permanently blocked tasks (circular dependencies)
- Suggest manual intervention for stuck tasks

## Usage

```
/speckit.implement
```

## Notes

- Tasks are executed in dependency order
- Failed tasks do not block unrelated tasks
- Progress is persisted so implementation can resume after interruption
- Use `/speckit.tasks` to regenerate or modify the task list

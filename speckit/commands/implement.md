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

**1.1: Run prerequisite check script with tasks content**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-tasks --json --include-tasks
```

**1.2: Parse JSON output to extract:**

The script returns a JSON object with the following fields:
- `FEATURE_DIR` - The path to the current feature directory
- `AVAILABLE_DOCS` - Array of documents that exist in the feature directory
- `GH_CLI_AVAILABLE` - Boolean indicating if GitHub CLI is installed
- `TASKS_CONTENT` - The full content of tasks.md (when `--include-tasks` is used)

If the script exits with error (missing tasks.md), display an error message instructing the user to run `/speckit.tasks` first, then stop execution.

**1.3: Parse tasks.md to extract task information**

Parse the `TASKS_CONTENT` to extract all tasks. Each task line follows one of these formats:

```
- [ ] T### Description (file path)                    # Pending task
- [ ] T### [P] Description (file path)                # Pending parallel task
- [ ] T### [US#] Description (file path)              # Pending task with story marker
- [ ] T### [P] [US#] Description (file path)          # Pending parallel task with story marker
- [x] T### Description (file path)                    # Completed task
```

For each task line, extract and store:

| Field | Extraction Pattern | Example |
|-------|-------------------|---------|
| Task ID | `T\d{3}` | T039 |
| Status | `\[ \]` = pending, `\[x\]` = completed | pending |
| Parallel | Contains `[P]` after task ID | true/false |
| Story Marker | `\[US\d+\]` | US3 |
| Description | Text after markers, before `(` | "Add implement command logic..." |
| File Path | Text inside final `()` | "speckit/commands/implement.md" |

Build a task array:
```
tasks = [
  {
    id: "T039",
    status: "pending" | "completed",
    isParallel: true | false,
    storyId: "US3" | null,
    description: "Task description text",
    filePath: "path/to/file" | null
  },
  ...
]
```

**1.4: Extract phase organization**

Parse the tasks.md structure to identify phases. Phases are indicated by:
- Section headers: `## Phase N: Phase Name`
- Optional phase markers in the format: `**Purpose**: Phase description`

Build a phase structure:
```
phases = [
  {
    number: 1,
    name: "Setup",
    purpose: "Project Initialization",
    taskIds: ["T001", "T002", "T003", "T004"]
  },
  {
    number: 2,
    name: "Foundational",
    purpose: "Blocking Prerequisites",
    taskIds: ["T005", "T006", ...]
  },
  ...
]
```

**1.5: Identify dependency information**

Parse dependency information from:
1. **Explicit dependency sections** - Look for "Dependencies" or "Dependencies & Execution Order" section
2. **Phase dependencies** - Earlier phases block later phases
3. **Implicit dependencies** - Tasks marked `[P]` within the same phase can run in parallel; others are sequential

Build dependency graph:
```
dependencies = {
  "T005": { blockedBy: [], blocks: ["T006", "T007", "T008"] },
  "T006": { blockedBy: ["T005"], blocks: [] },
  ...
}
```

Dependency rules to infer when not explicit:
- Non-`[P]` tasks within a phase depend on the previous non-`[P]` task
- `[P]` tasks depend on the last non-`[P]` task before them
- First task of a phase depends on all tasks of the previous phase completing

**1.6: Build execution queue**

Create a queue of tasks ready for execution:

```
function buildExecutionQueue(tasks, dependencies):
  completedTasks = tasks.filter(t => t.status == "completed").map(t => t.id)
  pendingTasks = tasks.filter(t => t.status == "pending")

  readyTasks = []
  blockedTasks = []

  for each task in pendingTasks:
    blockers = dependencies[task.id].blockedBy
    unblockedBlockers = blockers.filter(b => !completedTasks.includes(b))

    if unblockedBlockers.length == 0:
      readyTasks.push(task)
    else:
      blockedTasks.push({
        task: task,
        waitingFor: unblockedBlockers
      })

  return { readyTasks, blockedTasks }
```

Sort ready tasks by:
1. Phase number (lower phases first)
2. Task ID (lower IDs first within same phase)
3. Non-parallel tasks before parallel tasks (to maintain order)

**1.7: Report initial status**

Display the implementation status to the user:

```markdown
## Implementation Status

**Feature Directory**: {FEATURE_DIR}
**Tasks File**: {FEATURE_DIR}/tasks.md

### Progress Summary

| Status | Count |
|--------|-------|
| Completed | {completed_count} |
| Pending | {pending_count} |
| Blocked | {blocked_count} |
| Ready to Execute | {ready_count} |

**Progress**: {completed_count}/{total_count} tasks ({percentage}%)

### Ready for Execution

The following tasks are ready to be executed (no pending dependencies):

{For each ready task, display:}
- T### [P?] [US#?] Description
  File: {file_path}
  Phase: {phase_number} - {phase_name}

### Blocked Tasks

{If blocked tasks exist:}
The following tasks are waiting for dependencies:

{For each blocked task:}
- T### is waiting for: T###, T###, ...

### Next Action

{If ready tasks exist:}
Starting implementation with task T### - {description}

{If no ready tasks and blocked tasks exist:}
ERROR: All remaining tasks are blocked. This may indicate circular dependencies.
Review the Dependencies section of tasks.md.

{If no pending tasks remain:}
All tasks have been completed! The implementation is finished.
```

Store the execution queue and task data for use in subsequent steps (Step 2 onwards)

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

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

If prerequisites are not met, run `/projspec.tasks` first to generate the task file.

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

If the script exits with error (missing tasks.md), display an error message instructing the user to run `/projspec.tasks` first, then stop execution.

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

**2.1: For each ready task from the execution queue, spawn a Task tool agent**

For each task in the ready queue, invoke the Task tool with the following template:

```yaml
Task tool:
  subagent_type: "general-purpose"
  description: "[TaskID] Brief description"
  prompt: |
    You are implementing a specific task in isolation with a fresh context.

    TASK DETAILS:
    - Task ID: [TaskID]
    - Description: [Full task description from tasks.md]
    - File to modify: [file path from task]

    CONTEXT:
    [Include relevant excerpts from plan.md - architecture, file structure, patterns]
    [Include relevant user stories from spec.md if applicable]
    [Include data model details from data-model.md if the task involves entities]

    CONSTITUTION PRINCIPLES:
    [Key principles from constitution.md that apply to this task]

    INSTRUCTIONS:
    [Specific implementation instructions for this task]

    DO NOT:
    - Implement other tasks
    - Deviate from the plan
    - Skip error handling
    - Ignore constitution requirements

    When complete, report what was modified.
```

For sequential tasks, spawn one agent at a time and wait for completion before proceeding to the next task.

For parallel tasks (marked with `[P]`), spawn multiple agents simultaneously in a single message with multiple Task tool calls:

```yaml
# Parallel execution - multiple Task tool calls in one message
Task tool 1:
  description: "[T010] First parallel task"
  prompt: ...

Task tool 2:
  description: "[T011] Second parallel task"
  prompt: ...

Task tool 3:
  description: "[T012] Third parallel task"
  prompt: ...
```

**2.2: After agent completes successfully, commit and update status**

After each agent reports successful completion:

1. **Stage changes**:
   ```bash
   git add -A
   ```

2. **Commit with task ID**:
   ```bash
   git commit -m "[TaskID] Task description

   Co-Authored-By: Claude Sonnet 4.5 (1M context) <noreply@anthropic.com>"
   ```

   For parallel tasks, commit each task separately in completion order:
   ```bash
   git commit -m "[T010] First parallel task description

   Co-Authored-By: Claude Sonnet 4.5 (1M context) <noreply@anthropic.com>"
   ```

3. **Push to remote**:
   ```bash
   git push
   ```

   For parallel tasks, push all commits together after all have been committed:
   ```bash
   git push
   ```

4. **Update tasks.md**: Change the task status from pending to completed:
   - Find the line: `- [ ] T### Description (file path)`
   - Replace with: `- [x] T### Description (file path)`
   - Write the updated content back to tasks.md

**2.3: Handle agent failure**

If an agent fails to complete its task:

1. **Report the error**:
   ```markdown
   ## Task Failed: [TaskID]

   **Error**: [Agent error output or failure reason]

   **Task**: [Task description]
   **File**: [File path]
   ```

2. **Ask user for action**:
   ```markdown
   How would you like to proceed?

   1. **Retry** - Spawn the same agent again with the same prompt
   2. **Skip** - Mark task as skipped and move to the next task (not recommended)
   3. **Abort** - Stop implementation and review the task breakdown

   Please respond with: retry, skip, or abort
   ```

3. **Handle user response**:
   - **retry**: Re-spawn the agent with the same task context
   - **skip**: Log the skip, do NOT mark the task as completed, move to next task
   - **abort**: Stop execution and report current progress

**2.4: Move to next task in queue**

After successful completion or user-directed action:

1. Remove the completed/skipped task from the execution queue
2. Re-evaluate blocked tasks (handled in Step 4)
3. Get the next task from the ready queue
4. If ready queue is not empty, return to step 2.1
5. If ready queue is empty but blocked tasks exist, proceed to Step 4
6. If no pending tasks remain, proceed to Step 3 for final reporting

### Step 3: Track Progress and Report

**3.1: After each task completes, update and display progress**

After each successful task completion (from Step 2.2), calculate and display progress:

1. **Calculate completion percentage**:
   ```
   total_tasks = count of all tasks in tasks.md
   completed_tasks = count of tasks with [x] status
   percentage = (completed_tasks / total_tasks) * 100
   ```

2. **Display completion message**:
   ```markdown
   ✓ [T###] Description - Committed and pushed
   ```

   Example output:
   ```markdown
   ✓ [T039] Add implement command logic: prerequisites check - Committed and pushed
   ✓ [T040] Add implement command logic: task execution loop - Committed and pushed
   ```

**3.2: Track and display metrics after each task**

Maintain running metrics throughout execution:

1. **Core metrics**:
   ```
   metrics = {
     total_tasks: count of all tasks,
     completed_tasks: count of [x] tasks,
     remaining_tasks: count of [ ] tasks,
     skipped_tasks: count of tasks skipped by user,
     failed_retries: count of tasks that failed and were retried
   }
   ```

2. **Tasks by phase**:
   ```
   phase_metrics = {
     "Phase 1: Setup": { total: 4, completed: 4 },
     "Phase 2: Foundational": { total: 8, completed: 3 },
     ...
   }
   ```

3. **Display periodic progress update** (after every task or batch of parallel tasks):
   ```markdown
   Progress: {completed_tasks}/{total_tasks} ({percentage}%) | Phase {current_phase}: {phase_completed}/{phase_total}
   ```

**3.3: Show progress bar or percentage indicator**

Display a visual progress indicator after each task completion:

```markdown
## Progress Update

[████████████░░░░░░░░] 60% Complete

| Metric | Count |
|--------|-------|
| Completed | 24 |
| Remaining | 16 |
| Current Phase | Phase 3: Core Features |

Last completed: [T024] Add validation logic to form handler
```

For text-based progress bar, use:
- 20 character width total
- `█` for completed portions
- `░` for remaining portions
- Calculate: `filled = floor((completed / total) * 20)`

**3.4: On completion of all tasks, display final summary**

When all tasks are completed (remaining_tasks == 0 and no blocked tasks):

```markdown
## Implementation Complete! 🎉

All tasks have been successfully implemented.

### Summary

| Metric | Count |
|--------|-------|
| Total Tasks | {total_tasks} |
| Completed | {completed_tasks} |
| Skipped | {skipped_tasks} |
| Duration | {approximate duration if tracked} |

### Tasks by Phase

| Phase | Tasks Completed |
|-------|-----------------|
| Phase 1: Setup | 4/4 |
| Phase 2: Foundational | 8/8 |
| Phase 3: Core Features | 12/12 |
| ... | ... |

### Git Commits

The following commits were created during implementation:

{Run: git log --oneline -n {total_tasks} and display output}

Example:
```
a1b2c3d [T040] Add implement command logic: task execution loop
e4f5g6h [T039] Add implement command logic: prerequisites check
...
```

### Next Steps

Your implementation is ready for review. Suggested next action:

→ Run `/projspec.review-pr` to create a comprehensive pull request with review

Alternatively:
- Run `git log --oneline` to review all commits
- Run `git diff main...HEAD` to see full changes
- Create a PR manually with `gh pr create`
```

**3.5: Handle partial completion (user aborts or session ends)**

If implementation is interrupted before all tasks complete:

```markdown
## Implementation Paused

Progress has been saved. You can resume by running `/projspec.implement` again.

### Current Status

| Metric | Count |
|--------|-------|
| Completed | {completed_tasks} |
| Remaining | {remaining_tasks} |
| Progress | {percentage}% |

### Commits Made This Session

{Run: git log --oneline -n {tasks_completed_this_session}}

### To Resume

Run `/projspec.implement` to continue from where you left off.
The command will detect completed tasks and continue with remaining work.
```

### Step 4: Handle Blocked Tasks and Dependency Resolution

This step handles situations where tasks cannot proceed due to dependencies.

**4.1: When no ready tasks available but pending tasks exist**

When the execution queue is empty but blocked tasks remain:

1. **List blocked tasks and their blockers**:
   ```markdown
   ## Blocked Tasks Analysis

   No tasks are currently ready for execution. The following tasks are blocked:

   | Task | Waiting For | Blocker Status |
   |------|-------------|----------------|
   | T015 | T014 | pending |
   | T016 | T014, T015 | pending, pending |
   | T017 | T016 | pending |
   ```

2. **Check if any blockers are completed (refresh status)**:

   Re-read tasks.md to get the latest status:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-tasks --json --include-tasks
   ```

   Parse the updated `TASKS_CONTENT` and rebuild the execution queue:
   ```
   for each blocked task:
     blockerIds = dependencies[task.id].blockedBy
     for each blockerId in blockerIds:
       blocker = tasks.find(t => t.id == blockerId)
       if blocker.status == "completed":
         # Blocker has been completed since last check
         remove blockerId from task's blockedBy list

     if all blockers are now completed:
       move task from blockedTasks to readyTasks
   ```

3. **If tasks were unblocked, return to Step 2 for execution**

**4.2: For truly blocked tasks**

When tasks remain blocked after refresh:

1. **Show dependency chain**:
   ```markdown
   ## Dependency Chain Analysis

   The following dependency chains are preventing progress:

   ### Chain 1: T017 → T016 → T015 → T014

   - T014: "Set up database connection" (pending)
     └─ blocks: T015
   - T015: "Create user model" (pending)
     └─ waiting for: T014
     └─ blocks: T016
   - T016: "Add authentication service" (pending)
     └─ waiting for: T014, T015
     └─ blocks: T017
   - T017: "Implement login endpoint" (pending)
     └─ waiting for: T016

   **Root blocker**: T014 - "Set up database connection"
   ```

2. **Ask user for action**:
   ```markdown
   ## Action Required

   How would you like to proceed?

   1. **Wait** - The root blocker T014 may need manual completion or external resources
      - I'll provide guidance on completing T014 manually

   2. **Force Unblock** - Skip the blocker and proceed with dependent tasks
      - WARNING: This may cause issues if the blocker was truly required
      - Tasks that depend on skipped work may fail

   3. **Abort** - Stop implementation and review the task breakdown
      - Run `/projspec.tasks` to regenerate with different dependencies

   Please respond with: wait, force, or abort
   ```

3. **Handle user response**:

   **If "wait"**:
   ```markdown
   ## Guidance for Completing T014

   **Task**: {blocker description}
   **File**: {blocker file path}

   This task needs to be completed before the blocked tasks can proceed.

   You can:
   - Complete this task manually
   - Run `/projspec.implement` again after the blocker is resolved
   - Ask me to help implement just this specific task
   ```

   **If "force"**:
   ```markdown
   ## Force Unblocking

   Removing dependency on T014 for the following tasks:
   - T015: Now ready for execution
   - T016: Still waiting for T015

   WARNING: Skipped task T014 is NOT marked as completed.
   The dependent tasks may reference functionality that doesn't exist.

   Proceeding with T015...
   ```

   Then:
   - Remove the blocker from all blocked tasks' `blockedBy` lists
   - Rebuild the execution queue
   - Return to Step 2

   **If "abort"**:
   - Display the partial completion summary (Step 3.5)
   - Stop execution

**4.3: Handle circular dependencies**

Circular dependencies occur when tasks mutually block each other.

1. **Detect cycles**:

   Before execution, run cycle detection on the dependency graph:
   ```
   function detectCycles(dependencies):
     visited = {}
     recursionStack = {}
     cycles = []

     function dfs(taskId, path):
       visited[taskId] = true
       recursionStack[taskId] = true
       path.push(taskId)

       for each blockerId in dependencies[taskId].blockedBy:
         if recursionStack[blockerId]:
           # Found cycle - extract it from path
           cycleStart = path.indexOf(blockerId)
           cycle = path.slice(cycleStart)
           cycle.push(blockerId)  # Complete the cycle
           cycles.push(cycle)
         else if !visited[blockerId]:
           dfs(blockerId, path)

       path.pop()
       recursionStack[taskId] = false

     for each taskId in dependencies:
       if !visited[taskId]:
         dfs(taskId, [])

     return cycles
   ```

2. **Report the cycle**:
   ```markdown
   ## Circular Dependency Detected!

   A circular dependency exists in the task graph, preventing execution:

   ### Cycle Found

   T012 → T013 → T014 → T012

   **Details:**
   - T012: "Create validation utilities" depends on T014
   - T013: "Add input sanitization" depends on T012
   - T014: "Build form handler" depends on T013

   This creates an impossible execution order where each task requires another to complete first.
   ```

3. **Ask for user intervention**:
   ```markdown
   ## Resolution Required

   To resolve this circular dependency, you can:

   1. **Break the cycle** - Tell me which dependency to remove
      Example: "Remove dependency of T012 on T014"

   2. **Merge tasks** - Combine the circular tasks into one
      The merged task will implement all functionality together

   3. **Regenerate tasks** - Run `/projspec.tasks` to create a new task breakdown
      Consider restructuring the implementation approach

   Please provide your choice and any specific instructions.
   ```

4. **Handle user response**:

   **If breaking a dependency**:
   - Parse the user's instruction to identify which dependency to remove
   - Update the dependency graph: `dependencies[taskId].blockedBy.remove(blockerId)`
   - Update the reverse mapping: `dependencies[blockerId].blocks.remove(taskId)`
   - Re-run cycle detection to ensure the cycle is broken
   - If more cycles exist, repeat the process
   - Rebuild execution queue and return to Step 2

   **If merging tasks**:
   ```markdown
   ## Merging Circular Tasks

   Creating combined task from: T012, T013, T014

   **Merged Task**: T012-MERGED
   **Description**: Create validation utilities, add input sanitization, and build form handler
   **Files**:
   - path/to/validators.ts
   - path/to/sanitizers.ts
   - path/to/form-handler.ts

   Spawning agent for merged task...
   ```

   - Combine all task descriptions and file paths
   - Spawn a single agent with the combined context
   - On completion, mark all original tasks as completed
   - Remove the cycle from the graph
   - Continue with remaining tasks

   **If regenerating**:
   - Display instructions to run `/projspec.tasks`
   - Stop execution

**4.4: Update execution queue after unblocking**

After any unblocking action (task completion, force unblock, or cycle resolution):

1. **Rebuild the execution queue**:
   ```
   function updateExecutionQueue(tasks, dependencies, completedTasks):
     readyTasks = []
     blockedTasks = []

     for each task in tasks.filter(t => t.status == "pending"):
       # Get current blockers (excluding completed and force-skipped)
       activeBlockers = dependencies[task.id].blockedBy
         .filter(b => !completedTasks.includes(b))
         .filter(b => !forceSkippedTasks.includes(b))

       if activeBlockers.length == 0:
         readyTasks.push(task)
       else:
         blockedTasks.push({
           task: task,
           waitingFor: activeBlockers
         })

     # Sort ready tasks by phase and ID
     readyTasks.sort((a, b) => {
       if (a.phase != b.phase) return a.phase - b.phase
       return a.id.localeCompare(b.id)
     })

     return { readyTasks, blockedTasks }
   ```

2. **Report newly unblocked tasks**:
   ```markdown
   ## Tasks Unblocked

   The following tasks are now ready for execution:

   | Task | Description | Was Waiting For |
   |------|-------------|-----------------|
   | T015 | Create user model | T014 (completed) |
   | T016 | Add auth service | T014 (completed), T015 (now ready) |

   Continuing with T015...
   ```

3. **Continue execution**:
   - If readyTasks is not empty, return to Step 2.1
   - If readyTasks is empty but blockedTasks exist, return to Step 4.1
   - If no pending tasks remain, proceed to Step 3.4 for final summary

## Output

When the implement command completes, it produces the following outputs:

### Files Modified

| File | Modification |
|------|--------------|
| `tasks.md` | Task checkboxes updated from `[ ]` to `[x]` as tasks complete |
| Implementation files | Files created or modified as specified in each task |

### Git Artifacts

| Artifact | Description |
|----------|-------------|
| Commits | One commit per task with format `[TaskID] Description` |
| Push | All commits pushed to remote repository |

### Console Output

| Output | When Displayed |
|--------|----------------|
| Initial status | At command start - shows ready/blocked task counts |
| Progress updates | After each task - shows completion percentage and progress bar |
| Blocked task analysis | When no ready tasks available |
| Final summary | On completion or abort - shows total metrics and git log |

### Exit States

| State | Description |
|-------|-------------|
| Complete | All tasks executed successfully |
| Partial | Some tasks completed, user aborted or session ended |
| Blocked | Cannot proceed due to unresolvable dependencies |
| Error | Critical failure requiring manual intervention |

### Resume Capability

The command is idempotent and can be run multiple times:
- Completed tasks (marked `[x]`) are skipped
- Execution continues from the first pending ready task
- Progress is preserved between sessions

## Usage

```
/projspec.implement
```

## Notes

- Tasks are executed in dependency order
- Failed tasks do not block unrelated tasks
- Progress is persisted so implementation can resume after interruption
- Use `/projspec.tasks` to regenerate or modify the task list

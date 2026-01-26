---
description: Execute implementation tasks with dependency resolution and context injection
---

# /projspec.implement Command

This command guides the implementation of tasks defined in state.yaml. It finds the next ready task (based on dependency resolution), injects relevant context, guides the implementation, and updates task status with completion summaries.

## Prerequisites

- A spec must exist and be in the "tasks" or "implement" phase
- The state.yaml file must have tasks defined
- User should be in the spec's worktree or the main repository

## Task Status Workflow

Tasks progress through these statuses:

```
pending -> in_progress -> completed
                      \-> skipped
```

A task is **ready** when:
1. Its status is `pending`
2. All tasks in its `depends_on` list have status `completed` or `skipped`

## Execution Steps

Follow these steps exactly to implement tasks:

### Step 1: Detect Current Spec

Find the active spec by listing the `.projspec/specs/active/` directory:

```bash
ls .projspec/specs/active/
```

If the directory is empty or doesn't exist, output this error and stop:

```
Error: No active specs found.

Create a new spec first with: /projspec.new <spec-name>
```

If multiple specs are found, list them and ask the user which one to use:

```
Multiple active specs found:
- {SPEC_ID_1}: {SPEC_NAME_1} (phase: {PHASE_1})
- {SPEC_ID_2}: {SPEC_NAME_2} (phase: {PHASE_2})

Which spec would you like to implement? Please provide the spec ID.
```

### Step 2: Load State Configuration

Read the state.yaml file for the selected spec:

```bash
cat .projspec/specs/active/{SPEC_ID}/state.yaml
```

Parse the YAML to extract:
- `SPEC_ID`: The spec identifier
- `SPEC_NAME`: The spec name
- `PHASE`: Current phase
- `WORKTREE_PATH`: Path to the worktree
- `tasks`: List of task objects with id, name, description, status, depends_on, context_files, summary

### Step 3: Validate Phase

Check that the current phase is "tasks" or "implement". Handle other phases accordingly:

**If phase is "new":**
```
This spec is in the "new" phase.

The specification must be created first.
Please run the following commands in order:
  1. /projspec.spec - Create the specification
  2. /projspec.plan - Create the implementation plan
  3. /projspec.tasks - Generate the task list
  4. /projspec.implement - Then implement tasks
```

**If phase is "spec":**
```
This spec is in the "spec" phase.

The implementation plan and tasks must be created first.
Please run:
  1. /projspec.plan - Create the implementation plan
  2. /projspec.tasks - Generate the task list
  3. /projspec.implement - Then implement tasks
```

**If phase is "plan":**
```
This spec is in the "plan" phase.

The task list must be generated first.
Please run:
  1. /projspec.tasks - Generate the task list
  2. /projspec.implement - Then implement tasks
```

**If phase is "review":**
```
This spec is in the "review" phase.

All tasks have been completed! Please run: /projspec.review
```

### Step 4: Update Phase to "implement" (First Task Only) [T057]

If the current phase is "tasks", update it to "implement" before starting the first task:

1. Read the current state.yaml
2. Update the `phase` field from `tasks` to `implement`
3. Write the updated content back to state.yaml

Report the phase transition:
```
Phase updated: tasks -> implement
Starting implementation of {SPEC_NAME}...
```

### Step 5: Analyze Task States and Find Next Ready Task [T049, T050]

Analyze all tasks to determine their status:

#### Task Classification Algorithm

```
For each task in tasks:
  1. If status is "completed" or "skipped":
     - Add to completed_tasks

  2. If status is "in_progress":
     - Add to in_progress_tasks

  3. If status is "pending":
     - Check all depends_on tasks
     - If ALL dependencies are completed/skipped:
       - Add to ready_tasks
     - Else:
       - Add to blocked_tasks
       - Record which dependencies are incomplete
```

#### Ready Task Selection

From `ready_tasks`, select the next task to implement:
- If multiple tasks are ready, select the first one by ID order
- If a task is already `in_progress`, resume that task first

### Step 6: Handle Different Task States

Based on the analysis from Step 5, proceed accordingly:

#### Case A: All Tasks Complete [T055]

If all tasks have status `completed` or `skipped`:

```
All tasks complete!

Implementation Summary for {SPEC_NAME}:

  Completed: {COMPLETED_COUNT} tasks
  Skipped:   {SKIPPED_COUNT} tasks
  Total:     {TOTAL_COUNT} tasks

Completed Tasks:
  - {TASK_ID}: {TASK_NAME}
    Summary: {TASK_SUMMARY}

  - {TASK_ID}: {TASK_NAME}
    Summary: {TASK_SUMMARY}

  [... for all completed tasks ...]

Recommended Next Steps:
  1. Review the implementation with: /projspec.review
  2. Run tests to verify functionality
  3. Create a pull request when ready

Would you like me to run /projspec.review now?
```

Update the phase to "review" in state.yaml if all tasks are complete.

#### Case B: Task In Progress

If a task is already `in_progress`:

```
Resuming in-progress task:

  Task ID:     {TASK_ID}
  Name:        {TASK_NAME}
  Description: {TASK_DESCRIPTION}

Loading context and continuing implementation...
```

Proceed to Step 7 with this task.

#### Case C: Blocked Tasks Only [T056]

If there are no ready tasks but there are blocked tasks:

```
No ready tasks available.

Blocked Tasks:

| Task ID   | Name                    | Waiting On            |
|-----------|-------------------------|----------------------|
| {TASK_ID} | {TASK_NAME}            | {DEPENDENCY_IDS}     |
| {TASK_ID} | {TASK_NAME}            | {DEPENDENCY_IDS}     |

Dependency Details:

{BLOCKED_TASK_ID} is waiting on:
  - {DEP_ID}: {DEP_NAME} (status: {DEP_STATUS})
  - {DEP_ID}: {DEP_NAME} (status: {DEP_STATUS})

This may indicate:
1. A circular dependency exists
2. Tasks were marked as blocked incorrectly
3. Some tasks need to be completed manually

Would you like to:
1. View dependency graph to identify the issue
2. Force-start a specific blocked task
3. Mark a blocking task as skipped to unblock others

Please choose an option.
```

Handle user choice:
- **Option 1**: Display a visual dependency graph
- **Option 2**: Ask for task ID and proceed to Step 7 (update depends_on to empty)
- **Option 3**: Ask for task ID to skip and update its status to "skipped"

#### Case D: Ready Task Available

If there is a ready task:

```
Next ready task:

  Task ID:     {TASK_ID}
  Name:        {TASK_NAME}
  Description: {TASK_DESCRIPTION}

  Dependencies: {COMPLETED_DEPENDENCY_NAMES} (all complete)
  Context Files: {CONTEXT_FILE_PATTERNS}

Ready to start implementation?
1. Yes, begin this task
2. Skip this task and show next ready task
3. View all ready tasks

Please choose an option.
```

Handle user choice:
- **Option 1**: Proceed to Step 7
- **Option 2**: Update task status to "skipped" and repeat Step 5
- **Option 3**: List all ready tasks and let user choose

### Step 7: Update Task Status to "in_progress" [T052]

Before starting implementation, update the task status:

1. Read the current state.yaml
2. Find the task by ID
3. Update the `status` field from `pending` to `in_progress`
4. Write the updated content back to state.yaml

Report the status change:
```
Task {TASK_ID} status updated: pending -> in_progress
```

### Step 8: Load Context [T051]

Load and present all relevant context for the task:

#### 8.1 Load spec.md

```bash
cat {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md
```

Extract and summarize the relevant sections for this task.

#### 8.2 Load plan.md

```bash
cat {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md
```

Extract the relevant Build Order section and component details.

#### 8.3 Load Completed Task Summaries

For each task in the `depends_on` list (and any other completed tasks that provide relevant context):

```yaml
Completed Task Summaries:
  {DEP_TASK_ID}: {DEP_TASK_NAME}
    - {SUMMARY_BULLET_1}
    - {SUMMARY_BULLET_2}
    - {SUMMARY_BULLET_3}
```

#### 8.4 Load Context Files

For each pattern in the task's `context_files`:

```bash
# For directory patterns
ls {CONTEXT_FILE_PATTERN}

# For file patterns
cat {CONTEXT_FILE}
```

If a context file doesn't exist yet (e.g., file to be created), note it as "To be created".

#### 8.5 Present Context Summary

```
Context loaded for {TASK_NAME}:

Specification Summary:
  [Relevant excerpt from spec.md]

Plan Reference:
  [Relevant Build Order item from plan.md]

Completed Dependencies:
  - {DEP_TASK_ID}: {DEP_TASK_NAME}
    {SUMMARY_BULLETS}

Relevant Files:
  Existing:
    - {FILE_PATH} (read)
  To Create:
    - {FILE_PATH}
  To Modify:
    - {FILE_PATH}
```

### Step 9: Guide Implementation

Now guide the user through implementing the task:

```
Beginning implementation of: {TASK_NAME}

Task Description:
{TASK_DESCRIPTION}

Based on the context loaded, I'll now implement this task.
```

Proceed to implement the task according to its description, using the loaded context to inform decisions. Follow the project's coding conventions and patterns.

During implementation:
- Create or modify files as needed
- Run tests if applicable
- Handle any errors or issues that arise

### Step 10: Verify Task Completion

After implementation, verify the task is complete:

```
Implementation complete for: {TASK_NAME}

Verification checklist:
- [ ] All required files created/modified
- [ ] Code follows project conventions
- [ ] No obvious errors or issues
- [ ] Ready for testing

Would you like me to:
1. Mark this task as complete and generate summary
2. Continue working on this task
3. Mark as complete but note issues for follow-up

Please choose an option.
```

### Step 11: Generate Task Summary [T053]

When the user confirms completion, generate a 3-5 bullet summary of what was accomplished:

```
Generating task summary...

Task: {TASK_NAME}

Summary:
- [What was created/modified - specific files or components]
- [Key implementation decisions made]
- [Integration points with other components]
- [Any notable patterns or approaches used]
- [Test coverage or verification status]
```

Ask user to confirm or edit the summary:

```
Does this summary accurately capture the work done?
1. Yes, save this summary
2. Edit the summary
3. Regenerate with more/less detail

Please choose an option.
```

### Step 12: Update Task to "completed" [T054]

Update the task with the final status and summary:

1. Read the current state.yaml
2. Find the task by ID
3. Update the following fields:
   - `status`: Change from `in_progress` to `completed`
   - `summary`: Set to the generated/confirmed summary
4. Write the updated content back to state.yaml

Report the completion:

```
Task completed and saved!

  Task ID:     {TASK_ID}
  Name:        {TASK_NAME}
  Status:      in_progress -> completed
  Summary:     Saved to state.yaml

Progress: {COMPLETED_COUNT}/{TOTAL_COUNT} tasks complete
```

### Step 13: Check for Next Task or Completion

After completing a task, check if there are more tasks:

```
Task {TASK_ID} complete!

Progress: {COMPLETED_COUNT}/{TOTAL_COUNT} tasks

Remaining tasks: {REMAINING_COUNT}
  Ready:   {READY_COUNT}
  Blocked: {BLOCKED_COUNT}
```

**If more ready tasks exist:**
```
Next ready task:
  {NEXT_TASK_ID}: {NEXT_TASK_NAME}

Would you like to continue with the next task?
1. Yes, continue to next task
2. Take a break (you can resume with /projspec.implement)
3. View all remaining tasks

Please choose an option.
```

**If all tasks are complete:**
Proceed to Case A in Step 6 (All Tasks Complete).

## Error Handling

### Missing state.yaml
```
Error: state.yaml not found at .projspec/specs/active/{SPEC_ID}/state.yaml

The spec may be corrupted. Try running: /projspec.status
```

### Empty Task List
```
Error: No tasks found in state.yaml

Please generate tasks first with: /projspec.tasks
```

### Circular Dependency Detection

If circular dependencies are detected during task analysis:

```
Error: Circular dependency detected!

Cycle found:
  {TASK_A} -> {TASK_B} -> {TASK_C} -> {TASK_A}

This must be resolved before implementation can continue.

Options:
1. Remove one of the dependencies to break the cycle
2. Merge the tasks into a single task
3. Create an intermediate task

Which approach would you like to take?
```

### Context File Not Found

If a context file cannot be loaded:

```
Warning: Context file not found: {FILE_PATH}

This file may need to be created as part of this task or a previous task.
Continuing with available context...
```

### Task Status Conflict

If task status is unexpected:

```
Warning: Task {TASK_ID} has unexpected status: {STATUS}

Expected: pending or in_progress
Actual:   {STATUS}

Would you like to:
1. Reset status to pending and start fresh
2. View task details
3. Skip to next available task
```

## State.yaml Task Structure Reference

```yaml
tasks:
  - id: task-001
    name: Create user model
    description: |
      Create the User model with fields for authentication.
      Include email validation and password hashing.
    status: pending  # pending -> in_progress -> completed/skipped
    depends_on: []
    context_files:
      - src/models/
    summary: null  # Filled after completion with 3-5 bullet summary

  - id: task-002
    name: Implement registration endpoint
    description: |
      Create the user registration API endpoint.
    status: pending
    depends_on:
      - task-001
    context_files:
      - src/api/
      - src/models/user.py
    summary: null
```

## Dependency Resolution Examples

### Example 1: Simple Linear Dependencies

```yaml
tasks:
  - id: task-001
    status: completed
    depends_on: []

  - id: task-002
    status: pending
    depends_on: [task-001]  # READY (task-001 complete)

  - id: task-003
    status: pending
    depends_on: [task-002]  # BLOCKED (task-002 pending)
```

Result: task-002 is the next ready task.

### Example 2: Parallel Tasks

```yaml
tasks:
  - id: task-001
    status: completed
    depends_on: []

  - id: task-002
    status: pending
    depends_on: [task-001]  # READY

  - id: task-003
    status: pending
    depends_on: [task-001]  # READY

  - id: task-004
    status: pending
    depends_on: [task-002, task-003]  # BLOCKED
```

Result: task-002 and task-003 are both ready. task-002 selected (first by ID).

### Example 3: Multiple Dependencies

```yaml
tasks:
  - id: task-001
    status: completed
    depends_on: []

  - id: task-002
    status: completed
    depends_on: []

  - id: task-003
    status: pending
    depends_on: [task-001, task-002]  # READY (both deps complete)
```

Result: task-003 is ready.

### Example 4: Mixed Status Dependencies

```yaml
tasks:
  - id: task-001
    status: completed
    depends_on: []

  - id: task-002
    status: skipped
    depends_on: []

  - id: task-003
    status: pending
    depends_on: [task-001, task-002]  # READY (skipped counts as satisfied)
```

Result: task-003 is ready (skipped dependencies are treated as satisfied).

## Example Usage Session

```
User: /projspec.implement

Claude:
1. Detects spec a1b2c3d4 (user-auth) in "tasks" phase
2. Updates phase: tasks -> implement
3. Loads task list from state.yaml
4. Analyzes dependencies:
   - task-001: READY (no dependencies)
   - task-002: BLOCKED (depends on task-001)
   - task-003: BLOCKED (depends on task-001)
5. Presents task-001 as next ready task
6. User confirms to start
7. Updates task-001 status: pending -> in_progress
8. Loads context:
   - Reads spec.md summary
   - Reads plan.md Build Order
   - Lists context files
9. Implements the task
10. User confirms completion
11. Generates 3-5 bullet summary
12. Updates task-001: status -> completed, summary saved
13. Reports progress: 1/3 complete
14. Shows task-002 and task-003 now ready
15. Continues or pauses based on user choice
```

## Notes

- Always update state.yaml after status changes to persist progress
- Task IDs are immutable - never modify them during implementation
- The summary field is critical for context injection in dependent tasks
- Context loading should be efficient - summarize large files instead of loading entirely
- The phase transitions from "tasks" to "implement" on first task start
- The phase transitions from "implement" to "review" when all tasks complete
- Skipped tasks satisfy dependencies - use sparingly for optional tasks
- Resume capability: If Claude is interrupted, running /projspec.implement again will resume from the last saved state

## Feature Reference

This command implements the following features:
- **T049**: Task dependency resolution (find next ready task)
- **T050**: Next-ready-task finder (pending status, all depends_on completed)
- **T051**: Context injection (load spec.md, plan.md, completed task summaries)
- **T052**: Task status update to "in_progress" when starting
- **T053**: 3-5 bullet summary generation on task completion
- **T054**: Task status update to "completed" with summary storage
- **T055**: "All tasks complete" detection with review suggestion
- **T056**: Blocked task display showing which dependencies are incomplete
- **T057**: Phase update from "tasks" to "implement" on first task start

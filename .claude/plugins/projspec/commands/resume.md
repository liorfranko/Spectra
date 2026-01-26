---
description: Resume interrupted work on current spec
arguments: []
---

# /projspec.resume Command

This command detects the current state of specs and helps resume work where you left off. It identifies active specs, checks for in-progress tasks, and suggests the appropriate next action based on the current phase.

## Use Cases

- Returning to work after a break
- Context switching between specs
- Finding where you left off in a multi-task implementation
- Understanding current project state

## Execution Steps

Follow these steps exactly to detect and resume work:

### Step 1: Detect Environment

First, determine if we're in a worktree or the main repository.

Check if we're in a git worktree:

```bash
git rev-parse --git-common-dir 2>/dev/null
```

Compare with the git directory:

```bash
git rev-parse --git-dir 2>/dev/null
```

**Interpretation:**
- If `--git-common-dir` differs from `--git-dir`, we are in a worktree
- If they are the same, we are in the main repository

Also get the current directory path:

```bash
pwd
```

Store the result as `IS_WORKTREE` (true/false) and `CURRENT_DIR`.

### Step 2: Find Active Specs

List all active specs:

```bash
ls .projspec/specs/active/ 2>/dev/null || echo "NO_SPECS"
```

If the result is "NO_SPECS" or empty, output:

```
No active specs found.

To get started:
  1. Initialize ProjSpec: /projspec.init
  2. Create a new spec: /projspec.new <spec-name>
```

Stop here if no specs exist.

### Step 3: Load All Spec States

For each spec found, read its state.yaml:

```bash
cat .projspec/specs/active/{SPEC_ID}/state.yaml
```

Collect the following for each spec:
- `spec_id`: The spec identifier
- `name`: The spec name
- `phase`: Current phase (new, spec, plan, tasks, implement, review)
- `worktree_path`: Path to the worktree
- `tasks`: List of tasks (if any)

### Step 4: Detect In-Progress Tasks

For specs in the "implement" phase, scan the tasks array for any task with `status: in_progress`:

**For each spec:**
1. Parse the `tasks` array from state.yaml
2. Find tasks where `status` equals `in_progress`
3. Record the task ID and name

Store results as `IN_PROGRESS_TASKS` for each spec.

### Step 5: Detect Current Spec from Worktree

If `IS_WORKTREE` is true, try to match the current directory to a spec's worktree:

```bash
basename "$PWD" | grep -oE 'spec-[a-f0-9]{8}'
```

Or extract from the current path:

```bash
echo "$PWD" | grep -oE '[a-f0-9]{8}'
```

Cross-reference with the loaded specs to find `CURRENT_SPEC_ID`.

### Step 6: Present Status Summary

Output a status summary with this format:

**Single Active Spec:**

```
Resume Status
=============

Current Spec: {SPEC_NAME} ({SPEC_ID})
Phase: {PHASE}
Worktree: {WORKTREE_PATH}

{PHASE_SPECIFIC_STATUS}

Recommended Action:
  {NEXT_COMMAND}
```

**Multiple Active Specs:**

```
Resume Status
=============

You have {COUNT} active specs:

| ID       | Name          | Phase     | Progress        | Status      |
|----------|---------------|-----------|-----------------|-------------|
| {ID}     | {NAME}        | {PHASE}   | {PROGRESS}      | {STATUS}    |

{CURRENT_SPEC_INDICATOR if in worktree}

Which spec would you like to resume? Enter the spec ID, or:
  - "current" to continue with {CURRENT_SPEC_ID} (if in worktree)
  - "list" for more details about each spec
```

### Step 7: Generate Phase-Specific Guidance

Based on the phase of the selected spec, provide specific guidance:

#### Phase: new

```
Phase Status: new (awaiting specification)

The brief.md has been created but the specification hasn't been generated yet.

Files to review:
  - {WORKTREE_PATH}/specs/{SPEC_ID}/brief.md

Recommended Action:
  /projspec.spec

This will create a structured specification from your brief.
```

#### Phase: spec

```
Phase Status: spec (awaiting implementation plan)

The specification document exists. Review it before creating the plan.

Files to review:
  - {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md
  - {WORKTREE_PATH}/specs/{SPEC_ID}/brief.md

Recommended Action:
  /projspec.plan

This will create an implementation plan from your specification.
```

#### Phase: plan

```
Phase Status: plan (awaiting task generation)

The implementation plan exists. Review it before generating tasks.

Files to review:
  - {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md
  - {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md

Recommended Action:
  /projspec.tasks

This will generate implementation tasks from your plan.
```

#### Phase: tasks

```
Phase Status: tasks (ready for implementation)

Tasks have been generated and are ready for implementation.

Task Summary:
  - Total tasks: {TOTAL_COUNT}
  - Pending: {PENDING_COUNT}
  - Completed: {COMPLETED_COUNT}

Ready to Start (no dependencies):
  - {TASK_ID}: {TASK_NAME}
  - {TASK_ID}: {TASK_NAME}

Recommended Action:
  /projspec.implement

This will start implementing the first available task.
```

#### Phase: implement (with in-progress task)

```
Phase Status: implement (task in progress)

You have a task that was started but not completed:

In Progress:
  - {TASK_ID}: {TASK_NAME}
    Description: {TASK_DESCRIPTION_FIRST_LINE}
    Context files: {CONTEXT_FILES}

Task Progress:
  - Completed: {COMPLETED_COUNT}/{TOTAL_COUNT}
  - In Progress: {IN_PROGRESS_COUNT}
  - Pending: {PENDING_COUNT}

Recommended Action:
  Continue working on task {TASK_ID}

  To resume this task, you can:
  1. Review context files: {CONTEXT_FILES}
  2. Continue implementation based on the task description
  3. When done, mark complete and run /projspec.implement for next task

Or if you need to skip this task:
  /projspec.implement --skip {TASK_ID}
```

#### Phase: implement (no in-progress tasks)

```
Phase Status: implement (ready for next task)

Implementation is underway. No tasks are currently in progress.

Task Progress:
  - Completed: {COMPLETED_COUNT}/{TOTAL_COUNT}
  - Pending: {PENDING_COUNT}

Next Available Tasks:
  - {TASK_ID}: {TASK_NAME}
  - {TASK_ID}: {TASK_NAME}

Recommended Action:
  /projspec.implement

This will pick up the next available task.
```

#### Phase: implement (all tasks complete)

```
Phase Status: implement (all tasks complete)

All implementation tasks have been completed!

Task Summary:
  - Total: {TOTAL_COUNT}
  - Completed: {COMPLETED_COUNT}
  - Skipped: {SKIPPED_COUNT}

Recommended Action:
  /projspec.review

This will review the implementation against the specification.
```

#### Phase: review

```
Phase Status: review (under review)

Implementation is complete and under review.

Review Status:
  - Spec: {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md
  - Plan: {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md
  - Tasks: {COMPLETED_COUNT} completed

Recommended Actions:
  1. Verify all acceptance criteria from spec.md are met
  2. Run any test commands
  3. When satisfied, run: /projspec.archive to complete

Or if issues are found:
  - Create additional tasks for fixes
  - Run /projspec.implement to continue
```

### Step 8: Handle User Selection (Multiple Specs)

If there are multiple specs and the user provides a spec ID:

1. Validate the spec ID exists in the active specs
2. Load that spec's full state
3. Re-run Step 7 for the selected spec

If the user types "current" and they're in a worktree:
1. Use the `CURRENT_SPEC_ID` detected in Step 5
2. Proceed with that spec's state

If the user types "list":
1. Show detailed information for each spec (see Step 9)

### Step 9: Detailed Spec List (Optional)

When user requests "list", show detailed status for all specs:

```
Detailed Spec Status
====================

Spec 1: {SPEC_NAME} ({SPEC_ID})
---------------------------------
  Phase: {PHASE}
  Branch: {BRANCH}
  Worktree: {WORKTREE_PATH}
  Created: {CREATED_AT}
  Tasks: {TASK_SUMMARY}
  Next Action: {RECOMMENDED_COMMAND}

Spec 2: {SPEC_NAME} ({SPEC_ID})
---------------------------------
  ...

Enter a spec ID to resume, or "back" to see the summary.
```

## Error Handling

### Missing state.yaml

If a spec directory exists but state.yaml is missing:

```
Warning: Spec {SPEC_ID} has no state.yaml file.
This spec may be corrupted. Consider:
  1. Recreating it with /projspec.new
  2. Manually creating state.yaml in .projspec/specs/active/{SPEC_ID}/
```

### Invalid state.yaml

If state.yaml exists but cannot be parsed:

```
Warning: Spec {SPEC_ID} has an invalid state.yaml file.
Please check the file format:
  cat .projspec/specs/active/{SPEC_ID}/state.yaml
```

### Missing worktree

If the worktree path in state.yaml doesn't exist:

```
Warning: Worktree not found at {WORKTREE_PATH}

The worktree may have been deleted. Options:
  1. Recreate worktree: git worktree add {WORKTREE_PATH} {BRANCH}
  2. Archive the spec: /projspec.archive --force
  3. Update state.yaml with correct path
```

### Orphaned worktree

If in a worktree that doesn't match any active spec:

```
Note: You're in a worktree that doesn't match any active spec.

Current directory: {CURRENT_DIR}

This may be:
  - An archived spec's worktree
  - A manually created worktree
  - A worktree from another project

Suggestion: Navigate to the main repository or an active spec worktree.
```

## Example Usage

### Example 1: Single Spec in Progress

```
User: /projspec.resume

Claude:
Resume Status
=============

Current Spec: user-auth (a1b2c3d4)
Phase: implement
Worktree: worktrees/spec-a1b2c3d4-user-auth

Phase Status: implement (task in progress)

You have a task that was started but not completed:

In Progress:
  - task-003: Implement registration endpoint
    Description: Create the user registration API endpoint with validation.
    Context files: src/api/, src/models/user.py

Task Progress:
  - Completed: 2/6
  - In Progress: 1
  - Pending: 3

Recommended Action:
  Continue working on task task-003
```

### Example 2: Multiple Specs

```
User: /projspec.resume

Claude:
Resume Status
=============

You have 2 active specs:

| ID       | Name          | Phase     | Progress  | Status        |
|----------|---------------|-----------|-----------|---------------|
| a1b2c3d4 | user-auth     | implement | 2/6 tasks | task-003 WIP  |
| e5f6g7h8 | payment-api   | plan      | 0/0 tasks | awaiting tasks|

You are currently in: worktrees/spec-a1b2c3d4-user-auth

Which spec would you like to resume? Enter the spec ID, or:
  - "current" to continue with a1b2c3d4
  - "list" for more details about each spec
```

### Example 3: Fresh Start After Init

```
User: /projspec.resume

Claude:
No active specs found.

To get started:
  1. Initialize ProjSpec: /projspec.init
  2. Create a new spec: /projspec.new <spec-name>
```

### Example 4: All Tasks Complete

```
User: /projspec.resume

Claude:
Resume Status
=============

Current Spec: user-auth (a1b2c3d4)
Phase: implement
Worktree: worktrees/spec-a1b2c3d4-user-auth

Phase Status: implement (all tasks complete)

All implementation tasks have been completed!

Task Summary:
  - Total: 6
  - Completed: 6
  - Skipped: 0

Recommended Action:
  /projspec.review

This will review the implementation against the specification.
```

## Notes

- The resume command is non-destructive; it only reads state
- It provides context-aware guidance based on current phase
- Multiple active specs are supported with user selection
- In-progress tasks are highlighted for immediate continuation
- Worktree detection helps identify the current working context
- Progress tracking shows completion status for implement phase

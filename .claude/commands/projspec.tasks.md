---
description: Generate implementation tasks from the plan.md document
---

# /projspec.tasks Command

This command generates an implementation task list from the plan.md document. It parses the implementation plan and creates structured tasks with IDs, dependencies, and context files that are stored in state.yaml.

## Quick Reference

```
/projspec.tasks
```

Reads `plan.md` and generates a structured task list with dependencies, stored in `state.yaml`.

## Prerequisites

- A spec must exist and be in the "plan" phase
- The plan.md file should be populated with the implementation plan
- User should be in the spec's worktree or the main repository

## Execution Steps

Follow these steps exactly to generate the task list:

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

Which spec would you like to generate tasks for? Please provide the spec ID.
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
- `tasks`: Existing task list (may be empty or populated)

### Step 3: Validate Phase is "plan"

Check that the current phase is "plan". Handle other phases accordingly:

**If phase is "new":**
```
This spec is still in the "new" phase.

The specification document must be created first.
Please run: /projspec.spec

Then /projspec.plan to create the implementation plan.
Then /projspec.tasks to generate tasks.
```

**If phase is "spec":**
```
This spec is in the "spec" phase.

The implementation plan must be created first.
Please run: /projspec.plan

Then run /projspec.tasks after the plan.md is complete.
```

**If phase is "tasks" or later:**
```
This spec already has a task list.

Current phase: {PHASE}
Tasks: {TASK_COUNT} tasks defined

Would you like to:
1. View the existing task list
2. Regenerate the task list (this will replace all existing tasks)
3. Add additional tasks to the existing list

Please choose an option.
```

Handle each option:
- **Option 1**: Display the current task list in a formatted table and stop.
- **Option 2**: Proceed with task regeneration (continue to Step 4).
- **Option 3**: Proceed to Step 4 but preserve existing tasks and append new ones.

### Step 4: Read plan.md

Read the implementation plan from the worktree:

```bash
cat {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md
```

If the file doesn't exist or is empty, output this error:

```
Error: plan.md not found or empty at {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md

Please create the implementation plan first with: /projspec.plan
```

### Step 5: Analyze Plan Structure

Parse the plan.md to identify:

1. **Build Order sections**: Look for "Build Order", "Implementation Phases", or numbered phases
2. **Individual tasks**: Each numbered item or bullet point within phases
3. **File references**: Paths mentioned with each task (e.g., `Files: src/models/user.py`)
4. **Dependencies**: Tasks that reference other tasks or phases

Extract the following for each potential task:
- Task description/name
- Associated files or directories
- Phase grouping
- Any explicit dependencies mentioned

### Step 6: Generate Task List

Create tasks following this structure. Each task should have:

#### Task ID Generation

Generate sequential task IDs in the format `task-NNN`:
- `task-001`, `task-002`, `task-003`, etc.
- If adding to existing tasks, continue from the highest existing ID
- IDs must be unique within the spec

#### Task Name

Derive from the plan item:
- Keep names concise (under 80 characters)
- Use imperative form (e.g., "Create user model", "Implement authentication endpoint")
- Remove phase prefixes if present

#### Task Description

Create detailed descriptions that include:
- What needs to be done
- Any specific requirements from the plan
- References to relevant sections in spec.md or plan.md
- Clear acceptance criteria where applicable

#### Dependency Detection

Determine dependencies based on:

1. **Explicit phase ordering**: Tasks in Phase 2 depend on Phase 1 completion
2. **File dependencies**: If Task B modifies a file created by Task A, Task B depends on Task A
3. **Logical dependencies**: Model creation before endpoint implementation
4. **Explicit mentions**: "After [X] is complete", "Requires [Y]", "Depends on [Z]"

Rules for dependency assignment:
- Tasks within the same phase with no other dependencies can run in parallel (empty `depends_on`)
- First task in a phase may depend on the last task(s) of the previous phase
- Use the smallest dependency set that ensures correct ordering
- Avoid circular dependencies

#### Context Files Population

Determine relevant context files based on:

1. **Explicit file references**: Files mentioned in the plan task
2. **Directory patterns**: Use directory paths for broad scope (e.g., `src/models/`)
3. **Related files**: Include test files that correspond to implementation files
4. **Common patterns**:
   - Model files: `src/models/`, `models/`
   - Test files: `tests/`, `test_*.py`
   - API files: `src/api/`, `routes/`
   - Config files: `*.yaml`, `*.json`

Use glob patterns where appropriate:
- `src/models/*.py` for all Python files in models
- `tests/unit/test_*.py` for unit test files

### Step 7: Create Task Objects

For each identified task, create a task object with this structure:

```yaml
- id: task-001
  name: [Concise task name]
  description: |
    [Detailed description of what needs to be done]

    From plan.md:
    - [Relevant detail from plan]
    - [Relevant detail from plan]
  status: pending
  depends_on: []  # or [task-XXX, task-YYY]
  context_files:
    - [path/to/relevant/file/or/directory]
  summary: null
```

### Step 8: Validate Task List

Before saving, validate:

1. **No duplicate IDs**: Each task ID must be unique
2. **Valid dependencies**: All `depends_on` references must point to valid task IDs
3. **No circular dependencies**: Verify no circular dependency chains exist
4. **Context files exist**: Warn if context_files reference non-existent paths (but don't fail)

Circular dependency check algorithm:
```
For each task:
  Mark as visiting
  For each dependency:
    If dependency is visiting: CIRCULAR DEPENDENCY DETECTED
    If dependency not visited: recurse
  Mark as visited
```

If validation fails, report the issues and ask user to confirm before proceeding.

### Step 9: Present Task List for Review

Before updating state.yaml, present the generated tasks:

```
Generated {TASK_COUNT} tasks from plan.md:

| ID       | Name                            | Dependencies | Context Files |
|----------|--------------------------------|--------------|---------------|
| task-001 | [Task name]                    | -            | src/models/   |
| task-002 | [Task name]                    | task-001     | src/api/      |
| task-003 | [Task name]                    | task-001     | tests/        |
...

Dependency Graph:
task-001 (Create user model)
  |
  +-- task-002 (Implement registration endpoint)
  |
  +-- task-003 (Add unit tests)

Would you like to:
1. Accept this task list
2. Modify tasks before saving (add/remove/edit)
3. Regenerate with different granularity (more/fewer tasks)

Please choose an option.
```

**Option 1**: Proceed to Step 10.
**Option 2**: Enter interactive edit mode where user can specify changes.
**Option 3**: Ask for granularity preference and regenerate.

### Step 10: Update state.yaml

Update the state.yaml file with the generated tasks:

Read the current state.yaml:
```bash
cat .projspec/specs/active/{SPEC_ID}/state.yaml
```

Update the following fields:
- `phase`: Change from "plan" to "tasks"
- `tasks`: Replace with the generated task list

Write the updated content back to state.yaml.

The updated state.yaml should look like:

```yaml
# Projspec State File
# Auto-generated by /projspec.new
# Tasks generated by /projspec.tasks

spec_id: {SPEC_ID}
name: {SPEC_NAME}
phase: tasks
created_at: {CREATED_AT}
branch: {BRANCH_NAME}
worktree_path: {WORKTREE_PATH}

tasks:
  - id: task-001
    name: Create user model
    description: |
      Create the User model with fields for authentication.
      Include email validation and password hashing.
    status: pending
    depends_on: []
    context_files:
      - src/models/
    summary: null

  - id: task-002
    name: Implement registration endpoint
    description: |
      Create the user registration API endpoint.
      Handle validation and error responses.
    status: pending
    depends_on:
      - task-001
    context_files:
      - src/api/
      - src/models/user.py
    summary: null

  # ... additional tasks
```

### Step 11: Create tasks.md Summary (Optional)

Create a human-readable task summary at `{WORKTREE_PATH}/specs/{SPEC_ID}/tasks.md`:

```markdown
# {SPEC_NAME} Tasks

> Auto-generated by /projspec.tasks from plan.md

---

## Overview

- **Total Tasks**: {TASK_COUNT}
- **Generated From**: plan.md
- **Generated At**: {TIMESTAMP}

---

## Task List

### Phase 1: Foundation

#### task-001: [Task Name]
- **Status**: pending
- **Dependencies**: None
- **Context Files**: `src/models/`
- **Description**: [Task description]

#### task-002: [Task Name]
- **Status**: pending
- **Dependencies**: task-001
- **Context Files**: `src/api/`, `src/models/user.py`
- **Description**: [Task description]

### Phase 2: Core Implementation

#### task-003: [Task Name]
...

---

## Dependency Graph

```
task-001
├── task-002
└── task-003
    └── task-004
```

---

## Implementation Order

Recommended implementation sequence:

1. task-001 - [Name] (no dependencies)
2. task-002 - [Name] (after task-001)
3. task-003 - [Name] (after task-001)
4. task-004 - [Name] (after task-003)

---

**Note**: This file is for reference. The source of truth is `.projspec/specs/active/{SPEC_ID}/state.yaml`.
```

### Step 12: Output Success Message

Report success to the user:

```
Tasks generated successfully!

  Spec ID:     {SPEC_ID}
  Name:        {SPEC_NAME}
  Phase:       plan -> tasks
  Tasks:       {TASK_COUNT} tasks generated
  State file:  .projspec/specs/active/{SPEC_ID}/state.yaml
  Summary:     {WORKTREE_PATH}/specs/{SPEC_ID}/tasks.md

Task Summary:
  - Ready to start: {READY_COUNT} tasks (no dependencies)
  - Blocked: {BLOCKED_COUNT} tasks (waiting on dependencies)

First available tasks:
  - task-001: [Task name]
  - task-002: [Task name] (if no dependencies)

Next steps:
  1. Review the generated tasks in state.yaml or tasks.md
  2. When ready, run: /projspec.implement to start implementation
```

## Error Handling

If any step fails:
- For missing plan.md: Guide user to create implementation plan first with /projspec.plan
- For phase "new" or "spec": Redirect to appropriate earlier command
- For existing tasks (regenerate): Confirm with user before overwriting
- For state.yaml read/write errors: Check file permissions and path
- For circular dependencies: Report the cycle and suggest resolution

Report the specific error and suggest remediation steps.

## Task Generation Examples

### Example 1: Simple Sequential Tasks

Plan.md excerpt:
```
### Phase 1: Foundation
1. Create User model in src/models/user.py
2. Add database migration for users table

### Phase 2: API
3. Implement /register endpoint
4. Implement /login endpoint
```

Generated tasks:
```yaml
tasks:
  - id: task-001
    name: Create User model
    description: Create User model in src/models/user.py with authentication fields.
    status: pending
    depends_on: []
    context_files:
      - src/models/
    summary: null

  - id: task-002
    name: Add database migration for users table
    description: Create database migration for the users table schema.
    status: pending
    depends_on:
      - task-001
    context_files:
      - migrations/
      - src/models/user.py
    summary: null

  - id: task-003
    name: Implement /register endpoint
    description: Create user registration API endpoint with validation.
    status: pending
    depends_on:
      - task-002
    context_files:
      - src/api/
      - src/models/user.py
    summary: null

  - id: task-004
    name: Implement /login endpoint
    description: Create user login API endpoint with authentication.
    status: pending
    depends_on:
      - task-002
    context_files:
      - src/api/
      - src/models/user.py
    summary: null
```

### Example 2: Parallel Tasks

Plan.md excerpt:
```
### Phase 1: Models (can be parallel)
1. Create User model
2. Create Product model
3. Create Order model

### Phase 2: API (depends on all models)
4. Implement user endpoints
```

Generated tasks:
```yaml
tasks:
  - id: task-001
    name: Create User model
    depends_on: []

  - id: task-002
    name: Create Product model
    depends_on: []

  - id: task-003
    name: Create Order model
    depends_on: []

  - id: task-004
    name: Implement user endpoints
    depends_on:
      - task-001
      - task-002
      - task-003
```

## Example Usage

```
User: /projspec.tasks

Claude:
1. Detects spec a1b2c3d4 (user-auth) in "plan" phase
2. Reads plan.md content
3. Parses build order and task descriptions
4. Generates task-001 through task-006
5. Detects dependencies based on phases and file references
6. Populates context_files from file paths in plan
7. Presents task list for user review
8. User accepts the task list
9. Updates state.yaml with tasks and phase "tasks"
10. Creates tasks.md summary
11. Reports success with next steps
```

## Notes

- Task granularity should match the detail level in plan.md
- Each task should be completable in a single focused session
- Dependencies should create a DAG (Directed Acyclic Graph)
- Context files help with code navigation during implementation
- The tasks.md file is optional and for human reference only
- Source of truth for tasks is always state.yaml
- Task IDs are immutable once created to maintain reference integrity

## See Also

- `/projspec.plan` - Create implementation plan (previous step)
- `/projspec.implement` - Start implementing tasks (next step)
- `/projspec.status` - View all active specs and task progress

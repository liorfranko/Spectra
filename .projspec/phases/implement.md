# Implementation Phase Template

This template guides iterative task execution during the implementation phase. Work through tasks one by one, maintaining context and tracking progress.

---

## Task Selection

### Finding the Next Ready Task

A task is **ready** when:
1. Status is `pending`
2. All tasks in its `depends_on` list have status `completed`

**From state.yaml tasks list:**
```yaml
tasks:
  - id: T001
    name: "Task name"
    status: pending        # pending | in_progress | completed | skipped
    depends_on: []         # Empty = ready immediately
    context_files:
      - "src/module/*.py"  # Glob patterns for relevant files
    summary: null          # Populated after completion
```

### Task Priority Order

1. Select the first task where `status: pending` and all `depends_on` tasks are `completed`
2. If multiple tasks are ready, prefer tasks marked with `[P]` (parallelizable) first
3. Follow the task ID order (T001, T002, etc.) for deterministic execution

---

## Starting a Task

### Step 1: Mark Task In Progress

Update state.yaml:
```yaml
- id: T001
  status: in_progress  # Changed from pending
```

### Step 2: Load Context Files

Read all files matching the `context_files` glob patterns for the task.

**Example:**
```yaml
context_files:
  - "src/projspec/models.py"
  - "src/projspec/*.py"
  - "tests/unit/test_models.py"
```

Always include files from project configuration:
- Files in `config.context.always_include` (e.g., CLAUDE.md)
- The spec document for the current feature
- Related design artifacts (plan.md, data-model.md)

### Step 3: Understand Requirements

Before implementing:
1. Read the task description carefully
2. Review related spec sections
3. Check for patterns in existing code
4. Identify files to create or modify

---

## Implementation Guidelines

### Code Quality

- Follow existing code patterns and conventions
- Match the style of surrounding code
- Keep changes focused on the task scope
- Avoid scope creep - create new tasks for discovered work

### File Operations

- **Creating files**: Include appropriate headers, docstrings, imports
- **Modifying files**: Make minimal, targeted changes
- **Deleting files**: Only when explicitly required by task

### Testing Considerations

If the project includes tests:
- Run relevant tests after changes
- Fix failing tests before marking complete
- Add tests if the task description requires them

---

## Completing a Task

### Step 1: Verify Implementation

- [ ] Code compiles/runs without errors
- [ ] Functionality works as described
- [ ] No unintended side effects
- [ ] Tests pass (if applicable)

### Step 2: Generate Summary

Create a 3-5 bullet summary of what was accomplished. Be specific:

**Good Summary:**
```yaml
summary: |
  - Created TaskState Pydantic model with 6 fields (id, name, description, status, depends_on, context_files)
  - Added TaskStatus enum with pending, in_progress, completed, skipped values
  - Implemented Field validators for id pattern matching
  - Added docstrings explaining each field's purpose
  - Exported model in __init__.py
```

**Poor Summary:**
```yaml
summary: |
  - Added the model
  - Made some changes
  - It works now
```

### Step 3: Commit Changes

Use conventional commit format with task reference:

```
[T001] Brief description of changes

- Bullet point of specific change
- Bullet point of specific change

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Step 4: Update State

```yaml
- id: T001
  status: completed      # Changed from in_progress
  summary: |
    - Created TaskState Pydantic model...
    - Added TaskStatus enum...
```

---

## Progress Tracking

### Overall Progress Display

Show progress at the start of each task:

```
=== Implementation Progress ===
Phase: implement
Completed: 5/20 tasks (25%)
In Progress: 1 task (T006)
Ready: 3 tasks (T007, T008, T009)
Blocked: 11 tasks

Current Task: T006 - Create SpecState Pydantic model
Dependencies: T005 (completed)
Context Files: src/projspec/models.py
```

### Checkpoint Recognition

Tasks.md may contain checkpoint markers:

```markdown
**Checkpoint**: Foundation ready - Pydantic models complete
```

When reaching a checkpoint:
1. Summarize completed phase
2. Verify all checkpoint tasks are complete
3. Note transition to next phase of tasks

---

## Handling Edge Cases

### Blocked Tasks

If a task cannot be completed due to:
- Missing dependency not in task list
- Unclear requirements
- Technical blocker

**Action:**
1. Document the blocker in the task summary
2. Set status to `skipped` with reason
3. Continue to next ready task
4. Flag for human review

### Discovered Work

If implementation reveals additional needed work:
1. Complete the current task scope
2. Note additional work in summary
3. Do NOT create new tasks (that's the human's role)
4. Continue with existing task list

### Failed Attempts

If an approach doesn't work:
1. Revert changes
2. Try alternative approach
3. If stuck, document in summary and skip

---

## Context Injection Best Practices

### Minimal Context Loading

Only load files relevant to the current task:
- Start with explicit `context_files`
- Add dependencies discovered during implementation
- Avoid loading entire codebase

### State Preservation

Between tasks:
- State.yaml reflects current progress
- Each task summary provides context for future tasks
- Completed work is committed to git

### Resumability

Implementation can be paused and resumed:
- All progress is in state.yaml
- Git commits preserve code changes
- Summaries provide implementation context

---

**Phase Checklist**

Before moving to the review phase, ensure:

- [ ] All tasks have status `completed` or `skipped`
- [ ] Each completed task has a summary
- [ ] All changes are committed to git
- [ ] Tests pass (if applicable)
- [ ] Skipped tasks have documented reasons
- [ ] No tasks remain in `in_progress` status

# Command: implement

## Purpose

Execute tasks sequentially from tasks.md with proper context preservation and progress tracking. This command transforms a validated task breakdown into working code by processing each task one at a time, maintaining context between tasks, and producing atomic commits for each completed task.

The implementation process:
1. Reads tasks.md, plan.md, spec.md, and any previous task summaries
2. Identifies the next ready task (dependencies satisfied, not blocked)
3. Loads relevant context for that task
4. Marks the task as in_progress
5. Implements the task following the plan and spec requirements
6. Generates a 3-5 bullet summary of changes made
7. Marks the task as completed
8. Creates a git commit with [TaskID] format
9. Moves to the next task or reports completion
10. Updates feature state to "implement" phase

---

## Prerequisites

Before running this command, verify the following:

1. **Existing tasks.md**: The feature must have a tasks.md file already created (via the `tasks` command)
2. **Feature in tasks/implement phase**: The feature should be in the tasks or implement phase
3. **Spec.md exists**: The original specification should be available for reference
4. **Plan.md exists**: The implementation plan should be available for reference
5. **Feature directory exists**: The feature's specification directory must exist (e.g., `specs/{ID}-{feature-slug}/` or `.specify/features/{ID}-{feature-slug}/`)
6. **Working in feature context**: You should be in the feature's worktree or have the feature context loaded
7. **Clean git state**: The working directory should have no uncommitted changes (or changes should be stashed)

If prerequisites are not met, inform the user:
- If no tasks.md exists, suggest running the `tasks` command first
- If tasks.md is empty or has no pending tasks, report that implementation is complete
- If no spec.md or plan.md exists, suggest running the appropriate commands first
- If there are uncommitted changes, suggest committing or stashing them first

---

## Workflow

Follow these steps in order:

### Step 1: Locate and Read Required Documents

Find and read the following documents:

1. **Task List**: Locate tasks.md for the current feature
   - Check the current directory for tasks.md
   - Check `specs/{feature-slug}/tasks.md`
   - Check `.specify/features/{feature-slug}/tasks.md`

2. **Implementation Plan**: Read plan.md for technical approach
   - Architecture and design decisions
   - File structure and organization
   - Implementation phases and order

3. **Feature Specification**: Read spec.md for requirements
   - User stories with acceptance criteria
   - Functional requirements (FR-XXX)
   - Non-functional requirements (NFR-XXX)
   - Success criteria

4. **Data Model** (if exists): Read data-model.md
   - Entity definitions and relationships
   - State transitions
   - Validation rules

5. **API Contracts** (if exists): Read contracts/ directory
   - API specifications
   - Interface definitions
   - Schema definitions

6. **Previous Task Summaries** (if exists): Read task-summaries.md or similar
   - Context from previously completed tasks
   - Decisions made during implementation
   - Files created or modified

Read all documents thoroughly before proceeding.

### Step 2: Analyze Task Status and Dependencies

Review all tasks in tasks.md and categorize them:

#### Identify Completed Tasks
- Tasks with Status: Completed
- Note their summaries for context

#### Identify Blocked Tasks
- Tasks with Status: Blocked
- Note the blocker and whether it can be resolved

#### Identify Ready Tasks
A task is ready when:
- Status is "Pending" (not Completed, In Progress, or Blocked)
- All dependencies are satisfied (dependent tasks are Completed)
- No external blockers prevent work

#### Build the Ready Queue
Order ready tasks by:
1. Phase (lower phases first: Phase 0 before Phase 1, etc.)
2. Dependencies (tasks that unblock others have priority)
3. Priority level (P1 before P2 before P3)
4. Task ID (lower IDs first for deterministic ordering)

### Step 3: Select the Next Task

From the ready queue, select the first task to work on.

If no tasks are ready:
- If all tasks are completed, proceed to Step 10 (Completion)
- If tasks are blocked, report the blockers and ask for resolution
- If tasks are waiting on in-progress tasks, report the current state

For the selected task, extract:
- Task ID (e.g., T001)
- Task title and description
- Acceptance criteria
- Files to create/modify
- Dependencies (for context of what was already done)
- Context files (links to spec.md, plan.md sections)

### Step 4: Load Task Context

Before starting implementation, load all relevant context:

#### From Dependencies
For each completed dependency task:
1. Read the summary of what was implemented
2. Identify files created or modified
3. Understand interfaces or APIs exposed
4. Note any decisions or patterns established

#### From Plan.md
1. Locate the relevant section for this task
2. Understand the technical approach
3. Review file structure decisions
4. Check for implementation notes or warnings

#### From Spec.md
1. Find the user story (look for [US{N}] in task title)
2. Review acceptance criteria
3. Check success criteria related to this task
4. Note any constraints or requirements

#### From Contracts/Data Model
1. Review relevant entity definitions
2. Check API contracts for endpoints
3. Understand validation rules
4. Note schema requirements

### Step 5: Mark Task as In Progress

Update tasks.md to reflect the task is being worked on:

```markdown
#### T{NNN}: {Task Title}

- **Status**: In Progress  <!-- Changed from Pending -->
- **Priority**: {PRIORITY}
- **Estimated Effort**: {EFFORT}
- **Dependencies**: {DEPS}
```

Update the Progress Summary table:
- Increment "In Progress" count
- Decrement "Pending" count

### Step 6: Implement the Task

Execute the task according to its description and acceptance criteria.

#### Implementation Guidelines

**Follow the Plan**:
- Implement exactly what the task describes
- Use the file structure from plan.md
- Follow established patterns from earlier tasks
- Reference contracts and data models

**Code Quality**:
- Write clean, readable code
- Add appropriate comments
- Follow project coding standards
- Handle errors appropriately

**Testing**:
- Write tests if the task specifies
- Ensure existing tests pass
- Validate against acceptance criteria

**Scope Discipline**:
- Only implement what the task requires
- Do not add extra features "while you're at it"
- If you discover needed work, create a new task
- Note any issues in the task notes

#### Handling Issues During Implementation

**Blocker Discovered**:
1. Mark the task as Blocked in tasks.md
2. Document the blocker in the Blocked Tasks table
3. Move to the next ready task (if any)
4. Report the blocker to the user

**Task is Larger Than Expected**:
1. Complete a logical subset if possible
2. Create new tasks for remaining work
3. Document the split in task notes
4. Continue with next steps

**Design Decision Needed**:
1. Check plan.md for guidance
2. Check constitution.md for principles
3. If unclear, document the decision made and rationale
4. Continue implementation

**Dependency Missing**:
1. Verify the dependency was actually completed
2. If missing, add it as a blocker
3. Move to next ready task

### Step 7: Verify Implementation

Before marking the task complete, verify:

#### Acceptance Criteria Check
For each acceptance criterion in the task:
- [ ] Verify the criterion is satisfied
- [ ] Document how it was met (for the summary)

#### Code Verification
- [ ] Code compiles/parses without errors
- [ ] Tests pass (run test suite if applicable)
- [ ] No linting errors (if linter is configured)
- [ ] Files are in the correct locations

#### Integration Check
- [ ] New code integrates with existing code
- [ ] Interfaces match contracts
- [ ] No breaking changes introduced

If any verification fails:
1. Fix the issue
2. Re-verify
3. Document what was fixed in the summary

### Step 8: Generate Task Summary

Create a concise summary of the implementation (3-5 bullets):

```markdown
### T{NNN} Summary: {Task Title}

**Changes Made**:
- {What was created or modified}
- {Key implementation decisions}
- {Any patterns established}
- {Tests added}
- {Notable considerations}

**Files Changed**:
- `{file_path}`: {brief description of changes}
- `{file_path}`: {brief description of changes}
```

Store this summary:
- Append to task-summaries.md (create if doesn't exist)
- Or add to a "Completed Tasks" section with summaries

### Step 9: Mark Task Complete and Commit

#### Update tasks.md

1. Mark the task as Completed:
```markdown
#### T{NNN}: {Task Title}

- **Status**: Completed  <!-- Changed from In Progress -->
```

2. Update Progress Summary:
   - Decrement "In Progress" count
   - Increment "Completed" count

3. Move task to Completed Tasks section (optional, but recommended for large task lists)

#### Create Git Commit

Stage all changes for this task and create a commit:

```bash
git add <relevant files>
git commit -m "[T{NNN}] {Brief description of what was implemented}

- {Summary bullet 1}
- {Summary bullet 2}
- {Summary bullet 3}

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Commit Message Format**:
- Start with `[T{NNN}]` task ID
- Include `[US{N}]` if task is linked to a user story
- Brief description on first line
- Bullets with key changes in body
- Include Co-Authored-By for AI assistance

Example:
```
[T015] [US1] Implement init command handler in CLI

- Added init subcommand to CLI using Typer
- Handler calls init service with project path
- Returns appropriate exit codes for success/failure

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Step 10: Continue or Complete

After completing a task, determine next action:

#### If More Ready Tasks Exist
1. Report the completed task to the user
2. Show progress summary (X of Y tasks completed)
3. Return to Step 2 to process the next task

#### If Tasks Are Blocked
1. Report the completed task
2. List blocked tasks and their blockers
3. Ask user how to proceed:
   - Resolve blockers and continue
   - Skip blocked tasks for now
   - End implementation session

#### If All Tasks Are Complete
1. Report final completion status
2. Proceed to Step 11 (Finalization)

### Step 11: Finalization

When all tasks are complete:

#### Update Feature State
- Mark feature as being in "implement" phase (complete)
- Update any state metadata files
- The feature is ready for review/testing

#### Generate Implementation Summary

```markdown
## Implementation Complete

### Summary:
- Total Tasks Completed: {N}
- Phase 0 (Setup): {N} tasks
- Phase 1 (Foundation): {N} tasks
- Phase 2+ (Features): {N} tasks
- Final Phase (Polish): {N} tasks

### Files Created:
- `{file_path}`: {description}
...

### Files Modified:
- `{file_path}`: {description}
...

### Commits Made:
- [T001] {Description}
- [T002] {Description}
...

### Next Steps:
1. Run test suite to verify implementation
2. Review against spec.md acceptance criteria
3. Perform manual testing with quickstart.md
4. Create pull request for review
```

#### Recommend Next Actions
- Run tests: `{test command from project}`
- Review: Compare implementation against spec.md
- Create PR: Use the appropriate PR creation command

---

## Output

Upon successful execution, the following will be produced:

### Files Created/Modified

| Type | Files | Description |
|------|-------|-------------|
| Source Code | Multiple | Implementation files as specified in tasks |
| Tests | Multiple | Test files as specified in tasks |
| tasks.md | Modified | Updated with task status changes |
| task-summaries.md | Created/Modified | Running log of task completion summaries |

### Git Commits

One commit per completed task with format:
- `[T{NNN}] {Description}` for general tasks
- `[T{NNN}] [US{N}] {Description}` for user story tasks

### Task Status

Each processed task will have:
- Status updated (Pending -> In Progress -> Completed)
- Summary recorded for context preservation
- Acceptance criteria verified

### Feature State

- Phase: `implement`
- Status: In Progress or Complete
- Progress: Tracked in tasks.md Progress Summary

---

## Examples

### Example 1: Single Task Implementation

**Scenario**: User runs implement with one ready task (T015).

**Actions**:
1. Read tasks.md, find T015 is ready (deps T001-T014 completed)
2. Load context from T001-T014 summaries
3. Mark T015 as In Progress
4. Implement the init command handler
5. Verify acceptance criteria
6. Generate summary:
   ```
   ### T015 Summary: Implement init command handler
   - Added init subcommand to CLI
   - Handler calls init service
   - Returns exit codes 0 (success) or 1 (error)
   ```
7. Commit: `[T015] [US1] Implement init command handler in CLI`
8. Mark T015 as Completed
9. Report: "Task T015 completed. 15 of 35 tasks done. Moving to T016..."

### Example 2: Blocked Task Handling

**Scenario**: T020 is blocked because external API is not available.

**Actions**:
1. Identify T020 as next ready task
2. Attempt implementation, discover API unavailable
3. Mark T020 as Blocked
4. Update Blocked Tasks table:
   | T020 | External payment API not responding | Wait for API or mock it |
5. Move to next ready task (T021 if available)
6. Report: "T020 is blocked (external API unavailable). Moved to T021."

### Example 3: Complete Implementation Session

**Scenario**: Running implement for a feature with 10 remaining tasks.

**Session Flow**:
```
Starting implementation session...

Task T025: Creating user service... [Completed]
  Commit: [T025] [US2] Create user service with CRUD operations
  Progress: 25/35 tasks (71%)

Task T026: Implementing authentication middleware... [Completed]
  Commit: [T026] [US3] Add JWT authentication middleware
  Progress: 26/35 tasks (74%)

Task T027: Creating user API endpoints... [Blocked]
  Blocker: T026 middleware has failing tests
  Resolution needed before continuing

Would you like to:
1. Fix T026 tests and retry T027
2. Skip T027 and continue with T028
3. End implementation session
```

### Example 4: Dependency Chain

**Scenario**: Tasks with dependencies: T001 -> T002 -> T003

**Order of Execution**:
1. T001 (no dependencies) - Implement first
2. T002 (depends on T001) - Implement after T001 completes
3. T003 (depends on T002) - Implement after T002 completes

Each task builds on the context of previous tasks, with summaries providing continuity.

---

## Error Handling

### Common Issues

1. **No tasks.md found**: Guide user to run `tasks` command first
2. **No pending tasks**: Report implementation is complete or all tasks blocked
3. **Circular dependencies**: Report the cycle and suggest manual resolution
4. **Task too large**: Suggest splitting the task and creating subtasks
5. **Git commit fails**: Check for merge conflicts or staging issues
6. **Tests fail after implementation**: Report failure, suggest fixes, don't mark complete

### Recovery Steps

If the command fails partway through:
1. Check which tasks were marked as completed (check git log)
2. Identify the current task status
3. Resume from the current task or next ready task
4. Do not re-implement already completed tasks

### Context Loss Recovery

If context is lost between sessions:
1. Read task-summaries.md for completed task context
2. Check git log for `[T{NNN}]` commits
3. Identify current state from tasks.md status
4. Resume with full context from summaries

### Rollback Support

If a task implementation needs to be undone:
1. Revert the commit: `git revert <commit-hash>`
2. Mark task as Pending in tasks.md
3. Document issue in task Notes
4. Re-attempt implementation

---

## Notes

- **One task at a time**: Focus on completing one task fully before moving to the next. This ensures atomic commits and clear progress tracking.
- **Context preservation**: Task summaries are critical for maintaining context across tasks and sessions. Always generate them.
- **Atomic commits**: Each task should result in exactly one commit. If multiple commits are needed, the task may need to be split.
- **Scope discipline**: Resist the urge to fix unrelated issues while implementing a task. Create new tasks instead.
- **Dependency order**: Always respect dependencies. Never start a task until all its dependencies are complete.
- **Progress visibility**: Keep tasks.md updated in real-time so progress is always visible.
- **Test as you go**: Run tests after each task to catch issues early, not at the end.
- **Document decisions**: When making implementation choices, document them in the task summary for future reference.
- **Handle blockers promptly**: Don't ignore blockers. Either resolve them or explicitly skip and document.
- **Feature state**: Update the feature state to "implement" at the start and mark completion when done.

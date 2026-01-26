# Feature Specification: Implement Command Subagent Spawning

**Feature Branch**: `009-implement-subagents`
**Created**: 2026-01-27
**Status**: Draft
**Input**: User description: "Make the implement.md spin subagents for task execution, referencing spec-kit templates"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sequential Task Execution with Subagents (Priority: P1)

As a developer using the `/projspec.implement` command, I want each task from tasks.md to be executed by a dedicated subagent so that each task runs in isolation with fresh context and produces a clean, atomic commit.

**Why this priority**: This is the core functionality - without subagent spawning, the implement command cannot execute tasks in the isolated manner required for reliable, traceable implementation.

**Independent Test**: Can be fully tested by running `/projspec.implement` on a feature with 3+ sequential tasks and verifying each task is handled by a separate agent invocation, resulting in individual commits.

**Acceptance Scenarios**:

1. **Given** a tasks.md with 5 sequential tasks (T001-T005), **When** I run `/projspec.implement`, **Then** 5 separate subagents are spawned one after another, each handling exactly one task
2. **Given** a sequential task T002 that depends on T001, **When** T001's agent completes, **Then** T002's agent is spawned only after T001's commit is pushed
3. **Given** a spawned agent for task T003, **When** the agent completes its work, **Then** changes are committed with message format `[T003] Task description` and pushed before the next task starts

---

### User Story 2 - Parallel Task Execution with Subagents (Priority: P2)

As a developer with tasks marked `[P]` for parallel execution, I want multiple subagents to be spawned simultaneously so that independent tasks complete faster.

**Why this priority**: Parallel execution is an optimization that significantly speeds up implementation when tasks don't depend on each other, but sequential execution must work first.

**Independent Test**: Can be tested by creating tasks.md with 3 tasks marked `[P]` in the same phase and verifying all 3 agents are spawned in a single message.

**Acceptance Scenarios**:

1. **Given** tasks T010, T011, T012 all marked with `[P]` in the same phase, **When** I run `/projspec.implement`, **Then** all 3 agents are spawned simultaneously in a single message with multiple Task tool calls
2. **Given** 3 parallel agents running, **When** all complete, **Then** each task gets its own individual commit (not batched) before proceeding
3. **Given** parallel task T010 fails while T011 and T012 succeed, **When** completion is evaluated, **Then** T011 and T012 are committed successfully and user is prompted about T010

---

### User Story 3 - Context Injection for Subagents (Priority: P2)

As a developer, I want each subagent to receive relevant context from plan.md, spec.md, and other design documents so that tasks are implemented according to the established architecture.

**Why this priority**: Without proper context, subagents would implement tasks in isolation without understanding the broader architecture, leading to inconsistent implementations.

**Independent Test**: Can be tested by examining the prompt sent to a spawned agent and verifying it includes excerpts from plan.md, spec.md, and constitution.md.

**Acceptance Scenarios**:

1. **Given** a task T015 related to user authentication, **When** the subagent is spawned, **Then** the prompt includes relevant architecture patterns from plan.md
2. **Given** a task with story marker `[US2]`, **When** the subagent is spawned, **Then** the prompt includes the User Story 2 acceptance criteria from spec.md
3. **Given** a constitution.md exists with coding principles, **When** any subagent is spawned, **Then** the prompt includes the key constitution principles

---

### User Story 4 - Error Recovery and Retry (Priority: P3)

As a developer, when a subagent fails to complete a task, I want clear error reporting and options to retry, skip, or abort so that I can handle failures gracefully.

**Why this priority**: Error handling is important for robustness but the happy path (successful execution) must work first.

**Independent Test**: Can be tested by intentionally creating a task that will fail (e.g., referencing non-existent file) and verifying error handling workflow.

**Acceptance Scenarios**:

1. **Given** a subagent fails to complete task T020, **When** the failure is detected, **Then** the error output is displayed and user is prompted with retry/skip/abort options
2. **Given** user selects "retry" after a failure, **When** the retry is processed, **Then** a new subagent is spawned with the same task context
3. **Given** user selects "skip" for a failed task, **When** skipping is processed, **Then** the task is NOT marked complete and execution continues with next ready task

---

### Edge Cases

- What happens when all remaining tasks are blocked by dependencies that cannot be resolved?
- How does the system handle a task that produces no file changes (empty diff)?
- What happens when git push fails due to network issues or permissions?
- How does the system handle a task file path that doesn't exist in the codebase?
- What happens when tasks.md is modified externally during execution?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The implement command MUST spawn a new subagent for each task using the Task tool with `subagent_type: "general-purpose"`
- **FR-002**: Each subagent prompt MUST include the task ID, description, and file path from tasks.md
- **FR-003**: Each subagent prompt MUST include relevant excerpts from plan.md (architecture, file structure, patterns)
- **FR-004**: Each subagent prompt MUST include relevant user story details from spec.md when a `[US#]` marker is present
- **FR-005**: Each subagent prompt MUST include constitution principles from `.specify/memory/constitution.md` if the file exists
- **FR-006**: Sequential tasks MUST be executed one at a time, waiting for completion before spawning the next agent
- **FR-007**: Parallel tasks (marked `[P]`) within the same batch MUST be spawned simultaneously using multiple Task tool calls in a single message
- **FR-008**: After each successful task completion, the system MUST stage changes, commit with format `[TaskID] Description`, and push to remote
- **FR-009**: After successful commit+push, the system MUST update tasks.md to mark the task as complete (`[x]`)
- **FR-010**: On agent failure, the system MUST display error output and prompt user for action (retry, skip, or abort)
- **FR-011**: The system MUST display progress after each task completion showing completion percentage
- **FR-012**: The system MUST support resuming from where it left off when rerun (skip already-completed tasks)

### Key Entities

- **Task**: Represents a single unit of work with ID, description, file path, status, parallel marker, and story marker
- **Subagent**: A spawned agent instance that handles one task in isolation
- **Execution Queue**: The ordered list of tasks ready for execution based on dependency resolution

## Assumptions

- Git repository is initialized and has a remote configured
- User has push permissions to the remote repository
- The Task tool is available and functional in the Claude Code environment
- tasks.md follows the expected format with task IDs, checkboxes, and optional markers

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Each task produces exactly one commit with the correct `[TaskID]` format (verified by `git log --oneline`)
- **SC-002**: Number of commits after implementation equals number of completed tasks
- **SC-003**: All spawned agents receive context from plan.md and spec.md (verifiable in execution logs)
- **SC-004**: Parallel tasks (3+ tasks marked `[P]`) complete faster than if run sequentially (wall-clock time reduction)
- **SC-005**: Implementation can be paused and resumed without losing progress or creating duplicate commits
- **SC-006**: 100% of successful task completions result in git push before next task starts

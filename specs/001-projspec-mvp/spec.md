# Feature Specification: ProjSpec MVP

**Feature Branch**: `001-projspec-mvp`
**Created**: 2026-01-26
**Status**: Draft
**Input**: User description: "ProjSpec - Spec-driven development workflow orchestrator for Claude Code"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Initialize ProjSpec in a Project (Priority: P1)

A developer wants to set up ProjSpec in their existing git repository so they can use the spec-driven workflow for their features. They run a simple initialization command that creates the necessary directory structure and configuration files.

**Why this priority**: This is the foundation - without initialization, no other functionality works. It's the entry point for all users.

**Independent Test**: Can be fully tested by running `projspec init` in a git repository and verifying the `.projspec/` directory structure is created with correct files.

**Acceptance Scenarios**:

1. **Given** a git repository without ProjSpec, **When** user runs `projspec init`, **Then** the system creates `.projspec/` directory with `config.yaml`, `workflow.yaml`, `phases/` directory with default phase templates, and `specs/active/` and `specs/completed/` directories.

2. **Given** a repository with ProjSpec already initialized, **When** user runs `projspec init`, **Then** the system displays a message indicating ProjSpec is already initialized and does not overwrite existing configuration.

3. **Given** a directory that is not a git repository, **When** user runs `projspec init`, **Then** the system displays an error message instructing user to run `git init` first.

---

### User Story 2 - Create New Spec with Worktree (Priority: P1)

A developer has a new feature idea and wants to create an isolated workspace to develop it. They run a command that creates a new spec with its own git worktree, ensuring complete isolation from other ongoing work.

**Why this priority**: Core to the isolation principle - every spec needs its own worktree. This is essential for the multi-spec workflow.

**Independent Test**: Can be tested by running `/projspec.new <name>` and verifying a worktree is created, a spec directory exists with `state.yaml`, and a new branch is checked out.

**Acceptance Scenarios**:

1. **Given** an initialized ProjSpec project, **When** user runs `/projspec.new user-auth`, **Then** the system creates a worktree at `worktrees/spec-{id}-user-auth`, creates a branch `spec/{id}-user-auth`, creates `.projspec/specs/active/{id}/` with `state.yaml` and empty `brief.md`, and displays the worktree path and next steps.

2. **Given** a branch name that already exists, **When** user runs `/projspec.new` with that name, **Then** the system displays an error about the existing branch and suggests using a different name.

3. **Given** no active spec exists, **When** user checks status, **Then** the system displays "No active specs" with guidance to create one.

---

### User Story 3 - Define Specification (Priority: P1)

A developer has created a new spec and wants to document the requirements clearly. They describe their feature and work with Claude to produce a structured specification document covering problem statement, user stories, technical requirements, and success criteria.

**Why this priority**: Specifications are the source of truth - all subsequent phases depend on a well-defined spec.

**Independent Test**: Can be tested by running `/projspec.spec`, providing requirements, and verifying `spec.md` is created with all required sections.

**Acceptance Scenarios**:

1. **Given** an active spec in "new" phase, **When** user runs `/projspec.spec` and provides requirements, **Then** the system creates `spec.md` with Problem Statement, User Stories, Technical Requirements, Success Criteria, and Out of Scope sections, and updates `state.yaml` phase to "spec".

2. **Given** ambiguous requirements, **When** user runs `/projspec.spec`, **Then** the system asks clarifying questions before completing the specification.

3. **Given** a spec already in "plan" phase, **When** user runs `/projspec.spec`, **Then** the system allows editing the existing specification.

---

### User Story 4 - Create Implementation Plan (Priority: P1)

After defining the specification, a developer wants to design how to build the feature. They work with Claude to create an implementation plan that outlines the approach, components, and architecture decisions.

**Why this priority**: The plan bridges specification and implementation - it's essential for structured development.

**Independent Test**: Can be tested by running `/projspec.plan` on a spec with completed specification and verifying `plan.md` is created.

**Acceptance Scenarios**:

1. **Given** a spec in "spec" phase with completed `spec.md`, **When** user runs `/projspec.plan`, **Then** the system reads the specification, discusses approach with user, creates `plan.md` with implementation details, and updates `state.yaml` phase to "plan".

2. **Given** a spec without `spec.md`, **When** user runs `/projspec.plan`, **Then** the system indicates the specification phase must be completed first.

---

### User Story 5 - Generate Task List (Priority: P1)

A developer has a plan and wants to break it into actionable tasks with dependencies. They run a command that generates a structured task list they can work through sequentially.

**Why this priority**: Tasks are the atomic units of work - essential for tracking progress and maintaining context between sessions.

**Independent Test**: Can be tested by running `/projspec.tasks` on a spec with completed plan and verifying tasks are added to `state.yaml`.

**Acceptance Scenarios**:

1. **Given** a spec in "plan" phase with completed `plan.md`, **When** user runs `/projspec.tasks`, **Then** the system generates a list of tasks with unique IDs, descriptions, dependencies, and context files, stores them in `state.yaml`, and updates phase to "tasks".

2. **Given** tasks with dependencies, **When** tasks are generated, **Then** each task's `depends_on` field correctly references prerequisite task IDs.

3. **Given** an existing task list, **When** user runs `/projspec.tasks` again, **Then** the system offers to regenerate or modify the existing list.

---

### User Story 6 - Implement Tasks Sequentially (Priority: P1)

A developer wants to work through tasks one by one with proper context. They run a command that finds the next ready task, loads relevant context from spec, plan, and previous task summaries, and guides them through implementation.

**Why this priority**: This is where actual development happens - the core value proposition of guided, context-aware implementation.

**Independent Test**: Can be tested by running `/projspec.implement` and verifying the next ready task is identified, context is loaded, and task status updates correctly.

**Acceptance Scenarios**:

1. **Given** a spec in "tasks" or "implement" phase with pending tasks, **When** user runs `/projspec.implement`, **Then** the system finds the first task where all dependencies are completed, marks it "in_progress" in `state.yaml`, loads spec, plan, and previous task summaries, and displays the task description.

2. **Given** a task is completed, **When** user confirms completion, **Then** the system generates a 3-5 bullet summary, stores it in `state.yaml`, marks task "completed", and shows the next ready task.

3. **Given** all tasks are completed, **When** user runs `/projspec.implement`, **Then** the system indicates all tasks are done and suggests running review.

4. **Given** tasks have blocking dependencies, **When** user runs `/projspec.implement`, **Then** the system shows which tasks are blocked and by which dependencies.

---

### User Story 7 - Review and Complete (Priority: P2)

After implementing all tasks, a developer wants to review the complete implementation against the specification. They run a review phase that assesses quality and verifies all requirements are met.

**Why this priority**: Important for quality assurance but secondary to core implementation workflow.

**Independent Test**: Can be tested by running `/projspec.review` after completing all tasks and verifying a review report is generated.

**Acceptance Scenarios**:

1. **Given** all tasks are completed, **When** user runs `/projspec.review`, **Then** the system reads the specification and plan, compares against implementation, generates a review report with findings, and updates phase to "review".

2. **Given** not all tasks are completed, **When** user runs `/projspec.review`, **Then** the system warns about incomplete tasks and asks for confirmation before proceeding.

---

### User Story 8 - Archive and Merge (Priority: P2)

A developer has completed a feature and wants to merge it to the main branch and clean up the worktree. They run an archive command that merges changes, moves spec metadata to completed, and removes the worktree.

**Why this priority**: Essential for completing the lifecycle but only needed after all development is done.

**Independent Test**: Can be tested by running `/projspec.archive` on a reviewed spec and verifying merge to main, metadata move to completed, and worktree removal.

**Acceptance Scenarios**:

1. **Given** a reviewed spec, **When** user runs `/projspec.archive`, **Then** the system confirms with user, merges the branch to main, moves spec from `active/` to `completed/`, removes the worktree, and optionally deletes the branch.

2. **Given** merge conflicts occur, **When** archiving, **Then** the system lists conflicting files, instructs user to resolve conflicts, and does not proceed with archiving.

3. **Given** uncommitted changes in worktree, **When** user runs `/projspec.archive`, **Then** the system warns about uncommitted changes and does not proceed.

---

### User Story 9 - Check Status (Priority: P2)

A developer wants to see the current state of all active specs, including which phase each is in and task progress. They run a status command that displays a formatted summary.

**Why this priority**: Useful for overview but not blocking core workflow operations.

**Independent Test**: Can be tested by running `projspec status` and verifying active specs are displayed with phase, branch, and task progress.

**Acceptance Scenarios**:

1. **Given** active specs exist, **When** user runs `projspec status`, **Then** the system displays each spec's name, ID, phase, branch, worktree path, and task progress (X/Y completed, Z in progress).

2. **Given** no active specs, **When** user runs `projspec status`, **Then** the system displays "No active specs" with guidance to create one.

---

### User Story 10 - Resume Interrupted Work (Priority: P2)

A developer returns to their project after a break and wants to continue where they left off. They run a resume command that determines the current state and continues the appropriate phase or task.

**Why this priority**: Important for workflow continuity but relies on state already being persisted.

**Independent Test**: Can be tested by creating a spec with in-progress task, restarting session, running `/projspec.resume`, and verifying the correct task is resumed.

**Acceptance Scenarios**:

1. **Given** a task is "in_progress", **When** user runs `/projspec.resume`, **Then** the system finds that task, loads its context, and continues the task.

2. **Given** a phase is incomplete, **When** user runs `/projspec.resume`, **Then** the system continues the current phase.

3. **Given** multiple active specs, **When** user runs `/projspec.resume`, **Then** the system asks which spec to resume.

---

### Edge Cases

- What happens when a user tries to create a spec with invalid characters in the name? The system validates names and rejects invalid characters with a helpful message.
- How does the system handle a worktree that was manually deleted? The system detects missing worktrees and offers to recreate them or clean up the spec state.
- What happens if state.yaml becomes corrupted? The system validates YAML on read and provides clear error messages with recovery guidance.
- How does the system handle concurrent modifications to the same spec? Git's worktree isolation prevents conflicts; state.yaml changes are atomic writes.
- What happens if git commands fail during worktree creation? The system catches git errors, provides specific error messages, and cleans up partial state.

## Requirements *(mandatory)*

### Functional Requirements

**Python CLI (Minimal)**
- **FR-001**: System MUST provide a CLI command `projspec init` that initializes the `.projspec/` directory structure
- **FR-002**: System MUST provide a CLI command `projspec status` that displays all active specs with their current phase and progress
- **FR-003**: CLI MUST use Pydantic models for configuration and state validation
- **FR-004**: CLI MUST use Rich library for formatted terminal output

**State Management**
- **FR-005**: System MUST store spec state in `state.yaml` files within each spec's directory
- **FR-006**: System MUST track task status as one of: pending, in_progress, completed, or skipped
- **FR-007**: System MUST persist task summaries after completion for context injection
- **FR-008**: System MUST update state immediately after each state change (implicit checkpointing)

**Git Worktree Integration**
- **FR-009**: System MUST create a dedicated git worktree for each new spec
- **FR-010**: System MUST create a new branch for each spec with naming pattern `spec/{id}-{name}`
- **FR-011**: System MUST remove worktrees when specs are archived
- **FR-012**: System MUST support merging spec branches to main during archive

**Claude Code Commands**
- **FR-013**: System MUST provide Claude Code commands as the primary user interface
- **FR-014**: Commands MUST read and write state files directly (not through Python)
- **FR-015**: Commands MUST load phase prompt templates from `.projspec/phases/`
- **FR-016**: System MUST support the following commands: init, status, new, spec, plan, tasks, implement, review, resume, next, archive

**Phase Workflow**
- **FR-017**: System MUST enforce phase ordering: new -> spec -> plan -> tasks -> implement -> review
- **FR-018**: System MUST validate phase completion before allowing transition to next phase
- **FR-019**: System MUST support custom phases in `.projspec/phases/custom/` directory
- **FR-020**: System MUST allow workflow configuration via `.projspec/workflow.yaml`

**Context Management**
- **FR-021**: System MUST inject spec and plan content when implementing tasks
- **FR-022**: System MUST inject summaries from completed tasks as context for new tasks
- **FR-023**: Each task MUST have a `context_files` field listing relevant source files

**Task Execution**
- **FR-024**: System MUST find next ready task based on dependency resolution
- **FR-025**: System MUST generate 3-5 bullet summaries after each task completion
- **FR-026**: System MUST support skipping tasks with user confirmation

### Key Entities

- **Spec**: Represents a feature being developed. Has an ID, name, current phase, associated branch, worktree path, and a list of tasks. Stored in `.projspec/specs/active/{id}/` or `.projspec/specs/completed/{id}/`.

- **Task**: An atomic unit of implementation work within a spec. Has an ID, name, description, status, dependencies, context files, and summary. Multiple tasks belong to one spec.

- **Phase**: A stage in the development workflow (spec, plan, tasks, implement, review). Defined as markdown templates that guide Claude through the phase.

- **Worktree**: A git worktree providing filesystem isolation for a spec. One worktree per active spec, located in `worktrees/spec-{id}-{name}/`.

- **Config**: Global project configuration stored in `.projspec/config.yaml`. Contains project metadata, worktree settings, and context file patterns.

- **Workflow**: Defines the sequence of phases for the project. Stored in `.projspec/workflow.yaml`. Can be customized per project.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new spec with worktree can be created in under 30 seconds from command invocation
- **SC-002**: Users can complete the full workflow cycle (new -> archive) for a simple feature
- **SC-003**: Task context loading includes spec, plan, and all previous task summaries within 5 seconds
- **SC-004**: Resuming interrupted work correctly identifies the current state and continues from the right point
- **SC-005**: 100% of specs maintain isolation - changes in one worktree do not affect others
- **SC-006**: State is never lost - interrupted sessions can always be resumed from the last saved state
- **SC-007**: System provides clear, actionable error messages for all failure scenarios
- **SC-008**: E2E tests can verify the complete workflow using `claude -p` in non-interactive mode

## Assumptions

- Users have git installed and configured in their environment
- Users have Python 3.11+ available for CLI installation
- The project is already a git repository with at least one commit
- Users have Claude Code installed and configured
- The main branch is named `main` (not `master`)
- Users understand basic git concepts (branches, commits, merges)

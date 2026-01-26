# Command: tasks

## Purpose

Generate a dependency-ordered, actionable task breakdown from an existing implementation plan. This command transforms a validated plan.md into a structured tasks.md document with phased execution order, enabling systematic implementation.

The task generation process:
1. Reads and analyzes the existing plan.md, spec.md, data-model.md, and contracts/
2. Identifies all implementation work items from the plan
3. Creates tasks.md with phased structure organized by priority and dependencies
4. Assigns unique task IDs, effort estimates, and dependency chains
5. Marks parallel-safe tasks with [P] flag
6. Updates the feature state to the "tasks" phase

---

## Prerequisites

Before running this command, verify the following:

1. **Existing plan.md**: The feature must have a plan.md file already created (via the `plan` command)
2. **Feature in plan phase**: The feature should be in the planning phase with plan.md complete
3. **Spec.md exists**: The original specification should be available for reference
4. **Feature directory exists**: The feature's specification directory must exist (e.g., `specs/{ID}-{feature-slug}/` or `.specify/features/{ID}-{feature-slug}/`)
5. **Working in feature context**: You should be in the feature's worktree or have the feature context loaded

If prerequisites are not met, inform the user:
- If no plan.md exists, suggest running the `plan` command first
- If plan.md is incomplete (missing sections), suggest completing the plan first
- If no spec.md exists, suggest running the `specify` command first

---

## Workflow

Follow these steps in order:

### Step 1: Locate and Read Required Documents

Find and read the following documents:

1. **Implementation Plan**: Locate plan.md for the current feature
   - Check the current directory for plan.md
   - Check `specs/{feature-slug}/plan.md`
   - Check `.specify/features/{feature-slug}/plan.md`

2. **Feature Specification**: Read spec.md for user stories and requirements
   - User stories with priorities (P1, P2, P3)
   - Functional requirements (FR-XXX)
   - Non-functional requirements (NFR-XXX)
   - Success criteria

3. **Data Model** (if exists): Read data-model.md
   - Entity definitions and relationships
   - State transitions
   - Validation rules

4. **API Contracts** (if exists): Read contracts/ directory
   - API specifications
   - Interface definitions
   - Schema definitions

5. **Tasks Template**: Use `templates/tasks-template.md` as the structure guide

Read all documents thoroughly before proceeding.

### Step 2: Extract Implementation Work Items

From plan.md, identify all work items:

#### From Project Structure
- New files to create (each file may be one or more tasks)
- Modified files (each modification may be a task)
- Directory structure setup

#### From Implementation Phases
- Each phase step in plan.md should map to one or more tasks
- Research items that need implementation
- Infrastructure setup requirements

#### From Technical Context
- Dependencies to install/configure
- Environment setup requirements
- Integration points to implement

#### From API Design
- Endpoints to implement
- Data models to create
- Validation logic to implement

#### From Testing Strategy
- Unit tests to write
- Integration tests to create
- Manual test scenarios to document

### Step 3: Organize Tasks into Phases

Structure tasks into the following phases:

#### Phase 0: Setup (Project Infrastructure)
Tasks that establish the foundation for all other work:
- Directory structure creation
- Configuration file setup
- Dependency installation
- Environment configuration
- CI/CD pipeline updates (if applicable)

**Characteristics**:
- No dependencies on feature code
- Must complete before feature implementation
- Typically [P] parallel-safe within the phase

#### Phase 1: Foundation (Blocking Prerequisites)
Core infrastructure that other user stories depend on:
- Base classes/types/interfaces
- Core utilities and helpers
- Data models and schemas
- Database migrations (if applicable)
- Shared components

**Characteristics**:
- Blocks most other tasks
- Implements cross-cutting concerns
- Creates the foundation for user stories

#### Phase 2+: User Stories by Priority
Implement user stories organized by priority level:

**Phase 2: P1 User Stories (Must Have)**
- Critical path functionality
- Core user-facing features
- Tasks derived from P1 user stories in spec.md

**Phase 3: P2 User Stories (Should Have)**
- Important but not critical features
- Enhanced functionality
- Tasks derived from P2 user stories in spec.md

**Phase 4: P3 User Stories (Nice to Have)**
- Optional enhancements
- Polish features
- Tasks derived from P3 user stories in spec.md

#### Final Phase: Polish (Cross-Cutting Concerns)
Tasks that span the entire feature:
- Error handling improvements
- Logging and monitoring
- Performance optimization
- Documentation
- Code cleanup and refactoring
- Final integration testing

### Step 4: Define Each Task

For each task, include the following fields:

#### Task Structure

```markdown
#### T{NNN}: {Descriptive Task Title}

- **Status**: Pending
- **Priority**: P1 | P2 | P3
- **Estimated Effort**: XS | S | M | L | XL
- **Dependencies**: None | T{NNN}, T{NNN}
- **Parallel**: [P] (if can run in parallel with other tasks in same phase)

**Description**:
{Clear description of what needs to be done and why}

**Context Files**:
- Spec: {Link to relevant user story or requirement in spec.md}
- Plan: {Link to relevant section in plan.md}
- Contract: {Link to relevant API contract if applicable}

**Acceptance Criteria**:
- [ ] {Specific, verifiable criterion 1}
- [ ] {Specific, verifiable criterion 2}

**Files to Create/Modify**:
- `{file_path}`: {What to do with this file}

**Notes**:
{Implementation hints, gotchas, or references}
```

#### Task ID Convention
- Sequential numbering: T001, T002, T003...
- Never reuse IDs, even if tasks are removed
- IDs persist through the feature lifecycle

#### Effort Estimation Guide

| Size | Description | Typical Duration |
|------|-------------|------------------|
| XS | Trivial change, config update | < 30 min |
| S | Small task, single file | 30 min - 2 hours |
| M | Medium task, few files | 2 - 4 hours |
| L | Large task, multiple components | 4 - 8 hours |
| XL | Complex task, significant work | 1 - 2 days |

#### Dependency Mapping
- Each task lists tasks it depends on
- Create a clear dependency chain
- Identify parallel opportunities with [P] flag
- Avoid circular dependencies

### Step 5: Identify Parallel Opportunities

Mark tasks with [P] flag when they can execute in parallel:

**Parallel-Safe Criteria**:
- No shared file modifications
- No data dependencies between tasks
- Independent test coverage
- Can be merged in any order

**Common Parallel Patterns**:
- Multiple independent API endpoints
- Separate UI components
- Independent test suites
- Documentation for different sections

### Step 6: Create the tasks.md Document

Using the tasks-template.md structure, create tasks.md with all required sections:

#### Required Sections

1. **Header**: Feature name, branch, date, links to spec.md and plan.md

2. **Progress Summary**: Table tracking task counts by status
   - Pending, In Progress, Completed, Blocked, Total

3. **Task List**: All tasks organized by phase
   - Phase 0: Setup
   - Phase 1: Foundation
   - Phase 2+: User Stories (by priority)
   - Final Phase: Polish

4. **Blocked Tasks**: Table for tracking blocked tasks and resolutions

5. **Completed Tasks**: Section for moving completed tasks

6. **Task Dependencies Graph**: ASCII visualization of dependencies

7. **Effort Legend**: Reference table for effort sizes

#### Mapping User Stories to Tasks

For each user story in spec.md:

1. **Extract acceptance criteria** - Each criterion may become a task
2. **Identify implementation steps** - Break down into atomic tasks
3. **Link to plan.md sections** - Reference technical implementation details
4. **Add user story tag** - Include [US{N}] in task title for traceability

Example:
```markdown
#### T015: [US1] Implement user login endpoint

- **Status**: Pending
- **Priority**: P1
- **Context Files**:
  - Spec: spec.md#us1-user-login (User Story 1)
  - Plan: plan.md#phase-2-authentication
```

### Step 7: Validate Task Breakdown

Before completing, verify the following:

#### Completeness Check
- [ ] All user stories from spec.md have corresponding tasks
- [ ] All implementation phases from plan.md are covered
- [ ] All files listed in plan.md are addressed by tasks
- [ ] Testing strategy has corresponding test tasks

#### Dependency Check
- [ ] No circular dependencies exist
- [ ] All dependency references are valid (T{NNN} exists)
- [ ] Critical path is clearly identifiable
- [ ] Parallel tasks are properly marked

#### Quality Check
- [ ] Each task has clear acceptance criteria
- [ ] Effort estimates are reasonable
- [ ] Task descriptions are actionable
- [ ] Context files are correctly linked

### Step 8: Update Feature State

Update the feature to indicate the tasks phase is complete:

1. **Update feature state**: Mark the feature as being in "tasks" phase
2. **Update metadata**: If the project uses state files (e.g., `.state.json`, `meta.json`)
3. **The feature is now ready for implementation**

### Step 9: Present the Task Breakdown

After creating the tasks.md:

1. **Summarize what was created**:
```
## Task Generation Complete

### Summary:
- Total Tasks: {N}
- Phase 0 (Setup): {N} tasks
- Phase 1 (Foundation): {N} tasks
- Phase 2 (P1 Stories): {N} tasks
- Phase 3 (P2 Stories): {N} tasks
- Phase 4 (P3 Stories): {N} tasks
- Final Phase (Polish): {N} tasks

### Parallel Opportunities:
- {N} tasks marked as [P] parallel-safe

### Critical Path:
T001 -> T002 -> T005 -> T010 -> T015

### Estimated Total Effort:
- XS: {N}, S: {N}, M: {N}, L: {N}, XL: {N}

### Next Steps:
1. Review task breakdown with team
2. Begin implementation with Phase 0
3. Track progress in tasks.md
```

2. **Show the dependency graph**

3. **Highlight blockers or risks**:
   - Tasks with many dependents (high-risk if delayed)
   - Large effort tasks that may need splitting
   - External dependencies

---

## Output

Upon successful completion, the following will be created:

### Files Created

| File | Description |
|------|-------------|
| `tasks.md` | Complete task breakdown with phases, dependencies, and assignments |

### Tasks.md Contents

The tasks.md will contain:
- Progress tracking summary
- Phase 0: Setup tasks (infrastructure)
- Phase 1: Foundation tasks (core dependencies)
- Phase 2+: User Story implementation tasks (by priority)
- Final Phase: Polish tasks (cross-cutting)
- Blocked tasks tracking table
- Completed tasks archive section
- Visual dependency graph
- Effort estimation legend

### Task Attributes

Each task includes:
- Unique ID (T001, T002...)
- Status (Pending, In Progress, Completed, Blocked)
- Priority (P1, P2, P3)
- Effort estimate (XS, S, M, L, XL)
- Dependencies (task IDs)
- Parallel flag [P] when applicable
- Description and acceptance criteria
- Context file links (spec.md, plan.md, contracts/)
- Files to create/modify

### Feature State

- Phase: `tasks`
- Status: Ready for Implementation
- Ready for: Task execution, tracking, and completion

---

## Examples

### Example 1: Standard Feature Task Generation

**Scenario**: User has a complete plan.md for a "user authentication" feature with 3 user stories (P1: login, P1: logout, P2: password reset).

**Generated Tasks**:
```markdown
### Phase 0: Setup
- T001: [P] Create authentication module directory structure
- T002: [P] Add authentication dependencies to package.json

### Phase 1: Foundation
- T003: Create User entity with password hashing
- T004: Implement JWT token service (depends: T003)
- T005: Create authentication middleware (depends: T004)

### Phase 2: P1 User Stories
- T006: [US1] Implement login endpoint (depends: T005)
- T007: [US1] Create login form component (depends: T006)
- T008: [US2] Implement logout endpoint (depends: T005)
- T009: [US2] Add logout button to header (depends: T008)

### Phase 3: P2 User Stories
- T010: [US3] Implement password reset request (depends: T003)
- T011: [US3] Create password reset email template (depends: T010)
- T012: [US3] Implement password reset confirmation (depends: T011)

### Final Phase: Polish
- T013: Add comprehensive error handling (depends: T006-T012)
- T014: Write authentication integration tests (depends: T013)
- T015: Update API documentation (depends: T006-T012)
```

### Example 2: API-Heavy Feature

**Scenario**: User has plan.md for "project export" with multiple export formats and async processing.

**Generated Tasks**:
```markdown
### Phase 0: Setup
- T001: [P] Create exports module directory
- T002: [P] Add file generation dependencies

### Phase 1: Foundation
- T003: Create ExportJob entity with status states
- T004: Implement background job processor (depends: T003)
- T005: Create export base class (depends: T003)

### Phase 2: P1 User Stories
- T006: [US1] [P] Implement JSON exporter (depends: T005)
- T007: [US1] [P] Implement CSV exporter (depends: T005)
- T008: [US1] Create POST /exports endpoint (depends: T004, T006, T007)
- T009: [US1] Create GET /exports/{id} status endpoint (depends: T003)
- T010: [US1] Create GET /exports/{id}/download endpoint (depends: T008)

### Final Phase: Polish
- T011: Add export progress notifications (depends: T008)
- T012: Implement export cleanup scheduler (depends: T003)
- T013: Write export integration tests (depends: T006-T010)
```

### Example 3: Parallel Task Identification

**Scenario**: Plan has multiple independent components that can be developed simultaneously.

**Parallel Opportunities Identified**:
```markdown
### Phase 2: P1 User Stories

The following tasks are parallel-safe [P]:

- T010: [P] [US1] Implement settings page UI
- T011: [P] [US2] Implement profile page UI
- T012: [P] [US3] Implement dashboard page UI

Note: T010, T011, and T012 can be assigned to different developers
and merged in any order as they modify different files.
```

---

## Error Handling

### Common Issues

1. **No plan.md found**: Guide user to run `plan` command first
2. **Plan is incomplete**: Identify missing sections and suggest completing them
3. **No spec.md found**: Suggest running `specify` command first
4. **Circular dependencies detected**: Report the cycle and suggest resolution
5. **Tasks too large**: Suggest splitting XL tasks into smaller units

### Recovery Steps

If the command fails partway through:
1. Check what tasks were generated
2. Report which phases are complete
3. Resume from the failed phase
4. Keep partial tasks.md for reference

### Validation Errors

Before completing, validate:
- [ ] All user stories are covered by tasks
- [ ] No circular dependencies exist
- [ ] All task IDs are unique and sequential
- [ ] All dependency references are valid
- [ ] Effort estimates are assigned to all tasks

---

## Notes

- **Atomic tasks**: Each task should be completable in one work session. Split larger work into multiple tasks
- **Clear dependencies**: Explicit dependencies enable accurate scheduling and parallel work
- **Traceability**: Link tasks to spec.md user stories and plan.md sections for context
- **Living document**: tasks.md is updated throughout implementation as tasks are completed
- **Parallel work**: Identify [P] tasks early to enable team parallelization
- **Effort accuracy**: Estimates improve with experience; track actual vs estimated for calibration
- **Status updates**: Move completed tasks to the Completed section to track progress
- **Blocking issues**: Document blockers in the Blocked Tasks table with resolution plans
- **Task order**: Within a phase, tasks without dependencies can often be done in any order
- **Context matters**: Include enough context in each task for implementation without re-reading the entire plan

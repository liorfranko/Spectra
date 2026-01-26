# Tasks: ProjSpec MVP

**Input**: Design documents from `/specs/001-projspec-mvp/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md, contracts/

**Tests**: Not explicitly requested in specification - test tasks omitted.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Exact file paths included in descriptions

## Path Conventions

- **Python package**: `src/projspec/`
- **Tests**: `tests/unit/`, `tests/integration/`, `tests/e2e/`
- **Claude Code plugin**: `.claude/plugins/projspec/`
- **Phase templates**: `.projspec/phases/` (bundled assets)

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create Python package structure and configure development environment

- [X] T001 Create pyproject.toml with uv configuration, dependencies (pydantic, pyyaml, rich, pytest) in pyproject.toml
- [X] T002 [P] Create package structure with src/projspec/__init__.py containing version metadata
- [X] T003 [P] Create .gitignore with Python, IDE, and worktree patterns in .gitignore
- [X] T004 [P] Create README.md with project description and usage in README.md

---

## Phase 2: Foundational (Core Models & State)

**Purpose**: Pydantic models and state utilities that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Create TaskState Pydantic model with id, name, description, status, depends_on, context_files, summary fields in src/projspec/models.py
- [X] T006 Create SpecState Pydantic model with spec_id, name, phase, created_at, branch, worktree_path, tasks fields in src/projspec/models.py
- [X] T007 Create Config Pydantic model with version, project, worktrees, context fields in src/projspec/models.py
- [X] T008 Create Workflow Pydantic model with workflow.name and workflow.phases fields in src/projspec/models.py
- [X] T009 Implement load_active_specs function to read all specs from active directory in src/projspec/state.py
- [X] T010 Implement get_current_spec function to find most recently modified spec in src/projspec/state.py
- [X] T011 [P] Create default config.yaml template content as Python constant in src/projspec/defaults.py
- [X] T012 [P] Create default workflow.yaml template content as Python constant in src/projspec/defaults.py

**Checkpoint**: Foundation ready - Pydantic models and state utilities complete

---

## Phase 3: User Story 1 - Initialize ProjSpec (Priority: P1) MVP

**Goal**: Developer can run `projspec init` to set up .projspec/ directory structure in their git repository

**Independent Test**: Run `projspec init` in a git repo, verify .projspec/ structure created

### Implementation for User Story 1

- [X] T013 [US1] Create CLI entry point with argparse subcommand structure in src/projspec/cli.py
- [X] T014 [US1] Implement init subcommand that creates .projspec/ directory structure in src/projspec/cli.py
- [X] T015 [US1] Create default phase templates as bundled assets in src/projspec/assets/phases/spec.md
- [X] T016 [P] [US1] Create plan phase template in src/projspec/assets/phases/plan.md
- [X] T017 [P] [US1] Create tasks phase template in src/projspec/assets/phases/tasks.md
- [X] T018 [P] [US1] Create implement phase template in src/projspec/assets/phases/implement.md
- [X] T019 [P] [US1] Create review phase template in src/projspec/assets/phases/review.md
- [X] T020 [US1] Implement _copy_default_phases function to copy bundled templates in src/projspec/cli.py
- [X] T021 [US1] Add git repository detection (check for .git directory) in src/projspec/cli.py
- [X] T022 [US1] Add already-initialized detection with user-friendly message in src/projspec/cli.py
- [X] T023 [US1] Add Rich console output for success/error messages in src/projspec/cli.py
- [X] T024 [US1] Add console script entry point 'projspec' in pyproject.toml

**Checkpoint**: User Story 1 complete - `projspec init` creates full .projspec/ structure

---

## Phase 4: User Story 9 - Check Status (Priority: P2)

**Goal**: Developer can run `projspec status` to see all active specs with progress

**Note**: Moved from P2 to Phase 4 because status command completes the Python CLI

**Independent Test**: Run `projspec status` after creating specs, verify formatted output

### Implementation for User Story 9

- [X] T025 [US9] Implement status subcommand that reads active specs in src/projspec/cli.py
- [X] T026 [US9] Implement _print_spec_status helper with Rich table formatting in src/projspec/cli.py
- [X] T027 [US9] Add task progress calculation (completed/total, in_progress count) in src/projspec/cli.py
- [X] T028 [US9] Handle empty specs case with "No active specs" message in src/projspec/cli.py

**Checkpoint**: Python CLI complete - both init and status commands working

---

## Phase 5: User Story 2 - Create New Spec with Worktree (Priority: P1)

**Goal**: Developer can run `/projspec.new <name>` to create isolated worktree for a new spec

**Independent Test**: Run `/projspec.new test-feature`, verify worktree and state.yaml created

### Implementation for User Story 2

- [X] T029 [US2] Create Claude Code plugin manifest in .claude/plugins/projspec/plugin.json
- [X] T030 [US2] Create /projspec.new command with ID generation, worktree creation, state.yaml initialization in .claude/plugins/projspec/commands/new.md
- [X] T031 [US2] Add branch existence check and error handling in .claude/plugins/projspec/commands/new.md
- [X] T032 [US2] Add worktree directory existence check in .claude/plugins/projspec/commands/new.md
- [X] T033 [US2] Add spec name validation (kebab-case, no special chars) in .claude/plugins/projspec/commands/new.md
- [X] T034 [P] [US2] Create /projspec.init command wrapper that calls Python CLI in .claude/plugins/projspec/commands/init.md
- [X] T035 [P] [US2] Create /projspec.status command wrapper that calls Python CLI in .claude/plugins/projspec/commands/status.md

**Checkpoint**: User Story 2 complete - can create new specs with isolated worktrees

---

## Phase 6: User Story 3 - Define Specification (Priority: P1)

**Goal**: Developer can run `/projspec.spec` to create structured spec.md document

**Independent Test**: Run `/projspec.spec`, provide requirements, verify spec.md created

### Implementation for User Story 3

- [X] T036 [US3] Create /projspec.spec command that reads brief.md and guides spec creation in src/projspec/assets/commands/projspec.spec.md
- [X] T037 [US3] Add structured sections (Problem Statement, User Stories, Technical Requirements, Success Criteria, Out of Scope) in src/projspec/assets/commands/projspec.spec.md
- [X] T038 [US3] Add state.yaml phase update from "new" to "spec" in src/projspec/assets/commands/projspec.spec.md
- [X] T039 [US3] Add clarifying questions workflow for ambiguous requirements in src/projspec/assets/commands/projspec.spec.md

**Checkpoint**: User Story 3 complete - can define specifications with guided workflow

---

## Phase 7: User Story 4 - Create Implementation Plan (Priority: P1)

**Goal**: Developer can run `/projspec.plan` to create plan.md with implementation approach

**Independent Test**: Run `/projspec.plan` on completed spec, verify plan.md created

### Implementation for User Story 4

- [X] T040 [US4] Create /projspec.plan command that reads spec.md and creates plan.md in src/projspec/assets/commands/projspec.plan.md
- [X] T041 [US4] Add phase validation (must be in "spec" phase with spec.md present) in src/projspec/assets/commands/projspec.plan.md
- [X] T042 [US4] Add state.yaml phase update from "spec" to "plan" in src/projspec/assets/commands/projspec.plan.md

**Checkpoint**: User Story 4 complete - can create implementation plans from specifications

---

## Phase 8: User Story 5 - Generate Task List (Priority: P1)

**Goal**: Developer can run `/projspec.tasks` to generate task list with dependencies

**Independent Test**: Run `/projspec.tasks` on completed plan, verify tasks in state.yaml

### Implementation for User Story 5

- [X] T043 [US5] Create /projspec.tasks command that reads plan.md and generates tasks in src/projspec/assets/commands/projspec.tasks.md
- [X] T044 [US5] Add task ID generation (task-001, task-002, etc.) in src/projspec/assets/commands/projspec.tasks.md
- [X] T045 [US5] Add dependency detection and depends_on field population in src/projspec/assets/commands/projspec.tasks.md
- [X] T046 [US5] Add context_files field population based on task scope in src/projspec/assets/commands/projspec.tasks.md
- [X] T047 [US5] Add state.yaml update with tasks array and phase change to "tasks" in src/projspec/assets/commands/projspec.tasks.md
- [X] T048 [US5] Add existing task list detection with regenerate/modify option in src/projspec/assets/commands/projspec.tasks.md

**Checkpoint**: User Story 5 complete - can generate actionable task lists from plans

---

## Phase 9: User Story 6 - Implement Tasks Sequentially (Priority: P1)

**Goal**: Developer can run `/projspec.implement` to work through tasks with context injection

**Independent Test**: Run `/projspec.implement`, verify next ready task identified and context loaded

### Implementation for User Story 6

- [X] T049 [US6] Create /projspec.implement command with task dependency resolution in src/projspec/assets/commands/projspec.implement.md
- [X] T050 [US6] Add next-ready-task finder (pending status, all depends_on completed) in src/projspec/assets/commands/projspec.implement.md
- [X] T051 [US6] Add context injection (load spec.md, plan.md, completed task summaries) in src/projspec/assets/commands/projspec.implement.md
- [X] T052 [US6] Add task status update to "in_progress" when starting in src/projspec/assets/commands/projspec.implement.md
- [X] T053 [US6] Add 3-5 bullet summary generation on task completion in src/projspec/assets/commands/projspec.implement.md
- [X] T054 [US6] Add task status update to "completed" with summary storage in src/projspec/assets/commands/projspec.implement.md
- [X] T055 [US6] Add "all tasks complete" detection with review suggestion in src/projspec/assets/commands/projspec.implement.md
- [X] T056 [US6] Add blocked task display showing which dependencies are incomplete in src/projspec/assets/commands/projspec.implement.md
- [X] T057 [US6] Add phase update from "tasks" to "implement" on first task start in src/projspec/assets/commands/projspec.implement.md

**Checkpoint**: User Story 6 complete - can implement tasks with full context and progress tracking

---

## Phase 10: User Story 10 - Resume Interrupted Work (Priority: P2)

**Goal**: Developer can run `/projspec.resume` to continue from last saved state

**Independent Test**: Create spec with in-progress task, run `/projspec.resume`, verify correct task resumed

### Implementation for User Story 10

- [X] T058 [US10] Create /projspec.resume command that detects current state in .claude/plugins/projspec/commands/resume.md
- [X] T059 [US10] Add in-progress task detection and continuation in .claude/plugins/projspec/commands/resume.md
- [X] T060 [US10] Add incomplete phase detection and continuation in .claude/plugins/projspec/commands/resume.md
- [X] T061 [US10] Add multiple active specs handling with user prompt in .claude/plugins/projspec/commands/resume.md
- [X] T062 [P] [US10] Create /projspec.next command for manual phase advancement in .claude/plugins/projspec/commands/next.md

**Checkpoint**: User Story 10 complete - can resume work from any interrupted state

---

## Phase 11: User Story 7 - Review and Complete (Priority: P2)

**Goal**: Developer can run `/projspec.review` to assess implementation against specification

**Independent Test**: Complete all tasks, run `/projspec.review`, verify review report generated

### Implementation for User Story 7

- [X] T063 [US7] Create /projspec.review command that compares spec vs implementation in .claude/plugins/projspec/commands/review.md
- [X] T064 [US7] Add requirement verification checklist from spec.md in .claude/plugins/projspec/commands/review.md
- [X] T065 [US7] Add incomplete task warning with confirmation prompt in .claude/plugins/projspec/commands/review.md
- [X] T066 [US7] Add state.yaml phase update to "review" in .claude/plugins/projspec/commands/review.md

**Checkpoint**: User Story 7 complete - can review implementations against specifications

---

## Phase 12: User Story 8 - Archive and Merge (Priority: P2)

**Goal**: Developer can run `/projspec.archive` to merge branch and cleanup worktree

**Independent Test**: Complete review, run `/projspec.archive`, verify merge and cleanup

### Implementation for User Story 8

- [X] T067 [US8] Create /projspec.archive command with user confirmation in .claude/plugins/projspec/commands/archive.md
- [X] T068 [US8] Add git merge to main branch with conflict detection in .claude/plugins/projspec/commands/archive.md
- [X] T069 [US8] Add spec metadata move from active/ to completed/ in .claude/plugins/projspec/commands/archive.md
- [X] T070 [US8] Add worktree removal with uncommitted changes detection in .claude/plugins/projspec/commands/archive.md
- [X] T071 [US8] Add branch deletion (optional, with user confirmation) in .claude/plugins/projspec/commands/archive.md

**Checkpoint**: User Story 8 complete - can complete full workflow lifecycle

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T072 [P] Add error handling for YAML parsing failures in src/projspec/state.py
- [X] T073 [P] Add atomic file writes for state.yaml updates in src/projspec/state.py
- [X] T074 [P] Add input validation for spec names in .claude/plugins/projspec/commands/new.md
- [X] T075 Verify quickstart.md scenarios work end-to-end
- [X] T076 [P] Add help text and usage examples to all commands

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all user stories
- **US1 Init (Phase 3)**: Depends on Phase 2
- **US9 Status (Phase 4)**: Depends on Phase 3 (same CLI file)
- **US2 New Spec (Phase 5)**: Depends on Phase 4 (needs working CLI)
- **US3-US8 (Phases 6-12)**: Depend on Phase 5 (need spec creation working)
- **Polish (Phase 13)**: Depends on all user stories

### User Story Dependencies

```
Phase 2 (Foundational)
    │
    ├──> US1 (Init) ──> US9 (Status) ──> US2 (New Spec)
    │                                         │
    │                    ┌────────────────────┴────────────────────┐
    │                    │                                         │
    │                    v                                         v
    │               US3 (Spec) ──> US4 (Plan) ──> US5 (Tasks) ──> US6 (Implement)
    │                                                              │
    │                    ┌────────────────────┬────────────────────┤
    │                    v                    v                    v
    │               US10 (Resume)        US7 (Review) ──> US8 (Archive)
    │
    └──> Polish (Phase 13)
```

### Parallel Opportunities

**Within Phase 1 (Setup)**:
- T002, T003, T004 can run in parallel

**Within Phase 2 (Foundational)**:
- T011, T012 can run in parallel (separate files)

**Within US1 (Init)**:
- T015-T019 phase templates can run in parallel

**Within US2 (New Spec)**:
- T034, T035 wrapper commands can run in parallel

**Within US10 (Resume)**:
- T062 (next command) can run in parallel with T058-T061

**Within Polish**:
- T072, T073, T074, T076 can run in parallel (different files)

---

## Parallel Example: Phase 2 Foundational

```bash
# These must be sequential (same file):
Task: T005 Create TaskState model
Task: T006 Create SpecState model
Task: T007 Create Config model
Task: T008 Create Workflow model

# These can run in parallel (different files):
Task: T011 Create default config.yaml template in src/projspec/defaults.py
Task: T012 Create default workflow.yaml template in src/projspec/defaults.py
```

---

## Parallel Example: US1 Init Phase Templates

```bash
# All phase template files can be created in parallel:
Task: T015 Create spec.md template in src/projspec/assets/phases/
Task: T016 Create plan.md template
Task: T017 Create tasks.md template
Task: T018 Create implement.md template
Task: T019 Create review.md template
```

---

## Implementation Strategy

### MVP First (User Stories 1-2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational models
3. Complete Phase 3: US1 Init command
4. Complete Phase 4: US9 Status command
5. Complete Phase 5: US2 New Spec command
6. **STOP and VALIDATE**: Can initialize and create specs with worktrees
7. This is a working MVP - can demo project setup

### Core Workflow (Add US3-US6)

8. Complete Phase 6: US3 Define Specification
9. Complete Phase 7: US4 Create Plan
10. Complete Phase 8: US5 Generate Tasks
11. Complete Phase 9: US6 Implement Tasks
12. **STOP and VALIDATE**: Full spec-to-implementation workflow working

### Lifecycle Commands (Add US7-US10)

13. Complete Phase 10: US10 Resume
14. Complete Phase 11: US7 Review
15. Complete Phase 12: US8 Archive
16. Complete Phase 13: Polish
17. **FINAL VALIDATION**: Complete workflow cycle works

---

## Summary

| Category | Count |
|----------|-------|
| **Total Tasks** | 76 |
| **Phase 1: Setup** | 4 |
| **Phase 2: Foundational** | 8 |
| **US1 Initialize** | 12 |
| **US9 Status** | 4 |
| **US2 New Spec** | 7 |
| **US3 Specification** | 4 |
| **US4 Plan** | 3 |
| **US5 Tasks** | 6 |
| **US6 Implement** | 9 |
| **US10 Resume** | 5 |
| **US7 Review** | 4 |
| **US8 Archive** | 5 |
| **Polish** | 5 |
| **Parallel Tasks** | 24 |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- No test tasks generated (not requested in specification)
- US9 (Status) moved before US2 to complete Python CLI first
- Claude Code commands are markdown files, not Python
- State updates happen in Claude commands via file writes

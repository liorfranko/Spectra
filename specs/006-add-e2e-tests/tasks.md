# Tasks: End-to-End Tests for projspec Plugin

**Input**: Design documents from `/specs/006-add-e2e-tests/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: This feature IS the test infrastructure, so there are no separate test tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `tests/` at repository root
- Paths use the structure defined in plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and test directory structure

- [x] T001 Create test directory structure per plan in tests/__init__.py, tests/conftest.py
- [x] T002 [P] Create tests/e2e/__init__.py and tests/e2e/helpers/__init__.py
- [x] T003 [P] Create tests/e2e/stages/__init__.py
- [x] T004 [P] Create tests/e2e/output/.gitkeep (for logs/ and test-projects/)
- [x] T005 [P] Create tests/fixtures/todo-app/README.md with minimal fixture content

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core helper classes that ALL stage tests depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Implement ClaudeResult dataclass in tests/e2e/helpers/claude_runner.py
- [x] T007 Implement ClaudeRunner class with run() and get_stage_timeout() in tests/e2e/helpers/claude_runner.py
- [x] T008 [P] Implement FileVerifier class with all assertion methods in tests/e2e/helpers/file_verifier.py
- [x] T009 [P] Implement GitVerifier class with all assertion methods in tests/e2e/helpers/git_verifier.py
- [x] T010 Implement E2EProject class with setup() and get_log_file() in tests/e2e/helpers/test_environment.py
- [x] T011 Implement StageStatus enum in tests/e2e/conftest.py
- [x] T012 Implement StageTracker singleton in tests/e2e/conftest.py
- [x] T013 Implement E2EConfig dataclass with should_run_stage() in tests/e2e/conftest.py
- [x] T014 Implement pytest_addoption hook for --stage, --e2e-debug, --timeout-all in tests/e2e/conftest.py
- [x] T015 Implement pytest_collection_modifyitems hook for stage sorting in tests/e2e/conftest.py
- [x] T016 Implement pytest_runtest_setup hook for stage skipping in tests/e2e/conftest.py
- [x] T017 Implement pytest_runtest_makereport hook for failure tracking in tests/e2e/conftest.py
- [x] T018 Implement session-scoped fixtures (e2e_config, test_project) in tests/e2e/conftest.py
- [x] T019 Implement function-scoped fixtures (claude_runner, file_verifier, git_verifier, project_path) in tests/e2e/conftest.py
- [x] T020 Export helpers from tests/e2e/helpers/__init__.py

**Checkpoint**: Foundation ready - stage test implementation can now begin

---

## Phase 3: User Story 1 - Run E2E Tests to Validate Plugin Commands (Priority: P1) 🎯 MVP

**Goal**: Complete test infrastructure that can execute all 6 stages in sequence

**Independent Test**: Run `pytest tests/e2e/` and verify all stage tests execute in order with pass/fail results

### Implementation for User Story 1

This story is the orchestration layer - it depends on the stage tests from US2-US5 to be useful. However, the infrastructure (conftest.py fixtures and helpers) enables the test execution.

- [x] T021 [US1] Verify StageTracker correctly records first failure in tests/e2e/conftest.py
- [x] T022 [US1] Verify dependent stages are skipped when earlier stage fails in tests/e2e/conftest.py
- [x] T023 [US1] Verify test output shows pass/fail/skip status clearly via pytest markers

**Checkpoint**: Core E2E framework is functional

---

## Phase 4: User Story 2 - Verify projspec Plugin Initialization (Priority: P1)

**Goal**: Stage 1 tests verify `specify init` creates correct directory structure

**Independent Test**: Run `pytest tests/e2e/ --stage 1` and verify .specify/ directory structure is validated

### Implementation for User Story 2

- [x] T024 [US2] Create test_01_init.py with TestSpeckitInit class in tests/e2e/stages/test_01_init.py
- [ ] T025 [US2] Implement test_init_runs_successfully that runs `specify init` via ClaudeRunner in tests/e2e/stages/test_01_init.py
- [ ] T026 [US2] Implement test_specify_dir_created that verifies .specify/ directory exists in tests/e2e/stages/test_01_init.py
- [ ] T027 [US2] Implement test_templates_exist that verifies .specify/templates/ has required files in tests/e2e/stages/test_01_init.py
- [ ] T028 [US2] Implement test_claude_plugin_configured that verifies .claude/ directory setup in tests/e2e/stages/test_01_init.py
- [ ] T029 [US2] Add @pytest.mark.e2e and @pytest.mark.stage(1) decorators to all stage 1 tests in tests/e2e/stages/test_01_init.py

**Checkpoint**: Stage 1 (init) tests complete and independently runnable

---

## Phase 5: User Story 3 - Verify /speckit.specify Command (Priority: P1)

**Goal**: Stage 2-3 tests verify constitution and /speckit.specify create proper spec

**Independent Test**: Run `pytest tests/e2e/ --stage 2-3` and verify spec.md is created with required sections

### Implementation for User Story 3

- [ ] T030 [P] [US3] Create test_02_constitution.py with TestSpeckitConstitution class in tests/e2e/stages/test_02_constitution.py
- [ ] T031 [P] [US3] Create test_03_specify.py with TestSpeckitSpecify class in tests/e2e/stages/test_03_specify.py
- [ ] T032 [US3] Implement test_constitution_setup that runs /speckit.constitution via ClaudeRunner in tests/e2e/stages/test_02_constitution.py
- [ ] T033 [US3] Implement test_constitution_file_created that verifies constitution.md exists in tests/e2e/stages/test_02_constitution.py
- [ ] T034 [US3] Implement test_specify_runs_successfully that runs /speckit.specify via ClaudeRunner in tests/e2e/stages/test_03_specify.py
- [ ] T035 [US3] Implement test_feature_branch_created that uses GitVerifier to verify worktree in tests/e2e/stages/test_03_specify.py
- [ ] T036 [US3] Implement test_spec_file_created that uses FileVerifier to verify spec.md exists in tests/e2e/stages/test_03_specify.py
- [ ] T037 [US3] Implement test_spec_has_required_sections that verifies User Scenarios, Requirements, Success Criteria in tests/e2e/stages/test_03_specify.py
- [ ] T038 [US3] Add @pytest.mark.stage(2) to constitution tests and @pytest.mark.stage(3) to specify tests

**Checkpoint**: Stages 2-3 (constitution, specify) tests complete and independently runnable

---

## Phase 6: User Story 4 - Verify /speckit.plan Command (Priority: P2)

**Goal**: Stage 4 tests verify /speckit.plan creates implementation plan

**Independent Test**: Run `pytest tests/e2e/ --stage 4` and verify plan.md is created with architecture info

### Implementation for User Story 4

- [ ] T039 [US4] Create test_04_plan.py with TestSpeckitPlan class in tests/e2e/stages/test_04_plan.py
- [ ] T040 [US4] Implement test_plan_runs_successfully that runs /speckit.plan via ClaudeRunner in tests/e2e/stages/test_04_plan.py
- [ ] T041 [US4] Implement test_plan_file_created that uses FileVerifier to verify plan.md exists in tests/e2e/stages/test_04_plan.py
- [ ] T042 [US4] Implement test_plan_has_technical_context that verifies plan contains Technical Context section in tests/e2e/stages/test_04_plan.py
- [ ] T043 [US4] Implement test_plan_has_project_structure that verifies plan contains Project Structure section in tests/e2e/stages/test_04_plan.py
- [ ] T044 [US4] Add @pytest.mark.e2e and @pytest.mark.stage(4) decorators to all stage 4 tests

**Checkpoint**: Stage 4 (plan) tests complete and independently runnable

---

## Phase 7: User Story 5 - Verify /speckit.tasks Command (Priority: P2)

**Goal**: Stage 5 tests verify /speckit.tasks generates task list

**Independent Test**: Run `pytest tests/e2e/ --stage 5` and verify tasks.md is created with actionable items

### Implementation for User Story 5

- [ ] T045 [US5] Create test_05_tasks.py with TestSpeckitTasks class in tests/e2e/stages/test_05_tasks.py
- [ ] T046 [US5] Implement test_tasks_runs_successfully that runs /speckit.tasks via ClaudeRunner in tests/e2e/stages/test_05_tasks.py
- [ ] T047 [US5] Implement test_tasks_file_created that uses FileVerifier to verify tasks.md exists in tests/e2e/stages/test_05_tasks.py
- [ ] T048 [US5] Implement test_tasks_has_checkboxes that verifies tasks.md contains task checkboxes in tests/e2e/stages/test_05_tasks.py
- [ ] T049 [US5] Implement test_tasks_has_phases that verifies tasks.md contains phase sections in tests/e2e/stages/test_05_tasks.py
- [ ] T050 [US5] Add @pytest.mark.e2e and @pytest.mark.stage(5) decorators to all stage 5 tests

**Checkpoint**: Stage 5 (tasks) tests complete and independently runnable

---

## Phase 8: User Story 6 - Debug and Iterate on E2E Tests (Priority: P3)

**Goal**: CLI options for --stage filtering, --e2e-debug output, --timeout-all override

**Independent Test**: Run `pytest tests/e2e --stage 3 --e2e-debug --timeout-all 300` and verify filtered/verbose output

### Implementation for User Story 6

- [ ] T051 [US6] Create test_06_implement.py with TestSpeckitImplement class in tests/e2e/stages/test_06_implement.py
- [ ] T052 [US6] Implement test_implement_runs_successfully that runs /speckit.implement via ClaudeRunner in tests/e2e/stages/test_06_implement.py
- [ ] T053 [US6] Implement test_implement_produces_code that verifies implementation artifacts created in tests/e2e/stages/test_06_implement.py
- [ ] T054 [US6] Add @pytest.mark.e2e and @pytest.mark.stage(6) decorators to stage 6 tests
- [ ] T055 [US6] Verify --stage N filtering works correctly in tests/e2e/conftest.py
- [ ] T056 [US6] Verify --stage N-M range filtering works correctly in tests/e2e/conftest.py
- [ ] T057 [US6] Verify --e2e-debug enables streaming output in ClaudeRunner in tests/e2e/helpers/claude_runner.py
- [ ] T058 [US6] Verify --timeout-all overrides all stage timeouts in ClaudeRunner in tests/e2e/helpers/claude_runner.py

**Checkpoint**: All CLI options work and Stage 6 tests complete

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple stages

- [ ] T059 [P] Add .gitignore entries for tests/e2e/output/ directories
- [ ] T060 [P] Add error messages for Claude CLI not authenticated in ClaudeRunner
- [ ] T061 [P] Add error messages for timeout exceeded in ClaudeRunner
- [ ] T062 Verify all assertion error messages are clear and actionable in FileVerifier
- [ ] T063 Verify all assertion error messages are clear and actionable in GitVerifier
- [ ] T064 Run full E2E test suite to validate end-to-end workflow

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - US2 (init) → US3 (specify) → US4 (plan) → US5 (tasks) → US6 (implement) in runtime
  - BUT implementation tasks can proceed in parallel since they're different files
- **Polish (Phase 9)**: Depends on all stages being complete

### User Story Dependencies

- **User Story 1 (P1)**: Framework orchestration - depends on Phase 2
- **User Story 2 (P1)**: Stage 1 tests - can implement after Phase 2
- **User Story 3 (P1)**: Stages 2-3 tests - can implement in parallel with US2
- **User Story 4 (P2)**: Stage 4 tests - can implement in parallel with US2, US3
- **User Story 5 (P2)**: Stage 5 tests - can implement in parallel with US2-US4
- **User Story 6 (P3)**: Stage 6 tests + CLI options - can implement in parallel with US2-US5

### Within Each User Story

- Create test file structure first
- Implement test class and methods
- Add pytest markers last
- Test file can be committed after all its tests are complete

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002-T005)
- Foundational tasks T008 and T009 (FileVerifier, GitVerifier) can run in parallel
- Stage test files (T024, T030-T031, T039, T045, T051) can all be created in parallel
- All Polish tasks marked [P] can run in parallel (T059-T061)

---

## Parallel Example: Stage Test Files

```bash
# Launch all stage test file creation together:
Task: "Create test_01_init.py with TestSpeckitInit class in tests/e2e/stages/test_01_init.py"
Task: "Create test_02_constitution.py with TestSpeckitConstitution class in tests/e2e/stages/test_02_constitution.py"
Task: "Create test_03_specify.py with TestSpeckitSpecify class in tests/e2e/stages/test_03_specify.py"
Task: "Create test_04_plan.py with TestSpeckitPlan class in tests/e2e/stages/test_04_plan.py"
Task: "Create test_05_tasks.py with TestSpeckitTasks class in tests/e2e/stages/test_05_tasks.py"
Task: "Create test_06_implement.py with TestSpeckitImplement class in tests/e2e/stages/test_06_implement.py"
```

---

## Implementation Strategy

### MVP First (User Stories 1-3 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Framework)
4. Complete Phase 4: User Story 2 (Stage 1 - Init)
5. Complete Phase 5: User Story 3 (Stages 2-3 - Constitution, Specify)
6. **STOP and VALIDATE**: Run `pytest tests/e2e/ --stage 1-3`
7. MVP delivers: working init and specify validation

### Incremental Delivery

1. Setup + Foundational → Framework ready
2. Add US2 (init tests) → Validate Stage 1
3. Add US3 (specify tests) → Validate Stages 2-3
4. Add US4 (plan tests) → Validate Stage 4
5. Add US5 (tasks tests) → Validate Stage 5
6. Add US6 (implement + CLI options) → Full suite complete
7. Polish → Production ready

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: Stage 1-2 tests (US2, part of US3)
   - Developer B: Stage 3-4 tests (part of US3, US4)
   - Developer C: Stage 5-6 tests (US5, US6)
3. Stages integrate when merged

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 64 |
| Phase 1 (Setup) | 5 tasks |
| Phase 2 (Foundational) | 15 tasks |
| Phase 3 (US1 - Framework) | 3 tasks |
| Phase 4 (US2 - Init) | 6 tasks |
| Phase 5 (US3 - Specify) | 9 tasks |
| Phase 6 (US4 - Plan) | 6 tasks |
| Phase 7 (US5 - Tasks) | 6 tasks |
| Phase 8 (US6 - Implement/Debug) | 8 tasks |
| Phase 9 (Polish) | 6 tasks |
| Parallel Opportunities | 15 tasks marked [P] |
| MVP Scope | Phases 1-5 (US1-US3) |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each stage test file is independently completable
- Verify helpers work before implementing stage tests
- Commit after each task file or logical group
- Stop at any checkpoint to validate independently

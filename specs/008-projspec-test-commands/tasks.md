# Tasks: Modify Tests to Use Projspec Commands

**Input**: Design documents from `/specs/008-projspec-test-commands/`
**Prerequisites**: plan.md, spec.md (user stories), research.md, data-model.md, contracts/

**Tests**: No additional tests requested - this feature modifies existing E2E tests.

**Organization**: Tasks grouped by user story. US1 covers functional command changes, US2 covers documentation/naming consistency.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1 or US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Preparation and baseline verification

- [x] T001 Verify current test suite passes with `pytest tests/e2e/ --collect-only`
- [x] T002 Count current speckit occurrences with `grep -r "speckit" tests/e2e/` for baseline (56 occurrences found)

---

## Phase 2: User Story 1 - Run E2E Tests with Projspec Commands (Priority: P1) 🎯 MVP

**Goal**: Update all test files to use `/projspec.*` commands instead of `/speckit.*` commands

**Independent Test**: Run `pytest tests/e2e/` - all tests should pass with new command naming

### Implementation for User Story 1

- [x] T003 [P] [US1] Update command references in tests/e2e/stages/test_01_init.py (replace any /speckit.* with /projspec.*)
- [x] T004 [P] [US1] Update command references in tests/e2e/stages/test_02_constitution.py (/speckit.constitution → /projspec.constitution)
- [x] T005 [P] [US1] Update command references in tests/e2e/stages/test_03_specify.py (/speckit.specify → /projspec.specify)
- [x] T006 [P] [US1] Update command references in tests/e2e/stages/test_04_plan.py (/speckit.plan → /projspec.plan)
- [x] T007 [P] [US1] Update command references in tests/e2e/stages/test_05_tasks.py (/speckit.tasks → /projspec.tasks)
- [x] T008 [P] [US1] Update command references in tests/e2e/stages/test_06_implement.py (/speckit.implement → /projspec.implement)

**Checkpoint**: At this point, all test files should invoke the correct projspec commands. Verify with grep for remaining `/speckit.` patterns.

---

## Phase 3: User Story 2 - Consistent Documentation in Tests (Priority: P2)

**Goal**: Update all class names, docstrings, and comments to reference "projspec" instead of "speckit"

**Independent Test**: Run `grep -ri "speckit" tests/e2e/` - should return zero results

### Implementation for User Story 2

- [x] T009 [P] [US2] Rename class TestSpeckitInit → TestProjspecInit in tests/e2e/stages/test_01_init.py (combined with T003)
- [x] T010 [P] [US2] Rename class TestSpeckitConstitution → TestProjspecConstitution and update docstrings in tests/e2e/stages/test_02_constitution.py (combined with T004)
- [x] T011 [P] [US2] Rename class TestSpeckitSpecify → TestProjspecSpecify and update docstrings in tests/e2e/stages/test_03_specify.py (combined with T005)
- [x] T012 [P] [US2] Rename class TestSpeckitPlan → TestProjspecPlan and update docstrings in tests/e2e/stages/test_04_plan.py (combined with T006)
- [x] T013 [P] [US2] Rename class TestSpeckitTasks → TestProjspecTasks and update docstrings in tests/e2e/stages/test_05_tasks.py (combined with T007)
- [x] T014 [P] [US2] Rename class TestSpeckitImplement → TestProjspecImplement and update docstrings in tests/e2e/stages/test_06_implement.py (combined with T008)
- [x] T015 [US2] Update speckit reference in tests/e2e/stages/__init__.py

**Checkpoint**: All speckit references should now be replaced with projspec throughout the codebase.

---

## Phase 4: Polish & Verification

**Purpose**: Final validation and cleanup

- [x] T016 Verify zero speckit occurrences remain with `grep -ri "speckit" tests/e2e/` (verified: 0 results)
- [x] T017 Run full test collection to verify no syntax errors with `pytest tests/e2e/ --collect-only` (verified: 20 tests collected)
- [x] T018 Run quickstart.md validation steps to confirm successful migration

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - establishes baseline
- **User Story 1 (Phase 2)**: Depends on Setup - can start immediately after
- **User Story 2 (Phase 3)**: Depends on Setup - can run in parallel with US1 since they modify different parts of the same files (commands vs class names)
- **Polish (Phase 4)**: Depends on completion of both user stories

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on US2 - independently testable
- **User Story 2 (P2)**: No dependencies on US1 - independently testable (though recommended to do together since same files)

### Within Each User Story

- All tasks within a phase marked [P] can run in parallel (different files)
- T003-T008 (US1) all modify different files - fully parallelizable
- T009-T015 (US2) all modify different files - fully parallelizable

### Parallel Opportunities

Within Phase 2 (User Story 1):
```bash
# Launch all command update tasks together:
T003: tests/e2e/stages/test_01_init.py
T004: tests/e2e/stages/test_02_constitution.py
T005: tests/e2e/stages/test_03_specify.py
T006: tests/e2e/stages/test_04_plan.py
T007: tests/e2e/stages/test_05_tasks.py
T008: tests/e2e/stages/test_06_implement.py
```

Within Phase 3 (User Story 2):
```bash
# Launch all naming update tasks together:
T009: tests/e2e/stages/test_01_init.py
T010: tests/e2e/stages/test_02_constitution.py
T011: tests/e2e/stages/test_03_specify.py
T012: tests/e2e/stages/test_04_plan.py
T013: tests/e2e/stages/test_05_tasks.py
T014: tests/e2e/stages/test_06_implement.py
T015: tests/e2e/stages/__init__.py
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (baseline verification)
2. Complete Phase 2: User Story 1 (command updates)
3. **STOP and VALIDATE**: Run `pytest tests/e2e/ --collect-only` to verify tests still load
4. Tests should now use correct projspec commands

### Incremental Delivery

1. Complete Setup → Baseline established
2. Complete User Story 1 → Functional correctness achieved (MVP!)
3. Complete User Story 2 → Documentation consistency achieved
4. Complete Polish → Full validation complete

### Recommended Approach (Same Developer)

Since all tasks modify different files but related content, the most efficient approach is:

1. Complete T001-T002 (Setup)
2. For each test file, complete both US1 and US2 tasks together:
   - T003 + T009 for test_01_init.py
   - T004 + T010 for test_02_constitution.py
   - T005 + T011 for test_03_specify.py
   - T006 + T012 for test_04_plan.py
   - T007 + T013 for test_05_tasks.py
   - T008 + T014 for test_06_implement.py
   - T015 for __init__.py
3. Complete T016-T018 (Polish)

---

## Notes

- [P] tasks = different files, no dependencies
- All test files can be updated in parallel since each file is independent
- Total of 92 speckit occurrences to replace across 7 files
- Case-sensitive replacement: `speckit` → `projspec`, `Speckit` → `Projspec`
- Commit after each file or phase completion

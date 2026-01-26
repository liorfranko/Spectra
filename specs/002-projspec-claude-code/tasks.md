# Tasks: ProjSpec - Spec-Driven Development Toolkit for Claude Code

**Input**: Design documents from `/specs/002-projspec-claude-code/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Note**: Tests are NOT explicitly requested in the feature specification. Test tasks will be minimal (focused on critical integration tests only).

## Phase 1: Setup (Project Infrastructure)

**Purpose**: Initialize project structure, packaging, and tooling

- [X] T001 Create Python package structure per plan.md in src/projspec_cli/
- [X] T002 Create pyproject.toml with hatchling build backend and dependencies
- [X] T003 [P] Create tests/ directory structure per plan.md
- [X] T004 [P] Create scripts/ directory with bash script stubs
- [X] T005 [P] Create templates/ directory with all template files

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before any user story

**⚠️ CRITICAL**: All user stories depend on these being complete

- [X] T006 Implement Pydantic models for ProjectConfig in src/projspec_cli/models/config.py
- [X] T007 Implement Pydantic models for FeatureState in src/projspec_cli/models/feature.py
- [X] T008 Implement git utilities (get_repo_root, is_worktree, etc.) in src/projspec_cli/utils/git.py
- [X] T009 Implement path resolution utilities in src/projspec_cli/utils/paths.py
- [X] T010 [P] Implement common.sh with shared bash functions in scripts/common.sh
- [X] T011 [P] Implement check-prerequisites.sh validation script in scripts/check-prerequisites.sh

**Checkpoint**: Foundation ready - CLI commands and bash scripts can now be built

---

## Phase 3: User Story 1 - Initialize a New Project (Priority: P1) 🎯 MVP

**Goal**: Developer can run `projspec init` to set up spec-driven development structure with worktrees

**Independent Test**: Run `projspec init` in empty git repo, verify all directories and files created

### Implementation for User Story 1

- [X] T012 [US1] Create CLI entry point in src/projspec_cli/__main__.py
- [X] T013 [US1] Implement main CLI app with Typer in src/projspec_cli/cli.py
- [X] T014 [US1] Implement `init` command logic in src/projspec_cli/services/init.py
- [X] T015 [US1] Implement `init` command handler in src/projspec_cli/cli.py (calls init service)
- [X] T016 [P] [US1] Create spec-template.md in templates/spec-template.md
- [X] T017 [P] [US1] Create plan-template.md in templates/plan-template.md
- [X] T018 [P] [US1] Create tasks-template.md in templates/tasks-template.md
- [X] T019 [P] [US1] Create checklist-template.md in templates/checklist-template.md
- [X] T020 [P] [US1] Create agent-file-template.md (CLAUDE.md template) in templates/agent-file-template.md
- [X] T021 [US1] Create default constitution.md template in templates/constitution-template.md
- [X] T022 [US1] Add Rich output formatting for init success/error messages
- [X] T023 [US1] Handle edge cases: already initialized, not a git repo, --force flag

**Checkpoint**: `projspec init` fully functional, creates all required structure

---

## Phase 4: User Story 2 - Create Feature Specifications (Priority: P1)

**Goal**: Developer can describe a feature and get a structured specification with worktree isolation

**Independent Test**: Run specify command, verify worktree created, spec.md generated with all sections

### Implementation for User Story 2

- [X] T024 [US2] Create specify.md command template in templates/commands/specify.md
- [X] T025 [US2] Implement create-new-feature.sh script in scripts/create-new-feature.sh
- [X] T026 [US2] Add worktree creation logic with symlinks in create-new-feature.sh
- [X] T027 [US2] Add feature numbering logic (scan specs/ for next number) in create-new-feature.sh
- [X] T028 [US2] Add slug generation from feature description in create-new-feature.sh
- [X] T029 [P] [US2] Create clarify.md command template in templates/commands/clarify.md

**Checkpoint**: New features get isolated worktrees with linked specs

---

## Phase 5: User Story 3 - Generate Implementation Plans (Priority: P2)

**Goal**: Developer can generate technical implementation plans from specifications

**Independent Test**: Run plan command with complete spec, verify plan.md and supporting docs created

### Implementation for User Story 3

- [X] T030 [US3] Create plan.md command template in templates/commands/plan.md
- [X] T031 [US3] Implement setup-plan.sh script in scripts/setup-plan.sh
- [X] T032 [US3] Implement update-agent-context.sh script in scripts/update-agent-context.sh

**Checkpoint**: Plan generation produces complete technical documentation

---

## Phase 6: User Story 4 - Generate Actionable Tasks (Priority: P2)

**Goal**: Developer can generate dependency-ordered task breakdown from plans

**Independent Test**: Run tasks command, verify tasks.md has phases, IDs, dependencies

### Implementation for User Story 4

- [X] T033 [US4] Create tasks.md command template in templates/commands/tasks.md
- [X] T034 [US4] Create taskstoissues.md command template in templates/commands/taskstoissues.md

**Checkpoint**: Task generation and GitHub issue conversion working

---

## Phase 7: User Story 5 - Execute Implementation (Priority: P3)

**Goal**: Developer can execute tasks sequentially with context preservation

**Independent Test**: Run implement command, verify task progress tracking works

### Implementation for User Story 5

- [X] T035 [US5] Create implement.md command template in templates/commands/implement.md
- [X] T036 [US5] Implement status service for task tracking in src/projspec_cli/services/status.py
- [X] T037 [US5] Implement `status` command handler in src/projspec_cli/cli.py
- [X] T038 [US5] Add Rich output for status display (panels, tables)
- [X] T039 [US5] Add --json output option for status command

**Checkpoint**: Implementation tracking and status display functional

---

## Phase 8: User Story 6 - Project Constitution (Priority: P3)

**Goal**: Developer can establish project-wide principles that influence all features

**Independent Test**: Create constitution, verify subsequent plans reference it

### Implementation for User Story 6

- [X] T040 [US6] Create constitution.md command template in templates/commands/constitution.md
- [X] T041 [US6] Update plan command template to check constitution in templates/commands/plan.md

**Checkpoint**: Constitution influences all generated content

---

## Phase 9: Supporting Commands & Scripts

**Purpose**: Additional utilities and analysis commands

- [X] T042 [P] Create analyze.md command template in templates/commands/analyze.md
- [X] T043 [P] Create checklist.md command template in templates/commands/checklist.md
- [X] T044 Implement archive-feature.sh script in scripts/archive-feature.sh
- [X] T045 Implement `check` command (environment validation) in src/projspec_cli/cli.py
- [X] T046 Implement `version` command in src/projspec_cli/cli.py

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final quality improvements

- [X] T047 [P] Add error handling with Rich panels across all CLI commands
- [X] T048 [P] Ensure all scripts have --json output option
- [X] T049 Add script execution permissions and shebang lines
- [ ] T050 Run quickstart.md validation scenarios (manual verification)
- [ ] T051 Verify worktree workflow end-to-end
- [X] T052 Create conftest.py with test fixtures in tests/conftest.py
- [X] T053 Create basic integration test for init workflow in tests/integration/test_init.py

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion - BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 - Foundation must be complete
- **US2 (Phase 4)**: Depends on Phase 2 - Can run in parallel with US1
- **US3 (Phase 5)**: Depends on Phase 2 - Can run in parallel with US1/US2
- **US4 (Phase 6)**: Depends on Phase 2 - Can run in parallel with earlier stories
- **US5 (Phase 7)**: Depends on Phase 2 - Can run in parallel with earlier stories
- **US6 (Phase 8)**: Depends on Phase 2 - Can run in parallel with earlier stories
- **Supporting (Phase 9)**: Depends on Phase 2
- **Polish (Phase 10)**: Depends on all prior phases

### User Story Independence

All user stories can be implemented and tested independently after Foundational phase completes:

- **US1 (Init)**: Standalone - no dependencies on other stories
- **US2 (Specify)**: Standalone - uses scripts from foundational
- **US3 (Plan)**: Standalone - uses templates and scripts
- **US4 (Tasks)**: Standalone - uses templates
- **US5 (Implement)**: Standalone - uses services and CLI
- **US6 (Constitution)**: Standalone - uses templates

### Within Each User Story

- CLI commands depend on services
- Services depend on models and utilities
- Templates can be created in parallel [P]
- Scripts can be created in parallel [P]

### Parallel Opportunities

Setup phase (all [P] tasks can run together):
```
T003, T004, T005 - parallel directory creation
```

Foundational phase:
```
T010, T011 - bash scripts in parallel
```

US1 phase:
```
T016, T017, T018, T019, T020 - all templates in parallel
```

US2 phase:
```
T029 - clarify template parallel with specify work
```

Supporting phase:
```
T042, T043 - command templates in parallel
```

Polish phase:
```
T047, T048 - error handling improvements in parallel
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T011)
3. Complete Phase 3: User Story 1 (T012-T023)
4. **STOP and VALIDATE**: Run `projspec init` end-to-end
5. Delivers: Working initialization command

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → `projspec init` works → **MVP!**
3. Add US2 → Feature specification with worktrees works
4. Add US3 → Plan generation works
5. Add US4 → Task breakdown works
6. Add US5 → Implementation tracking works
7. Add US6 → Constitution works
8. Supporting + Polish → Production ready

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| Setup | T001-T005 (5) | Project infrastructure |
| Foundational | T006-T011 (6) | Core models, utils, scripts |
| US1 (P1) | T012-T023 (12) | Initialize command |
| US2 (P1) | T024-T029 (6) | Specify command + worktrees |
| US3 (P2) | T030-T032 (3) | Plan command |
| US4 (P2) | T033-T034 (2) | Tasks command |
| US5 (P3) | T035-T039 (5) | Implement command + status |
| US6 (P3) | T040-T041 (2) | Constitution command |
| Supporting | T042-T046 (5) | Additional commands/scripts |
| Polish | T047-T053 (7) | Quality and testing |

**Total Tasks**: 53
**MVP (US1 only)**: 23 tasks (Setup + Foundational + US1)
**Parallel opportunities**: 14 tasks can run in parallel within their phases

---

## Notes

- [P] tasks = different files, no dependencies
- [US#] label maps task to specific user story
- Each user story is independently completable and testable
- Commit after each task completion
- Spec-kit prompt templates should be adapted, not copied verbatim
- All bash scripts require `set -euo pipefail` for strict error handling

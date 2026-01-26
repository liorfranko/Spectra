# Tasks: Worktree-Based Feature Workflow

**Input**: Design documents from `/specs/007-worktree-workflow/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/worktree-context.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- Scripts: `.specify/scripts/bash/`
- Commands: `.claude/commands/`
- Skills: `.claude/skills/learned/`
- Templates: `.specify/templates/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization - N/A for this feature (no new project structure needed)

This feature modifies existing files rather than creating new project structure. No setup tasks required.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core worktree detection functions that ALL user stories depend on

**CRITICAL**: User stories 1-4 all depend on these functions existing in common.sh

- [ ] T001 [P] Implement `is_worktree()` function in .specify/scripts/bash/common.sh
- [ ] T002 [P] Implement `get_main_repo_from_worktree()` function in .specify/scripts/bash/common.sh
- [ ] T003 [P] Implement `get_worktree_for_branch()` function in .specify/scripts/bash/common.sh
- [ ] T004 Implement `check_worktree_context()` function in .specify/scripts/bash/common.sh (depends on T001, T002, T003)
- [ ] T005 [P] Implement `list_worktrees()` helper function in .specify/scripts/bash/common.sh

**Checkpoint**: Foundation ready - all worktree utility functions available for use by scripts and commands

---

## Phase 3: User Story 1 - Start New Feature in Dedicated Worktree (Priority: P1) MVP

**Goal**: Developers can create new features with isolated worktrees via `/projspec.specify`

**Independent Test**: Run `/projspec.specify "test feature"` and verify:
- Worktree created at `worktrees/NNN-test-feature/`
- Spec file created at `worktrees/NNN-test-feature/specs/NNN-test-feature/spec.md`
- Feature branch checked out in worktree

**Note**: Core worktree creation is already implemented. These tasks ensure messaging and edge cases are handled.

### Implementation for User Story 1

- [ ] T006 [US1] Review and update worktree creation messages in .specify/scripts/bash/create-new-feature.sh to use consistent "worktree" terminology
- [ ] T007 [US1] Update `/projspec.specify` command documentation in .claude/commands/projspec.specify.md with worktree workflow guidance

**Checkpoint**: User Story 1 complete - developers can create new features with proper worktree setup

---

## Phase 4: User Story 2 - Execute Commands from Worktree Context (Priority: P1)

**Goal**: All projspec commands work correctly when executed from a worktree

**Independent Test**: Navigate to worktree, run `/projspec.plan`, verify:
- Specs read from worktree's specs directory
- Plan artifacts created in correct location
- No errors about missing paths

### Implementation for User Story 2

- [ ] T008 [US2] Add worktree context detection to .specify/scripts/bash/check-prerequisites.sh
- [ ] T009 [US2] Add worktree context check to .specify/scripts/bash/setup-plan.sh
- [ ] T010 [P] [US2] Update .claude/commands/projspec.plan.md to document worktree behavior
- [ ] T011 [P] [US2] Update .claude/commands/projspec.implement.md to ensure source modifications target worktree directory
- [ ] T012 [US2] Verify `get_repo_root()` correctly resolves paths from worktree context in .specify/scripts/bash/common.sh
- [ ] T012a [US2] Verify source code isolation: create test file in worktree, confirm it does NOT appear in main repository

**Checkpoint**: User Story 2 complete - all commands work seamlessly from worktree context

---

## Phase 5: User Story 3 - Navigate Between Worktrees (Priority: P2)

**Goal**: Developers can easily navigate between worktrees and understand their current context

**Independent Test**: Create two features, navigate between worktrees, verify changes are isolated

### Implementation for User Story 3

- [ ] T013 [US3] Update .claude/skills/learned/worktree-based-feature-workflow.md with multi-worktree navigation guidance
- [ ] T014 [US3] Add worktree list display to create-new-feature.sh output showing existing worktrees
- [ ] T015 [P] [US3] Update quickstart documentation at specs/007-worktree-workflow/quickstart.md with navigation examples and cleanup troubleshooting

**Checkpoint**: User Story 3 complete - developers can navigate between worktrees confidently

---

## Phase 6: User Story 4 - Clean Up Completed Feature Worktrees (Priority: P3)

**Goal**: Developers can remove worktrees after features are merged

**Independent Test**: Remove worktree with `git worktree remove`, verify specs were already merged via PR

### Implementation for User Story 4

- [ ] T016 [US4] Add cleanup guidance to .claude/skills/learned/worktree-based-feature-workflow.md
- [ ] T017 [US4] Add worktree prune recommendation to check-prerequisites.sh for stale worktree cleanup

**Checkpoint**: User Story 4 complete - developers can clean up worktrees safely

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates and final validation

- [ ] T018 [P] Update terminology from "branch" to "worktree" in .specify/templates/spec-template.md where appropriate
- [ ] T019 [P] Review and update error messages in all modified scripts for consistency
- [ ] T020 Run manual validation using quickstart.md scenarios
- [ ] T021 Update CLAUDE.md to reflect worktree workflow patterns (if needed)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: N/A - no new structure needed
- **Phase 2 (Foundational)**: BLOCKS all user stories - must complete first
- **Phase 3 (US1)**: Depends on Phase 2
- **Phase 4 (US2)**: Depends on Phase 2
- **Phase 5 (US3)**: Depends on Phase 2
- **Phase 6 (US4)**: Depends on Phase 2
- **Phase 7 (Polish)**: Depends on all user stories

### User Story Dependencies

- **User Story 1 (P1)**: Foundational functions only - no story dependencies
- **User Story 2 (P1)**: Foundational functions only - can run parallel with US1
- **User Story 3 (P2)**: Foundational functions + benefits from US1/US2 but independently testable
- **User Story 4 (P3)**: Foundational functions + benefits from US3 navigation docs

### Within Foundational Phase

Tasks T001, T002, T003, T005 can run in parallel (different functions, no dependencies).
Task T004 depends on T001, T002, T003 (uses those functions internally).

### Parallel Opportunities

```text
Foundational Phase (Phase 2):
  Parallel: T001, T002, T003, T005
  Sequential: T004 (after T001, T002, T003)

User Story 1 (Phase 3):
  Parallel: T006, T007 (different files)

User Story 2 (Phase 4):
  Sequential: T008 → T009 → T012
  Parallel: T010, T011 (different files)

User Story 3 (Phase 5):
  Sequential: T013 → T014
  Parallel: T015 (different file)

User Story 4 (Phase 6):
  Parallel: T016, T017 (different files)

Polish (Phase 7):
  Parallel: T018, T019
  Sequential: T020 → T021
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 2: Foundational (5 tasks)
2. Complete Phase 3: User Story 1 (2 tasks)
3. Complete Phase 4: User Story 2 (6 tasks)
4. **STOP and VALIDATE**: Test worktree creation and command execution
5. Feature is usable at this point

### Incremental Delivery

1. Foundational → Core functions available
2. US1 + US2 → MVP - create features and run commands from worktrees
3. US3 → Multi-worktree navigation guidance
4. US4 → Cleanup documentation
5. Polish → Final consistency pass

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| Foundational | 5 | Core worktree functions in common.sh |
| US1 (P1) | 2 | Feature creation with worktrees |
| US2 (P1) | 6 | Command execution from worktrees (includes isolation test) |
| US3 (P2) | 3 | Multi-worktree navigation (includes cleanup docs) |
| US4 (P3) | 2 | Worktree cleanup |
| Polish | 4 | Documentation and validation |
| **Total** | **22** | |

**Parallel opportunities**: 8 tasks marked [P]
**MVP scope**: Foundational + US1 + US2 = 13 tasks

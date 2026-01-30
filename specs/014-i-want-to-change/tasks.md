# Tasks: Rename Project from ProjSpec to Spectra

Generated: 2026-01-30
Feature: specs/014-i-want-to-change
Source: plan.md, spec.md, data-model.md, research.md

## Overview

- Total Tasks: 42
- Phases: 7
- Estimated Complexity: Medium
- Parallel Execution Groups: 6

## Task Legend

- `[ ]` - Incomplete task
- `[x]` - Completed task
- `[P]` - Can execute in parallel with other [P] tasks in same group
- `[US#]` - Linked to User Story # (e.g., [US1] = User Story 1)
- `CHECKPOINT` - Review point before proceeding to next phase

---

## Phase 1: Directory Rename

This phase performs the fundamental directory restructuring using git mv to preserve history.

- [ ] T001 Rename root projspec/ directory to spectra/ using git mv (projspec/ → spectra/)
- [ ] T002 Rename nested plugins/projspec/ to plugins/spectra/ using git mv (spectra/plugins/projspec/ → spectra/plugins/spectra/)
- [ ] T003 Verify git history is preserved for renamed directories (git log verification)
- [ ] T004 CHECKPOINT: Verify directory structure matches spec

---

## Phase 2: Configuration Update

Update the plugin manifest to reflect the new name and version.

- [ ] T005 [US1] Update plugin.json name field from "projspec" to "spectra" (spectra/plugins/spectra/.claude-plugin/plugin.json)
- [ ] T006 [US1] Update plugin.json version to 2.0.0 for breaking change (spectra/plugins/spectra/.claude-plugin/plugin.json)
- [ ] T007 [US1] Verify plugin.json is valid JSON after changes (spectra/plugins/spectra/.claude-plugin/plugin.json)
- [ ] T008 CHECKPOINT: Verify plugin manifest is correct

---

## Phase 3: Command Updates (US-001)

Update all 12 command files to use the new /spectra: prefix.

### Entity Tasks
- [ ] T009 [US1] Update accept.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/accept.md)
- [ ] T010 [US1] Update analyze.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/analyze.md)
- [ ] T011 [US1] Update cancel.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/cancel.md)
- [ ] T012 [US1] Update clarify.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/clarify.md)
- [ ] T013 [US1] Update constitution.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/constitution.md)
- [ ] T014 [US1] Update implement.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/implement.md)
- [ ] T015 [US1] Update issues.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/issues.md)
- [ ] T016 [US1] Update merge.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/merge.md)
- [ ] T017 [US1] Update plan.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/plan.md)
- [ ] T018 [US1] Update review-pr.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/review-pr.md)
- [ ] T019 [US1] Update specify.md - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/specify.md)
- [ ] T020 [US1] Update tasks.md command - replace /projspec: with /spectra: (spectra/plugins/spectra/commands/tasks.md)

### Verification
- [ ] T021 [US1] Verify all commands contain /spectra: prefix (grep verification)
- [ ] T022 [US1] CHECKPOINT: Verify zero /projspec: occurrences in commands directory

---

## Phase 4: Script Updates (US-001)

Update all 5 bash scripts to use new paths and references.

- [ ] T023 [P] [US1] Update check-prerequisites.sh - replace projspec references (spectra/plugins/spectra/scripts/check-prerequisites.sh)
- [ ] T024 [P] [US1] Update common.sh - replace projspec references (spectra/plugins/spectra/scripts/common.sh)
- [ ] T025 [P] [US1] Update any remaining script files with projspec references (spectra/plugins/spectra/scripts/)
- [ ] T026 [US1] Verify all scripts use spectra paths (grep verification)
- [ ] T027 [US1] CHECKPOINT: Verify zero projspec occurrences in scripts directory

---

## Phase 5: Documentation Updates (US-002, US-003)

Update all documentation files for consistent Spectra branding.

### README Updates
- [ ] T028 [P] [US2] [US3] Update root README.md with Spectra branding (README.md)
- [ ] T029 [P] [US2] [US3] Update spectra/README.md with Spectra branding (spectra/README.md)

### CLAUDE.md Updates
- [ ] T030 [US2] Update CLAUDE.md project description to reference Spectra (CLAUDE.md)
- [ ] T031 [US2] Update CLAUDE.md directory structure references (CLAUDE.md)

### Template Updates
- [ ] T032 [P] [US1] Update template files with spectra references (spectra/plugins/spectra/templates/)
- [ ] T033 [P] [US1] Update agent description files (spectra/plugins/spectra/agents/)

### Verification
- [ ] T034 [US2] Verify documentation consistency (grep verification)
- [ ] T035 [US2] [US3] CHECKPOINT: Verify zero projspec occurrences in documentation

---

## Phase 6: Verification (All Stories)

Comprehensive verification that all renaming is complete.

- [ ] T036 [US1] [US2] Run grep to verify zero "projspec" occurrences in all files (full codebase grep)
- [ ] T037 [US1] Test /spectra:specify command execution (manual test)
- [ ] T038 [US1] Test /spectra:plan command execution (manual test)
- [ ] T039 [US1] Test /spectra:tasks command execution (manual test)
- [ ] T040 [US1] Verify plugin loads correctly and appears as "Spectra" (plugin listing)
- [ ] T041 [US1] [US2] [US3] CHECKPOINT: All verification criteria passed

---

## Phase 7: GitHub Repository Rename (US-003)

Rename the GitHub repository for complete brand consistency.

- [ ] T042 [US3] Rename GitHub repository from projspec to spectra via GitHub Settings (github.com/liorfranko/projspec → spectra)

---

## Dependencies

### Phase Dependencies

| Phase | Depends On | Description |
|-------|------------|-------------|
| Phase 1: Directory Rename | None | Initial structure changes |
| Phase 2: Configuration | Phase 1 | Requires renamed directories |
| Phase 3: Command Updates | Phase 1 | Requires renamed directories |
| Phase 4: Script Updates | Phase 1 | Requires renamed directories |
| Phase 5: Documentation | Phase 1 | Requires renamed directories |
| Phase 6: Verification | Phases 1-5 | Requires all changes complete |
| Phase 7: GitHub Rename | Phase 6 | Requires verification passed |

### Task Dependency Table

| Task ID | Description | Blocked By | Blocks | Parallel |
|---------|-------------|------------|--------|----------|
| T001 | Rename root directory | - | T002, T005+ | No |
| T002 | Rename nested plugin directory | T001 | T003, T005+ | No |
| T003 | Verify git history | T002 | T004 | No |
| T004 | Phase 1 checkpoint | T003 | T005 | No |
| T005 | Update plugin.json name | T004 | T006, T007 | No |
| T006 | Update plugin.json version | T005 | T007 | No |
| T007 | Verify plugin.json | T006 | T008 | No |
| T008 | Phase 2 checkpoint | T007 | T009-T020 | No |
| T009-T020 | Command updates | T008 | T021 | Yes (within) |
| T021 | Verify commands | T009-T020 | T022 | No |
| T022 | Phase 3 checkpoint | T021 | T023-T025 | No |
| T023-T025 | Script updates | T022 | T026 | Yes |
| T026 | Verify scripts | T023-T025 | T027 | No |
| T027 | Phase 4 checkpoint | T026 | T028-T033 | No |
| T028-T033 | Documentation updates | T027 | T034 | Yes |
| T034 | Verify documentation | T028-T033 | T035 | No |
| T035 | Phase 5 checkpoint | T034 | T036 | No |
| T036 | Final grep verification | T035 | T037-T040 | No |
| T037-T040 | Command tests | T036 | T041 | Yes |
| T041 | Phase 6 checkpoint | T036-T040 | T042 | No |
| T042 | GitHub rename | T041 | - | No |

### Parallel Execution Groups

#### Group A: Command Updates (Phase 3)
Tasks T009-T020 can execute in parallel - each updates a separate file.

#### Group B: Script Updates (Phase 4)
Tasks T023-T025 are marked [P] - update separate script files.

#### Group C: Documentation Updates (Phase 5)
Tasks T028-T029, T032-T033 are marked [P] - update separate documentation files.

#### Group D: Command Tests (Phase 6)
Tasks T037-T040 can execute in parallel - independent verification tests.

### Dependency Diagram: Critical Path

```
T001 ──▶ T002 ──▶ T003 ──▶ T004 (Phase 1 Complete)
                              │
                              ▼
                           T005 ──▶ T006 ──▶ T007 ──▶ T008 (Phase 2 Complete)
                                                         │
              ┌──────────────────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────────────────────┐
    │  T009-T020 (12 command updates) [Parallel]  │
    └─────────────────────────────────────────────┘
              │
              ▼
           T021 ──▶ T022 (Phase 3 Complete)
              │
              ▼
    ┌─────────────────────────────────┐
    │ T023-T025 (Script updates) [P]  │
    └─────────────────────────────────┘
              │
              ▼
           T026 ──▶ T027 (Phase 4 Complete)
              │
              ▼
    ┌─────────────────────────────────────────┐
    │ T028-T033 (Documentation updates) [P]   │
    └─────────────────────────────────────────┘
              │
              ▼
           T034 ──▶ T035 (Phase 5 Complete)
              │
              ▼
           T036 (Full verification)
              │
              ▼
    ┌────────────────────────────────┐
    │ T037-T040 (Command tests) [P]  │
    └────────────────────────────────┘
              │
              ▼
           T041 (Phase 6 Complete)
              │
              ▼
           T042 (GitHub rename - Final)
```

---

## Validation Summary

### Format Validation
✓ All tasks have valid T### format
✓ All user story tasks have [US#] markers
✓ Parallel tasks marked with [P]
✓ Checkpoints present at phase boundaries

### Dependency Validation
✓ No circular dependencies
✓ All dependency references valid
✓ Phase order enforced through checkpoints

### Priority Validation
✓ Phase 1-2 tasks (critical path) have no lower-priority blockers
✓ US-001 (High priority) tasks execute before US-003 (Medium) GitHub rename

---

## Story-to-Task Mapping

| Story ID | Description | Tasks | Count |
|----------|-------------|-------|-------|
| US-001 | Install plugin with new name | T005-T027, T037-T041 | 28 |
| US-002 | Existing user transition | T028-T036, T041 | 10 |
| US-003 | Developer discovers project | T028-T029, T035, T041-T042 | 5 |

---

## Notes

- All directory renames use `git mv` to preserve history
- Version bump to 2.0.0 indicates breaking change (new command prefix)
- GitHub rename is final step after all verification passes
- Existing worktrees will continue to work as they use branch names, not plugin names

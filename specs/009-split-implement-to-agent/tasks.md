# Tasks: Split Implement Command into Agent and Direct Modes

Generated: 2026-01-27
Feature: specs/009-split-implement-to-agent
Source: plan.md, spec.md, data-model.md, research.md

## Overview

- Total Tasks: 12
- Phases: 4
- Estimated Complexity: Medium
- Parallel Execution Groups: 2

## Task Legend

- `[ ]` - Incomplete task
- `[x]` - Completed task
- `[P]` - Can execute in parallel with other [P] tasks in same group
- `[US#]` - Linked to User Story # (e.g., [US1] = User Story 1)
- `CHECKPOINT` - Review point before proceeding to next phase

---

## Phase 1: Setup

No setup tasks required - this feature modifies an existing command file in an established plugin structure.

---

## Phase 2: Foundational

### Flag Parsing and Mode Selection

- [X] T001 Add flag parsing section to implement.md after prerequisites (commands/implement.md)
  - Parse `$ARGUMENTS` for `--agent` and `--direct` flags
  - Detect conflict when both flags provided → display error and exit
  - Set MODE variable to "agent" or "direct"
  - Requirements: FR-001, FR-005

- [X] T002 Add mode indicator display after flag parsing (commands/implement.md)
  - Display "Executing tasks in agent mode (isolated context per task)" for agent mode
  - Display "Executing tasks in direct mode (sequential, no agents)" for direct mode
  - Display "(default)" suffix when no flag provided
  - Requirements: FR-001, US-003

---

## Phase 3: User Story Implementation

### US-001: Agent Mode (Existing Behavior Preservation)

- [X] T003 [US1] Verify agent mode section is properly marked as conditional (commands/implement.md)
  - Wrap existing Task tool spawning logic in MODE == "agent" conditional
  - Ensure parallel task [P] handling remains in agent mode section
  - No functional changes to agent mode behavior
  - Requirements: FR-002

### US-002: Direct Mode Execution

- [X] T004 [US2] Add direct mode execution section to implement.md (commands/implement.md)
  - Create new section for MODE == "direct" execution path
  - Execute tasks inline without spawning Task tool agents
  - Read task details and implement changes in current context
  - Requirements: FR-003

- [X] T005 [US2] Implement parallel task handling for direct mode (commands/implement.md)
  - Track count of [P] marked tasks encountered
  - Execute [P] tasks sequentially (same as non-parallel in direct mode)
  - Display info message after parallel batch: "Note: N parallel tasks ran sequentially in direct mode"
  - Requirements: FR-003

- [X] T006 [US2] Ensure git commit workflow is shared between modes (commands/implement.md)
  - Both modes use same git add/commit/push sequence
  - Commit format: `[T###] Description` with Co-Authored-By trailer
  - Update task checkbox in tasks.md after successful commit
  - Requirements: FR-004

### US-003: Default Mode Behavior

- [X] T007 [US3] Verify default mode falls through to agent mode (commands/implement.md)
  - When no flag provided, MODE defaults to "agent"
  - Backward compatibility: existing `/projspec.implement` invocations work unchanged
  - Requirements: FR-005, US-003

### Error Handling (Cross-cutting)

- [X] T008 Add error handling for conflicting flags (commands/implement.md)
  - If both --agent and --direct present, display error message
  - Error format: "Cannot use both --agent and --direct flags"
  - Exit without executing any tasks
  - Requirements: FR-001 (edge case)

- [X] T009 Ensure retry/skip/abort available in both modes (commands/implement.md)
  - Verify error handling section applies to both agent and direct modes
  - Direct mode retry: re-read task details, re-attempt implementation
  - Consistent UX regardless of mode
  - Requirements: FR-002, FR-003

---

## Phase 4: Testing and Polish

### Test Fixtures

- [X] T010 [P] Create test-tasks-sequential.md fixture (tests/test-tasks-sequential.md)
  - Sample tasks.md with 3 sequential tasks (no [P] markers)
  - Tasks: create file, modify file, add documentation
  - Used to verify both modes produce identical outcomes
  - Requirements: SC-001, SC-002

- [X] T011 [P] Create test-tasks-parallel.md fixture (tests/test-tasks-parallel.md)
  - Sample tasks.md with 2 parallel [P] tasks and 1 sequential task
  - Used to verify agent mode parallelization and direct mode sequential fallback
  - Requirements: SC-001, FR-002, FR-003

### Validation

- [X] T012 CHECKPOINT: Manual validation of both modes (manual testing)
  - Run `/projspec.implement --agent` on test-tasks-sequential.md
  - Run `/projspec.implement --direct` on test-tasks-sequential.md
  - Compare git logs: verify identical commit count and format
  - Run `/projspec.implement --direct` on test-tasks-parallel.md
  - Verify "Note: N parallel tasks ran sequentially" message appears
  - Run `/projspec.implement` (no flag) and verify agent mode is used
  - Requirements: SC-001, SC-002, SC-003

---

## Dependencies

### Phase Dependencies

| Phase | Depends On | Description |
|-------|------------|-------------|
| Phase 1: Setup | None | No setup required |
| Phase 2: Foundational | None | Can start immediately |
| Phase 3: User Stories | Phase 2 | Requires flag parsing to be in place |
| Phase 4: Testing | Phase 3 | Requires all implementation complete |

### Task Dependencies

| Task | Blocked By | Blocks | Parallel |
|------|------------|--------|----------|
| T001 | - | T002, T003, T004 | No |
| T002 | T001 | T003, T004 | No |
| T003 | T002 | T007 | No |
| T004 | T002 | T005, T006 | No |
| T005 | T004 | T009 | No |
| T006 | T004 | T009 | No |
| T007 | T003 | T012 | No |
| T008 | T001 | T012 | No |
| T009 | T005, T006 | T012 | No |
| T010 | - | T012 | Yes |
| T011 | - | T012 | Yes |
| T012 | T007, T008, T009, T010, T011 | - | No |

### Parallel Execution Groups

#### Group A: Test Fixtures (Phase 4)
Tasks that can run simultaneously:
- T010: Create test-tasks-sequential.md
- T011: Create test-tasks-parallel.md

**Execution**: Both can start immediately and run in parallel.

---

## Dependency Diagram

```
Phase 2                    Phase 3                           Phase 4
────────                   ────────                          ────────

┌───────┐
│ T001  │ Flag parsing
│       │
└───┬───┘
    │
    ▼
┌───────┐
│ T002  │ Mode display
│       │
└───┬───┘
    │
    ├─────────────────────────────────────────┐
    │                                         │
    ▼                                         ▼
┌───────┐                               ┌───────┐
│ T003  │ Agent mode                    │ T004  │ Direct mode
│ [US1] │                               │ [US2] │
└───┬───┘                               └───┬───┘
    │                                       │
    │                           ┌───────────┼───────────┐
    │                           │           │           │
    │                           ▼           ▼           │
    │                     ┌───────┐   ┌───────┐        │
    │                     │ T005  │   │ T006  │        │
    │                     │ [P]   │   │ Git   │        │
    │                     │ tasks │   │ commit│        │
    │                     └───┬───┘   └───┬───┘        │
    │                         │           │             │
    │                         └─────┬─────┘             │
    │                               │                   │
    ▼                               ▼                   │
┌───────┐                     ┌───────┐                │
│ T007  │ Default             │ T009  │ Error          │
│ [US3] │ mode                │       │ handling       │
└───┬───┘                     └───┬───┘                │
    │                             │                     │
    │   ┌───────┐                 │   ┌───────┐ ┌───────┐
    │   │ T008  │ Flag            │   │ T010  │ │ T011  │
    │   │       │ conflict        │   │  [P]  │ │  [P]  │
    │   └───┬───┘                 │   └───┬───┘ └───┬───┘
    │       │                     │       │         │
    └───────┼─────────────────────┼───────┼─────────┘
            │                     │       │
            └─────────────────────┼───────┘
                                  │
                                  ▼
                            ┌───────────┐
                            │   T012    │
                            │ CHECKPOINT│
                            │ Validation│
                            └───────────┘
```

---

## Validation Summary

### Format Validation
✓ All tasks have valid T### format
✓ All task IDs are unique
✓ User story markers [US#] present where required

### Dependency Validation
✓ No circular dependencies detected
✓ All dependency references are valid
✓ Phase dependencies are consistent

### Priority Distribution

| Priority | Task Count | Percentage |
|----------|------------|------------|
| P1 (Critical) | 9 | 75% |
| P2 (Testing) | 3 | 25% |

---

## Next Steps

Ready to implement? Run:

```
/projspec.implement
```

Or for direct mode (faster, no agents):

```
/projspec.implement --direct
```

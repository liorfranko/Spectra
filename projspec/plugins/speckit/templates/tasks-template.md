---
description: "Task list template for feature implementation"
---

# Tasks: {{FEATURE_NAME}}

**Feature**: `{{FEATURE_ID}}-{{FEATURE_SLUG}}`
**Input**: Design documents from `/specs/{{FEATURE_ID}}-{{FEATURE_SLUG}}/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

## Task Format: `[ID] [P?] [Story] Description`

| Notation | Meaning |
|----------|---------|
| `[P]` | Can run in parallel (different files, no dependencies) |
| `[USn]` | Maps to User Story n from spec.md |
| `T###` | Task identifier (e.g., T001, T002) |

## Task Attributes Reference

Each task has these attributes:
- **id**: Task identifier (e.g., T001)
- **title**: Imperative-form task description
- **status**: pending, in-progress, completed
- **priority**: P1, P2, P3 (inherited from user story)
- **blockedBy**: Task IDs this depends on
- **blocks**: Task IDs that depend on this

---

## Phase 1: Setup

**Purpose**: Project initialization and shared infrastructure

- [ ] T001 {{SETUP_TASK_1}}
- [ ] T002 {{SETUP_TASK_2}}
- [ ] T003 [P] {{SETUP_TASK_3}}

<!--
Example setup tasks:
- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize project with required dependencies
- [ ] T003 [P] Configure linting and formatting tools
-->

---

## Phase 2: Foundational

**Purpose**: Core infrastructure that MUST complete before ANY user story begins

**CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 {{FOUNDATION_TASK_1}}
- [ ] T005 [P] {{FOUNDATION_TASK_2}}
- [ ] T006 [P] {{FOUNDATION_TASK_3}}

<!--
Example foundational tasks:
- [ ] T004 Setup database schema and migrations
- [ ] T005 [P] Implement authentication framework
- [ ] T006 [P] Create base models/entities all stories depend on
-->

**Checkpoint**: Foundation ready - user story implementation can begin

---

## Phase 3: User Stories

### User Story 1: {{US1_TITLE}} (Priority: P1)

**Goal**: {{US1_GOAL}}
**Acceptance Criteria**: {{US1_ACCEPTANCE}}

- [ ] T007 [P] [US1] {{US1_TASK_1}}
- [ ] T008 [P] [US1] {{US1_TASK_2}}
- [ ] T009 [US1] {{US1_TASK_3}} (depends on T007, T008)
- [ ] T010 [US1] {{US1_TASK_4}}

**Checkpoint**: User Story 1 is independently functional and testable

---

### User Story 2: {{US2_TITLE}} (Priority: P2)

**Goal**: {{US2_GOAL}}
**Acceptance Criteria**: {{US2_ACCEPTANCE}}

- [ ] T011 [P] [US2] {{US2_TASK_1}}
- [ ] T012 [US2] {{US2_TASK_2}}
- [ ] T013 [US2] {{US2_TASK_3}}

**Checkpoint**: User Story 2 is independently functional and testable

---

### User Story 3: {{US3_TITLE}} (Priority: P3)

**Goal**: {{US3_GOAL}}
**Acceptance Criteria**: {{US3_ACCEPTANCE}}

- [ ] T014 [P] [US3] {{US3_TASK_1}}
- [ ] T015 [US3] {{US3_TASK_2}}
- [ ] T016 [US3] {{US3_TASK_3}}

**Checkpoint**: User Story 3 is independently functional and testable

---

<!-- Add additional user story sections as needed, following the same pattern -->

---

## Phase 4: Polish

**Purpose**: Cross-cutting improvements affecting multiple user stories

- [ ] T0XX [P] Documentation updates
- [ ] T0XX Code cleanup and refactoring
- [ ] T0XX Performance optimization
- [ ] T0XX Security hardening
- [ ] T0XX Run quickstart.md validation

---

## Dependencies

### Phase Dependencies

```
Phase 1: Setup
    └── Phase 2: Foundational (BLOCKS all user stories)
            ├── Phase 3: User Story 1 (P1)
            ├── Phase 3: User Story 2 (P2)  ← Can run in parallel with US1
            └── Phase 3: User Story 3 (P3)  ← Can run in parallel with US1, US2
                    └── Phase 4: Polish
```

### Task Dependencies

| Task | Blocked By | Blocks |
|------|------------|--------|
| T004 | T001-T003 | T007+ (all user story tasks) |
| T009 | T007, T008 | T010 |
| {{TASK_ID}} | {{BLOCKED_BY}} | {{BLOCKS}} |

### Parallel Execution Groups

Tasks marked `[P]` within the same phase can execute simultaneously:

**Setup parallel group**: T003
**Foundation parallel group**: T005, T006
**US1 parallel group**: T007, T008
**US2 parallel group**: T011
**US3 parallel group**: T014

---

## Implementation Strategy

### MVP First (P1 Only)
1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete User Story 1 (P1)
4. **STOP and VALIDATE**: Test US1 independently
5. Deploy if ready

### Incremental Delivery
1. Setup + Foundational -> Foundation ready
2. User Story 1 -> Test -> Deploy (MVP!)
3. User Story 2 -> Test -> Deploy
4. User Story 3 -> Test -> Deploy

### Parallel Team Strategy
After Foundational completes:
- Developer A: User Story 1
- Developer B: User Story 2
- Developer C: User Story 3

---

## Example Tasks (For Reference)

Below are concrete examples showing proper task format:

```markdown
## Phase 1: Setup

- [ ] T001 Create directory structure: src/, tests/, docs/
- [ ] T002 Initialize Node.js project with package.json
- [ ] T003 [P] Configure ESLint and Prettier

## Phase 2: Foundational

- [ ] T004 Create database connection module in src/db/connection.js
- [ ] T005 [P] Implement JWT authentication middleware in src/middleware/auth.js
- [ ] T006 [P] Create User model in src/models/user.js

## Phase 3: User Stories

### User Story 1: User Registration (Priority: P1)

- [ ] T007 [P] [US1] Create registration form component in src/components/RegisterForm.jsx
- [ ] T008 [P] [US1] Create registration API endpoint in src/api/auth/register.js
- [ ] T009 [US1] Implement email validation service in src/services/emailValidation.js
- [ ] T010 [US1] Add registration success/error handling
```

---

## Notes

- Each task should be completable in a single work session
- Commit after each task or logical group
- Verify each checkpoint before proceeding
- Tasks without `[P]` must wait for their blockedBy tasks
- Stop at any checkpoint to validate independently

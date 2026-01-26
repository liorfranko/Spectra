# Tasks: {FEATURE_NAME}

**Branch**: `{BRANCH_NUMBER}-{BRANCH_SLUG}` | **Date**: {DATE}
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

---

## Progress Summary

| Status | Count |
|--------|-------|
| Pending | {N} |
| In Progress | {N} |
| Completed | {N} |
| **Total** | **{N}** |

---

## Task List

### Phase 1: {PHASE_NAME}

#### T001: {TASK_TITLE}

- **Status**: Pending | In Progress | Completed | Blocked
- **Priority**: P1 | P2 | P3
- **Estimated Effort**: XS | S | M | L | XL
- **Dependencies**: None | T{NNN}
- **Assigned**: {ASSIGNEE}

**Description**:
{DETAILED_TASK_DESCRIPTION}

**Acceptance Criteria**:
- [ ] {CRITERION_1}
- [ ] {CRITERION_2}

**Files to Create/Modify**:
- `{FILE_PATH_1}`: {WHAT_TO_DO}
- `{FILE_PATH_2}`: {WHAT_TO_DO}

**Notes**:
{IMPLEMENTATION_NOTES}

---

#### T002: {TASK_TITLE}

- **Status**: Pending
- **Priority**: P1
- **Estimated Effort**: M
- **Dependencies**: T001
- **Assigned**: {ASSIGNEE}

**Description**:
{DETAILED_TASK_DESCRIPTION}

**Acceptance Criteria**:
- [ ] {CRITERION_1}
- [ ] {CRITERION_2}

**Files to Create/Modify**:
- `{FILE_PATH_1}`: {WHAT_TO_DO}

---

### Phase 2: {PHASE_NAME}

#### T003: {TASK_TITLE}

- **Status**: Pending
- **Priority**: P2
- **Estimated Effort**: S
- **Dependencies**: T001, T002
- **Assigned**: {ASSIGNEE}

**Description**:
{DETAILED_TASK_DESCRIPTION}

**Acceptance Criteria**:
- [ ] {CRITERION_1}

---

## Blocked Tasks

<!-- Tasks that cannot proceed due to external blockers -->

| Task | Blocked By | Resolution |
|------|------------|------------|
| {TASK_ID} | {BLOCKER_DESCRIPTION} | {HOW_TO_RESOLVE} |

---

## Completed Tasks

<!-- Move completed tasks here for reference -->

### Completed in {DATE}

- [x] T{NNN}: {TASK_TITLE} - {COMPLETION_NOTES}

---

## Task Dependencies Graph

<!-- Visual representation of task dependencies -->

```
T001 ──┬──> T002 ──> T004
       │
       └──> T003 ──> T005
```

---

## Effort Legend

| Size | Description | Typical Duration |
|------|-------------|------------------|
| XS | Trivial change | < 30 min |
| S | Small task | 30 min - 2 hours |
| M | Medium task | 2 - 4 hours |
| L | Large task | 4 - 8 hours |
| XL | Very large task | 1 - 2 days |

---

<!--
TEMPLATE INSTRUCTIONS:
1. Replace all {PLACEHOLDERS} with actual content
2. Each task should map to plan.md phases
3. Update status as work progresses
4. Move completed tasks to the Completed section
5. Track blockers and their resolutions
6. Keep Progress Summary updated

TASK STATUS WORKFLOW:
Pending -> In Progress -> Completed
                      -> Blocked -> In Progress -> Completed
-->

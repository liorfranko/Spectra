# Implementation Plan: {FEATURE_NAME}

**Branch**: `{BRANCH_NUMBER}-{BRANCH_SLUG}` | **Date**: {DATE} | **Spec**: [spec.md](./spec.md)

---

## Summary

<!-- 2-3 sentence overview of the implementation approach -->

{IMPLEMENTATION_SUMMARY}

---

## Technical Context

### Existing Codebase Analysis

<!-- Understanding of relevant existing code, patterns, and conventions -->

- **Relevant Files**: {LIST_KEY_FILES}
- **Patterns in Use**: {EXISTING_PATTERNS}
- **Integration Points**: {WHERE_NEW_CODE_CONNECTS}

### Technology Stack

<!-- Technologies and tools required for this implementation -->

- {TECHNOLOGY_1}
- {TECHNOLOGY_2}

---

## Constitution Check

<!-- Verify alignment with project constitution principles -->

| Principle | Alignment | Notes |
|-----------|-----------|-------|
| {PRINCIPLE_1} | {YES/NO/PARTIAL} | {EXPLANATION} |
| {PRINCIPLE_2} | {YES/NO/PARTIAL} | {EXPLANATION} |

---

## Project Structure

<!-- How this feature fits into the project structure -->

```text
{PROJECT_ROOT}/
├── {DIRECTORY_1}/
│   ├── {NEW_FILE_1}      # {DESCRIPTION}
│   └── {NEW_FILE_2}      # {DESCRIPTION}
├── {DIRECTORY_2}/
│   └── {MODIFIED_FILE}   # {CHANGES}
└── {OTHER_STRUCTURE}
```

### New Files

| File | Purpose |
|------|---------|
| `{PATH_1}` | {DESCRIPTION} |
| `{PATH_2}` | {DESCRIPTION} |

### Modified Files

| File | Changes |
|------|---------|
| `{PATH_1}` | {WHAT_CHANGES} |
| `{PATH_2}` | {WHAT_CHANGES} |

---

## Complexity Tracking

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {RISK_1} | Low/Med/High | Low/Med/High | {STRATEGY} |
| {RISK_2} | Low/Med/High | Low/Med/High | {STRATEGY} |

### Complexity Indicators

- **Estimated Effort**: {SMALL/MEDIUM/LARGE}
- **Integration Complexity**: {LOW/MEDIUM/HIGH}
- **Testing Complexity**: {LOW/MEDIUM/HIGH}

---

## Implementation Phases

<!-- Break down into logical implementation phases -->

### Phase 1: {PHASE_NAME}

**Goal**: {PHASE_OBJECTIVE}

- [ ] {STEP_1}
- [ ] {STEP_2}
- [ ] {STEP_3}

### Phase 2: {PHASE_NAME}

**Goal**: {PHASE_OBJECTIVE}

- [ ] {STEP_1}
- [ ] {STEP_2}

---

## API Design

<!-- If applicable, define APIs, interfaces, or contracts -->

### {INTERFACE_NAME}

```{LANGUAGE}
{API_DEFINITION}
```

---

## Testing Strategy

### Unit Tests

- {TEST_AREA_1}: {WHAT_TO_TEST}
- {TEST_AREA_2}: {WHAT_TO_TEST}

### Integration Tests

- {INTEGRATION_TEST_1}
- {INTEGRATION_TEST_2}

### Manual Testing

- {MANUAL_TEST_SCENARIO_1}
- {MANUAL_TEST_SCENARIO_2}

---

## Rollback Plan

<!-- How to safely revert if issues arise -->

{ROLLBACK_STRATEGY}

---

## Open Design Decisions

<!-- Decisions that need to be made during implementation -->

- [ ] {DECISION_1}
- [ ] {DECISION_2}

---

<!--
TEMPLATE INSTRUCTIONS:
1. Replace all {PLACEHOLDERS} with actual content
2. Remove sections that don't apply to this feature
3. Add additional phases as needed
4. Link back to spec.md for requirements traceability
5. Update this document as implementation progresses
-->

# Implementation Plan: [FEATURE_NAME]

**Feature ID:** [FEATURE_ID]
**Branch:** [BRANCH]
**Created:** [DATE]
**Status:** Draft

---

## Summary

<!--
INSTRUCTIONS: Provide a concise summary (2-3 sentences) that captures:
1. The primary requirement being addressed
2. The technical approach chosen to implement it
-->

[PRIMARY_REQUIREMENT_DESCRIPTION]

**Technical Approach:** [BRIEF_TECHNICAL_APPROACH]

---

## Technical Context

<!--
INSTRUCTIONS: Document the technical environment and constraints for this feature.
Be specific about versions and requirements.
-->

### Language & Runtime

| Aspect | Value |
|--------|-------|
| Primary Language | [LANGUAGE] |
| Runtime/Version | [RUNTIME_VERSION] |
| Package Manager | [PACKAGE_MANAGER] |

### Dependencies

<!-- List key dependencies required for this feature -->

| Dependency | Version | Purpose |
|------------|---------|---------|
| [DEPENDENCY_1] | [VERSION] | [PURPOSE] |
| [DEPENDENCY_2] | [VERSION] | [PURPOSE] |

### Platform & Environment

| Aspect | Value |
|--------|-------|
| Target Platform | [PLATFORM] |
| Minimum Requirements | [MIN_REQUIREMENTS] |
| Environment Variables | [ENV_VARS_NEEDED] |

### Constraints

<!-- List any technical constraints that affect implementation -->

- [CONSTRAINT_1]
- [CONSTRAINT_2]

---

## Constitution Check

<!--
INSTRUCTIONS: Validate this plan against the project's constitution principles.
For each principle, mark compliance status and provide justification.
Status options: COMPLIANT, PARTIAL, VIOLATION, N/A
-->

| Principle | Status | Justification |
|-----------|--------|---------------|
| [PRINCIPLE_1] | [STATUS] | [JUSTIFICATION] |
| [PRINCIPLE_2] | [STATUS] | [JUSTIFICATION] |
| [PRINCIPLE_3] | [STATUS] | [JUSTIFICATION] |

### Constitution Reference

<!-- Link to or cite the project constitution being validated against -->

**Constitution Path:** [CONSTITUTION_PATH]
**Constitution Version:** [CONSTITUTION_VERSION]

---

## Project Structure

<!--
INSTRUCTIONS: Define where files will be created or modified.
Separate documentation from source code locations.
-->

### Documentation Layout

```
specs/[FEATURE_ID]/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── tasks.md             # Generated task list
└── checklists/          # Requirement checklists
    └── [CHECKLIST_FILES]
```

### Source Code Layout

```
[SOURCE_ROOT]/
├── [DIRECTORY_1]/
│   ├── [FILE_1]         # [PURPOSE]
│   └── [FILE_2]         # [PURPOSE]
├── [DIRECTORY_2]/
│   └── [FILE_3]         # [PURPOSE]
└── [TEST_DIRECTORY]/
    └── [TEST_FILES]     # [PURPOSE]
```

### File Mapping

<!-- Map each planned file to its purpose and the spec requirements it addresses -->

| File Path | Purpose | Spec Requirements |
|-----------|---------|-------------------|
| [FILE_PATH_1] | [PURPOSE] | [REQ_IDS] |
| [FILE_PATH_2] | [PURPOSE] | [REQ_IDS] |

---

## Complexity Tracking

<!--
INSTRUCTIONS: Document any complexity that may require violations of
project constraints. Each violation must be explicitly justified.
-->

### Complexity Score

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Lines of Code (estimated) | [LOC] | [THRESHOLD] | [OK/OVER] |
| Number of Files | [FILES] | [THRESHOLD] | [OK/OVER] |
| External Dependencies | [DEPS] | [THRESHOLD] | [OK/OVER] |

### Violation Justifications

<!--
If any threshold is exceeded, document the justification here.
Leave empty if all metrics are within acceptable limits.
-->

| Violation | Justification | Mitigation |
|-----------|---------------|------------|
| [VIOLATION_DESCRIPTION] | [WHY_NECESSARY] | [HOW_TO_MITIGATE] |

---

## Implementation Notes

<!--
INSTRUCTIONS: Add any additional notes relevant to implementation.
This section is optional but recommended for complex features.
-->

### Key Decisions

- [DECISION_1]: [RATIONALE]
- [DECISION_2]: [RATIONALE]

### Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [RISK_1] | [LOW/MED/HIGH] | [LOW/MED/HIGH] | [MITIGATION] |

### Open Questions

- [ ] [QUESTION_1]
- [ ] [QUESTION_2]

---

## Approval

<!--
INSTRUCTIONS: Track plan approval status.
Update when plan is reviewed and approved.
-->

| Role | Approver | Date | Status |
|------|----------|------|--------|
| Technical Lead | [NAME] | [DATE] | [PENDING/APPROVED] |
| Stakeholder | [NAME] | [DATE] | [PENDING/APPROVED] |

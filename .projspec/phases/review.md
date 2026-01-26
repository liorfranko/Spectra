# Review Phase Template

This template guides the final review of implementation against the specification. Work through each section to verify all requirements are met before archiving the project.

---

## Spec Verification

<!-- Compare implementation against spec.md requirements -->

### Requirements Checklist

Review each requirement from `spec.md` and verify implementation status:

| Requirement | Implemented | Location/Evidence | Notes |
|-------------|-------------|-------------------|-------|
| [Requirement from spec] | Yes/No/Partial | [File or test reference] | [Any gaps or deviations] |

### User Stories Verification

For each user story in the spec, confirm the capability is delivered:

- [ ] **[User Story 1]**: [How it was implemented]
- [ ] **[User Story 2]**: [How it was implemented]
- [ ] **[User Story 3]**: [How it was implemented]

### Gap Analysis

List any requirements that were not fully implemented:

| Requirement | Gap Description | Severity | Recommendation |
|-------------|-----------------|----------|----------------|
| [Requirement] | [What is missing] | Critical/Major/Minor | [Fix now / Defer / Accept] |

---

## Success Criteria Verification

<!-- Verify each success criterion from spec.md is met -->

### Acceptance Criteria

Check each acceptance criterion from the specification:

- [ ] [Criterion 1 from spec]: **Status**: Pass/Fail
  - Evidence: [How verified]
- [ ] [Criterion 2 from spec]: **Status**: Pass/Fail
  - Evidence: [How verified]
- [ ] [Criterion 3 from spec]: **Status**: Pass/Fail
  - Evidence: [How verified]

### Definition of Done

- [ ] All acceptance criteria met
- [ ] Code reviewed and approved
- [ ] Tests passing
- [ ] Documentation updated

---

## Code Quality Review

<!-- Assess code quality, patterns, and best practices -->

### Architecture Alignment

- [ ] Implementation follows the planned architecture from `plan.md`
- [ ] Design patterns are used consistently
- [ ] No architectural deviations without documented reasons

### Code Standards

- [ ] Code follows project style guidelines
- [ ] Naming conventions are consistent
- [ ] No obvious code smells or anti-patterns
- [ ] Error handling is appropriate
- [ ] Logging/debugging aids are in place where needed

### Maintainability

- [ ] Code is readable and self-documenting
- [ ] Complex logic has explanatory comments
- [ ] Functions/methods have appropriate size and responsibility
- [ ] Dependencies are minimal and appropriate

### Issues Found

| File/Location | Issue | Severity | Resolution |
|---------------|-------|----------|------------|
| [Path/line] | [Description] | Critical/Major/Minor | [Action taken or needed] |

---

## Test Coverage Review

<!-- Verify tests exist and provide adequate coverage -->

### Test Inventory

| Test Type | Count | Status | Notes |
|-----------|-------|--------|-------|
| Unit Tests | [N] | All Pass / [N] Failures | [Notes] |
| Integration Tests | [N] | All Pass / [N] Failures | [Notes] |
| End-to-End Tests | [N] | All Pass / [N] Failures | [Notes] |

### Coverage Assessment

- [ ] Critical paths have test coverage
- [ ] Edge cases are tested
- [ ] Error conditions are tested
- [ ] Tests are meaningful (not just for coverage metrics)

### Test Execution

```bash
# Record test execution results here
# Example: pytest --tb=short
```

**Result**: [Pass/Fail with summary]

### Testing Gaps

| Area | Gap Description | Priority |
|------|-----------------|----------|
| [Feature/Component] | [Missing test coverage] | High/Medium/Low |

---

## Documentation Review

<!-- Verify documentation is complete and accurate -->

### README Assessment

- [ ] README exists and is up to date
- [ ] Installation instructions are accurate
- [ ] Usage examples work correctly
- [ ] Configuration options are documented

### Code Documentation

- [ ] Public APIs have docstrings/comments
- [ ] Complex algorithms are explained
- [ ] Configuration files have comments

### Additional Documentation

- [ ] Architecture decisions documented (if applicable)
- [ ] API documentation exists (if applicable)
- [ ] Changelog updated (if applicable)

### Documentation Gaps

| Document | Issue | Action Needed |
|----------|-------|---------------|
| [Document] | [Missing/Outdated/Unclear] | [Specific action] |

---

## Final Report

### Summary

**Overall Status**: Ready to Archive / Needs Remediation

| Category | Status | Score |
|----------|--------|-------|
| Spec Verification | Pass/Fail | [X]/[Y] requirements met |
| Success Criteria | Pass/Fail | [X]/[Y] criteria met |
| Code Quality | Pass/Fail | [Assessment] |
| Test Coverage | Pass/Fail | [Assessment] |
| Documentation | Pass/Fail | [Assessment] |

### Findings Summary

**Strengths:**
- [What was done well]
- [What was done well]

**Issues Requiring Attention:**
- [Critical/major issues that need resolution]
- [Critical/major issues that need resolution]

**Minor Observations:**
- [Non-blocking observations for future improvement]
- [Non-blocking observations for future improvement]

---

## Next Steps

Based on review findings, select the appropriate path:

### If Complete (No Critical/Major Issues)

- [ ] All critical and major issues resolved
- [ ] Final test suite passes
- [ ] Documentation is complete
- **Action**: Proceed to archive phase with `projspec advance`

### If Gaps Found (Critical/Major Issues Exist)

1. **Document gaps** in the Gap Analysis section above
2. **Create remediation tasks** for unresolved issues
3. **Return to implement phase** if significant work needed: `projspec set-phase implement`
4. **Re-run review** after remediation is complete

---

**Phase Checklist**

Before archiving, ensure:

- [ ] All spec requirements verified against implementation
- [ ] All success criteria have pass/fail status
- [ ] Code quality review completed
- [ ] Test suite passes
- [ ] Documentation is adequate
- [ ] No unresolved critical or major issues
- [ ] Final report summary is complete

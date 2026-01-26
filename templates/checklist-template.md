# Quality Checklist: {FEATURE_NAME}

**Branch**: `{BRANCH_NUMBER}-{BRANCH_SLUG}` | **Date**: {DATE}
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Tasks**: [tasks.md](./tasks.md)

---

## Pre-Implementation Checklist

### Specification Review

- [ ] All user stories have clear acceptance criteria
- [ ] Requirements are complete and unambiguous
- [ ] Success criteria are measurable
- [ ] Out of scope items are documented
- [ ] Dependencies are identified
- [ ] Open questions are resolved or tracked

### Plan Review

- [ ] Technical approach aligns with codebase patterns
- [ ] Constitution principles are respected
- [ ] File structure is clear and follows conventions
- [ ] Risks are identified with mitigations
- [ ] Testing strategy is defined

---

## Implementation Checklist

### Code Quality

- [ ] Code follows project style guidelines
- [ ] Functions/methods are appropriately sized
- [ ] Names are descriptive and consistent
- [ ] No hardcoded values (use constants/config)
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate and useful

### Documentation

- [ ] Code comments explain "why" not "what"
- [ ] Public APIs have docstrings
- [ ] README updated if needed
- [ ] CHANGELOG updated if needed

### Testing

- [ ] Unit tests cover happy paths
- [ ] Unit tests cover edge cases
- [ ] Unit tests cover error conditions
- [ ] Integration tests verify component interaction
- [ ] All tests pass locally

---

## Pre-Merge Checklist

### Code Review

- [ ] Self-review completed
- [ ] Code diff is reasonable size
- [ ] No debugging code left behind
- [ ] No commented-out code without explanation
- [ ] No TODO comments without issue links

### Testing Verification

- [ ] All automated tests pass
- [ ] Manual testing completed per test scenarios
- [ ] No regressions in existing functionality
- [ ] Performance is acceptable

### Documentation Verification

- [ ] Spec status updated to Approved
- [ ] Tasks marked as Completed
- [ ] Any new dependencies documented

---

## Feature-Specific Checks

### {FEATURE_AREA_1}

- [ ] {SPECIFIC_CHECK_1}
- [ ] {SPECIFIC_CHECK_2}
- [ ] {SPECIFIC_CHECK_3}

### {FEATURE_AREA_2}

- [ ] {SPECIFIC_CHECK_1}
- [ ] {SPECIFIC_CHECK_2}

---

## Security Checklist

<!-- Remove if not applicable -->

- [ ] No secrets or credentials in code
- [ ] Input validation implemented
- [ ] Output encoding/escaping as needed
- [ ] Authentication/authorization checks in place
- [ ] Sensitive data handled appropriately

---

## Performance Checklist

<!-- Remove if not applicable -->

- [ ] No obvious performance bottlenecks
- [ ] Database queries are optimized
- [ ] Caching considered where appropriate
- [ ] Large operations are paginated/batched

---

## Accessibility Checklist

<!-- Remove if not applicable -->

- [ ] Keyboard navigation works
- [ ] Screen reader compatible
- [ ] Color contrast is sufficient
- [ ] Focus states are visible

---

## Sign-Off

| Role | Name | Date | Approved |
|------|------|------|----------|
| Developer | {NAME} | {DATE} | [ ] |
| Reviewer | {NAME} | {DATE} | [ ] |
| QA | {NAME} | {DATE} | [ ] |

---

## Notes

<!-- Any additional notes or observations -->

{NOTES}

---

<!--
TEMPLATE INSTRUCTIONS:
1. Replace all {PLACEHOLDERS} with actual content
2. Remove sections that don't apply to this feature
3. Add feature-specific checks as needed
4. Check items as they are completed
5. Get sign-offs before merging
-->

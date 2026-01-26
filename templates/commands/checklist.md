# Command: checklist

## Purpose

Generate custom quality checklists for the current feature based on user requirements. This command creates structured, checkable lists that ensure quality standards are met across various dimensions such as UX, security, accessibility, testing, and performance.

The checklist generation process:
1. Reads the existing spec.md and plan.md for the current feature
2. Asks the user what type of checklist they need
3. Generates a comprehensive, context-aware checklist with checkable items
4. Saves the checklist to the feature's checklists/ directory

---

## Prerequisites

Before running this command, verify the following:

1. **Existing spec.md**: The feature must have a spec.md file (via the `specify` command)
2. **Plan.md recommended**: While not strictly required, having plan.md provides better context for technical checklists
3. **Feature directory exists**: The feature's specification directory must exist (e.g., `specs/{ID}-{feature-slug}/` or `.specify/features/{ID}-{feature-slug}/`)
4. **Working in feature context**: You should be in the feature's worktree or have the feature context loaded

If prerequisites are not met, inform the user:
- If no spec.md exists, suggest running the `specify` command first
- If no plan.md exists and a technical checklist is requested, suggest running the `plan` command first for better results

---

## Workflow

Follow these steps in order:

### Step 1: Locate and Read Feature Documents

Find and read the following documents for the current feature:

1. **Feature Specification**: Locate spec.md
   - Check the current directory for spec.md
   - Check `specs/{feature-slug}/spec.md`
   - Check `.specify/features/{feature-slug}/spec.md`

2. **Implementation Plan** (if exists): Locate plan.md
   - Check the same directories as spec.md
   - Extract technical details, components, and integration points

3. **Existing Checklists** (if any): Check `checklists/` directory
   - List existing checklists to avoid duplication
   - Note which types have already been created

Read all available documents thoroughly before proceeding.

### Step 2: Ask User for Checklist Type

Present the user with checklist type options:

```
I've read the feature specification and I'm ready to generate a custom checklist.

What type of checklist would you like me to create?

### Common Checklist Types:

1. **UX Checklist**: User experience, usability, and user flow validation
2. **Security Checklist**: Security best practices, vulnerability prevention, data protection
3. **Accessibility Checklist**: WCAG compliance, screen reader support, keyboard navigation
4. **Testing Checklist**: Test coverage, test scenarios, edge cases to verify
5. **Performance Checklist**: Performance optimization, load considerations, efficiency
6. **Code Review Checklist**: Code quality, patterns, best practices for reviewers
7. **Deployment Checklist**: Pre/post deployment verification steps
8. **API Checklist**: API design, documentation, versioning standards
9. **Custom**: Describe a specific area you want to validate

Which type of checklist would you like? (Enter number, name, or describe a custom type)
```

**If user requests multiple types**:
- Offer to create each as a separate file
- Or combine into one comprehensive checklist (if user prefers)

**If user requests a custom type**:
- Ask for clarification on what aspects to include
- Generate a checklist tailored to their specific needs

### Step 3: Generate the Checklist

Based on the selected type, generate a comprehensive checklist that is:

#### Checklist Quality Criteria

- **Context-aware**: References specific elements from spec.md and plan.md
- **Actionable**: Each item is something that can be verified or checked
- **Complete**: Covers all relevant aspects for the chosen type
- **Prioritized**: Critical items marked for attention
- **Specific**: Avoids generic items; tailored to this feature

#### Checklist Structure

```markdown
# {Checklist Type} Checklist: {Feature Name}

**Feature**: {Feature ID} - {Feature Name}
**Created**: {Date}
**Spec**: spec.md
**Plan**: plan.md (if applicable)

---

## Overview

{Brief description of what this checklist validates and why it matters for this feature}

---

## Critical Items

These items are high-priority and must be verified before release:

- [ ] {Critical item 1 with specific context from spec/plan}
- [ ] {Critical item 2}
- [ ] {Critical item 3}

---

## {Section 1 Name}

### {Subsection if needed}

- [ ] {Checklist item with clear verification criteria}
- [ ] {Another item referencing specific user story or requirement}
- [ ] {Item with notes: **Note**: Additional context}

### {Another subsection}

- [ ] {Item}
- [ ] {Item}

---

## {Section 2 Name}

- [ ] {Items continue...}

---

## Notes & References

- {Any additional notes about using this checklist}
- {References to external standards if applicable (e.g., WCAG 2.1 for accessibility)}

---

## Sign-off

| Reviewer | Date | Status |
|----------|------|--------|
| | | Pending |
```

### Step 4: Generate Type-Specific Content

Use the following guidelines for each checklist type:

#### UX Checklist Content

**Sections to include**:
- User Flows: Each user story flow is intuitive
- Feedback & Messaging: Loading states, error messages, success confirmations
- Consistency: UI elements match design system
- Discoverability: Features are easily found
- Mobile/Responsive: Works across device sizes
- Edge Cases: Empty states, long content, error states

**Reference from spec.md**:
- User stories and acceptance criteria
- User roles and their specific needs

#### Security Checklist Content

**Sections to include**:
- Authentication & Authorization: Proper access controls
- Data Protection: Sensitive data handling, encryption
- Input Validation: Sanitization, injection prevention
- API Security: Rate limiting, authentication
- Secrets Management: No hardcoded secrets
- Audit & Logging: Security events are logged
- Dependencies: No vulnerable dependencies

**Reference from plan.md**:
- Technical components that handle sensitive data
- Integration points that need securing

#### Accessibility Checklist Content

**Sections to include**:
- Keyboard Navigation: All functions accessible via keyboard
- Screen Reader Support: Proper ARIA labels, semantic HTML
- Visual Design: Color contrast, text sizing, focus indicators
- Forms: Labels, error messages, required field indicators
- Media: Alt text, captions, transcripts
- Motion & Animation: Reduced motion support

**Reference from spec.md**:
- UI-related user stories
- Accessibility requirements in NFRs

#### Testing Checklist Content

**Sections to include**:
- Unit Tests: Core logic has unit test coverage
- Integration Tests: Component interactions tested
- E2E Tests: Critical user paths covered
- Edge Cases: Boundary conditions, error states tested
- Performance Tests: Load testing for critical paths
- Manual Testing: Scenarios that require human verification

**Reference from spec.md**:
- Acceptance criteria (each should have a test)
- User story test scenarios

#### Performance Checklist Content

**Sections to include**:
- Load Time: Initial load, lazy loading strategy
- Resource Optimization: Image sizes, bundle size, caching
- Database/API: Query optimization, connection pooling
- Memory: No memory leaks, efficient data structures
- Network: Request batching, data compression
- Metrics: Performance monitoring in place

**Reference from plan.md**:
- NFRs related to performance
- Critical path operations

#### Code Review Checklist Content

**Sections to include**:
- Code Quality: Clean code, naming conventions
- Architecture: Follows project patterns
- Error Handling: Proper exception handling
- Testing: Adequate test coverage
- Documentation: Code comments, API docs
- Security: No security anti-patterns
- Performance: No obvious bottlenecks

#### Deployment Checklist Content

**Sections to include**:
- Pre-Deployment: Feature flags, database migrations
- Environment: Configuration, secrets setup
- Verification: Smoke tests, health checks
- Rollback: Rollback plan documented
- Post-Deployment: Monitoring, alerting
- Communication: Stakeholder notification

#### API Checklist Content

**Sections to include**:
- Design: RESTful/GraphQL best practices
- Documentation: OpenAPI spec, examples
- Versioning: Version strategy in place
- Error Handling: Consistent error responses
- Validation: Input validation, response schemas
- Security: Authentication, rate limiting
- Performance: Pagination, caching headers

### Step 5: Create the Checklists Directory

If the `checklists/` directory does not exist in the feature directory:

1. Create the directory: `{feature-dir}/checklists/`
2. Inform the user that the directory was created

### Step 6: Save the Checklist

Save the generated checklist to the feature's checklists directory:

1. **File naming convention**: `{type}.md`
   - Examples: `ux.md`, `security.md`, `accessibility.md`, `testing.md`
   - For custom types: `{descriptive-name}.md` (e.g., `data-migration.md`)

2. **File location**: `{feature-dir}/checklists/{type}.md`

3. **Handle existing files**:
   - If file exists, ask user: "A {type} checklist already exists. Would you like to replace it or create a new version (e.g., {type}-v2.md)?"

### Step 7: Present the Result

After creating the checklist:

1. **Summarize what was created**:
```
## Checklist Created

**File**: checklists/{type}.md
**Type**: {Checklist Type}
**Items**: {N} total items ({M} critical)

### Summary:
- {Section 1}: {X} items
- {Section 2}: {Y} items
- {Section 3}: {Z} items

### Critical Items to Address:
1. {First critical item}
2. {Second critical item}
3. {Third critical item}

### Next Steps:
1. Review the checklist and customize if needed
2. Work through items during development/review
3. Mark items complete as they are verified
4. Use for sign-off before release
```

2. **Offer to create additional checklists**:
```
Would you like to create another checklist for this feature?
```

---

## Output

Upon successful completion, the following will be created:

### Files Created

| File | Description |
|------|-------------|
| `checklists/{type}.md` | The generated checklist document |

### Directory Created (if needed)

| Directory | Description |
|-----------|-------------|
| `checklists/` | Directory to hold all checklists for the feature |

### Checklist Contents

The checklist will contain:
- Feature context and references
- Critical items section (high-priority)
- Organized sections relevant to the checklist type
- Specific, actionable items with clear verification criteria
- Context from spec.md and plan.md where applicable
- Sign-off section for tracking completion

### Checklist Attributes

Each checklist item:
- Is checkable: `- [ ]` format
- Is specific to this feature when possible
- Has clear pass/fail criteria
- May include notes or context where helpful
- References specific requirements when applicable

---

## Examples

### Example 1: UX Checklist for a Login Feature

**User Request**: "Create a UX checklist"

**Generated Checklist** (partial):
```markdown
# UX Checklist: User Authentication

**Feature**: 042-user-authentication
**Created**: 2026-01-26
**Spec**: spec.md
**Plan**: plan.md

---

## Critical Items

- [ ] Login form is visible and accessible on first page load
- [ ] Password visibility toggle works correctly
- [ ] Error messages are clear and help users fix issues

---

## User Flows

### Login Flow (US1)

- [ ] User can navigate to login from any page
- [ ] Form auto-focuses on email field
- [ ] Tab order follows logical sequence (email -> password -> submit)
- [ ] "Forgot password" link is discoverable

### Session Management (US2)

- [ ] User is informed when session expires
- [ ] Re-authentication is smooth and preserves context
- [ ] Logout confirmation is provided

---

## Feedback & Messaging

- [ ] Loading state shows during authentication attempt
- [ ] Invalid credentials show specific error (not just "Error")
- [ ] Account locked state provides recovery options
- [ ] Success feedback confirms login completion

---

## Edge Cases

- [ ] Empty form submission shows validation errors
- [ ] Very long email addresses display correctly
- [ ] Paste into password field works correctly
- [ ] Browser autofill is supported
```

### Example 2: Security Checklist for an API Feature

**User Request**: "Security checklist"

**Generated Checklist** (partial):
```markdown
# Security Checklist: Project Export API

**Feature**: 055-export-api
**Created**: 2026-01-26

---

## Critical Items

- [ ] API endpoints require authentication
- [ ] Export file access is scoped to authorized users only
- [ ] No sensitive data in URL parameters

---

## Authentication & Authorization

- [ ] All export endpoints validate JWT tokens
- [ ] User can only export their own projects
- [ ] Admin role required for organization-wide exports
- [ ] Token expiration is enforced

---

## Data Protection

- [ ] Exported files are encrypted at rest
- [ ] Download links are time-limited (max 24 hours)
- [ ] PII is excluded or anonymized based on user permissions
- [ ] Export audit log captures who exported what

---

## Input Validation

- [ ] Project IDs are validated before processing
- [ ] Export format parameter only accepts whitelist values
- [ ] Date range parameters are sanitized
- [ ] Maximum export size is enforced
```

### Example 3: Custom Checklist

**User Request**: "Create a checklist for data migration validation"

**AI Response**: "I'll create a custom data migration checklist. A few questions to make it specific:
1. What types of data are being migrated?
2. Are there any critical data integrity requirements?
3. Should I include rollback verification items?"

**User Response**: "User accounts and project data. Data integrity is critical. Yes, include rollback."

**Generated Checklist**:
```markdown
# Data Migration Checklist: {Feature Name}

---

## Critical Items

- [ ] All user accounts migrated with intact credentials
- [ ] Project ownership preserved during migration
- [ ] Rollback script tested in staging environment

---

## Pre-Migration Verification

- [ ] Source data backup completed
- [ ] Target schema matches source structure
- [ ] Migration scripts tested with production data copy
- [ ] Stakeholders notified of migration window

---

## User Account Migration

- [ ] User count matches pre/post migration
- [ ] Email addresses preserved exactly
- [ ] Password hashes migrated (users don't need to reset)
- [ ] User roles and permissions preserved

---

## Project Data Migration

- [ ] All projects migrated with correct ownership
- [ ] Project metadata intact (dates, settings)
- [ ] File attachments accessible post-migration
- [ ] Project relationships preserved

---

## Data Integrity Verification

- [ ] Record counts match source and target
- [ ] Spot-check sample records for accuracy
- [ ] Referential integrity verified
- [ ] No orphaned records in target

---

## Rollback Readiness

- [ ] Rollback script exists and is tested
- [ ] Rollback can complete within acceptable window
- [ ] Rollback leaves system in known good state
- [ ] Rollback documentation is available
```

---

## Error Handling

### Common Issues

1. **No spec.md found**: Guide user to run `specify` command first
2. **Feature directory not found**: Help locate the correct feature directory
3. **Checklists directory not writable**: Check permissions
4. **Invalid checklist type**: Offer the list of valid types
5. **Duplicate checklist file**: Ask about replacement or versioning

### Recovery Steps

If the command fails partway through:
1. Report which steps completed successfully
2. Offer to resume from the failed step
3. If file was partially written, clean up or complete it

### Validation Checks

Before saving the checklist:
- [ ] At least 5 items in the checklist
- [ ] Critical items section is populated
- [ ] Items are specific and actionable
- [ ] Feature references are accurate

---

## Notes

- **Customize after generation**: Generated checklists are starting points; modify to fit your specific needs
- **Iterative use**: Run multiple checklist types for comprehensive quality coverage
- **Team alignment**: Share checklists with team members for consistent quality standards
- **Living documents**: Update checklists as requirements evolve
- **Integration with reviews**: Use checklists during code review and QA processes
- **Sign-off tracking**: Use the sign-off section to track verification status
- **Reusability**: Well-crafted checklists can be templated for similar future features
- **Priority focus**: Start with critical items; they block release
- **Context matters**: The more detailed your spec.md and plan.md, the better the generated checklist

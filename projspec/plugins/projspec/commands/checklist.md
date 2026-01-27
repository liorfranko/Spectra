---
description: "Generate custom validation checklists based on feature type and requirements"
user-invocable: true
argument-hint: checklist type (requirements, implementation, review)
---

# Checklist Command

Generate custom validation checklists tailored to the current feature based on user requirements, feature type, and project context. This command creates structured checklists that help ensure quality gates are met before proceeding to the next development phase.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Arguments

The `$ARGUMENTS` variable contains the optional checklist type to generate. Valid types:
- `requirements` - Validate specification quality before planning
- `implementation` - Validate implementation readiness before coding
- `review` - Validate code quality before PR/merge
- (empty) - Generate all applicable checklists

## Prerequisites

This command works best when feature artifacts exist, but can generate basic checklists without them.

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --json
```

Parse the output to determine available documents and feature context.

## Workflow

### Step 1: Determine Feature Context

**1.1: Check for feature directory and available artifacts**

Run prerequisite check to identify context:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --json
```

Parse JSON output to extract:
- `FEATURE_DIR` - Path to feature directory (may be null if not in feature context)
- `AVAILABLE_DOCS` - List of existing documents

**1.2: Read available artifacts for context**

If in a feature directory, read available documents to understand the feature:

| Document | Extract For Checklist |
|----------|----------------------|
| `spec.md` | User scenarios, requirements, success criteria, edge cases |
| `plan.md` | Technical context, constraints, architecture decisions |
| `data-model.md` | Entities, validation rules, relationships |
| `tasks.md` | Implementation phases, task categories |

**1.3: Determine feature type from context**

Analyze the available artifacts to identify feature type:

| Feature Type | Indicators | Checklist Focus |
|--------------|------------|-----------------|
| CLI Tool | Commands defined, argument parsing | Command coverage, help text, error messages |
| API Service | Endpoints defined, request/response schemas | Input validation, error codes, documentation |
| UI Component | User interactions, visual elements | Accessibility, responsiveness, user feedback |
| Data Pipeline | Input/output transformations, scheduling | Data validation, error recovery, monitoring |
| Plugin/Extension | Hook points, configuration, integration | Compatibility, configuration options, isolation |
| Library | Public API, types, documentation | API consistency, type safety, examples |

Store the inferred feature type for checklist customization.

### Step 2: Determine Checklist Type

**2.1: Parse the $ARGUMENTS to determine requested checklist type**

If `$ARGUMENTS` is provided:
- `requirements` - Generate requirements validation checklist
- `implementation` - Generate implementation readiness checklist
- `review` - Generate code review checklist
- `all` - Generate all applicable checklists

**2.2: If no argument provided, determine from context**

Analyze the current state of artifacts to suggest the appropriate checklist:

| Current State | Suggested Checklist |
|---------------|---------------------|
| Only spec.md exists | requirements |
| spec.md + plan.md exist | implementation |
| tasks.md exists with completed tasks | review |
| No artifacts | requirements (basic template) |

**2.3: Confirm checklist type with user if ambiguous**

If the state is ambiguous, ask the user:
```markdown
## Checklist Type Selection

Based on the current feature state, I can generate the following checklists:

1. **requirements** - Validate the feature specification
2. **implementation** - Verify implementation readiness
3. **review** - Code quality review checklist

Which checklist would you like to generate? (Or type 'all' for all checklists)
```

### Step 3: Generate Requirements Checklist

Generate a requirements validation checklist when type is `requirements` or `all`.

**3.1: Create the requirements checklist structure**

```markdown
# Requirements Checklist: [FEATURE_NAME]

**Purpose**: Validate specification quality before proceeding to implementation planning
**Created**: [DATE in YYYY-MM-DD format]
**Feature**: [Link to spec.md or feature description]

---

## Overview

This checklist validates that the feature specification is complete, well-formed,
and ready for implementation planning. All items should pass before running `/projspec:plan`.

---
```

**3.2: Generate Completeness section based on spec.md**

Extract requirements from spec.md and generate checklist items:

```markdown
## Completeness

### Core Sections
- [ ] Overview section describes feature purpose and scope
- [ ] At least 2 user scenarios are defined (US-001, US-002)
- [ ] Edge cases table has at least 1 entry
- [ ] At least 1 functional requirement is defined (FR-001)
- [ ] At least 1 success criterion is defined (SC-001)
- [ ] Key entities are identified and described
- [ ] Assumptions are documented
- [ ] Open questions are tracked (if any)

### User Scenarios (from spec.md)
{For each US-### found in spec.md:}
- [ ] US-###: Has clear role, action, and benefit
- [ ] US-###: Has testable acceptance criteria
- [ ] US-###: Priority is assigned (P1/P2/P3)
{End for}

### Requirements Coverage
{For each FR-### found in spec.md:}
- [ ] FR-###: Requirement is testable
- [ ] FR-###: Verification method is defined
{End for}
```

**3.3: Generate Quality section based on feature type**

Customize quality checks based on the inferred feature type:

```markdown
## Requirement Quality

### Clarity
- [ ] All requirements are testable (have pass/fail criteria)
- [ ] All requirements are specific (no vague terms like "fast", "easy", "user-friendly")
- [ ] All requirements are atomic (one behavior per requirement)
- [ ] Requirements use consistent terminology

### Implementation Independence
- [ ] No programming languages mentioned (Python, JavaScript, etc.)
- [ ] No frameworks mentioned (React, Django, Express, etc.)
- [ ] No database technologies mentioned (PostgreSQL, MongoDB, etc.)
- [ ] No infrastructure details mentioned (AWS, Docker, etc.)
- [ ] Focus is on "what" not "how"

{If feature type is CLI Tool:}
### CLI-Specific Quality
- [ ] Command syntax is clearly defined
- [ ] Required vs optional arguments are distinguished
- [ ] Help text requirements are specified
- [ ] Error message format is defined
- [ ] Exit codes are documented
{End if}

{If feature type is API Service:}
### API-Specific Quality
- [ ] All endpoints have request/response formats defined
- [ ] Error response structure is specified
- [ ] Authentication requirements are documented
- [ ] Rate limiting requirements are specified
{End if}

{If feature type is UI Component:}
### UI-Specific Quality
- [ ] Accessibility requirements are specified
- [ ] Responsive behavior is defined
- [ ] Loading states are documented
- [ ] Error states are defined
{End if}
```

**3.4: Generate Success Criteria section**

```markdown
## Success Criteria Quality

{For each SC-### found in spec.md:}
- [ ] SC-###: Has measurable target value
- [ ] SC-###: Verification method is defined
- [ ] SC-###: Target is realistic and achievable
{End for}

### General Success Criteria
- [ ] All success criteria have quantifiable metrics
- [ ] Measurement methods are practical to implement
- [ ] Criteria align with user scenarios
```

**3.5: Generate Edge Case section**

```markdown
## Edge Case Coverage

- [ ] Empty/null input cases are considered
- [ ] Boundary conditions are identified
- [ ] Error scenarios are documented
- [ ] Recovery behaviors are specified

{For each edge case in spec.md:}
- [ ] Edge case "{description}": Has defined trigger and expected behavior
{End for}
```

### Step 4: Generate Implementation Checklist

Generate an implementation readiness checklist when type is `implementation` or `all`.

**4.1: Create the implementation checklist structure**

```markdown
# Implementation Checklist: [FEATURE_NAME]

**Purpose**: Validate implementation readiness before starting development
**Created**: [DATE in YYYY-MM-DD format]
**Feature**: [Link to plan.md]

---

## Overview

This checklist validates that the implementation plan is complete and the project
is ready for development. All items should pass before running `/projspec:implement`.

---
```

**4.2: Generate Technical Readiness section from plan.md**

```markdown
## Technical Readiness

### Environment Setup
- [ ] Language and runtime version are specified
- [ ] Package manager is identified
- [ ] All required dependencies are documented
- [ ] Development environment can be set up from plan

### Architecture
- [ ] Project structure is defined
- [ ] File-to-requirement mapping is complete
- [ ] No orphaned requirements (all FR-### have mapped files)
- [ ] Integration points are documented

### Constitution Compliance
{If constitution check exists in plan.md:}
- [ ] All principles have been evaluated
- [ ] No unresolved VIOLATION status exists
- [ ] Partial compliance items have justification
{End if}

### Testing Strategy
- [ ] Test framework is identified
- [ ] Test types are defined (unit, integration, e2e)
- [ ] Coverage requirements are documented
```

**4.3: Generate Data Model Readiness section**

```markdown
## Data Model Readiness

{If data-model.md exists:}
{For each entity in data-model.md:}
### Entity: {EntityName}
- [ ] All attributes have types defined
- [ ] Required fields are marked
- [ ] Validation rules are specified
- [ ] Relationships are documented
{End for}

### Relationships
- [ ] All entity relationships are defined
- [ ] Cascade behaviors are documented
- [ ] State transitions are mapped (if applicable)

{Else:}
- [ ] No formal data model required, or
- [ ] Data model will be created during implementation
{End if}
```

**4.4: Generate Task Readiness section from tasks.md**

```markdown
## Task Readiness

{If tasks.md exists:}
### Task Structure
- [ ] All tasks have unique IDs (T###)
- [ ] Tasks are organized into phases
- [ ] Dependencies are clearly defined
- [ ] No circular dependencies exist

### Phase Coverage
{For each phase in tasks.md:}
- [ ] Phase {N}: {Name} - Tasks are complete and ordered
{End for}

### Parallel Execution
- [ ] Parallel tasks are marked with [P]
- [ ] Parallel tasks don't have conflicting file modifications

{Else:}
- [ ] tasks.md not yet generated
- [ ] Run `/projspec:tasks` before implementation
{End if}
```

### Step 5: Generate Review Checklist

Generate a code review checklist when type is `review` or `all`.

**5.1: Create the review checklist structure**

```markdown
# Review Checklist: [FEATURE_NAME]

**Purpose**: Validate code quality and completeness before merging
**Created**: [DATE in YYYY-MM-DD format]
**Feature**: [Link to implementation]

---

## Overview

This checklist validates that the implementation is complete, tested, and ready
for review and merge. Use this before creating a pull request.

---
```

**5.2: Generate Code Quality section**

```markdown
## Code Quality

### Standards Compliance
- [ ] Code follows project style guidelines
- [ ] No linting errors or warnings
- [ ] No TypeScript/type errors
- [ ] Consistent naming conventions

### Documentation
- [ ] Public APIs have documentation
- [ ] Complex logic has explanatory comments
- [ ] README is updated (if needed)
- [ ] CHANGELOG is updated (if needed)

### Error Handling
- [ ] All error cases are handled
- [ ] Error messages are user-friendly
- [ ] Errors are logged appropriately
- [ ] No silent failures
```

**5.3: Generate Test Coverage section**

```markdown
## Test Coverage

### Unit Tests
- [ ] All new functions have unit tests
- [ ] Edge cases are tested
- [ ] Error paths are tested
- [ ] Tests are readable and maintainable

### Integration Tests
- [ ] Component interactions are tested
- [ ] External dependencies are mocked appropriately
- [ ] Integration points have tests

### Acceptance Tests
{For each SC-### from spec.md:}
- [ ] SC-###: Verified with test or manual validation
{End for}
```

**5.4: Generate Security and Performance section**

```markdown
## Security

- [ ] No sensitive data in code or logs
- [ ] Input validation is implemented
- [ ] No hardcoded credentials
- [ ] Dependencies are from trusted sources

## Performance

- [ ] No obvious performance issues
- [ ] Resource cleanup is handled
- [ ] Large data sets are handled efficiently
- [ ] Async operations don't block

{If success criteria include performance metrics:}
### Performance Criteria
{For each performance-related SC-###:}
- [ ] SC-###: Performance target met
{End for}
{End if}
```

**5.5: Generate Requirement Traceability section**

```markdown
## Requirement Traceability

### Functional Requirements
{For each FR-### from spec.md:}
- [ ] FR-###: Implemented and verified
{End for}

### User Scenarios
{For each US-### from spec.md:}
- [ ] US-###: All acceptance criteria met
{End for}

### Task Completion
{If tasks.md exists:}
- [ ] All tasks marked as complete [x]
- [ ] No skipped or blocked tasks
{End if}
```

### Step 6: Finalize and Write Checklists

**6.1: Add notes and summary sections to each checklist**

```markdown
---

## Notes

<!--
Document any issues, blockers, or observations here.
Format: - [ITEM_REF] Description of issue or note
-->

-

---

## Summary

| Category | Passed | Failed | Skipped |
|----------|--------|--------|---------|
| [Category 1] | 0 | 0 | 0 |
| [Category 2] | 0 | 0 | 0 |
| [Category 3] | 0 | 0 | 0 |
| **Total** | 0 | 0 | 0 |

**Status**: [ ] PASS / [ ] FAIL / [ ] BLOCKED

---

## Instructions

1. Check items as you validate them: `- [x]` for pass, leave unchecked for fail
2. Add notes for any failed or concerning items
3. Update the summary table when complete
4. Mark final status based on results
5. Address any failed items before proceeding
```

**6.2: Determine output location**

If in a feature directory:
- Write to `${FEATURE_DIR}/checklists/{type}.md`
- Create the checklists directory if it doesn't exist

If not in a feature directory:
- Display the checklist content to the user
- Offer to save to a specified location

**6.3: Write checklist files**

For each generated checklist:

```bash
# Ensure checklists directory exists
mkdir -p "${FEATURE_DIR}/checklists"

# Write the checklist
echo "${checklist_content}" > "${FEATURE_DIR}/checklists/${type}.md"
```

**6.4: Report completion**

```markdown
## Checklist Generation Complete

### Generated Checklists

| Checklist | Location | Items |
|-----------|----------|-------|
| {type} | {path} | {item_count} |

### Next Steps

{If type is requirements:}
- Review and complete the requirements checklist
- Address any failed items
- Run `/projspec:plan` when all items pass

{If type is implementation:}
- Review and complete the implementation checklist
- Ensure all prerequisites are met
- Run `/projspec:implement` when all items pass

{If type is review:}
- Review and complete the review checklist
- Address any failed items
- Run `/projspec:review-pr` when all items pass
```

## Output

Upon completion, this command produces:

### Files Created

| File | Description |
|------|-------------|
| `checklists/requirements.md` | Requirements validation checklist (if requested) |
| `checklists/implementation.md` | Implementation readiness checklist (if requested) |
| `checklists/review.md` | Code review checklist (if requested) |

### Console Output

| Output | When Displayed |
|--------|----------------|
| Feature context analysis | At command start |
| Checklist type selection | If type is ambiguous |
| Generation progress | During checklist creation |
| Completion summary | On successful generation |

## Usage

```
/projspec:checklist [type]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `requirements` | Generate requirements validation checklist |
| `implementation` | Generate implementation readiness checklist |
| `review` | Generate code review checklist |
| `all` | Generate all applicable checklists |
| (empty) | Auto-detect appropriate checklist from context |

## Notes

- Checklists are customized based on feature type and available artifacts
- Items are generated from actual spec content when available
- Checklist items can be manually edited after generation
- Run this command multiple times to regenerate as the feature evolves

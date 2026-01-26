---
description: "Validate current feature artifacts against checklists and quality criteria"
user-invocable: true
argument-hint: artifact to validate (spec, plan, tasks, all)
---

# Validate Command

Validate current feature artifacts against checklists, quality criteria, and constitution principles. This command performs automated checks and reports compliance status without modifying any files.

## Arguments

The `$ARGUMENTS` variable contains the artifact(s) to validate:
- `spec` - Validate spec.md against requirements checklist
- `plan` - Validate plan.md against implementation checklist
- `tasks` - Validate tasks.md against task format rules
- `all` - Validate all available artifacts
- (empty) - Auto-detect and validate available artifacts

## Prerequisites

This command requires at least one feature artifact to exist.

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --json
```

## Workflow

### Step 1: Discover Available Artifacts

**1.1: Run prerequisite check to identify feature context**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --json
```

Parse JSON output to extract:
- `FEATURE_DIR` - Path to feature directory
- `AVAILABLE_DOCS` - List of existing documents

**1.2: Determine which artifacts to validate**

Based on `$ARGUMENTS`:

| Argument | Artifacts to Validate |
|----------|----------------------|
| `spec` | spec.md only |
| `plan` | plan.md, research.md, data-model.md |
| `tasks` | tasks.md only |
| `all` | All available artifacts |
| (empty) | All available artifacts |

Filter to only include artifacts that exist in `AVAILABLE_DOCS`.

**1.3: Report validation scope**

```markdown
## Validation Scope

**Feature Directory:** {FEATURE_DIR}
**Requested:** {$ARGUMENTS or "all"}

### Artifacts to Validate

| Artifact | Status | Validation Type |
|----------|--------|-----------------|
| spec.md | {Found/Not Found} | Requirements validation |
| plan.md | {Found/Not Found} | Plan validation |
| research.md | {Found/Not Found} | Research validation |
| data-model.md | {Found/Not Found} | Data model validation |
| tasks.md | {Found/Not Found} | Task format validation |

Starting validation...
```

### Step 2: Validate Specification (spec.md)

**2.1: Read and parse spec.md**

Parse the specification document to extract:
- User Scenarios (US-###)
- Functional Requirements (FR-###)
- Success Criteria (SC-###)
- Edge Cases
- Key Entities
- Assumptions
- Open Questions

**2.2: Run mandatory section checks**

```markdown
### Specification Validation

#### Section Completeness

| Section | Minimum Required | Found | Status |
|---------|------------------|-------|--------|
| User Scenarios | >= 2 | {count} | {PASS/FAIL} |
| Functional Requirements | >= 1 | {count} | {PASS/FAIL} |
| Success Criteria | >= 1 | {count} | {PASS/FAIL} |
| Edge Cases | >= 1 | {count} | {PASS/FAIL} |
| Key Entities | >= 0 | {count} | {PASS/INFO} |
| Assumptions | >= 0 | {count} | {PASS/INFO} |
```

**2.3: Check for implementation details**

Scan for prohibited implementation-specific content:

| Category | Examples | Detection |
|----------|----------|-----------|
| Languages | Python, JavaScript, TypeScript, etc. | Word match |
| Frameworks | React, Django, Express, etc. | Word match |
| Databases | PostgreSQL, MongoDB, Redis, etc. | Word match |
| Infrastructure | Docker, AWS, Kubernetes, etc. | Word match |

```markdown
#### Implementation Independence

| Category | Violations Found | Details |
|----------|------------------|---------|
| Programming Languages | {count} | {list or "None"} |
| Frameworks | {count} | {list or "None"} |
| Databases | {count} | {list or "None"} |
| Infrastructure | {count} | {list or "None"} |

**Status:** {PASS/FAIL}

{If violations:}
**Violations Found:**
{For each violation:}
- Line {N}: "{violating text}" in section {section}
  Suggestion: {rephrasing suggestion}
{End for}
{End if}
```

**2.4: Validate requirement format**

For each FR-### requirement:
- Check ID format matches `FR-\d{3}`
- Verify requirement is testable (no vague terms)
- Check verification method is specified

Vague terms to flag:
- "easy to use", "user-friendly", "intuitive"
- "fast", "quick", "responsive" (without metric)
- "robust", "reliable", "stable" (without criteria)
- "as needed", "when appropriate", "sometimes"

```markdown
#### Requirement Quality

| Requirement | ID Format | Testable | Verification Method | Status |
|-------------|-----------|----------|---------------------|--------|
{For each FR-###:}
| {FR-ID} | {OK/INVALID} | {Yes/No} | {Yes/No} | {PASS/FAIL} |
{End for}

{If issues found:}
**Issues Found:**
{For each issue:}
- {FR-ID}: {Issue description}
  - Current: "{current text}"
  - Suggestion: {suggestion}
{End for}
{End if}
```

**2.5: Validate success criteria format**

For each SC-### criterion:
- Check ID format matches `SC-\d{3}`
- Verify measurable target exists (number, percentage, duration)
- Check verification method is specified

```markdown
#### Success Criteria Quality

| Criterion | ID Format | Measurable | Verification Method | Status |
|-----------|-----------|------------|---------------------|--------|
{For each SC-###:}
| {SC-ID} | {OK/INVALID} | {Yes/No} | {Yes/No} | {PASS/FAIL} |
{End for}

{If issues found:}
**Issues Found:**
{For each issue:}
- {SC-ID}: Missing measurable target
  - Current: "{current text}"
  - Example fix: "Response time < 2 seconds (P95)"
{End for}
{End if}
```

**2.6: Check clarification markers**

Count `[NEEDS CLARIFICATION]` markers:

```markdown
#### Clarification Status

| Metric | Count | Limit | Status |
|--------|-------|-------|--------|
| [NEEDS CLARIFICATION] markers | {count} | 3 | {PASS/FAIL} |
| Open Questions (Q-###) | {count} | - | {INFO} |

{If count > 0:}
**Open Clarifications:**
{For each marker:}
- {Section}: {marker description}
{End for}

Run `/projspec.clarify` to resolve open questions.
{End if}
```

### Step 3: Validate Plan (plan.md)

**3.1: Read and parse plan.md**

Parse the plan document to extract:
- Technical Context section
- Constitution Check section
- Project Structure section
- Dependencies and constraints

**3.2: Validate Technical Context completeness**

```markdown
### Plan Validation

#### Technical Context

| Field | Required | Present | Value | Status |
|-------|----------|---------|-------|--------|
| Primary Language | Yes | {Yes/No} | {value} | {PASS/FAIL} |
| Runtime/Version | Yes | {Yes/No} | {value} | {PASS/FAIL} |
| Package Manager | No | {Yes/No} | {value} | {PASS/INFO} |
| Target Platform | Yes | {Yes/No} | {value} | {PASS/FAIL} |
| Test Framework | No | {Yes/No} | {value} | {PASS/INFO} |

**Dependencies:** {count} documented
**Constraints:** {count} documented
```

**3.3: Validate Constitution Check**

```markdown
#### Constitution Compliance

{If Constitution Check section exists:}
| Principle | Status | Notes |
|-----------|--------|-------|
{For each principle checked:}
| {P-ID}: {Name} | {PASS/PARTIAL/VIOLATION} | {Notes} |
{End for}

**Overall Compliance:** {PASS/PARTIAL/VIOLATION}

{If any VIOLATION:}
**Violations Requiring Attention:**
{For each violation:}
- {P-ID}: {Description}
  - Justification: {justification or "MISSING"}
  - Mitigation: {mitigation or "MISSING"}
  - Governance: {approval status or "REQUIRED"}
{End for}
{End if}

{Else:}
**Warning:** Constitution Check section not found in plan.md
Run `/projspec.plan` to generate constitution compliance check.
{End if}
```

**3.4: Validate Project Structure**

```markdown
#### Project Structure

| Check | Status |
|-------|--------|
| Directory structure defined | {PASS/FAIL} |
| File-to-requirement mapping exists | {PASS/FAIL} |
| All FR-### mapped to files | {PASS/FAIL/PARTIAL} |

{If unmapped requirements:}
**Unmapped Requirements:**
{For each unmapped FR-###:}
- {FR-ID}: {Description} - No file mapping found
{End for}
{End if}
```

### Step 4: Validate Research (research.md)

**4.1: Read and parse research.md**

Parse the research document to extract:
- Technical Unknowns
- Decisions made
- Sources and references

**4.2: Validate research quality**

```markdown
### Research Validation

#### Research Completeness

| Check | Count | Status |
|-------|-------|--------|
| Technical unknowns identified | {count} | {PASS/WARN} |
| Decisions documented | {count} | {PASS/WARN} |
| Sources provided | {count} | {PASS/WARN} |

#### Decision Quality

{For each decision:}
| Decision | Options Listed | Rationale | Trade-offs | Status |
|----------|----------------|-----------|------------|--------|
| {Decision title} | {Yes/No} | {Yes/No} | {Yes/No} | {PASS/FAIL} |
{End for}

{If issues found:}
**Recommendations:**
{For each issue:}
- {Decision}: {Missing element} needed for completeness
{End for}
{End if}
```

### Step 5: Validate Data Model (data-model.md)

**5.1: Read and parse data-model.md**

Parse the data model document to extract:
- Entity definitions
- Attributes and types
- Relationships
- Validation rules

**5.2: Validate entity completeness**

```markdown
### Data Model Validation

#### Entity Definitions

| Entity | Attributes | Types Defined | Validation Rules | Status |
|--------|------------|---------------|------------------|--------|
{For each entity:}
| {EntityName} | {attr_count} | {all_typed} | {has_rules} | {PASS/FAIL} |
{End for}

#### Relationship Integrity

| From | To | Type | Status |
|------|-----|------|--------|
{For each relationship:}
| {Entity1} | {Entity2} | {1:1/1:n/n:m} | {PASS/INVALID} |
{End for}

{If issues:}
**Issues Found:**
{For each issue:}
- {EntityName}: {Issue description}
{End for}
{End if}
```

### Step 6: Validate Tasks (tasks.md)

**6.1: Read and parse tasks.md**

Parse the tasks file to extract:
- Task IDs and descriptions
- Phase organization
- Dependencies
- Status markers

**6.2: Validate task format**

```markdown
### Task Validation

#### Task Format

| Check | Count | Status |
|-------|-------|--------|
| Total Tasks | {count} | INFO |
| Valid Task IDs (T###) | {valid_count} | {PASS/FAIL} |
| Invalid Task IDs | {invalid_count} | {PASS/FAIL} |
| Duplicate Task IDs | {dup_count} | {PASS/FAIL} |

{If format issues:}
**Format Issues:**
{For each issue:}
- Line {N}: {Issue description}
{End for}
{End if}
```

**6.3: Validate dependencies**

```markdown
#### Dependency Validation

| Check | Count | Status |
|-------|-------|--------|
| Total Dependencies | {count} | INFO |
| Valid References | {valid_count} | {PASS/FAIL} |
| Invalid References | {invalid_count} | {PASS/FAIL} |
| Circular Dependencies | {circular_count} | {PASS/FAIL} |

{If circular dependencies found:}
**Circular Dependencies Detected:**
{For each cycle:}
- Cycle: {T001} -> {T002} -> {T003} -> {T001}
{End for}

These must be resolved before implementation can proceed.
{End if}

{If invalid references:}
**Invalid References:**
{For each invalid:}
- {Task ID} references non-existent task {invalid_ref}
{End for}
{End if}
```

**6.4: Validate phase structure**

```markdown
#### Phase Organization

| Phase | Task Count | Status |
|-------|------------|--------|
{For each phase:}
| Phase {N}: {Name} | {count} | {PASS} |
{End for}

**Phase Dependency Flow:**
- Phase 1 (Setup) -> Phase 2 (Foundational) -> Phase 3+ (User Stories)
- Status: {VALID/INVALID}
```

### Step 7: Generate Validation Report

**7.1: Compile all validation results**

```markdown
## Validation Report

**Feature:** {FEATURE_NAME}
**Directory:** {FEATURE_DIR}
**Timestamp:** {YYYY-MM-DD HH:MM:SS}

### Summary

| Artifact | Checks Passed | Checks Failed | Warnings | Overall |
|----------|---------------|---------------|----------|---------|
| spec.md | {count} | {count} | {count} | {PASS/FAIL/WARN} |
| plan.md | {count} | {count} | {count} | {PASS/FAIL/WARN} |
| research.md | {count} | {count} | {count} | {PASS/FAIL/WARN} |
| data-model.md | {count} | {count} | {count} | {PASS/FAIL/WARN} |
| tasks.md | {count} | {count} | {count} | {PASS/FAIL/WARN} |
| **Total** | {total} | {total} | {total} | {OVERALL} |

### Overall Status: {PASS / FAIL / NEEDS ATTENTION}

{If overall PASS:}
All validation checks passed. The feature artifacts are ready for the next step.

{Else if overall FAIL:}
Validation failed. Please address the following issues:

**Critical Issues (Must Fix):**
{For each critical issue:}
1. [{Artifact}] {Issue description}
   - Location: {section/line}
   - Fix: {suggestion}
{End for}

**Warnings (Should Review):**
{For each warning:}
1. [{Artifact}] {Warning description}
   - Recommendation: {suggestion}
{End for}
{End if}
```

**7.2: Provide next steps based on validation results**

```markdown
### Next Steps

{If all pass:}
Validation complete. Recommended next actions:

{If validating spec:}
- Run `/projspec.plan` to generate implementation plan
{End if}

{If validating plan:}
- Run `/projspec.tasks` to generate task list
{End if}

{If validating tasks:}
- Run `/projspec.implement` to start implementation
{End if}

{Else:}
Address the issues above, then re-run:
```
/projspec.validate {$ARGUMENTS}
```

For specific artifact validation:
```
/projspec.validate spec    # Validate specification only
/projspec.validate plan    # Validate plan only
/projspec.validate tasks   # Validate tasks only
```
{End if}
```

## Output

Upon completion, this command produces:

### Console Output

| Output | When Displayed |
|--------|----------------|
| Validation scope | At command start |
| Per-artifact results | During validation |
| Summary report | On completion |
| Next steps guidance | After summary |

### Exit Status

| Status | Meaning |
|--------|---------|
| PASS | All validation checks passed |
| FAIL | Critical issues found that must be fixed |
| WARN | No critical issues but warnings exist |
| SKIP | No artifacts available to validate |

## Usage

```
/projspec.validate [artifact]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `spec` | Validate specification only |
| `plan` | Validate plan and related artifacts |
| `tasks` | Validate task list only |
| `all` | Validate all available artifacts |
| (empty) | Auto-detect and validate all |

### Examples

```bash
# Validate all available artifacts
/projspec.validate

# Validate only the specification
/projspec.validate spec

# Validate plan and related documents
/projspec.validate plan

# Validate task format and dependencies
/projspec.validate tasks
```

## Notes

- This command is read-only and does not modify any files
- Validation checks are based on the templates and constitution
- Some checks produce warnings rather than failures
- Run this command before proceeding to the next workflow step
- Use `/projspec.analyze` for cross-artifact consistency analysis

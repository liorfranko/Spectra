# Command: analyze

## Purpose

Perform a non-destructive cross-artifact consistency and quality analysis across all design artifacts (spec.md, plan.md, tasks.md, data-model.md, and contracts/). This command identifies gaps, misalignments, and quality issues without modifying any files.

The analysis process:
1. Reads all available design artifacts for the current feature
2. Checks for completeness (all requirements covered by tasks)
3. Verifies consistency (plan matches spec, tasks implement plan)
4. Validates traceability (every requirement has a path to implementation)
5. Identifies gaps, misalignments, and potential issues
6. Generates a comprehensive analysis report with findings and recommendations
7. Suggests fixes without implementing them

---

## Prerequisites

Before running this command, verify the following:

1. **Existing spec.md**: At minimum, the feature must have a spec.md file
2. **Feature directory exists**: The feature's specification directory must exist (e.g., `specs/{ID}-{feature-slug}/` or `.specify/features/{ID}-{feature-slug}/`)
3. **Working in feature context**: You should be in the feature's worktree or have the feature context loaded

If prerequisites are not met, inform the user:
- If no spec.md exists, suggest running the `specify` command first
- If no plan.md or tasks.md exists, note their absence but proceed with available artifacts
- Report which artifacts are available for analysis

---

## Workflow

Follow these steps in order:

### Step 1: Locate and Read All Available Artifacts

Find and read all design documents for the current feature:

1. **Feature Specification (spec.md)**: Required
   - Check the current directory for spec.md
   - Check `specs/{feature-slug}/spec.md`
   - Check `.specify/features/{feature-slug}/spec.md`

2. **Implementation Plan (plan.md)**: Optional but important
   - Technical approach and architecture
   - File structure and project organization
   - Implementation phases

3. **Task Breakdown (tasks.md)**: Optional but important
   - Task definitions with dependencies
   - Status tracking
   - Effort estimates

4. **Data Model (data-model.md)**: Optional
   - Entity definitions and relationships
   - State transitions
   - Validation rules

5. **API Contracts (contracts/)**: Optional
   - API specifications (OpenAPI, GraphQL)
   - Interface definitions
   - Schema definitions

6. **Research Document (research.md)**: Optional
   - Technology decisions
   - Alternative considerations
   - Decision rationale

7. **Quickstart Document (quickstart.md)**: Optional
   - Validation scenarios
   - Test cases

8. **Constitution (.specify/memory/constitution.md)**: Optional
   - Core principles for compliance checking

Document which artifacts are present and which are missing before proceeding.

### Step 2: Perform Completeness Analysis

Check that all artifacts are fully populated and contain required sections.

#### Spec.md Completeness

Verify the specification contains:
- [ ] Overview section with clear problem statement
- [ ] User stories with priorities (P1, P2, P3)
- [ ] Acceptance criteria for each user story (Given/When/Then)
- [ ] Functional requirements (FR-XXX)
- [ ] Non-functional requirements (NFR-XXX)
- [ ] Success criteria
- [ ] Scope boundaries (in scope / out of scope)

**Issues to identify:**
- User stories without acceptance criteria
- Requirements without clear success criteria
- Missing priority assignments
- Vague or unmeasurable requirements

#### Plan.md Completeness

Verify the plan contains (if plan.md exists):
- [ ] Summary of implementation approach
- [ ] Technical context and codebase analysis
- [ ] Constitution compliance check
- [ ] Project structure (files to create/modify)
- [ ] Risk assessment
- [ ] Implementation phases
- [ ] Testing strategy
- [ ] Rollback plan

**Issues to identify:**
- Phases without clear goals
- Missing risk mitigation strategies
- Incomplete file structure
- Testing strategy gaps

#### Tasks.md Completeness

Verify the task breakdown contains (if tasks.md exists):
- [ ] Progress summary table
- [ ] All tasks have unique IDs (T001, T002, etc.)
- [ ] All tasks have status, priority, and effort
- [ ] All tasks have acceptance criteria
- [ ] All tasks have dependencies defined
- [ ] Parallel tasks marked with [P] flag

**Issues to identify:**
- Tasks without acceptance criteria
- Missing effort estimates
- Undefined dependencies
- Orphan tasks (no phase assignment)

### Step 3: Perform Consistency Analysis

Check that artifacts are aligned and don't contradict each other.

#### Spec-to-Plan Consistency

For each user story in spec.md:
- [ ] Implementation approach is defined in plan.md
- [ ] Technical decisions align with requirements
- [ ] File structure supports required functionality

For each requirement in spec.md:
- [ ] Plan addresses how it will be implemented
- [ ] Non-functional requirements have technical solutions

**Issues to identify:**
- User stories not addressed in plan
- Requirements with no implementation approach
- Plan assumptions that contradict spec
- Technology choices that don't support requirements

#### Plan-to-Tasks Consistency

For each implementation phase in plan.md:
- [ ] Corresponding tasks exist in tasks.md
- [ ] Task order matches phase order

For each file in plan.md project structure:
- [ ] Task exists to create/modify the file
- [ ] File purpose matches task description

**Issues to identify:**
- Phases without corresponding tasks
- Files in plan with no task to create them
- Tasks that don't align with plan phases
- Effort estimates inconsistent with plan complexity

#### Tasks-to-Spec Consistency

For each task in tasks.md:
- [ ] Links to user story ([US{N}] tag) or requirement
- [ ] Acceptance criteria align with spec requirements

For each user story in spec.md:
- [ ] At least one task addresses it
- [ ] All acceptance criteria covered by task criteria

**Issues to identify:**
- Tasks without spec traceability
- User stories without implementing tasks
- Orphan tasks (not linked to requirements)
- Acceptance criteria gaps

#### Data Model Consistency

If data-model.md exists:
- [ ] Entities match those mentioned in spec
- [ ] Relationships support user stories
- [ ] State transitions match workflow requirements

**Issues to identify:**
- Entities mentioned in spec but not in data model
- Relationships that don't support required operations
- Missing state transitions for user workflows

#### Contract Consistency

If contracts/ exists:
- [ ] API endpoints match user stories
- [ ] Request/response schemas match data model
- [ ] Error responses cover failure scenarios

**Issues to identify:**
- User actions without API endpoints
- Schema mismatches with data model
- Missing error handling in contracts

### Step 4: Perform Traceability Analysis

Verify every requirement has a complete path from definition to implementation.

#### Forward Traceability (Spec -> Tasks)

For each requirement (FR-XXX, NFR-XXX):
1. Find corresponding section in plan.md
2. Find corresponding tasks in tasks.md
3. Verify coverage is complete

Create a traceability matrix:

```markdown
| Requirement | Plan Section | Task(s) | Coverage |
|-------------|--------------|---------|----------|
| FR-001 | Phase 2.1 | T015, T016 | Complete |
| FR-002 | Phase 2.2 | T017 | Partial |
| NFR-001 | Phase 3 | - | Missing |
```

#### Backward Traceability (Tasks -> Spec)

For each task:
1. Identify the user story or requirement it addresses
2. Verify the link is correct and complete

**Issues to identify:**
- Requirements with no tasks (coverage gaps)
- Requirements with partial coverage
- Tasks with no requirement linkage
- Broken traceability links

#### User Story Traceability

For each user story (US{N}):
1. List all tasks tagged with [US{N}]
2. Map acceptance criteria to task acceptance criteria
3. Verify all acceptance criteria are covered

### Step 5: Perform Quality Analysis

Assess the quality of each artifact.

#### Specification Quality

Evaluate:
- **Clarity**: Are requirements unambiguous?
- **Testability**: Can acceptance criteria be verified?
- **Completeness**: Are there obvious gaps?
- **Consistency**: Do requirements conflict?
- **Feasibility**: Are requirements implementable?

Quality indicators:
- [ ] No vague terms (e.g., "should be fast", "user-friendly")
- [ ] All acceptance criteria are testable
- [ ] No contradictory requirements
- [ ] Clear scope boundaries

#### Plan Quality

Evaluate:
- **Alignment**: Does plan follow spec requirements?
- **Architecture**: Are design decisions sound?
- **Risk Management**: Are risks identified and mitigated?
- **Feasibility**: Is the approach realistic?

Quality indicators:
- [ ] Clear technical approach for each requirement
- [ ] Identified and addressed risks
- [ ] Reasonable implementation phases
- [ ] Testable milestones

#### Task Quality

Evaluate:
- **Granularity**: Are tasks appropriately sized?
- **Dependencies**: Are dependencies correctly identified?
- **Estimates**: Are effort estimates reasonable?
- **Parallelization**: Are parallel opportunities identified?

Quality indicators:
- [ ] Tasks estimated at M or smaller (L/XL should be split)
- [ ] No circular dependencies
- [ ] Clear acceptance criteria per task
- [ ] Appropriate parallel marking

#### Constitution Compliance

If constitution.md exists:
- [ ] Review plan's constitution check table
- [ ] Verify each principle has alignment status
- [ ] Check for unaddressed violations
- [ ] Verify exceptions are documented

### Step 6: Identify Gaps and Misalignments

Compile all issues discovered during analysis into categorized findings.

#### Gap Categories

1. **Coverage Gaps**: Requirements not implemented
2. **Documentation Gaps**: Missing sections or artifacts
3. **Traceability Gaps**: Broken links between artifacts

#### Misalignment Categories

1. **Specification Misalignments**: Conflicts within spec
2. **Plan Misalignments**: Plan doesn't match spec
3. **Task Misalignments**: Tasks don't implement plan
4. **Contract Misalignments**: API doesn't match spec

#### Quality Issues

1. **Clarity Issues**: Vague or ambiguous content
2. **Completeness Issues**: Missing required elements
3. **Testability Issues**: Unverifiable criteria
4. **Sizing Issues**: Tasks too large or small

### Step 7: Generate Analysis Report

Create a comprehensive report summarizing all findings.

#### Report Structure

```markdown
# Artifact Analysis Report

**Feature**: {Feature Name}
**Date**: {Date}
**Artifacts Analyzed**: {List of artifacts found}

## Executive Summary

{2-3 sentence summary of analysis results}

- Total Issues Found: {N}
- Critical Issues: {N}
- Warnings: {N}
- Suggestions: {N}

## Artifacts Status

| Artifact | Present | Completeness | Quality |
|----------|---------|--------------|---------|
| spec.md | Yes | 85% | Good |
| plan.md | Yes | 90% | Good |
| tasks.md | Yes | 75% | Needs Work |
| data-model.md | No | - | - |
| contracts/ | No | - | - |

## Completeness Analysis

### Spec.md
{Completeness findings}

### Plan.md
{Completeness findings}

### Tasks.md
{Completeness findings}

## Consistency Analysis

### Spec-to-Plan Alignment
{Consistency findings}

### Plan-to-Tasks Alignment
{Consistency findings}

### Cross-Artifact Conflicts
{Any conflicts found}

## Traceability Matrix

| Requirement | User Story | Plan Phase | Task(s) | Status |
|-------------|------------|------------|---------|--------|
| FR-001 | US1 | Phase 2.1 | T015 | OK |
| FR-002 | US1 | Phase 2.2 | - | MISSING |
| NFR-001 | - | Phase 3 | T025 | OK |

### Coverage Summary
- Requirements with full coverage: {N} of {M}
- Requirements with partial coverage: {N}
- Requirements with no coverage: {N}

## Quality Assessment

### Overall Quality Score: {X}/10

| Category | Score | Notes |
|----------|-------|-------|
| Clarity | {X}/10 | {Notes} |
| Completeness | {X}/10 | {Notes} |
| Consistency | {X}/10 | {Notes} |
| Traceability | {X}/10 | {Notes} |

## Issues Found

### Critical Issues (Must Fix)

| ID | Category | Location | Description | Suggested Fix |
|----|----------|----------|-------------|---------------|
| C1 | Coverage | FR-002 | No task implements this requirement | Add task for FR-002 |
| C2 | Consistency | plan.md | Phase 3 contradicts NFR-001 | Revise phase 3 |

### Warnings (Should Fix)

| ID | Category | Location | Description | Suggested Fix |
|----|----------|----------|-------------|---------------|
| W1 | Quality | T008 | Task is XL, consider splitting | Split into 2-3 tasks |
| W2 | Traceability | T012 | Missing user story link | Add [US{N}] tag |

### Suggestions (Nice to Have)

| ID | Category | Location | Description | Suggested Fix |
|----|----------|----------|-------------|---------------|
| S1 | Quality | US3 | Acceptance criteria could be clearer | Add specific values |
| S2 | Documentation | - | Consider adding data-model.md | Run plan command |

## Recommendations

### Immediate Actions
1. {Most critical fix needed}
2. {Second critical fix}
3. {Third critical fix}

### Before Implementation
1. {Fixes needed before starting implementation}
2. {Artifacts to complete}

### Optional Improvements
1. {Nice-to-have improvements}
2. {Quality enhancements}

## Next Steps

Based on this analysis:
- [ ] Fix {N} critical issues before proceeding
- [ ] Address {N} warnings for better quality
- [ ] Consider {N} suggestions for improvements
- [ ] Re-run analysis after fixes to verify

---

*Analysis performed by Claude. No files were modified during this analysis.*
```

### Step 8: Present Findings

After generating the report:

1. **Summarize key findings**:
```
## Analysis Complete

### Results:
- Artifacts Analyzed: spec.md, plan.md, tasks.md
- Overall Quality Score: 7.5/10
- Critical Issues: 2
- Warnings: 5
- Suggestions: 3

### Critical Issues Requiring Attention:
1. FR-002 (Password Reset) has no implementing task
2. Phase 3 in plan.md contradicts NFR-001 (response time)

### Recommended Next Steps:
1. Add task for FR-002 in tasks.md
2. Revise Phase 3 to meet NFR-001 requirements
3. Re-run /analyze after fixes

The full report has been displayed above.
```

2. **Highlight actionable items**:
   - List specific changes needed
   - Reference exact locations (file, section, line if applicable)
   - Provide concrete suggestions

3. **Offer next steps**:
   - Fix critical issues
   - Re-run analysis after fixes
   - Proceed to next phase if no critical issues

---

## Output

Upon successful completion, the following will be produced:

### Analysis Report

The analysis produces a read-only report containing:
- Executive summary of artifact status
- Completeness analysis for each artifact
- Consistency analysis across artifacts
- Traceability matrix (requirements to tasks)
- Quality assessment with scores
- Categorized issues (Critical, Warning, Suggestion)
- Specific recommendations with locations
- Next steps based on findings

### No Files Modified

**Important**: This command does NOT modify any files. It only reads and analyzes existing artifacts. All findings and recommendations are presented in the output.

### Artifacts Analyzed

| Artifact | Purpose in Analysis |
|----------|---------------------|
| spec.md | Source of requirements and acceptance criteria |
| plan.md | Technical approach and file structure |
| tasks.md | Implementation breakdown and dependencies |
| data-model.md | Entity definitions for consistency checks |
| contracts/ | API specifications for interface validation |
| research.md | Technology decisions for context |
| quickstart.md | Validation scenarios for completeness |
| constitution.md | Principle compliance verification |

---

## Examples

### Example 1: Complete Feature Analysis

**Scenario**: All artifacts exist and are complete.

**Analysis Results**:
```
## Analysis Complete

### Results:
- Artifacts Analyzed: spec.md, plan.md, tasks.md, data-model.md, contracts/
- Overall Quality Score: 9/10
- Critical Issues: 0
- Warnings: 2
- Suggestions: 4

### Warnings:
1. T015 is estimated as XL - consider splitting
2. US3 acceptance criteria #2 is vague ("should be responsive")

### Recommendations:
- Split T015 into T015a and T015b
- Update US3 acceptance criteria with specific response time

### Verdict: Ready for implementation with minor improvements
```

### Example 2: Missing Artifacts

**Scenario**: Only spec.md exists.

**Analysis Results**:
```
## Analysis Complete

### Results:
- Artifacts Analyzed: spec.md only
- Missing Artifacts: plan.md, tasks.md, data-model.md, contracts/
- Limited analysis performed

### Spec.md Analysis:
- Completeness: 80%
- Quality Score: 7/10
- Issues Found: 3

### Critical Issues:
1. US2 has no acceptance criteria
2. NFR-002 is not measurable ("should be secure")

### Recommendations:
1. Add acceptance criteria to US2
2. Define specific security requirements for NFR-002
3. Run /plan to generate plan.md
4. Run /tasks to generate tasks.md
```

### Example 3: Consistency Issues Detected

**Scenario**: Plan and tasks exist but have misalignments.

**Analysis Results**:
```
## Analysis Complete

### Results:
- Artifacts Analyzed: spec.md, plan.md, tasks.md
- Overall Quality Score: 6/10
- Critical Issues: 3
- Warnings: 4

### Critical Consistency Issues:

1. **Spec-Plan Mismatch**:
   - NFR-001 requires <100ms response time
   - Plan Phase 2 uses synchronous processing
   - Suggested Fix: Update plan to use async processing

2. **Plan-Tasks Gap**:
   - plan.md lists `src/middleware/auth.py`
   - No task creates this file
   - Suggested Fix: Add task in Phase 1 for auth middleware

3. **Traceability Break**:
   - US3 (Password Reset) has 3 acceptance criteria
   - Only 1 is covered by T018
   - Suggested Fix: Add tasks for remaining acceptance criteria

### Traceability Matrix Issues:
| Requirement | Expected Tasks | Actual Tasks | Gap |
|-------------|----------------|--------------|-----|
| FR-003 | 2 | 1 | -1 |
| US3 AC-2 | 1 | 0 | -1 |
| US3 AC-3 | 1 | 0 | -1 |
```

### Example 4: Quality Issues Focus

**Scenario**: Artifacts are complete but have quality issues.

**Analysis Results**:
```
## Analysis Complete

### Quality Assessment:

| Category | Score | Details |
|----------|-------|---------|
| Clarity | 6/10 | 4 vague requirements found |
| Completeness | 9/10 | All sections present |
| Consistency | 8/10 | Minor misalignments |
| Traceability | 7/10 | 2 orphan tasks |

### Clarity Issues:
1. FR-005: "System should handle errors gracefully"
   - Too vague: What errors? What is "gracefully"?
   - Suggested: "System should display user-friendly error messages
     and log detailed errors to console"

2. NFR-003: "Should be performant"
   - Not measurable
   - Suggested: "Response time < 200ms for 95th percentile"

### Task Sizing Issues:
- T025: Estimated XL (1-2 days)
  - Violates atomic task principle
  - Suggested: Split into T025a, T025b, T025c

### Orphan Tasks:
- T030: Not linked to any user story or requirement
- T031: Not linked to any user story or requirement
  - Review if these are needed or add [US{N}] tags
```

---

## Error Handling

### Common Issues

1. **No spec.md found**: Cannot proceed without specification
   - Guide user to run `specify` command first

2. **All artifacts missing except spec**: Limited analysis possible
   - Perform spec.md analysis only
   - Recommend creating other artifacts

3. **Corrupted or malformed artifacts**: Cannot parse content
   - Report which artifact has issues
   - Suggest manual review or recreation

4. **Circular dependency in tasks**: Detected during consistency check
   - Report the cycle (T001 -> T005 -> T001)
   - Suggest resolution

### Recovery Steps

If the analysis fails partway through:
1. Report which analyses were completed
2. Present partial findings
3. Indicate where the failure occurred
4. Suggest fixes for blocking issues

### Incomplete Analysis

If some checks cannot be performed:
1. Document what was skipped and why
2. Mark those sections as "Not Analyzed"
3. Proceed with available data
4. Note limitations in the report

---

## Notes

- **Non-destructive**: This command NEVER modifies any files. It only reads and reports.
- **Comprehensive**: Analyze all available artifacts, not just the minimum.
- **Actionable**: Every issue should have a suggested fix with specific location.
- **Prioritized**: Categorize issues as Critical, Warning, or Suggestion to guide effort.
- **Traceable**: The traceability matrix is key for ensuring complete coverage.
- **Re-runnable**: Users should run this after making fixes to verify improvements.
- **Early and often**: Running analyze before implementation catches issues early.
- **Quality scores**: Scores provide quick assessment but details matter more.
- **Constitution check**: Include constitution compliance in the analysis if available.
- **No judgment**: Report findings objectively without editorial comments.

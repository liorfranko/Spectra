## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Goal: Perform a comprehensive validation of the current feature specification and all related artifacts, cross-checking for consistency, completeness, and alignment with the project constitution. This is especially useful after making changes to research or other artifacts to ensure no leftover inconsistencies remain.

## Execution Steps

1. **Identify Feature Context**

   Run `.specify.specify/scripts/bash/check-prerequisites.sh --json --paths-only` to get:
   - `FEATURE_DIR`
   - `FEATURE_SPEC`
   - `IMPL_PLAN`
   - `TASKS`

   If no feature branch is active, prompt user to specify which feature to validate (e.g., "001-feature-name").

2. **Load All Artifacts**

   Read the following files (skip if not present, note as "not yet created"):
   - `FEATURE_SPEC` (spec.md) - **Required**
   - `IMPL_PLAN` (plan.md)
   - `FEATURE_DIR/research.md`
   - `FEATURE_DIR/data-model.md`
   - `FEATURE_DIR/quickstart.md`
   - `FEATURE_DIR/contracts/*.md`
   - `FEATURE_DIR/checklists/*.md`
   - `.specify.specify/memory/constitution.md`

3. **Validation Categories**

   Perform validation in these categories, producing a pass/fail/warning status for each:

   ### A. Specification Completeness

   - [ ] All mandatory sections present (User Scenarios, Requirements, Success Criteria)
   - [ ] No placeholder text remaining (e.g., "[FEATURE NAME]", "[TODO]")
   - [ ] No unresolved [NEEDS CLARIFICATION] markers
   - [ ] All user stories have acceptance scenarios
   - [ ] All functional requirements have MUST/SHOULD language
   - [ ] Success criteria are measurable with specific numbers/percentages
   - [ ] Edge cases section has concrete resolutions (not just questions)

   ### B. Constitution Alignment

   - [ ] All constitution principles addressed in plan's Constitution Check
   - [ ] No principle violations without documented justification
   - [ ] Quality gates from constitution reflected in requirements or plan

   ### C. Cross-Artifact Consistency

   **Spec <-> Plan**:
   - [ ] All user stories from spec appear in plan's scope
   - [ ] Technical Context in plan addresses all spec requirements
   - [ ] Project structure supports all functional requirements

   **Spec <-> Data Model**:
   - [ ] All Key Entities from spec defined in data-model.md
   - [ ] Entity attributes cover all referenced data in requirements
   - [ ] Relationships in data model match spec's relationship types

   **Spec <-> Contracts**:
   - [ ] All user stories have corresponding CLI commands or API endpoints
   - [ ] Functional requirements map to specific contract operations
   - [ ] Output formats (JSON, human-readable) defined per constitution

   **Spec <-> Quickstart**:
   - [ ] Quickstart covers all P1 user stories
   - [ ] Commands in quickstart match contract definitions
   - [ ] No features in quickstart that aren't in spec

   **Research <-> Plan**:
   - [ ] Technologies mentioned in research are reflected in plan
   - [ ] No outdated research conclusions contradicting current plan decisions
   - [ ] Research findings are incorporated or explicitly superseded

   ### D. Terminology Consistency

   - [ ] Same entity names used across all artifacts
   - [ ] No synonyms that could cause confusion (e.g., "repo" vs "repository")
   - [ ] Technical terms consistent with constitution glossary (if present)

   ### E. Testability Check

   - [ ] Each functional requirement can be verified with a specific test
   - [ ] Success criteria have clear pass/fail conditions
   - [ ] Acceptance scenarios follow Given/When/Then format correctly

   ### F. Clarity & Ambiguity Scan

   - [ ] No vague adjectives without quantification ("fast", "robust", "intuitive")
   - [ ] No assumptions that should be explicit
   - [ ] No requirements that contradict each other

   ### G. Leftover Detection

   - [ ] No orphaned references to removed features
   - [ ] No stale TODOs or FIXMEs in artifacts
   - [ ] No commented-out sections that should be deleted or restored
   - [ ] No references to renamed entities using old names

4. **Generate Validation Report**

   Create a structured report with:

   ```markdown
   # Validation Report: [FEATURE NAME]

   **Feature**: [branch name]
   **Validated**: [timestamp]
   **Artifacts Checked**: [list]

   ## Summary

   | Category | Status | Issues |
   |----------|--------|--------|
   | Specification Completeness | pass/warning/fail | N |
   | Constitution Alignment | pass/warning/fail | N |
   | Cross-Artifact Consistency | pass/warning/fail | N |
   | Terminology Consistency | pass/warning/fail | N |
   | Testability | pass/warning/fail | N |
   | Clarity & Ambiguity | pass/warning/fail | N |
   | Leftover Detection | pass/warning/fail | N |

   **Overall Status**: PASS / PASS WITH WARNINGS / FAIL

   ## Detailed Findings

   ### Critical Issues (must fix)
   - [List of blocking issues]

   ### Warnings (should fix)
   - [List of non-blocking concerns]

   ### Recommendations (nice to have)
   - [List of improvement suggestions]

   ## Cross-Reference Matrix

   | Requirement | Plan | Data Model | Contract | Quickstart |
   |-------------|------|------------|----------|------------|
   | FR-001      | yes  | yes        | yes      | yes        |
   | FR-002      | yes  | partial    | yes      | -          |
   ...

   ## Next Steps

   [Based on findings, recommend specific actions]
   ```

5. **Save Report**

   Write the validation report to `FEATURE_DIR/checklists/validation-report.md`.

6. **Interactive Fix Mode** (if issues found)

   If critical issues are found, offer to help fix them:
   - For missing content: Suggest specific additions
   - For inconsistencies: Show the conflicting values and ask which is correct
   - For ambiguities: Ask clarifying questions
   - For leftovers: Suggest deletions or updates

   User can respond:
   - "fix all" - Apply all suggested fixes automatically
   - "fix [issue number]" - Fix specific issue
   - "skip" - Just report, don't fix
   - "done" - Finish validation

## Validation Rules

### Status Definitions

- **PASS**: All checks in category pass
- **WARNING**: Minor issues that don't block implementation
- **FAIL**: Critical issues that must be resolved before proceeding

### Overall Status

- **PASS**: All categories pass
- **PASS WITH WARNINGS**: No failures, some warnings
- **FAIL**: Any category fails

### Auto-Fail Conditions

These conditions automatically fail validation:

1. Spec file missing or unreadable
2. Any [NEEDS CLARIFICATION] markers remain
3. Missing mandatory sections (User Scenarios, Requirements, Success Criteria)
4. Functional requirements without testable criteria
5. Constitution violations without documented justification

## Behavior Rules

- If user provides a specific feature number (e.g., "001"), validate that feature
- If on a feature branch, validate current feature
- If on main with no arguments, list available features and ask which to validate
- Always read constitution for cross-reference
- Don't modify artifacts unless user explicitly requests fixes
- For large specs, focus detailed analysis on P1 user stories first
- Report findings incrementally (don't wait until end to show anything)

## Example Usage

```bash
# Validate current feature
/speckit.validate

# Validate specific feature
/speckit.validate 001

# Validate with auto-fix
/speckit.validate --fix
```

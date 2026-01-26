---
description: Review implementation against specification and generate assessment report
arguments: []
---

# /projspec.review Command

This command reviews the completed implementation against the specification document. It compares what was requested (spec.md) with what was built (task summaries), validates success criteria, and generates a review report.

## Use Cases

- Assessing implementation completeness after all tasks are done
- Validating that requirements from spec.md are satisfied
- Generating a review report before archiving
- Identifying gaps between specification and implementation

## Prerequisites

- A spec must exist and be in the "implement" phase
- Ideally, all tasks should be completed (warning if not)
- The spec.md and plan.md files should exist
- User should be in the spec's worktree or the main repository

## Execution Steps

Follow these steps exactly to perform the implementation review:

### Step 1: Detect Current Spec

Find the active spec by listing the `.projspec/specs/active/` directory:

```bash
ls .projspec/specs/active/
```

If the directory is empty or doesn't exist, output this error and stop:

```
Error: No active specs found.

Create a new spec first with: /projspec.new <spec-name>
```

If multiple specs are found, list them and ask the user which one to review:

```
Multiple active specs found:
- {SPEC_ID_1}: {SPEC_NAME_1} (phase: {PHASE_1})
- {SPEC_ID_2}: {SPEC_NAME_2} (phase: {PHASE_2})

Which spec would you like to review? Please provide the spec ID.
```

### Step 2: Load State Configuration

Read the state.yaml file for the selected spec:

```bash
cat .projspec/specs/active/{SPEC_ID}/state.yaml
```

Parse the YAML to extract:
- `SPEC_ID`: The spec identifier
- `SPEC_NAME`: The spec name
- `PHASE`: Current phase
- `WORKTREE_PATH`: Path to the worktree
- `tasks`: List of tasks with their status and summaries

### Step 3: Validate Phase

Check that the current phase allows review:

**If phase is "new", "spec", or "plan":**
```
This spec is still in the "{PHASE}" phase.

The implementation must be started first.
Current workflow: new -> spec -> plan -> tasks -> implement -> review

Please complete the earlier phases:
  - If in "new": /projspec.spec
  - If in "spec": /projspec.plan
  - If in "plan": /projspec.tasks

Then run /projspec.implement to complete tasks before review.
```

**If phase is "tasks":**
```
This spec is in the "tasks" phase.

Implementation has not started yet.
Please run: /projspec.implement

After completing implementation tasks, run /projspec.review.
```

**If phase is "review":**
```
This spec has already been reviewed.

Current phase: review
Review completed at: {REVIEW_TIMESTAMP if available}

Would you like to:
1. View the existing review report
2. Re-run the review (generate new assessment)
3. Proceed to archive: /projspec.archive

Please choose an option.
```

If user chooses option 2, proceed with the remaining steps.

**If phase is "implement":**
Proceed to Step 4.

### Step 4: Check Task Completion Status

Analyze the tasks array from state.yaml:

```
Task Summary:
  - Total: {TOTAL_COUNT}
  - Completed: {COMPLETED_COUNT}
  - In Progress: {IN_PROGRESS_COUNT}
  - Pending: {PENDING_COUNT}
  - Skipped: {SKIPPED_COUNT}
```

**If all tasks are completed or skipped:**
```
All implementation tasks are complete. Proceeding with review.
```

**If tasks are incomplete (pending or in_progress exist):**
```
Warning: Not all tasks are completed.

Incomplete Tasks:
| ID       | Name                  | Status      |
|----------|----------------------|-------------|
| {ID}     | {NAME}               | {STATUS}    |

Continuing with the review will assess the current state.

Do you want to:
1. Continue with partial review (assess current state)
2. Go back and complete remaining tasks first (/projspec.implement)

Please choose an option.
```

If user chooses option 2, stop and suggest `/projspec.implement`.
If user chooses option 1, proceed with review.

### Step 5: Load Specification Document

Read the spec.md file:

```bash
cat {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md
```

If the file doesn't exist:
```
Error: spec.md not found at {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md

The specification document is required for review.
Please ensure the specification phase was completed.
```

Parse spec.md to extract:
- **User Stories**: All user story items from the "User Stories" section
- **Technical Requirements**: All requirements from "Technical Requirements" section
- **Success Criteria**: All items from "Success Criteria" / "Acceptance Criteria" section
- **Out of Scope**: Items listed as explicitly excluded

### Step 6: Load Implementation Plan

Read the plan.md file:

```bash
cat {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md
```

Parse plan.md to extract:
- **Build Order**: The phases and tasks defined
- **Testing Strategy**: Test requirements and coverage goals
- **Key Decisions**: Technical decisions made during planning

### Step 7: Collect Task Summaries

Gather all completed task summaries from state.yaml:

For each task with `status: completed`:
- Extract the `summary` field (3-5 bullet points of what was implemented)
- Note the task `name` and `id`

Create a consolidated implementation summary:

```
Implementation Summary (from completed tasks):

task-001: {TASK_NAME}
  - {SUMMARY_BULLET_1}
  - {SUMMARY_BULLET_2}
  - {SUMMARY_BULLET_3}

task-002: {TASK_NAME}
  - {SUMMARY_BULLET_1}
  - {SUMMARY_BULLET_2}
...
```

### Step 8: Perform Requirement Verification

Compare spec.md requirements against task summaries to assess coverage.

#### User Story Verification

For each user story in spec.md:
1. Check if any completed task summary addresses this story
2. Mark as: VERIFIED, PARTIAL, or NOT ADDRESSED

```
User Story Verification:
| Story | Status | Evidence |
|-------|--------|----------|
| As a {role}, I want {capability}... | VERIFIED | task-001, task-003 |
| As a {role}, I want {capability}... | PARTIAL | task-002 (missing X) |
| As a {role}, I want {capability}... | NOT ADDRESSED | No matching task |
```

#### Technical Requirements Verification

For each requirement in spec.md:
1. Check if task summaries indicate this requirement was implemented
2. Mark as: IMPLEMENTED, PARTIAL, or NOT IMPLEMENTED

```
Technical Requirements Verification:
| Requirement | Status | Evidence |
|-------------|--------|----------|
| {Requirement description} | IMPLEMENTED | task-004 summary |
| {Requirement description} | PARTIAL | task-002 (needs completion) |
| {Requirement description} | NOT IMPLEMENTED | No evidence |
```

#### Success Criteria Verification

For each acceptance criterion:
1. Assess if the implementation meets the criterion
2. Mark as: PASSED, NEEDS VERIFICATION, or FAILED

```
Success Criteria Verification:
| Criterion | Status | Notes |
|-----------|--------|-------|
| {Specific criterion} | PASSED | Verified by task-001 |
| {Specific criterion} | NEEDS VERIFICATION | Requires manual testing |
| {Specific criterion} | FAILED | Not implemented |
```

### Step 9: Generate Review Report

Create or display the review report with the following structure:

```markdown
# Review Report: {SPEC_NAME}

**Spec ID**: {SPEC_ID}
**Review Date**: {CURRENT_DATE}
**Phase**: implement -> review

---

## Executive Summary

**Overall Status**: {COMPLETE / MOSTLY COMPLETE / PARTIALLY COMPLETE / INCOMPLETE}

- User Stories: {X}/{Y} verified ({PERCENTAGE}%)
- Requirements: {X}/{Y} implemented ({PERCENTAGE}%)
- Acceptance Criteria: {X}/{Y} passed ({PERCENTAGE}%)

---

## Task Completion Summary

| Task ID | Task Name | Status | Summary |
|---------|-----------|--------|---------|
| task-001 | {NAME} | completed | {FIRST_SUMMARY_LINE} |
| task-002 | {NAME} | completed | {FIRST_SUMMARY_LINE} |
| task-003 | {NAME} | skipped | Skipped: {REASON} |

**Completed**: {COMPLETED_COUNT}/{TOTAL_COUNT} tasks
**Skipped**: {SKIPPED_COUNT} tasks

---

## User Story Coverage

{USER_STORY_VERIFICATION_TABLE from Step 8}

### Verified Stories

- {STORY_1}: Fully implemented by {TASK_IDS}
- {STORY_2}: Fully implemented by {TASK_IDS}

### Partially Addressed Stories

- {STORY_3}: Missing {SPECIFIC_GAP}

### Unaddressed Stories

- {STORY_4}: Not implemented - {RECOMMENDATION}

---

## Requirements Coverage

{TECHNICAL_REQUIREMENTS_VERIFICATION_TABLE from Step 8}

### Implemented Requirements

1. {REQUIREMENT_1}: {EVIDENCE}
2. {REQUIREMENT_2}: {EVIDENCE}

### Partially Implemented Requirements

1. {REQUIREMENT_3}: {WHAT_IS_MISSING}

### Not Implemented Requirements

1. {REQUIREMENT_4}: {RECOMMENDATION}

---

## Success Criteria Assessment

{SUCCESS_CRITERIA_VERIFICATION_TABLE from Step 8}

### Passed Criteria

- [ x ] {CRITERION_1}
- [ x ] {CRITERION_2}

### Needs Verification (Manual Testing Required)

- [ ? ] {CRITERION_3}: {WHAT_TO_TEST}
- [ ? ] {CRITERION_4}: {WHAT_TO_TEST}

### Failed Criteria

- [ ] {CRITERION_5}: {WHY_FAILED}

---

## Implementation Highlights

### Key Accomplishments

Based on completed task summaries:

1. {MAJOR_ACCOMPLISHMENT_1}
2. {MAJOR_ACCOMPLISHMENT_2}
3. {MAJOR_ACCOMPLISHMENT_3}

### Files Created/Modified

Based on context_files from tasks:
- {FILE_PATH_1}
- {FILE_PATH_2}
- {DIRECTORY_1}

---

## Recommendations

### Before Archive

{LIST_OF_ITEMS_TO_ADDRESS_BEFORE_ARCHIVING}

1. {RECOMMENDATION_1}
2. {RECOMMENDATION_2}

### Future Considerations

Items intentionally out of scope that could be addressed later:

- {OUT_OF_SCOPE_ITEM_1}
- {OUT_OF_SCOPE_ITEM_2}

---

## Review Decision

Based on this assessment:

- [ ] **Ready to Archive**: All criteria met, proceed with /projspec.archive
- [ ] **Needs Work**: Address recommendations above, then re-run /projspec.review
- [ ] **Requires Discussion**: Significant gaps need stakeholder input

---

**Reviewed by**: Claude Code
**Review Method**: Automated spec-vs-implementation comparison
```

### Step 10: Save Review Report (Optional)

Ask user if they want to save the review report:

```
Would you like to save this review report?

1. Save to {WORKTREE_PATH}/specs/{SPEC_ID}/review.md
2. Display only (do not save)

Please choose an option.
```

If option 1, write the report to `{WORKTREE_PATH}/specs/{SPEC_ID}/review.md`.

### Step 11: Update state.yaml

Update the phase in state.yaml from "implement" to "review":

Read the current state.yaml:
```bash
cat .projspec/specs/active/{SPEC_ID}/state.yaml
```

Modify the `phase` field from `implement` to `review` and write the updated content back to the file.

The updated state.yaml should have:
```yaml
phase: review
```

### Step 12: Output Success Message

Report completion:

```
Review completed successfully!

  Spec ID:      {SPEC_ID}
  Name:         {SPEC_NAME}
  Phase:        implement -> review
  Report:       {WORKTREE_PATH}/specs/{SPEC_ID}/review.md (if saved)

Review Summary:
  - Overall Status: {COMPLETE / MOSTLY COMPLETE / etc.}
  - User Stories: {X}/{Y} verified
  - Requirements: {X}/{Y} implemented
  - Acceptance Criteria: {X}/{Y} passed

{CONDITIONAL_RECOMMENDATIONS}

Next steps:
  1. Address any recommendations noted in the review
  2. Perform manual testing for "Needs Verification" items
  3. When satisfied, run: /projspec.archive to complete the spec
```

## Error Handling

### Missing spec.md

```
Error: Specification document not found.

Expected location: {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md

The review requires the specification to compare against.
This may indicate the spec phase was not completed properly.

Recovery options:
  1. Create spec.md manually
  2. Run /projspec.spec to generate it (may require phase reset)
```

### Missing plan.md

```
Warning: Implementation plan not found at {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md

Proceeding with review using spec.md only.
Some testing strategy and build order context may be missing.
```

### No completed tasks

```
Error: No completed tasks found.

Task Summary:
  - Completed: 0
  - In Progress: {COUNT}
  - Pending: {COUNT}

Review requires at least some completed tasks to assess.

Please run: /projspec.implement to complete tasks first.
```

### Corrupted state.yaml

```
Error: Unable to parse state.yaml for spec {SPEC_ID}.

Please check the file format:
  cat .projspec/specs/active/{SPEC_ID}/state.yaml

The file should be valid YAML with required fields:
  spec_id, name, phase, branch, worktree_path, tasks
```

## Example Usage

### Example 1: Standard Review (All Tasks Complete)

```
User: /projspec.review

Claude:
1. Detects spec a1b2c3d4 (user-auth) in "implement" phase
2. Verifies all 6 tasks are completed
3. Reads spec.md with 4 user stories, 10 requirements, 5 success criteria
4. Reads plan.md for testing strategy context
5. Collects summaries from all completed tasks
6. Compares requirements against implementation:
   - User Stories: 4/4 verified (100%)
   - Requirements: 9/10 implemented (90%)
   - Success Criteria: 4/5 passed (80%)
7. Generates review report with findings
8. User chooses to save report
9. Updates phase to "review"
10. Reports success with recommendations
```

### Example 2: Partial Review (Incomplete Tasks)

```
User: /projspec.review

Claude:
Warning: Not all tasks are completed.

Incomplete Tasks:
| ID       | Name                      | Status      |
|----------|--------------------------|-------------|
| task-005 | Add unit tests           | pending     |
| task-006 | Update documentation     | in_progress |

Do you want to:
1. Continue with partial review (assess current state)
2. Go back and complete remaining tasks first (/projspec.implement)

User: 1

Claude:
[Proceeds with review, noting gaps in coverage due to incomplete tasks]
```

### Example 3: Already Reviewed

```
User: /projspec.review

Claude:
This spec has already been reviewed.

Current phase: review

Would you like to:
1. View the existing review report
2. Re-run the review (generate new assessment)
3. Proceed to archive: /projspec.archive

User: 3

Claude:
To archive this spec, run: /projspec.archive

This will:
  - Merge the branch to main
  - Move spec from active/ to completed/
  - Clean up the worktree
```

## Review Assessment Guidelines

### Overall Status Determination

- **COMPLETE**: All user stories verified, all requirements implemented, all criteria passed
- **MOSTLY COMPLETE**: >80% coverage across all categories, no critical gaps
- **PARTIALLY COMPLETE**: 50-80% coverage, some important gaps exist
- **INCOMPLETE**: <50% coverage, significant work remaining

### Evidence Collection

When marking requirements as verified:
- Quote specific bullet points from task summaries
- Reference task IDs that address the requirement
- Note file paths from context_files that demonstrate implementation

### Gap Identification

For unaddressed requirements:
- Clearly state what is missing
- Suggest which phase might have missed it (tasks, implement)
- Recommend next action (create task, manual fix, defer)

## Notes

- The review is non-destructive until phase update
- Task summaries are the primary source of implementation evidence
- The report can be regenerated multiple times if needed
- Manual testing items should be highlighted for user verification
- Out-of-scope items from spec.md should be acknowledged, not flagged as gaps
- The review provides recommendations but doesn't block archive

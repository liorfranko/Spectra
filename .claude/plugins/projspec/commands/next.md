---
description: Manually advance a spec to the next workflow phase
arguments:
  - name: spec_id
    description: Spec ID to advance (optional - uses current spec if in worktree)
    required: false
  - name: --force
    description: Skip validation and force phase advancement
    required: false
---

# /projspec.next Command

This command allows manual advancement of a spec to the next workflow phase. It validates that required artifacts exist for the current phase before advancing, updates the state.yaml, and suggests the appropriate command to run after advancement.

## Quick Reference

```
/projspec.next [spec_id] [--force]
```

**Arguments:**
- `spec_id` (optional) - Spec ID to advance; auto-detected if in worktree
- `--force` (optional) - Skip validation checks

Advances the spec to the next phase: `new -> spec -> plan -> tasks -> implement -> review`

## Use Cases

- Advancing a spec when you've created artifacts outside the normal workflow
- Recovering from interrupted workflows
- Moving forward when validation passes but auto-advancement didn't trigger
- Testing workflow transitions

## Phase Transitions

The workflow follows this sequence:

```
new -> spec -> plan -> tasks -> implement -> review
```

Phase can only move forward (no going back to previous phases).

## Validation Requirements by Phase

| Current Phase | Required Artifacts for Advancement |
|---------------|-----------------------------------|
| new | None (brief.md is optional) |
| spec | spec.md must exist |
| plan | plan.md must exist |
| tasks | tasks.md OR tasks in state.yaml must exist |
| implement | All tasks must be completed or skipped |
| review | Cannot advance (final phase) |

## Execution Steps

Follow these steps exactly to advance the spec to the next phase:

### Step 1: Detect Current Spec

If a spec_id argument is provided, use that. Otherwise, detect from environment.

**If spec_id argument provided:**
Store the argument value as `SPEC_ID`.

**If no argument provided:**
List all active specs:

```bash
ls .projspec/specs/active/ 2>/dev/null || echo "NO_SPECS"
```

If the result is "NO_SPECS" or empty, output:

```
Error: No active specs found.

Create a new spec first with: /projspec.new <spec-name>
```

If exactly one spec exists, use that spec's ID.

If multiple specs exist, try to detect from worktree:

```bash
basename "$PWD" | grep -oE 'spec-[a-f0-9]{8}' | grep -oE '[a-f0-9]{8}'
```

If in a worktree, match to a spec. Otherwise, list specs and ask user:

```
Multiple active specs found:
- {SPEC_ID_1}: {SPEC_NAME_1} (phase: {PHASE_1})
- {SPEC_ID_2}: {SPEC_NAME_2} (phase: {PHASE_2})

Which spec would you like to advance? Provide the spec ID:
  /projspec.next <spec-id>
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
- `TASKS`: List of tasks (if any)

If state.yaml doesn't exist or cannot be parsed, output error:

```
Error: Cannot read state.yaml for spec {SPEC_ID}.

File: .projspec/specs/active/{SPEC_ID}/state.yaml

Please check that the file exists and is valid YAML.
```

### Step 3: Determine Next Phase

Based on the current phase, determine the next phase:

| Current | Next |
|---------|------|
| new | spec |
| spec | plan |
| plan | tasks |
| tasks | implement |
| implement | review |
| review | (none - final) |

If the current phase is "review", output:

```
Spec {SPEC_NAME} ({SPEC_ID}) is already in the final phase (review).

No further advancement is possible. Options:
  - Archive the spec when complete: /projspec.archive
  - Continue reviewing the implementation
```

Store the next phase as `NEXT_PHASE`.

### Step 4: Validate Artifacts (Unless --force)

Unless the `--force` flag is provided, validate that required artifacts exist for the current phase before allowing advancement.

#### Validation: new -> spec

No validation required. Brief.md is optional.

```
Validation: PASSED (no artifacts required for new phase)
```

#### Validation: spec -> plan

Check that spec.md exists:

```bash
test -f {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md && echo "EXISTS" || echo "MISSING"
```

If MISSING:

```
Validation: FAILED

Cannot advance from 'spec' to 'plan' phase.

Missing required artifact:
  - {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md

Run /projspec.spec to create the specification document, or use --force to skip validation.
```

#### Validation: plan -> tasks

Check that plan.md exists:

```bash
test -f {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md && echo "EXISTS" || echo "MISSING"
```

If MISSING:

```
Validation: FAILED

Cannot advance from 'plan' to 'tasks' phase.

Missing required artifact:
  - {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md

Run /projspec.plan to create the implementation plan, or use --force to skip validation.
```

#### Validation: tasks -> implement

Check that tasks exist either in tasks.md OR in state.yaml:

```bash
test -f {WORKTREE_PATH}/specs/{SPEC_ID}/tasks.md && echo "EXISTS" || echo "MISSING"
```

Also check the `tasks` array in state.yaml from Step 2.

If tasks.md is MISSING AND the `tasks` array in state.yaml is empty or missing:

```
Validation: FAILED

Cannot advance from 'tasks' to 'implement' phase.

Missing required artifact:
  - {WORKTREE_PATH}/specs/{SPEC_ID}/tasks.md (not found)
  - state.yaml tasks array (empty or missing)

Run /projspec.tasks to generate tasks, or use --force to skip validation.
```

#### Validation: implement -> review

Check that all tasks are either completed or skipped:

Parse the `tasks` array from state.yaml and check statuses.

Count tasks by status:
- `completed_count`: Tasks with status "completed"
- `skipped_count`: Tasks with status "skipped"
- `pending_count`: Tasks with status "pending"
- `in_progress_count`: Tasks with status "in_progress"

If `pending_count > 0` OR `in_progress_count > 0`:

```
Validation: FAILED

Cannot advance from 'implement' to 'review' phase.

Task completion required:
  - Completed: {completed_count}
  - Skipped: {skipped_count}
  - In Progress: {in_progress_count}
  - Pending: {pending_count}

All tasks must be completed or skipped before moving to review.

Run /projspec.implement to continue implementation, or use --force to skip validation.
```

### Step 5: Update state.yaml

If validation passes (or --force was used), update the phase in state.yaml:

Read the current state.yaml:

```bash
cat .projspec/specs/active/{SPEC_ID}/state.yaml
```

Modify the `phase` field from `{PHASE}` to `{NEXT_PHASE}` and write the updated content back to the file.

**Important:** Preserve all other fields in the YAML file exactly as they were.

### Step 6: Output Success Message

Report success with the next recommended action:

```
Phase Advanced Successfully!

  Spec ID:    {SPEC_ID}
  Name:       {SPEC_NAME}
  Transition: {PHASE} -> {NEXT_PHASE}

{NEXT_STEP_GUIDANCE}
```

#### Next Step Guidance by New Phase

**If NEXT_PHASE is "spec":**
```
Next Steps:
  1. Edit or review: {WORKTREE_PATH}/specs/{SPEC_ID}/brief.md
  2. Run: /projspec.spec to create the specification document
```

**If NEXT_PHASE is "plan":**
```
Next Steps:
  1. Review: {WORKTREE_PATH}/specs/{SPEC_ID}/spec.md
  2. Run: /projspec.plan to create the implementation plan
```

**If NEXT_PHASE is "tasks":**
```
Next Steps:
  1. Review: {WORKTREE_PATH}/specs/{SPEC_ID}/plan.md
  2. Run: /projspec.tasks to generate implementation tasks
```

**If NEXT_PHASE is "implement":**
```
Next Steps:
  1. Review the generated tasks in state.yaml
  2. Run: /projspec.implement to start implementation
```

**If NEXT_PHASE is "review":**
```
Next Steps:
  1. Review implementation against the specification
  2. Verify all acceptance criteria are met
  3. Run tests and quality checks
  4. When satisfied: /projspec.archive to complete the spec
```

## Error Handling

### Spec Not Found

```
Error: Spec '{SPEC_ID}' not found.

Available specs:
  - {ID_1}: {NAME_1} (phase: {PHASE_1})
  - {ID_2}: {NAME_2} (phase: {PHASE_2})

Use /projspec.status to see all specs.
```

### Invalid State File

```
Error: Invalid state.yaml for spec {SPEC_ID}.

The state file exists but could not be parsed as valid YAML.
Check: .projspec/specs/active/{SPEC_ID}/state.yaml
```

### Force Mode Warning

When --force is used and validation would have failed:

```
Warning: Forcing phase advancement despite validation failure.

The following validation issues were bypassed:
  - {VALIDATION_ISSUE}

Phase advanced: {PHASE} -> {NEXT_PHASE}

Note: This may cause issues in subsequent workflow steps.
```

## Example Usage

### Example 1: Simple Advancement

```
User: /projspec.next

Claude:
Validating phase transition...
  Current phase: plan
  Checking: worktrees/spec-a1b2c3d4-user-auth/specs/a1b2c3d4/plan.md
  Validation: PASSED

Phase Advanced Successfully!

  Spec ID:    a1b2c3d4
  Name:       user-auth
  Transition: plan -> tasks

Next Steps:
  1. Review: worktrees/spec-a1b2c3d4-user-auth/specs/a1b2c3d4/plan.md
  2. Run: /projspec.tasks to generate implementation tasks
```

### Example 2: Validation Failure

```
User: /projspec.next

Claude:
Validating phase transition...
  Current phase: spec
  Checking: worktrees/spec-a1b2c3d4-user-auth/specs/a1b2c3d4/spec.md
  Validation: FAILED

Cannot advance from 'spec' to 'plan' phase.

Missing required artifact:
  - worktrees/spec-a1b2c3d4-user-auth/specs/a1b2c3d4/spec.md

Run /projspec.spec to create the specification document, or use --force to skip validation.
```

### Example 3: Force Advancement

```
User: /projspec.next --force

Claude:
Warning: Forcing phase advancement despite validation failure.

The following validation issues were bypassed:
  - spec.md not found at worktrees/spec-a1b2c3d4-user-auth/specs/a1b2c3d4/spec.md

Phase advanced: spec -> plan

Note: This may cause issues in subsequent workflow steps.

Next Steps:
  1. Review: worktrees/spec-a1b2c3d4-user-auth/specs/a1b2c3d4/spec.md
  2. Run: /projspec.plan to create the implementation plan
```

### Example 4: Final Phase

```
User: /projspec.next

Claude:
Spec user-auth (a1b2c3d4) is already in the final phase (review).

No further advancement is possible. Options:
  - Archive the spec when complete: /projspec.archive
  - Continue reviewing the implementation
```

### Example 5: With Specific Spec ID

```
User: /projspec.next e5f6g7h8

Claude:
Validating phase transition for spec e5f6g7h8...
  Current phase: new
  Validation: PASSED (no artifacts required for new phase)

Phase Advanced Successfully!

  Spec ID:    e5f6g7h8
  Name:       payment-api
  Transition: new -> spec

Next Steps:
  1. Edit or review: worktrees/spec-e5f6g7h8-payment-api/specs/e5f6g7h8/brief.md
  2. Run: /projspec.spec to create the specification document
```

## Notes

- This command is non-destructive to artifacts; it only modifies state.yaml
- Phase transitions are one-way (forward only)
- The --force flag should be used sparingly, as it may cause workflow issues
- For normal workflow, prefer using the phase-specific commands (/projspec.spec, /projspec.plan, etc.)
- This command is useful for recovery and manual intervention scenarios

## See Also

- `/projspec.resume` - Detect current state and get guidance
- `/projspec.status` - View all specs and their phases
- `/projspec.spec`, `/projspec.plan`, `/projspec.tasks` - Standard phase commands

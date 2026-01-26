---
description: "Create an explicit session checkpoint to save current state for later reference"
user-invocable: true
argument-hint: checkpoint name or description
---

# Checkpoint Command

Create an explicit session checkpoint that captures the current state of the feature development process. Checkpoints provide a way to save progress, document decision points, and enable session resumption.

## Arguments

The `$ARGUMENTS` variable contains the optional checkpoint name or description:
- A descriptive name (e.g., "spec-complete", "pre-implementation")
- A longer description of the checkpoint purpose
- (empty) - Auto-generate checkpoint name based on current state

## Overview

Checkpoints serve several purposes:
- Save session state for later reference or resumption
- Document important decision points in the development process
- Enable rollback to known-good states
- Provide audit trail of feature development

## Workflow

### Step 1: Gather Current State

**1.1: Identify feature context**

Run prerequisite check to gather context:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --json
```

Parse JSON output to extract:
- `FEATURE_DIR` - Path to current feature directory
- `FEATURE_ID` - Current feature identifier
- `AVAILABLE_DOCS` - List of existing documents

**1.2: Collect artifact states**

For each artifact in the feature directory, collect:

| Artifact | Collect |
|----------|---------|
| spec.md | User scenario count, requirement count, open questions |
| plan.md | Constitution check status, phases defined |
| research.md | Decisions count, unknowns resolved |
| data-model.md | Entity count, relationship count |
| tasks.md | Total tasks, completed tasks, pending tasks |
| checklists/*.md | Checklist completion status |

```
artifactState = {
  "spec.md": {
    exists: true,
    lastModified: "2024-01-15T10:30:00Z",
    stats: {
      userScenarios: 3,
      requirements: 5,
      successCriteria: 2,
      openQuestions: 1
    }
  },
  "plan.md": {
    exists: true,
    lastModified: "2024-01-15T11:00:00Z",
    stats: {
      constitutionCheck: "PASS",
      phases: 4
    }
  },
  "tasks.md": {
    exists: true,
    lastModified: "2024-01-15T12:00:00Z",
    stats: {
      total: 40,
      completed: 15,
      pending: 25,
      blocked: 2
    }
  },
  ...
}
```

**1.3: Capture git state**

```bash
# Get current branch
git rev-parse --abbrev-ref HEAD

# Get current commit
git rev-parse HEAD

# Get current commit message
git log -1 --format=%s

# Check for uncommitted changes
git status --porcelain
```

Store git state:
```
gitState = {
  branch: "003-feature-name",
  commit: "a1b2c3d4e5f6...",
  commitMessage: "[T015] Implement validation logic",
  uncommittedChanges: true | false,
  changedFiles: ["path/to/file1", "path/to/file2"]
}
```

**1.4: Collect session context**

Gather contextual information:
- Current timestamp
- User-provided checkpoint name/description
- Inferred development phase
- Recent commands executed (if available)

```
sessionContext = {
  timestamp: "2024-01-15T14:30:00Z",
  checkpointName: $ARGUMENTS or auto-generated,
  developmentPhase: inferred from artifact state,
  description: user-provided or auto-generated
}
```

### Step 2: Determine Checkpoint Name

**2.1: If $ARGUMENTS provided, use as checkpoint name**

Parse the arguments:
- If short (1-3 words): Use as checkpoint name
- If longer: Use as description, generate short name

**2.2: If no arguments, auto-generate based on state**

Analyze artifact state to generate meaningful name:

| Current State | Generated Name |
|---------------|----------------|
| Only spec.md exists | `spec-draft-{N}` |
| spec.md complete, no plan | `spec-complete` |
| plan.md exists | `plan-draft-{N}` |
| tasks.md exists, 0 completed | `ready-to-implement` |
| tasks.md with some completed | `implementation-{percent}%` |
| All tasks completed | `implementation-complete` |
| After review | `review-checkpoint` |

Where `{N}` is an incrementing number based on existing checkpoints.

**2.3: Sanitize checkpoint name for file system**

```
sanitized_name = checkpointName
  .toLowerCase()
  .replace(/[^a-z0-9-]/g, '-')
  .replace(/-+/g, '-')
  .replace(/^-|-$/g, '')
```

### Step 3: Create Checkpoint Document

**3.1: Determine checkpoint storage location**

```bash
# Create checkpoints directory if needed
CHECKPOINT_DIR="${FEATURE_DIR}/checkpoints"
mkdir -p "${CHECKPOINT_DIR}"

# Generate unique checkpoint file name
CHECKPOINT_FILE="${CHECKPOINT_DIR}/${timestamp}-${sanitized_name}.md"
```

**3.2: Generate checkpoint content**

```markdown
# Checkpoint: {checkpointName}

**Created:** {timestamp in ISO 8601}
**Feature:** {FEATURE_ID}
**Branch:** {gitState.branch}
**Commit:** {gitState.commit}

---

## Description

{User-provided description or auto-generated summary}

---

## Development State

### Phase: {developmentPhase}

| Milestone | Status |
|-----------|--------|
| Specification | {Complete/In Progress/Not Started} |
| Planning | {Complete/In Progress/Not Started} |
| Tasks Generated | {Yes/No} |
| Implementation | {X% Complete} |
| Review | {Complete/In Progress/Not Started} |

### Progress Summary

- **Total Tasks:** {total or "N/A"}
- **Completed:** {completed or "N/A"}
- **Remaining:** {pending or "N/A"}
- **Blocked:** {blocked or "N/A"}

---

## Artifact States

{For each artifact in artifactState:}
### {artifact_name}

- **Exists:** {Yes/No}
- **Last Modified:** {lastModified or "N/A"}
{For each stat in artifact.stats:}
- **{stat_name}:** {stat_value}
{End for}

{End for}

---

## Git State

- **Branch:** `{gitState.branch}`
- **Commit:** `{gitState.commit}`
- **Message:** {gitState.commitMessage}
- **Uncommitted Changes:** {Yes/No}

{If uncommittedChanges:}
### Uncommitted Files

```
{For each file in changedFiles:}
{file}
{End for}
```

**Warning:** Consider committing changes before creating checkpoint for full state capture.
{End if}

---

## Session Notes

{If user provided additional notes:}
{user notes}
{Else:}
<!--
Add any notes about decisions, blockers, or context for this checkpoint.
-->
{End if}

---

## Resume Instructions

To resume from this checkpoint:

1. **Verify branch:**
   ```bash
   git checkout {gitState.branch}
   ```

2. **Verify commit (if needed):**
   ```bash
   git log --oneline -1  # Should show: {gitState.commit short}
   ```

3. **Continue development:**
   {Based on development phase:}
   {If spec phase:}
   - Run `/speckit.clarify` to resolve open questions
   - Run `/speckit.plan` when spec is complete
   {End if}
   {If plan phase:}
   - Run `/speckit.tasks` to generate task list
   {End if}
   {If implementation phase:}
   - Run `/speckit.implement` to continue implementation
   - Next task: {next pending task ID and description}
   {End if}
   {If review phase:}
   - Run `/speckit.review-pr` to complete review
   {End if}

---

*Checkpoint created by SpecKit `/checkpoint` command*
```

**3.3: Write checkpoint file**

Write the generated content to the checkpoint file.

### Step 4: Create Checkpoint Index

**4.1: Update or create checkpoint index**

Maintain an index of all checkpoints for easy navigation:

```bash
INDEX_FILE="${FEATURE_DIR}/checkpoints/INDEX.md"
```

If index doesn't exist, create it:
```markdown
# Checkpoint Index: {FEATURE_ID}

This document lists all checkpoints for this feature in reverse chronological order.

---

## Checkpoints

| Timestamp | Name | Phase | Commit | Description |
|-----------|------|-------|--------|-------------|
```

**4.2: Add new checkpoint to index**

Prepend new checkpoint entry to the table:
```markdown
| {timestamp} | [{checkpointName}](./{checkpoint_filename}) | {phase} | `{commit_short}` | {brief_description} |
```

### Step 5: Optional Git Tag

**5.1: Offer to create git tag for significant checkpoints**

```markdown
## Git Tag Option

Would you like to create a git tag for this checkpoint?

A git tag provides:
- Easy reference point in git history
- Ability to checkout this exact state later
- Clear marker in commit log

Tag name would be: `checkpoint/{FEATURE_ID}/{sanitized_name}`

Create tag? (y/n)
```

**5.2: If user confirms, create git tag**

```bash
git tag -a "checkpoint/${FEATURE_ID}/${sanitized_name}" \
  -m "Checkpoint: ${checkpointName}" \
  -m "Feature: ${FEATURE_ID}" \
  -m "Phase: ${developmentPhase}" \
  -m "Created by: /speckit.checkpoint"
```

**5.3: Optionally push tag to remote**

```markdown
Tag created: `checkpoint/{FEATURE_ID}/{sanitized_name}`

Push tag to remote? (y/n)
```

If confirmed:
```bash
git push origin "checkpoint/${FEATURE_ID}/${sanitized_name}"
```

### Step 6: Report Checkpoint Creation

**6.1: Display checkpoint summary**

```markdown
## Checkpoint Created

**Name:** {checkpointName}
**File:** {CHECKPOINT_FILE}
**Timestamp:** {timestamp}

### State Captured

| Item | Value |
|------|-------|
| Feature | {FEATURE_ID} |
| Branch | {gitState.branch} |
| Commit | `{gitState.commit short}` |
| Phase | {developmentPhase} |
| Progress | {completion percentage}% |

### Quick Stats

- **Artifacts:** {artifact_count} captured
- **Tasks:** {completed}/{total} complete
- **Uncommitted Changes:** {Yes/No}
{If git tag created:}
- **Git Tag:** `checkpoint/{FEATURE_ID}/{sanitized_name}`
{End if}

### Resume From This Checkpoint

To return to this checkpoint state:

```bash
# View checkpoint details
cat {CHECKPOINT_FILE}

# Checkout the commit
git checkout {gitState.commit}

# Or checkout the tag (if created)
git checkout checkpoint/{FEATURE_ID}/{sanitized_name}
```

### View All Checkpoints

```bash
# List checkpoint files
ls {FEATURE_DIR}/checkpoints/

# View checkpoint index
cat {FEATURE_DIR}/checkpoints/INDEX.md
```
```

**6.2: Suggest next actions**

```markdown
### Next Steps

{Based on development phase:}
{If implementation in progress:}
- Continue implementation: `/speckit.implement`
- Check task status: Review tasks.md
{End if}

{If blocked or stuck:}
- Consider: What's blocking progress?
- Review: Open questions or dependencies
{End if}

{If completing a milestone:}
- Review checkpoint before proceeding
- Share checkpoint file with team if needed
{End if}
```

## Output

Upon completion, this command produces:

### Files Created

| File | Description |
|------|-------------|
| `checkpoints/{timestamp}-{name}.md` | Checkpoint document |
| `checkpoints/INDEX.md` | Checkpoint index (created/updated) |

### Git Artifacts (Optional)

| Artifact | Description |
|----------|-------------|
| Git tag | `checkpoint/{feature}/{name}` (if user confirms) |

### Console Output

| Output | When Displayed |
|--------|----------------|
| State collection progress | During checkpoint creation |
| Checkpoint summary | After creation |
| Resume instructions | In summary |
| Next steps | Based on current phase |

## Usage

```
/speckit.checkpoint [name or description]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `name` | Short checkpoint name (e.g., "pre-refactor") |
| `description` | Longer description of checkpoint purpose |
| (empty) | Auto-generate name based on current state |

### Examples

```bash
# Create checkpoint with auto-generated name
/speckit.checkpoint

# Create named checkpoint
/speckit.checkpoint spec-complete

# Create checkpoint with description
/speckit.checkpoint "Before major refactoring of auth module"

# Create milestone checkpoint
/speckit.checkpoint phase-2-complete
```

## Notes

- Checkpoints are stored in the feature's `checkpoints/` directory
- Uncommitted changes are noted but not captured in git state
- Git tags are optional but recommended for significant milestones
- Use checkpoints before risky changes or at natural break points
- Checkpoint index provides quick navigation to all checkpoints
- Resume instructions are tailored to the development phase

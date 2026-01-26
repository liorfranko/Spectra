---
description: Create an explicit session checkpoint to save current state for later reference.
argument-hint: "[checkpoint name or description]"
---

## User Input

```text
$ARGUMENTS
```

## Outline

Create an explicit checkpoint of the current session state. This is useful for:

- Marking significant milestones in a session
- Saving context before taking a break
- Creating reference points for complex work

### 1. Validate Checkpoint Name

If the user provided a name/description:

- Use it as the checkpoint identifier
- Sanitize for use in filenames (replace spaces with hyphens, remove special characters)

If no name provided:

- Generate a descriptive name based on recent activity
- Example: `implement-auth-feature` or `debug-api-issue`

### 2. Gather Current State

Collect information about the current session state:

#### Active Work

- Current feature branch (if any)
- Files recently modified
- Open tasks or in-progress items

#### Context Summary

- What was accomplished in this session
- Current focus area
- Pending decisions or blockers

#### Important References

- Key files involved
- Relevant documentation
- External resources consulted

### 3. Create Checkpoint File

Create a checkpoint file at `.specify/sessions/checkpoints/[name].md`:

```markdown
# Checkpoint: [Name]

**Created**: [timestamp]
**Branch**: [current branch]
**Session**: [session date]

## Summary

[Brief description of what was happening at checkpoint time]

## Current State

### Completed

- [List of completed items]

### In Progress

- [List of in-progress items]

### Pending

- [List of pending items or decisions]

## Key Files

- [List of important files for context]

## Notes

[Any additional context for resuming work]

## Resume Instructions

When resuming from this checkpoint:

1. [Step 1]
2. [Step 2]
3. ...
```

### 4. Update Session Log

Add a reference to this checkpoint in today's session log:

```markdown
## Checkpoint Created: [timestamp]

Name: [checkpoint name]
File: .specify/sessions/checkpoints/[name].md
```

### 5. Report Completion

Confirm the checkpoint was created:

- Show the checkpoint file path
- Summarize what was captured
- Explain how to reference it later

## Usage Examples

```text
/speckit.checkpoint auth implementation complete
/speckit.checkpoint before refactoring
/speckit.checkpoint end of day
```

## Notes

- Checkpoints are saved in `.specify/sessions/checkpoints/`
- They can be git-tracked for team visibility
- Reference checkpoints when resuming work
- Checkpoints complement automatic session logging

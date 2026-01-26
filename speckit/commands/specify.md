---
description: Create a structured feature specification from a natural language description
user-invocable: true
argument-hint: feature description
---

# Specify Command

Create or update a feature specification from a natural language feature description. This command transforms informal requirements into a structured spec.md document.

## Arguments

The `$ARGUMENTS` variable contains the feature description provided by the user. This should be a natural language description of the feature to be specified.

## Workflow Steps

### Step 1: Validate Input

Check that the user provided a feature description:

1. If `$ARGUMENTS` is empty or contains only whitespace:
   - Prompt the user: "Please provide a feature description. What feature would you like to specify?"
   - Wait for user input before proceeding
   - Store the response as the feature description

2. If `$ARGUMENTS` contains a valid description:
   - Use it directly as the feature description
   - Proceed to Step 2

### Step 2: Create Feature Structure

Run the create-new-feature.sh script to set up the feature branch and directory:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/create-new-feature.sh "$ARGUMENTS" --json
```

**Parse the JSON output** to extract:
- `FEATURE_ID`: The unique identifier for the feature (e.g., "003-user-auth")
- `FEATURE_DIR`: The absolute path to the feature directory (e.g., "/path/to/specs/003-user-auth")
- `BRANCH`: The git branch name (same as FEATURE_ID)

**Error Handling:**
- If the script exits with a non-zero status, report the error message to the user and stop
- Common errors include:
  - Feature directory already exists
  - Branch already exists
  - Failed to create worktree
  - Invalid feature description

### Step 3: Navigate to Feature Directory

Use the `FEATURE_DIR` path from the script output:

1. Verify the directory exists and contains a `checklists/` subdirectory
2. The spec.md file will be created at: `${FEATURE_DIR}/spec.md`
3. Store the feature context for subsequent steps:
   - Feature ID: Used for cross-references
   - Feature Directory: Base path for all feature artifacts
   - Branch Name: For git operations

<!-- T018: Add spec generation step -->
<!-- Generate structured spec.md from feature description -->

<!-- T019: Add clarification questions step -->
<!-- Identify ambiguities and prompt for clarification -->

<!-- T020: Add finalization step -->
<!-- Finalize spec and report results -->

## Output

Upon completion, this command will:
1. Create a structured specification document at `specs/{feature-id}/spec.md`
2. Report any clarification questions or ambiguities found
3. Provide a summary of the generated specification

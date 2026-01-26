---
description: "Convert tasks from tasks.md into GitHub issues"
user-invocable: true
---

# Issues Command

Converts tasks defined in `tasks.md` into GitHub issues with appropriate labels and dependency references.

## Prerequisites

Before running this command, ensure the following requirements are met:

1. **tasks.md must exist**: The feature must have a completed `tasks.md` file containing the task definitions to convert.
2. **gh CLI must be installed**: The GitHub CLI (`gh`) is required for issue creation.
3. **gh CLI must be authenticated**: Run `gh auth status` to verify authentication.

## Workflow

The issues command executes the following steps:

### Step 1: Check gh CLI Authentication
<!-- Implementation: T044 -->
Verify that the GitHub CLI is installed and properly authenticated before proceeding.

### Step 2: Parse tasks.md
<!-- Implementation: T045 -->
Read and parse the tasks.md file to extract:
- Task IDs
- Task titles and descriptions
- Dependencies between tasks
- Acceptance criteria

### Step 3: Create GitHub Issues
<!-- Implementation: T046 -->
For each task in tasks.md:
- Create a corresponding GitHub issue
- Apply appropriate labels (e.g., feature name, task type)
- Include task description and acceptance criteria in the issue body

### Step 4: Add Dependency References
<!-- Implementation: T047 -->
After all issues are created:
- Update issue bodies with references to dependent issues
- Add "blocked by" and "blocks" references where applicable

### Step 5: Error Handling
<!-- Implementation: T048 -->
Handle potential errors gracefully:
- Missing tasks.md file
- gh CLI not installed or not authenticated
- GitHub API rate limits
- Network connectivity issues
- Duplicate issue detection

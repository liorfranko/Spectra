---
description: "Convert tasks from tasks.md into GitHub issues"
user-invocable: true
---

# Issues Command

Converts tasks defined in `tasks.md` into GitHub issues with appropriate labels and dependency references.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

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

**1.1: Run prerequisite check to verify tasks.md exists**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-tasks --json --include-tasks
```

Parse the JSON output to extract:
- `FEATURE_DIR` - The path to the current feature directory
- `AVAILABLE_DOCS` - List of documents that exist in the feature directory
- `GH_CLI_AVAILABLE` - Boolean indicating if GitHub CLI is installed
- `TASKS_CONTENT` - The full content of tasks.md

If the script exits with error (missing tasks.md), display an error message instructing the user to run `/projspec.tasks` first, then stop execution.

**1.2: Check if gh CLI is available**

If `GH_CLI_AVAILABLE` is `false`:

```markdown
## Error: GitHub CLI Not Installed

The GitHub CLI (`gh`) is required to create issues but is not installed.

**Installation:**

- macOS: `brew install gh`
- Linux: See https://github.com/cli/cli#installation
- Windows: `winget install GitHub.cli` or `choco install gh`

After installation, run `gh auth login` to authenticate.
```

Stop execution if gh CLI is not available.

**1.3: Verify gh CLI authentication status**

Run the authentication check:

```bash
gh auth status 2>&1
```

Parse the output to determine authentication status. The output contains:
- Host (e.g., `github.com`)
- Logged in status
- Account name
- Token status
- Git protocol (https/ssh)

**1.4: Handle authentication check results**

**If authenticated successfully:**

Parse the output to extract the authenticated account. Look for patterns like:
- `Logged in to github.com as USERNAME`
- `Token: valid`

```markdown
## GitHub Authentication Verified

✓ Authenticated to GitHub as **{username}**
✓ Token is valid
✓ Ready to create issues
```

**If not authenticated or token is invalid:**

```markdown
## Error: GitHub CLI Not Authenticated

The GitHub CLI is installed but not authenticated.

**Authentication Required:**

Run the following command to authenticate:

```bash
gh auth login
```

Follow the prompts to:
1. Choose GitHub.com or GitHub Enterprise
2. Select authentication method (browser or token)
3. Complete the authentication flow

After authentication, run `/projspec.issues` again.
```

Stop execution if not authenticated.

**1.5: Verify repository context**

Check that we're in a valid git repository with a remote:

```bash
gh repo view --json nameWithOwner,url 2>&1
```

Parse the output to extract:
- `nameWithOwner` - Repository identifier (e.g., `owner/repo`)
- `url` - Repository URL

If the command fails (not in a repo or no remote):

```markdown
## Error: No GitHub Repository Found

This directory is not linked to a GitHub repository.

**Possible causes:**
1. Not in a git repository
2. No remote configured
3. Remote is not on GitHub

**Resolution:**
- Ensure you're in the project root directory
- Run `git remote -v` to check remotes
- Add a GitHub remote with `git remote add origin https://github.com/owner/repo.git`
```

Stop execution if no repository context.

**1.6: Store authentication context for subsequent steps**

```
authContext = {
  authenticated: true,
  username: "{authenticated_username}",
  repository: "{owner/repo}",
  repositoryUrl: "{https://github.com/owner/repo}"
}
```

### Step 2: Parse tasks.md and Extract Task Details
<!-- Implementation: T045 -->

Read and parse the tasks.md file to extract task information needed for issue creation.

**2.1: Parse TASKS_CONTENT from Step 1.1**

The `TASKS_CONTENT` contains the full tasks.md file. Parse it to extract all tasks. Each task line follows one of these formats:

```
- [ ] T### Description (file path)                    # Pending task
- [ ] T### [P] Description (file path)                # Pending parallel task
- [ ] T### [US#] Description (file path)              # Pending task with story marker
- [ ] T### [P] [US#] Description (file path)          # Pending parallel task with story marker
- [x] T### Description (file path)                    # Completed task
```

**2.2: For each task line, extract the following fields:**

| Field | Extraction Pattern | Example |
|-------|-------------------|---------|
| Task ID | `T\d{3}` | T039 |
| Status | `\[ \]` = pending, `\[x\]` = completed | pending |
| Parallel Marker | Contains `[P]` after task ID | true/false |
| Story Marker | `\[US\d+\]` | US3 |
| Description | Text after markers, before `(` | "Add implement command logic..." |
| File Path | Text inside final `()` | "projspec/commands/implement.md" |

Build a task array:
```
tasks = [
  {
    id: "T039",
    status: "pending" | "completed",
    isParallel: true | false,
    storyId: "US3" | null,
    description: "Task description text",
    filePath: "path/to/file" | null
  },
  ...
]
```

**2.3: Extract phase information**

Parse the tasks.md structure to identify which phase each task belongs to. Phases are indicated by section headers:

```
## Phase N: Phase Name
```

For each task, determine its phase:
```
for each task in tasks:
  task.phase = {
    number: N,
    name: "Phase Name"
  }
```

**2.4: Extract dependency information**

Look for the "Dependencies" or "Dependencies & Execution Order" section in tasks.md. Parse dependency relationships:

| Dependency Type | Format | Example |
|-----------------|--------|---------|
| Phase dependencies | `Phase N depends on Phase M` | Phase 3 depends on Phase 2 |
| Task dependencies | Task blocked by other tasks | T015 blocked by T014 |
| Explicit blockedBy | In dependency table | `T015 | T014 | ...` |

Build dependency map:
```
dependencies = {
  "T015": {
    blockedBy: ["T014"],
    blocks: ["T016"]
  },
  ...
}
```

If explicit dependencies are not found, infer them from:
- Phase order (first task of Phase N depends on all tasks of Phase N-1)
- Sequential tasks within a phase (non-[P] tasks depend on previous non-[P] task)
- Parallel tasks depend on the last non-[P] task before them

**2.5: Extract feature metadata**

Parse the header of tasks.md to extract:
- Feature name (from `# Tasks: {Feature Name}` heading)
- Input sources (from `**Input**: ...` line)
- Prerequisites (from `**Prerequisites**: ...` line)

Store metadata:
```
featureMetadata = {
  name: "Feature Name",
  inputDocs: ["plan.md", "spec.md", ...],
  prerequisites: ["plan.md (required)", "spec.md (required)", ...]
}
```

**2.6: Filter tasks for issue creation**

Determine which tasks should be converted to issues:
- **Pending tasks**: Convert to issues (status = `[ ]`)
- **Completed tasks**: Skip unless `--include-completed` flag is provided

```
tasksToConvert = tasks.filter(t => t.status == "pending")
```

Report the task summary:
```markdown
## Task Analysis Complete

**Feature**: {featureMetadata.name}
**Repository**: {authContext.repository}

| Status | Count |
|--------|-------|
| Total Tasks | {tasks.length} |
| Pending (will create issues) | {tasksToConvert.length} |
| Completed (skipping) | {tasks.length - tasksToConvert.length} |

**Phases**: {unique phase count}
**User Stories**: {unique story marker count}
```

### Step 3: Create GitHub Issues
<!-- Implementation: T046 -->

Create a GitHub issue for each task using the gh CLI.

**3.1: Define label strategy**

Create labels for organizing issues. Labels will be created if they don't exist.

| Label Type | Format | Example | Color |
|------------|--------|---------|-------|
| Phase | `phase:{N}` | `phase:1`, `phase:2` | `0E8A16` (green) |
| Story | `story:{USN}` | `story:US1`, `story:US3` | `5319E7` (purple) |
| Parallel | `parallel` | `parallel` | `1D76DB` (blue) |
| Feature | `feature:{name}` | `feature:projspec-plugin` | `D93F0B` (red) |

**3.2: Create labels if they don't exist**

For each unique label needed, check if it exists and create if missing:

```bash
# Check if label exists
gh label list --search "{label_name}" --json name

# Create label if it doesn't exist
gh label create "{label_name}" --color "{color}" --description "{description}"
```

Example label creation:
```bash
gh label create "phase:1" --color "0E8A16" --description "Setup phase tasks"
gh label create "story:US1" --color "5319E7" --description "User Story 1"
gh label create "parallel" --color "1D76DB" --description "Can execute in parallel"
```

If label creation fails (already exists), continue without error.

**3.3: For each task, create a GitHub issue**

For each task in `tasksToConvert`, create an issue with the following structure:

**Issue Title Format:**
```
[{TaskID}] {Description}
```

Example: `[T044] Check gh CLI authentication status`

**Issue Body Template:**
```markdown
## Task Details

**Task ID**: {task.id}
**Phase**: Phase {task.phase.number}: {task.phase.name}
**Story**: {task.storyId or "N/A"}
**File**: `{task.filePath or "N/A"}`

## Description

{task.description}

## Context

This task is part of the **{featureMetadata.name}** feature.

### Phase Information

{task.phase.name}: {phase description if available}

### Dependencies

{if task has blockedBy dependencies}
This task is blocked by:
{for each blocker}
- #{blocker_issue_number} ([{blocker_id}] {blocker_description})
{end for}

{else}
No dependencies. This task can start immediately.
{end if}

### Parallel Execution

{if task.isParallel}
This task is marked as **parallel** and can be worked on simultaneously with other parallel tasks in the same phase.
{else}
This task should be completed sequentially.
{end if}

## Acceptance Criteria

- [ ] Implementation matches the task description
- [ ] Code follows project conventions
- [ ] Changes are tested
- [ ] Task checkbox in tasks.md is updated to `[x]`

---

*Generated by projspec `/issues` command*
*Source: {FEATURE_DIR}/tasks.md*
```

**3.4: Build the gh issue create command**

```bash
gh issue create \
  --title "[{task.id}] {task.description}" \
  --body "{issue_body}" \
  --label "phase:{task.phase.number}" \
  --label "feature:{feature_slug}" \
  {if task.storyId} --label "story:{task.storyId}" {end if} \
  {if task.isParallel} --label "parallel" {end if}
```

Example:
```bash
gh issue create \
  --title "[T044] Check gh CLI authentication status" \
  --body "$(cat <<'EOF'
## Task Details
...
EOF
)" \
  --label "phase:7" \
  --label "feature:projspec" \
  --label "story:US4"
```

**3.5: Capture issue creation results**

For each successful issue creation:
1. Parse the output to get the issue number and URL
2. Store the mapping between task ID and issue number

```
issueMapping = {
  "T044": { number: 1, url: "https://github.com/owner/repo/issues/1" },
  "T045": { number: 2, url: "https://github.com/owner/repo/issues/2" },
  ...
}
```

**3.6: Report progress during creation**

Display progress as issues are created:

```markdown
## Creating Issues

Creating issue 1/{total}: [T044] Check gh CLI authentication status
✓ Created issue #1: https://github.com/owner/repo/issues/1

Creating issue 2/{total}: [T045] Parse tasks.md and extract task details
✓ Created issue #2: https://github.com/owner/repo/issues/2

...

Progress: {created}/{total} issues created
```

**3.7: Handle issue creation errors**

If an issue creation fails:

```markdown
## Issue Creation Failed

**Task**: {task.id} - {task.description}
**Error**: {error_message}

**Possible causes:**
- Rate limiting (wait and retry)
- Network connectivity issues
- Repository permissions

**Options:**
1. **Retry** - Attempt to create this issue again
2. **Skip** - Skip this task and continue with remaining tasks
3. **Abort** - Stop issue creation and save progress

Progress so far: {created}/{total} issues created
```

Store partial progress for potential resume.

### Step 4: Add Dependency References Between Issues
<!-- Implementation: T047 -->

After all issues are created, update issues with cross-references to their dependencies.

**4.1: Build the dependency reference map**

Using the `dependencies` data from Step 2.4 and `issueMapping` from Step 3.5, create a map of issue cross-references:

```
for each task in tasksToConvert:
  if dependencies[task.id].blockedBy.length > 0:
    taskIssueNumber = issueMapping[task.id].number
    blockerIssueNumbers = []

    for each blockerId in dependencies[task.id].blockedBy:
      if issueMapping[blockerId]:
        blockerIssueNumbers.push(issueMapping[blockerId].number)

    if blockerIssueNumbers.length > 0:
      issueReferences[taskIssueNumber] = blockerIssueNumbers
```

**4.2: Add dependency comments to issues**

For each issue with dependencies, add a comment linking to the blocking issues:

```bash
gh issue comment {issue_number} --body "$(cat <<'EOF'
## Dependencies

This issue is blocked by:
{for each blocker_number in blockerIssueNumbers}
- Blocked by #{blocker_number}
{end for}

This issue cannot be started until all blocking issues are closed.
EOF
)"
```

Example:
```bash
gh issue comment 5 --body "## Dependencies

This issue is blocked by:
- Blocked by #3
- Blocked by #4

This issue cannot be started until all blocking issues are closed."
```

**4.3: Add "blocks" comments to blocker issues**

For each issue that blocks other issues, add a comment noting what it blocks:

```
reverseReferences = {}
for each [blockedIssue, blockers] in issueReferences:
  for each blocker in blockers:
    if not reverseReferences[blocker]:
      reverseReferences[blocker] = []
    reverseReferences[blocker].push(blockedIssue)

for each [blockerIssue, blockedIssues] in reverseReferences:
  gh issue comment {blockerIssue} --body "## Blocks

This issue blocks:
{for each blocked in blockedIssues}
- Blocks #{blocked}
{end for}

Complete this issue to unblock dependent work."
```

**4.4: Report dependency linking progress**

```markdown
## Linking Dependencies

Adding dependency references to issues...

✓ Issue #5: Added "Blocked by #3, #4" reference
✓ Issue #3: Added "Blocks #5, #6" reference
✓ Issue #4: Added "Blocks #5" reference

Dependency linking complete: {linked_count} issues updated
```

**4.5: Create a summary issue (optional)**

Create a tracking issue that provides an overview of all created issues:

```bash
gh issue create \
  --title "[Feature] {featureMetadata.name} - Task Tracker" \
  --body "$(cat <<'EOF'
# {featureMetadata.name} - Implementation Tasks

This issue tracks all tasks for the {featureMetadata.name} feature.

## Task Summary

| Task | Issue | Phase | Story | Status |
|------|-------|-------|-------|--------|
{for each task in tasksToConvert}
| {task.id} | #{issueMapping[task.id].number} | {task.phase.number} | {task.storyId or "-"} | Open |
{end for}

## Progress

- Total Issues: {tasksToConvert.length}
- Completed: 0
- Remaining: {tasksToConvert.length}

## Phase Breakdown

{for each phase in phases}
### Phase {phase.number}: {phase.name}
{for each task in phase.tasks}
- [ ] #{issueMapping[task.id].number} {task.description}
{end for}
{end for}

---

*Generated by projspec `/issues` command*
*Last updated: {timestamp}*
EOF
)" \
  --label "tracking" \
  --label "feature:{feature_slug}"
```

### Step 5: Error Handling
<!-- Implementation: T048 -->

Handle potential errors gracefully throughout the issue creation process.

**5.1: Rate limiting handling**

GitHub API has rate limits. When rate limiting is detected:

**Detection:**
Look for error messages containing:
- `API rate limit exceeded`
- `secondary rate limit`
- HTTP status 403 with rate limit headers

**Response:**
```markdown
## Rate Limit Reached

GitHub API rate limit has been reached.

**Progress saved**: {created}/{total} issues created
**Issues created**: #1 - #{last_created}
**Remaining**: {remaining_count} tasks

**Options:**

1. **Wait and Resume** - Rate limits typically reset within an hour
   - Run `/projspec.issues --resume` after the limit resets
   - Check rate limit status: `gh api rate_limit`

2. **Continue Later** - Progress has been saved
   - The next run will skip already-created issues
   - Use `--skip-existing` flag to avoid duplicates

**Rate Limit Info:**
```bash
gh api rate_limit --jq '.resources.core'
```
```

Save progress to a state file:
```
issueCreationState = {
  timestamp: "{current_time}",
  feature: "{featureMetadata.name}",
  repository: "{authContext.repository}",
  totalTasks: {total_count},
  createdIssues: [
    { taskId: "T044", issueNumber: 1 },
    { taskId: "T045", issueNumber: 2 },
    ...
  ],
  pendingTasks: ["T046", "T047", ...]
}
```

Write state to: `{FEATURE_DIR}/.issues-state.json`

**5.2: Network error handling**

When network errors occur:

**Detection:**
- Connection timeout
- DNS resolution failure
- SSL/TLS errors
- `ECONNREFUSED`, `ETIMEDOUT`, `ENOTFOUND`

**Response:**
```markdown
## Network Error

Failed to connect to GitHub API.

**Error**: {error_message}

**Troubleshooting:**
1. Check your internet connection
2. Verify GitHub status: https://www.githubstatus.com/
3. Check if you're behind a proxy or firewall

**Progress Saved**

Issues created before the error: {created_count}
Remaining tasks: {remaining_count}

Run `/projspec.issues --resume` to continue after resolving the network issue.
```

**5.3: Authentication expiration handling**

When authentication fails mid-process:

**Detection:**
- HTTP 401 Unauthorized
- Token expired errors
- `Bad credentials` message

**Response:**
```markdown
## Authentication Expired

Your GitHub authentication has expired or been revoked.

**Progress Saved**: {created}/{total} issues created

**To continue:**

1. Re-authenticate with GitHub:
   ```bash
   gh auth login
   ```

2. Resume issue creation:
   ```bash
   # Run the issues command again
   /projspec.issues --resume
   ```

The command will skip already-created issues and continue with remaining tasks.
```

**5.4: Partial completion status reporting**

When the command is interrupted or fails partway through:

```markdown
## Partial Completion Report

Issue creation was interrupted. Progress has been saved.

### Summary

| Metric | Count |
|--------|-------|
| Total Tasks | {total_count} |
| Issues Created | {created_count} |
| Issues Remaining | {remaining_count} |
| Issues Failed | {failed_count} |

### Created Issues

| Task ID | Issue # | URL |
|---------|---------|-----|
{for each created in issueMapping}
| {created.taskId} | #{created.number} | {created.url} |
{end for}

### Pending Tasks

The following tasks still need issues created:
{for each pending in pendingTasks}
- {pending.id}: {pending.description}
{end for}

{if failed_count > 0}
### Failed Tasks

The following tasks failed to create issues:
{for each failed in failedTasks}
- {failed.id}: {failed.error}
{end for}
{end if}

### Resume Instructions

To continue creating issues, run:

```
/projspec.issues --resume
```

This will:
1. Load the saved progress from `.issues-state.json`
2. Skip already-created issues
3. Retry failed tasks
4. Continue with pending tasks
```

**5.5: Save progress for resume**

Write progress to state file after each successful issue creation:

```bash
# State file location
STATE_FILE="${FEATURE_DIR}/.issues-state.json"

# State structure
{
  "version": "1.0",
  "timestamp": "2024-01-15T10:30:00Z",
  "feature": "{featureMetadata.name}",
  "repository": "{authContext.repository}",
  "status": "in_progress" | "completed" | "failed",
  "progress": {
    "total": {total_count},
    "created": {created_count},
    "failed": {failed_count},
    "pending": {pending_count}
  },
  "issueMapping": {
    "T044": { "number": 1, "url": "..." },
    "T045": { "number": 2, "url": "..." }
  },
  "pendingTasks": ["T046", "T047", ...],
  "failedTasks": [
    { "taskId": "T048", "error": "Rate limit exceeded", "retryCount": 1 }
  ],
  "labelsCreated": ["phase:1", "phase:2", "story:US4", ...]
}
```

**5.6: Resume from saved progress**

When `--resume` flag is provided:

1. Check if state file exists:
   ```bash
   if [ -f "${FEATURE_DIR}/.issues-state.json" ]; then
     # Load state
   else
     # No state file, start fresh
   fi
   ```

2. Load and validate state:
   ```
   state = JSON.parse(readFile(STATE_FILE))

   # Verify state matches current context
   if state.repository != authContext.repository:
     error("State file is for a different repository")

   if state.feature != featureMetadata.name:
     error("State file is for a different feature")
   ```

3. Resume from last position:
   ```
   # Mark created issues as complete
   completedTaskIds = Object.keys(state.issueMapping)

   # Filter remaining tasks
   remainingTasks = tasksToConvert.filter(t => !completedTaskIds.includes(t.id))

   # Use existing issue mapping
   issueMapping = state.issueMapping

   # Continue with Step 3.3 for remaining tasks
   ```

4. Report resume status:
   ```markdown
   ## Resuming Issue Creation

   Loaded progress from previous run.

   **Previous Progress**: {state.progress.created}/{state.progress.total} issues
   **Remaining**: {remainingTasks.length} tasks

   Continuing from task {remainingTasks[0].id}...
   ```

**5.7: Duplicate issue detection**

Before creating an issue, check if one already exists:

```bash
gh issue list --search "[{task.id}]" --json number,title --limit 1
```

If a matching issue exists:
```
# Parse result
existingIssue = JSON.parse(result)

if existingIssue.length > 0 and existingIssue[0].title.includes(task.id):
  # Issue already exists
  issueMapping[task.id] = { number: existingIssue[0].number, url: "..." }
  report("Skipping {task.id} - issue #{existingIssue[0].number} already exists")
  continue to next task
```

Report duplicate detection:
```markdown
## Duplicate Issue Found

Task {task.id} already has an existing issue: #{existing_number}

Skipping creation and using existing issue for dependency linking.
```

## Output

Upon successful completion, this command produces:

### GitHub Artifacts

| Artifact | Description |
|----------|-------------|
| Issues | One GitHub issue per pending task with title format `[T###] Description` |
| Labels | Phase, story, parallel, and feature labels created as needed |
| Comments | Dependency references added as comments on issues |
| Tracking Issue | Optional summary issue linking all created issues |

### Local Artifacts

| File | Description |
|------|-------------|
| `.issues-state.json` | Progress state file for resume capability (in FEATURE_DIR) |

### Console Output

| Output | When Displayed |
|--------|----------------|
| Authentication status | At command start |
| Task analysis summary | After parsing tasks.md |
| Issue creation progress | During issue creation |
| Dependency linking status | After all issues created |
| Final summary | On completion or interruption |

### Final Summary Output

```markdown
## Issue Creation Complete

✓ Successfully created {created_count} GitHub issues

**Repository**: {authContext.repository}
**Feature**: {featureMetadata.name}

### Issue Summary

| Phase | Issues Created |
|-------|----------------|
| Phase 1: Setup | {count} |
| Phase 2: Foundational | {count} |
| Phase 3: {Story Name} | {count} |
| ... | ... |

### Created Issues

| Task | Issue | Labels |
|------|-------|--------|
| T044 | [#1](url) | phase:7, story:US4 |
| T045 | [#2](url) | phase:7, story:US4 |
| ... | ... | ... |

### Dependency Links

{count} dependency references added across {linked_issues} issues.

### Next Steps

View all issues:
  {authContext.repositoryUrl}/issues?q=label:feature:{feature_slug}

View project board (if configured):
  {authContext.repositoryUrl}/projects

---

*State saved to: {FEATURE_DIR}/.issues-state.json*
*Run `/projspec.issues --resume` to resume if interrupted*
```

## Usage

```
/projspec.issues [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--resume` | Resume from a previous interrupted run |
| `--include-completed` | Also create issues for completed tasks |
| `--dry-run` | Show what would be created without creating issues |
| `--no-dependencies` | Skip adding dependency comments |
| `--no-tracking-issue` | Skip creating the summary tracking issue |

## Notes

- Issues are created in task order (by phase and task ID)
- Completed tasks are skipped by default
- Progress is saved after each issue creation for resume capability
- Labels are created automatically if they don't exist
- Duplicate issues are detected and skipped
- Rate limiting is handled gracefully with save/resume support

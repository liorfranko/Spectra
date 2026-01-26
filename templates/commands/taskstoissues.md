# Command: taskstoissues

## Purpose

Convert tasks from an existing tasks.md file into actionable GitHub issues with proper dependency links, labels, and structured formatting. This command transforms your local task planning into a collaborative GitHub-tracked workflow.

The conversion process:
1. Reads the existing tasks.md to extract all tasks
2. Creates a parent issue for the feature as a tracking hub
3. Converts each task into a GitHub issue with title, body, labels, and metadata
4. Establishes dependency relationships using issue references
5. Reports all created issues with their numbers and URLs

---

## Prerequisites

Before running this command, verify the following:

1. **Existing tasks.md**: The feature must have a tasks.md file already created (via the `tasks` command)
2. **GitHub CLI installed**: The `gh` CLI tool must be installed and authenticated
   - Verify with: `gh auth status`
   - If not authenticated: `gh auth login`
3. **GitHub repository exists**: The project must be a git repository with a configured GitHub remote
   - Verify with: `git remote -v`
4. **Network connectivity**: Internet access is required to create GitHub issues
5. **Repository write access**: The authenticated user must have permission to create issues in the repository
6. **Feature context loaded**: You should be in the feature's worktree or have the feature context loaded

If prerequisites are not met, inform the user:
- If no tasks.md exists, suggest running the `tasks` command first
- If `gh` is not installed, provide installation instructions for their platform
- If `gh` is not authenticated, guide them through `gh auth login`
- If no GitHub remote exists, guide them to add one with `git remote add origin <url>`

---

## Workflow

Follow these steps in order:

### Step 1: Verify Prerequisites

Before proceeding, verify all prerequisites are met:

```bash
# Check GitHub CLI is installed
gh --version

# Check GitHub CLI is authenticated
gh auth status

# Check repository has GitHub remote
git remote -v | grep github
```

If any check fails, stop and provide guidance to resolve the issue.

### Step 2: Locate and Read tasks.md

Find and read the tasks.md for the current feature:

1. Check the current directory for tasks.md
2. Check `specs/{feature-slug}/tasks.md`
3. Check `.specify/features/{feature-slug}/tasks.md`

Parse the tasks.md to extract:
- Feature name and branch information
- All tasks with their metadata:
  - Task ID (e.g., T001, T002)
  - Title
  - Status
  - Priority (P1, P2, P3)
  - Estimated effort (XS, S, M, L, XL)
  - Dependencies (references to other task IDs)
  - Description
  - Acceptance criteria
  - Files to create/modify
  - Notes

Store all extracted tasks in memory for processing.

### Step 3: Determine Repository Information

Extract repository owner and name for `gh` commands:

```bash
# Get repository info
gh repo view --json owner,name
```

Store the `owner` and `name` values for use in subsequent commands.

### Step 4: Create Parent Feature Issue

Create a parent issue to serve as a tracking hub for all task issues:

**Issue Title Format**:
```
[FEATURE] {Feature Name}
```

**Issue Body Template**:
```markdown
## Feature: {Feature Name}

**Branch**: `{branch-name}`
**Spec**: [spec.md](./specs/{feature-slug}/spec.md) (if exists)
**Plan**: [plan.md](./specs/{feature-slug}/plan.md) (if exists)
**Tasks**: [tasks.md](./specs/{feature-slug}/tasks.md)

---

## Overview

{Brief description from tasks.md or spec.md if available}

---

## Task Checklist

This issue tracks the implementation of the following tasks:

- [ ] #{ISSUE_NUMBER}: [T001] {Task Title}
- [ ] #{ISSUE_NUMBER}: [T002] {Task Title}
- [ ] #{ISSUE_NUMBER}: [T003] {Task Title}
...

---

## Progress

| Phase | Tasks | Completed |
|-------|-------|-----------|
| Phase 1: {Name} | {N} | 0 |
| Phase 2: {Name} | {N} | 0 |
| **Total** | **{N}** | **0** |

---

_This issue was auto-generated from tasks.md by ProjSpec._
```

**Command**:
```bash
gh issue create \
  --title "[FEATURE] {Feature Name}" \
  --body "{body content}" \
  --label "feature,tracking"
```

**Note**: The parent issue body will be updated after all task issues are created to include the correct issue numbers in the checklist.

Store the created parent issue number for reference.

### Step 5: Create Task Issues (Dependency-Ordered)

Process tasks in dependency order to ensure blocking issues exist before dependent issues:

#### Dependency Resolution Algorithm

1. Build a dependency graph from task references
2. Topologically sort tasks so dependencies come before dependents
3. Process tasks in sorted order
4. Track created issue numbers for dependency linking

#### For Each Task, Create an Issue

**Issue Title Format**:
```
[{TASK_ID}] {Task Title}
```

**Issue Body Template**:
```markdown
## Task: {Task Title}

**Task ID**: {TASK_ID}
**Priority**: {P1|P2|P3}
**Effort**: {XS|S|M|L|XL}
**Phase**: {Phase Name}

---

## Description

{Detailed task description from tasks.md}

---

## Acceptance Criteria

- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] {Criterion 3}

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `{file_path_1}` | {What to do} |
| `{file_path_2}` | {What to do} |

---

## Dependencies

{If no dependencies}
No dependencies - this task can start immediately.

{If has dependencies}
This task depends on:
- #{ISSUE_NUMBER} [T{NNN}] {Blocked task title}
- #{ISSUE_NUMBER} [T{NNN}] {Blocked task title}

---

## Notes

{Implementation notes from tasks.md}

---

## Context

- **Feature Issue**: #{PARENT_ISSUE_NUMBER}
- **User Stories**: {US references if available}
- **Requirements**: {FR/NFR references if available}

---

_Part of [Feature: {Feature Name}](#{PARENT_ISSUE_NUMBER})_
_Generated from tasks.md by ProjSpec_
```

**Determine Labels**:

Based on task metadata, apply appropriate labels:

| Priority | Label |
|----------|-------|
| P1 | `priority:high` |
| P2 | `priority:medium` |
| P3 | `priority:low` |

| Effort | Label |
|--------|-------|
| XS, S | `effort:small` |
| M | `effort:medium` |
| L, XL | `effort:large` |

Additional labels based on phase or task type:
- `phase:1`, `phase:2`, etc.
- `setup`, `implementation`, `testing`, `documentation` (if discernible from task title/description)

**Create Issue Command**:
```bash
gh issue create \
  --title "[{TASK_ID}] {Task Title}" \
  --body "{body content}" \
  --label "task,priority:{level},effort:{size},phase:{n}"
```

**Record the Issue Number**:
After each issue is created, record the mapping:
- `T001 -> #123`
- `T002 -> #124`
- etc.

### Step 6: Update Parent Issue with Task Links

After all task issues are created, update the parent feature issue to include the correct issue numbers in the task checklist:

**Update Command**:
```bash
gh issue edit {PARENT_ISSUE_NUMBER} --body "{updated body with issue links}"
```

The checklist should now show:
```markdown
- [ ] #123: [T001] {Task Title}
- [ ] #124: [T002] {Task Title}
- [ ] #125: [T003] {Task Title}
```

### Step 7: Handle Network Failures Gracefully

If a network failure occurs during issue creation:

#### Failure During Task Issue Creation

1. **Record progress**: Track which issues were successfully created
2. **Log the failure**: Note which task failed and the error message
3. **Provide recovery information**:

```
Issue creation failed for task {TASK_ID}: {Error message}

Successfully created issues:
- T001 -> #123
- T002 -> #124

Remaining tasks to create:
- T003: {Task Title}
- T004: {Task Title}

To retry, run the command again. Already-created issues will be detected and skipped.
```

#### Retry Logic

Before creating an issue, check if it already exists:

```bash
# Search for existing issue with task ID in title
gh issue list --search "[{TASK_ID}]" --json number,title
```

If found, skip creation and use the existing issue number.

#### Timeout Handling

For long-running operations, implement reasonable timeouts:
- Individual issue creation: 30 seconds
- Overall operation: 10 minutes for up to 50 tasks

If timeout occurs, follow the same recovery procedure as network failures.

### Step 8: Present Results

After all issues are created, present a summary:

```
## GitHub Issues Created Successfully

### Parent Issue
- #{PARENT_NUMBER}: [FEATURE] {Feature Name}
  URL: https://github.com/{owner}/{repo}/issues/{PARENT_NUMBER}

### Task Issues

| Task | Issue | Title | Labels |
|------|-------|-------|--------|
| T001 | #123 | {Title} | priority:high, effort:small |
| T002 | #124 | {Title} | priority:high, effort:medium |
| T003 | #125 | {Title} | priority:medium, effort:small |

### Dependency Graph (as GitHub Links)

#123 ──┬──> #124 ──> #126
       │
       └──> #125 ──> #127

### Quick Links

- Feature Overview: https://github.com/{owner}/{repo}/issues/{PARENT_NUMBER}
- All Feature Tasks: https://github.com/{owner}/{repo}/issues?q=label:feature-{id}
- Project Board: {if applicable}

### Next Steps

1. Review created issues on GitHub
2. Assign team members to tasks
3. Add issues to a project board if using GitHub Projects
4. Begin implementation with the first unblocked task (#123)
```

---

## Output

Upon successful completion, the following will be created:

### GitHub Issues Created

| Issue Type | Count | Description |
|------------|-------|-------------|
| Feature Issue | 1 | Parent tracking issue for the feature |
| Task Issues | {N} | Individual issues for each task from tasks.md |

### Issue Structure

Each task issue will contain:
- Formatted title with task ID
- Complete description with acceptance criteria
- Priority and effort labels
- Dependency links to blocking issues
- Reference back to parent feature issue
- Files to create/modify list
- Implementation notes

### Dependency Tracking

- GitHub issue references (e.g., "Depends on #123") link tasks
- Parent issue contains a checklist of all task issues
- Labels enable filtering by priority, effort, and phase

### Local Artifacts

No local files are modified. The tasks.md remains unchanged as the source of truth.

---

## Examples

### Example 1: Standard Task Conversion

**Scenario**: tasks.md has 8 tasks across 3 phases with various dependencies.

**Actions**:
1. Verify `gh` is authenticated and repository exists
2. Parse tasks.md extracting all 8 tasks
3. Create parent issue: `[FEATURE] User Authentication`
4. Topologically sort tasks by dependencies
5. Create T001, T002, T003 (no dependencies) first
6. Create T004, T005 (depend on T001-T003)
7. Create T006, T007, T008 (depend on T004-T005)
8. Update parent issue with complete checklist
9. Present summary with all issue URLs

**Result**:
```
Created 9 GitHub issues:
- #100: [FEATURE] User Authentication (parent)
- #101: [T001] Set up authentication module structure
- #102: [T002] Implement password hashing service
- #103: [T003] Create user model schema
- #104: [T004] Implement login endpoint (depends on #101, #102, #103)
- #105: [T005] Implement logout endpoint (depends on #101)
- #106: [T006] Add session management (depends on #104)
- #107: [T007] Write authentication tests (depends on #104, #105)
- #108: [T008] Document authentication API (depends on #106, #107)
```

### Example 2: Network Failure Recovery

**Scenario**: Network fails after creating 5 of 8 task issues.

**Actions**:
1. Detect network error on task T006
2. Record successfully created issues (T001-T005)
3. Present recovery information
4. User runs command again
5. Command detects existing issues via search
6. Skips T001-T005, resumes with T006-T008
7. Completes remaining issues
8. Updates parent issue

**Result**:
```
Resuming issue creation (5 already exist):
- T001 -> #101 (existing)
- T002 -> #102 (existing)
- T003 -> #103 (existing)
- T004 -> #104 (existing)
- T005 -> #105 (existing)
- T006 -> #106 (created)
- T007 -> #107 (created)
- T008 -> #108 (created)

All issues created successfully.
```

### Example 3: Labels Not Pre-existing

**Scenario**: Repository doesn't have the required labels (priority:high, effort:small, etc.).

**Actions**:
1. Attempt to create issue with labels
2. If label creation fails, create without labels and warn user
3. Provide commands to create missing labels

**Result**:
```
Note: Some labels don't exist in the repository. Issues were created without them.

To create the missing labels, run:
gh label create "priority:high" --color "d73a4a" --description "High priority task"
gh label create "priority:medium" --color "fbca04" --description "Medium priority task"
gh label create "priority:low" --color "0e8a16" --description "Low priority task"
gh label create "effort:small" --color "c5def5" --description "Small effort (< 2 hours)"
gh label create "effort:medium" --color "bfd4f2" --description "Medium effort (2-4 hours)"
gh label create "effort:large" --color "d4c5f9" --description "Large effort (> 4 hours)"

Then update the issues with labels:
gh issue edit #101 --add-label "priority:high,effort:small"
```

---

## Error Handling

### Common Issues

1. **No tasks.md found**: Guide user to run `tasks` command first
2. **gh not installed**: Provide installation instructions
   - macOS: `brew install gh`
   - Linux: `sudo apt install gh` or equivalent
   - Windows: `winget install GitHub.cli`
3. **gh not authenticated**: Guide through `gh auth login`
4. **No GitHub remote**: Guide to add remote or push to GitHub
5. **No write permission**: Explain that user needs write access to create issues
6. **Network timeout**: Provide retry instructions and progress summary
7. **Rate limiting**: Wait and retry, or suggest creating issues in batches

### Recovery Steps

If the command fails partway through:

1. **Check created issues**: List what was successfully created
   ```bash
   gh issue list --search "[T0" --json number,title
   ```
2. **Resume from failure point**: Re-run the command; it will skip existing issues
3. **Manual cleanup if needed**: Delete incorrectly created issues
   ```bash
   gh issue delete {number} --yes
   ```

### Validation Before Proceeding

Before creating issues, validate:
- [ ] tasks.md exists and is parseable
- [ ] At least one task is defined
- [ ] Task IDs are unique
- [ ] Dependencies reference existing task IDs
- [ ] No circular dependencies exist

If validation fails, report errors and do not proceed.

---

## Notes

- **Idempotent design**: Running the command multiple times is safe; existing issues are detected and skipped
- **Dependency order matters**: Always process tasks in topological order to ensure blocking issues exist first
- **Labels are optional**: Issues can be created without labels if repository doesn't have them configured
- **Parent issue as hub**: The feature issue serves as a central tracking point; keep it updated as tasks complete
- **Local tasks.md unchanged**: This command only creates GitHub issues; it does not modify local files
- **Rate limits**: GitHub API has rate limits; for large task lists (50+), the command may need to pause
- **Branch references**: Issue bodies can link to branches for easy navigation
- **Markdown formatting**: All issue bodies use GitHub-Flavored Markdown for proper rendering
- **Issue templates**: If the repository has issue templates, this command bypasses them to ensure consistent formatting

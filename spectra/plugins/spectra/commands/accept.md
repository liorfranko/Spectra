---
description: "Validate feature readiness before merging to main - checks all tasks complete, runs quality gates, and confirms acceptance criteria"
user-invocable: true
argument-hint: "[--lenient] [--skip-tests]"
---

# Accept Command

Validate that a feature is ready for merge by checking task completion, running quality gates, and confirming all acceptance criteria are met. This is the final gate before `/spectra:merge`.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Arguments

Parse `$ARGUMENTS` for optional flags:
- `--lenient` - Skip strict metadata validation (allows merge with minor issues)
- `--skip-tests` - Skip test execution (not recommended)
- `--actor <name>` - Name to record as the acceptance actor (defaults to git user.name)

## Prerequisites

- Must be on a feature branch (pattern: `[###]-[short-name]`)
- Feature directory must exist in `specs/[###]-[short-name]/`
- tasks.md must exist with task checkboxes

## Workflow

### Step 1: Gather Context

**1.1: Run prerequisites check**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --json --require-tasks --include-tasks
```

Parse the JSON response to get:
- `FEATURE_DIR` - Path to feature specification directory
- `AVAILABLE_DOCS` - List of available documents
- `TASKS_CONTENT` - Content of tasks.md

**1.2: Get git context**

```bash
# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get base branch
BASE_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5 || echo "main")

# Get commit count on this branch
COMMIT_COUNT=$(git rev-list --count ${BASE_BRANCH}..HEAD 2>/dev/null || echo "0")

# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain)

# Get worktree info if applicable
WORKTREE_PATH=$(git worktree list --porcelain | grep "worktree" | head -1 | cut -d' ' -f2)
```

**1.3: Report acceptance context**

```markdown
## Acceptance Validation

**Feature:** {CURRENT_BRANCH}
**Spec Directory:** {FEATURE_DIR}
**Commits:** {COMMIT_COUNT}
**Base Branch:** {BASE_BRANCH}

Starting validation checks...
```

### Step 2: Task Completion Check

**2.1: Parse tasks.md and count task status**

Read tasks.md and extract all task checkboxes:
- `- [X]` or `- [x]` = Completed
- `- [ ]` = Incomplete

```
taskStatus = {
  total: 0,
  completed: 0,
  incomplete: 0,
  incompleteList: []  // List of incomplete task IDs and descriptions
}
```

**2.2: Report task status**

```markdown
### Task Completion

| Status | Count |
|--------|-------|
| Completed | {completed} |
| Incomplete | {incomplete} |
| **Total** | **{total}** |

{If incomplete > 0:}
**Incomplete Tasks:**
{For each incomplete task:}
- [ ] {task_id}: {task_description}
{End for}

> **Warning:** {incomplete} task(s) are not marked complete.
> These must be completed before acceptance.
{End if}

{If incomplete == 0:}
All {total} tasks are complete.
{End if}
```

**2.3: Fail if tasks incomplete (unless --lenient)**

If `taskStatus.incomplete > 0` and NOT `--lenient`:
```markdown
## Acceptance Failed

**Reason:** {incomplete} task(s) not completed.

Complete the remaining tasks and run `/spectra:accept` again.
```
**STOP execution.**

### Step 3: Document Completeness Check

**3.1: Verify required documents exist**

Required documents:
- `spec.md` - Feature specification
- `plan.md` - Implementation plan
- `tasks.md` - Task breakdown

Optional but recommended:
- `data-model.md` - Data structures
- `research.md` - Technical research
- `contracts/` - API contracts

**3.2: Check for unresolved markers**

Search for markers that indicate incomplete work:
- `NEEDS CLARIFICATION`
- `TODO:`
- `FIXME:`
- `XXX:`
- `[TBD]`
- `???`

```bash
# Search for unresolved markers in spec documents
grep -rn "NEEDS CLARIFICATION\|TODO:\|FIXME:\|XXX:\|\\[TBD\\]\|???" ${FEATURE_DIR}/*.md 2>/dev/null || echo ""
```

**3.3: Report document status**

```markdown
### Document Completeness

| Document | Status | Notes |
|----------|--------|-------|
| spec.md | {EXISTS/MISSING} | {notes} |
| plan.md | {EXISTS/MISSING} | {notes} |
| tasks.md | {EXISTS/MISSING} | {notes} |
| data-model.md | {EXISTS/OPTIONAL} | {notes} |
| research.md | {EXISTS/OPTIONAL} | {notes} |
| contracts/ | {EXISTS/OPTIONAL} | {notes} |

{If unresolved markers found:}
**Unresolved Markers Found:**
{For each marker:}
- `{file}:{line}` - {marker_text}
{End for}

> **Warning:** Unresolved markers indicate incomplete work.
{End if}
```

### Step 4: Git State Validation

**4.1: Check for uncommitted changes**

```bash
git status --porcelain
```

If output is not empty:
```markdown
### Git State

**Warning:** Uncommitted changes detected:
```
{git status output}
```

These changes should be committed before acceptance.
```

**4.2: Check branch is up to date with remote**

```bash
git fetch origin ${CURRENT_BRANCH} 2>/dev/null
LOCAL=$(git rev-parse ${CURRENT_BRANCH})
REMOTE=$(git rev-parse origin/${CURRENT_BRANCH} 2>/dev/null || echo "")
```

If LOCAL != REMOTE and REMOTE is not empty:
```markdown
**Warning:** Local branch differs from remote.
Run `git push` to sync changes.
```

**4.3: Check for merge conflicts with base**

```bash
# Check if merge would have conflicts
git merge-tree $(git merge-base HEAD ${BASE_BRANCH}) HEAD ${BASE_BRANCH} 2>/dev/null | grep -q "^<<<<<<<" && echo "conflicts" || echo "clean"
```

If conflicts:
```markdown
**Warning:** Potential merge conflicts detected with {BASE_BRANCH}.
Consider rebasing or resolving conflicts before merge.
```

### Step 5: Quality Gate Checks (Optional)

**5.1: Run tests if available (unless --skip-tests)**

Detect test framework and run tests:

```bash
# Detect test framework
if [[ -f "package.json" ]]; then
  # Node.js project
  if grep -q '"test"' package.json; then
    npm test
  fi
elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
  # Python project
  if command -v pytest &>/dev/null; then
    pytest
  elif command -v python &>/dev/null; then
    python -m pytest
  fi
elif [[ -f "Cargo.toml" ]]; then
  # Rust project
  cargo test
elif [[ -f "go.mod" ]]; then
  # Go project
  go test ./...
fi
```

**5.2: Report test results**

```markdown
### Quality Gates

| Check | Status | Details |
|-------|--------|---------|
| Tests | {PASS/FAIL/SKIPPED} | {details} |
| Lint | {PASS/FAIL/SKIPPED} | {details} |
| Build | {PASS/FAIL/SKIPPED} | {details} |

{If any failed:}
> **Error:** Quality gates failed. Fix issues before acceptance.
{End if}
```

### Step 6: Generate Acceptance Summary

**6.1: Calculate acceptance score**

```
acceptanceScore = {
  tasksComplete: taskStatus.incomplete == 0,
  docsComplete: requiredDocsExist && unresolvedMarkers.length == 0,
  gitClean: uncommittedChanges.length == 0,
  testsPass: testsPassed || testsSkipped,
  noConflicts: !hasConflicts
}

readyForMerge = all values are true (or --lenient mode)
```

**6.2: Generate final report**

```markdown
## Acceptance Summary

**Feature:** {CURRENT_BRANCH}
**Date:** {current_date}
**Actor:** {actor_name or git user.name}

### Validation Results

| Check | Status | Required |
|-------|--------|----------|
| Tasks Complete | {PASS/FAIL} | Yes |
| Documents Complete | {PASS/FAIL} | Yes |
| Git State Clean | {PASS/WARN} | Recommended |
| Tests Pass | {PASS/FAIL/SKIP} | {Yes/No} |
| No Merge Conflicts | {PASS/WARN} | Recommended |

{If readyForMerge:}
---

## Ready for Merge

All acceptance criteria passed. The feature is ready to merge.

**Next Step:** Run `/spectra:merge` to merge this feature into {BASE_BRANCH}.

```bash
# Quick merge command
/spectra:merge
```

{Else:}
---

## Not Ready for Merge

The following issues must be resolved:

{For each failed check:}
- {check_name}: {failure_reason}
{End for}

**Actions Required:**
{For each action:}
1. {action_description}
{End for}

After resolving issues, run `/spectra:accept` again.
{End if}
```

### Step 7: Record Acceptance (if passed)

**7.1: Create acceptance record (optional)**

If acceptance passed, optionally record in a structured format:

```markdown
<!-- ACCEPTANCE RECORD -->
<!--
  feature: {CURRENT_BRANCH}
  accepted_at: {ISO timestamp}
  accepted_by: {actor}
  tasks_completed: {completed}/{total}
  commits: {commit_count}
-->
```

This can be appended to tasks.md or stored separately.

## Output

### Console Output

| Output | When Displayed |
|--------|----------------|
| Context info | At command start |
| Task status | After task parsing |
| Document check | After doc validation |
| Git state | After git checks |
| Quality gates | After test execution |
| Final summary | At command end |

### Exit Conditions

| Condition | Behavior |
|-----------|----------|
| All checks pass | Report success, recommend `/spectra:merge` |
| Tasks incomplete | Fail (unless --lenient) |
| Tests fail | Fail (unless --skip-tests) |
| Unresolved markers | Warn (fail unless --lenient) |
| Uncommitted changes | Warn |
| Merge conflicts | Warn |

## Usage

```
/spectra:accept [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--lenient` | Allow acceptance with warnings (not recommended) |
| `--skip-tests` | Skip test execution |
| `--actor <name>` | Name to record as acceptor |

### Examples

```bash
# Standard acceptance check
/spectra:accept

# Lenient mode (allows minor issues)
/spectra:accept --lenient

# Skip test execution
/spectra:accept --skip-tests

# Specify actor name
/spectra:accept --actor "John Doe"
```

## Notes

- This command is a gate before `/spectra:merge`
- All tasks should be marked complete [X] before acceptance
- Unresolved markers (TODO, FIXME, etc.) indicate incomplete work
- Tests are run if a recognized test framework is detected
- Use `--lenient` sparingly - it allows merging with known issues
- Acceptance status can be used in CI/CD pipelines

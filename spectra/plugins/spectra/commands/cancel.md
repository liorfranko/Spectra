---
description: "Cancel and clean up a feature spec that you decided not to develop"
user-invocable: true
argument-hint: "[--delete] [--keep-spec] [--force]"
---

# Cancel Command

Cancel a feature that you decided not to develop. This command cleans up the associated git branch, worktree, and optionally the spec files.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Arguments

Parse `$ARGUMENTS` for optional flags:
- `--delete` - Delete the spec files (default: keep them)
- `--keep-spec` - Explicitly keep spec files (default behavior)
- `--force` - Skip confirmation prompts
- `--reason <text>` - Record reason for cancellation

## Prerequisites

- Must be on a feature branch (pattern: `[###]-[short-name]`) OR specify feature ID
- Feature directory should exist in `specs/[###]-[short-name]/`

## Workflow

### Step 1: Identify Feature to Cancel

**1.1: Get current context**

```bash
# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get repo root
REPO_ROOT=$(git rev-parse --show-toplevel)

# Check if on feature branch
if [[ "$CURRENT_BRANCH" =~ ^([0-9]{3}-[a-z0-9-]+) ]]; then
  FEATURE_ID="${BASH_REMATCH[1]}"
else
  FEATURE_ID=""
fi

# Get base branch
BASE_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5 || echo "main")
```

**1.2: Validate feature exists**

If not on a feature branch and no feature ID provided:
```markdown
**Error:** Not on a feature branch.

Either:
1. Checkout the feature branch: `git checkout [feature-branch]`
2. Navigate to the feature worktree: `cd worktrees/[feature-id]`

Then run `/spectra:cancel` again.
```
**STOP execution.**

**1.3: Gather feature information**

```bash
# Find spec directory
SPEC_DIR="${REPO_ROOT}/specs/${FEATURE_ID}"

# Check for worktree
WORKTREE_PATH=$(git worktree list | grep "${FEATURE_ID}" | awk '{print $1}')

# Check for remote branch
REMOTE_EXISTS=$(git ls-remote --heads origin "${FEATURE_ID}" 2>/dev/null | wc -l)

# Count commits on branch
COMMIT_COUNT=$(git rev-list --count ${BASE_BRANCH}..HEAD 2>/dev/null || echo "0")

# Check for uncommitted changes
HAS_CHANGES=$(git status --porcelain | wc -l)
```

**1.4: Report cancellation scope**

```markdown
## Cancel Feature

**Feature:** {FEATURE_ID}
**Branch:** {CURRENT_BRANCH}
**Spec Directory:** {SPEC_DIR}

### Current State

| Resource | Status | Action |
|----------|--------|--------|
| Local branch | {EXISTS} | Will delete |
| Remote branch | {EXISTS/NONE} | {Will delete/N/A} |
| Worktree | {path or NONE} | {Will remove/N/A} |
| Spec files | {EXISTS/NONE} | {Will keep/Will delete} |
| Uncommitted changes | {count} | {Will be lost!} |
| Commits | {count} | Will be discarded |

{If HAS_CHANGES > 0:}
> **Warning:** You have uncommitted changes that will be lost!
{End if}

{If COMMIT_COUNT > 0:}
> **Note:** {COMMIT_COUNT} commit(s) will be discarded.
{End if}
```

### Step 2: Confirm Cancellation

**2.1: Prompt for confirmation (unless --force)**

If not `--force`:

Use AskUserQuestion:
```yaml
question: "Are you sure you want to cancel feature '{FEATURE_ID}'?"
header: "Confirm"
options:
  - label: "Yes, cancel and cleanup"
    description: "Delete branch/worktree, keep spec files for reference"
  - label: "Yes, delete everything"
    description: "Delete branch, worktree, AND spec files"
  - label: "No, abort"
    description: "Keep everything, don't cancel"
```

Based on response:
- Option 1: Set `DELETE_SPEC=false`
- Option 2: Set `DELETE_SPEC=true`
- Option 3: **STOP execution** with "Cancellation aborted."

**2.2: Record cancellation reason (optional)**

If `--reason` not provided and there are spec files:

Use AskUserQuestion:
```yaml
question: "Would you like to record a reason for cancellation?"
header: "Reason"
options:
  - label: "Skip"
    description: "Don't record a reason"
  - label: "No longer needed"
    description: "Requirements changed or feature deprecated"
  - label: "Technical blocker"
    description: "Cannot be implemented as specified"
  - label: "Deprioritized"
    description: "Moving to backlog for later consideration"
```

### Step 3: Switch to Safe Branch

**3.1: Stash or discard uncommitted changes**

```bash
{If HAS_CHANGES > 0:}
# Discard all uncommitted changes
git checkout -- .
git clean -fd
{End if}
```

**3.2: Switch to base branch**

```bash
# If in worktree, navigate to main repo first
{If in worktree:}
cd "${MAIN_REPO_PATH}"
{End if}

# Checkout base branch
git checkout ${BASE_BRANCH}
git pull origin ${BASE_BRANCH}
```

### Step 4: Clean Up Resources

**4.1: Remove worktree (if exists)**

```bash
{If WORKTREE_PATH exists:}
git worktree remove "${WORKTREE_PATH}" --force
echo "Removed worktree: ${WORKTREE_PATH}"
{End if}
```

**4.2: Delete local branch**

```bash
# Force delete since we're abandoning the work
git branch -D "${FEATURE_ID}"
echo "Deleted local branch: ${FEATURE_ID}"
```

**4.3: Delete remote branch (if exists)**

```bash
{If REMOTE_EXISTS > 0:}
git push origin --delete "${FEATURE_ID}"
echo "Deleted remote branch: origin/${FEATURE_ID}"
{End if}
```

**4.4: Handle spec files**

```bash
{If DELETE_SPEC == true AND spec directory exists:}
# Delete spec directory
rm -rf "${SPEC_DIR}"
echo "Deleted spec directory: ${SPEC_DIR}"
git add -A
git commit -m "chore: Remove cancelled feature ${FEATURE_ID}

Reason: ${REASON:-Not specified}

Co-Authored-By: Claude <noreply@anthropic.com>"
git push origin ${BASE_BRANCH}

{Else if spec directory exists:}
# Keep spec files but mark as cancelled
# Add a CANCELLED.md marker file
cat > "${SPEC_DIR}/CANCELLED.md" << EOF
# Feature Cancelled

**Feature:** ${FEATURE_ID}
**Cancelled:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Reason:** ${REASON:-Not specified}

## Status

This feature was cancelled and will not be developed.

## Spec Files

The specification files have been preserved for reference:
$(ls -1 "${SPEC_DIR}"/*.md 2>/dev/null | sed 's|.*/|- |')

## Notes

{Add any relevant notes about why this was cancelled or if it might be revisited.}
EOF

git add "${SPEC_DIR}/CANCELLED.md"
git commit -m "chore: Mark feature ${FEATURE_ID} as cancelled

Reason: ${REASON:-Not specified}

Co-Authored-By: Claude <noreply@anthropic.com>"
git push origin ${BASE_BRANCH}
{End if}
```

### Step 5: Generate Summary

**5.1: Report cleanup results**

```markdown
## Feature Cancelled

**Feature:** {FEATURE_ID}
**Date:** {current_date}
**Reason:** {REASON or "Not specified"}

### Cleanup Summary

| Action | Status |
|--------|--------|
| Switched to {BASE_BRANCH} | Done |
| Removed worktree | {Done/N/A} |
| Deleted local branch | Done |
| Deleted remote branch | {Done/N/A} |
| Spec files | {Deleted/Kept with CANCELLED.md marker} |

{If spec files kept:}
### Spec Files Preserved

The specification files are preserved at:
```
{SPEC_DIR}/
```

A `CANCELLED.md` marker has been added to indicate this feature was cancelled.
{End if}

### Next Steps

You are now on the `{BASE_BRANCH}` branch.

To start a new feature:
```bash
/spectra:specify
```
```

## Output

### Console Output

| Output | When Displayed |
|--------|----------------|
| Feature info | At command start |
| Confirmation prompt | Before cleanup (unless --force) |
| Cleanup progress | During cleanup |
| Summary | At command end |

### Exit Conditions

| Condition | Behavior |
|-----------|----------|
| Success | Report cleanup complete |
| User aborts | Stop with message |
| Not on feature branch | Fail with instructions |
| Cleanup fails | Report partial cleanup status |

## Usage

```
/spectra:cancel [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--delete` | Delete spec files (default: keep them) |
| `--keep-spec` | Keep spec files (default) |
| `--force` | Skip confirmation prompts |
| `--reason <text>` | Record reason for cancellation |

### Examples

```bash
# Cancel current feature (keep spec files)
/spectra:cancel

# Cancel and delete everything
/spectra:cancel --delete

# Cancel with reason
/spectra:cancel --reason "Requirements changed, no longer needed"

# Force cancel without prompts
/spectra:cancel --force

# Cancel with reason and delete spec
/spectra:cancel --delete --reason "Superseded by feature 015"
```

## Notes

- By default, spec files are kept with a `CANCELLED.md` marker for future reference
- Use `--delete` to completely remove the spec directory
- Uncommitted changes will be discarded - commit important work first
- The command will switch you to the base branch after cleanup
- Cancelled features can be "revived" by creating a new branch from the preserved specs

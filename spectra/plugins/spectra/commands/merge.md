---
description: "Merge a completed feature branch into main and clean up resources (worktree, branch)"
user-invocable: true
argument-hint: "[--push] [--squash] [--keep-branch] [--keep-worktree] [--dry-run]"
---

# Merge Command

Merge a completed feature branch into the base branch (main/master) and optionally clean up the associated worktree and feature branch. This is the final step in the spectra workflow after `/spectra:accept`.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Arguments

Parse `$ARGUMENTS` for optional flags:
- `--push` - Push to remote after merge
- `--squash` - Squash commits into a single commit
- `--rebase` - Rebase instead of merge
- `--keep-branch` - Keep the feature branch after merge (default: delete)
- `--keep-worktree` - Keep the worktree after merge (default: remove)
- `--dry-run` - Show what would be done without executing
- `--target <branch>` - Target branch to merge into (default: main or master)
- `--no-verify` - Skip pre-merge hooks (not recommended)

## Prerequisites

- Must be on a feature branch (pattern: `[###]-[short-name]`)
- Feature should have passed `/spectra:accept` (recommended)
- Working directory should be clean (all changes committed)
- Target branch must exist

## Workflow

### Step 1: Gather Context and Validate

**1.1: Get current context**

```bash
# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get repo root
REPO_ROOT=$(git rev-parse --show-toplevel)

# Detect if we're in a worktree
IS_WORKTREE=$(git rev-parse --is-inside-work-tree 2>/dev/null && git worktree list --porcelain | grep -c "worktree" || echo "0")
MAIN_WORKTREE=$(git worktree list --porcelain | head -1 | grep "worktree" | cut -d' ' -f2-)

# Get target branch (from args or detect)
if [[ -z "${TARGET_BRANCH:-}" ]]; then
  TARGET_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5 || echo "main")
fi

# Get commit count
COMMIT_COUNT=$(git rev-list --count ${TARGET_BRANCH}..HEAD 2>/dev/null || echo "0")

# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain)
```

**1.2: Validate branch pattern**

```bash
# Validate feature branch pattern
if [[ ! "$CURRENT_BRANCH" =~ ^[0-9]{3}-[a-z0-9-]+$ ]]; then
  echo "Error: Branch '$CURRENT_BRANCH' does not match feature pattern [###]-[short-name]"
  echo "Example: 001-user-auth, 042-dashboard-refresh"
  exit 1
fi
```

**1.3: Parse merge options**

```
mergeOptions = {
  push: false,          // --push
  squash: false,        // --squash
  rebase: false,        // --rebase
  keepBranch: false,    // --keep-branch
  keepWorktree: false,  // --keep-worktree
  dryRun: false,        // --dry-run
  targetBranch: "main", // --target
  noVerify: false       // --no-verify
}
```

**1.4: Report merge context**

```markdown
## Merge Preview

**Feature Branch:** {CURRENT_BRANCH}
**Target Branch:** {TARGET_BRANCH}
**Commits:** {COMMIT_COUNT}
**Strategy:** {merge/squash/rebase}

{If IS_WORKTREE > 1:}
**Worktree:** {current_worktree_path}
**Main Repo:** {MAIN_WORKTREE}
{End if}

### Options

| Option | Value |
|--------|-------|
| Push after merge | {push} |
| Squash commits | {squash} |
| Keep feature branch | {keepBranch} |
| Keep worktree | {keepWorktree} |

{If dryRun:}
> **Dry Run Mode:** No changes will be made.
{End if}
```

### Step 2: Pre-Merge Validation

**2.1: Check for uncommitted changes**

```bash
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: Uncommitted changes detected."
  echo "Commit or stash changes before merging."
  git status --short
  exit 1
fi
```

If uncommitted changes and not dry-run:
```markdown
### Pre-Merge Check Failed

**Error:** Uncommitted changes detected.

```
{git status --short output}
```

**Options:**
1. Commit changes: `git add -A && git commit -m "Final changes"`
2. Stash changes: `git stash`
3. Discard changes: `git checkout .` (dangerous)

After resolving, run `/spectra:merge` again.
```
**STOP execution.**

**2.2: Ensure we're up to date with remote**

```bash
# Fetch latest from origin
git fetch origin ${TARGET_BRANCH}
git fetch origin ${CURRENT_BRANCH} 2>/dev/null || true

# Check if local is behind remote
BEHIND=$(git rev-list --count HEAD..origin/${CURRENT_BRANCH} 2>/dev/null || echo "0")
```

If BEHIND > 0:
```markdown
**Warning:** Local branch is {BEHIND} commit(s) behind remote.

Run `git pull` to update before merging.
```

**2.3: Check for merge conflicts**

```bash
# Test merge without committing
git merge --no-commit --no-ff ${TARGET_BRANCH} 2>&1 || MERGE_CONFLICT=true
git merge --abort 2>/dev/null || true
```

If MERGE_CONFLICT:
```markdown
### Merge Conflict Detected

Merging {CURRENT_BRANCH} into {TARGET_BRANCH} would cause conflicts.

**Options:**
1. **Rebase first** (recommended):
   ```bash
   git rebase ${TARGET_BRANCH}
   # Resolve conflicts, then:
   git rebase --continue
   ```

2. **Merge and resolve**:
   Continue with merge and resolve conflicts manually.

Would you like to proceed with conflict resolution?
```

Use AskUserQuestion to confirm.

### Step 3: Execute Merge

**3.1: Navigate to main worktree (if in feature worktree)**

If we're in a worktree, we need to switch to the main repo:

```bash
# If in a worktree, get the main repo path
if [[ -n "$MAIN_WORKTREE" ]] && [[ "$MAIN_WORKTREE" != "$REPO_ROOT" ]]; then
  ORIGINAL_DIR=$(pwd)
  cd "$MAIN_WORKTREE"
fi
```

**3.2: Checkout target branch**

```bash
{If not dryRun:}
git checkout ${TARGET_BRANCH}
git pull origin ${TARGET_BRANCH}
{End if}
```

**3.3: Perform merge**

Based on merge strategy:

**Standard Merge:**
```bash
{If not dryRun:}
git merge ${CURRENT_BRANCH} --no-ff -m "Merge branch '${CURRENT_BRANCH}' into ${TARGET_BRANCH}

Co-Authored-By: Claude <noreply@anthropic.com>"
{End if}
```

**Squash Merge:**
```bash
{If not dryRun:}
git merge --squash ${CURRENT_BRANCH}
git commit -m "feat: ${CURRENT_BRANCH}

Squashed commits from feature branch.

Co-Authored-By: Claude <noreply@anthropic.com>"
{End if}
```

**Rebase (alternative):**
```bash
{If not dryRun:}
# First rebase feature onto target
git checkout ${CURRENT_BRANCH}
git rebase ${TARGET_BRANCH}
# Then fast-forward target
git checkout ${TARGET_BRANCH}
git merge --ff-only ${CURRENT_BRANCH}
{End if}
```

**3.4: Report merge result**

```markdown
### Merge Complete

**Merged:** {CURRENT_BRANCH} -> {TARGET_BRANCH}
**Commits:** {COMMIT_COUNT} commit(s) merged
**Strategy:** {merge/squash/rebase}

```bash
# Latest commits on {TARGET_BRANCH}
{git log --oneline -5}
```
```

### Step 4: Push to Remote (if --push)

**4.1: Push merged changes**

```bash
{If push and not dryRun:}
git push origin ${TARGET_BRANCH}
{End if}
```

**4.2: Report push result**

```markdown
{If push:}
### Pushed to Remote

Successfully pushed {TARGET_BRANCH} to origin.
{End if}
```

### Step 5: Cleanup Feature Branch (unless --keep-branch)

**5.1: Delete local feature branch**

```bash
{If not keepBranch and not dryRun:}
git branch -d ${CURRENT_BRANCH}
{End if}
```

**5.2: Delete remote feature branch**

```bash
{If not keepBranch and push and not dryRun:}
git push origin --delete ${CURRENT_BRANCH} 2>/dev/null || true
{End if}
```

**5.3: Report branch cleanup**

```markdown
{If not keepBranch:}
### Branch Cleanup

- [x] Deleted local branch: {CURRENT_BRANCH}
{If push:}
- [x] Deleted remote branch: origin/{CURRENT_BRANCH}
{End if}
{Else:}
### Branch Preserved

Feature branch {CURRENT_BRANCH} was kept (--keep-branch).
{End if}
```

### Step 6: Cleanup Worktree (unless --keep-worktree)

**6.1: Check if worktree exists for this feature**

```bash
# Find worktree for this branch
WORKTREE_PATH=$(git worktree list | grep "${CURRENT_BRANCH}" | awk '{print $1}')
```

**6.2: Remove worktree**

```bash
{If WORKTREE_PATH exists and not keepWorktree and not dryRun:}
# Remove the worktree
git worktree remove "${WORKTREE_PATH}" --force 2>/dev/null || {
  # If worktree remove fails, try manual cleanup
  rm -rf "${WORKTREE_PATH}"
  git worktree prune
}
{End if}
```

**6.3: Report worktree cleanup**

```markdown
{If WORKTREE_PATH exists:}
### Worktree Cleanup

{If not keepWorktree:}
- [x] Removed worktree: {WORKTREE_PATH}
{Else:}
- [ ] Worktree preserved: {WORKTREE_PATH} (--keep-worktree)
{End if}
{End if}
```

### Step 7: Generate Final Summary

**7.1: Create completion report**

```markdown
## Merge Summary

**Feature:** {CURRENT_BRANCH}
**Target:** {TARGET_BRANCH}
**Date:** {current_date}

### Actions Completed

| Action | Status |
|--------|--------|
| Merge to {TARGET_BRANCH} | {DONE/DRY-RUN} |
| Push to remote | {DONE/SKIPPED/DRY-RUN} |
| Delete local branch | {DONE/SKIPPED/DRY-RUN} |
| Delete remote branch | {DONE/SKIPPED/DRY-RUN} |
| Remove worktree | {DONE/SKIPPED/N-A/DRY-RUN} |

{If dryRun:}
---

> **Dry Run Complete:** No changes were made.
>
> To execute this merge, run:
> ```bash
> /spectra:merge {original_args_without_dry_run}
> ```
{Else:}
---

### Feature Merged Successfully

The feature branch `{CURRENT_BRANCH}` has been merged into `{TARGET_BRANCH}`.

{If not push:}
**Note:** Changes are local only. Run `git push origin {TARGET_BRANCH}` to push.
{End if}

### Next Steps

1. Verify the merge on {TARGET_BRANCH}:
   ```bash
   git log --oneline -10
   ```

2. Start a new feature:
   ```bash
   /spectra:specify
   ```
{End if}
```

### Step 8: Return to Main Repo (if started in worktree)

If we navigated away from a worktree:

```bash
{If ORIGINAL_DIR was in a worktree that was removed:}
cd "$MAIN_WORKTREE"
echo "Returned to main repository: $MAIN_WORKTREE"
{End if}
```

## Output

### Console Output

| Output | When Displayed |
|--------|----------------|
| Merge preview | At command start |
| Pre-merge validation | Before merge |
| Merge result | After merge |
| Push result | If --push |
| Cleanup report | After cleanup |
| Final summary | At command end |

### Exit Conditions

| Condition | Behavior |
|-----------|----------|
| Success | Report completion, suggest next steps |
| Uncommitted changes | Fail with instructions |
| Merge conflicts | Offer resolution options |
| Not on feature branch | Fail with error |
| Dry run | Show plan without executing |

## Usage

```
/spectra:merge [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--push` | Push to remote after merge |
| `--squash` | Squash all commits into one |
| `--rebase` | Rebase instead of merge |
| `--keep-branch` | Don't delete feature branch |
| `--keep-worktree` | Don't remove worktree |
| `--dry-run` | Preview without executing |
| `--target <branch>` | Target branch (default: main) |
| `--no-verify` | Skip pre-merge hooks |

### Examples

```bash
# Standard merge (no push, cleanup branch and worktree)
/spectra:merge

# Merge and push to remote
/spectra:merge --push

# Squash commits and push
/spectra:merge --squash --push

# Preview merge without executing
/spectra:merge --dry-run

# Merge but keep the branch for reference
/spectra:merge --push --keep-branch

# Merge to a different target branch
/spectra:merge --target develop --push

# Full cleanup (merge, push, delete everything)
/spectra:merge --push
```

## Workflow Integration

This command is designed to be the final step in the spectra workflow:

```
/spectra:specify  →  Define the feature
/spectra:plan     →  Create implementation plan
/spectra:tasks    →  Break into tasks
/spectra:implement →  Execute tasks
/spectra:review-pr →  Code review
/spectra:accept   →  Validate readiness  ← Run this first
/spectra:merge    →  Merge and cleanup   ← You are here
```

## Notes

- Always run `/spectra:accept` before `/spectra:merge`
- Use `--dry-run` to preview the merge before executing
- Worktrees are automatically detected and cleaned up
- Remote branches are only deleted if `--push` is specified
- Use `--squash` for a cleaner git history
- Use `--keep-branch` if you want to preserve the branch for reference
- The command handles being run from either the main repo or a worktree

---
description: Archive a completed spec by merging to main and cleaning up
arguments:
  - name: spec_id
    description: Spec ID to archive (optional - uses current spec if in worktree)
    required: false
  - name: --force
    description: Skip phase validation (spec must still be in review-ready state)
    required: false
  - name: --keep-branch
    description: Keep the spec branch after archiving (do not delete)
    required: false
---

# /projspec.archive Command

This command completes the spec lifecycle by merging the spec branch to main, moving metadata to the completed directory, and cleaning up the worktree and branch. It includes comprehensive validation and user confirmation at each critical step.

## Use Cases

- Completing a spec after successful review
- Merging implemented features to the main branch
- Cleaning up development artifacts after feature completion
- Finalizing the spec-driven development workflow

## Prerequisites

- A spec must exist and ideally be in the "review" phase
- The spec branch should have all changes committed
- The main branch should be clean (no uncommitted changes)
- User must confirm the archive action

## Execution Steps

Follow these steps exactly to archive a completed spec:

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

Nothing to archive. Create a new spec with: /projspec.new <spec-name>
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

Which spec would you like to archive? Provide the spec ID:
  /projspec.archive <spec-id>
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
- `BRANCH`: The git branch name
- `WORKTREE_PATH`: Path to the worktree
- `TASKS`: List of tasks (for summary)

If state.yaml doesn't exist or cannot be parsed, output error:

```
Error: Cannot read state.yaml for spec {SPEC_ID}.

File: .projspec/specs/active/{SPEC_ID}/state.yaml

Please check that the file exists and is valid YAML.
```

### Step 3: Validate Phase (Unless --force)

Check that the spec is in the "review" phase:

**If phase is "review":**
Proceed to Step 4.

**If phase is NOT "review" and --force is NOT provided:**

```
Error: Spec is not ready for archive.

Current phase: {PHASE}
Required phase: review

The spec must complete the full workflow before archiving:
  new -> spec -> plan -> tasks -> implement -> review

Current status:
  - Phase: {PHASE}
  - Completed tasks: {COMPLETED_COUNT}/{TOTAL_COUNT}

To continue the workflow, run the appropriate command for your current phase.
Or use --force to bypass this check (not recommended).
```

**If phase is NOT "review" and --force IS provided:**

```
Warning: Forcing archive despite phase validation failure.

Current phase: {PHASE} (expected: review)

Proceeding with archive. This may archive incomplete work.
```

Proceed to Step 4.

### Step 4: Pre-Archive Summary

Display a summary of what will happen and request confirmation:

```
Archive Summary for: {SPEC_NAME} ({SPEC_ID})
=============================================

This action will:
  1. Merge branch '{BRANCH}' to main
  2. Move spec metadata from active/ to completed/
  3. Remove worktree: {WORKTREE_PATH}
  4. Delete branch: {BRANCH} (unless --keep-branch is set)

Spec Details:
  - Phase: {PHASE}
  - Branch: {BRANCH}
  - Worktree: {WORKTREE_PATH}
  - Tasks: {COMPLETED_COUNT} completed, {SKIPPED_COUNT} skipped

This action cannot be easily undone.

Do you want to proceed with archiving this spec? (yes/no)
```

Wait for user confirmation. If user responds with anything other than "yes" or "y":

```
Archive cancelled.

The spec remains active at: .projspec/specs/active/{SPEC_ID}
```

Stop execution here.

### Step 5: Navigate to Main Repository

Ensure we're working from the main repository, not the worktree:

```bash
git rev-parse --git-common-dir
```

Store the path to the main repository. If currently in a worktree, operations may need to reference the main repo.

Get the current directory:

```bash
pwd
```

Store as `CURRENT_DIR`. Note if we're in the worktree so we can handle path references correctly.

### Step 6: Check for Uncommitted Changes in Worktree

Before proceeding, check if the worktree has uncommitted changes:

```bash
git -C {WORKTREE_PATH} status --porcelain 2>/dev/null
```

If the output is not empty (there are uncommitted changes):

```
Error: Worktree has uncommitted changes.

Worktree: {WORKTREE_PATH}

Uncommitted files:
{LIST_OF_CHANGED_FILES}

Please commit or discard these changes before archiving:
  1. Navigate to worktree: cd {WORKTREE_PATH}
  2. Commit changes: git add . && git commit -m "message"
  3. Or discard: git checkout .

Then run /projspec.archive again.
```

Stop execution here.

### Step 7: Check for Uncommitted Changes on Main

Check if the main branch has uncommitted changes:

First, determine what branch is checked out in the main repository:

```bash
git -C {MAIN_REPO_PATH} status --porcelain 2>/dev/null
```

If there are uncommitted changes on main:

```
Error: Main repository has uncommitted changes.

Please commit or stash changes on main before archiving:
  1. Commit: git add . && git commit -m "message"
  2. Or stash: git stash

Then run /projspec.archive again.
```

Stop execution here.

### Step 8: Switch to Main Branch

Ensure we're on the main branch for the merge:

```bash
git checkout main
```

If checkout fails:

```
Error: Could not switch to main branch.

Please manually switch to main and retry:
  git checkout main
  /projspec.archive {SPEC_ID}
```

### Step 9: Fetch and Update (Optional)

If the repository has a remote, fetch latest:

```bash
git fetch origin main 2>/dev/null || true
```

This is optional and should not block the archive if it fails.

### Step 10: Merge Spec Branch

Merge the spec branch to main with a descriptive commit message:

```bash
git merge {BRANCH} --no-ff -m "Merge {BRANCH}: {SPEC_NAME}

Spec ID: {SPEC_ID}
Tasks completed: {COMPLETED_COUNT}
Archived via /projspec.archive"
```

**Check merge result:**

If the merge succeeds (exit code 0), proceed to Step 11.

If merge fails due to conflicts:

```
Error: Merge conflicts detected.

Conflicting files:
{LIST_OF_CONFLICTING_FILES}

Please resolve the conflicts manually:
  1. Review and fix conflicts in each file
  2. Stage resolved files: git add <file>
  3. Complete merge: git commit
  4. Then run /projspec.archive again

Or abort the merge:
  git merge --abort

The spec remains in active state until conflicts are resolved.
```

Stop execution here. The spec stays active and the user must resolve conflicts.

### Step 11: Move Spec Metadata to Completed

Create the completed directory if it doesn't exist:

```bash
mkdir -p .projspec/specs/completed
```

Move the spec from active to completed:

```bash
mv .projspec/specs/active/{SPEC_ID} .projspec/specs/completed/{SPEC_ID}
```

If the move fails:

```
Warning: Could not move spec metadata.

Source: .projspec/specs/active/{SPEC_ID}
Destination: .projspec/specs/completed/{SPEC_ID}

The merge was successful, but you may need to move the metadata manually.
Continuing with worktree cleanup...
```

### Step 12: Update Archived State

Update the state.yaml in its new location to reflect archived status:

Read the state.yaml:

```bash
cat .projspec/specs/completed/{SPEC_ID}/state.yaml
```

Add or update the following fields:
- `phase: archived`
- `archived_at: {CURRENT_TIMESTAMP}`
- `merged_to: main`

Write the updated state.yaml back to `.projspec/specs/completed/{SPEC_ID}/state.yaml`.

### Step 13: Remove Worktree

Remove the git worktree:

```bash
git worktree remove {WORKTREE_PATH} --force
```

If worktree removal fails:

```
Warning: Could not remove worktree automatically.

Worktree: {WORKTREE_PATH}

You can remove it manually:
  git worktree remove {WORKTREE_PATH} --force

Or delete the directory:
  rm -rf {WORKTREE_PATH}
  git worktree prune
```

### Step 14: Delete Branch (Unless --keep-branch)

If `--keep-branch` is NOT set, ask for confirmation to delete the branch:

```
The spec branch can now be deleted.

Branch: {BRANCH}

Delete this branch? (yes/no)
```

If user confirms "yes" or "y":

```bash
git branch -d {BRANCH}
```

If branch deletion fails (e.g., unmerged changes):

```bash
git branch -D {BRANCH}
```

If `--keep-branch` IS set:

```
Branch kept as requested: {BRANCH}
```

### Step 15: Commit Metadata Changes

Commit the metadata changes (moving spec to completed):

```bash
git add .projspec/specs/
git commit -m "Archive spec {SPEC_ID}: {SPEC_NAME}

Moved from active/ to completed/
Archived via /projspec.archive"
```

### Step 16: Output Success Message

Report completion with summary:

```
Spec Archived Successfully!
===========================

  Spec ID:     {SPEC_ID}
  Name:        {SPEC_NAME}

Actions Completed:
  [x] Merged branch '{BRANCH}' to main
  [x] Moved metadata to .projspec/specs/completed/{SPEC_ID}
  [x] Removed worktree: {WORKTREE_PATH}
  {BRANCH_STATUS}

Summary:
  - Tasks completed: {COMPLETED_COUNT}
  - Tasks skipped: {SKIPPED_COUNT}
  - Spec archived at: {TIMESTAMP}

The spec is now complete. View archived specs with:
  ls .projspec/specs/completed/
```

Where `{BRANCH_STATUS}` is either:
- `[x] Deleted branch: {BRANCH}` (if branch was deleted)
- `[ ] Branch kept: {BRANCH}` (if --keep-branch was set)

## Error Handling

### Spec Not Found

```
Error: Spec '{SPEC_ID}' not found.

Available active specs:
  - {ID_1}: {NAME_1} (phase: {PHASE_1})
  - {ID_2}: {NAME_2} (phase: {PHASE_2})

Use /projspec.status to see all specs.
```

### Already Archived

If the spec is found in completed/ instead of active/:

```
Error: Spec '{SPEC_ID}' is already archived.

Location: .projspec/specs/completed/{SPEC_ID}

This spec has already been archived and is no longer active.
```

### Git Not Clean

```
Error: Git working directory is not clean.

Please commit or stash all changes before archiving:
  git status
  git stash  # to temporarily save changes

Then run /projspec.archive again.
```

### Branch Does Not Exist

```
Error: Spec branch '{BRANCH}' does not exist.

The branch may have been deleted manually.

Options:
  1. Use --force to archive without merge
  2. Recreate the branch from worktree
  3. Manually move spec to completed/
```

### Worktree Does Not Exist

```
Warning: Worktree not found at {WORKTREE_PATH}.

The worktree may have been removed manually.
Proceeding with merge and metadata archival...
```

### Permission Denied

```
Error: Permission denied while archiving.

Cannot write to: {PATH}

Please check file permissions and try again.
```

## Example Usage

### Example 1: Standard Archive (Single Spec)

```
User: /projspec.archive

Claude:
Archive Summary for: user-auth (a1b2c3d4)
=============================================

This action will:
  1. Merge branch 'spec/a1b2c3d4-user-auth' to main
  2. Move spec metadata from active/ to completed/
  3. Remove worktree: worktrees/spec-a1b2c3d4-user-auth
  4. Delete branch: spec/a1b2c3d4-user-auth

Spec Details:
  - Phase: review
  - Branch: spec/a1b2c3d4-user-auth
  - Worktree: worktrees/spec-a1b2c3d4-user-auth
  - Tasks: 6 completed, 0 skipped

This action cannot be easily undone.

Do you want to proceed with archiving this spec? (yes/no)

User: yes

Claude:
[Performs merge, cleanup, etc.]

Spec Archived Successfully!
===========================

  Spec ID:     a1b2c3d4
  Name:        user-auth

Actions Completed:
  [x] Merged branch 'spec/a1b2c3d4-user-auth' to main
  [x] Moved metadata to .projspec/specs/completed/a1b2c3d4
  [x] Removed worktree: worktrees/spec-a1b2c3d4-user-auth
  [x] Deleted branch: spec/a1b2c3d4-user-auth

Summary:
  - Tasks completed: 6
  - Tasks skipped: 0
  - Spec archived at: 2024-01-15T14:30:00Z

The spec is now complete. View archived specs with:
  ls .projspec/specs/completed/
```

### Example 2: Archive with Keep Branch

```
User: /projspec.archive --keep-branch

Claude:
Archive Summary for: user-auth (a1b2c3d4)
...

Do you want to proceed with archiving this spec? (yes/no)

User: yes

Claude:
...

Actions Completed:
  [x] Merged branch 'spec/a1b2c3d4-user-auth' to main
  [x] Moved metadata to .projspec/specs/completed/a1b2c3d4
  [x] Removed worktree: worktrees/spec-a1b2c3d4-user-auth
  [ ] Branch kept: spec/a1b2c3d4-user-auth
```

### Example 3: Merge Conflict

```
User: /projspec.archive

Claude:
[After confirmation, attempts merge...]

Error: Merge conflicts detected.

Conflicting files:
  - src/api/auth.py
  - src/models/user.py

Please resolve the conflicts manually:
  1. Review and fix conflicts in each file
  2. Stage resolved files: git add <file>
  3. Complete merge: git commit
  4. Then run /projspec.archive again

Or abort the merge:
  git merge --abort

The spec remains in active state until conflicts are resolved.
```

### Example 4: Force Archive (Not in Review Phase)

```
User: /projspec.archive --force

Claude:
Warning: Forcing archive despite phase validation failure.

Current phase: implement (expected: review)

Proceeding with archive. This may archive incomplete work.

Archive Summary for: user-auth (a1b2c3d4)
...
```

### Example 5: User Cancellation

```
User: /projspec.archive

Claude:
Archive Summary for: user-auth (a1b2c3d4)
...

Do you want to proceed with archiving this spec? (yes/no)

User: no

Claude:
Archive cancelled.

The spec remains active at: .projspec/specs/active/a1b2c3d4
```

## Notes

- The archive command is destructive - always confirm before proceeding
- Merge conflicts must be resolved manually before archive can complete
- The --force flag bypasses phase validation but not other safety checks
- Branch deletion is optional and confirmed separately
- Archived specs can be viewed but not modified through standard commands
- The worktree is removed even if --keep-branch is set
- All git operations use --no-ff to preserve merge history
- Consider running /projspec.review before archive to ensure completeness

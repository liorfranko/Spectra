# Skill: Worktree-Based Feature Workflow

## When to Use
When working on features that use git worktrees for isolation, and the main repository contains configuration/scripts that aren't replicated in worktrees.

## Pattern

1. **Identify the worktree path**
   - Feature branches may be checked out in worktrees (e.g., `worktrees/001-feature-name/`)
   - The main repo can't checkout the same branch (`fatal: 'branch' is already checked out`)

2. **Access scripts from main repo**
   - Worktrees don't automatically have all directories from main (e.g., `.specify/`)
   - Use absolute paths to run scripts: `/path/to/main-repo/.specify/scripts/...`
   - Or `cd` to worktree and reference main repo scripts

3. **File operations in worktrees**
   - Specs and feature files belong in the worktree: `worktrees/001-feature/specs/...`
   - Session files and learned skills stay in main repo: `.specify/sessions/`, `.claude/skills/learned/`

4. **Running setup scripts**
   ```bash
   # From worktree directory, use absolute path to main repo script
   cd /path/to/worktrees/001-feature
   /path/to/main-repo/.specify/scripts/bash/setup-plan.sh --json
   ```

## Example

```bash
# Script in main repo, feature work in worktree
MAIN_REPO=/Users/dev/project
WORKTREE=/Users/dev/project/worktrees/001-feature

# Run setup from worktree using main repo script
cd $WORKTREE && $MAIN_REPO/.specify/scripts/bash/setup-plan.sh --json

# Create plan artifacts in worktree
# specs/001-feature/plan.md -> $WORKTREE/specs/001-feature/plan.md
```

## Multi-Worktree Navigation

When working with multiple features simultaneously, each in its own worktree:

### Listing All Active Worktrees

```bash
# Show all worktrees with their branches and paths
git worktree list

# Example output:
# /Users/dev/project                       abc1234 [main]
# /Users/dev/project/worktrees/001-auth    def5678 [001-auth]
# /Users/dev/project/worktrees/002-api     ghi9012 [002-api]
```

### Navigating Between Worktrees

```bash
# From main repo to a worktree
cd worktrees/001-auth

# From one worktree to another (relative navigation)
cd ../002-api

# Using absolute paths (recommended for scripts)
cd /Users/dev/project/worktrees/001-auth
```

### Identifying Current Worktree

```bash
# Check which branch you're on
git branch --show-current

# Get the worktree root directory
git rev-parse --show-toplevel

# Verify you're in a worktree (not main)
git rev-parse --git-common-dir  # Shows path to main .git if in worktree
```

### Key Behaviors

- **Isolation**: Each worktree is a complete, independent working copy
- **No interference**: Changes in one worktree don't affect others
- **Shared history**: All worktrees share the same git history and remote
- **Branch lock**: A branch can only be checked out in one worktree at a time

## Troubleshooting

### "Branch already checked out" Error

```
fatal: 'feature-branch' is already checked out at '/path/to/worktree'
```

**Solution**: Navigate to the existing worktree instead of creating a new checkout:
```bash
# Find where the branch is checked out
git worktree list | grep feature-branch

# Navigate to that worktree
cd /path/to/worktree
```

### Stale Worktrees

When worktree directories are deleted manually (not via `git worktree remove`):

```bash
# List worktrees - stale ones show as "prunable"
git worktree list

# Clean up stale worktree references
git worktree prune

# Verify cleanup
git worktree list
```

### Worktree Not Found

If a worktree path doesn't exist but git still references it:

```bash
# Check worktree status
git worktree list

# Prune if marked as prunable
git worktree prune

# Or explicitly remove the reference
git worktree remove /path/to/missing/worktree --force
```

## Cleanup After Merge

Once a feature's PR is merged, the worktree and feature branch can be safely removed.

### Pre-Cleanup Verification

**Always verify the PR is merged before cleanup**:

```bash
# Check PR status (requires GitHub CLI)
gh pr view <pr-number> --json state,mergedAt

# Or verify specs exist in main repo
cd /path/to/main-repo
git checkout main && git pull
ls specs/<feature-id>/  # Should show spec.md, plan.md, tasks.md
```

### Cleanup Steps

```bash
# 1. Navigate to main repo (not the worktree)
cd /path/to/main-repo

# 2. Remove the worktree
git worktree remove worktrees/<feature-id>

# 3. (Optional) Delete the feature branch if no longer needed
git branch -d <feature-branch>

# 4. Clean up any stale worktree references
git worktree prune

# 5. Verify cleanup
git worktree list
git branch -a | grep <feature-id>  # Should show nothing
```

### Example Cleanup Session

```bash
# Feature 007-worktree-workflow merged via PR #42
cd /Users/dev/project

# Verify PR is merged
gh pr view 42 --json state
# Output: {"state":"MERGED"}

# Verify specs are in main
git pull origin main
ls specs/007-worktree-workflow/
# Output: spec.md  plan.md  tasks.md

# Safe to clean up
git worktree remove worktrees/007-worktree-workflow
git branch -d 007-worktree-workflow
git worktree prune
```

### Safety Notes

- **Never force-remove** (`--force`) without verifying PR is merged
- If `git branch -d` fails, the branch has unmerged changes - investigate before using `-D`
- Keep worktrees until PR is merged, not just created
- Specs in the worktree are only safe in main after the PR merge completes

## Key Insight
Keep a mental model of two workspaces: the main repo (configuration, scripts, session state) and the worktree (feature-specific code and specs). Use absolute paths when crossing between them.

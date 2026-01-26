# Quickstart: Worktree-Based Feature Workflow

**Feature**: 007-worktree-workflow
**Date**: 2026-01-26

## Overview

This guide explains how to work with projspec's worktree-based feature workflow. Each feature gets its own isolated worktree, allowing you to work on multiple features simultaneously without branch switching.

---

## Quick Reference

| Action | Command |
|--------|---------|
| Create new feature | `/projspec.specify "feature description"` |
| Navigate to worktree | `cd worktrees/<NNN-feature-name>` |
| List all worktrees | `git worktree list` |
| Switch between features | `cd worktrees/<other-feature>` |
| Remove completed worktree | `git worktree remove worktrees/<feature>` |

---

## Creating a New Feature

### Step 1: Run the specify command

```bash
/projspec.specify "Add user authentication"
```

This creates:
1. A new branch: `008-user-auth`
2. A new worktree: `worktrees/008-user-auth/`
3. A spec file: `worktrees/008-user-auth/specs/008-user-auth/spec.md` (in worktree, for feature branch commit)

### Step 2: Navigate to the worktree

```bash
cd worktrees/008-user-auth
```

You're now in an isolated environment with:
- Your feature branch checked out
- Spec files in `specs/<feature>/` (committed to feature branch)
- All source files ready for modification

### Step 3: Continue the workflow

Run subsequent commands from within the worktree:

```bash
/projspec.plan      # Create implementation plan
/projspec.tasks     # Generate task breakdown
/projspec.implement # Execute implementation
```

---

## Understanding the Directory Structure

```
projspec/                           # Main repository (on main branch)
├── .specify/                       # Configuration and scripts
│   ├── scripts/bash/               # All bash scripts
│   ├── templates/                  # Document templates
│   └── memory/                     # Persistent context
├── specs/                          # Specs from merged features
│   ├── 001-projspec-mvp/
│   └── 007-worktree-workflow/      # Merged from feature branch
├── worktrees/                      # Feature worktrees
│   ├── 007-worktree-workflow/      # Isolated working directory
│   │   ├── .git                    # Worktree pointer (not a directory)
│   │   ├── specs/007-worktree-workflow/  # Feature specs (on feature branch)
│   │   └── src/                    # Feature-specific code
│   └── 008-user-auth/
│       ├── .git
│       ├── specs/008-user-auth/    # Feature specs (on feature branch)
│       └── src/
└── src/                            # Main branch source (if any)
```

### Key Points

- **Specs are on feature branches**: Each worktree has its own specs directory
- **Worktrees are isolated**: Each feature has its own copy of the full repo
- **Standard git workflow**: Commit specs + code to feature branch, merge via PR
- **No symlinks needed**: Git handles everything naturally

---

## Working with Multiple Features

### Scenario: You're working on feature A and need to check feature B

```bash
# From worktree A
pwd  # /path/to/projspec/worktrees/008-user-auth

# Simply navigate to worktree B
cd ../007-worktree-workflow

# Now you're in feature B's context
git branch  # * 007-worktree-workflow
```

### Scenario: Check which features are active

```bash
git worktree list
# /path/to/projspec                            abc1234 [main]
# /path/to/projspec/worktrees/007-worktree-workflow  def5678 [007-worktree-workflow]
# /path/to/projspec/worktrees/008-user-auth          ghi9012 [008-user-auth]
```

### Scenario: Uncommitted changes are preserved

Changes in one worktree don't affect others:

```bash
# In worktree 008-user-auth
echo "work in progress" > src/temp.txt

# Navigate to another worktree
cd ../007-worktree-workflow

# Changes in 008-user-auth are still there when you return
cd ../008-user-auth
cat src/temp.txt  # work in progress
```

---

## Common Operations

### Viewing a feature's spec

From the worktree:
```bash
cd worktrees/007-worktree-workflow
cat specs/007-worktree-workflow/spec.md
```

From main repo (for merged specs):
```bash
cat specs/007-worktree-workflow/spec.md  # Only available after PR is merged
```

### Running scripts from a worktree

Scripts automatically resolve paths correctly:

```bash
cd worktrees/008-user-auth
.specify/scripts/bash/check-prerequisites.sh --json

# Scripts find the main repo's .specify/ via git
```

### Cleaning up completed features

After merging a feature:

```bash
# From main repo
git worktree remove worktrees/008-user-auth

# Or force remove if uncommitted changes exist
git worktree remove --force worktrees/008-user-auth
```

After the PR is merged, specs are in main repo's `specs/008-user-auth/` for reference.

---

## Troubleshooting

### "Branch is already checked out" error

**Problem**: You tried to checkout a branch that's in a worktree.

**Solution**: Navigate to the worktree instead:
```bash
git worktree list | grep 008-user-auth
# /path/to/projspec/worktrees/008-user-auth  [008-user-auth]

cd /path/to/projspec/worktrees/008-user-auth
```

### Worktree not showing in list

**Problem**: Worktree was deleted manually without `git worktree remove`.

**Solution**: Prune stale entries:
```bash
git worktree prune
git worktree list  # Now shows only valid worktrees
```

### Scripts can't find .specify directory

**Problem**: Running script from worktree can't access templates.

**Solution**: Scripts should use `get_repo_root()` which finds the main repo. If a script fails, ensure it sources `common.sh`:
```bash
source .specify/scripts/bash/common.sh
```

---

## Best Practices

1. **Always work from worktrees** for feature development
2. **Don't manually checkout feature branches** in the main repo
3. **Use the `/projspec.specify` command** to create features (it sets up worktrees)
4. **Keep the main repo on `main` branch** for admin tasks
5. **Clean up worktrees** after features are merged
6. **Commit frequently** - worktrees are independent so conflicts are minimized

---

## Integration with Claude Code

When using Claude Code in a worktree:

1. **Open terminal in worktree directory**
2. **Run Claude Code** - it will detect the worktree context
3. **Projspec commands work seamlessly** - paths resolve correctly
4. **Source modifications happen in the worktree** - not the main repo

The plugin's learned skill at `.claude/skills/learned/worktree-based-feature-workflow.md` provides additional context for AI assistants.

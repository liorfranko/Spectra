# Research: Worktree-Based Feature Workflow

**Feature**: 007-worktree-workflow
**Date**: 2026-01-26
**Status**: Complete

## Executive Summary

Git worktrees provide an ideal mechanism for feature isolation in the projspec workflow. The current implementation already leverages worktrees effectively; this research consolidates findings and identifies remaining gaps to ensure complete worktree support across all commands.

---

## 1. Git Worktree Behavior

### Decision: Use git worktree add -b for feature creation

**Rationale**: Creates a new branch and worktree in a single atomic operation, ensuring the branch is immediately associated with the worktree.

**Alternatives Considered**:
- `git worktree add <path> <existing-branch>`: Requires branch to exist first; two-step process
- `git clone --worktree`: Not applicable; we're working within a single repository

### Key Git Commands for Worktree Operations

| Command | Purpose | Output |
|---------|---------|--------|
| `git worktree list` | List all worktrees | Path + branch + HEAD commit |
| `git worktree list --porcelain` | Machine-readable list | Structured output for parsing |
| `git worktree add -b <branch> <path>` | Create new worktree with branch | Creates directory and .git file |
| `git worktree remove <path>` | Remove worktree | Deletes directory, keeps branch |
| `git rev-parse --git-common-dir` | Find main .git directory | Differs from --git-dir in worktrees |
| `git rev-parse --git-dir` | Find local .git | Returns .git file path in worktrees |

### Worktree Detection Logic

**Decision**: Use comparison of `--git-common-dir` vs `--git-dir` to detect worktree context

**Rationale**:
- In main repo: Both return the same path (`.git` directory)
- In worktree: `--git-common-dir` returns main repo's `.git`, while `--git-dir` returns worktree's `.git` file

```bash
is_worktree() {
    local common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    local git_dir=$(git rev-parse --git-dir 2>/dev/null)
    [[ -n "$common_dir" && -n "$git_dir" && "$common_dir" != "$git_dir" ]]
}
```

---

## 2. Symlink Strategy

### Decision: Use relative symlinks for specs directory

**Rationale**: Relative symlinks (`../../specs`) remain valid when the repository is moved or cloned to a different location.

**Alternatives Considered**:
- Absolute symlinks: Break when repo is moved
- Bind mounts: Platform-specific, requires elevated permissions
- Git submodules: Overkill for this use case

### Symlink Validation

```bash
validate_specs_symlink() {
    local worktree_path="${1:-$(pwd)}"
    # Check both that symlink exists AND target is accessible
    [[ -L "$worktree_path/specs" && -d "$worktree_path/specs" ]]
}
```

### Symlink Repair

When symlink is broken or missing, it can be recreated:

```bash
repair_specs_symlink() {
    local worktree_path="${1:-$(pwd)}"
    rm -f "$worktree_path/specs"  # Remove broken symlink if exists
    ln -s "../../specs" "$worktree_path/specs"
}
```

---

## 3. Path Resolution from Worktrees

### Decision: Use git rev-parse --show-toplevel for repo root detection

**Rationale**: Works correctly in both main repo and worktree contexts, always returning the working tree root (not the .git directory).

**Current Implementation Analysis**:

The existing `get_repo_root()` in `common.sh` already handles this correctly:

```bash
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel  # Returns worktree root when in worktree
    else
        # Fallback for non-git repos
        local script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}
```

### Accessing Main Repo Resources from Worktree

For resources that should remain in main repo (`.specify/`, configuration):

```bash
get_main_repo_path() {
    if is_worktree; then
        # Get main repo from git-common-dir
        git rev-parse --git-common-dir 2>/dev/null | sed 's|/.git$||'
    else
        get_repo_root  # Already in main repo
    fi
}
```

---

## 4. Edge Cases and Error Handling

### Case 1: Branch Already Checked Out in Worktree

**Scenario**: User tries to checkout a branch in main repo that's already in a worktree.

**Git Behavior**: `fatal: 'branch-name' is already checked out at '/path/to/worktree'`

**Solution**: Detect this scenario and redirect user to worktree:

```bash
check_worktree_context() {
    local branch=$(get_current_branch)
    local worktree_path=$(get_worktree_for_branch "$branch")

    if [[ -n "$worktree_path" && ! $(is_worktree) ]]; then
        echo "Branch '$branch' is checked out in worktree: $worktree_path" >&2
        echo "Navigate there with: cd $worktree_path" >&2
        return 1
    fi
    return 0
}
```

### Case 2: Worktree Deleted Without Git Cleanup

**Scenario**: User deletes worktree directory manually instead of using `git worktree remove`.

**Git Behavior**: `git worktree list` shows the worktree as "prunable"

**Solution**: Run `git worktree prune` periodically or before listing:

```bash
list_worktrees_clean() {
    git worktree prune 2>/dev/null  # Clean up stale entries
    git worktree list
}
```

### Case 3: Broken Specs Symlink

**Scenario**: Symlink exists but target directory is missing or inaccessible.

**Solution**: Validate before operations, offer repair:

```bash
if ! validate_specs_symlink; then
    echo "Specs symlink is broken. Attempting repair..." >&2
    if repair_specs_symlink; then
        echo "Symlink repaired successfully." >&2
    else
        echo "ERROR: Could not repair specs symlink. Manual intervention required." >&2
        exit 1
    fi
fi
```

### Case 4: Command Run from Main Repo Context

**Scenario**: User is in main repo on `main` branch, runs `/projspec.plan` for feature 007.

**Solution**: Check if the target feature has a worktree and provide guidance:

```bash
# In check-prerequisites.sh or command entry points
check_feature_worktree_context() {
    local feature_branch="$1"
    local worktree=$(get_worktree_for_branch "$feature_branch")

    if [[ -n "$worktree" ]]; then
        if is_worktree; then
            return 0  # Already in a worktree
        else
            echo "Feature '$feature_branch' has a dedicated worktree." >&2
            echo "For best results, navigate to: $worktree" >&2
            echo "Continue from main repo anyway? [y/N]" >&2
            # Note: Scripts called from Claude Code can't prompt interactively
            # Instead, just warn and continue
        fi
    fi
}
```

---

## 5. Cross-Platform Considerations

### Symlinks on Different Platforms

| Platform | Symlink Support | Notes |
|----------|-----------------|-------|
| macOS | Full | Default behavior |
| Linux | Full | Default behavior |
| Windows (WSL) | Full | Behaves like Linux |
| Windows (Git Bash) | Partial | Requires developer mode or admin |
| Windows (native) | Partial | May need configuration |

**Decision**: Document that symlinks are required; provide fallback guidance for Windows users who cannot use symlinks.

### Git Worktree Version Requirements

| Git Version | Worktree Support |
|-------------|------------------|
| < 2.5 | Not available |
| 2.5+ | Basic support |
| 2.17+ | `--porcelain` flag for `worktree list` |

**Decision**: Require Git 2.5+ (released July 2015, widely available)

---

## 6. Documentation Terminology Updates

### Terms to Replace

| Old Term | New Term | Context |
|----------|----------|---------|
| "checkout branch" | "create worktree" | Feature creation |
| "switch to branch" | "navigate to worktree" | Context switching |
| "on branch X" | "in worktree for X" | Status messages |
| "branch directory" | "worktree directory" | Path references |

### Updated Workflow Description

**Before**: "Run `/projspec.specify` to create a new feature branch, then checkout the branch to start working."

**After**: "Run `/projspec.specify` to create a new feature with its own worktree. Navigate to the worktree directory to start working."

---

## 7. Implementation Recommendations

### Priority 1: Worktree Utilities in common.sh

Add these functions to enable worktree-aware operations:

1. `is_worktree()` - Detect worktree context
2. `get_main_repo_from_worktree()` - Get main repo path
3. `validate_specs_symlink()` - Check symlink health
4. `repair_specs_symlink()` - Fix broken symlinks
5. `get_worktree_for_branch()` - Find worktree by branch
6. `check_worktree_context()` - Warn if should be in worktree

### Priority 2: Update check-prerequisites.sh

Add worktree context validation to prerequisite checks:

1. Validate specs symlink if in worktree
2. Warn if running from main repo when worktree exists
3. Prune stale worktree entries

### Priority 3: Update Documentation

1. Update command help text with worktree terminology
2. Update learned skill `worktree-based-feature-workflow.md`
3. Add worktree navigation section to quickstart

### Priority 4: Implement Command Updates

Update these commands for worktree awareness:

1. `projspec.implement.md` - Ensure source modifications go to worktree
2. `projspec.specify.md` - Already handles worktree creation; review messages
3. Other commands - Add context detection and guidance

---

## Summary

The worktree-based workflow is already largely implemented. Key remaining work:

1. **Utility functions** in `common.sh` for worktree detection and management
2. **Context detection** to guide users to appropriate worktrees
3. **Symlink validation** and repair for edge cases
4. **Documentation updates** for consistent terminology

All research questions have been resolved. No blockers identified.

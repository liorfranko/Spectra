# Contract: Worktree Context Functions

**Feature**: 007-worktree-workflow
**Date**: 2026-01-26
**Location**: `.specify/scripts/bash/common.sh`

## Overview

This contract defines the interface for worktree detection and context management functions to be added to `common.sh`.

---

## Function Specifications

### is_worktree

Detects whether the current working directory is inside a git worktree (as opposed to the main repository).

**Signature**:
```bash
is_worktree() -> exit_code
```

**Parameters**: None

**Returns**:
- Exit code `0`: Current directory is inside a git worktree
- Exit code `1`: Current directory is in the main repository or not a git repository

**Implementation**:
```bash
is_worktree() {
    local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    local git_dir=$(git rev-parse --git-dir 2>/dev/null)
    [[ -n "$git_common_dir" && -n "$git_dir" && "$git_common_dir" != "$git_dir" ]]
}
```

**Usage**:
```bash
if is_worktree; then
    echo "Running in worktree context"
else
    echo "Running in main repo context"
fi
```

---

### get_main_repo_from_worktree

Returns the absolute path to the main repository when called from within a worktree.

**Signature**:
```bash
get_main_repo_from_worktree() -> stdout
```

**Parameters**: None

**Output** (stdout):
- Absolute path to main repository if in a worktree
- Empty string if not in a worktree

**Implementation**:
```bash
get_main_repo_from_worktree() {
    if is_worktree; then
        local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
        # Remove /.git suffix to get repo root
        echo "${git_common_dir%/.git}"
    fi
}
```

**Usage**:
```bash
main_repo=$(get_main_repo_from_worktree)
if [[ -n "$main_repo" ]]; then
    echo "Main repo at: $main_repo"
fi
```

---

### validate_specs_symlink

Checks whether the specs symlink in a worktree exists and points to a valid directory.

**Signature**:
```bash
validate_specs_symlink [worktree_path] -> exit_code
```

**Parameters**:
- `worktree_path` (optional): Path to check. Defaults to current directory.

**Returns**:
- Exit code `0`: Symlink exists and target directory is accessible
- Exit code `1`: Symlink missing, broken, or target inaccessible

**Implementation**:
```bash
validate_specs_symlink() {
    local worktree_path="${1:-$(pwd)}"
    [[ -L "$worktree_path/specs" && -d "$worktree_path/specs" ]]
}
```

**Usage**:
```bash
if ! validate_specs_symlink; then
    echo "Specs symlink is broken or missing"
fi
```

---

### repair_specs_symlink

Repairs or recreates the specs symlink in a worktree.

**Signature**:
```bash
repair_specs_symlink [worktree_path] -> exit_code
```

**Parameters**:
- `worktree_path` (optional): Path to repair. Defaults to current directory.

**Returns**:
- Exit code `0`: Symlink repaired successfully
- Exit code `1`: Repair failed (not in a worktree or other error)

**Implementation**:
```bash
repair_specs_symlink() {
    local worktree_path="${1:-$(pwd)}"

    if ! is_worktree; then
        echo "Not in a worktree, cannot repair specs symlink" >&2
        return 1
    fi

    # Remove existing symlink or file
    rm -f "$worktree_path/specs"

    # Create relative symlink to main repo specs
    ln -s "../../specs" "$worktree_path/specs"

    # Verify repair was successful
    validate_specs_symlink "$worktree_path"
}
```

**Usage**:
```bash
if ! validate_specs_symlink; then
    if repair_specs_symlink; then
        echo "Symlink repaired"
    else
        echo "Failed to repair symlink" >&2
        exit 1
    fi
fi
```

---

### get_worktree_for_branch

Finds the worktree path for a given branch name.

**Signature**:
```bash
get_worktree_for_branch <branch_name> -> stdout
```

**Parameters**:
- `branch_name` (required): The branch name to look up (e.g., `007-worktree-workflow`)

**Output** (stdout):
- Absolute path to worktree if branch is checked out in a worktree
- Empty string if branch is not in any worktree

**Implementation**:
```bash
get_worktree_for_branch() {
    local branch="$1"
    [[ -z "$branch" ]] && return

    git worktree list --porcelain 2>/dev/null | awk -v branch="$branch" '
        /^worktree / { wt = substr($0, 10) }
        /^branch refs\/heads\// {
            b = substr($0, 21)
            if (b == branch) print wt
        }
    '
}
```

**Usage**:
```bash
worktree_path=$(get_worktree_for_branch "007-worktree-workflow")
if [[ -n "$worktree_path" ]]; then
    echo "Branch checked out at: $worktree_path"
fi
```

---

### check_worktree_context

Checks if the user should be working in a worktree instead of the main repository. Prints guidance if redirection is needed.

**Signature**:
```bash
check_worktree_context [feature_branch] -> exit_code
```

**Parameters**:
- `feature_branch` (optional): Branch to check. Defaults to current branch.

**Returns**:
- Exit code `0`: User is in appropriate context (worktree or no worktree exists)
- Exit code `1`: User should navigate to a worktree

**Output** (stderr): Warning message with navigation instructions if redirection needed

**Implementation**:
```bash
check_worktree_context() {
    local feature_branch="${1:-$(get_current_branch)}"

    # Skip check if already in a worktree
    if is_worktree; then
        return 0
    fi

    # Check if the branch has an associated worktree
    local worktree_path=$(get_worktree_for_branch "$feature_branch")

    if [[ -n "$worktree_path" ]]; then
        echo "Warning: Branch '$feature_branch' is checked out in a worktree" >&2
        echo "Worktree location: $worktree_path" >&2
        echo "Navigate there with: cd $worktree_path" >&2
        return 1
    fi

    return 0
}
```

**Usage**:
```bash
if ! check_worktree_context; then
    # User was warned about worktree context
    # Script can continue or exit based on requirements
fi
```

---

### list_worktrees

Lists all worktrees with their branches (after pruning stale entries).

**Signature**:
```bash
list_worktrees [format] -> stdout
```

**Parameters**:
- `format` (optional): `simple` (default) or `porcelain`

**Output** (stdout):
- List of worktrees

**Implementation**:
```bash
list_worktrees() {
    local format="${1:-simple}"

    # Prune stale worktree entries first
    git worktree prune 2>/dev/null

    case "$format" in
        porcelain)
            git worktree list --porcelain
            ;;
        *)
            git worktree list
            ;;
    esac
}
```

---

## Error Messages

| Scenario | Message |
|----------|---------|
| Not in git repo | `ERROR: Not in a git repository` |
| Broken symlink | `ERROR: Specs symlink is broken. Run from worktree or repair manually.` |
| Branch in worktree | `Warning: Branch 'X' is checked out in a worktree at Y` |
| Symlink repair failed | `ERROR: Could not repair specs symlink` |

---

## Integration Points

### check-prerequisites.sh

Add worktree context validation:

```bash
# After loading common.sh

# Validate specs symlink if in worktree
if is_worktree && ! validate_specs_symlink; then
    echo "Repairing broken specs symlink..." >&2
    repair_specs_symlink || exit 1
fi

# Warn if should be in worktree
check_worktree_context
```

### create-new-feature.sh

Already handles worktree creation. Ensure output messages use "worktree" terminology consistently.

### setup-plan.sh / setup-tasks.sh

Add context check at script entry:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Warn if running from main repo when worktree exists
check_worktree_context
```

---

## Testing

### Test Cases

1. **is_worktree from main repo** → returns 1
2. **is_worktree from worktree** → returns 0
3. **get_main_repo_from_worktree from main repo** → empty output
4. **get_main_repo_from_worktree from worktree** → main repo path
5. **validate_specs_symlink with valid symlink** → returns 0
6. **validate_specs_symlink with broken symlink** → returns 1
7. **repair_specs_symlink in worktree** → creates valid symlink
8. **get_worktree_for_branch with existing worktree** → returns path
9. **get_worktree_for_branch with no worktree** → empty output
10. **check_worktree_context from worktree** → returns 0, no output
11. **check_worktree_context from main repo with worktree** → returns 1, prints warning

### Manual Testing Script

```bash
#!/bin/bash
# test-worktree-functions.sh

source .specify/scripts/bash/common.sh

echo "=== Testing from $(pwd) ==="

echo -n "is_worktree: "
is_worktree && echo "YES" || echo "NO"

echo -n "get_main_repo_from_worktree: "
get_main_repo_from_worktree || echo "(empty)"

echo -n "validate_specs_symlink: "
validate_specs_symlink && echo "VALID" || echo "INVALID"

echo -n "get_worktree_for_branch 007-worktree-workflow: "
get_worktree_for_branch "007-worktree-workflow" || echo "(none)"

echo "check_worktree_context:"
check_worktree_context && echo "OK" || echo "REDIRECTED"
```

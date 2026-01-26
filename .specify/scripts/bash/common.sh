#!/usr/bin/env bash
# Common functions and variables for all scripts

# Get repository root, with fallback for non-git repositories
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Fall back to script location for non-git repos
        local script_dir="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/../../.." && pwd)
    fi
}

# Get current branch, with fallback for non-git repositories
get_current_branch() {
    # First check if SPECIFY_FEATURE environment variable is set
    if [[ -n "${SPECIFY_FEATURE:-}" ]]; then
        echo "$SPECIFY_FEATURE"
        return
    fi

    # Then check git if available
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi

    # For non-git repos, try to find the latest feature directory
    local repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"

    if [[ -d "$specs_dir" ]]; then
        local latest_feature=""
        local highest=0

        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^([0-9]{3})- ]]; then
                    local number=${BASH_REMATCH[1]}
                    number=$((10#$number))
                    if [[ "$number" -gt "$highest" ]]; then
                        highest=$number
                        latest_feature=$dirname
                    fi
                fi
            fi
        done

        if [[ -n "$latest_feature" ]]; then
            echo "$latest_feature"
            return
        fi
    fi

    echo "main"  # Final fallback
}

# Check if we have git available
has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

# ============================================================================
# Worktree Detection Functions
# ============================================================================

# Detect if current directory is inside a git worktree
# Returns: 0 if worktree, 1 if not
is_worktree() {
    local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    local git_dir=$(git rev-parse --git-dir 2>/dev/null)
    [[ -n "$git_common_dir" && -n "$git_dir" && "$git_common_dir" != "$git_dir" ]]
}

# Get the main repository path from a worktree
# Returns: Absolute path to main repo, or empty if not in worktree
get_main_repo_from_worktree() {
    if is_worktree; then
        local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
        # Remove /.git suffix to get repo root
        echo "${git_common_dir%/.git}"
    fi
}

# List all worktrees (prunes stale entries first)
# Usage: list_worktrees [format]
#   format: "simple" (default) or "porcelain"
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

# Get worktree path for a given branch
# Returns: Worktree path or empty if branch not in a worktree
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

# Check if user should be in a worktree instead of main repo
# Prints guidance message and returns 1 if redirect needed
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

check_feature_branch() {
    local branch="$1"
    local has_git_repo="$2"

    # For non-git repos, we can't enforce branch naming but still provide output
    if [[ "$has_git_repo" != "true" ]]; then
        echo "[specify] Warning: Git repository not detected; skipped branch validation" >&2
        return 0
    fi

    if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $branch" >&2
        echo "Feature branches should be named like: 001-feature-name" >&2
        return 1
    fi

    return 0
}

get_feature_dir() { echo "$1/specs/$2"; }

# Find feature directory by numeric prefix instead of exact branch match
# This allows multiple branches to work on the same spec (e.g., 004-fix-bug, 004-add-feature)
find_feature_dir_by_prefix() {
    local repo_root="$1"
    local branch_name="$2"
    local specs_dir="$repo_root/specs"

    # Extract numeric prefix from branch (e.g., "004" from "004-whatever")
    if [[ ! "$branch_name" =~ ^([0-9]{3})- ]]; then
        # If branch doesn't have numeric prefix, fall back to exact match
        echo "$specs_dir/$branch_name"
        return
    fi

    local prefix="${BASH_REMATCH[1]}"

    # Search for directories in specs/ that start with this prefix
    local matches=()
    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/"$prefix"-*; do
            if [[ -d "$dir" ]]; then
                matches+=("$(basename "$dir")")
            fi
        done
    fi

    # Handle results
    if [[ ${#matches[@]} -eq 0 ]]; then
        # No match found - return the branch name path (will fail later with clear error)
        echo "$specs_dir/$branch_name"
    elif [[ ${#matches[@]} -eq 1 ]]; then
        # Exactly one match - perfect!
        echo "$specs_dir/${matches[0]}"
    else
        # Multiple matches - this shouldn't happen with proper naming convention
        echo "ERROR: Multiple spec directories found with prefix '$prefix': ${matches[*]}" >&2
        echo "Please ensure only one spec directory exists per numeric prefix." >&2
        echo "$specs_dir/$branch_name"  # Return something to avoid breaking the script
    fi
}

get_feature_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    local has_git_repo="false"

    if has_git; then
        has_git_repo="true"
    fi

    # Use prefix-based lookup to support multiple branches per spec
    local feature_dir=$(find_feature_dir_by_prefix "$repo_root" "$current_branch")

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
HAS_GIT='$has_git_repo'
FEATURE_DIR='$feature_dir'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/plan.md'
TASKS='$feature_dir/tasks.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
QUICKSTART='$feature_dir/quickstart.md'
CONTRACTS_DIR='$feature_dir/contracts'
EOF
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }


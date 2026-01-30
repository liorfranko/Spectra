#!/usr/bin/env bash
# spectra/scripts/common.sh - Common utilities for spectra scripts
# Provides path helpers, JSON output, error handling, and utility functions
set -euo pipefail

# =============================================================================
# Path Helper Functions
# =============================================================================

# Get the git repository root directory
# Usage: repo_root=$(get_repo_root)
get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || {
        error "Not in a git repository"
    }
}

# Get the specs/ directory path
# Usage: specs_dir=$(get_specs_dir)
get_specs_dir() {
    local repo_root
    repo_root=$(get_repo_root)
    echo "${repo_root}/specs"
}

# Get the current feature directory
# Uses branch name pattern [###]-[short-name] or accepts feature identifier as argument
# Usage: feature_dir=$(get_feature_dir) or feature_dir=$(get_feature_dir "003-user-auth")
get_feature_dir() {
    local feature_id="${1:-}"
    local specs_dir
    specs_dir=$(get_specs_dir)

    if [[ -z "$feature_id" ]]; then
        # Extract from current branch name
        local branch_name
        branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
            error "Failed to get current branch name"
        }

        # Match pattern: [###]-[short-name] (e.g., 003-user-auth)
        if [[ "$branch_name" =~ ^([0-9]{3}-[a-z0-9-]+) ]]; then
            feature_id="${BASH_REMATCH[1]}"
        else
            error "Branch name '${branch_name}' does not match feature pattern [###]-[short-name]"
        fi
    fi

    echo "${specs_dir}/${feature_id}"
}

# Calculate the next feature number (highest across all branches + 1)
# Returns zero-padded 3-digit number (e.g., "004")
# Usage: next_num=$(get_next_feature_number)
get_next_feature_number() {
    local specs_dir
    specs_dir=$(get_specs_dir)

    local max_num=0

    # Check existing feature directories in specs/
    if [[ -d "$specs_dir" ]]; then
        while IFS= read -r dir; do
            local basename
            basename=$(basename "$dir")
            # Extract number from pattern [###]-[short-name]
            if [[ "$basename" =~ ^([0-9]{3})- ]]; then
                local num="${BASH_REMATCH[1]}"
                # Remove leading zeros for numeric comparison
                num=$((10#$num))
                if (( num > max_num )); then
                    max_num=$num
                fi
            fi
        done < <(find "$specs_dir" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null)
    fi

    # Also check git branches for feature patterns
    while IFS= read -r branch; do
        # Extract number from pattern [###]-[short-name]
        if [[ "$branch" =~ ^([0-9]{3})- ]]; then
            local num="${BASH_REMATCH[1]}"
            # Remove leading zeros for numeric comparison
            num=$((10#$num))
            if (( num > max_num )); then
                max_num=$num
            fi
        fi
    done < <(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)

    # Return next number, zero-padded to 3 digits
    printf "%03d\n" $((max_num + 1))
}

# =============================================================================
# JSON Output Functions
# =============================================================================

# Output a JSON object with key-value pairs
# Usage: json_output "key1" "value1" "key2" "value2" ...
# Keys and values are automatically escaped
json_output() {
    local first=true
    echo -n "{"

    while (( $# >= 2 )); do
        local key="$1"
        local value="$2"
        shift 2

        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo -n ","
        fi

        # Escape JSON special characters: backslash, quotes, tabs, newlines, carriage returns
        key=$(printf '%s' "$key" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g' | tr '\n' ' ')
        value=$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g' | tr '\n' ' ')

        echo -n "\"${key}\":\"${value}\""
    done

    echo "}"
}

# Output a JSON error object
# Usage: json_error "Error message" [exit_code]
json_error() {
    local message="$1"
    local exit_code="${2:-1}"

    json_output "error" "true" "message" "$message" "exit_code" "$exit_code"
    return "$exit_code"
}

# =============================================================================
# Error Handling Functions
# =============================================================================

# Print error message to stderr and exit
# Usage: error "Something went wrong"
error() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: ${message}" >&2
    exit "$exit_code"
}

# Print warning message to stderr (does not exit)
# Usage: warn "This might be a problem"
warn() {
    local message="$1"
    echo "WARNING: ${message}" >&2
}

# Print info message to stderr (for --verbose mode)
# Usage: info "Processing file..."
info() {
    local message="$1"
    echo "INFO: ${message}" >&2
}

# =============================================================================
# Utility Functions
# =============================================================================

# Check if a command exists, error if not
# Usage: require_command "jq" "jq is required for JSON parsing"
require_command() {
    local cmd="$1"
    local message="${2:-Command '${cmd}' is required but not found}"

    if ! command -v "$cmd" &>/dev/null; then
        error "$message"
    fi
}

# Check if a command exists, return true/false without exiting
# Usage: if has_command "bc"; then ... fi
has_command() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

# Safe arithmetic with bc, falls back to integer arithmetic if bc not available
# Usage: result=$(safe_calc "1.5 + 2.3" "4")  # fallback value if bc unavailable
safe_calc() {
    local expression="$1"
    local fallback="${2:-0}"

    if has_command "bc"; then
        echo "$expression" | bc -l 2>/dev/null || echo "$fallback"
    else
        warn "bc not available, using fallback value for: $expression"
        echo "$fallback"
    fi
}

# Safe floating-point comparison, returns 0 (true) or 1 (false)
# Usage: if safe_compare "1.5 > 1.0"; then ... fi
safe_compare() {
    local expression="$1"

    if has_command "bc"; then
        local result
        result=$(echo "$expression" | bc -l 2>/dev/null || echo "0")
        [[ "$result" == "1" ]]
    else
        warn "bc not available, comparison failed for: $expression"
        return 1
    fi
}

# Check if a file exists, error if not
# Usage: require_file "/path/to/file" "Configuration file not found"
require_file() {
    local filepath="$1"
    local message="${2:-File '${filepath}' not found}"

    if [[ ! -f "$filepath" ]]; then
        error "$message"
    fi
}

# Convert text to kebab-case slug (lowercase, hyphens, 2-4 words)
# Usage: slug=$(slugify "My Feature Name")
# Output: my-feature-name
slugify() {
    local text="$1"
    local max_words="${2:-4}"

    # Convert to lowercase, replace non-alphanumeric with hyphens, collapse multiple hyphens
    # Use printf for safer handling of special characters
    local slug
    slug=$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')

    # Limit to max_words (count by hyphens)
    local word_count
    word_count=$(printf '%s' "$slug" | tr '-' '\n' | wc -l | tr -d ' ')

    if (( word_count > max_words )); then
        slug=$(printf '%s' "$slug" | cut -d'-' -f1-"${max_words}")
    fi

    # Ensure at least 2 words worth of content (or return as-is if single word)
    printf '%s\n' "$slug"
}

# =============================================================================
# Worktree Helper Functions
# =============================================================================

# Check if current directory is inside a git worktree
# Returns: "true" if in a worktree, "false" otherwise
# Usage: if [[ "$(is_worktree)" == "true" ]]; then ... fi
is_worktree() {
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
        echo "false"
        return
    }

    # If git-dir contains "worktrees", we're in a worktree
    if [[ "$git_dir" == *"/worktrees/"* ]] || [[ "$git_dir" == *"/.git/worktrees/"* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Get the main repository path from a worktree
# Returns: Path to main repository, or current repo root if not in worktree
# Usage: main_repo=$(get_main_repo_from_worktree)
get_main_repo_from_worktree() {
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
        error "Not in a git repository"
    }

    if [[ "$(is_worktree)" == "true" ]]; then
        # Extract main repo path from gitdir file or path
        # Worktree git-dir format: /path/to/main/.git/worktrees/branch-name
        local main_git_dir
        main_git_dir=$(echo "$git_dir" | sed 's|/worktrees/[^/]*$||')
        # Remove .git suffix to get repo root
        echo "${main_git_dir%/.git}"
    else
        git rev-parse --show-toplevel
    fi
}

# Get the worktree path for a given branch
# Returns: Worktree path if exists, empty string otherwise
# Usage: wt_path=$(get_worktree_for_branch "001-my-feature")
get_worktree_for_branch() {
    local branch_name="$1"
    git worktree list --porcelain 2>/dev/null | \
        awk -v branch="$branch_name" '
            /^worktree / { wt = substr($0, 10) }
            /^branch / {
                b = substr($0, 8)
                gsub(/^refs\/heads\//, "", b)
                if (b == branch) print wt
            }
        '
}

# Remove a worktree safely
# Usage: remove_worktree "/path/to/worktree"
# Returns: 0 on success, 1 on failure
remove_worktree() {
    local worktree_path="$1"
    local force="${2:-false}"

    if [[ ! -d "$worktree_path" ]]; then
        warn "Worktree path does not exist: $worktree_path"
        return 0
    fi

    local force_flag=""
    [[ "$force" == "true" ]] && force_flag="--force"

    if git worktree remove "$worktree_path" $force_flag 2>/dev/null; then
        return 0
    else
        # Fallback: manual cleanup
        warn "git worktree remove failed, attempting manual cleanup"
        rm -rf "$worktree_path" 2>/dev/null || return 1
        git worktree prune 2>/dev/null || true
        return 0
    fi
}

# Check if we should warn about being in wrong context (main vs worktree)
# Usage: check_worktree_context "implement"  # warns if not in worktree for implement
check_worktree_context() {
    local command="$1"
    local in_worktree
    in_worktree=$(is_worktree)

    case "$command" in
        specify|constitution)
            # These should typically run from main repo
            if [[ "$in_worktree" == "true" ]]; then
                warn "Running '$command' from a worktree. Consider running from main repository."
            fi
            ;;
        implement|review|accept)
            # These should typically run from worktree
            if [[ "$in_worktree" == "false" ]]; then
                local branch
                branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
                if [[ "$branch" =~ ^[0-9]{3}-[a-z0-9-]+$ ]]; then
                    local wt_path
                    wt_path=$(get_worktree_for_branch "$branch")
                    if [[ -n "$wt_path" ]]; then
                        warn "A worktree exists for branch '$branch' at: $wt_path"
                        warn "Consider running '$command' from the worktree: cd $wt_path"
                    fi
                fi
            fi
            ;;
    esac
}

# Get base branch (main/master) for the repository
# Usage: base=$(get_base_branch)
get_base_branch() {
    # Try to get from remote HEAD
    local base
    base=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)

    if [[ -z "$base" ]]; then
        # Fallback: check if main or master exists
        if git rev-parse --verify main &>/dev/null; then
            base="main"
        elif git rev-parse --verify master &>/dev/null; then
            base="master"
        else
            base="main"  # Default
        fi
    fi

    echo "$base"
}

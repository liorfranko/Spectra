#!/usr/bin/env bash
# =============================================================================
# common.sh - Shared utility functions for projspec scripts
# =============================================================================
# This file provides common utility functions used by all projspec bash scripts.
# Source this file at the beginning of other scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Version information
readonly PROJSPEC_VERSION="0.1.0"

# Default output format (text or json)
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"

# Feature branch pattern: NNN-feature-name (e.g., 001-user-auth)
readonly FEATURE_BRANCH_PATTERN='^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$'

# =============================================================================
# Color Configuration
# =============================================================================

# Check if stdout is a terminal for colored output
if [[ -t 1 ]]; then
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_BOLD='\033[1m'
else
    readonly COLOR_RESET=''
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_BOLD=''
fi

# =============================================================================
# Output Utilities
# =============================================================================

# log_info - Print info message (blue)
# Usage: log_info "Processing files..."
log_info() {
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        return 0  # Suppress logs in JSON mode
    fi
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

# log_success - Print success message (green)
# Usage: log_success "Operation completed"
log_success() {
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        return 0  # Suppress logs in JSON mode
    fi
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

# log_warning - Print warning message (yellow) to stderr
# Usage: log_warning "File already exists"
log_warning() {
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        return 0  # Suppress logs in JSON mode
    fi
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*" >&2
}

# log_error - Print error message (red) to stderr
# Usage: log_error "Failed to read file"
log_error() {
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        # In JSON mode, output error as JSON to stderr
        echo "{\"error\": \"$*\"}" >&2
        return 0
    fi
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

# =============================================================================
# JSON Output Support
# =============================================================================

# json_output - Output data in JSON format
# Usage: json_output "key1" "value1" "key2" "value2" ...
# Note: Handles simple key-value pairs. For complex structures, build JSON manually.
json_output() {
    local output="{"
    local first=true

    while [[ $# -ge 2 ]]; do
        local key="$1"
        local value="$2"
        shift 2

        if [[ "$first" == "true" ]]; then
            first=false
        else
            output+=", "
        fi

        # Escape special characters in value
        value="${value//\\/\\\\}"  # Escape backslashes first
        value="${value//\"/\\\"}"  # Escape quotes
        value="${value//$'\n'/\\n}"  # Escape newlines
        value="${value//$'\t'/\\t}"  # Escape tabs

        output+="\"$key\": \"$value\""
    done

    output+="}"
    echo "$output"
}

# json_array - Output an array of values in JSON format
# Usage: json_array "value1" "value2" "value3"
json_array() {
    local output="["
    local first=true

    for value in "$@"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            output+=", "
        fi

        # Escape special characters
        value="${value//\\/\\\\}"
        value="${value//\"/\\\"}"
        value="${value//$'\n'/\\n}"
        value="${value//$'\t'/\\t}"

        output+="\"$value\""
    done

    output+="]"
    echo "$output"
}

# json_bool - Convert bash true/false to JSON boolean
# Usage: json_bool "$result" -> "true" or "false"
json_bool() {
    if [[ "$1" == "true" || "$1" == "0" || "$1" == "yes" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# =============================================================================
# String Utilities
# =============================================================================

# slugify - Convert text to URL-friendly slug format
# Usage: slugify "My Feature Name" -> "my-feature-name"
slugify() {
    local text="$1"

    # Convert to lowercase (compatible with older bash/zsh)
    text=$(echo "$text" | tr '[:upper:]' '[:lower:]')

    # Replace spaces and underscores with hyphens
    text=$(echo "$text" | tr ' _' '-')

    # Remove any character that isn't alphanumeric or hyphen
    text=$(echo "$text" | sed 's/[^a-z0-9-]//g')

    # Collapse multiple hyphens into one
    text=$(echo "$text" | sed 's/-\{2,\}/-/g')

    # Remove leading/trailing hyphens
    text="${text#-}"
    text="${text%-}"

    echo "$text"
}

# =============================================================================
# Repository Functions
# =============================================================================

# has_git - Check if git is available and we're in a git repo
# Usage: if has_git; then ...; fi
# Returns: exit 0 if git available and in repo, exit 1 otherwise
has_git() {
    command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1
}

# get_repo_root - Find repository root (handles worktrees)
# For a worktree, returns the worktree's root directory
# Usage: root=$(get_repo_root)
# Output: stdout - path to repository root, empty string if not in git repo
get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || echo ""
}

# get_main_repo_root - Find main repo root (not worktree)
# For a worktree, returns the main repository's root
# Usage: main_root=$(get_main_repo_root)
# Output: stdout - path to main repository root, empty string if not in git repo
get_main_repo_root() {
    local git_common_dir
    local git_dir
    local resolved_common

    # Get the common git directory
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null) || {
        echo ""
        return 1
    }

    # If it's a relative path, resolve it
    if [[ ! "$git_common_dir" = /* ]]; then
        git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
            echo ""
            return 1
        }

        if [[ ! "$git_dir" = /* ]]; then
            git_dir="$(pwd)/$git_dir"
        fi

        # Resolve the path
        resolved_common=$(cd "$(dirname "$git_dir")" && cd "$(dirname "$git_common_dir")" && pwd)/$(basename "$git_common_dir")
    else
        resolved_common="$git_common_dir"
    fi

    # The common dir is the .git directory of the main repo
    # The main repo root is its parent (unless it's a bare repo)
    if [[ "$(basename "$resolved_common")" == ".git" ]]; then
        dirname "$resolved_common"
    else
        dirname "$resolved_common"
    fi
}

# get_current_branch - Get current git branch name
# Usage: branch=$(get_current_branch)
# Output: stdout - branch name, empty string if not in repo or detached HEAD
get_current_branch() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
        echo ""
        return 0
    }

    # In detached HEAD state, git returns "HEAD"
    if [[ "$branch" == "HEAD" ]]; then
        echo ""
    else
        echo "$branch"
    fi
}

# is_worktree - Check if current directory is a git worktree
# Usage: if is_worktree; then ...; fi
# Returns: exit 0 if worktree, exit 1 if not
is_worktree() {
    local git_dir
    local common_dir
    local resolved_git_dir
    local resolved_common_dir

    git_dir=$(git rev-parse --git-dir 2>/dev/null) || return 1
    common_dir=$(git rev-parse --git-common-dir 2>/dev/null) || return 1

    # Resolve git_dir to absolute path
    if [[ ! "$git_dir" = /* ]]; then
        resolved_git_dir="$(cd "$(pwd)" && cd "$(dirname "$git_dir")" && pwd)/$(basename "$git_dir")"
    else
        resolved_git_dir="$git_dir"
    fi

    # Resolve common_dir to absolute path
    if [[ ! "$common_dir" = /* ]]; then
        # Common dir is relative to git_dir's parent
        resolved_common_dir="$(cd "$(dirname "$resolved_git_dir")" && cd "$(dirname "$common_dir")" && pwd)/$(basename "$common_dir")"
    else
        resolved_common_dir="$common_dir"
    fi

    # In a worktree, git-dir and git-common-dir are different
    [[ "$resolved_git_dir" != "$resolved_common_dir" ]]
}

# get_worktree_path - Get worktree path for a given branch name
# Usage: path=$(get_worktree_path "001-feature")
# Args: $1 - branch name
# Output: stdout - path to worktree, empty string if not found
get_worktree_path() {
    local branch="${1:-}"

    if [[ -z "$branch" ]]; then
        echo ""
        return 1
    fi

    # Parse worktree list output
    local current_path=""

    while IFS= read -r line; do
        if [[ "$line" == worktree\ * ]]; then
            current_path="${line#worktree }"
        elif [[ "$line" == branch\ * ]]; then
            local branch_ref="${line#branch }"
            # Branch is in refs/heads/name format
            local branch_name="${branch_ref#refs/heads/}"
            if [[ "$branch_name" == "$branch" ]]; then
                echo "$current_path"
                return 0
            fi
        elif [[ -z "$line" ]]; then
            current_path=""
        fi
    done < <(git worktree list --porcelain 2>/dev/null)

    echo ""
    return 1
}

# list_worktrees - List all worktrees in the repository
# Usage: list_worktrees
# Output: stdout - one worktree per line in format: path:branch
list_worktrees() {
    local current_path=""
    local current_branch=""

    while IFS= read -r line; do
        if [[ "$line" == worktree\ * ]]; then
            current_path="${line#worktree }"
        elif [[ "$line" == branch\ * ]]; then
            local branch_ref="${line#branch }"
            current_branch="${branch_ref#refs/heads/}"
        elif [[ "$line" == "detached" ]]; then
            current_branch="(detached)"
        elif [[ -z "$line" ]]; then
            if [[ -n "$current_path" ]]; then
                echo "${current_path}:${current_branch}"
            fi
            current_path=""
            current_branch=""
        fi
    done < <(git worktree list --porcelain 2>/dev/null)

    # Handle last entry
    if [[ -n "$current_path" ]]; then
        echo "${current_path}:${current_branch}"
    fi
}

# =============================================================================
# Feature Branch Functions
# =============================================================================

# check_feature_branch - Validate branch naming follows convention
# Usage: if check_feature_branch "001-my-feature"; then ...; fi
# Args: $1 - branch name to validate (defaults to current branch)
# Convention: NNN-feature-name (e.g., 001-initial-setup)
# Returns: exit 0 if valid, exit 1 if invalid
check_feature_branch() {
    local branch="${1:-$(get_current_branch)}"

    if [[ -z "$branch" ]]; then
        return 1
    fi

    [[ "$branch" =~ $FEATURE_BRANCH_PATTERN ]]
}

# extract_feature_id - Extract the feature ID (NNN) from a branch name
# Usage: id=$(extract_feature_id "001-user-auth") -> "001"
# Args: $1 - branch name
# Output: stdout - feature ID (3 digits), empty if invalid
extract_feature_id() {
    local branch="${1:-}"

    if ! check_feature_branch "$branch"; then
        echo ""
        return 1
    fi

    echo "${branch:0:3}"
}

# extract_feature_name - Extract the feature name from a branch name
# Usage: name=$(extract_feature_name "001-user-auth") -> "user-auth"
# Args: $1 - branch name
# Output: stdout - feature name portion, empty if invalid
extract_feature_name() {
    local branch="${1:-}"

    if ! check_feature_branch "$branch"; then
        echo ""
        return 1
    fi

    echo "${branch:4}"
}

# get_next_feature_number - Determine the next available feature number
# Usage: next=$(get_next_feature_number)
# Output: stdout - next feature number as 3-digit string (e.g., "003")
get_next_feature_number() {
    local main_root
    local specs_dir
    local max_num=0

    main_root=$(get_main_repo_root) || {
        echo "001"
        return 0
    }

    specs_dir="$main_root/specs"

    if [[ ! -d "$specs_dir" ]]; then
        echo "001"
        return 0
    fi

    # Scan existing feature directories
    for dir in "$specs_dir"/[0-9][0-9][0-9]-*/; do
        if [[ -d "$dir" ]]; then
            local dirname
            dirname=$(basename "$dir")
            local num="${dirname:0:3}"
            # Remove leading zeros for comparison
            num=$((10#$num))
            if [[ $num -gt $max_num ]]; then
                max_num=$num
            fi
        fi
    done

    # Return next number, zero-padded
    printf "%03d" $((max_num + 1))
}

# get_feature_dir - Get feature spec directory for current or specified feature
# Usage: dir=$(get_feature_dir) or dir=$(get_feature_dir "001-feature")
# Args: $1 - optional branch name (uses current branch if not provided)
# Output: stdout - path to feature spec directory
get_feature_dir() {
    local branch="${1:-$(get_current_branch)}"
    local main_root

    if [[ -z "$branch" ]]; then
        echo ""
        return 1
    fi

    if ! check_feature_branch "$branch"; then
        echo ""
        return 1
    fi

    main_root=$(get_main_repo_root) || {
        echo ""
        return 1
    }

    echo "$main_root/specs/$branch"
}

# get_feature_paths - Export feature-related paths as environment variables
# Usage: get_feature_paths or get_feature_paths "001-feature"
# Args: $1 - optional branch name (uses current branch if not provided)
# Exports:
#   FEATURE_ID - Feature number (e.g., "001")
#   FEATURE_NAME - Feature name portion (e.g., "user-auth")
#   FEATURE_BRANCH - Full branch name (e.g., "001-user-auth")
#   FEATURE_DIR - Path to feature spec directory
#   FEATURE_SPEC - Path to spec.md
#   IMPL_PLAN - Path to plan.md
#   WORKTREE - Path to worktree directory
#   MAIN_REPO - Path to main repository root
get_feature_paths() {
    local branch="${1:-$(get_current_branch)}"
    local main_root
    local feature_dir
    local worktree_path

    # Initialize exports to empty
    export FEATURE_ID=""
    export FEATURE_NAME=""
    export FEATURE_BRANCH=""
    export FEATURE_DIR=""
    export FEATURE_SPEC=""
    export IMPL_PLAN=""
    export WORKTREE=""
    export MAIN_REPO=""

    if [[ -z "$branch" ]]; then
        return 1
    fi

    if ! check_feature_branch "$branch"; then
        return 1
    fi

    main_root=$(get_main_repo_root) || return 1
    feature_dir="$main_root/specs/$branch"
    worktree_path=$(get_worktree_path "$branch") || worktree_path=""

    export FEATURE_ID="${branch:0:3}"
    export FEATURE_NAME="${branch:4}"
    export FEATURE_BRANCH="$branch"
    export FEATURE_DIR="$feature_dir"
    export FEATURE_SPEC="$feature_dir/spec.md"
    export IMPL_PLAN="$feature_dir/plan.md"
    export WORKTREE="${worktree_path:-$main_root/worktrees/$branch}"
    export MAIN_REPO="$main_root"
}

# =============================================================================
# Argument Parsing Helpers
# =============================================================================

# parse_common_args - Handle common flags (--json, --help, --version)
# Usage: parse_common_args "$@"
# Note: Sets OUTPUT_FORMAT=json if --json is passed
# Note: This function modifies global OUTPUT_FORMAT variable
# For custom help, define show_help() before calling this function
parse_common_args() {
    local remaining_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --version|-V)
                echo "projspec version $PROJSPEC_VERSION"
                exit 0
                ;;
            --help|-h)
                if declare -f show_help >/dev/null; then
                    show_help
                else
                    echo "Usage: $(basename "$0") [OPTIONS]"
                    echo ""
                    echo "Options:"
                    echo "  --json     Output in JSON format"
                    echo "  --version  Show version information"
                    echo "  --help     Show this help message"
                fi
                exit 0
                ;;
            *)
                remaining_args+=("$1")
                shift
                ;;
        esac
    done

    # Set positional parameters to remaining args
    set -- "${remaining_args[@]+"${remaining_args[@]}"}"

    # Return remaining args via REMAINING_ARGS array
    REMAINING_ARGS=("${remaining_args[@]+"${remaining_args[@]}"}")
}

# =============================================================================
# Validation Helpers
# =============================================================================

# require_git - Exit with error if not in a git repository
# Usage: require_git
require_git() {
    if ! has_git; then
        log_error "Not in a git repository"
        exit 1
    fi
}

# require_feature_branch - Exit with error if not on a feature branch
# Usage: require_feature_branch
require_feature_branch() {
    local branch
    branch=$(get_current_branch)

    if [[ -z "$branch" ]]; then
        log_error "Unable to determine current branch"
        exit 2
    fi

    if ! check_feature_branch "$branch"; then
        log_error "Not on a feature branch. Expected format: NNN-feature-name"
        exit 2
    fi
}

# require_clean_worktree - Exit with error if there are uncommitted changes
# Usage: require_clean_worktree
require_clean_worktree() {
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_error "Working tree has uncommitted changes"
        exit 1
    fi
}

# require_file - Exit with error if file doesn't exist
# Usage: require_file "/path/to/file" "Description of file"
require_file() {
    local filepath="$1"
    local description="${2:-$filepath}"

    if [[ ! -f "$filepath" ]]; then
        log_error "$description not found: $filepath"
        exit 1
    fi
}

# require_directory - Exit with error if directory doesn't exist
# Usage: require_directory "/path/to/dir" "Description of directory"
require_directory() {
    local dirpath="$1"
    local description="${2:-$dirpath}"

    if [[ ! -d "$dirpath" ]]; then
        log_error "$description not found: $dirpath"
        exit 1
    fi
}

# require_command - Exit with error if command is not available
# Usage: require_command "jq" "JSON processor"
require_command() {
    local cmd="$1"
    local description="${2:-$cmd}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "$description ($cmd) is required but not installed"
        exit 1
    fi
}

# =============================================================================
# Path Utilities
# =============================================================================

# get_script_dir - Get directory containing the current script
# Usage: script_dir=$(get_script_dir)
# Note: Call this at the top of your script before changing directory
get_script_dir() {
    local source="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
    local dir

    # Resolve symlinks
    while [[ -L "$source" ]]; do
        dir=$(cd -P "$(dirname "$source")" && pwd)
        source=$(readlink "$source")
        [[ $source != /* ]] && source="$dir/$source"
    done

    cd -P "$(dirname "$source")" && pwd
}

# resolve_path - Convert relative path to absolute
# Usage: abs_path=$(resolve_path "../relative/path")
resolve_path() {
    local path="$1"

    if [[ "$path" = /* ]]; then
        echo "$path"
    else
        echo "$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")"
    fi
}

# =============================================================================
# State Management
# =============================================================================

# get_feature_state - Get state from feature's state.yaml
# Usage: phase=$(get_feature_state "phase")
# Args: $1 - key to retrieve (e.g., "phase", "created_at")
# Output: stdout - value for the key, empty if not found
get_feature_state() {
    local key="$1"
    local feature_dir
    local state_file

    feature_dir=$(get_feature_dir) || return 1
    state_file="$feature_dir/state.yaml"

    if [[ ! -f "$state_file" ]]; then
        echo ""
        return 1
    fi

    # Simple YAML parsing for flat key-value pairs
    grep "^${key}:" "$state_file" 2>/dev/null | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//'
}

# =============================================================================
# End of common.sh
# =============================================================================

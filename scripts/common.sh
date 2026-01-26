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

# =============================================================================
# Output Utilities
# =============================================================================

# TODO: Implement colored output functions
# log_info() - Print info message (blue)
# log_success() - Print success message (green)
# log_warning() - Print warning message (yellow)
# log_error() - Print error message (red)

log_info() {
    # TODO: Implement colored info output
    echo "[INFO] $*"
}

log_success() {
    # TODO: Implement colored success output
    echo "[SUCCESS] $*"
}

log_warning() {
    # TODO: Implement colored warning output
    echo "[WARNING] $*" >&2
}

log_error() {
    # TODO: Implement colored error output
    echo "[ERROR] $*" >&2
}

# =============================================================================
# JSON Output Support
# =============================================================================

# TODO: Implement JSON output helper
# json_output() - Format output as JSON when --json flag is used

json_output() {
    # TODO: Implement JSON formatting
    # Should handle key-value pairs and nested structures
    echo "{}"
}

# =============================================================================
# Repository Functions
# =============================================================================

get_repo_root() {
    # TODO: Find repository root (handles worktrees)
    # Should work correctly whether in main repo or worktree
    git rev-parse --show-toplevel 2>/dev/null || echo ""
}

get_main_repo_root() {
    # TODO: Find main repo root (not worktree)
    # If in a worktree, navigate to the main repository
    local toplevel
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || return 1

    # TODO: Check if this is a worktree and find main repo
    echo "$toplevel"
}

get_current_branch() {
    # TODO: Get current git branch name
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

has_git() {
    # TODO: Check if git is available and we're in a git repo
    command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1
}

is_worktree() {
    # TODO: Check if current directory is a git worktree
    # Returns 0 if worktree, 1 if not
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || return 1

    # TODO: Implement worktree detection logic
    [[ -f "$git_dir/gitdir" ]]
}

get_worktree_path() {
    # TODO: Get worktree path for a given branch name
    # Args: $1 - branch name
    # Returns: path to worktree or empty string
    local branch="${1:-}"

    # TODO: Implement worktree path lookup
    echo ""
}

# =============================================================================
# Feature Branch Functions
# =============================================================================

check_feature_branch() {
    # TODO: Validate branch naming follows convention
    # Args: $1 - branch name to validate
    # Convention: NNN-feature-name (e.g., 001-initial-setup)
    local branch="${1:-}"

    # TODO: Implement naming convention validation
    [[ "$branch" =~ ^[0-9]{3}- ]]
}

get_feature_dir() {
    # TODO: Get feature spec directory for current or specified feature
    # Args: $1 - optional feature ID (uses current branch if not provided)
    local feature_id="${1:-}"

    # TODO: Implement feature directory lookup
    echo ""
}

get_feature_paths() {
    # TODO: Export feature-related paths as environment variables
    # Exports: FEATURE_SPEC, IMPL_PLAN, WORKTREE, FEATURE_ID, etc.
    # Args: $1 - optional feature ID
    local feature_id="${1:-}"

    # TODO: Implement path resolution and export
    export FEATURE_SPEC=""
    export IMPL_PLAN=""
    export WORKTREE=""
    export FEATURE_ID=""
}

# =============================================================================
# Argument Parsing Helpers
# =============================================================================

# TODO: Implement common argument parsing
# parse_common_args() - Handle --json, --help, --version flags

parse_common_args() {
    # TODO: Implement common argument parsing
    # Sets OUTPUT_FORMAT=json if --json is passed
    # Displays help/version as needed
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --version)
                echo "projspec version $PROJSPEC_VERSION"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

# =============================================================================
# Validation Helpers
# =============================================================================

require_git() {
    # TODO: Exit with error if not in a git repository
    if ! has_git; then
        log_error "Not in a git repository"
        exit 1
    fi
}

require_clean_worktree() {
    # TODO: Exit with error if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_error "Working tree has uncommitted changes"
        exit 1
    fi
}

# =============================================================================
# End of common.sh
# =============================================================================

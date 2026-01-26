#!/usr/bin/env bash
# =============================================================================
# create-new-feature.sh - Create new feature branch, worktree, and spec
# =============================================================================
# This script automates the creation of a new feature including:
# - Creating a new feature branch with proper naming convention
# - Setting up a git worktree for isolated development
# - Creating the feature specification directory structure
# - Initializing template files
#
# Usage:
#   ./create-new-feature.sh <feature-name> [options]
#
# Arguments:
#   feature-name    Short descriptive name (will be slugified)
#
# Options:
#   --id <NNN>      Specify feature ID (auto-increments if not provided)
#   --base <branch> Base branch to create from (default: main)
#   --no-worktree   Skip worktree creation
#   --json          Output results in JSON format
#
# Examples:
#   ./create-new-feature.sh user-authentication
#   ./create-new-feature.sh api-refactor --id 042 --base develop
#
# Exit codes:
#   0 - Feature created successfully
#   1 - Error during creation
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Default base branch
DEFAULT_BASE_BRANCH="main"

# Worktree directory pattern
WORKTREE_DIR_PATTERN="worktrees"

# Feature spec directory pattern
SPEC_DIR_PATTERN="specs"

# =============================================================================
# Helper Functions
# =============================================================================

slugify() {
    # TODO: Convert feature name to URL-safe slug
    # Args: $1 - feature name
    # Returns: slugified name (lowercase, hyphens)
    local name="${1:-}"
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'
}

get_next_feature_id() {
    # TODO: Determine next available feature ID
    # Scans existing branches/specs for highest ID and increments
    # Returns: three-digit ID (e.g., "042")
    echo "001"
}

validate_feature_name() {
    # TODO: Validate feature name is acceptable
    # Args: $1 - feature name
    # Returns: 0 if valid, 1 if invalid
    local name="${1:-}"
    [[ -n "$name" ]] && [[ "$name" =~ ^[a-zA-Z] ]]
}

create_feature_branch() {
    # TODO: Create new git branch with proper naming
    # Args: $1 - feature ID, $2 - feature slug, $3 - base branch
    local feature_id="${1:-}"
    local feature_slug="${2:-}"
    local base_branch="${3:-$DEFAULT_BASE_BRANCH}"

    local branch_name="${feature_id}-${feature_slug}"

    log_info "Creating branch: $branch_name from $base_branch"
    # TODO: Implement branch creation
    # git checkout -b "$branch_name" "$base_branch"
}

create_worktree() {
    # TODO: Create git worktree for the feature branch
    # Args: $1 - branch name
    local branch_name="${1:-}"

    log_info "Creating worktree for: $branch_name"
    # TODO: Implement worktree creation
    # git worktree add "worktrees/$branch_name" "$branch_name"
}

create_spec_directory() {
    # TODO: Create feature specification directory structure
    # Args: $1 - feature ID, $2 - feature slug
    local feature_id="${1:-}"
    local feature_slug="${2:-}"

    log_info "Creating spec directory structure"
    # TODO: Implement directory creation
    # mkdir -p "specs/${feature_id}-${feature_slug}"
}

initialize_templates() {
    # TODO: Copy and initialize template files
    # Args: $1 - feature ID, $2 - feature slug
    local feature_id="${1:-}"
    local feature_slug="${2:-}"

    log_info "Initializing templates"
    # TODO: Copy spec.md, plan.md templates
    # TODO: Replace placeholders with feature info
}

# =============================================================================
# Main
# =============================================================================

main() {
    # TODO: Parse command line arguments
    # TODO: Validate inputs
    # TODO: Check prerequisites
    # TODO: Create feature branch
    # TODO: Create worktree (if not --no-worktree)
    # TODO: Create spec directory
    # TODO: Initialize templates
    # TODO: Output results

    local feature_name="${1:-}"

    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        echo "Usage: $0 <feature-name> [options]"
        exit 1
    fi

    require_git

    local feature_slug
    feature_slug=$(slugify "$feature_name")

    local feature_id
    feature_id=$(get_next_feature_id)

    log_info "Creating new feature: ${feature_id}-${feature_slug}"

    # TODO: Implement full creation flow

    log_success "Feature created: ${feature_id}-${feature_slug}"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

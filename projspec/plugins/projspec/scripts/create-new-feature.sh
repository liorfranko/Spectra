#!/usr/bin/env bash
# projspec/scripts/create-new-feature.sh - Create a new feature branch and directory structure
# Creates git branch (or worktree), specs directory, and checklists directory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Script Configuration
# =============================================================================

OUTPUT_JSON=false
NO_WORKTREE=false
DESCRIPTION=""

# =============================================================================
# Usage and Help
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") <feature-description> [options]

Create a new feature branch and directory structure.

Arguments:
  feature-description    Required. A brief description of the feature.
                        Will be converted to a short name (e.g., "User Auth Flow" -> "user-auth-flow")

Options:
  --json                Output in JSON format
  --no-worktree         Skip worktree creation (just create branch in current repo)
  -h, --help            Show this help message

Examples:
  $(basename "$0") "User Authentication"
  $(basename "$0") "API Rate Limiting" --json
  $(basename "$0") "Database Migration" --no-worktree

Output:
  Creates:
    - Git branch: [###]-[short-name] (e.g., 003-user-auth)
    - Directory: specs/[###]-[short-name]/
    - Directory: specs/[###]-[short-name]/checklists/

  JSON output format:
    {"FEATURE_ID": "003-user-auth", "FEATURE_DIR": "/path/to/specs/003-user-auth", "BRANCH": "003-user-auth"}
EOF
}

# =============================================================================
# Argument Parsing
# =============================================================================

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --json)
                OUTPUT_JSON=true
                shift
                ;;
            --no-worktree)
                NO_WORKTREE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                if [[ -z "$DESCRIPTION" ]]; then
                    DESCRIPTION="$1"
                else
                    error "Unexpected argument: $1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$DESCRIPTION" ]]; then
        error "Feature description is required. Use --help for usage."
    fi
}

# =============================================================================
# Main Feature Creation Logic
# =============================================================================

create_feature() {
    local repo_root
    repo_root=$(get_repo_root)

    # Generate short name from description
    local short_name
    short_name=$(slugify "$DESCRIPTION")

    # Validate slug is not empty and contains at least one alphanumeric character
    if [[ -z "$short_name" || "$short_name" =~ ^-*$ ]]; then
        error "Could not generate a valid short name from description: '$DESCRIPTION' (must contain alphanumeric characters)"
    fi

    # Get next feature number
    local feature_number
    feature_number=$(get_next_feature_number)

    # Create feature ID
    local feature_id="${feature_number}-${short_name}"
    local branch_name="$feature_id"

    # Determine paths
    local specs_dir="${repo_root}/specs"
    local feature_dir="${specs_dir}/${feature_id}"
    local checklists_dir="${feature_dir}/checklists"

    # Check if feature already exists
    if [[ -d "$feature_dir" ]]; then
        error "Feature directory already exists: $feature_dir"
    fi

    if git show-ref --verify --quiet "refs/heads/${branch_name}" 2>/dev/null; then
        error "Branch already exists: $branch_name"
    fi

    # Create git branch or worktree
    if [[ "$NO_WORKTREE" == "true" ]]; then
        # Create branch in current repo
        local git_output
        if ! git_output=$(git branch "$branch_name" 2>&1); then
            error "Failed to create branch '$branch_name': $git_output"
        fi
        if ! git_output=$(git checkout "$branch_name" 2>&1); then
            error "Failed to checkout branch '$branch_name': $git_output"
        fi
    else
        # Create worktree
        local worktrees_dir
        worktrees_dir=$(dirname "$repo_root")/worktrees

        # Ensure worktrees directory exists
        mkdir -p "$worktrees_dir"

        local worktree_path="${worktrees_dir}/${feature_id}"

        if [[ -d "$worktree_path" ]]; then
            error "Worktree directory already exists: $worktree_path"
        fi

        local git_output
        if ! git_output=$(git worktree add "$worktree_path" -b "$branch_name" 2>&1); then
            error "Failed to create worktree at '$worktree_path': $git_output"
        fi

        # Update paths for worktree context
        specs_dir="${worktree_path}/specs"
        feature_dir="${specs_dir}/${feature_id}"
        checklists_dir="${feature_dir}/checklists"
    fi

    # Create directory structure
    mkdir -p "$checklists_dir" || {
        error "Failed to create directory: $checklists_dir"
    }

    # Output results
    if [[ "$OUTPUT_JSON" == "true" ]]; then
        json_output \
            "FEATURE_ID" "$feature_id" \
            "FEATURE_DIR" "$feature_dir" \
            "BRANCH" "$branch_name"
    else
        echo "Feature created successfully!"
        echo ""
        echo "  Feature ID:  $feature_id"
        echo "  Branch:      $branch_name"
        echo "  Directory:   $feature_dir"
        echo ""
        if [[ "$NO_WORKTREE" == "true" ]]; then
            echo "Switched to branch '$branch_name'"
        else
            echo "Worktree created at: $(dirname "$repo_root")/worktrees/${feature_id}"
            echo ""
            echo "To start working on this feature:"
            echo "  cd $(dirname "$repo_root")/worktrees/${feature_id}"
        fi
    fi
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    parse_args "$@"
    create_feature
}

main "$@"

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

# Stop words to remove from slugs
STOP_WORDS=(the a an in on for to of and with is are be been being was were)

# Maximum slug length (GitHub branch limit is 244 bytes)
MAX_SLUG_LENGTH=100

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << 'EOF'
Usage: create-new-feature.sh <feature-name> [options]

Create a new feature with branch, worktree, and specification structure.

Arguments:
  feature-name    Short descriptive name (will be slugified)

Options:
  --id <NNN>      Specify feature ID (auto-increments if not provided)
  --base <branch> Base branch to create from (default: main)
  --no-worktree   Skip worktree creation
  --json          Output results in JSON format
  --help          Show this help message
  --version       Show version information

Examples:
  ./create-new-feature.sh user-authentication
  ./create-new-feature.sh "API Refactor" --id 042 --base develop
  ./create-new-feature.sh "the new feature for authentication" --json
EOF
}

slugify_with_stop_words() {
    # Convert feature name to URL-safe slug with stop word removal
    # Args: $1 - feature name
    # Returns: slugified name (lowercase, hyphens, no stop words)
    local name="${1:-}"
    local result=""

    # Convert to lowercase
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Replace spaces and underscores with hyphens
    name=$(echo "$name" | tr ' _' '-')

    # Remove any character that isn't alphanumeric or hyphen
    name=$(echo "$name" | sed 's/[^a-z0-9-]//g')

    # Split by hyphens and filter stop words
    IFS='-' read -ra words <<< "$name"
    local filtered_words=()

    for word in "${words[@]}"; do
        [[ -z "$word" ]] && continue

        local is_stop_word=false
        for stop in "${STOP_WORDS[@]}"; do
            if [[ "$word" == "$stop" ]]; then
                is_stop_word=true
                break
            fi
        done

        if [[ "$is_stop_word" == "false" ]]; then
            filtered_words+=("$word")
        fi
    done

    # Join with hyphens
    result=$(IFS='-'; echo "${filtered_words[*]}")

    # Collapse multiple hyphens into one
    result=$(echo "$result" | sed 's/-\{2,\}/-/g')

    # Remove leading/trailing hyphens
    result="${result#-}"
    result="${result%-}"

    # Truncate to maximum length
    if [[ ${#result} -gt $MAX_SLUG_LENGTH ]]; then
        result="${result:0:$MAX_SLUG_LENGTH}"
        # Don't end with a hyphen after truncation
        result="${result%-}"
    fi

    echo "$result"
}

get_next_feature_id() {
    # Determine next available feature ID by scanning specs/ directory
    # Returns: three-digit ID (e.g., "042")
    local main_root
    local specs_dir
    local max_num=0

    main_root=$(get_main_repo_root) || {
        echo "001"
        return 0
    }

    specs_dir="$main_root/$SPEC_DIR_PATTERN"

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
            # Remove leading zeros for comparison (handle as base 10)
            num=$((10#$num))
            if [[ $num -gt $max_num ]]; then
                max_num=$num
            fi
        fi
    done

    # Also check existing branches for feature IDs
    while IFS= read -r branch; do
        if [[ "$branch" =~ ^[0-9]{3}- ]]; then
            local num="${branch:0:3}"
            num=$((10#$num))
            if [[ $num -gt $max_num ]]; then
                max_num=$num
            fi
        fi
    done < <(git branch --list --format='%(refname:short)' 2>/dev/null)

    # Return next number, zero-padded
    printf "%03d" $((max_num + 1))
}

validate_feature_name() {
    # Validate feature name is acceptable
    # Args: $1 - feature name
    # Returns: 0 if valid, 1 if invalid
    local name="${1:-}"

    # Must not be empty
    if [[ -z "$name" ]]; then
        return 1
    fi

    # Must start with a letter
    if [[ ! "$name" =~ ^[a-zA-Z] ]]; then
        return 1
    fi

    return 0
}

validate_feature_id() {
    # Validate feature ID format (3 digits)
    # Args: $1 - feature ID
    # Returns: 0 if valid, 1 if invalid
    local id="${1:-}"

    [[ "$id" =~ ^[0-9]{3}$ ]]
}

branch_exists() {
    # Check if a branch already exists
    # Args: $1 - branch name
    # Returns: 0 if exists, 1 if not
    local branch="${1:-}"

    git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null
}

create_feature_branch() {
    # Create new git branch with proper naming
    # Args: $1 - feature ID, $2 - feature slug, $3 - base branch
    local feature_id="${1:-}"
    local feature_slug="${2:-}"
    local base_branch="${3:-$DEFAULT_BASE_BRANCH}"

    local branch_name="${feature_id}-${feature_slug}"

    # Check if branch already exists
    if branch_exists "$branch_name"; then
        log_error "Branch '$branch_name' already exists"
        return 1
    fi

    # Verify base branch exists
    if ! branch_exists "$base_branch" && ! git show-ref --verify --quiet "refs/remotes/origin/$base_branch" 2>/dev/null; then
        log_error "Base branch '$base_branch' does not exist"
        return 1
    fi

    log_info "Creating branch: $branch_name from $base_branch"

    # Create branch without switching to it
    git branch "$branch_name" "$base_branch" || {
        log_error "Failed to create branch '$branch_name'"
        return 1
    }

    echo "$branch_name"
}

create_worktree() {
    # Create git worktree for the feature branch with symlinks
    # Args: $1 - branch name, $2 - main repo root
    local branch_name="${1:-}"
    local main_root="${2:-}"

    local worktree_dir="$main_root/$WORKTREE_DIR_PATTERN/$branch_name"

    # Check if worktree already exists
    if [[ -d "$worktree_dir" ]]; then
        log_error "Worktree directory already exists: $worktree_dir"
        return 1
    fi

    log_info "Creating worktree for: $branch_name"

    # Create worktrees directory if it doesn't exist
    mkdir -p "$main_root/$WORKTREE_DIR_PATTERN"

    # Create the worktree
    git worktree add "$worktree_dir" "$branch_name" || {
        log_error "Failed to create worktree at '$worktree_dir'"
        return 1
    }

    log_info "Creating symlinks in worktree"

    # Create symlink to specs/ directory
    if [[ -d "$main_root/$SPEC_DIR_PATTERN" ]]; then
        ln -sfn "../../$SPEC_DIR_PATTERN" "$worktree_dir/$SPEC_DIR_PATTERN" || {
            log_warning "Failed to create symlink to specs/"
        }
    fi

    # Create symlink to .specify/ directory
    if [[ -d "$main_root/.specify" ]]; then
        ln -sfn "../../.specify" "$worktree_dir/.specify" || {
            log_warning "Failed to create symlink to .specify/"
        }
    fi

    echo "$worktree_dir"
}

create_spec_directory() {
    # Create feature specification directory structure
    # Args: $1 - feature ID, $2 - feature slug, $3 - main repo root
    local feature_id="${1:-}"
    local feature_slug="${2:-}"
    local main_root="${3:-}"

    local feature_dir_name="${feature_id}-${feature_slug}"
    local spec_dir="$main_root/$SPEC_DIR_PATTERN/$feature_dir_name"

    # Check if directory already exists
    if [[ -d "$spec_dir" ]]; then
        log_error "Feature spec directory already exists: $spec_dir"
        return 1
    fi

    log_info "Creating spec directory: $spec_dir"

    # Create the directory
    mkdir -p "$spec_dir" || {
        log_error "Failed to create spec directory"
        return 1
    }

    echo "$spec_dir"
}

initialize_templates() {
    # Copy and initialize template files
    # Args: $1 - feature ID, $2 - feature slug, $3 - feature name, $4 - spec directory, $5 - templates directory
    local feature_id="${1:-}"
    local feature_slug="${2:-}"
    local feature_name="${3:-}"
    local spec_dir="${4:-}"
    local templates_dir="${5:-}"

    local branch_name="${feature_id}-${feature_slug}"
    local current_date
    current_date=$(date +%Y-%m-%d)

    log_info "Initializing templates"

    # Initialize spec.md from template
    local spec_template="$templates_dir/spec-template.md"
    if [[ -f "$spec_template" ]]; then
        local spec_content
        spec_content=$(cat "$spec_template")

        # Replace placeholders
        spec_content="${spec_content//\{FEATURE_NAME\}/$feature_name}"
        spec_content="${spec_content//\{BRANCH_NUMBER\}/$feature_id}"
        spec_content="${spec_content//\{BRANCH_SLUG\}/$feature_slug}"
        spec_content="${spec_content//\{DATE\}/$current_date}"

        echo "$spec_content" > "$spec_dir/spec.md"
        log_info "Created spec.md"
    else
        # Create minimal spec.md if template not found
        cat > "$spec_dir/spec.md" << EOF
# Feature Specification: $feature_name

**Feature Branch**: \`$branch_name\`
**Created**: $current_date
**Status**: Draft

---

## Overview

<!-- Provide a clear, concise summary of the feature -->

---

## User Scenarios & Testing

### User Story 1 - (Priority: P1)

**As a** user
**I want** this feature
**So that** I can achieve my goal

#### Acceptance Criteria
- [ ] Given context, when action, then outcome

---

## Requirements

### Functional Requirements

- **FR-001**: Requirement description

### Non-Functional Requirements

- **NFR-001**: Requirement description

---

## Success Criteria

- **SC-001**: Measurable outcome

---

## Out of Scope

- Items not included in this feature

---

## Open Questions

- [ ] Question to be resolved
EOF
        log_info "Created spec.md (minimal template)"
    fi

    # Create state.yaml with initial state
    cat > "$spec_dir/state.yaml" << EOF
# Feature state tracking
# This file tracks the current phase and progress of the feature

phase: specify
created_at: $current_date
feature_id: "$feature_id"
feature_slug: "$feature_slug"
branch: "$branch_name"

# Phase progression:
# specify -> plan -> implement -> review -> complete
EOF
    log_info "Created state.yaml"

    return 0
}

find_templates_dir() {
    # Find the templates directory
    # Args: $1 - main repo root
    local main_root="${1:-}"

    # Check common locations
    local locations=(
        "$main_root/templates"
        "$main_root/.specify/templates"
        "$SCRIPT_DIR/../templates"
        "$SCRIPT_DIR/../src/projspec_cli/resources/templates"
    )

    for loc in "${locations[@]}"; do
        if [[ -d "$loc" ]] && [[ -f "$loc/spec-template.md" ]]; then
            echo "$loc"
            return 0
        fi
    done

    echo ""
    return 1
}

# =============================================================================
# Main
# =============================================================================

main() {
    local feature_name=""
    local explicit_id=""
    local base_branch="$DEFAULT_BASE_BRANCH"
    local create_worktree_flag=true

    # Parse command line arguments
    parse_common_args "$@"
    set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --id)
                if [[ -n "${2:-}" ]]; then
                    explicit_id="$2"
                    shift 2
                else
                    log_error "--id requires a value"
                    exit 1
                fi
                ;;
            --base)
                if [[ -n "${2:-}" ]]; then
                    base_branch="$2"
                    shift 2
                else
                    log_error "--base requires a value"
                    exit 1
                fi
                ;;
            --no-worktree)
                create_worktree_flag=false
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$feature_name" ]]; then
                    feature_name="$1"
                    shift
                else
                    log_error "Unexpected argument: $1"
                    exit 1
                fi
                ;;
        esac
    done

    # Validate feature name is provided
    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        if [[ "$OUTPUT_FORMAT" != "json" ]]; then
            echo "Usage: $0 <feature-name> [options]"
            echo "Run with --help for more information"
        fi
        exit 1
    fi

    # Validate feature name format
    if ! validate_feature_name "$feature_name"; then
        log_error "Invalid feature name: must start with a letter"
        exit 1
    fi

    # Ensure we're in a git repository
    require_git

    # Get main repository root
    local main_root
    main_root=$(get_main_repo_root) || {
        log_error "Could not determine main repository root"
        exit 1
    }

    # Generate feature slug
    local feature_slug
    feature_slug=$(slugify_with_stop_words "$feature_name")

    if [[ -z "$feature_slug" ]]; then
        log_error "Could not generate valid slug from feature name"
        exit 1
    fi

    # Determine feature ID
    local feature_id
    if [[ -n "$explicit_id" ]]; then
        # Validate explicit ID
        if ! validate_feature_id "$explicit_id"; then
            log_error "Invalid feature ID: must be exactly 3 digits (e.g., 001, 042)"
            exit 1
        fi
        feature_id="$explicit_id"
    else
        feature_id=$(get_next_feature_id)
    fi

    local branch_name="${feature_id}-${feature_slug}"

    log_info "Creating new feature: $branch_name"

    # Ensure specs directory exists
    mkdir -p "$main_root/$SPEC_DIR_PATTERN"

    # Create feature branch
    local created_branch
    created_branch=$(create_feature_branch "$feature_id" "$feature_slug" "$base_branch") || exit 1

    # Create spec directory
    local spec_dir
    spec_dir=$(create_spec_directory "$feature_id" "$feature_slug" "$main_root") || {
        # Cleanup: remove the branch if spec directory creation fails
        git branch -d "$branch_name" 2>/dev/null || true
        exit 1
    }

    # Find templates directory and initialize
    local templates_dir
    templates_dir=$(find_templates_dir "$main_root") || templates_dir=""

    initialize_templates "$feature_id" "$feature_slug" "$feature_name" "$spec_dir" "$templates_dir" || {
        log_warning "Template initialization had issues, but continuing"
    }

    # Create worktree if requested
    local worktree_path=""
    if [[ "$create_worktree_flag" == "true" ]]; then
        worktree_path=$(create_worktree "$branch_name" "$main_root") || {
            log_warning "Worktree creation failed, but branch and spec directory were created"
        }
    fi

    # Output results
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        local worktree_json="null"
        if [[ -n "$worktree_path" ]]; then
            worktree_json="\"$worktree_path\""
        fi

        cat << EOF
{
  "success": true,
  "feature": {
    "id": "$feature_id",
    "slug": "$feature_slug",
    "name": "$feature_name",
    "branch": "$branch_name"
  },
  "paths": {
    "spec_directory": "$spec_dir",
    "worktree": $worktree_json
  },
  "base_branch": "$base_branch"
}
EOF
    else
        log_success "Feature created successfully!"
        echo ""
        echo "  Feature ID:      $feature_id"
        echo "  Feature Slug:    $feature_slug"
        echo "  Branch:          $branch_name"
        echo "  Spec Directory:  $spec_dir"
        if [[ -n "$worktree_path" ]]; then
            echo "  Worktree:        $worktree_path"
        fi
        echo ""
        echo "Next steps:"
        echo "  1. Edit the spec: $spec_dir/spec.md"
        if [[ -n "$worktree_path" ]]; then
            echo "  2. Start development: cd $worktree_path"
        else
            echo "  2. Switch to branch: git checkout $branch_name"
        fi
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

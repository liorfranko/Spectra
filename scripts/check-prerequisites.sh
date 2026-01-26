#!/usr/bin/env bash
# =============================================================================
# check-prerequisites.sh - Validate system prerequisites for projspec
# =============================================================================
# This script validates that the current environment meets prerequisites for
# running projspec workflows. It checks git repository status, feature branch
# naming, and presence of required specification files.
#
# Usage:
#   ./check-prerequisites.sh [OPTIONS]
#
# Options:
#   --json            Output results in JSON format
#   --require-tasks   Require tasks.md to exist
#   --include-tasks   Include tasks.md in available docs check
#   --paths-only      Output paths without validation
#
# Exit codes:
#   0 - All prerequisites satisfied
#   1 - Missing required files
#   2 - Invalid branch/feature (not a git repo or not a feature branch)
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Script-specific options
JSON_OUTPUT=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false
PATHS_ONLY=false

# =============================================================================
# Argument Parsing
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                JSON_OUTPUT=true
                OUTPUT_FORMAT="json"
                shift
                ;;
            --require-tasks)
                REQUIRE_TASKS=true
                shift
                ;;
            --include-tasks)
                INCLUDE_TASKS=true
                shift
                ;;
            --paths-only)
                PATHS_ONLY=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version)
                echo "check-prerequisites.sh version $PROJSPEC_VERSION"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 2
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: check-prerequisites.sh [OPTIONS]

Validate system prerequisites for projspec workflows.

Options:
  --json            Output results in JSON format
  --require-tasks   Require tasks.md to exist (exit 1 if missing)
  --include-tasks   Include tasks.md in available docs check
  --paths-only      Output paths without validation
  --help, -h        Show this help message
  --version         Show version information

Exit codes:
  0 - All prerequisites satisfied
  1 - Missing required files
  2 - Invalid branch/feature (not a git repo or not a feature branch)

Examples:
  # Basic check
  ./check-prerequisites.sh

  # JSON output for scripting
  ./check-prerequisites.sh --json

  # Require tasks.md for implementation phase
  ./check-prerequisites.sh --require-tasks

  # Just get paths without validation
  ./check-prerequisites.sh --paths-only --json
EOF
}

# =============================================================================
# Validation Functions
# =============================================================================

# Check if we're in a git repository
check_git_repository() {
    if ! has_git; then
        return 1
    fi
    return 0
}

# Check if current branch follows feature branch naming convention (NNN-feature-name)
check_feature_branch_pattern() {
    local branch
    branch=$(get_current_branch)

    if [[ -z "$branch" ]]; then
        return 1
    fi

    # Check if branch matches NNN-feature-name pattern
    if [[ "$branch" =~ ^[0-9]{3}-[a-zA-Z0-9][-a-zA-Z0-9]*$ ]]; then
        return 0
    fi

    return 1
}

# Extract feature ID from branch name (e.g., "001" from "001-feature-name")
get_feature_id_from_branch() {
    local branch="${1:-}"
    if [[ "$branch" =~ ^([0-9]{3})- ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Get the feature spec directory path
get_feature_spec_directory() {
    local branch="${1:-}"
    local repo_root

    # Get main repo root (handles worktree case)
    repo_root=$(get_main_repo_root)

    if [[ -z "$repo_root" ]]; then
        echo ""
        return 1
    fi

    # Feature spec directory is in specs/ relative to main repo
    local specs_dir="${repo_root}/specs"

    # Find matching spec directory
    if [[ -d "$specs_dir" ]]; then
        # Look for directory starting with the branch name or feature ID
        local feature_id
        feature_id=$(get_feature_id_from_branch "$branch")

        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname
                dirname=$(basename "$dir")
                # Check if directory name starts with branch name or matches feature pattern
                if [[ "$dirname" == "$branch" ]] || [[ "$dirname" == "${feature_id}-"* ]]; then
                    echo "$dir"
                    return 0
                fi
            fi
        done
    fi

    echo ""
    return 1
}

# List available documentation files in feature directory
list_available_docs() {
    local feature_dir="${1:-}"
    local docs=()

    if [[ -z "$feature_dir" ]] || [[ ! -d "$feature_dir" ]]; then
        echo ""
        return
    fi

    # Check for standard spec files
    for doc in "spec.md" "plan.md" "research.md" "data-model.md" "quickstart.md" "state.yaml"; do
        if [[ -f "${feature_dir}/${doc}" ]]; then
            docs+=("$doc")
        fi
    done

    # Include tasks.md if requested or if it exists and we're including tasks
    if [[ -f "${feature_dir}/tasks.md" ]]; then
        if [[ "$INCLUDE_TASKS" == "true" ]] || [[ "$REQUIRE_TASKS" == "true" ]]; then
            docs+=("tasks.md")
        fi
    fi

    # Check for checklists directory
    if [[ -d "${feature_dir}/checklists" ]]; then
        for checklist in "${feature_dir}/checklists"/*.md; do
            if [[ -f "$checklist" ]]; then
                docs+=("checklists/$(basename "$checklist")")
            fi
        done
    fi

    # Check for contracts directory
    if [[ -d "${feature_dir}/contracts" ]]; then
        for contract in "${feature_dir}/contracts"/*.md; do
            if [[ -f "$contract" ]]; then
                docs+=("contracts/$(basename "$contract")")
            fi
        done
    fi

    # Output as space-separated list (will be converted to JSON array if needed)
    echo "${docs[*]}"
}

# Check if we're in a worktree
check_is_worktree() {
    is_worktree
}

# =============================================================================
# Output Functions
# =============================================================================

# Output results in JSON format
output_json() {
    local feature_dir="${1:-}"
    local branch="${2:-}"
    local is_wt="${3:-false}"
    local docs_str="${4:-}"

    # Convert docs string to JSON array
    local docs_json="[]"
    if [[ -n "$docs_str" ]]; then
        docs_json="["
        local first=true
        for doc in $docs_str; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                docs_json+=","
            fi
            docs_json+="\"$doc\""
        done
        docs_json+="]"
    fi

    cat << EOF
{
  "FEATURE_DIR": "${feature_dir}",
  "AVAILABLE_DOCS": ${docs_json},
  "BRANCH": "${branch}",
  "IS_WORKTREE": ${is_wt}
}
EOF
}

# Output human-readable status
output_text() {
    local feature_dir="${1:-}"
    local branch="${2:-}"
    local is_wt="${3:-false}"
    local docs_str="${4:-}"

    echo "=== ProjSpec Prerequisites Check ==="
    echo ""
    echo "Branch:       $branch"
    echo "Feature Dir:  $feature_dir"
    echo "Is Worktree:  $is_wt"
    echo ""
    echo "Available Docs:"
    if [[ -n "$docs_str" ]]; then
        for doc in $docs_str; do
            echo "  - $doc"
        done
    else
        echo "  (none)"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"

    local exit_code=0
    local branch=""
    local feature_dir=""
    local is_wt=false
    local available_docs=""

    # Check 1: Is this a git repository?
    if ! check_git_repository; then
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            echo '{"error": "Not a git repository", "exit_code": 2}'
        else
            log_error "Not a git repository"
        fi
        exit 2
    fi

    # Get current branch
    branch=$(get_current_branch)

    # Check 2: Is this a feature branch (NNN-feature-name pattern)?
    if ! check_feature_branch_pattern; then
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            echo "{\"error\": \"Invalid branch name. Expected NNN-feature-name pattern, got: ${branch}\", \"exit_code\": 2}"
        else
            log_error "Invalid branch name. Expected NNN-feature-name pattern, got: ${branch}"
        fi
        exit 2
    fi

    # Check if we're in a worktree
    if check_is_worktree; then
        is_wt=true
    fi

    # Check 3: Does the feature spec directory exist?
    feature_dir=$(get_feature_spec_directory "$branch")

    if [[ -z "$feature_dir" ]] || [[ ! -d "$feature_dir" ]]; then
        if [[ "$PATHS_ONLY" == "true" ]]; then
            # For paths-only mode, just report what we have
            if [[ "$JSON_OUTPUT" == "true" ]]; then
                output_json "" "$branch" "$is_wt" ""
            else
                output_text "" "$branch" "$is_wt" ""
            fi
            exit 1
        fi

        if [[ "$JSON_OUTPUT" == "true" ]]; then
            echo "{\"error\": \"Feature spec directory not found for branch: ${branch}\", \"exit_code\": 1}"
        else
            log_error "Feature spec directory not found for branch: ${branch}"
        fi
        exit 1
    fi

    # If --paths-only, skip validation and just output paths
    if [[ "$PATHS_ONLY" == "true" ]]; then
        available_docs=$(list_available_docs "$feature_dir")
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            output_json "$feature_dir" "$branch" "$is_wt" "$available_docs"
        else
            output_text "$feature_dir" "$branch" "$is_wt" "$available_docs"
        fi
        exit 0
    fi

    # Check 4: Does spec.md exist?
    if [[ ! -f "${feature_dir}/spec.md" ]]; then
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            echo "{\"error\": \"spec.md not found in ${feature_dir}\", \"exit_code\": 1}"
        else
            log_error "spec.md not found in ${feature_dir}"
        fi
        exit 1
    fi

    # Check 5: Does plan.md exist? (we report but don't fail on this one)
    local has_plan=false
    if [[ -f "${feature_dir}/plan.md" ]]; then
        has_plan=true
    fi

    # Check 6: Does tasks.md exist? (if --require-tasks)
    if [[ "$REQUIRE_TASKS" == "true" ]]; then
        if [[ ! -f "${feature_dir}/tasks.md" ]]; then
            if [[ "$JSON_OUTPUT" == "true" ]]; then
                echo "{\"error\": \"tasks.md not found in ${feature_dir} (required by --require-tasks)\", \"exit_code\": 1}"
            else
                log_error "tasks.md not found in ${feature_dir} (required by --require-tasks)"
            fi
            exit 1
        fi
    fi

    # Get list of available docs
    available_docs=$(list_available_docs "$feature_dir")

    # Output results
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        output_json "$feature_dir" "$branch" "$is_wt" "$available_docs"
    else
        output_text "$feature_dir" "$branch" "$is_wt" "$available_docs"
        echo ""
        log_success "All prerequisites satisfied"
    fi

    exit 0
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

#!/usr/bin/env bash
# projspec/scripts/check-prerequisites.sh - Validate prerequisites for ProjSpec commands
# Checks for required tools, validates feature directory structure, and reports available documents
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Default Configuration
# =============================================================================

JSON_OUTPUT=false
REQUIRE_SPEC=false
REQUIRE_PLAN=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Validate prerequisites for ProjSpec commands and report available documents.

OPTIONS:
    --json              Output in JSON format (default: human-readable)
    --require-spec      Require spec.md to exist (exit 1 if missing)
    --require-plan      Require plan.md to exist (exit 1 if missing)
    --require-tasks     Require tasks.md to exist (exit 1 if missing)
    --include-tasks     Include tasks content in output
    -h, --help          Show this help message

EXIT CODES:
    0   Success - all prerequisites met
    1   Missing required prerequisite

EXAMPLES:
    $(basename "$0")                     # Check prerequisites, human output
    $(basename "$0") --json              # Check prerequisites, JSON output
    $(basename "$0") --require-spec      # Fail if spec.md is missing
    $(basename "$0") --json --include-tasks  # Include tasks in JSON output
EOF
}

# =============================================================================
# Argument Parsing
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --require-spec)
                REQUIRE_SPEC=true
                shift
                ;;
            --require-plan)
                REQUIRE_PLAN=true
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
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Prerequisite Checks
# =============================================================================

# Check if git is installed
check_git() {
    if ! command -v git &>/dev/null; then
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            json_error "git is not installed"
        else
            error "git is not installed. Please install git to use ProjSpec."
        fi
        exit 1
    fi
}

# Check if in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            json_error "Not in a git repository"
        else
            error "Not in a git repository. ProjSpec requires a git repository."
        fi
        exit 1
    fi
}

# Check if gh CLI is installed (optional, just report status)
check_gh_cli() {
    if command -v gh &>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# =============================================================================
# Document Discovery
# =============================================================================

# Scan feature directory for available documents
# Returns a newline-separated list of available documents
scan_available_docs() {
    local feature_dir="$1"
    local docs=()

    # Check for main documents
    [[ -f "${feature_dir}/spec.md" ]] && docs+=("spec.md")
    [[ -f "${feature_dir}/plan.md" ]] && docs+=("plan.md")
    [[ -f "${feature_dir}/tasks.md" ]] && docs+=("tasks.md")
    [[ -f "${feature_dir}/research.md" ]] && docs+=("research.md")
    [[ -f "${feature_dir}/data-model.md" ]] && docs+=("data-model.md")
    [[ -f "${feature_dir}/quickstart.md" ]] && docs+=("quickstart.md")

    # Check for contracts directory
    if [[ -d "${feature_dir}/contracts" ]] && [[ -n "$(ls -A "${feature_dir}/contracts" 2>/dev/null)" ]]; then
        docs+=("contracts/")
    fi


    # Output each doc on a new line
    printf '%s\n' "${docs[@]}"
}

# Read tasks.md content if it exists
get_tasks_content() {
    local feature_dir="$1"
    local tasks_file="${feature_dir}/tasks.md"

    if [[ -f "$tasks_file" ]]; then
        cat "$tasks_file"
    else
        echo ""
    fi
}

# =============================================================================
# Output Functions
# =============================================================================

# Build JSON array from newline-separated values
build_json_array() {
    local first=true
    echo -n "["
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo -n ","
        fi
        # Escape special JSON characters
        item=$(echo -n "$item" | sed 's/\\/\\\\/g; s/"/\\"/g')
        echo -n "\"${item}\""
    done
    echo -n "]"
}

# Output results in JSON format
output_json() {
    local feature_dir="$1"
    local available_docs="$2"
    local gh_available="$3"
    local tasks_content="${4:-}"

    # Build the docs array
    local docs_array
    docs_array=$(echo "$available_docs" | build_json_array)

    # Start JSON object
    echo -n "{"

    # Add FEATURE_DIR
    local escaped_dir
    escaped_dir=$(echo -n "$feature_dir" | sed 's/\\/\\\\/g; s/"/\\"/g')
    echo -n "\"FEATURE_DIR\":\"${escaped_dir}\""

    # Add AVAILABLE_DOCS
    echo -n ",\"AVAILABLE_DOCS\":${docs_array}"

    # Add GH_CLI_AVAILABLE
    echo -n ",\"GH_CLI_AVAILABLE\":${gh_available}"

    # Add TASKS_CONTENT if requested
    if [[ "$INCLUDE_TASKS" == "true" ]] && [[ -n "$tasks_content" ]]; then
        # Escape the tasks content for JSON
        local escaped_tasks
        escaped_tasks=$(echo -n "$tasks_content" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
        echo -n ",\"TASKS_CONTENT\":\"${escaped_tasks}\""
    fi

    echo "}"
}

# Output results in human-readable format
output_text() {
    local feature_dir="$1"
    local available_docs="$2"
    local gh_available="$3"
    local tasks_content="${4:-}"

    echo "Prerequisites Check"
    echo "==================="
    echo ""
    echo "Git: OK"
    echo "Git Repository: OK"
    echo "GitHub CLI: $([ "$gh_available" = "true" ] && echo "Available" || echo "Not installed (optional)")"
    echo ""
    echo "Feature Directory: ${feature_dir}"
    echo ""
    echo "Available Documents:"
    if [[ -n "$available_docs" ]]; then
        echo "$available_docs" | while IFS= read -r doc; do
            [[ -n "$doc" ]] && echo "  - ${doc}"
        done
    else
        echo "  (none)"
    fi

    if [[ "$INCLUDE_TASKS" == "true" ]] && [[ -n "$tasks_content" ]]; then
        echo ""
        echo "Tasks Content:"
        echo "-------------"
        echo "$tasks_content"
    fi
}

# =============================================================================
# Requirement Validation
# =============================================================================

check_requirements() {
    local feature_dir="$1"
    local missing=()

    if [[ "$REQUIRE_SPEC" == "true" ]] && [[ ! -f "${feature_dir}/spec.md" ]]; then
        missing+=("spec.md")
    fi

    if [[ "$REQUIRE_PLAN" == "true" ]] && [[ ! -f "${feature_dir}/plan.md" ]]; then
        missing+=("plan.md")
    fi

    if [[ "$REQUIRE_TASKS" == "true" ]] && [[ ! -f "${feature_dir}/tasks.md" ]]; then
        missing+=("tasks.md")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        local missing_str
        missing_str=$(IFS=', '; echo "${missing[*]}")
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            json_error "Missing required documents: ${missing_str}"
        else
            error "Missing required documents: ${missing_str}"
        fi
        exit 1
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"

    # Check basic prerequisites
    check_git
    check_git_repo

    # Get feature directory
    local feature_dir
    feature_dir=$(get_feature_dir) || {
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            json_error "Failed to determine feature directory from branch name"
        else
            error "Failed to determine feature directory from branch name"
        fi
        exit 1
    }

    # Create feature directory if it doesn't exist
    if [[ ! -d "$feature_dir" ]]; then
        mkdir -p "$feature_dir"
    fi

    # Check requirements before proceeding
    check_requirements "$feature_dir"

    # Gather information
    local gh_available
    gh_available=$(check_gh_cli)

    local available_docs
    available_docs=$(scan_available_docs "$feature_dir")

    local tasks_content=""
    if [[ "$INCLUDE_TASKS" == "true" ]]; then
        tasks_content=$(get_tasks_content "$feature_dir")
    fi

    # Output results
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        output_json "$feature_dir" "$available_docs" "$gh_available" "$tasks_content"
    else
        output_text "$feature_dir" "$available_docs" "$gh_available" "$tasks_content"
    fi
}

main "$@"

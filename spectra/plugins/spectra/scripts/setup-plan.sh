#!/usr/bin/env bash
# spectra/scripts/setup-plan.sh - Initialize plan workflow for a feature
# Prepares the feature directory for plan generation by verifying spec.md
# and creating necessary directory structure
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Prepare a feature directory for plan generation.

OPTIONS:
    --feature-dir DIR   Feature directory path (auto-detect from branch if not provided)
    --json              Output in JSON format
    -h, --help          Show this help message

EXAMPLES:
    $(basename "$0")
    $(basename "$0") --feature-dir /path/to/specs/003-my-feature
    $(basename "$0") --json
EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    local feature_dir=""
    local json_output=false

    # Parse arguments
    while (( $# > 0 )); do
        case "$1" in
            --feature-dir)
                if [[ -z "${2:-}" ]]; then
                    error "--feature-dir requires a value"
                fi
                feature_dir="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done

    # Auto-detect feature directory if not provided
    if [[ -z "$feature_dir" ]]; then
        feature_dir=$(get_feature_dir) || {
            if [[ "$json_output" == "true" ]]; then
                json_error "Failed to auto-detect feature directory from branch name"
                exit 1
            else
                error "Failed to auto-detect feature directory from branch name"
            fi
        }
    fi

    # Validate feature directory exists
    if [[ ! -d "$feature_dir" ]]; then
        if [[ "$json_output" == "true" ]]; then
            json_output "FEATURE_DIR" "$feature_dir" "SPEC_EXISTS" "false" "READY" "false" "ERROR" "Feature directory does not exist"
            exit 1
        else
            error "Feature directory does not exist: $feature_dir"
        fi
    fi

    # Check if spec.md exists
    local spec_file="${feature_dir}/spec.md"
    if [[ ! -f "$spec_file" ]]; then
        if [[ "$json_output" == "true" ]]; then
            json_output "FEATURE_DIR" "$feature_dir" "SPEC_EXISTS" "false" "READY" "false" "ERROR" "spec.md not found - run /specify first"
            exit 1
        else
            error "spec.md not found in $feature_dir - run /specify first"
        fi
    fi

    # Create contracts/ directory if it doesn't exist
    local contracts_dir="${feature_dir}/contracts"
    local contracts_created=false
    if [[ ! -d "$contracts_dir" ]]; then
        mkdir -p "$contracts_dir"
        contracts_created=true
    fi

    # Output results
    if [[ "$json_output" == "true" ]]; then
        json_output "FEATURE_DIR" "$feature_dir" "SPEC_EXISTS" "true" "READY" "true" "CONTRACTS_CREATED" "$contracts_created"
    else
        echo "Plan setup complete for: $feature_dir"
        echo ""
        echo "Status:"
        echo "  - Feature directory: $feature_dir"
        echo "  - spec.md: Found"
        if [[ "$contracts_created" == "true" ]]; then
            echo "  - contracts/: Created"
        else
            echo "  - contracts/: Already exists"
        fi
        echo ""
        echo "Ready for plan generation."
    fi
}

main "$@"

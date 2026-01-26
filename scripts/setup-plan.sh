#!/usr/bin/env bash
# =============================================================================
# setup-plan.sh - Initialize implementation plan for a feature
# =============================================================================
# This script sets up the implementation plan structure for a feature,
# including creating plan.md, tasks.md, and related artifacts.
#
# Usage:
#   ./setup-plan.sh [feature-id] [options]
#
# Arguments:
#   feature-id    Feature ID (uses current branch if not provided)
#
# Options:
#   --from-spec   Generate plan outline from spec.md
#   --template    Use specific plan template
#   --json        Output results in JSON format
#
# Examples:
#   ./setup-plan.sh                    # Use current branch
#   ./setup-plan.sh 042                # Specific feature
#   ./setup-plan.sh --from-spec        # Auto-generate from spec
#
# Exit codes:
#   0 - Plan initialized successfully
#   1 - Error during initialization
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Plan template location (relative to templates directory)
PLAN_TEMPLATE_NAME="plan-template.md"

# Tasks template location (relative to templates directory)
TASKS_TEMPLATE_NAME="tasks-template.md"

# =============================================================================
# Help
# =============================================================================

show_help() {
    cat << 'EOF'
Usage: setup-plan.sh [feature-id] [options]

Initialize implementation plan structure for a feature.

Arguments:
  feature-id    Feature ID or branch name (uses current branch if not provided)

Options:
  --from-spec   Generate plan outline from spec.md (placeholder for future)
  --template    Use specific plan template path
  --json        Output results in JSON format
  --help        Show this help message
  --version     Show version information

Examples:
  ./setup-plan.sh                        # Use current branch
  ./setup-plan.sh 042                    # Specific feature ID
  ./setup-plan.sh 042-my-feature         # Full branch name
  ./setup-plan.sh --from-spec            # Generate from spec
  ./setup-plan.sh --json                 # JSON output

Created Files:
  - plan.md         Implementation plan document
  - research.md     Research and discovery notes
  - data-model.md   Data model documentation
  - quickstart.md   Getting started guide
  - contracts/      API contracts directory
EOF
}

# =============================================================================
# Helper Functions
# =============================================================================

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
        if [[ -d "$loc" ]] && [[ -f "$loc/$PLAN_TEMPLATE_NAME" ]]; then
            echo "$loc"
            return 0
        fi
    done

    echo ""
    return 1
}

resolve_feature_branch() {
    # Resolve feature ID or partial branch to full branch name
    # Args: $1 - feature ID or branch name
    # Output: full branch name
    local input="${1:-}"
    local main_root
    local specs_dir

    main_root=$(get_main_repo_root) || return 1
    specs_dir="$main_root/specs"

    # If input is just 3 digits, try to find matching feature
    if [[ "$input" =~ ^[0-9]{3}$ ]]; then
        # Look for matching directory in specs/
        for dir in "$specs_dir"/"${input}"-*/; do
            if [[ -d "$dir" ]]; then
                basename "$dir"
                return 0
            fi
        done
        # Not found
        return 1
    fi

    # If input matches full branch pattern, return as-is
    if check_feature_branch "$input"; then
        echo "$input"
        return 0
    fi

    return 1
}

get_feature_spec_path() {
    # Get path to feature's spec.md
    # Args: $1 - feature ID or full branch name
    local feature_input="${1:-}"
    local main_root
    local feature_branch

    main_root=$(get_main_repo_root) || return 1

    # Resolve to full branch name
    feature_branch=$(resolve_feature_branch "$feature_input") || {
        # Try as-is if it's already a valid branch
        if check_feature_branch "$feature_input"; then
            feature_branch="$feature_input"
        else
            return 1
        fi
    }

    echo "$main_root/specs/$feature_branch/spec.md"
}

get_feature_plan_path() {
    # Get path to feature's plan.md
    # Args: $1 - feature ID or full branch name
    local feature_input="${1:-}"
    local main_root
    local feature_branch

    main_root=$(get_main_repo_root) || return 1

    # Resolve to full branch name
    feature_branch=$(resolve_feature_branch "$feature_input") || {
        if check_feature_branch "$feature_input"; then
            feature_branch="$feature_input"
        else
            return 1
        fi
    }

    echo "$main_root/specs/$feature_branch/plan.md"
}

get_feature_directory() {
    # Get path to feature's spec directory
    # Args: $1 - feature ID or full branch name
    local feature_input="${1:-}"
    local main_root
    local feature_branch

    main_root=$(get_main_repo_root) || return 1

    # Resolve to full branch name
    feature_branch=$(resolve_feature_branch "$feature_input") || {
        if check_feature_branch "$feature_input"; then
            feature_branch="$feature_input"
        else
            return 1
        fi
    }

    echo "$main_root/specs/$feature_branch"
}

validate_spec_exists() {
    # Verify spec.md exists for the feature
    # Args: $1 - feature ID or branch name
    local feature_input="${1:-}"

    local spec_path
    spec_path=$(get_feature_spec_path "$feature_input") || return 1

    [[ -f "$spec_path" ]]
}

extract_feature_title_from_spec() {
    # Extract feature title from spec.md header
    # Args: $1 - path to spec.md
    local spec_path="${1:-}"

    if [[ ! -f "$spec_path" ]]; then
        echo "Untitled Feature"
        return 0
    fi

    # Try to extract from # Feature Specification: Title line
    local title
    title=$(grep -m 1 '^# .*:' "$spec_path" 2>/dev/null | sed 's/^# [^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [[ -n "$title" ]]; then
        echo "$title"
    else
        # Fallback: try first # header
        title=$(grep -m 1 '^# ' "$spec_path" 2>/dev/null | sed 's/^# //')
        if [[ -n "$title" ]]; then
            echo "$title"
        else
            echo "Untitled Feature"
        fi
    fi
}

copy_plan_template() {
    # Copy and customize plan template
    # Args: $1 - feature branch, $2 - feature dir, $3 - templates dir, $4 - optional custom template
    local feature_branch="${1:-}"
    local feature_dir="${2:-}"
    local templates_dir="${3:-}"
    local custom_template="${4:-}"

    local plan_path="$feature_dir/plan.md"
    local template_path=""

    # Determine template path
    if [[ -n "$custom_template" ]] && [[ -f "$custom_template" ]]; then
        template_path="$custom_template"
    elif [[ -n "$templates_dir" ]] && [[ -f "$templates_dir/$PLAN_TEMPLATE_NAME" ]]; then
        template_path="$templates_dir/$PLAN_TEMPLATE_NAME"
    fi

    # Check if plan already exists
    if [[ -f "$plan_path" ]]; then
        log_warning "plan.md already exists, skipping template copy"
        return 0
    fi

    local feature_id="${feature_branch:0:3}"
    local feature_slug="${feature_branch:4}"
    local current_date
    current_date=$(date +%Y-%m-%d)

    # Extract feature name from spec if available
    local spec_path="$feature_dir/spec.md"
    local feature_name
    feature_name=$(extract_feature_title_from_spec "$spec_path")

    if [[ -n "$template_path" ]]; then
        log_info "Copying plan template from: $template_path"

        local plan_content
        plan_content=$(cat "$template_path")

        # Replace placeholders
        plan_content="${plan_content//\{FEATURE_NAME\}/$feature_name}"
        plan_content="${plan_content//\{BRANCH_NUMBER\}/$feature_id}"
        plan_content="${plan_content//\{BRANCH_SLUG\}/$feature_slug}"
        plan_content="${plan_content//\{DATE\}/$current_date}"

        echo "$plan_content" > "$plan_path"
    else
        # Create minimal plan.md if template not found
        log_info "Creating minimal plan.md (template not found)"

        cat > "$plan_path" << EOF
# Implementation Plan: $feature_name

**Branch**: \`$feature_branch\` | **Date**: $current_date | **Spec**: [spec.md](./spec.md)

---

## Summary

<!-- 2-3 sentence overview of the implementation approach -->

---

## Technical Context

### Existing Codebase Analysis

- **Relevant Files**: TBD
- **Patterns in Use**: TBD
- **Integration Points**: TBD

### Technology Stack

- TBD

---

## Implementation Phases

### Phase 1: Foundation

**Goal**: Set up initial structure

- [ ] Step 1
- [ ] Step 2

### Phase 2: Core Implementation

**Goal**: Implement main functionality

- [ ] Step 1
- [ ] Step 2

---

## Testing Strategy

### Unit Tests

- TBD

### Integration Tests

- TBD

---

## Open Design Decisions

- [ ] Decision 1
- [ ] Decision 2

---
EOF
    fi

    log_info "Created plan.md"
}

initialize_supporting_docs() {
    # Create supporting documentation files
    # Args: $1 - feature branch, $2 - feature directory
    local feature_branch="${1:-}"
    local feature_dir="${2:-}"

    local feature_id="${feature_branch:0:3}"
    local feature_slug="${feature_branch:4}"
    local current_date
    current_date=$(date +%Y-%m-%d)

    # Extract feature name from spec
    local spec_path="$feature_dir/spec.md"
    local feature_name
    feature_name=$(extract_feature_title_from_spec "$spec_path")

    local created_files=()

    # Create research.md if it doesn't exist
    if [[ ! -f "$feature_dir/research.md" ]]; then
        log_info "Creating research.md"
        cat > "$feature_dir/research.md" << EOF
# Research Notes: $feature_name

**Branch**: \`$feature_branch\` | **Date**: $current_date

---

## Overview

Research and discovery notes for the feature implementation.

---

## Findings

### Topic 1

<!-- Research findings go here -->

---

### Topic 2

<!-- Additional research findings -->

---

## References

- [Link 1](URL) - Description
- [Link 2](URL) - Description

---

## Open Questions

- [ ] Question to research

---
EOF
        created_files+=("research.md")
    else
        log_info "research.md already exists, skipping"
    fi

    # Create data-model.md if it doesn't exist
    if [[ ! -f "$feature_dir/data-model.md" ]]; then
        log_info "Creating data-model.md"
        cat > "$feature_dir/data-model.md" << EOF
# Data Model: $feature_name

**Branch**: \`$feature_branch\` | **Date**: $current_date

---

## Overview

Data model documentation for the feature.

---

## Entities

### Entity 1

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | Unique identifier |
| name | string | Yes | Display name |

---

### Entity 2

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | Unique identifier |

---

## Relationships

\`\`\`
Entity1 --1:N-- Entity2
\`\`\`

---

## State Transitions

- State A -> State B: Trigger/Condition
- State B -> State C: Trigger/Condition

---
EOF
        created_files+=("data-model.md")
    else
        log_info "data-model.md already exists, skipping"
    fi

    # Create quickstart.md if it doesn't exist
    if [[ ! -f "$feature_dir/quickstart.md" ]]; then
        log_info "Creating quickstart.md"
        cat > "$feature_dir/quickstart.md" << EOF
# Quickstart: $feature_name

**Branch**: \`$feature_branch\` | **Date**: $current_date

---

## Prerequisites

- Prerequisite 1
- Prerequisite 2

---

## Getting Started

### Step 1: Setup

\`\`\`bash
# Setup commands
\`\`\`

### Step 2: Configuration

Describe configuration steps.

### Step 3: Running

\`\`\`bash
# Run commands
\`\`\`

---

## Common Tasks

### Task 1

Instructions for common task.

### Task 2

Instructions for another task.

---

## Troubleshooting

### Issue 1

Solution for common issue.

---
EOF
        created_files+=("quickstart.md")
    else
        log_info "quickstart.md already exists, skipping"
    fi

    # Create contracts/ directory if it doesn't exist
    if [[ ! -d "$feature_dir/contracts" ]]; then
        log_info "Creating contracts/ directory"
        mkdir -p "$feature_dir/contracts"

        # Create a placeholder README in contracts
        cat > "$feature_dir/contracts/README.md" << EOF
# API Contracts: $feature_name

**Branch**: \`$feature_branch\` | **Date**: $current_date

---

This directory contains API contracts and interface definitions for the feature.

## Contents

- Place OpenAPI/Swagger specs here
- Interface definitions
- Protocol buffers
- GraphQL schemas

---
EOF
        created_files+=("contracts/")
    else
        log_info "contracts/ directory already exists, skipping"
    fi

    # Return list of created files (handle empty array)
    if [[ ${#created_files[@]} -gt 0 ]]; then
        printf '%s\n' "${created_files[@]}"
    fi
}

initialize_tasks_file() {
    # Create initial tasks.md with structure
    # Args: $1 - feature branch, $2 - feature directory, $3 - templates directory
    local feature_branch="${1:-}"
    local feature_dir="${2:-}"
    local templates_dir="${3:-}"

    local tasks_path="$feature_dir/tasks.md"

    # Check if tasks.md already exists
    if [[ -f "$tasks_path" ]]; then
        log_info "tasks.md already exists, skipping"
        return 0
    fi

    local feature_id="${feature_branch:0:3}"
    local feature_slug="${feature_branch:4}"
    local current_date
    current_date=$(date +%Y-%m-%d)

    # Extract feature name from spec
    local spec_path="$feature_dir/spec.md"
    local feature_name
    feature_name=$(extract_feature_title_from_spec "$spec_path")

    # Try to use template
    local template_path="$templates_dir/$TASKS_TEMPLATE_NAME"

    if [[ -f "$template_path" ]]; then
        log_info "Copying tasks template"

        local tasks_content
        tasks_content=$(cat "$template_path")

        # Replace placeholders
        tasks_content="${tasks_content//\{FEATURE_NAME\}/$feature_name}"
        tasks_content="${tasks_content//\{BRANCH_NUMBER\}/$feature_id}"
        tasks_content="${tasks_content//\{BRANCH_SLUG\}/$feature_slug}"
        tasks_content="${tasks_content//\{DATE\}/$current_date}"

        echo "$tasks_content" > "$tasks_path"
    else
        # Create minimal tasks.md if template not found
        log_info "Creating minimal tasks.md (template not found)"

        cat > "$tasks_path" << EOF
# Tasks: $feature_name

**Branch**: \`$feature_branch\` | **Date**: $current_date
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

---

## Progress Summary

| Status | Count |
|--------|-------|
| Pending | 0 |
| In Progress | 0 |
| Completed | 0 |
| **Total** | **0** |

---

## Task List

<!-- Tasks will be added here based on the implementation plan -->

### Phase 1: Foundation

#### T001: Initial Setup

- **Status**: Pending
- **Priority**: P1
- **Estimated Effort**: S
- **Dependencies**: None

**Description**:
Set up initial structure for the feature.

**Acceptance Criteria**:
- [ ] Criterion 1
- [ ] Criterion 2

---

## Completed Tasks

<!-- Move completed tasks here for reference -->

---
EOF
    fi

    log_info "Created tasks.md"
}

update_feature_status() {
    # Update feature status to indicate plan phase
    # Args: $1 - feature directory
    local feature_dir="${1:-}"

    local state_file="$feature_dir/state.yaml"
    local current_date
    current_date=$(date +%Y-%m-%d)

    if [[ ! -f "$state_file" ]]; then
        log_warning "state.yaml not found, cannot update status"
        return 1
    fi

    log_info "Updating feature status to 'plan' phase"

    # Read current state and update phase
    # Using sed to update the phase line
    if grep -q '^phase:' "$state_file"; then
        # Update existing phase line
        sed -i.bak 's/^phase:.*$/phase: plan/' "$state_file"
        rm -f "${state_file}.bak"
    else
        # Add phase line if not present
        echo "phase: plan" >> "$state_file"
    fi

    # Add or update plan_started_at timestamp
    if grep -q '^plan_started_at:' "$state_file"; then
        sed -i.bak "s/^plan_started_at:.*$/plan_started_at: $current_date/" "$state_file"
        rm -f "${state_file}.bak"
    else
        echo "plan_started_at: $current_date" >> "$state_file"
    fi
}

generate_plan_from_spec() {
    # Parse spec.md and generate plan outline
    # Args: $1 - feature directory
    local feature_dir="${1:-}"

    log_info "Generating plan from spec"

    local spec_path="$feature_dir/spec.md"
    local plan_path="$feature_dir/plan.md"

    if [[ ! -f "$spec_path" ]]; then
        log_error "spec.md not found"
        return 1
    fi

    if [[ ! -f "$plan_path" ]]; then
        log_error "plan.md not found - run without --from-spec first"
        return 1
    fi

    # Note: Full implementation would involve parsing spec.md sections
    # and populating plan.md. This is a placeholder for future AI-assisted
    # plan generation.

    log_info "Plan generation from spec is a placeholder for future enhancement"
    log_info "Manually review spec.md and update plan.md accordingly"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local feature_input=""
    local from_spec=false
    local custom_template=""

    # Parse command line arguments
    parse_common_args "$@"
    set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from-spec)
                from_spec=true
                shift
                ;;
            --template)
                if [[ -n "${2:-}" ]]; then
                    custom_template="$2"
                    shift 2
                else
                    log_error "--template requires a path argument"
                    exit 1
                fi
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$feature_input" ]]; then
                    feature_input="$1"
                    shift
                else
                    log_error "Unexpected argument: $1"
                    exit 1
                fi
                ;;
        esac
    done

    require_git

    # Get main repository root
    local main_root
    main_root=$(get_main_repo_root) || {
        log_error "Could not determine main repository root"
        exit 1
    }

    # If no feature input provided, try to get from current branch
    local feature_branch=""
    if [[ -z "$feature_input" ]]; then
        local current_branch
        current_branch=$(get_current_branch)

        if check_feature_branch "$current_branch"; then
            feature_branch="$current_branch"
            log_info "Using feature from current branch: $feature_branch"
        else
            log_error "Could not determine feature. Please provide a feature ID or branch name."
            exit 1
        fi
    else
        # Resolve input to full branch name
        feature_branch=$(resolve_feature_branch "$feature_input") || {
            # Try treating input as full branch name
            if check_feature_branch "$feature_input"; then
                feature_branch="$feature_input"
            else
                log_error "Could not resolve feature: $feature_input"
                exit 1
            fi
        }
    fi

    local feature_id="${feature_branch:0:3}"

    log_info "Setting up plan for feature: $feature_branch"

    # Get feature directory
    local feature_dir
    feature_dir=$(get_feature_directory "$feature_branch") || {
        log_error "Could not determine feature directory"
        exit 1
    }

    # Validate spec exists
    if ! validate_spec_exists "$feature_branch"; then
        log_error "spec.md not found for feature: $feature_branch"
        log_error "Expected at: $feature_dir/spec.md"
        log_error "Please create the spec first using create-new-feature.sh or the specify command."
        exit 1
    fi

    # Find templates directory
    local templates_dir
    templates_dir=$(find_templates_dir "$main_root") || templates_dir=""

    # Track created files for output
    local created_files=()
    local plan_created=false
    local tasks_created=false

    # Copy plan template
    if [[ ! -f "$feature_dir/plan.md" ]]; then
        copy_plan_template "$feature_branch" "$feature_dir" "$templates_dir" "$custom_template"
        plan_created=true
        created_files+=("plan.md")
    else
        log_info "plan.md already exists"
    fi

    # Initialize supporting documents
    local supporting_docs
    supporting_docs=$(initialize_supporting_docs "$feature_branch" "$feature_dir")
    while IFS= read -r doc; do
        [[ -n "$doc" ]] && created_files+=("$doc")
    done <<< "$supporting_docs"

    # Initialize tasks file
    if [[ ! -f "$feature_dir/tasks.md" ]]; then
        initialize_tasks_file "$feature_branch" "$feature_dir" "$templates_dir"
        tasks_created=true
        created_files+=("tasks.md")
    else
        log_info "tasks.md already exists"
    fi

    # Update feature status (don't fail if state.yaml doesn't exist)
    update_feature_status "$feature_dir" || true

    # Optionally generate from spec
    if [[ "$from_spec" == "true" ]]; then
        generate_plan_from_spec "$feature_dir"
    fi

    # Output results
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        local created_json
        if [[ ${#created_files[@]} -gt 0 ]]; then
            created_json=$(json_array "${created_files[@]}")
        else
            created_json="[]"
        fi

        cat << EOF
{
  "success": true,
  "feature": {
    "id": "$feature_id",
    "branch": "$feature_branch"
  },
  "paths": {
    "feature_directory": "$feature_dir",
    "plan": "$feature_dir/plan.md",
    "tasks": "$feature_dir/tasks.md",
    "research": "$feature_dir/research.md",
    "data_model": "$feature_dir/data-model.md",
    "quickstart": "$feature_dir/quickstart.md",
    "contracts": "$feature_dir/contracts"
  },
  "created_files": $created_json,
  "phase": "plan"
}
EOF
    else
        log_success "Plan initialized for feature: $feature_branch"
        echo ""
        echo "  Feature ID:        $feature_id"
        echo "  Feature Branch:    $feature_branch"
        echo "  Feature Directory: $feature_dir"
        echo ""
        echo "Created/Updated files:"
        echo "  - plan.md          Implementation plan"
        echo "  - tasks.md         Task tracking"
        echo "  - research.md      Research notes"
        echo "  - data-model.md    Data model documentation"
        echo "  - quickstart.md    Getting started guide"
        echo "  - contracts/       API contracts directory"
        echo ""
        echo "Next steps:"
        echo "  1. Review and update plan.md with implementation details"
        echo "  2. Break down work into tasks in tasks.md"
        echo "  3. Document any research findings in research.md"
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

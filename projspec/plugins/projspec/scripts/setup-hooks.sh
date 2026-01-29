#!/usr/bin/env bash
# projspec/scripts/setup-hooks.sh - Initialize hooks in user's project
# Copies hook templates to .projspec/ directory and creates necessary configuration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

JSON_OUTPUT=false
FORCE=false
VERBOSE=false

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Initialize projspec hooks in the current project.
Creates .projspec/ directory with hooks and memory infrastructure.

OPTIONS:
    --json          Output in JSON format
    --force, -f     Force reinstall even if hooks exist
    --verbose, -v   Show detailed progress
    -h, --help      Show this help message

WHAT GETS CREATED:
    .projspec/hooks/           Hook scripts directory
    .projspec/memory/          Persistent memory storage
    .projspec/templates/       Template files for specs/plans

EXAMPLES:
    $(basename "$0")              # Install hooks
    $(basename "$0") --force      # Reinstall hooks
    $(basename "$0") --json       # JSON output for automation
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
            --force|-f)
                FORCE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
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
# Logging Functions
# =============================================================================

log_info() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo "[setup-hooks] $1"
    fi
}

log_verbose() {
    if [[ "$VERBOSE" == "true" && "$JSON_OUTPUT" != "true" ]]; then
        echo "[setup-hooks] $1"
    fi
}

log_error() {
    echo "[setup-hooks] ERROR: $1" >&2
}

# =============================================================================
# Setup Functions
# =============================================================================

# Check if hooks are already installed
check_existing_hooks() {
    local specify_dir="$1"

    if [[ -d "$specify_dir/hooks" ]] && [[ -d "$specify_dir/memory" ]]; then
        if [[ "$FORCE" != "true" ]]; then
            return 0  # Already installed
        fi
    fi
    return 1  # Not installed or force reinstall
}

# Create directory structure
create_directories() {
    local specify_dir="$1"

    log_verbose "Creating directory structure..."

    mkdir -p "$specify_dir/hooks"
    mkdir -p "$specify_dir/memory"
    mkdir -p "$specify_dir/templates"
    mkdir -p "$specify_dir/scripts/bash"
}

# Copy hook templates from plugin
copy_hook_templates() {
    local specify_dir="$1"
    local plugin_root="${CLAUDE_PLUGIN_ROOT:-$SCRIPT_DIR/..}"

    log_verbose "Copying hook templates..."

    # Copy templates if they exist in plugin
    local templates_dir="$plugin_root/templates"

    if [[ -d "$templates_dir" ]]; then
        # Copy spec/plan/tasks templates
        for template in spec-template.md plan-template.md tasks-template.md; do
            if [[ -f "$templates_dir/$template" ]]; then
                if cp "$templates_dir/$template" "$specify_dir/templates/" 2>/dev/null; then
                    log_verbose "Copied $template"
                else
                    log_verbose "Skipped $template (copy failed or already exists)"
                fi
            fi
        done
    fi
}

# Copy script utilities
copy_scripts() {
    local specify_dir="$1"

    log_verbose "Copying utility scripts..."

    # Copy common.sh
    if [[ -f "${SCRIPT_DIR}/common.sh" ]]; then
        cp "${SCRIPT_DIR}/common.sh" "$specify_dir/scripts/bash/"
        log_verbose "Copied common.sh"
    fi
}

# Create initial context file
create_initial_context() {
    local specify_dir="$1"
    local context_file="$specify_dir/memory/context.md"

    if [[ ! -f "$context_file" ]]; then
        log_verbose "Creating initial context file..."

        cat > "$context_file" << 'EOF'
# Project Context

This file contains persistent context that carries across Claude Code sessions.

## Project Overview

_Add a brief description of this project._

## Key Conventions

_Document important project conventions here._

## Common Patterns

_Document common patterns used in this codebase._

## Notes

_Add any notes that should persist across sessions._

---
*Last updated: automatically by projspec*
EOF
        log_verbose "Created context.md"
    fi
}

# Create initial constitution file
create_initial_constitution() {
    local specify_dir="$1"
    local constitution_file="$specify_dir/memory/constitution.md"

    if [[ ! -f "$constitution_file" ]]; then
        log_verbose "Creating initial constitution file..."

        cat > "$constitution_file" << 'EOF'
# Project Constitution

This file defines the core principles and constraints for AI-assisted development.

## Core Principles

1. **Code Quality First** - Prioritize maintainable, readable code
2. **Test Before Commit** - Ensure tests pass before committing
3. **Document Changes** - Keep documentation in sync with code

## Constraints

- Do not commit directly to main/master
- Always use pull requests for changes
- Follow existing code style and patterns

## Preferences

_Add project-specific preferences here._

---
*Created by projspec*
EOF
        log_verbose "Created constitution.md"
    fi
}

# Output JSON result
output_json() {
    local status="$1"
    local message="$2"
    local specify_dir="$3"

    cat << EOF
{
  "status": "$status",
  "message": "$message",
  "paths": {
    "specify_dir": "$specify_dir",
    "hooks_dir": "$specify_dir/hooks",
    "memory_dir": "$specify_dir/memory"
  }
}
EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"

    # Get repository root
    local repo_root
    repo_root=$(get_repo_root)

    local specify_dir="$repo_root/.specify"

    log_info "Setting up projspec hooks..."
    log_verbose "Repository root: $repo_root"

    # Check if already installed
    if check_existing_hooks "$specify_dir"; then
        log_info "Hooks already installed. Use --force to reinstall."
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            output_json "already_installed" "Hooks already installed" "$specify_dir"
        fi
        return 0
    fi

    # Create directories
    create_directories "$specify_dir"

    # Copy templates and hooks
    copy_hook_templates "$specify_dir"

    # Copy utility scripts
    copy_scripts "$specify_dir"

    # Create initial files
    create_initial_context "$specify_dir"
    create_initial_constitution "$specify_dir"

    log_info "Hook setup complete!"

    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo ""
        log_info "Installed components:"
        log_info "  - Hooks: $specify_dir/hooks/"
        log_info "  - Memory: $specify_dir/memory/"
        log_info "  - Templates: $specify_dir/templates/"
        echo ""
        log_info "Next steps:"
        log_info "  1. Review and customize $specify_dir/memory/context.md"
        log_info "  2. Review and customize $specify_dir/memory/constitution.md"
        log_info "  3. Start a new Claude Code session to activate hooks"
    else
        output_json "success" "Hooks installed successfully" "$specify_dir"
    fi
}

main "$@"

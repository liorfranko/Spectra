#!/usr/bin/env bash
# Setup Hooks - Configure Claude Code hooks for memory persistence
# This script sets up the hook files and configuration in a project

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Parse arguments
JSON_OUTPUT=false
FORCE=false

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
        *)
            shift
            ;;
    esac
done

# Get repository root
REPO_ROOT=$(get_repo_root)
SPECIFY_DIR="$REPO_ROOT/.specify"
HOOKS_DIR="$SPECIFY_DIR/hooks"
SKILLS_DIR="$SPECIFY_DIR/skills"
SESSIONS_DIR="$SPECIFY_DIR/sessions"
MEMORY_DIR="$SPECIFY_DIR/memory"
SETTINGS_FILE="$SPECIFY_DIR/settings.json"

# Output functions
log_info() {
    if [[ "$JSON_OUTPUT" != "true" ]]; then
        echo "[setup-hooks] $1"
    fi
}

log_error() {
    echo "[setup-hooks] ERROR: $1" >&2
}

# Check if hooks are already installed
check_existing_hooks() {
    if [[ -d "$HOOKS_DIR" ]] && [[ -f "$SETTINGS_FILE" ]]; then
        if [[ "$FORCE" != "true" ]]; then
            return 0  # Already installed
        fi
    fi
    return 1  # Not installed or force reinstall
}

# Find template directory
find_template_dir() {
    # Check if we're in the spec-kit repo itself
    if [[ -d "$REPO_ROOT/templates/hooks" ]]; then
        echo "$REPO_ROOT/templates"
        return 0
    fi

    # Check if templates were installed via specify init
    if [[ -d "$SPECIFY_DIR/templates/hooks" ]]; then
        echo "$SPECIFY_DIR/templates"
        return 0
    fi

    # Templates not found
    return 1
}

# Copy hook files
copy_hooks() {
    local template_dir="$1"

    log_info "Copying hook files..."

    # Create directories
    mkdir -p "$HOOKS_DIR/memory-persistence"
    mkdir -p "$HOOKS_DIR/strategic-compact"
    mkdir -p "$SKILLS_DIR/continuous-learning"
    mkdir -p "$SKILLS_DIR/learned"
    mkdir -p "$SESSIONS_DIR/checkpoints"
    mkdir -p "$MEMORY_DIR"

    # Copy memory-persistence hooks
    if [[ -d "$template_dir/hooks/memory-persistence" ]]; then
        cp "$template_dir/hooks/memory-persistence/"*.sh "$HOOKS_DIR/memory-persistence/" 2>/dev/null || true
        chmod +x "$HOOKS_DIR/memory-persistence/"*.sh 2>/dev/null || true
        log_info "Installed memory-persistence hooks"
    fi

    # Copy strategic-compact hooks
    if [[ -d "$template_dir/hooks/strategic-compact" ]]; then
        cp "$template_dir/hooks/strategic-compact/"*.sh "$HOOKS_DIR/strategic-compact/" 2>/dev/null || true
        chmod +x "$HOOKS_DIR/strategic-compact/"*.sh 2>/dev/null || true
        log_info "Installed strategic-compact hooks"
    fi

    # Copy continuous-learning skill
    if [[ -d "$template_dir/skills/continuous-learning" ]]; then
        cp "$template_dir/skills/continuous-learning/"* "$SKILLS_DIR/continuous-learning/" 2>/dev/null || true
        chmod +x "$SKILLS_DIR/continuous-learning/"*.sh 2>/dev/null || true
        log_info "Installed continuous-learning skill"
    fi
}

# Create settings.json with hook configuration
create_settings() {
    local template_dir="$1"

    log_info "Creating settings.json with hook configuration..."

    if [[ -f "$template_dir/settings-hooks.json" ]]; then
        cp "$template_dir/settings-hooks.json" "$SETTINGS_FILE"
        log_info "Created $SETTINGS_FILE"
    else
        # Create settings manually if template not found
        # Hook commands use a wrapper to find project root, ensuring they work from any subdirectory or worktree
        cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'r=$PWD; while [ \"$r\" != / ] && [ ! -d \"$r/.specify\" ]; do r=$(dirname \"$r\"); done; [ -d \"$r/.specify\" ] && \"$r/.specify/hooks/memory-persistence/session-start.sh\"'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'r=$PWD; while [ \"$r\" != / ] && [ ! -d \"$r/.specify\" ]; do r=$(dirname \"$r\"); done; [ -d \"$r/.specify\" ] && \"$r/.specify/hooks/memory-persistence/session-end.sh\"'"
          },
          {
            "type": "command",
            "command": "bash -c 'r=$PWD; while [ \"$r\" != / ] && [ ! -d \"$r/.specify\" ]; do r=$(dirname \"$r\"); done; [ -d \"$r/.specify\" ] && \"$r/.specify/hooks/strategic-compact/suggest-compact.sh\"'"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'r=$PWD; while [ \"$r\" != / ] && [ ! -d \"$r/.specify\" ]; do r=$(dirname \"$r\"); done; [ -d \"$r/.specify\" ] && \"$r/.specify/hooks/memory-persistence/pre-compact.sh\"'"
          }
        ]
      }
    ]
  }
}
EOF
        log_info "Created $SETTINGS_FILE (from inline template)"
    fi
}

# Create initial memory context file
create_initial_context() {
    local context_file="$MEMORY_DIR/context.md"

    if [[ ! -f "$context_file" ]]; then
        cat > "$context_file" << EOF
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
EOF
        log_info "Created initial context file"
    fi
}

# Output JSON result
output_json() {
    local status="$1"
    local message="$2"

    cat << EOF
{
  "status": "$status",
  "message": "$message",
  "paths": {
    "hooks_dir": "$HOOKS_DIR",
    "skills_dir": "$SKILLS_DIR",
    "sessions_dir": "$SESSIONS_DIR",
    "memory_dir": "$MEMORY_DIR",
    "settings_file": "$SETTINGS_FILE"
  }
}
EOF
}

# Main execution
main() {
    log_info "Setting up Claude Code hooks for memory persistence..."

    # Check if already installed
    if check_existing_hooks; then
        log_info "Hooks already installed. Use --force to reinstall."
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            output_json "already_installed" "Hooks already installed"
        fi
        return 0
    fi

    # Find template directory
    template_dir=$(find_template_dir) || {
        log_error "Template directory not found. Run from spec-kit repo or after 'specify init'."
        if [[ "$JSON_OUTPUT" == "true" ]]; then
            output_json "error" "Template directory not found"
        fi
        return 1
    }

    log_info "Using templates from: $template_dir"

    # Copy hooks and create configuration
    copy_hooks "$template_dir"
    create_settings "$template_dir"
    create_initial_context

    log_info "Hook setup complete!"
    log_info ""
    log_info "Installed components:"
    log_info "  - Memory persistence hooks: $HOOKS_DIR/memory-persistence/"
    log_info "  - Strategic compact hooks: $HOOKS_DIR/strategic-compact/"
    log_info "  - Continuous learning skill: $SKILLS_DIR/continuous-learning/"
    log_info "  - Session logs: $SESSIONS_DIR/"
    log_info "  - Memory context: $MEMORY_DIR/"
    log_info "  - Hook configuration: $SETTINGS_FILE"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Review and customize $MEMORY_DIR/context.md"
    log_info "  2. Start a new Claude Code session to activate hooks"
    log_info "  3. Use /speckit.learn to extract patterns"
    log_info "  4. Use /speckit.checkpoint to save state"

    if [[ "$JSON_OUTPUT" == "true" ]]; then
        output_json "success" "Hooks installed successfully"
    fi
}

main "$@"

#!/usr/bin/env bash
# Auto-Learn: PostToolUse Hook - Capture results and detect corrections
# This hook runs after every tool call
# Captures results and uses regex to detect user corrections

set -euo pipefail

# Read JSON input from stdin (Claude Code passes hook data via stdin)
INPUT_JSON=$(cat)

# Get project root - prefer CLAUDE_PROJECT_DIR env var, fallback to search
get_project_root() {
    # Use Claude Code's project dir if available
    if [[ -n "${CLAUDE_PROJECT_DIR:-}" && -d "$CLAUDE_PROJECT_DIR/.specify" ]]; then
        echo "$CLAUDE_PROJECT_DIR"
        return 0
    fi
    # Fallback: search up from current directory
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.specify" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}

PROJECT_ROOT=$(get_project_root)
LEARNING_DIR="$PROJECT_ROOT/.specify/learning"

# Get current session directory
get_current_session_dir() {
    local session_file="$LEARNING_DIR/.current-session-dir"
    if [[ -f "$session_file" ]]; then
        cat "$session_file"
    fi
}

# Extract fields from JSON input
get_json_field() {
    local field="$1"
    echo "$INPUT_JSON" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*"\([^"]*\)"$/\1/' || echo ""
}

get_json_bool() {
    local field="$1"
    echo "$INPUT_JSON" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*[a-z]*" | sed 's/.*:[[:space:]]*//' || echo "false"
}

# Correction detection patterns
# Returns: NEGATIVE_PREFERENCE, POSITIVE_PREFERENCE, ERROR_CORRECTION, PROJECT_CONVENTION, or empty
detect_correction_type() {
    local text="$1"
    local lower_text
    lower_text=$(echo "$text" | tr '[:upper:]' '[:lower:]')

    # Direct negations - NEGATIVE_PREFERENCE
    if echo "$lower_text" | grep -qE '^(no,|no |nope|wrong|incorrect)'; then
        echo "NEGATIVE_PREFERENCE"
        return
    fi

    # Redirections - POSITIVE_PREFERENCE
    if echo "$lower_text" | grep -qE "(don.t|never|stop) (use|do|add)"; then
        echo "NEGATIVE_PREFERENCE"
        return
    fi

    if echo "$lower_text" | grep -qE "(actually|instead),? (use|do|try)"; then
        echo "POSITIVE_PREFERENCE"
        return
    fi

    # Explicit corrections - ERROR_CORRECTION
    if echo "$lower_text" | grep -qE "(should be|was supposed to be)"; then
        echo "ERROR_CORRECTION"
        return
    fi

    if echo "$lower_text" | grep -qE "(fix|correct|change) (that|this) to"; then
        echo "ERROR_CORRECTION"
        return
    fi

    # Revert requests - ERROR_CORRECTION
    if echo "$lower_text" | grep -qE "(revert|undo|rollback|that broke)"; then
        echo "ERROR_CORRECTION"
        return
    fi

    # Preferences - POSITIVE_PREFERENCE or PROJECT_CONVENTION
    if echo "$lower_text" | grep -qE "(in this (project|repo|codebase))"; then
        echo "PROJECT_CONVENTION"
        return
    fi

    if echo "$lower_text" | grep -qE "(prefer|always|i want|we use)"; then
        echo "POSITIVE_PREFERENCE"
        return
    fi

    # No correction detected
    echo ""
}

# Get initial confidence for correction type
get_initial_confidence() {
    local correction_type="$1"
    case "$correction_type" in
        "NEGATIVE_PREFERENCE") echo "0.5" ;;
        "POSITIVE_PREFERENCE") echo "0.5" ;;
        "ERROR_CORRECTION") echo "0.4" ;;
        "PROJECT_CONVENTION") echo "0.6" ;;
        *) echo "0.3" ;;
    esac
}

main() {
    local session_dir=$(get_current_session_dir)

    # Skip if no session directory
    [[ -z "$session_dir" || ! -d "$session_dir" ]] && exit 0

    local tools_file="$session_dir/tools.jsonl"
    local corrections_file="$session_dir/corrections.jsonl"

    # Get timestamp
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)

    # Extract tool information
    local tool_name
    tool_name=$(get_json_field "tool_name")
    [[ -z "$tool_name" ]] && exit 0

    # Check for tool success/failure
    local tool_error
    tool_error=$(get_json_field "error")
    local success="true"
    [[ -n "$tool_error" ]] && success="false"

    # Get the pre-event ID for correlation
    local pre_event_id=""
    if [[ -f "$session_dir/.last-event-id" ]]; then
        pre_event_id=$(cat "$session_dir/.last-event-id")
        rm -f "$session_dir/.last-event-id"
    fi

    # Generate post event ID
    local event_id
    event_id="post-$(date +%s%N | tail -c 12)"

    # Append post-tool record
    printf '%s\n' "{\"event_id\":\"$event_id\",\"pre_event_id\":\"$pre_event_id\",\"phase\":\"post\",\"timestamp\":\"$timestamp\",\"tool\":\"$tool_name\",\"success\":$success}" >> "$tools_file"

    # Check for user message that might contain corrections
    # The tool output or recent messages might contain correction signals
    local message_content
    message_content=$(get_json_field "message")

    if [[ -n "$message_content" ]]; then
        local correction_type
        correction_type=$(detect_correction_type "$message_content")

        if [[ -n "$correction_type" ]]; then
            local confidence
            confidence=$(get_initial_confidence "$correction_type")

            # Record the detected correction
            printf '%s\n' "{\"timestamp\":\"$timestamp\",\"type\":\"$correction_type\",\"confidence\":$confidence,\"tool\":\"$tool_name\",\"message\":\"$(echo "$message_content" | sed 's/"/\\"/g' | head -c 500)\",\"event_id\":\"$event_id\"}" >> "$corrections_file"
        fi
    fi
}

main "$@"

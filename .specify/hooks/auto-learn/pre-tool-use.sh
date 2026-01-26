#!/usr/bin/env bash
# Auto-Learn: PreToolUse Hook - Capture tool context before execution
# This hook runs before every tool call
# Captures context for later analysis - MUST BE FAST

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

# Get nested JSON field value
get_nested_json_field() {
    local parent="$1"
    local field="$2"
    echo "$INPUT_JSON" | grep -o "\"$parent\"[[:space:]]*:[[:space:]]*{[^}]*\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*"\([^"]*\)"$/\1/' || echo ""
}

main() {
    local session_dir=$(get_current_session_dir)

    # Skip if no session directory
    [[ -z "$session_dir" || ! -d "$session_dir" ]] && exit 0

    local tools_file="$session_dir/tools.jsonl"

    # Extract tool information
    local tool_name
    tool_name=$(get_json_field "tool_name")
    [[ -z "$tool_name" ]] && exit 0

    # Get tool input (file path for Edit/Write, etc.)
    local tool_input
    tool_input=$(get_nested_json_field "tool_input" "file_path")
    if [[ -z "$tool_input" ]]; then
        tool_input=$(get_nested_json_field "tool_input" "command")
    fi
    if [[ -z "$tool_input" ]]; then
        tool_input=$(get_nested_json_field "tool_input" "pattern")
    fi

    # Create pre-tool observation record
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)

    # Generate unique event ID
    local event_id
    event_id="pre-$(date +%s%N | tail -c 12)"

    # Append to tools.jsonl (atomic append)
    printf '%s\n' "{\"event_id\":\"$event_id\",\"phase\":\"pre\",\"timestamp\":\"$timestamp\",\"tool\":\"$tool_name\",\"input\":\"$(echo "$tool_input" | sed 's/"/\\"/g' | head -c 200)\"}" >> "$tools_file"

    # Store event ID for post-tool correlation
    echo "$event_id" > "$session_dir/.last-event-id"
}

main "$@"

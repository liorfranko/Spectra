#!/usr/bin/env bash
# Auto-Learn: Session End Hook - Queue session for background analysis
# This hook runs when a Claude Code session ends (Stop event)
# CRITICAL: This hook NEVER BLOCKS - it only queues the session for later analysis

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
PENDING_DIR="$LEARNING_DIR/pending-analysis"

log_status() { echo "[AutoLearn:SessionEnd] $1" >&2; }

# Get current session directory
get_current_session_dir() {
    local session_file="$LEARNING_DIR/.current-session-dir"
    if [[ -f "$session_file" ]]; then
        cat "$session_file"
    fi
}

# Get current session ID
get_current_session_id() {
    local session_file="$LEARNING_DIR/.current-session-id"
    if [[ -f "$session_file" ]]; then
        cat "$session_file"
    fi
}

# Extract fields from JSON input
get_json_field() {
    local field="$1"
    echo "$INPUT_JSON" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*"\([^"]*\)"$/\1/' || echo ""
}

main() {
    local session_dir=$(get_current_session_dir)
    local session_id=$(get_current_session_id)

    # Skip if no session tracking was initialized
    if [[ -z "$session_dir" || ! -d "$session_dir" ]]; then
        exit 0
    fi

    # Ensure pending directory exists
    mkdir -p "$PENDING_DIR"

    # Finalize session metadata
    local meta_file="$session_dir/session-meta.json"
    if [[ -f "$meta_file" ]]; then
        # Update with end time (using temp file for atomic update)
        local temp_meta="${meta_file}.tmp"
        local end_time
        end_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)

        # Add ended_at field to JSON
        sed 's/}$/,"ended_at":"'"$end_time"'"}/' "$meta_file" > "$temp_meta"
        mv "$temp_meta" "$meta_file"
    fi

    # Count observations
    local tool_count=0
    local correction_count=0
    if [[ -f "$session_dir/tools.jsonl" ]]; then
        tool_count=$(wc -l < "$session_dir/tools.jsonl" | tr -d ' ')
    fi
    if [[ -f "$session_dir/corrections.jsonl" ]]; then
        correction_count=$(wc -l < "$session_dir/corrections.jsonl" | tr -d ' ')
    fi

    # Only queue for analysis if there are corrections to process
    if [[ "$correction_count" -gt 0 ]]; then
        # Create a queue entry (just a symlink to the session dir for fast lookup)
        local queue_file="$PENDING_DIR/${session_id}.pending"
        echo "$session_dir" > "$queue_file"
        log_status "Queued session for analysis: $correction_count correction(s) detected"
    else
        log_status "Session complete: $tool_count tool event(s), no corrections to analyze"
    fi

    # Clean up current session markers
    rm -f "$LEARNING_DIR/.current-session-id"
    rm -f "$LEARNING_DIR/.current-session-dir"

    # IMPORTANT: Never block - just exit cleanly
    exit 0
}

main "$@"

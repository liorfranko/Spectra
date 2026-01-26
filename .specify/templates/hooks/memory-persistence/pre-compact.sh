#!/usr/bin/env bash
# Pre-Compact Hook - Save state before compaction
# This hook runs before Claude Code compacts the conversation

set -euo pipefail

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
SESSIONS_DIR="$PROJECT_ROOT/.specify/sessions"
COMPACTION_LOG="$SESSIONS_DIR/compaction-log.md"

# Output status to stderr
log_status() {
    echo "[pre-compact] $1" >&2
}

# Get current timestamp
get_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Get today's date
get_today() {
    date +%Y-%m-%d
}

# Log compaction event
log_compaction() {
    local timestamp=$(get_timestamp)

    mkdir -p "$SESSIONS_DIR"

    if [[ -f "$COMPACTION_LOG" ]]; then
        # Append to existing log
        cat >> "$COMPACTION_LOG" << EOF
| $timestamp | Automatic | Context preserved |
EOF
    else
        # Create new compaction log
        cat > "$COMPACTION_LOG" << EOF
# Compaction Log

This file tracks when Claude Code compacts the conversation context.

| Timestamp | Type | Notes |
|-----------|------|-------|
| $timestamp | Automatic | Context preserved |
EOF
    fi

    log_status "Logged compaction event"
}

# Update today's session log with compaction notice
update_session_log() {
    local today=$(get_today)
    local timestamp=$(get_timestamp)
    local session_file="$SESSIONS_DIR/${today}-session.md"

    if [[ -f "$session_file" ]]; then
        cat >> "$session_file" << EOF

---

## Compaction Notice: $timestamp

_Context was compacted at this point. Information before this may be summarized._

EOF
        log_status "Added compaction notice to session log"
    fi
}

# Main execution
main() {
    log_status "Saving state before compaction..."

    log_compaction
    update_session_log

    log_status "Pre-compact hook completed"
}

main "$@"

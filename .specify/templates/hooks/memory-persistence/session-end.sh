#!/usr/bin/env bash
# Stop Hook (Session End) - Persist learnings when session ends
# This hook runs when a Claude Code session ends (Stop event)

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
SESSIONS_DIR="$PROJECT_ROOT/.specify/sessions"

log_status() { echo "[SessionEnd] $1" >&2; }
get_today() { date +%Y-%m-%d; }
get_time() { date "+%H:%M"; }

# Get short session ID (last 8 chars) from JSON input
get_session_id_short() {
    # Extract session_id from JSON input, take last 8 chars
    local session_id
    session_id=$(echo "$INPUT_JSON" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
    if [[ -n "$session_id" ]]; then
        echo "${session_id: -8}"
    else
        # Generate ID from timestamp if session_id not available
        date +%H%M%S%N | tail -c 9
    fi
}

main() {
    local today=$(get_today)
    local current_time=$(get_time)
    local short_id=$(get_session_id_short)
    local session_file="$SESSIONS_DIR/${today}-${short_id}-session.md"

    mkdir -p "$SESSIONS_DIR"

    # If session file exists, update the Last Updated time
    if [[ -f "$session_file" ]]; then
        # Replace Last Updated line with new time
        if grep -q '\*\*Last Updated:\*\*' "$session_file"; then
            sed -i.bak "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $current_time/" "$session_file"
            rm -f "${session_file}.bak"
        fi
        log_status "Updated session file: $session_file"
    else
        # Create new session file with template
        cat > "$session_file" << EOF
# Session: $today
**Date:** $today
**Started:** $current_time
**Last Updated:** $current_time

---

## Current State

[Session context goes here]

### Completed
- [ ]

### In Progress
- [ ]

### Notes for Next Session
-

### Context to Load
\`\`\`
[relevant files]
\`\`\`
EOF
        log_status "Created session file: $session_file"
    fi
}

main "$@"

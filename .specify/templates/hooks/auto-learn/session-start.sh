#!/usr/bin/env bash
# Auto-Learn: Session Start Hook - Initialize session tracking
# This hook runs when a new Claude Code session begins
# Creates observation directory for this session

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
INSTINCTS_DIR="$LEARNING_DIR/instincts"

log_status() { echo "[AutoLearn:SessionStart] $1" >&2; }

# Get today's date
get_today() { date +%Y-%m-%d; }

# Extract session_id from JSON input
get_session_id() {
    local session_id
    session_id=$(echo "$INPUT_JSON" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
    if [[ -n "$session_id" ]]; then
        echo "$session_id"
    else
        # Fallback: generate ID from timestamp + random if not provided
        echo "$(date +%Y%m%d%H%M%S)-$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    fi
}

# Extract source field from JSON to detect session type
get_session_source() {
    echo "$INPUT_JSON" | grep -o '"source"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || echo "startup"
}

# Count active instincts
count_active_instincts() {
    if [[ -d "$INSTINCTS_DIR" ]]; then
        find "$INSTINCTS_DIR" -name "instinct-*.json" -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Find high-confidence instincts for session guidance
find_high_confidence_instincts() {
    if [[ ! -d "$INSTINCTS_DIR" ]]; then
        return
    fi

    local high_conf_count=0
    while IFS= read -r instinct_file; do
        [[ -z "$instinct_file" ]] && continue
        # Check if confidence >= 0.7
        local confidence
        confidence=$(grep -o '"confidence"[[:space:]]*:[[:space:]]*[0-9.]*' "$instinct_file" 2>/dev/null | sed 's/.*:[[:space:]]*//' || echo "0")
        if (( $(echo "$confidence >= 0.7" | bc -l 2>/dev/null || echo 0) )); then
            ((high_conf_count++))
        fi
    done < <(find "$INSTINCTS_DIR" -name "instinct-*.json" -type f 2>/dev/null)

    if [[ "$high_conf_count" -gt 0 ]]; then
        log_status "$high_conf_count high-confidence instinct(s) ready for skill promotion"
    fi
}

main() {
    local today=$(get_today)
    local session_id=$(get_session_id)
    local session_source=$(get_session_source)

    # Create session observation directory
    local session_obs_dir="$LEARNING_DIR/observations/${today}-${session_id}"
    mkdir -p "$session_obs_dir"
    mkdir -p "$INSTINCTS_DIR"
    mkdir -p "$LEARNING_DIR/pending-analysis"
    mkdir -p "$LEARNING_DIR/snapshots"

    # Detect if likely running in pipe/headless mode
    # Heuristic: check if stdin is a terminal (not reliable in hooks, so use source)
    local is_interactive="true"
    # In pipe mode (-p), sessions are typically short and don't resume
    # We can't reliably detect this, so default to interactive

    # Create session metadata file
    cat > "$session_obs_dir/session-meta.json" << EOF
{
    "session_id": "$session_id",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "project_root": "$PROJECT_ROOT",
    "source": "$session_source",
    "is_interactive": $is_interactive
}
EOF

    # Initialize empty observation files
    touch "$session_obs_dir/tools.jsonl"
    touch "$session_obs_dir/corrections.jsonl"

    # Export session ID for other hooks to use
    echo "$session_id" > "$LEARNING_DIR/.current-session-id"
    echo "$session_obs_dir" > "$LEARNING_DIR/.current-session-dir"

    log_status "Session tracking initialized: $session_obs_dir"

    # Report instinct stats
    local instinct_count=$(count_active_instincts)
    if [[ "$instinct_count" -gt 0 ]]; then
        log_status "$instinct_count active instinct(s) loaded"
        find_high_confidence_instincts
    fi
}

main "$@"

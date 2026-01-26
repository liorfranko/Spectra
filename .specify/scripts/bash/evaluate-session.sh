#!/usr/bin/env bash
# Continuous Learning - Session Evaluator
#
# Runs on Stop hook to extract reusable patterns from Claude Code sessions
# Uses JSON output to block Claude and request session documentation
#
# Why Stop hook instead of UserPromptSubmit:
# - Stop runs once at session end (lightweight)
# - UserPromptSubmit runs every message (heavy, adds latency)

set -euo pipefail

# Read JSON input from stdin (Claude Code passes hook data via stdin)
INPUT_JSON=$(cat)

# Get project root (where .specify/ lives)
get_project_root() {
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
SKILLS_DIR="$PROJECT_ROOT/.claude/skills/learned"
MIN_SESSION_LENGTH=3

# Extract fields from JSON input
get_json_field() {
    local field="$1"
    echo "$INPUT_JSON" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*"\([^"]*\)"$/\1/' || echo ""
}

get_json_bool() {
    local field="$1"
    echo "$INPUT_JSON" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*[a-z]*" | sed 's/.*:[[:space:]]*//' || echo "false"
}

main() {
    # Ensure directories exist
    mkdir -p "$SKILLS_DIR"
    mkdir -p "$SESSIONS_DIR"

    # Check if stop hook is already active (prevent infinite loop)
    local stop_hook_active
    stop_hook_active=$(get_json_bool "stop_hook_active")
    if [[ "$stop_hook_active" == "true" ]]; then
        # Already ran once, allow stop
        exit 0
    fi

    # Get transcript path from JSON input
    local transcript_path
    transcript_path=$(get_json_field "transcript_path")

    if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
        exit 0
    fi

    # Count user messages in session
    local message_count
    message_count=$(grep -c '"type":"user"' "$transcript_path" 2>/dev/null || echo "0")

    # Skip very short sessions
    if [[ "$message_count" -lt "$MIN_SESSION_LENGTH" ]]; then
        exit 0
    fi

    # Get session ID for the session file
    local session_id
    session_id=$(get_json_field "session_id")
    local short_id="${session_id: -8}"
    local today=$(date +%Y-%m-%d)
    local session_file="$SESSIONS_DIR/${today}-${short_id}-session.md"

    # Block Claude from stopping and ask it to document the session
    cat << EOF
{
  "decision": "block",
  "reason": "Before ending, please update the session file at $session_file with a summary of this session. Fill in the Current State, Completed tasks, In Progress items, and Notes for Next Session sections based on what was accomplished. Also, if you learned any reusable patterns or skills during this session, save them as markdown files in $SKILLS_DIR."
}
EOF
}

main "$@"

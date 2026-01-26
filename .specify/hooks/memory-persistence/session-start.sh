#!/usr/bin/env bash
# Session Start Hook - Load previous context on new session
# This hook runs when a new Claude Code session begins

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
SKILLS_DIR="$PROJECT_ROOT/.claude/skills/learned"
MEMORY_DIR="$PROJECT_ROOT/.specify/memory"

log_status() { echo "[SessionStart] $1" >&2; }

# Ensure directories exist
mkdir -p "$SESSIONS_DIR"
mkdir -p "$SKILLS_DIR"

# Find recent session files (last 7 days)
# Matches both old format (YYYY-MM-DD-session.md) and new format (YYYY-MM-DD-shortid-session.md)
find_recent_sessions() {
    if [[ -d "$SESSIONS_DIR" ]]; then
        find "$SESSIONS_DIR" -name "*-session.md" -type f -mtime -7 2>/dev/null | sort -r
    fi
}

main() {
    # Check for recent sessions
    recent_sessions=$(find_recent_sessions)
    if [[ -n "$recent_sessions" ]]; then
        session_count=$(echo "$recent_sessions" | wc -l | tr -d ' ')
        latest_session=$(echo "$recent_sessions" | head -1)
        log_status "Found $session_count recent session(s)"
        log_status "Latest: $latest_session"
    fi

    # Check for learned skills
    if [[ -d "$SKILLS_DIR" ]]; then
        skill_count=$(find "$SKILLS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$skill_count" -gt 0 ]]; then
            log_status "$skill_count learned skill(s) available in $SKILLS_DIR"
        fi
    fi

    # Check for persistent context
    if [[ -f "$MEMORY_DIR/context.md" ]]; then
        log_status "Persistent context available at $MEMORY_DIR/context.md"
    fi
}

main "$@"

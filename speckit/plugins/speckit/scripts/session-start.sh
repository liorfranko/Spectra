#!/usr/bin/env bash
# speckit/scripts/session-start.sh - Session Start Hook
# Loads current feature state and context when a new Claude Code session begins
# Creates observation directory for learning and initializes session tracking
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Read JSON input from stdin (Claude Code passes hook data via stdin)
INPUT_JSON=$(cat 2>/dev/null || echo "{}")

# =============================================================================
# Helper Functions
# =============================================================================

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

# Extract field from JSON input
get_json_field() {
    local field="$1"
    echo "$INPUT_JSON" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*"\([^"]*\)"$/\1/' || echo ""
}

# Get today's date
get_today() {
    date +%Y-%m-%d
}

# Generate a random hex string for session IDs
generate_random_hex() {
    if [[ -r /dev/urandom ]]; then
        head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n'
    else
        # Fallback for systems without /dev/urandom
        printf '%08x' $((RANDOM * RANDOM))
    fi
}

# Extract or generate session_id from JSON input
get_session_id() {
    local session_id
    session_id=$(get_json_field "session_id")
    if [[ -n "$session_id" ]]; then
        echo "$session_id"
    else
        # Fallback: generate ID from timestamp + random
        echo "$(date +%Y%m%d%H%M%S)-$(generate_random_hex)"
    fi
}

# Extract source field from JSON to detect session type
get_session_source() {
    local source
    source=$(get_json_field "source")
    echo "${source:-startup}"
}

# Log status message
log_status() {
    echo "[SpecKit:SessionStart] $1" >&2
}

# =============================================================================
# Feature State Loading
# =============================================================================

# Load current feature context from spec files
load_feature_context() {
    local feature_dir="$1"
    local context=""

    # Check for spec.md
    if [[ -f "${feature_dir}/spec.md" ]]; then
        context="Spec: ${feature_dir}/spec.md"
    fi

    # Check for plan.md
    if [[ -f "${feature_dir}/plan.md" ]]; then
        [[ -n "$context" ]] && context+=", "
        context+="Plan: ${feature_dir}/plan.md"
    fi

    # Check for tasks.md
    if [[ -f "${feature_dir}/tasks.md" ]]; then
        [[ -n "$context" ]] && context+=", "
        context+="Tasks: ${feature_dir}/tasks.md"
    fi

    echo "$context"
}

# Count pending tasks from tasks.md
count_pending_tasks() {
    local feature_dir="$1"
    local tasks_file="${feature_dir}/tasks.md"

    if [[ -f "$tasks_file" ]]; then
        # Count lines with [ ] (unchecked tasks)
        grep -c '\[ \]' "$tasks_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Count completed tasks from tasks.md
count_completed_tasks() {
    local feature_dir="$1"
    local tasks_file="${feature_dir}/tasks.md"

    if [[ -f "$tasks_file" ]]; then
        # Count lines with [x] or [X] (checked tasks)
        grep -c '\[[xX]\]' "$tasks_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# =============================================================================
# Learning System Initialization
# =============================================================================

# Initialize observation directory for learning
init_learning_session() {
    local project_root="$1"
    local session_id="$2"
    local session_source="$3"

    local learning_dir="$project_root/.specify/learning"
    local today=$(get_today)
    local session_obs_dir="$learning_dir/observations/${today}-${session_id}"

    # Create learning directories
    mkdir -p "$session_obs_dir"
    mkdir -p "$learning_dir/instincts"
    mkdir -p "$learning_dir/pending-analysis"
    mkdir -p "$learning_dir/snapshots"

    # Create session metadata file
    cat > "$session_obs_dir/session-meta.json" << EOF
{
    "session_id": "$session_id",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "project_root": "$project_root",
    "source": "$session_source",
    "is_interactive": true
}
EOF

    # Initialize empty observation files
    touch "$session_obs_dir/tools.jsonl"
    touch "$session_obs_dir/corrections.jsonl"

    # Export session ID for other hooks to use
    echo "$session_id" > "$learning_dir/.current-session-id"
    echo "$session_obs_dir" > "$learning_dir/.current-session-dir"

    echo "$session_obs_dir"
}

# Count active instincts
count_active_instincts() {
    local project_root="$1"
    local instincts_dir="$project_root/.specify/learning/instincts"

    if [[ -d "$instincts_dir" ]]; then
        find "$instincts_dir" -name "instinct-*.json" -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local project_root
    project_root=$(get_project_root)

    local session_id
    session_id=$(get_session_id)

    local session_source
    session_source=$(get_session_source)

    log_status "Session starting: $session_id"

    # Initialize learning session
    local session_obs_dir
    session_obs_dir=$(init_learning_session "$project_root" "$session_id" "$session_source")
    log_status "Learning initialized: $session_obs_dir"

    # Try to load feature context
    local feature_dir
    feature_dir=$(get_feature_dir 2>/dev/null) || feature_dir=""

    if [[ -n "$feature_dir" && -d "$feature_dir" ]]; then
        local feature_context
        feature_context=$(load_feature_context "$feature_dir")

        if [[ -n "$feature_context" ]]; then
            log_status "Feature context: $feature_context"
        fi

        # Report task status
        local pending_tasks completed_tasks
        pending_tasks=$(count_pending_tasks "$feature_dir")
        completed_tasks=$(count_completed_tasks "$feature_dir")

        if [[ "$pending_tasks" -gt 0 || "$completed_tasks" -gt 0 ]]; then
            log_status "Tasks: $completed_tasks completed, $pending_tasks pending"
        fi
    fi

    # Report instinct stats
    local instinct_count
    instinct_count=$(count_active_instincts "$project_root")
    if [[ "$instinct_count" -gt 0 ]]; then
        log_status "$instinct_count active instinct(s) loaded"
    fi

    # Check for memory context
    local context_file="$project_root/.specify/memory/context.md"
    if [[ -f "$context_file" ]]; then
        log_status "Memory context available: $context_file"
    fi

    # Check for constitution
    local constitution_file="$project_root/.specify/memory/constitution.md"
    if [[ -f "$constitution_file" ]]; then
        log_status "Constitution loaded: $constitution_file"
    fi

    log_status "Session ready"
}

main "$@"

#!/usr/bin/env bash
# Strategic Compact Hook - Suggest compaction at logical workflow boundaries
# This hook analyzes session state and suggests compaction when appropriate

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
SPECS_DIR="$PROJECT_ROOT/specs"

# Output status to stderr
log_status() {
    echo "[strategic-compact] $1" >&2
}

# Get today's date
get_today() {
    date +%Y-%m-%d
}

# Check if current feature has completed milestones
check_feature_milestones() {
    # Get current branch/feature
    local current_branch=""
    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    fi

    if [[ -z "$current_branch" ]] || [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
        return 1
    fi

    # Extract feature number
    if [[ ! "$current_branch" =~ ^([0-9]{3})- ]]; then
        return 1
    fi

    local prefix="${BASH_REMATCH[1]}"

    # Find matching spec directory
    local feature_dir=""
    for dir in "$SPECS_DIR"/"$prefix"-*; do
        if [[ -d "$dir" ]]; then
            feature_dir="$dir"
            break
        fi
    done

    if [[ -z "$feature_dir" ]]; then
        return 1
    fi

    # Check for completed artifacts
    local has_spec=false
    local has_plan=false
    local has_tasks=false

    [[ -f "$feature_dir/spec.md" ]] && has_spec=true
    [[ -f "$feature_dir/plan.md" ]] && has_plan=true
    [[ -f "$feature_dir/tasks.md" ]] && has_tasks=true

    # If all three exist, this is a good compaction point
    if $has_spec && $has_plan && $has_tasks; then
        echo "feature_complete"
        return 0
    fi

    # If spec and plan exist, also good
    if $has_spec && $has_plan; then
        echo "planning_complete"
        return 0
    fi

    return 1
}

# Check session duration (number of compaction events today)
check_session_duration() {
    local today=$(get_today)
    local compaction_log="$SESSIONS_DIR/compaction-log.md"

    if [[ ! -f "$compaction_log" ]]; then
        echo "0"
        return
    fi

    # Count compactions today
    grep -c "$today" "$compaction_log" 2>/dev/null || echo "0"
}

# Check for recent git commits
check_recent_commits() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 1
    fi

    # Check for commits in the last hour
    local recent_commits
    recent_commits=$(git log --since="1 hour ago" --oneline 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$recent_commits" -gt 0 ]]; then
        echo "$recent_commits"
        return 0
    fi

    return 1
}

# Main execution
main() {
    local suggest_compact=false
    local reason=""

    # Check for feature milestones
    milestone=$(check_feature_milestones 2>/dev/null || true)
    if [[ -n "$milestone" ]]; then
        suggest_compact=true
        case "$milestone" in
            "feature_complete")
                reason="Feature has spec, plan, and tasks completed"
                ;;
            "planning_complete")
                reason="Feature planning phase completed"
                ;;
        esac
    fi

    # Check for multiple compactions today (extended session)
    compaction_count=$(check_session_duration)
    if [[ "$compaction_count" -ge 3 ]]; then
        suggest_compact=true
        reason="${reason:+$reason; }Extended session with $compaction_count compactions"
    fi

    # Check for significant commits
    recent_commits=$(check_recent_commits 2>/dev/null || true)
    if [[ -n "$recent_commits" ]]; then
        suggest_compact=true
        reason="${reason:+$reason; }$recent_commits commit(s) made in last hour"
    fi

    # Output recommendation
    if $suggest_compact; then
        log_status "Compaction recommended: $reason"
        log_status "Consider running /compact to clear completed context"
    fi
}

main "$@"

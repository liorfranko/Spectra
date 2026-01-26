#!/usr/bin/env bash
# Auto-Learn: PreCompact Hook - Snapshot high-confidence instincts before compaction
# This hook runs before Claude Code compacts the conversation
# Creates snapshots of instincts that might be affected by context loss

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
LEARNING_DIR="$PROJECT_ROOT/.specify/learning"
INSTINCTS_DIR="$LEARNING_DIR/instincts"
SNAPSHOTS_DIR="$LEARNING_DIR/snapshots"

log_status() { echo "[AutoLearn:PreCompact] $1" >&2; }

# Get timestamp for snapshot
get_timestamp() { date +%Y%m%d-%H%M%S; }

main() {
    # Skip if no instincts directory
    if [[ ! -d "$INSTINCTS_DIR" ]]; then
        exit 0
    fi

    # Count instincts
    local instinct_count
    instinct_count=$(find "$INSTINCTS_DIR" -name "instinct-*.json" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$instinct_count" -eq 0 ]]; then
        exit 0
    fi

    # Create snapshot directory
    mkdir -p "$SNAPSHOTS_DIR"

    local timestamp=$(get_timestamp)
    local snapshot_file="$SNAPSHOTS_DIR/instincts-${timestamp}.snapshot"

    # Create a simple snapshot with high-confidence instincts
    {
        echo "# Instincts Snapshot: $timestamp"
        echo "# Taken before context compaction"
        echo ""

        while IFS= read -r instinct_file; do
            [[ -z "$instinct_file" ]] && continue
            local confidence
            confidence=$(grep -o '"confidence"[[:space:]]*:[[:space:]]*[0-9.]*' "$instinct_file" 2>/dev/null | sed 's/.*:[[:space:]]*//' || echo "0")

            # Only snapshot instincts with confidence >= 0.5
            if (( $(echo "$confidence >= 0.5" | bc -l 2>/dev/null || echo 0) )); then
                echo "## $(basename "$instinct_file")"
                cat "$instinct_file"
                echo ""
            fi
        done < <(find "$INSTINCTS_DIR" -name "instinct-*.json" -type f 2>/dev/null)
    } > "$snapshot_file"

    log_status "Created instincts snapshot: $snapshot_file ($instinct_count instincts)"

    # Prune old snapshots (keep last 10)
    local snapshot_count
    snapshot_count=$(find "$SNAPSHOTS_DIR" -name "*.snapshot" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$snapshot_count" -gt 10 ]]; then
        # Delete oldest snapshots
        find "$SNAPSHOTS_DIR" -name "*.snapshot" -type f -printf '%T@ %p\n' 2>/dev/null | \
            sort -n | head -n $((snapshot_count - 10)) | cut -d' ' -f2- | xargs rm -f 2>/dev/null || true
    fi
}

main "$@"

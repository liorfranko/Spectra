#!/usr/bin/env bash
# projspec/scripts/purge-events.sh - Purge old events from the observability database
# Deletes events older than the specified number of days
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use CLAUDE_PLUGIN_ROOT if set, otherwise calculate from script location
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    PLUGIN_DIR="$CLAUDE_PLUGIN_ROOT"
else
    PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
fi

PROJSPEC_HOME="${HOME}/.projspec"
DB_FILE="$PROJSPEC_HOME/observability.db"

# Default retention period
DEFAULT_RETENTION_DAYS=7

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Purge old events from the observability database.

OPTIONS:
    --days=N        Delete events older than N days (default: $DEFAULT_RETENTION_DAYS)
    --dry-run       Show what would be deleted without actually deleting
    --all           Delete ALL events (requires confirmation)
    --json          Output results in JSON format
    -h, --help      Show this help message

EXAMPLES:
    $(basename "$0")                # Delete events older than $DEFAULT_RETENTION_DAYS days
    $(basename "$0") --days=14      # Delete events older than 14 days
    $(basename "$0") --dry-run      # Preview what would be deleted
    $(basename "$0") --all          # Delete all events
EOF
}

# =============================================================================
# Utility Functions
# =============================================================================

# Check if sqlite3 is available
check_sqlite() {
    if ! command -v sqlite3 &>/dev/null; then
        echo "ERROR: sqlite3 is required but not installed" >&2
        exit 1
    fi
}

# Get count of events to be deleted
get_events_to_delete_count() {
    local cutoff_ms=$1
    sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM events WHERE timestamp < $cutoff_ms;" 2>/dev/null || echo "0"
}

# Get total event count
get_total_event_count() {
    sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo "0"
}

# Get oldest event timestamp
get_oldest_event() {
    local oldest_ts
    oldest_ts=$(sqlite3 "$DB_FILE" "SELECT MIN(timestamp) FROM events;" 2>/dev/null || echo "")

    if [[ -n "$oldest_ts" ]] && [[ "$oldest_ts" != "" ]]; then
        # Convert milliseconds to date
        if [[ "$(uname)" == "Darwin" ]]; then
            date -r "$((oldest_ts / 1000))" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown"
        else
            date -d "@$((oldest_ts / 1000))" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown"
        fi
    else
        echo "none"
    fi
}

# Delete events older than cutoff
delete_old_events() {
    local cutoff_ms=$1
    sqlite3 "$DB_FILE" "DELETE FROM events WHERE timestamp < $cutoff_ms;" 2>/dev/null
    echo $?
}

# Delete all events
delete_all_events() {
    sqlite3 "$DB_FILE" "DELETE FROM events;" 2>/dev/null
    echo $?
}

# Vacuum database to reclaim space
vacuum_database() {
    sqlite3 "$DB_FILE" "VACUUM;" 2>/dev/null
}

# =============================================================================
# Main
# =============================================================================

main() {
    local days=$DEFAULT_RETENTION_DAYS
    local dry_run=false
    local delete_all=false
    local json_output=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --days=*)
                days="${1#*=}"
                if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                    echo "ERROR: --days must be a positive integer" >&2
                    exit 1
                fi
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --all)
                delete_all=true
                shift
                ;;
            --json)
                json_output=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    check_sqlite

    # Check if database exists
    if [[ ! -f "$DB_FILE" ]]; then
        if [[ "$json_output" == "true" ]]; then
            echo '{"success": true, "message": "No database found", "deleted_count": 0}'
        else
            echo "INFO: No database found at $DB_FILE"
            echo "Nothing to purge."
        fi
        exit 0
    fi

    # Get current counts
    local total_before
    total_before=$(get_total_event_count)
    local oldest_event
    oldest_event=$(get_oldest_event)

    if [[ "$delete_all" == "true" ]]; then
        # Delete all events
        if [[ "$dry_run" == "true" ]]; then
            if [[ "$json_output" == "true" ]]; then
                echo "{\"dry_run\": true, \"would_delete\": $total_before, \"total_events\": $total_before}"
            else
                echo "DRY RUN: Would delete ALL $total_before events"
            fi
        else
            # Confirm deletion
            if [[ "$json_output" != "true" ]]; then
                echo "WARNING: This will delete ALL $total_before events!"
                read -p "Are you sure? (yes/no): " confirm
                if [[ "$confirm" != "yes" ]]; then
                    echo "Aborted."
                    exit 0
                fi
            fi

            delete_all_events
            vacuum_database

            if [[ "$json_output" == "true" ]]; then
                echo "{\"success\": true, \"deleted_count\": $total_before, \"remaining_count\": 0}"
            else
                echo "Deleted all $total_before events."
                echo "Database vacuumed to reclaim space."
            fi
        fi
    else
        # Calculate cutoff timestamp (current time minus retention days)
        local cutoff_ms
        cutoff_ms=$(($(date +%s) * 1000 - days * 24 * 60 * 60 * 1000))

        # Get count of events to delete
        local to_delete
        to_delete=$(get_events_to_delete_count "$cutoff_ms")

        if [[ "$dry_run" == "true" ]]; then
            if [[ "$json_output" == "true" ]]; then
                echo "{\"dry_run\": true, \"retention_days\": $days, \"would_delete\": $to_delete, \"would_remain\": $((total_before - to_delete)), \"total_events\": $total_before, \"oldest_event\": \"$oldest_event\"}"
            else
                echo "DRY RUN: Purging events older than $days days"
                echo ""
                echo "Database:     $DB_FILE"
                echo "Total events: $total_before"
                echo "Oldest event: $oldest_event"
                echo ""
                echo "Would delete: $to_delete events"
                echo "Would remain: $((total_before - to_delete)) events"
            fi
        else
            if [[ "$to_delete" -eq 0 ]]; then
                if [[ "$json_output" == "true" ]]; then
                    echo "{\"success\": true, \"deleted_count\": 0, \"remaining_count\": $total_before, \"message\": \"No events older than $days days\"}"
                else
                    echo "No events older than $days days to delete."
                    echo "Total events: $total_before"
                fi
            else
                # Delete old events
                delete_old_events "$cutoff_ms"

                local remaining
                remaining=$(get_total_event_count)
                local deleted=$((total_before - remaining))

                # Vacuum to reclaim space
                vacuum_database

                if [[ "$json_output" == "true" ]]; then
                    echo "{\"success\": true, \"deleted_count\": $deleted, \"remaining_count\": $remaining, \"retention_days\": $days}"
                else
                    echo "Purged events older than $days days"
                    echo ""
                    echo "Deleted:   $deleted events"
                    echo "Remaining: $remaining events"
                    echo ""
                    echo "Database vacuumed to reclaim space."
                fi
            fi
        fi
    fi
}

main "$@"

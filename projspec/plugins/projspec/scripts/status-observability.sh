#!/usr/bin/env bash
# projspec/scripts/status-observability.sh - Check status of the observability server
# Reports server status, ports, and database information
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use CLAUDE_PLUGIN_ROOT if set, otherwise calculate from script location
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    PLUGIN_DIR="$CLAUDE_PLUGIN_ROOT"
else
    PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
fi

PROJSPEC_HOME="${HOME}/.projspec"
PID_FILE="$PROJSPEC_HOME/observability.pid"
DB_FILE="$PROJSPEC_HOME/observability.db"

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check the status of the multi-agent observability server.

OPTIONS:
    --json      Output status in JSON format
    -h, --help  Show this help message

EXAMPLES:
    $(basename "$0")        # Show human-readable status
    $(basename "$0") --json # Show status as JSON
EOF
}

# =============================================================================
# Utility Functions
# =============================================================================

# Check if a process is running
is_process_running() {
    local pid=$1
    kill -0 "$pid" 2>/dev/null
}

# Get file size in human-readable format
get_file_size() {
    local file=$1
    if [[ -f "$file" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            stat -f%z "$file" 2>/dev/null || echo "0"
        else
            stat -c%s "$file" 2>/dev/null || echo "0"
        fi
    else
        echo "0"
    fi
}

# Format bytes to human-readable
format_bytes() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024)) KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$((bytes / 1048576)) MB"
    else
        echo "$((bytes / 1073741824)) GB"
    fi
}

# Get event count from database
get_event_count() {
    if [[ -f "$DB_FILE" ]] && command -v sqlite3 &>/dev/null; then
        sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Check if server is responding
check_server_health() {
    local port=$1
    if command -v curl &>/dev/null; then
        curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/" 2>/dev/null || echo "0"
    else
        echo "unknown"
    fi
}

# =============================================================================
# Status Functions
# =============================================================================

get_status() {
    local server_running="false"
    local server_pid=""
    local server_port=""
    local db_path=""
    local log_path=""
    local started_at=""
    local db_size="0"
    local event_count="unknown"
    local http_status="0"

    # Check if PID file exists
    if [[ -f "$PID_FILE" ]]; then
        local pid_info
        pid_info=$(cat "$PID_FILE" 2>/dev/null || echo "{}")

        # Extract values using grep/sed for compatibility
        server_pid=$(echo "$pid_info" | grep -o '"server_pid":[0-9]*' | cut -d: -f2 || echo "")
        server_port=$(echo "$pid_info" | grep -o '"server_port":[0-9]*' | cut -d: -f2 || echo "")
        db_path=$(echo "$pid_info" | grep -o '"database_path":"[^"]*"' | sed 's/"database_path":"//;s/"$//' || echo "")
        log_path=$(echo "$pid_info" | grep -o '"log_path":"[^"]*"' | sed 's/"log_path":"//;s/"$//' || echo "")
        started_at=$(echo "$pid_info" | grep -o '"started_at":"[^"]*"' | sed 's/"started_at":"//;s/"$//' || echo "")

        # Check if process is actually running
        if [[ -n "$server_pid" ]] && is_process_running "$server_pid"; then
            server_running="true"

            # Check server health
            if [[ -n "$server_port" ]]; then
                http_status=$(check_server_health "$server_port")
            fi
        fi
    fi

    # Get database info
    if [[ -z "$db_path" ]]; then
        db_path="$DB_FILE"
    fi

    if [[ -f "$db_path" ]]; then
        db_size=$(get_file_size "$db_path")
        event_count=$(get_event_count)
    fi

    # Output results
    echo "server_running=$server_running"
    echo "server_pid=$server_pid"
    echo "server_port=$server_port"
    echo "database_path=$db_path"
    echo "database_size=$db_size"
    echo "event_count=$event_count"
    echo "log_path=$log_path"
    echo "started_at=$started_at"
    echo "http_status=$http_status"
}

output_text() {
    # Read status into variables
    eval "$(get_status)"

    echo "Multi-Agent Observability Status"
    echo "================================="
    echo ""

    if [[ "$server_running" == "true" ]]; then
        echo "Server:    RUNNING"
        echo "  PID:     $server_pid"
        echo "  Port:    $server_port"
        echo "  API:     http://localhost:$server_port/events"
        echo "  Stream:  ws://localhost:$server_port/stream"

        if [[ "$http_status" == "200" ]]; then
            echo "  Health:  OK"
        elif [[ "$http_status" != "unknown" ]] && [[ "$http_status" != "0" ]]; then
            echo "  Health:  Warning (HTTP $http_status)"
        else
            echo "  Health:  Unknown"
        fi

        if [[ -n "$started_at" ]]; then
            echo "  Started: $started_at"
        fi
    else
        echo "Server:    NOT RUNNING"
    fi

    echo ""
    echo "Database:"
    echo "  Path:    $database_path"

    if [[ -f "$database_path" ]]; then
        echo "  Size:    $(format_bytes "$database_size")"
        echo "  Events:  $event_count"
    else
        echo "  Status:  Not created yet"
    fi

    if [[ -n "$log_path" ]] && [[ -f "$log_path" ]]; then
        local log_size
        log_size=$(get_file_size "$log_path")
        echo ""
        echo "Logs:"
        echo "  Path:    $log_path"
        echo "  Size:    $(format_bytes "$log_size")"
    fi
}

output_json() {
    # Read status into variables
    eval "$(get_status)"

    # Handle nullable fields
    local pid_json="null"
    local port_json="null"
    local started_json="null"
    local http_json="null"

    if [[ -n "$server_pid" ]]; then
        pid_json="$server_pid"
    fi
    if [[ -n "$server_port" ]]; then
        port_json="$server_port"
    fi
    if [[ -n "$started_at" ]]; then
        started_json="\"$started_at\""
    fi
    if [[ -n "$http_status" ]] && [[ "$http_status" != "0" ]]; then
        http_json="$http_status"
    fi

    cat <<EOF
{
  "server": {
    "running": $server_running,
    "pid": $pid_json,
    "port": $port_json,
    "started_at": $started_json,
    "http_status": $http_json
  },
  "database": {
    "path": "$database_path",
    "size_bytes": $database_size,
    "event_count": "$event_count"
  },
  "log": {
    "path": "${log_path:-$PROJSPEC_HOME/observability.log}"
  }
}
EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    local json_output=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
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

    if [[ "$json_output" == "true" ]]; then
        output_json
    else
        output_text
    fi
}

main "$@"

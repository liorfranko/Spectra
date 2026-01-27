#!/usr/bin/env bash
# projspec/scripts/stop-observability.sh - Stop the multi-agent observability server
# Gracefully stops the server process and cleans up
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

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Stop the multi-agent observability server.

OPTIONS:
    --force     Force kill the process (use SIGKILL instead of SIGTERM)
    -h, --help  Show this help message

EXAMPLES:
    $(basename "$0")         # Gracefully stop the server
    $(basename "$0") --force # Force stop the server
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

# Stop a process gracefully
stop_process() {
    local pid=$1
    local force=${2:-false}
    local name=${3:-"process"}
    local timeout=10

    if ! is_process_running "$pid"; then
        echo "INFO: $name (PID: $pid) is not running"
        return 0
    fi

    if [[ "$force" == "true" ]]; then
        echo "Force stopping $name (PID: $pid)..."
        kill -9 "$pid" 2>/dev/null || true
    else
        echo "Stopping $name (PID: $pid)..."
        kill -TERM "$pid" 2>/dev/null || true

        # Wait for graceful shutdown
        local count=0
        while is_process_running "$pid" && [[ $count -lt $timeout ]]; do
            sleep 1
            count=$((count + 1))
        done

        # Force kill if still running
        if is_process_running "$pid"; then
            echo "WARN: $name did not stop gracefully, forcing..."
            kill -9 "$pid" 2>/dev/null || true
            sleep 1
        fi
    fi

    if is_process_running "$pid"; then
        echo "ERROR: Failed to stop $name (PID: $pid)" >&2
        return 1
    fi

    echo "INFO: $name stopped"
    return 0
}

# =============================================================================
# Main
# =============================================================================

main() {
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
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

    # Check if PID file exists
    if [[ ! -f "$PID_FILE" ]]; then
        echo "INFO: Observability server is not running (no PID file found)"
        exit 0
    fi

    # Read PID file
    local pid_info
    pid_info=$(cat "$PID_FILE" 2>/dev/null || echo "{}")

    # Extract server PID using grep/sed for compatibility
    local server_pid
    server_pid=$(echo "$pid_info" | grep -o '"server_pid":[0-9]*' | cut -d: -f2 || echo "")

    if [[ -z "$server_pid" ]]; then
        echo "WARN: Could not read server PID from PID file" >&2
        rm -f "$PID_FILE"
        exit 0
    fi

    # Stop server process
    if stop_process "$server_pid" "$force" "server"; then
        # Clean up PID file
        rm -f "$PID_FILE"
        echo ""
        echo "Observability server stopped successfully."
    else
        echo ""
        echo "ERROR: Failed to stop observability server" >&2
        exit 1
    fi
}

main "$@"

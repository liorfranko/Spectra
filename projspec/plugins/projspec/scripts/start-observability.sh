#!/usr/bin/env bash
# projspec/scripts/start-observability.sh - Start the multi-agent observability server
# Starts both the Bun server and serves the client from server/static
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use CLAUDE_PLUGIN_ROOT if set, otherwise calculate from script location
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    PLUGIN_DIR="$CLAUDE_PLUGIN_ROOT"
else
    PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
fi

OBSERVABILITY_DIR="$PLUGIN_DIR/observability"
PROJSPEC_HOME="${HOME}/.projspec"
PID_FILE="$PROJSPEC_HOME/observability.pid"
LOG_FILE="$PROJSPEC_HOME/observability.log"
DB_FILE="$PROJSPEC_HOME/observability.db"

# Default ports
DEFAULT_SERVER_PORT=4000
DEFAULT_CLIENT_PORT=3000

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Start the multi-agent observability server and client.

OPTIONS:
    --server-port=PORT    Server port (default: $DEFAULT_SERVER_PORT)
    --client-port=PORT    Client port (default: $DEFAULT_CLIENT_PORT)
    --foreground          Run in foreground (don't daemonize)
    -h, --help            Show this help message

EXAMPLES:
    $(basename "$0")                           # Start with default ports
    $(basename "$0") --server-port=4001        # Use custom server port
    $(basename "$0") --foreground              # Run in foreground for debugging
EOF
}

# =============================================================================
# Utility Functions
# =============================================================================

# Find an available port starting from the given port
find_available_port() {
    local port=$1
    while lsof -i :"$port" >/dev/null 2>&1; do
        port=$((port + 1))
    done
    echo "$port"
}

# Check if a process is running
is_process_running() {
    local pid=$1
    kill -0 "$pid" 2>/dev/null
}

# =============================================================================
# Pre-flight Checks
# =============================================================================

preflight_checks() {
    # Check if bun is installed
    if ! command -v bun &>/dev/null; then
        echo "ERROR: bun is not installed. Please install bun: https://bun.sh" >&2
        exit 1
    fi

    # Check if observability directory exists
    if [[ ! -d "$OBSERVABILITY_DIR" ]]; then
        echo "ERROR: Observability directory not found: $OBSERVABILITY_DIR" >&2
        exit 1
    fi

    # Check if server source exists
    if [[ ! -f "$OBSERVABILITY_DIR/server/src/index.ts" ]]; then
        echo "ERROR: Server source not found: $OBSERVABILITY_DIR/server/src/index.ts" >&2
        exit 1
    fi

    # Check if already running
    if [[ -f "$PID_FILE" ]]; then
        local pid_info
        pid_info=$(cat "$PID_FILE" 2>/dev/null || echo "{}")

        local server_pid
        server_pid=$(echo "$pid_info" | grep -o '"server_pid":[0-9]*' | cut -d: -f2 || echo "")

        if [[ -n "$server_pid" ]] && is_process_running "$server_pid"; then
            echo "ERROR: Observability server is already running (PID: $server_pid)" >&2
            echo "Use 'stop-observability.sh' to stop it first." >&2
            exit 1
        else
            # Stale PID file, remove it
            rm -f "$PID_FILE"
        fi
    fi

    # Create projspec home directory if it doesn't exist
    mkdir -p "$PROJSPEC_HOME"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local server_port=$DEFAULT_SERVER_PORT
    local client_port=$DEFAULT_CLIENT_PORT
    local foreground=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --server-port=*)
                server_port="${1#*=}"
                shift
                ;;
            --client-port=*)
                client_port="${1#*=}"
                shift
                ;;
            --foreground)
                foreground=true
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

    # Run pre-flight checks
    preflight_checks

    # Find available ports
    server_port=$(find_available_port "$server_port")

    # Report port selection
    if [[ "$server_port" -ne $DEFAULT_SERVER_PORT ]]; then
        echo "INFO: Default server port $DEFAULT_SERVER_PORT is in use, using port $server_port"
    fi

    echo "Starting Multi-Agent Observability Server..."
    echo "  Server:   http://localhost:$server_port"
    echo "  Database: $DB_FILE"
    echo "  Logs:     $LOG_FILE"

    # Change to server directory
    cd "$OBSERVABILITY_DIR/server"

    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        echo "Installing server dependencies..."
        bun install --silent
    fi

    # Prepare environment
    export SERVER_PORT="$server_port"
    export DB_PATH="$DB_FILE"

    if [[ "$foreground" == "true" ]]; then
        # Run in foreground
        echo ""
        echo "Running in foreground mode. Press Ctrl+C to stop."
        echo ""
        bun src/index.ts
    else
        # Run in background
        nohup bun src/index.ts >> "$LOG_FILE" 2>&1 &
        local server_pid=$!

        # Wait a moment to ensure server starts
        sleep 1

        # Verify server is running
        if ! is_process_running "$server_pid"; then
            echo "ERROR: Server failed to start. Check logs: $LOG_FILE" >&2
            exit 1
        fi

        # Write PID file with JSON format
        cat > "$PID_FILE" <<EOF
{
  "server_pid": $server_pid,
  "server_port": $server_port,
  "database_path": "$DB_FILE",
  "log_path": "$LOG_FILE",
  "started_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

        echo ""
        echo "Observability server started successfully!"
        echo "  PID:      $server_pid"
        echo "  API:      http://localhost:$server_port/events"
        echo "  Stream:   ws://localhost:$server_port/stream"
        echo ""
        echo "To view logs: tail -f $LOG_FILE"
        echo "To stop:      $(dirname "$0")/stop-observability.sh"
    fi
}

main "$@"

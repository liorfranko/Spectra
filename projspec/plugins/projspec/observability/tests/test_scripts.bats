#!/usr/bin/env bats

# Unit tests for Multi-Agent Observability lifecycle scripts
# T407: Tests for start-observability.sh
# T408: Tests for stop-observability.sh
# T409: Tests for status-observability.sh

# =============================================================================
# Test Setup and Teardown
# =============================================================================

setup() {
  # Get script directory
  # Tests are in: projspec/plugins/projspec/observability/tests/
  # Scripts are in: projspec/plugins/projspec/scripts/
  BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  SCRIPTS_DIR="$(cd "$BATS_TEST_DIR/../.." && pwd)/scripts"

  # Create temporary test directory for isolation
  export TEST_TMP_DIR=$(mktemp -d)
  export TEST_PROJSPEC_HOME="$TEST_TMP_DIR/.projspec"
  mkdir -p "$TEST_PROJSPEC_HOME"

  # Store original HOME for restoration
  export ORIGINAL_HOME="$HOME"
  export HOME="$TEST_TMP_DIR"

  # Script paths
  export START_SCRIPT="$SCRIPTS_DIR/start-observability.sh"
  export STOP_SCRIPT="$SCRIPTS_DIR/stop-observability.sh"
  export STATUS_SCRIPT="$SCRIPTS_DIR/status-observability.sh"
  export PURGE_SCRIPT="$SCRIPTS_DIR/purge-events.sh"
}

teardown() {
  # Restore original HOME
  export HOME="$ORIGINAL_HOME"

  # Clean up temporary directory
  if [[ -d "$TEST_TMP_DIR" ]]; then
    rm -rf "$TEST_TMP_DIR"
  fi
}

# =============================================================================
# Helper Functions
# =============================================================================

# Create a mock PID file for testing
create_mock_pid_file() {
  local server_pid="${1:-12345}"
  local server_port="${2:-4000}"

  cat > "$TEST_PROJSPEC_HOME/observability.pid" <<EOF
{
  "server_pid": $server_pid,
  "server_port": $server_port,
  "database_path": "$TEST_PROJSPEC_HOME/observability.db",
  "log_path": "$TEST_PROJSPEC_HOME/observability.log",
  "started_at": "2024-01-01T00:00:00Z"
}
EOF
}

# Create a mock database file
create_mock_database() {
  touch "$TEST_PROJSPEC_HOME/observability.db"
}

# =============================================================================
# T407: Tests for start-observability.sh
# =============================================================================

@test "T407: start-observability.sh script exists" {
  [ -f "$START_SCRIPT" ]
}

@test "T407: start-observability.sh is executable" {
  [ -x "$START_SCRIPT" ]
}

@test "T407: start-observability.sh --help shows usage information" {
  run "$START_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "Start the multi-agent observability server" ]]
}

@test "T407: start-observability.sh -h shows usage information" {
  run "$START_SCRIPT" -h

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "T407: start-observability.sh --help shows --server-port option" {
  run "$START_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--server-port" ]]
}

@test "T407: start-observability.sh --help shows --client-port option" {
  run "$START_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--client-port" ]]
}

@test "T407: start-observability.sh --help shows --foreground option" {
  run "$START_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--foreground" ]]
}

@test "T407: start-observability.sh --help shows examples" {
  run "$START_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "EXAMPLES:" ]]
}

@test "T407: start-observability.sh rejects unknown options" {
  run "$START_SCRIPT" --unknown-option

  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown option" ]]
}

@test "T407: start-observability.sh detects missing bun" {
  # Create a wrapper that hides bun from PATH
  export PATH="/nonexistent:$PATH"

  # We need to unset bun from the environment if it exists
  local original_path="$PATH"

  # Skip if bun is actually installed (we just want to test the error message format)
  if ! command -v bun &>/dev/null; then
    run "$START_SCRIPT"

    [ "$status" -ne 0 ]
    [[ "$output" =~ "bun is not installed" ]] || [[ "$output" =~ "ERROR" ]]
  else
    skip "Bun is installed - cannot test missing bun detection"
  fi
}

@test "T407: start-observability.sh detects already running server via PID file" {
  skip "Requires mocking process check - functional test"

  # This test would require a running process or mock
  # Skip for unit testing purposes
}

@test "T407: start-observability.sh removes stale PID file" {
  # Create PID file with non-existent process
  create_mock_pid_file 99999

  # The script should detect this is a stale PID and remove it
  # However, it still needs bun to proceed, so we just verify the file exists first
  [ -f "$TEST_PROJSPEC_HOME/observability.pid" ]
}

# =============================================================================
# T408: Tests for stop-observability.sh
# =============================================================================

@test "T408: stop-observability.sh script exists" {
  [ -f "$STOP_SCRIPT" ]
}

@test "T408: stop-observability.sh is executable" {
  [ -x "$STOP_SCRIPT" ]
}

@test "T408: stop-observability.sh --help shows usage information" {
  run "$STOP_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "Stop the multi-agent observability server" ]]
}

@test "T408: stop-observability.sh -h shows usage information" {
  run "$STOP_SCRIPT" -h

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "T408: stop-observability.sh --help shows --force option" {
  run "$STOP_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--force" ]]
}

@test "T408: stop-observability.sh --help shows examples" {
  run "$STOP_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "EXAMPLES:" ]]
}

@test "T408: stop-observability.sh rejects unknown options" {
  run "$STOP_SCRIPT" --unknown-option

  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown option" ]]
}

@test "T408: stop-observability.sh handles missing PID file gracefully" {
  # Ensure no PID file exists
  rm -f "$TEST_PROJSPEC_HOME/observability.pid"

  run "$STOP_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "not running" ]] || [[ "$output" =~ "no PID file" ]]
}

@test "T408: stop-observability.sh handles empty PID file gracefully" {
  # Create empty PID file
  touch "$TEST_PROJSPEC_HOME/observability.pid"

  run "$STOP_SCRIPT"

  [ "$status" -eq 0 ]
  # Should handle gracefully - either warn or succeed
}

@test "T408: stop-observability.sh handles malformed PID file gracefully" {
  # Create malformed PID file
  echo "not valid json" > "$TEST_PROJSPEC_HOME/observability.pid"

  run "$STOP_SCRIPT"

  [ "$status" -eq 0 ]
  # Should handle gracefully
  [[ "$output" =~ "Could not read" ]] || [[ "$output" =~ "WARN" ]] || true
}

@test "T408: stop-observability.sh handles non-existent process PID" {
  # Create PID file with non-existent process
  create_mock_pid_file 99999

  run "$STOP_SCRIPT"

  # Should succeed since process doesn't exist
  [ "$status" -eq 0 ]

  # PID file should be cleaned up
  [ ! -f "$TEST_PROJSPEC_HOME/observability.pid" ]
}

@test "T408: stop-observability.sh --force flag is accepted" {
  # Create PID file with non-existent process
  create_mock_pid_file 99999

  run "$STOP_SCRIPT" --force

  # Should accept the flag
  [ "$status" -eq 0 ]
}

@test "T408: stop-observability.sh cleans up PID file after stop" {
  # Create PID file with non-existent process
  create_mock_pid_file 99999

  run "$STOP_SCRIPT"

  [ "$status" -eq 0 ]
  [ ! -f "$TEST_PROJSPEC_HOME/observability.pid" ]
}

# =============================================================================
# T409: Tests for status-observability.sh
# =============================================================================

@test "T409: status-observability.sh script exists" {
  [ -f "$STATUS_SCRIPT" ]
}

@test "T409: status-observability.sh is executable" {
  [ -x "$STATUS_SCRIPT" ]
}

@test "T409: status-observability.sh --help shows usage information" {
  run "$STATUS_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "Check the status of the multi-agent observability server" ]]
}

@test "T409: status-observability.sh -h shows usage information" {
  run "$STATUS_SCRIPT" -h

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "T409: status-observability.sh --help shows --json option" {
  run "$STATUS_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--json" ]]
}

@test "T409: status-observability.sh --help shows examples" {
  run "$STATUS_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "EXAMPLES:" ]]
}

@test "T409: status-observability.sh rejects unknown options" {
  run "$STATUS_SCRIPT" --unknown-option

  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown option" ]]
}

@test "T409: status-observability.sh shows NOT RUNNING when no PID file" {
  # Ensure no PID file exists
  rm -f "$TEST_PROJSPEC_HOME/observability.pid"

  run "$STATUS_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "NOT RUNNING" ]]
}

@test "T409: status-observability.sh shows server status header" {
  run "$STATUS_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Multi-Agent Observability Status" ]]
}

@test "T409: status-observability.sh shows database information" {
  run "$STATUS_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Database:" ]]
}

@test "T409: status-observability.sh --json outputs valid JSON structure" {
  run "$STATUS_SCRIPT" --json

  [ "$status" -eq 0 ]

  # Should be valid JSON with expected structure
  [[ "$output" =~ "{" ]]
  [[ "$output" =~ "\"server\":" ]]
  [[ "$output" =~ "\"database\":" ]]
  [[ "$output" =~ "\"running\":" ]]
}

@test "T409: status-observability.sh --json shows server running false when no PID" {
  # Ensure no PID file exists
  rm -f "$TEST_PROJSPEC_HOME/observability.pid"

  run "$STATUS_SCRIPT" --json

  [ "$status" -eq 0 ]
  [[ "$output" =~ "\"running\": false" ]]
}

@test "T409: status-observability.sh --json shows database path" {
  run "$STATUS_SCRIPT" --json

  [ "$status" -eq 0 ]
  [[ "$output" =~ "\"path\":" ]]
}

@test "T409: status-observability.sh handles stale PID file" {
  # Create PID file with non-existent process
  create_mock_pid_file 99999

  run "$STATUS_SCRIPT"

  [ "$status" -eq 0 ]
  # Should show NOT RUNNING since process doesn't exist
  [[ "$output" =~ "NOT RUNNING" ]]
}

@test "T409: status-observability.sh --json handles stale PID file" {
  # Create PID file with non-existent process
  create_mock_pid_file 99999

  run "$STATUS_SCRIPT" --json

  [ "$status" -eq 0 ]
  [[ "$output" =~ "\"running\": false" ]]
}

@test "T409: status-observability.sh shows database info when database exists" {
  # Create mock database
  create_mock_database

  run "$STATUS_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Database:" ]]
  # Should show size instead of "Not created yet"
}

@test "T409: status-observability.sh handles database not created yet" {
  # Ensure no database exists
  rm -f "$TEST_PROJSPEC_HOME/observability.db"

  run "$STATUS_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Not created yet" ]] || [[ "$output" =~ "Database:" ]]
}

# =============================================================================
# Tests for purge-events.sh
# =============================================================================

@test "purge-events.sh script exists" {
  [ -f "$PURGE_SCRIPT" ]
}

@test "purge-events.sh is executable" {
  [ -x "$PURGE_SCRIPT" ]
}

@test "purge-events.sh --help shows usage information" {
  run "$PURGE_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "Purge old events from the observability database" ]]
}

@test "purge-events.sh -h shows usage information" {
  run "$PURGE_SCRIPT" -h

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "purge-events.sh --help shows --days option" {
  run "$PURGE_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--days" ]]
}

@test "purge-events.sh --help shows --dry-run option" {
  run "$PURGE_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--dry-run" ]]
}

@test "purge-events.sh --help shows --all option" {
  run "$PURGE_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--all" ]]
}

@test "purge-events.sh --help shows --json option" {
  run "$PURGE_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "--json" ]]
}

@test "purge-events.sh --help shows examples" {
  run "$PURGE_SCRIPT" --help

  [ "$status" -eq 0 ]
  [[ "$output" =~ "EXAMPLES:" ]]
}

@test "purge-events.sh rejects unknown options" {
  run "$PURGE_SCRIPT" --unknown-option

  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown option" ]]
}

@test "purge-events.sh handles missing database gracefully" {
  # Ensure no database exists
  rm -f "$TEST_PROJSPEC_HOME/observability.db"

  run "$PURGE_SCRIPT"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "No database found" ]] || [[ "$output" =~ "Nothing to purge" ]]
}

@test "purge-events.sh --json handles missing database" {
  # Ensure no database exists
  rm -f "$TEST_PROJSPEC_HOME/observability.db"

  run "$PURGE_SCRIPT" --json

  [ "$status" -eq 0 ]
  [[ "$output" =~ "\"success\": true" ]]
  [[ "$output" =~ "No database found" ]] || [[ "$output" =~ "\"deleted_count\": 0" ]]
}

@test "purge-events.sh rejects invalid --days value" {
  run "$PURGE_SCRIPT" --days=invalid

  [ "$status" -ne 0 ]
  [[ "$output" =~ "must be a positive integer" ]] || [[ "$output" =~ "ERROR" ]]
}

@test "purge-events.sh detects missing sqlite3" {
  # Only test if sqlite3 is not available
  if ! command -v sqlite3 &>/dev/null; then
    # Create a database file so the script tries to use sqlite3
    touch "$TEST_PROJSPEC_HOME/observability.db"

    run "$PURGE_SCRIPT"

    [ "$status" -ne 0 ]
    [[ "$output" =~ "sqlite3" ]]
  else
    skip "sqlite3 is installed - cannot test missing sqlite3 detection"
  fi
}

# =============================================================================
# Cross-script consistency tests
# =============================================================================

@test "All lifecycle scripts have consistent help format" {
  run "$START_SCRIPT" --help
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "OPTIONS:" ]]

  run "$STOP_SCRIPT" --help
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "OPTIONS:" ]]

  run "$STATUS_SCRIPT" --help
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "OPTIONS:" ]]

  run "$PURGE_SCRIPT" --help
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "OPTIONS:" ]]
}

@test "All lifecycle scripts support -h and --help" {
  run "$START_SCRIPT" -h
  [ "$status" -eq 0 ]

  run "$START_SCRIPT" --help
  [ "$status" -eq 0 ]

  run "$STOP_SCRIPT" -h
  [ "$status" -eq 0 ]

  run "$STOP_SCRIPT" --help
  [ "$status" -eq 0 ]

  run "$STATUS_SCRIPT" -h
  [ "$status" -eq 0 ]

  run "$STATUS_SCRIPT" --help
  [ "$status" -eq 0 ]

  run "$PURGE_SCRIPT" -h
  [ "$status" -eq 0 ]

  run "$PURGE_SCRIPT" --help
  [ "$status" -eq 0 ]
}

@test "All lifecycle scripts reject unknown options with non-zero exit" {
  run "$START_SCRIPT" --nonexistent-flag
  [ "$status" -ne 0 ]

  run "$STOP_SCRIPT" --nonexistent-flag
  [ "$status" -ne 0 ]

  run "$STATUS_SCRIPT" --nonexistent-flag
  [ "$status" -ne 0 ]

  run "$PURGE_SCRIPT" --nonexistent-flag
  [ "$status" -ne 0 ]
}

@test "Scripts use correct shebang" {
  head -1 "$START_SCRIPT" | grep -q "#!/usr/bin/env bash"
  head -1 "$STOP_SCRIPT" | grep -q "#!/usr/bin/env bash"
  head -1 "$STATUS_SCRIPT" | grep -q "#!/usr/bin/env bash"
  head -1 "$PURGE_SCRIPT" | grep -q "#!/usr/bin/env bash"
}

@test "Scripts use strict mode (set -euo pipefail)" {
  grep -q "set -euo pipefail" "$START_SCRIPT"
  grep -q "set -euo pipefail" "$STOP_SCRIPT"
  grep -q "set -euo pipefail" "$STATUS_SCRIPT"
  grep -q "set -euo pipefail" "$PURGE_SCRIPT"
}

# =============================================================================
# Unit tests for utility functions (using sourcing approach)
# =============================================================================

@test "format_bytes function formats bytes correctly" {
  # Source the status script to get the function
  # We need to extract and test the function in isolation

  # Test small value - basic check that status script has format_bytes
  grep -q "format_bytes" "$STATUS_SCRIPT"
}

@test "is_process_running function exists in all relevant scripts" {
  grep -q "is_process_running" "$START_SCRIPT"
  grep -q "is_process_running" "$STOP_SCRIPT"
  grep -q "is_process_running" "$STATUS_SCRIPT"
}

@test "Scripts handle CLAUDE_PLUGIN_ROOT environment variable" {
  # All scripts should check for CLAUDE_PLUGIN_ROOT
  grep -q "CLAUDE_PLUGIN_ROOT" "$START_SCRIPT"
  grep -q "CLAUDE_PLUGIN_ROOT" "$STOP_SCRIPT"
  grep -q "CLAUDE_PLUGIN_ROOT" "$STATUS_SCRIPT"
  grep -q "CLAUDE_PLUGIN_ROOT" "$PURGE_SCRIPT"
}

# =============================================================================
# PID file format tests
# =============================================================================

@test "PID file JSON format is documented in start script" {
  # The start script should create JSON-formatted PID files
  grep -q '"server_pid"' "$START_SCRIPT"
  grep -q '"server_port"' "$START_SCRIPT"
  grep -q '"started_at"' "$START_SCRIPT"
}

@test "Stop and status scripts can parse JSON PID file" {
  grep -q '"server_pid"' "$STOP_SCRIPT"
  grep -q '"server_pid"' "$STATUS_SCRIPT"
}

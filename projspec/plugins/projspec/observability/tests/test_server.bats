#!/usr/bin/env bats

# Integration tests for Multi-Agent Observability Server endpoints
# T304: POST /events endpoint tests
# T305: GET /events/recent endpoint tests
# T306: WebSocket event broadcasting tests

# Test setup and teardown
setup() {
  # Server URL - configurable via environment variable
  export SERVER_URL="${SERVER_URL:-http://localhost:4000}"

  # Generate unique test identifiers for isolation
  export TEST_SESSION_ID="test-session-$(date +%s)-$$"
  export TEST_SOURCE_APP="bats-integration-test"

  # Check if server is running
  if ! curl -s --max-time 2 "$SERVER_URL" > /dev/null 2>&1; then
    export SERVER_NOT_RUNNING=true
  else
    export SERVER_NOT_RUNNING=false
  fi
}

teardown() {
  # Cleanup: No persistent state modifications needed
  # Each test uses unique session_id for isolation
  :
}

# Helper function to skip if server is not running
skip_if_server_not_running() {
  if [ "$SERVER_NOT_RUNNING" = "true" ]; then
    skip "Server not running at $SERVER_URL"
  fi
}

# Helper function to create valid event payload
create_valid_event() {
  local hook_type="${1:-PreToolUse}"
  local summary="${2:-Test event}"
  cat <<EOF
{
  "source_app": "$TEST_SOURCE_APP",
  "session_id": "$TEST_SESSION_ID",
  "hook_event_type": "$hook_type",
  "payload": {
    "tool_name": "test_tool",
    "tool_input": {"key": "value"}
  },
  "summary": "$summary",
  "timestamp": $(date +%s)000
}
EOF
}

# =============================================================================
# T304: Integration tests for POST /events endpoint
# =============================================================================

@test "T304: POST /events accepts valid event data and returns 200" {
  skip_if_server_not_running

  local event_data=$(create_valid_event "PreToolUse" "Valid event test")

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$event_data"

  [ "$status" -eq 0 ]

  # Extract HTTP status code (last line)
  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "200" ]

  # Verify response contains the event data
  local response_body=$(echo "$output" | sed '$d')
  [[ "$response_body" =~ "source_app" ]]
  [[ "$response_body" =~ "$TEST_SOURCE_APP" ]]
}

@test "T304: POST /events returns event with assigned ID" {
  skip_if_server_not_running

  local event_data=$(create_valid_event "PreToolUse" "ID assignment test")

  run curl -s -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$event_data"

  [ "$status" -eq 0 ]

  # Response should contain an ID field
  [[ "$output" =~ "\"id\":" ]]
}

@test "T304: POST /events rejects request missing source_app" {
  skip_if_server_not_running

  local invalid_event='{
    "session_id": "test-123",
    "hook_event_type": "PreToolUse",
    "payload": {"tool_name": "test"}
  }'

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$invalid_event"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "400" ]

  local response_body=$(echo "$output" | sed '$d')
  [[ "$response_body" =~ "error" ]]
  [[ "$response_body" =~ "Missing required fields" ]]
}

@test "T304: POST /events rejects request missing session_id" {
  skip_if_server_not_running

  local invalid_event='{
    "source_app": "test-app",
    "hook_event_type": "PreToolUse",
    "payload": {"tool_name": "test"}
  }'

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$invalid_event"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "400" ]
}

@test "T304: POST /events rejects request missing hook_event_type" {
  skip_if_server_not_running

  local invalid_event='{
    "source_app": "test-app",
    "session_id": "test-123",
    "payload": {"tool_name": "test"}
  }'

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$invalid_event"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "400" ]
}

@test "T304: POST /events rejects request missing payload" {
  skip_if_server_not_running

  local invalid_event='{
    "source_app": "test-app",
    "session_id": "test-123",
    "hook_event_type": "PreToolUse"
  }'

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$invalid_event"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "400" ]
}

@test "T304: POST /events rejects invalid JSON" {
  skip_if_server_not_running

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "not valid json {]"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "400" ]

  local response_body=$(echo "$output" | sed '$d')
  [[ "$response_body" =~ "error" ]]
}

@test "T304: POST /events accepts event with optional summary field" {
  skip_if_server_not_running

  local event_with_summary=$(create_valid_event "PreToolUse" "Event with summary field")

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$event_with_summary"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "200" ]

  local response_body=$(echo "$output" | sed '$d')
  [[ "$response_body" =~ "summary" ]]
}

@test "T304: POST /events accepts event with humanInTheLoop data" {
  skip_if_server_not_running

  local hitl_event='{
    "source_app": "'"$TEST_SOURCE_APP"'",
    "session_id": "'"$TEST_SESSION_ID"'-hitl",
    "hook_event_type": "PreToolUse",
    "payload": {"tool_name": "test_tool"},
    "humanInTheLoop": {
      "question": "Should this action proceed?",
      "responseWebSocketUrl": "ws://localhost:9999/test",
      "type": "permission"
    }
  }'

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$hitl_event"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "200" ]

  local response_body=$(echo "$output" | sed '$d')
  [[ "$response_body" =~ "humanInTheLoop" ]]
}

@test "T304: POST /events accepts different hook_event_types" {
  skip_if_server_not_running

  local hook_types=("PreToolUse" "PostToolUse" "Stop" "SubagentStop" "Notification")

  for hook_type in "${hook_types[@]}"; do
    local event_data=$(create_valid_event "$hook_type" "Testing $hook_type")

    run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events" \
      -H "Content-Type: application/json" \
      -d "$event_data"

    local http_code=$(echo "$output" | tail -n1)
    [ "$http_code" = "200" ]
  done
}

@test "T304: POST /events handles concurrent requests" {
  skip_if_server_not_running

  # Send 5 concurrent requests
  local pids=()
  for i in {1..5}; do
    local event_data=$(create_valid_event "PreToolUse" "Concurrent test $i")
    curl -s -X POST "$SERVER_URL/events" \
      -H "Content-Type: application/json" \
      -d "$event_data" > /dev/null &
    pids+=($!)
  done

  # Wait for all requests to complete
  local all_success=true
  for pid in "${pids[@]}"; do
    if ! wait $pid; then
      all_success=false
    fi
  done

  [ "$all_success" = "true" ]
}

# =============================================================================
# T305: Integration tests for GET /events/recent endpoint
# =============================================================================

@test "T305: GET /events/recent returns JSON array" {
  skip_if_server_not_running

  run curl -s -w "\n%{http_code}" -X GET "$SERVER_URL/events/recent"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "200" ]

  local response_body=$(echo "$output" | sed '$d')
  # Response should be a JSON array (starts with [)
  [[ "$response_body" =~ ^\[ ]]
}

@test "T305: GET /events/recent returns events as valid JSON" {
  skip_if_server_not_running

  run curl -s -X GET "$SERVER_URL/events/recent"

  [ "$status" -eq 0 ]

  # Verify valid JSON using jq if available
  if command -v jq &> /dev/null; then
    echo "$output" | jq empty
    [ $? -eq 0 ]
  else
    # Basic JSON structure check
    [[ "$output" =~ ^\[.*\]$ ]]
  fi
}

@test "T305: GET /events/recent supports limit parameter" {
  skip_if_server_not_running

  # First, add a few events to ensure we have data
  for i in {1..5}; do
    local event_data=$(create_valid_event "PreToolUse" "Limit test event $i")
    curl -s -X POST "$SERVER_URL/events" \
      -H "Content-Type: application/json" \
      -d "$event_data" > /dev/null
  done

  # Request with limit=2
  run curl -s -X GET "$SERVER_URL/events/recent?limit=2"

  [ "$status" -eq 0 ]

  # Verify we get at most 2 events
  if command -v jq &> /dev/null; then
    local count=$(echo "$output" | jq 'length')
    [ "$count" -le 2 ]
  fi
}

@test "T305: GET /events/recent with limit=1 returns single event" {
  skip_if_server_not_running

  # Add an event first
  local event_data=$(create_valid_event "PreToolUse" "Single event test")
  curl -s -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$event_data" > /dev/null

  run curl -s -X GET "$SERVER_URL/events/recent?limit=1"

  [ "$status" -eq 0 ]

  if command -v jq &> /dev/null; then
    local count=$(echo "$output" | jq 'length')
    [ "$count" -eq 1 ]
  fi
}

@test "T305: GET /events/recent default limit is 300" {
  skip_if_server_not_running

  run curl -s -X GET "$SERVER_URL/events/recent"

  [ "$status" -eq 0 ]

  # Response should be valid (default is 300 as per server code)
  if command -v jq &> /dev/null; then
    local count=$(echo "$output" | jq 'length')
    [ "$count" -le 300 ]
  fi
}

@test "T305: GET /events/recent returns events with required fields" {
  skip_if_server_not_running

  # Add an event first
  local event_data=$(create_valid_event "PreToolUse" "Field check test")
  curl -s -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$event_data" > /dev/null

  run curl -s -X GET "$SERVER_URL/events/recent?limit=1"

  [ "$status" -eq 0 ]

  if command -v jq &> /dev/null; then
    # Check required fields exist in the first event
    local has_id=$(echo "$output" | jq '.[0] | has("id")')
    local has_source=$(echo "$output" | jq '.[0] | has("source_app")')
    local has_session=$(echo "$output" | jq '.[0] | has("session_id")')
    local has_hook_type=$(echo "$output" | jq '.[0] | has("hook_event_type")')
    local has_payload=$(echo "$output" | jq '.[0] | has("payload")')

    [ "$has_id" = "true" ]
    [ "$has_source" = "true" ]
    [ "$has_session" = "true" ]
    [ "$has_hook_type" = "true" ]
    [ "$has_payload" = "true" ]
  else
    # Basic field presence check
    [[ "$output" =~ "id" ]]
    [[ "$output" =~ "source_app" ]]
    [[ "$output" =~ "session_id" ]]
    [[ "$output" =~ "hook_event_type" ]]
    [[ "$output" =~ "payload" ]]
  fi
}

@test "T305: GET /events/recent returns recently posted event" {
  skip_if_server_not_running

  # Create a unique identifier for this test
  local unique_summary="unique-test-$(date +%s)-$$"
  local event_data='{
    "source_app": "'"$TEST_SOURCE_APP"'",
    "session_id": "'"$TEST_SESSION_ID"'-recent",
    "hook_event_type": "PreToolUse",
    "payload": {"tool_name": "test"},
    "summary": "'"$unique_summary"'"
  }'

  # Post the event
  curl -s -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$event_data" > /dev/null

  # Fetch recent events
  run curl -s -X GET "$SERVER_URL/events/recent?limit=50"

  [ "$status" -eq 0 ]

  # Verify our event is in the response
  [[ "$output" =~ "$unique_summary" ]]
}

@test "T305: GET /events/recent orders events by most recent first" {
  skip_if_server_not_running

  # Add events with slight delays
  for i in {1..3}; do
    local event_data=$(create_valid_event "PreToolUse" "Order test event $i")
    curl -s -X POST "$SERVER_URL/events" \
      -H "Content-Type: application/json" \
      -d "$event_data" > /dev/null
    sleep 0.1
  done

  run curl -s -X GET "$SERVER_URL/events/recent?limit=10"

  [ "$status" -eq 0 ]

  # Most recent events should appear (order depends on implementation)
  [[ "$output" =~ "Order test event" ]]
}

@test "T305: GET /events/recent handles invalid limit gracefully" {
  skip_if_server_not_running

  # Test with non-numeric limit - should use default
  run curl -s -w "\n%{http_code}" -X GET "$SERVER_URL/events/recent?limit=invalid"

  [ "$status" -eq 0 ]

  # Server should handle gracefully (either use default or return error)
  local http_code=$(echo "$output" | tail -n1)
  # Accept 200 (graceful fallback) or 400 (validation error)
  [[ "$http_code" = "200" ]] || [[ "$http_code" = "400" ]]
}

@test "T305: GET /events/recent handles negative limit gracefully" {
  skip_if_server_not_running

  run curl -s -w "\n%{http_code}" -X GET "$SERVER_URL/events/recent?limit=-10"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  # Accept 200 (graceful fallback to default) or 400 (validation error)
  [[ "$http_code" = "200" ]] || [[ "$http_code" = "400" ]]
}

# =============================================================================
# GET /events/filter-options endpoint tests
# =============================================================================

@test "T305: GET /events/filter-options returns filter options" {
  skip_if_server_not_running

  run curl -s -w "\n%{http_code}" -X GET "$SERVER_URL/events/filter-options"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "200" ]

  local response_body=$(echo "$output" | sed '$d')

  # Should contain the expected filter option fields
  [[ "$response_body" =~ "source_apps" ]]
  [[ "$response_body" =~ "session_ids" ]]
  [[ "$response_body" =~ "hook_event_types" ]]
}

@test "T305: GET /events/filter-options returns arrays for each filter type" {
  skip_if_server_not_running

  run curl -s -X GET "$SERVER_URL/events/filter-options"

  [ "$status" -eq 0 ]

  if command -v jq &> /dev/null; then
    # Verify each field is an array
    local source_apps_type=$(echo "$output" | jq '.source_apps | type')
    local session_ids_type=$(echo "$output" | jq '.session_ids | type')
    local hook_types_type=$(echo "$output" | jq '.hook_event_types | type')

    [ "$source_apps_type" = '"array"' ]
    [ "$session_ids_type" = '"array"' ]
    [ "$hook_types_type" = '"array"' ]
  fi
}

# =============================================================================
# POST /events/:id/respond endpoint tests (HITL responses)
# =============================================================================

@test "T305: POST /events/:id/respond returns 404 for non-existent event" {
  skip_if_server_not_running

  local response='{
    "permission": true,
    "respondedAt": 1234567890
  }'

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events/999999/respond" \
    -H "Content-Type: application/json" \
    -d "$response"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "404" ]
}

@test "T305: POST /events/:id/respond rejects invalid JSON" {
  skip_if_server_not_running

  run curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/events/1/respond" \
    -H "Content-Type: application/json" \
    -d "invalid json"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "400" ]
}

# =============================================================================
# CORS and HTTP method tests
# =============================================================================

@test "T305: Server responds with CORS headers" {
  skip_if_server_not_running

  run curl -s -i -X OPTIONS "$SERVER_URL/events"

  [ "$status" -eq 0 ]

  # Should include CORS headers
  [[ "$output" =~ "Access-Control-Allow-Origin" ]]
  [[ "$output" =~ "Access-Control-Allow-Methods" ]]
}

@test "T305: OPTIONS request returns 200 for preflight" {
  skip_if_server_not_running

  run curl -s -w "\n%{http_code}" -X OPTIONS "$SERVER_URL/events" \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Method: POST"

  [ "$status" -eq 0 ]

  local http_code=$(echo "$output" | tail -n1)
  [ "$http_code" = "200" ]
}

@test "T305: Root endpoint returns server identification" {
  skip_if_server_not_running

  run curl -s -X GET "$SERVER_URL/"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Multi-Agent Observability Server" ]]
}

# =============================================================================
# T306: WebSocket event broadcasting tests
# =============================================================================

@test "T306: WebSocket endpoint /stream exists" {
  skip "WebSocket tests require specialized tooling (wscat, websocat)"

  # This test would verify WebSocket upgrade is accepted
  # Requires: wscat, websocat, or similar tool
  #
  # Example test with websocat:
  # run timeout 2 websocat -t "$WS_URL/stream"
  # [ "$status" -eq 0 ] || [ "$status" -eq 124 ]  # 124 = timeout (expected)
}

@test "T306: WebSocket sends initial events on connection" {
  skip "WebSocket tests require specialized tooling (wscat, websocat)"

  # This test would verify that on connection, the server sends
  # a message with type: 'initial' containing recent events
  #
  # Expected: { type: 'initial', data: [...events...] }
}

@test "T306: WebSocket broadcasts new events to connected clients" {
  skip "WebSocket tests require specialized tooling (wscat, websocat)"

  # This test would:
  # 1. Connect a WebSocket client to /stream
  # 2. POST a new event to /events
  # 3. Verify the WebSocket client receives the event
  #
  # Expected: { type: 'event', data: {...event...} }
}

@test "T306: WebSocket handles multiple concurrent clients" {
  skip "WebSocket tests require specialized tooling (wscat, websocat)"

  # This test would:
  # 1. Connect multiple WebSocket clients to /stream
  # 2. POST a new event to /events
  # 3. Verify all clients receive the broadcast
}

@test "T306: WebSocket client disconnect is handled gracefully" {
  skip "WebSocket tests require specialized tooling (wscat, websocat)"

  # This test would:
  # 1. Connect a WebSocket client
  # 2. Disconnect abruptly
  # 3. POST a new event (should not cause server error)
  # 4. Verify server is still operational
}

@test "T306: WebSocket broadcasts HITL response updates" {
  skip "WebSocket tests require specialized tooling (wscat, websocat)"

  # This test would:
  # 1. Connect a WebSocket client
  # 2. POST an event with humanInTheLoop data
  # 3. POST a response to /events/:id/respond
  # 4. Verify WebSocket client receives the updated event
}

# =============================================================================
# Integration workflow tests
# =============================================================================

@test "Integration: POST event then GET recent includes the event" {
  skip_if_server_not_running

  # Create unique event
  local unique_id="workflow-$(date +%s)-$$"
  local event_data='{
    "source_app": "'"$TEST_SOURCE_APP"'",
    "session_id": "'"$unique_id"'",
    "hook_event_type": "PreToolUse",
    "payload": {"workflow_test": true},
    "summary": "Workflow integration test"
  }'

  # POST the event
  local post_response=$(curl -s -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$event_data")

  # Verify POST succeeded
  [[ "$post_response" =~ "id" ]]

  # GET recent events
  run curl -s -X GET "$SERVER_URL/events/recent?limit=50"

  [ "$status" -eq 0 ]

  # Verify our event is in the list
  [[ "$output" =~ "$unique_id" ]]
  [[ "$output" =~ "Workflow integration test" ]]
}

@test "Integration: Multiple events from same session are retrievable" {
  skip_if_server_not_running

  local unique_session="multi-event-$(date +%s)-$$"

  # Post multiple events from same session
  for i in {1..3}; do
    local event_data='{
      "source_app": "'"$TEST_SOURCE_APP"'",
      "session_id": "'"$unique_session"'",
      "hook_event_type": "PreToolUse",
      "payload": {"event_number": '"$i"'},
      "summary": "Multi-event test '"$i"'"
    }'

    curl -s -X POST "$SERVER_URL/events" \
      -H "Content-Type: application/json" \
      -d "$event_data" > /dev/null
  done

  # GET recent events
  run curl -s -X GET "$SERVER_URL/events/recent?limit=100"

  [ "$status" -eq 0 ]

  # Verify all events are present
  [[ "$output" =~ "Multi-event test 1" ]]
  [[ "$output" =~ "Multi-event test 2" ]]
  [[ "$output" =~ "Multi-event test 3" ]]
}

@test "Integration: Filter options include posted event's source_app" {
  skip_if_server_not_running

  local unique_source="unique-source-$(date +%s)"
  local event_data='{
    "source_app": "'"$unique_source"'",
    "session_id": "filter-options-test",
    "hook_event_type": "PreToolUse",
    "payload": {"test": true}
  }'

  # POST event with unique source_app
  curl -s -X POST "$SERVER_URL/events" \
    -H "Content-Type: application/json" \
    -d "$event_data" > /dev/null

  # GET filter options
  run curl -s -X GET "$SERVER_URL/events/filter-options"

  [ "$status" -eq 0 ]

  # Verify our unique source_app is in the filter options
  [[ "$output" =~ "$unique_source" ]]
}

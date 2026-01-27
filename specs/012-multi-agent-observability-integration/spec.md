# Feature Specification: Multi-Agent Observability Integration

## Metadata

| Field | Value |
|-------|-------|
| Branch | `012-multi-agent-observability-integration` |
| Date | 2026-01-27 |
| Status | Draft |
| Input | Integrate multi-agent observability capabilities from disler/claude-code-hooks-multi-agent-observability into the projspec plugin for real-time monitoring and visualization of Claude Code agent behavior |

---

## User Scenarios & Testing

### Primary Scenarios

#### US-001: Enable Observability for Projspec Sessions

**As a** projspec plugin user
**I want to** enable real-time observability for my projspec workflow sessions
**So that** I can monitor agent behavior, track tool usage, and visualize session activity across multiple concurrent agents

**Acceptance Criteria:**
- [ ] User can enable observability integration through projspec plugin configuration
- [ ] Hook events (PreToolUse, PostToolUse, Stop, SubagentStop, etc.) are captured and sent to the observability server
- [ ] Events include projspec-specific context (feature ID, workflow stage, current command)
- [ ] Observability server receives and stores events without blocking Claude Code operations

**Priority:** High

#### US-002: View Real-Time Agent Activity Dashboard

**As a** projspec plugin user
**I want to** view a real-time dashboard showing agent activity across my projspec workflows
**So that** I can understand what agents are doing, identify bottlenecks, and monitor progress

**Acceptance Criteria:**
- [ ] Dashboard displays events in real-time via WebSocket connection
- [ ] Events are filterable by source app, session, and event type
- [ ] Each event shows timestamp, event type, tool name, and summary
- [ ] Chat transcripts are viewable for completed sessions

**Priority:** High

#### US-003: Start and Stop Observability System

**As a** projspec plugin user
**I want to** easily start and stop the observability server and client
**So that** I can enable observability only when needed without manual setup complexity

**Acceptance Criteria:**
- [ ] A single command starts both the observability server and web client
- [ ] A single command stops all observability processes cleanly
- [ ] System health status is reportable on demand
- [ ] Server port conflicts are detected and reported

**Priority:** Medium

### Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| Observability server not running | Hook scripts exit gracefully without blocking Claude Code operations; events are lost but logged locally |
| Multiple concurrent projspec sessions | Each session is tracked with unique session ID; dashboard displays all sessions with distinct visual markers |
| Network timeout during event send | Event send times out after 5 seconds; operation continues without blocking |
| Large chat transcript (>1MB) | Oldest messages are truncated to keep transcript under 1MB limit while preserving most recent context |
| Server restart during active session | Client reconnects automatically; new events continue streaming; historical events remain in database |
| Default port already in use | Server/client auto-increment to next available port (e.g., 4001, 4002) and report selected port to user |

---

## Requirements

### Functional Requirements

#### FR-001: Hook Integration for Event Capture

The projspec plugin must integrate Claude Code hooks to capture lifecycle events. The following hook types must be supported:
- PreToolUse: Before any tool execution
- PostToolUse: After tool completion
- Notification: User interaction points
- Stop: Response/session completion
- SubagentStop: Subagent task completion
- PreCompact: Context compaction events
- UserPromptSubmit: User prompt logging
- SessionStart: Session initialization
- SessionEnd: Session termination

Each hook must send event data to the observability server endpoint without blocking Claude Code operations.

**Verification:** Configure hooks in settings.json; execute Claude Code commands; verify all event types appear in server logs and client dashboard

#### FR-002: Event Data Structure

Each event sent to the observability server must include:
- source_app: Identifier for the projspec plugin instance
- session_id: Unique session identifier from Claude Code
- hook_event_type: The type of hook event
- payload: Full hook input data (tool name, inputs, outputs as applicable)
- timestamp: Event timestamp in milliseconds
- model_name: The Claude model being used (extracted from transcript)

Optional fields:
- summary: AI-generated summary of the event (when --summarize flag is used)
- chat: Full chat transcript (when --add-chat flag is used)

**Verification:** Send test event via curl; verify all required fields are present in database record

#### FR-003: Observability Server Endpoint

The observability server must expose the following endpoints:
- POST /events: Receive and store hook events
- GET /events/recent: Retrieve paginated events with filtering
- GET /events/filter-options: Return available filter values
- WebSocket /stream: Real-time event broadcasting to clients

The server must store events persistently and broadcast new events to all connected WebSocket clients.

**Verification:** Send POST request to /events; verify GET /events/recent returns the event; verify WebSocket clients receive broadcast

#### FR-004: Plugin Configuration for Observability

The projspec plugin must provide configuration options for observability:
- Enable/disable observability hooks (default: disabled)
- Configure server URL (default: http://localhost:4000)
- Configure client URL (default: http://localhost:3000)
- Set source app name for event identification
- Toggle AI summarization for events
- Toggle chat transcript inclusion
- Set maximum chat transcript size (default: 1MB)
- Set event retention period (default: 7 days)

Observability is disabled by default. Users must explicitly enable it via `observability.enabled: true` in the plugin's local configuration file.

Configuration must be stored in the plugin's local configuration file.

**Verification:** Modify configuration values; restart Claude Code; verify hooks behave according to configuration

#### FR-005: Lifecycle Scripts for System Management

The projspec plugin must include scripts to manage the observability system:
- start-observability: Start both server and client processes
- stop-observability: Stop all observability processes
- status-observability: Report system health and running processes
- purge-events: Manually delete events older than specified age

Scripts must handle process management gracefully and report clear status messages. When starting, if default ports (4000 for server, 3000 for client) are occupied, scripts must auto-increment to the next available port and report the selected ports to the user.

Observability components (hooks, server, client) are vendored within the projspec plugin directory for simpler distribution and installation.

**Verification:** Run start script; verify server and client are running; run stop script; verify processes are terminated

### Constraints

| Constraint | Description |
|------------|-------------|
| Non-blocking hooks | All hook scripts must exit within 5 seconds and never block Claude Code operations |
| Local-only by default | Observability server runs on localhost only; no external network exposure without explicit configuration |
| Dependency on external tools | Requires Bun runtime for server, uv for Python hooks; must document prerequisites |
| Disabled by default | Observability hooks are disabled until explicitly enabled by user configuration |
| Event retention | Events are automatically deleted after 7 days; manual purge available for immediate cleanup |
| Transcript size limit | Chat transcripts exceeding 1MB are truncated (oldest messages removed) to preserve recent context |
| Port auto-increment | Server and client auto-select available ports starting from defaults (4000, 3000) if occupied |

---

## Key Entities

### HookEvent

**Description:** A single lifecycle event captured from Claude Code during projspec operations

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| id | Unique event identifier | Auto-generated, unique |
| source_app | Application identifier | Required, string |
| session_id | Claude Code session ID | Required, string |
| hook_event_type | Type of hook event | One of: PreToolUse, PostToolUse, Notification, Stop, SubagentStop, PreCompact, UserPromptSubmit, SessionStart, SessionEnd |
| payload | Event-specific data | JSON object |
| timestamp | Event timestamp | Unix milliseconds |
| model_name | Claude model identifier | Optional string |
| summary | AI-generated event summary | Optional string |
| chat | Full chat transcript | Optional JSON array |

### Session

**Description:** A Claude Code session containing multiple events

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| session_id | Unique session identifier | From Claude Code |
| source_app | Application that generated events | String |
| start_time | Session start timestamp | Unix milliseconds |
| end_time | Session end timestamp | Optional, Unix milliseconds |
| event_count | Number of events in session | Integer >= 0 |

### Entity Relationships

- Session contains multiple HookEvents (one-to-many)
- HookEvent belongs to exactly one Session
- Multiple Sessions can have the same source_app

---

## Success Criteria

### SC-001: Event Capture Reliability

**Measure:** Percentage of hook events successfully captured and stored
**Target:** >= 99% of events captured when observability server is running
**Verification Method:** Run automated test suite with 1000 tool operations; count events in database vs expected

### SC-002: Hook Latency Impact

**Measure:** Additional latency introduced by observability hooks
**Target:** < 100ms average added latency per hook event
**Verification Method:** Measure tool execution time with and without observability hooks enabled; compare averages

### SC-003: Real-time Dashboard Updates

**Measure:** Time from event generation to dashboard display
**Target:** < 500ms from hook execution to client display
**Verification Method:** Trigger test event; measure time until event appears in connected dashboard

---

## Assumptions

| ID | Assumption | Impact if Wrong | Validated |
|----|------------|-----------------|-----------|
| A-001 | Users have Bun and uv installed or can install them | Cannot run observability server or hooks; need to bundle dependencies or provide alternative | No |
| A-002 | Port 4000 is available on user's machine | Server fails to start; need configurable port option | No |
| A-003 | Users primarily work with single-machine setups | Remote/distributed observability not supported initially | No |
| A-004 | The disler/claude-code-hooks-multi-agent-observability codebase is stable and can be vendored | May need to track upstream changes or fork | No |

---

## Open Questions

### Q-001: Dependency Bundling Strategy

- **Question**: Should the observability server/client be bundled with projspec, or should users clone/install it separately?
- **Why Needed**: Affects distribution size, update mechanism, and installation complexity
- **Resolution**: Vendor the required components (hooks, server, client) within the projspec plugin directory
- **Status**: Resolved
- **Impacts**: FR-005, A-001

### Q-002: Event Retention Policy

- **Question**: How long should events be retained in the database, and should users be able to configure this?
- **Why Needed**: Affects storage growth and database performance over time
- **Resolution**: Retain last 7 days of events with automatic cleanup; provide manual purge command
- **Status**: Resolved
- **Impacts**: FR-003, FR-004

### Q-003: Authentication for Multi-User Scenarios

- **Question**: Should the observability system support authentication for team/shared environments?
- **Why Needed**: Current implementation assumes single-user local access; team use may require access control
- **Suggested Default**: No authentication for initial release (localhost only); document as future enhancement
- **Status**: Open (deferred to future release)
- **Impacts**: Constraints

### Q-004: Default Port Conflict Handling

- **Question**: What should happen when default ports (4000 for server, 3000 for client) are already in use?
- **Why Needed**: Ensures smooth startup experience without manual port configuration
- **Resolution**: Auto-increment to next available port and report selected port to user
- **Status**: Resolved
- **Impacts**: FR-005, A-002

### Q-005: Default Observability State

- **Question**: Should observability be enabled or disabled by default when the plugin is first installed?
- **Why Needed**: Affects first-run experience and whether users need to opt-in or opt-out
- **Resolution**: Disabled by default; users explicitly enable via configuration
- **Status**: Resolved
- **Impacts**: FR-004, US-001

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-01-27 | Claude (projspec) | Initial draft from feature description |
| 0.2 | 2026-01-27 | Claude (projspec/clarify) | Resolved 5 clarification questions: dependency bundling (vendor in plugin), event retention (7 days), port handling (auto-increment), default state (disabled), transcript size (truncate oldest at 1MB); updated FR-004, FR-005, Constraints, and Edge Cases |

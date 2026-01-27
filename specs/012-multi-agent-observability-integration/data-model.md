# Data Model: Multi-Agent Observability Integration

**Feature**: Multi-Agent Observability Integration
**Date**: 2026-01-27

## Overview

This data model defines the entities, relationships, and storage formats for the multi-agent observability system integrated into the projspec plugin. The model captures Claude Code lifecycle events, organizes them by session, and supports real-time querying and visualization.

---

## Core Entities

### 1. HookEvent

**Description**: A single lifecycle event captured from Claude Code during projspec operations. Each event represents a discrete action or state change in the agent's execution.

**Identifier Pattern**: Auto-generated integer ID (SQLite ROWID)

**Storage Location**: `~/.projspec/observability.db` (SQLite table: `events`)

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Auto-generated unique identifier |
| source_app | string | Yes | Application identifier (e.g., "projspec") |
| session_id | string | Yes | Claude Code session identifier |
| hook_event_type | enum | Yes | Type of hook event triggered |
| payload | json | Yes | Event-specific data from Claude Code |
| timestamp | integer | Yes | Unix timestamp in milliseconds |
| model_name | string | No | Claude model identifier (e.g., "claude-sonnet-4-20250514") |
| summary | string | No | AI-generated event summary (when --summarize enabled) |
| chat | json | No | Full chat transcript array (when --add-chat enabled) |
| human_in_the_loop | json | No | HITL query structure if awaiting user input |
| human_in_the_loop_status | enum | No | Status of HITL request |

**Enum Values - hook_event_type**:
| Value | Description |
|-------|-------------|
| PreToolUse | Before any tool execution |
| PostToolUse | After tool completion |
| Notification | User interaction points |
| Stop | Response/session completion |
| SubagentStop | Subagent task completion |
| PreCompact | Context compaction events |
| UserPromptSubmit | User prompt logging |
| SessionStart | Session initialization |
| SessionEnd | Session termination |

**Enum Values - human_in_the_loop_status**:
| Value | Description |
|-------|-------------|
| pending | Awaiting user response |
| responded | User has responded |
| timeout | Request timed out |
| error | Error processing response |

**Validation Rules**:
- `source_app` must be non-empty string (max 100 characters)
- `session_id` must be non-empty string (max 256 characters)
- `hook_event_type` must be one of the defined enum values
- `timestamp` must be positive integer
- `chat` array size must not exceed 1MB when serialized; truncate oldest messages if exceeded

---

### 2. Session

**Description**: A logical grouping of HookEvents representing a single Claude Code session. Sessions are derived from HookEvents by aggregating on `session_id`.

**Identifier Pattern**: `session_id` from Claude Code

**Storage Location**: Virtual entity (computed from events table via GROUP BY)

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| session_id | string | Yes | Unique session identifier from Claude Code |
| source_app | string | Yes | Application that generated events |
| start_time | integer | Yes | Timestamp of first event (Unix ms) |
| end_time | integer | No | Timestamp of last event (Unix ms) |
| event_count | integer | Yes | Number of events in session |
| model_name | string | No | Claude model used (from first event with model) |
| has_transcript | boolean | Yes | Whether any event includes chat transcript |

**Validation Rules**:
- `session_id` must match pattern from Claude Code (typically UUID-like)
- `start_time` <= `end_time` when both present
- `event_count` must equal actual count of events with matching session_id

**Derived Calculation**:
```sql
SELECT
  session_id,
  source_app,
  MIN(timestamp) as start_time,
  MAX(timestamp) as end_time,
  COUNT(*) as event_count,
  MAX(model_name) as model_name,
  MAX(CASE WHEN chat IS NOT NULL THEN 1 ELSE 0 END) as has_transcript
FROM events
GROUP BY session_id, source_app
```

---

### 3. ObservabilityConfig

**Description**: Plugin configuration for observability features, stored in the plugin's local configuration file.

**Identifier Pattern**: Singleton per project

**Storage Location**: `.projspec/projspec.local.md` (YAML frontmatter)

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| enabled | boolean | Yes | Master toggle for observability (default: false) |
| server_url | string | Yes | Observability server URL (default: http://localhost:4000) |
| client_url | string | Yes | Web client URL (default: http://localhost:3000) |
| source_app | string | Yes | Event source identifier (default: "projspec") |
| summarize_events | boolean | Yes | Enable AI event summarization (default: false) |
| include_chat | boolean | Yes | Include chat transcripts (default: false) |
| max_chat_size | integer | Yes | Maximum chat size in bytes (default: 1048576) |
| retention_days | integer | Yes | Days to retain events (default: 7) |

**Validation Rules**:
- `server_url` must be valid HTTP/HTTPS URL
- `client_url` must be valid HTTP/HTTPS URL
- `source_app` must be non-empty string (max 50 characters)
- `max_chat_size` must be between 1024 and 10485760 (1KB to 10MB)
- `retention_days` must be between 1 and 365

**Default Configuration**:
```yaml
---
observability:
  enabled: false
  server_url: http://localhost:4000
  client_url: http://localhost:3000
  source_app: projspec
  summarize_events: false
  include_chat: false
  max_chat_size: 1048576
  retention_days: 7
---
```

---

### 4. ProcessState

**Description**: Runtime state tracking for observability server and client processes.

**Identifier Pattern**: Process type (server/client)

**Storage Location**: `~/.projspec/observability.pid` (JSON file)

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| server_pid | integer | No | Process ID of running server |
| server_port | integer | No | Actual port server is listening on |
| client_pid | integer | No | Process ID of running client |
| client_port | integer | No | Actual port client is listening on |
| started_at | integer | No | Timestamp when processes were started |
| database_path | string | No | Path to SQLite database file |

**Validation Rules**:
- PIDs must be positive integers
- Ports must be between 1024 and 65535
- `started_at` must be valid Unix timestamp

**File Format**:
```json
{
  "server_pid": 12345,
  "server_port": 4000,
  "client_pid": 12346,
  "client_port": 3000,
  "started_at": 1706367600000,
  "database_path": "/Users/user/.projspec/observability.db"
}
```

---

## Relationships

```
┌─────────────────────┐          ┌─────────────────────┐
│  ObservabilityConfig│          │    ProcessState     │
│  (projspec.local.md)│          │  (observability.pid)│
└─────────────────────┘          └─────────────────────┘
         │                                 │
         │ configures                      │ tracks
         ▼                                 ▼
┌─────────────────────────────────────────────────────┐
│                   Observability System              │
│  ┌──────────────────┐    ┌────────────────────┐    │
│  │   Hook Scripts   │───▶│    Bun Server      │    │
│  │   (Python/uv)    │    │    (:server_port)  │    │
│  └──────────────────┘    └─────────┬──────────┘    │
│                                    │               │
│                                    ▼               │
│                          ┌─────────────────┐       │
│                          │    SQLite DB    │       │
│                          │ (observability.db)      │
│                          └─────────┬───────┘       │
│                                    │               │
│                                    ▼               │
│                          ┌─────────────────┐       │
│                          │   Vue Client    │       │
│                          │  (:client_port) │       │
│                          └─────────────────┘       │
└─────────────────────────────────────────────────────┘

Entity Relationships:
─────────────────────

Session (1) ◀────────────────▶ (n) HookEvent
           "contains"

- A Session contains multiple HookEvents
- A HookEvent belongs to exactly one Session
- Sessions are derived by grouping events on session_id
- Multiple Sessions can share the same source_app
```

### Relationship Details

| Relationship | Cardinality | Description |
|--------------|-------------|-------------|
| Session → HookEvent | 1:n | One session contains many events |
| HookEvent → Session | n:1 | Each event belongs to one session |
| ObservabilityConfig → System | 1:1 | Config controls system behavior |
| ProcessState → System | 1:1 | Tracks running process state |

---

## File Format Specifications

### SQLite Database Schema

**File Extension**: `.db`
**Location**: `~/.projspec/observability.db`

**Schema Definition**:
```sql
-- Events table (primary storage)
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_app TEXT NOT NULL,
  session_id TEXT NOT NULL,
  hook_event_type TEXT NOT NULL,
  payload TEXT NOT NULL,  -- JSON string
  timestamp INTEGER NOT NULL,
  model_name TEXT,
  summary TEXT,
  chat TEXT,  -- JSON string (nullable)
  human_in_the_loop TEXT,  -- JSON string (nullable)
  human_in_the_loop_status TEXT
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_events_source_app ON events(source_app);
CREATE INDEX IF NOT EXISTS idx_events_session_id ON events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_hook_event_type ON events(hook_event_type);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);

-- Compound index for filtered queries
CREATE INDEX IF NOT EXISTS idx_events_filter
  ON events(source_app, session_id, hook_event_type, timestamp);
```

### Configuration File Format

**File Extension**: `.local.md`
**Location**: `.projspec/projspec.local.md`

**Structure**:
```markdown
---
observability:
  enabled: false
  server_url: http://localhost:4000
  client_url: http://localhost:3000
  source_app: projspec
  summarize_events: false
  include_chat: false
  max_chat_size: 1048576
  retention_days: 7
---

# Projspec Local Configuration

This file contains project-specific projspec settings.
It is gitignored to prevent committing sensitive or environment-specific values.

## Observability

Enable the observability system to monitor Claude Code agent behavior:

```yaml
observability:
  enabled: true
```

View the dashboard at the configured client_url when enabled.
```

### Process State File Format

**File Extension**: `.pid`
**Location**: `~/.projspec/observability.pid`

**Structure**:
```json
{
  "server_pid": 12345,
  "server_port": 4000,
  "client_pid": 12346,
  "client_port": 3000,
  "started_at": 1706367600000,
  "database_path": "/Users/user/.projspec/observability.db"
}
```

### Event Payload Formats

**PreToolUse Payload**:
```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git status",
    "description": "Check git status"
  },
  "session_id": "abc-123-def"
}
```

**PostToolUse Payload**:
```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git status"
  },
  "tool_output": "On branch main\nnothing to commit",
  "session_id": "abc-123-def"
}
```

**SessionStart Payload**:
```json
{
  "session_id": "abc-123-def",
  "model_name": "claude-sonnet-4-20250514",
  "working_directory": "/path/to/project"
}
```

**SessionEnd Payload**:
```json
{
  "session_id": "abc-123-def",
  "chat": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ]
}
```

---

## Validation Rules Summary

| Entity | Rule | Error Action |
|--------|------|--------------|
| HookEvent | source_app max 100 chars | Truncate |
| HookEvent | session_id max 256 chars | Truncate |
| HookEvent | hook_event_type must be valid enum | Reject event |
| HookEvent | timestamp must be positive | Use current time |
| HookEvent | chat size <= max_chat_size | Truncate oldest messages |
| Session | event_count matches actual | Recalculate |
| ObservabilityConfig | URLs must be valid HTTP(S) | Use defaults |
| ObservabilityConfig | retention_days 1-365 | Clamp to range |
| ProcessState | PIDs must be positive | Clear stale entry |
| ProcessState | Ports 1024-65535 | Use defaults |

---

## State Transitions

### HookEvent Lifecycle

Events are immutable once created. The only state change is deletion during retention cleanup.

```
Created → Stored → (7 days pass) → Deleted
```

### Human-in-the-Loop Status Transitions

```
                    ┌─────────────┐
                    │   pending   │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    ┌──────────┐     ┌──────────┐     ┌──────────┐
    │ responded│     │ timeout  │     │  error   │
    └──────────┘     └──────────┘     └──────────┘
```

**Transition Rules**:
- `pending` → `responded`: User provides response within timeout
- `pending` → `timeout`: No response within 5 seconds
- `pending` → `error`: Error processing response or connection failure

### ProcessState Lifecycle

```
     ┌───────────┐
     │  stopped  │  (no .pid file)
     └─────┬─────┘
           │ start-observability
           ▼
     ┌───────────┐
     │  running  │  (.pid file exists, processes alive)
     └─────┬─────┘
           │ stop-observability
           ▼
     ┌───────────┐
     │  stopped  │  (.pid file deleted)
     └───────────┘

           │ crash/orphan
           ▼
     ┌───────────┐
     │   stale   │  (.pid file exists, processes dead)
     └─────┬─────┘
           │ start-observability (cleanup)
           ▼
     ┌───────────┐
     │  running  │
     └───────────┘
```

**Transition Rules**:
- `stopped` → `running`: start-observability creates .pid file with valid PIDs
- `running` → `stopped`: stop-observability terminates processes and removes .pid
- `running` → `stale`: Processes terminate unexpectedly (crash, system restart)
- `stale` → `running`: start-observability detects dead PIDs, cleans up, starts fresh

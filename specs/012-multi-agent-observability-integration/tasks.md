# Tasks: Multi-Agent Observability Integration

**Generated**: 2026-01-27
**Feature**: specs/012-multi-agent-observability-integration
**Source**: plan.md, spec.md, data-model.md, research.md

## Overview

- **Total Tasks**: 47
- **Phases**: 6
- **Estimated Complexity**: Medium
- **Parallel Execution Groups**: 8

## Task Legend

- `[ ]` - Incomplete task
- `[x]` - Completed task
- `[P]` - Can execute in parallel with other [P] tasks in same group
- `[US#]` - Linked to User Story # (e.g., [US1] = User Story 1)
- `CHECKPOINT` - Review point before proceeding to next phase

---

## Phase 1: Setup

Project structure and initial configuration for the observability integration.

### Directory Structure

- [X] T001 [P] Create observability directory structure (projspec/plugins/projspec/observability/)
- [X] T002 [P] Create observability/server directory (projspec/plugins/projspec/observability/server/)
- [X] T003 [P] Create observability/client directory (projspec/plugins/projspec/observability/client/)
- [X] T004 [P] Create observability/hooks directory (projspec/plugins/projspec/observability/hooks/)
- [X] T005 [P] Create observability/tests directory (projspec/plugins/projspec/observability/tests/)

### Documentation

- [X] T006 Create observability README with attribution (projspec/plugins/projspec/observability/README.md)

---

## Phase 2: Foundational - Vendor Components

Vendor the observability server, client, and hook scripts from the upstream repository.

### Server Vendoring

- [X] T100 Vendor Bun server source files from upstream (observability/server/src/)
- [X] T101 Create server package.json with dependencies (observability/server/package.json)
- [X] T102 Vendor database schema module (observability/server/src/db.ts)
- [X] T103 Vendor server entry point with endpoints (observability/server/src/index.ts)
- [X] T104 Install server dependencies and generate lockfile (observability/server/bun.lockb)

### Client Vendoring

- [X] T105 [P] Build and vendor Vue client static files (observability/client/dist/)
- [X] T106 [P] Vendor client index.html (observability/client/dist/index.html)
- [X] T107 [P] Vendor client JavaScript assets (observability/client/dist/assets/)

### Hook Scripts Vendoring

- [X] T108 Vendor core event dispatcher script (observability/hooks/send_event.py)
- [X] T109 [P] Vendor pre_tool_use.py hook script (observability/hooks/pre_tool_use.py)
- [X] T110 [P] Vendor post_tool_use.py hook script (observability/hooks/post_tool_use.py)
- [X] T111 [P] Vendor notification.py hook script (observability/hooks/notification.py)
- [X] T112 [P] Vendor stop.py hook script (observability/hooks/stop.py)
- [X] T113 [P] Vendor subagent_stop.py hook script (observability/hooks/subagent_stop.py)
- [X] T114 [P] Vendor pre_compact.py hook script (observability/hooks/pre_compact.py)
- [X] T115 [P] Vendor user_prompt_submit.py hook script (observability/hooks/user_prompt_submit.py)
- [X] T116 [P] Vendor session_start.py hook script (observability/hooks/session_start.py)
- [X] T117 [P] Vendor session_end.py hook script (observability/hooks/session_end.py)

### Checkpoint

- [X] T118 CHECKPOINT: Verify all vendored components are present and server starts successfully

---

## Phase 3: User Story 1 - Enable Observability for Projspec Sessions (US-001)

**Story**: As a projspec plugin user, I want to enable real-time observability for my projspec workflow sessions so that I can monitor agent behavior, track tool usage, and visualize session activity.

**Priority**: High (P1)

### Hook Configuration

- [X] T200 [US1] Update hooks.json with PreToolUse hook definition (hooks/hooks.json)
- [X] T201 [US1] Add PostToolUse hook definition to hooks.json (hooks/hooks.json)
- [X] T202 [US1] Add Notification hook definition to hooks.json (hooks/hooks.json)
- [X] T203 [US1] Add Stop hook definition to hooks.json (hooks/hooks.json)
- [X] T204 [US1] Add SubagentStop hook definition to hooks.json (hooks/hooks.json)
- [X] T205 [US1] Add PreCompact hook definition to hooks.json (hooks/hooks.json)
- [X] T206 [US1] Add UserPromptSubmit hook definition to hooks.json (hooks/hooks.json)
- [X] T207 [US1] Add SessionStart hook definition to hooks.json (hooks/hooks.json)
- [X] T208 [US1] Add SessionEnd hook definition to hooks.json (hooks/hooks.json)

### Hook Script Modifications

- [X] T209 [US1] Modify send_event.py to read projspec configuration (observability/hooks/send_event.py)
- [X] T210 [US1] Add conditional execution based on observability.enabled flag (observability/hooks/send_event.py)
- [X] T211 [US1] Add projspec-specific context to event payloads (observability/hooks/send_event.py)
- [X] T212 [US1] Implement chat transcript truncation at 1MB limit (observability/hooks/send_event.py)

### Configuration

- [X] T213 [US1] Document .local.md configuration pattern for observability (observability/README.md)
- [X] T214 [US1] Create example projspec.local.md configuration template (observability/config-example.md)

### Test Tasks

- [X] T215 [P] [US1] Write unit tests for send_event.py payload construction (observability/tests/test_hooks.py)
- [X] T216 [P] [US1] Write unit tests for configuration reading (observability/tests/test_hooks.py)
- [X] T217 [US1] Verify: User can enable observability through configuration
- [X] T218 [US1] Verify: Hook events are captured and sent to server
- [X] T219 [US1] Verify: Events include projspec-specific context
- [X] T220 [US1] Verify: Server receives events without blocking Claude Code

### Checkpoint

- [X] T221 [US1] CHECKPOINT: Verify US-001 Enable Observability is complete and functional

---

## Phase 4: User Story 2 - View Real-Time Agent Activity Dashboard (US-002)

**Story**: As a projspec plugin user, I want to view a real-time dashboard showing agent activity across my projspec workflows so that I can understand what agents are doing and monitor progress.

**Priority**: High (P1)

### Server Endpoints

- [X] T300 [US2] Verify POST /events endpoint stores events correctly (observability/server/src/index.ts)
- [X] T301 [US2] Verify GET /events/recent returns paginated events with filtering (observability/server/src/index.ts)
- [X] T302 [US2] Verify WebSocket /stream broadcasts events to clients (observability/server/src/index.ts)
- [X] T303 [US2] Implement 7-day event retention cleanup on server startup (observability/server/src/db.ts)

### Integration Tests

- [X] T304 [P] [US2] Write integration tests for POST /events endpoint (observability/tests/test_server.bats)
- [X] T305 [P] [US2] Write integration tests for GET /events/recent endpoint (observability/tests/test_server.bats)
- [X] T306 [US2] Write integration tests for WebSocket event broadcasting (observability/tests/test_server.bats)

### Acceptance Verification

- [X] T307 [US2] Verify: Dashboard displays events in real-time via WebSocket
- [X] T308 [US2] Verify: Events are filterable by source app, session, and event type
- [X] T309 [US2] Verify: Each event shows timestamp, event type, tool name, and summary
- [X] T310 [US2] Verify: Chat transcripts are viewable for completed sessions

### Checkpoint

- [X] T311 [US2] CHECKPOINT: Verify US-002 Dashboard is complete and functional

---

## Phase 5: User Story 3 - Start and Stop Observability System (US-003)

**Story**: As a projspec plugin user, I want to easily start and stop the observability server and client so that I can enable observability only when needed.

**Priority**: Medium (P2)

### Lifecycle Scripts

- [X] T400 [US3] Implement start-observability.sh with process management (scripts/start-observability.sh)
- [X] T401 [US3] Add port availability detection to start script (scripts/start-observability.sh)
- [X] T402 [US3] Add port auto-increment logic when default ports are occupied (scripts/start-observability.sh)
- [X] T403 [US3] Implement stop-observability.sh with graceful shutdown (scripts/stop-observability.sh)
- [X] T404 [US3] Implement status-observability.sh for health reporting (scripts/status-observability.sh)
- [X] T405 [US3] Implement purge-events.sh for manual cleanup (scripts/purge-events.sh)
- [X] T406 [US3] Create PID file management for process tracking (scripts/start-observability.sh)

### Script Tests

- [X] T407 [P] [US3] Write tests for start-observability.sh (observability/tests/test_scripts.bats)
- [X] T408 [P] [US3] Write tests for stop-observability.sh (observability/tests/test_scripts.bats)
- [X] T409 [P] [US3] Write tests for status-observability.sh (observability/tests/test_scripts.bats)

### Acceptance Verification

- [X] T410 [US3] Verify: Single command starts both server and client
- [X] T411 [US3] Verify: Single command stops all processes cleanly
- [X] T412 [US3] Verify: Health status is reportable on demand
- [X] T413 [US3] Verify: Port conflicts are detected and reported

### Checkpoint

- [X] T414 [US3] CHECKPOINT: Verify US-003 Lifecycle Scripts are complete and functional

---

## Phase 6: Polish - Final Integration and Documentation

Final integration testing, documentation updates, and polish.

### Documentation

- [X] T500 [P] Update quickstart.md with final installation steps (specs/.../quickstart.md)
- [X] T501 [P] Add troubleshooting section to quickstart.md (specs/.../quickstart.md)
- [X] T502 [P] Update observability README with usage examples (observability/README.md)

### End-to-End Testing

- [X] T503 Test complete workflow: enable observability, run command, view dashboard
- [X] T504 Test port conflict scenario with auto-increment
- [X] T505 Test large chat transcript truncation
- [X] T506 Test server restart recovery

### Final Validation

- [X] T507 Verify all success criteria are met (SC-001, SC-002, SC-003)
- [X] T508 CHECKPOINT: Final review - feature is complete and ready for PR

---

## Dependencies

### Phase Dependencies

| Phase | Depends On | Description |
|-------|------------|-------------|
| Phase 1: Setup | None | Initial directory structure |
| Phase 2: Foundational | Phase 1 | Requires directories to exist |
| Phase 3: US-001 | Phase 2 | Requires vendored components |
| Phase 4: US-002 | Phase 2, Phase 3 | Requires hooks sending events |
| Phase 5: US-003 | Phase 2 | Requires server/client vendored |
| Phase 6: Polish | Phase 3, 4, 5 | Requires all features complete |

### Task Dependency Table

| Task ID | Description | Blocked By | Parallel |
|---------|-------------|------------|----------|
| T001-T005 | Directory creation | - | Yes |
| T006 | README creation | T001 | No |
| T100-T104 | Server vendoring | T002 | No (sequential) |
| T105-T107 | Client vendoring | T003 | Yes |
| T108-T117 | Hook vendoring | T004 | Yes (except T108) |
| T118 | Vendor checkpoint | T100-T117 | No |
| T200-T208 | Hook definitions | T118 | No (sequential) |
| T209-T212 | Hook modifications | T108, T118 | No |
| T213-T214 | Configuration docs | T209 | No |
| T215-T220 | US-001 tests | T212 | Partially |
| T221 | US-001 checkpoint | T215-T220 | No |
| T300-T303 | Server verification | T118 | No |
| T304-T310 | US-002 tests | T303 | Partially |
| T311 | US-002 checkpoint | T304-T310 | No |
| T400-T406 | Lifecycle scripts | T118 | No |
| T407-T413 | US-003 tests | T406 | Partially |
| T414 | US-003 checkpoint | T407-T413 | No |
| T500-T506 | Polish tasks | T221, T311, T414 | Partially |
| T507-T508 | Final validation | T500-T506 | No |

### Parallel Execution Groups

#### Group A: Initial Setup (Phase 1)
Tasks that can run simultaneously:
- T001, T002, T003, T004, T005

#### Group B: Client Vendoring (Phase 2)
Tasks that can run simultaneously:
- T105, T106, T107

#### Group C: Hook Script Vendoring (Phase 2)
Tasks that can run simultaneously after T108:
- T109, T110, T111, T112, T113, T114, T115, T116, T117

#### Group D: US-001 Unit Tests (Phase 3)
Tasks that can run simultaneously:
- T215, T216

#### Group E: US-002 Integration Tests (Phase 4)
Tasks that can run simultaneously:
- T304, T305

#### Group F: US-003 Script Tests (Phase 5)
Tasks that can run simultaneously:
- T407, T408, T409

#### Group G: Polish Documentation (Phase 6)
Tasks that can run simultaneously:
- T500, T501, T502

### Dependency Diagram

```
PHASE 1: SETUP
──────────────────────────────────────────────────────────

┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
│T001 │  │T002 │  │T003 │  │T004 │  │T005 │  [P]
│dirs │  │servr│  │clnt │  │hooks│  │tests│
└──┬──┘  └──┬──┘  └──┬──┘  └──┬──┘  └──┬──┘
   │        │        │        │        │
   └────────┴────────┴────────┴────────┘
                     │
                     ▼
               ┌───────────┐
               │   T006    │
               │  README   │
               └─────┬─────┘
                     │
═══════════════════════════════════════════════════════════

PHASE 2: FOUNDATIONAL
──────────────────────────────────────────────────────────

         ┌─────────────────────────────────────┐
         │                                     │
         ▼                                     ▼
┌────────────────────┐              ┌─────────────────────┐
│ T100-T104          │              │ T105-T107 [P]       │
│ Server Vendoring   │              │ Client Vendoring    │
└────────┬───────────┘              └──────────┬──────────┘
         │                                     │
         │            ┌────────────────────────┤
         │            │                        │
         │            ▼                        │
         │   ┌─────────────────────┐           │
         │   │ T108                │           │
         │   │ send_event.py      │           │
         │   └────────┬────────────┘           │
         │            │                        │
         │            ▼                        │
         │   ┌─────────────────────┐           │
         │   │ T109-T117 [P]       │           │
         │   │ Hook Scripts        │           │
         │   └────────┬────────────┘           │
         │            │                        │
         └────────────┴────────────────────────┘
                      │
                      ▼
               ┌─────────────┐
               │    T118     │
               │ CHECKPOINT  │
               └──────┬──────┘
                      │
═══════════════════════════════════════════════════════════

PHASE 3-5: USER STORIES
──────────────────────────────────────────────────────────

                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
  ┌───────────┐ ┌───────────┐ ┌───────────┐
  │  US-001   │ │  US-002   │ │  US-003   │
  │ T200-T221 │ │ T300-T311 │ │ T400-T414 │
  │  Hooks    │ │ Dashboard │ │ Lifecycle │
  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘
        │             │             │
        └─────────────┴─────────────┘
                      │
                      ▼
═══════════════════════════════════════════════════════════

PHASE 6: POLISH
──────────────────────────────────────────────────────────

                      │
                      ▼
               ┌─────────────┐
               │  T500-T506  │
               │   Polish    │
               └──────┬──────┘
                      │
                      ▼
               ┌─────────────┐
               │    T508     │
               │ FINAL CKPT  │
               └─────────────┘
```

---

## Validation Summary

### Format Validation
✓ All tasks have valid format (T### pattern)
✓ All task IDs are unique
✓ Parallel markers [P] properly applied

### Dependency Validation
✓ No circular dependencies detected
✓ All dependency references are valid
✓ Phase dependencies are consistent

### Priority Validation
✓ P1 tasks (US-001, US-002) scheduled before P2 (US-003)
✓ No priority inversions detected

### Coverage Validation
✓ All functional requirements (FR-001 to FR-005) have corresponding tasks
✓ All user stories (US-001 to US-003) have dedicated phases
✓ All acceptance criteria have verification tasks

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 47 |
| Setup Tasks | 6 |
| Foundational Tasks | 19 |
| US-001 Tasks | 22 |
| US-002 Tasks | 12 |
| US-003 Tasks | 15 |
| Polish Tasks | 9 |
| Parallel Tasks | 28 |
| Checkpoints | 5 |

### Priority Distribution

| Priority | Task Count | Percentage |
|----------|------------|------------|
| P1 (Critical) | 28 | 60% |
| P2 (Important) | 15 | 32% |
| P3 (Polish) | 4 | 8% |

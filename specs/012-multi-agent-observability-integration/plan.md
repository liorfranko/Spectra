# Implementation Plan: Multi-Agent Observability Integration

**Feature**: Multi-Agent Observability Integration
**Branch**: `012-multi-agent-observability-integration`
**Date**: 2026-01-27
**Status**: Ready for Implementation

---

## Technical Context

### Language & Runtime

| Aspect | Value |
|--------|-------|
| Primary Language | Python 3.8+ (hooks), TypeScript (server), Bash (lifecycle scripts) |
| Server Runtime | Bun >= 1.0 |
| Hook Runtime | Python via uv (Astral) |
| Client Framework | Vue 3 (pre-built static files) |
| Database | SQLite 3.x (bundled with Bun) |

### Dependencies

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| Bun | >= 1.0 | Server runtime, SQLite bindings, static file serving | Required (new) |
| uv | >= 0.1 | Python hook script execution | Required (new) |
| Python | >= 3.8 | Hook script language | Required (usually pre-installed) |
| sqlite | ^5.1.1 | Database driver (npm) | Vendored with server |
| Vue | ^3.5 | Client framework | Vendored (pre-built) |

### Platform & Environment

| Aspect | Value |
|--------|-------|
| Target Platform | Claude Code plugin (macOS, Linux) |
| Minimum Requirements | Claude Code CLI installed, Bun runtime, uv package manager |
| Environment Variables | `CLAUDE_PLUGIN_ROOT` (plugin path), `PROJSPEC_OBSERVABILITY_*` (optional overrides) |

### Constraints

- **Non-blocking Execution**: All hook scripts must exit within 5 seconds and never block Claude Code operations
- **Localhost Only**: Server binds to 127.0.0.1 by default; no external network exposure
- **Disabled by Default**: Observability requires explicit opt-in via configuration
- **Dependency Documentation**: Prerequisites (Bun, uv) must be clearly documented
- **Event Retention**: Automatic 7-day retention with cleanup on server startup
- **Transcript Size**: Chat transcripts truncated at 1MB (oldest messages removed)
- **Port Conflicts**: Auto-increment to available port if default is occupied

### Testing Approach

| Aspect | Value |
|--------|-------|
| Test Framework | pytest (Python hooks), bats-core (Bash scripts), manual (integration) |
| Test Location | `projspec/plugins/projspec/observability/tests/` |
| Required Coverage | Critical paths (event send, server endpoints, lifecycle scripts) |

**Test Types**:
- Unit: Python hook logic, event payload construction
- Integration: Server endpoints, database operations, WebSocket broadcasting
- E2E: Full flow from Claude Code hook trigger to client dashboard display
- Manual: Port conflict scenarios, large transcripts, server restart recovery

---

## Constitution Check

**Constitution Source**: `projspec/plugins/projspec/memory/constitution.md`
**Check Date**: 2026-01-27

### Principle Compliance

| Principle | Description | Status | Notes |
|-----------|-------------|--------|-------|
| I. User-Centric Design | Prioritize UX and accessibility | PASS | Dashboard provides clear visualization; disabled by default avoids confusion |
| II. Maintainability First | Code for humans to read | PASS | Clear separation of concerns; upstream code is well-documented |
| III. Incremental Delivery | Small, testable increments | PASS | Plan follows phased approach; each component independently testable |
| IV. Documentation as Code | Documentation is first-class | PASS | Quickstart, research, and data model provided; prerequisites documented |
| V. Test-Driven Confidence | Tests accompany functionality | PASS | Test strategy defined for all components |

### Compliance Details

#### Principles with Full Compliance (PASS)

- **Principle I (User-Centric Design)**: The observability system is disabled by default, preventing unexpected behavior for new users. The dashboard provides intuitive real-time visualization with filtering capabilities. Port auto-increment ensures smooth startup experience.

- **Principle II (Maintainability First)**: Code is organized into clear components (hooks, server, client). Vendoring upstream code maintains parity with well-tested implementation. Configuration uses familiar YAML patterns.

- **Principle III (Incremental Delivery)**: Implementation is decomposed into phases:
  1. Vendor components (standalone, testable)
  2. Integrate hooks (testable against mock server)
  3. Add lifecycle scripts (testable in isolation)
  4. Add configuration (final integration)

- **Principle IV (Documentation as Code)**: Complete documentation artifacts:
  - `quickstart.md`: Setup and usage guide
  - `research.md`: Technical decisions with rationale
  - `data-model.md`: Entity definitions and schemas
  - Prerequisites documented with installation commands

- **Principle V (Test-Driven Confidence)**: Test strategy covers:
  - Unit tests for hook logic and payload construction
  - Integration tests for server endpoints
  - E2E tests for full event flow
  - Manual test procedures for edge cases

### Gate Status

**Constitution Check Result**: PASS

**Criteria**:
- All 5 principles are PASS with documented compliance

**Action Required**: None - proceed to implementation

---

## Project Structure

### Documentation Layout

```
specs/012-multi-agent-observability-integration/
├── spec.md              # Feature specification
├── research.md          # Technical research and decisions
├── data-model.md        # Entity definitions and schemas
├── plan.md              # This implementation plan
├── quickstart.md        # Getting started guide
├── tasks.md             # Implementation task list (TBD)
└── checklists/          # Validation checklists
    └── requirements.md
```

### Source Code Layout

Based on project type: Claude Code Plugin

```
projspec/plugins/projspec/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/
│   └── *.md                     # Existing commands
├── agents/
│   └── *.md                     # Existing agents
├── hooks/
│   └── hooks.json               # Hook definitions (to be updated)
├── memory/
│   └── *.md                     # Persistent context
├── scripts/
│   ├── *.sh                     # Existing scripts
│   ├── start-observability.sh   # NEW: Start server/client
│   ├── stop-observability.sh    # NEW: Stop processes
│   ├── status-observability.sh  # NEW: Health check
│   └── purge-events.sh          # NEW: Manual cleanup
├── templates/
│   └── *.md                     # Existing templates
├── tests/
│   └── *.md                     # Existing tests
└── observability/               # NEW: Vendored observability system
    ├── README.md                # Attribution and version info
    ├── server/                  # Bun server (TypeScript)
    │   ├── src/
    │   │   ├── index.ts         # Server entry point
    │   │   └── db.ts            # Database schema
    │   ├── package.json
    │   └── bun.lockb
    ├── client/                  # Vue client (pre-built)
    │   └── dist/                # Static files
    │       ├── index.html
    │       ├── assets/
    │       └── *.js, *.css
    ├── hooks/                   # Python hook scripts
    │   ├── send_event.py        # Core event dispatcher
    │   ├── pre_tool_use.py
    │   ├── post_tool_use.py
    │   ├── notification.py
    │   ├── stop.py
    │   ├── subagent_stop.py
    │   ├── pre_compact.py
    │   ├── user_prompt_submit.py
    │   ├── session_start.py
    │   └── session_end.py
    └── tests/                   # Test files
        ├── test_hooks.py
        └── test_server.bats
```

### Directory Purposes

| Directory | Purpose |
|-----------|---------|
| `observability/` | Vendored observability components from upstream |
| `observability/server/` | Bun TypeScript server for event storage and WebSocket |
| `observability/client/dist/` | Pre-built Vue client static files |
| `observability/hooks/` | Python hook scripts for event capture |
| `observability/tests/` | Unit and integration tests |
| `scripts/` | Bash lifecycle management scripts |
| `hooks/` | Claude Code hook definitions (hooks.json) |

### File-to-Requirement Mapping

| File | Requirements | Purpose |
|------|--------------|---------|
| `hooks/hooks.json` | FR-001 | Claude Code hook registration for all 9 event types |
| `observability/hooks/send_event.py` | FR-002 | Core event dispatch with payload construction |
| `observability/hooks/pre_tool_use.py` | FR-001 | PreToolUse event capture |
| `observability/hooks/post_tool_use.py` | FR-001 | PostToolUse event capture |
| `observability/hooks/session_start.py` | FR-001 | SessionStart event capture |
| `observability/hooks/session_end.py` | FR-001 | SessionEnd event capture with transcript |
| `observability/hooks/stop.py` | FR-001 | Stop event capture |
| `observability/hooks/subagent_stop.py` | FR-001 | SubagentStop event capture |
| `observability/hooks/notification.py` | FR-001 | Notification event capture |
| `observability/hooks/pre_compact.py` | FR-001 | PreCompact event capture |
| `observability/hooks/user_prompt_submit.py` | FR-001 | UserPromptSubmit event capture |
| `observability/server/src/index.ts` | FR-003 | Server endpoints (POST /events, GET /events/recent, WebSocket) |
| `observability/server/src/db.ts` | FR-003 | SQLite schema and event storage |
| `observability/client/dist/` | US-002 | Real-time dashboard UI |
| `scripts/start-observability.sh` | FR-005, US-003 | Start server and client processes |
| `scripts/stop-observability.sh` | FR-005, US-003 | Stop all processes |
| `scripts/status-observability.sh` | FR-005, US-003 | Health status reporting |
| `scripts/purge-events.sh` | FR-005 | Manual event cleanup |
| `.projspec/projspec.local.md` | FR-004 | Plugin configuration (user-created) |

### New Files to Create

| File Path | Type | Description |
|-----------|------|-------------|
| `observability/README.md` | doc | Attribution, upstream version, license info |
| `observability/server/*` | source | Vendored Bun server from upstream |
| `observability/client/dist/*` | static | Pre-built Vue client |
| `observability/hooks/*.py` | source | Vendored Python hooks from upstream |
| `scripts/start-observability.sh` | script | Start server/client with port detection |
| `scripts/stop-observability.sh` | script | Stop all observability processes |
| `scripts/status-observability.sh` | script | Report health and running status |
| `scripts/purge-events.sh` | script | Delete events older than N days |
| `hooks/hooks.json` | config | Updated hook definitions for observability |
| `observability/tests/test_hooks.py` | test | Python hook unit tests |
| `observability/tests/test_server.bats` | test | Server integration tests |

---

## Complexity Tracking

### Technical Debt

No technical debt identified for initial implementation. The following items are deferred to future releases:

| Item | Description | Severity | Notes |
|------|-------------|----------|-------|
| Authentication | No auth for multi-user scenarios | Low | Documented in Q-003 as future enhancement |
| Remote Access | Localhost-only operation | Low | Security by design; can add later |
| Event Summarization | AI summarization is optional | Low | Available via --summarize flag |

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Bun not installed | Medium | High | Clear prerequisite docs, installation script |
| uv not installed | Medium | High | Clear prerequisite docs, installation script |
| Port conflicts | Medium | Low | Auto-increment logic implemented |
| Large database growth | Low | Medium | 7-day retention with auto-cleanup |
| Upstream breaking changes | Low | Medium | Pin to specific version, document update process |

---

## Implementation Phases

### Phase 1: Vendor Components
Vendor the observability server, client, and hooks from upstream repository.
- Copy TypeScript server source
- Pre-build Vue client to static files
- Copy Python hook scripts
- Create attribution README

### Phase 2: Integrate Hooks
Configure Claude Code hooks to capture events.
- Update hooks.json with observability hook definitions
- Modify hooks to read projspec configuration
- Add conditional execution based on enabled flag
- Add projspec-specific context to payloads

### Phase 3: Lifecycle Scripts
Create Bash scripts for system management.
- Implement start-observability.sh with port detection
- Implement stop-observability.sh with graceful shutdown
- Implement status-observability.sh for health reporting
- Implement purge-events.sh for manual cleanup

### Phase 4: Configuration & Documentation
Finalize configuration patterns and documentation.
- Document .local.md configuration pattern
- Create quickstart guide with prerequisites
- Add troubleshooting section
- Test complete workflow end-to-end

---

## Next Steps

Run `/projspec:tasks` to generate the detailed implementation task list with dependencies.

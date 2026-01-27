# Research: Multi-Agent Observability Integration

## Overview

This document captures technical research and decision rationale for integrating multi-agent observability capabilities from the `disler/claude-code-hooks-multi-agent-observability` project into the projspec plugin. The integration enables real-time monitoring and visualization of Claude Code agent behavior during projspec workflows.

---

## Technical Unknowns

### Unknown 1: Vendoring Strategy for Observability Components

**Question**: How should the observability server, client, and hook scripts be integrated into the projspec plugin?

**Options Considered**:
1. **Full Repository Vendor** - Copy entire disler/claude-code-hooks-multi-agent-observability repo into projspec
2. **Selective Component Vendor** - Extract only necessary components (server, client, hooks)
3. **Git Submodule** - Reference as a git submodule for easier updates
4. **NPM/Package Dependency** - Publish observability as a package and declare dependency

**Decision**: Selective Component Vendor

**Rationale**:
- Full repository includes documentation, examples, and files not needed for integration
- Submodules add complexity for users who clone/install the plugin
- NPM dependency would require publishing and maintaining a separate package
- Selective vendoring keeps the plugin self-contained while minimizing size

**Trade-offs**:
- Manual effort required to update vendored components when upstream changes
- May miss upstream improvements if not regularly synced

**Implementation**:
```
projspec/plugins/projspec/observability/
├── server/          # Bun server (TypeScript)
├── client/          # Vue client (pre-built or source)
├── hooks/           # Python hook scripts
└── README.md        # Attribution and version info
```

---

### Unknown 2: Hook Script Language Choice

**Question**: Should observability hooks be implemented in Python (matching upstream) or Bash (matching existing projspec scripts)?

**Options Considered**:
1. **Python (upstream approach)** - Use uv + Python for hook scripts
2. **Bash (native)** - Reimplement hooks in pure Bash
3. **Hybrid** - Bash wrapper calling Python core logic

**Decision**: Python (upstream approach)

**Rationale**:
- Upstream implementation is well-tested and feature-complete
- Python provides better HTTP handling and JSON parsing than Bash
- The `uv` package manager provides fast, reproducible Python execution
- Maintaining parity with upstream simplifies updates and debugging
- Claude Code hook system explicitly supports Python via uv

**Trade-offs**:
- Adds Python/uv as a dependency (documented in A-001)
- Slight context switch from Bash-based projspec scripts

**Sources**:
- Claude Code documentation on hooks: supports both bash and uv-based Python
- Upstream hooks use `urllib.request` for HTTP with 5-second timeout

---

### Unknown 3: Server Runtime and Database

**Question**: What runtime and database should the observability server use?

**Options Considered**:
1. **Bun + SQLite (upstream)** - Use existing implementation
2. **Node.js + SQLite** - More common runtime
3. **Node.js + PostgreSQL** - More scalable database
4. **Python + SQLite** - Align with hook language

**Decision**: Bun + SQLite (upstream)

**Rationale**:
- Bun provides fast startup and execution for local development server
- SQLite is file-based, requires no external database setup
- Upstream implementation is production-tested
- Single-user local use case doesn't require PostgreSQL scalability
- Keeping upstream stack simplifies vendoring and maintenance

**Trade-offs**:
- Bun is less common than Node.js (additional dependency)
- SQLite limits concurrent write performance (acceptable for local use)

**Sources**:
- Bun documentation: https://bun.sh
- SQLite WAL mode provides good read/write concurrency for single-user scenarios

---

### Unknown 4: Client Delivery Method

**Question**: Should the Vue client be delivered as source code, pre-built static files, or built on first run?

**Options Considered**:
1. **Pre-built Static Files** - Include compiled dist/ directory
2. **Source Code** - Include source, build on first run
3. **CDN/Remote** - Serve client from external URL

**Decision**: Pre-built Static Files

**Rationale**:
- Eliminates need for Node.js/npm on user's machine for client build
- Faster startup (no build step required)
- Bun can serve static files directly
- Reduces plugin size vs full source + node_modules
- Self-contained operation (no external CDN dependency)

**Trade-offs**:
- Larger initial plugin size (~2-5MB for built client)
- Customization requires rebuilding

**Implementation**:
- Pre-build client during plugin release
- Store in `observability/client/dist/`
- Server serves from this directory

---

### Unknown 5: Configuration Storage Pattern

**Question**: How should observability configuration be stored and accessed?

**Options Considered**:
1. **YAML Frontmatter in .local.md** - Projspec plugin convention
2. **JSON Configuration File** - Standard config pattern
3. **Environment Variables** - Runtime configuration
4. **Claude Code settings.json** - Native integration

**Decision**: YAML Frontmatter in `.local.md` + Environment Variables for runtime

**Rationale**:
- `.local.md` pattern aligns with projspec plugin conventions
- YAML frontmatter is human-readable and editable
- Environment variables allow runtime overrides without file changes
- Claude Code settings.json is for hook definitions, not plugin config
- `.local.md` is gitignored by convention (no accidental secret commits)

**Trade-offs**:
- Requires parsing YAML frontmatter (simple with Python/Bash)
- Two config sources to check (file + env vars)

**Configuration Schema**:
```yaml
---
observability:
  enabled: false
  server_url: http://localhost:4000
  client_url: http://localhost:3000
  source_app: projspec
  summarize_events: false
  include_chat: false
  max_chat_size: 1048576  # 1MB
  retention_days: 7
---
```

---

### Unknown 6: Port Conflict Resolution Strategy

**Question**: How should the system handle port conflicts when starting the observability server and client?

**Options Considered**:
1. **Fail with Error** - Exit if port is taken
2. **Auto-Increment** - Try next port (4001, 4002, etc.)
3. **User-Specified Only** - Require explicit port configuration
4. **Kill Existing Process** - Terminate conflicting process

**Decision**: Auto-Increment with Reporting

**Rationale**:
- Provides seamless startup experience for users with multiple projects
- Reporting selected ports keeps user informed
- Avoids frustration of manual port hunting
- Safer than killing potentially important processes

**Trade-offs**:
- Users must check status output to know actual ports
- May lead to orphaned processes on non-standard ports

**Implementation**:
```bash
find_available_port() {
  local base_port=$1
  local port=$base_port
  while lsof -i :$port > /dev/null 2>&1; do
    port=$((port + 1))
  done
  echo $port
}
```

---

### Unknown 7: Event Retention and Cleanup

**Question**: How should automatic event cleanup be implemented?

**Options Considered**:
1. **Scheduled Background Task** - Cron/launchd job
2. **On-Startup Cleanup** - Clean when server starts
3. **On-Event Cleanup** - Probabilistic cleanup on each event
4. **Manual Only** - User-triggered purge command

**Decision**: On-Startup Cleanup + Manual Purge Command

**Rationale**:
- On-startup cleanup ensures consistent behavior without external schedulers
- Avoids complexity of cron/launchd configuration
- Probabilistic cleanup adds unpredictability
- Manual purge provides immediate control when needed

**Trade-offs**:
- Long-running servers won't auto-cleanup until restart
- Could add optional background timer for long sessions

**Implementation**:
- Server runs cleanup query on startup: `DELETE FROM events WHERE timestamp < (now - retention_days)`
- Purge script provides immediate cleanup via HTTP endpoint or direct SQLite

---

## Key Findings

### Architecture Alignment

The upstream observability system aligns well with projspec's plugin architecture:

| Upstream Component | Projspec Integration Point |
|--------------------|---------------------------|
| Python hook scripts | `projspec/plugins/projspec/observability/hooks/` |
| Bun server | `projspec/plugins/projspec/observability/server/` |
| Vue client (built) | `projspec/plugins/projspec/observability/client/dist/` |
| SQLite database | `~/.projspec/observability.db` (user home) |
| Hook configuration | `projspec/plugins/projspec/hooks/hooks.json` |

### Dependency Matrix

| Dependency | Required For | Version | Installation |
|------------|--------------|---------|--------------|
| Bun | Server runtime | >= 1.0 | https://bun.sh |
| uv | Python hooks | >= 0.1 | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Python | Hook scripts | >= 3.8 | Usually pre-installed |
| SQLite | Database | 3.x | Bundled with Bun |

### Hook Event Flow

```
Claude Code Agent
       │
       ▼
┌──────────────────┐
│  Claude Code     │  Triggers hook on:
│  Hook System     │  PreToolUse, PostToolUse, etc.
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Python Hook     │  Constructs event payload
│  (via uv run)    │  Adds projspec context
└────────┬─────────┘
         │ HTTP POST (5s timeout)
         ▼
┌──────────────────┐
│  Bun Server      │  Stores in SQLite
│  (:4000)         │  Broadcasts via WebSocket
└────────┬─────────┘
         │ WebSocket
         ▼
┌──────────────────┐
│  Vue Client      │  Real-time display
│  (:3000)         │  Filtering, analytics
└──────────────────┘
```

### Security Considerations

1. **Localhost Only**: Server binds to 127.0.0.1 by default (no external access)
2. **No Authentication**: Acceptable for single-user local use; documented as future enhancement
3. **Sensitive Data**: Chat transcripts may contain API keys, passwords in examples
   - Recommendation: Add warning to quickstart about transcript content
   - Consider: Optional redaction patterns for sensitive data

---

## Recommendations

### Implementation Approach

1. **Phase 1: Vendor Components**
   - Copy server, client (pre-built), and hook scripts to observability/ directory
   - Create attribution README with upstream version and license info

2. **Phase 2: Integrate Hooks**
   - Populate hooks.json with observability hook definitions
   - Configure conditional execution based on observability.enabled config
   - Add projspec-specific context to event payloads

3. **Phase 3: Lifecycle Scripts**
   - Create start-observability.sh, stop-observability.sh, status-observability.sh
   - Implement port auto-increment logic
   - Add purge-events.sh for manual cleanup

4. **Phase 4: Configuration**
   - Document .local.md configuration pattern
   - Implement config parsing in hook scripts
   - Add environment variable overrides

### Testing Strategy

1. **Unit Tests**: Hook script logic (Python)
2. **Integration Tests**: Server endpoint behavior
3. **E2E Tests**: Full flow from Claude Code trigger to client display
4. **Manual Testing**: Port conflict scenarios, large transcripts, server restart

---

## Sources

- **Upstream Repository**: https://github.com/disler/claude-code-hooks-multi-agent-observability
- **Claude Code Hooks Documentation**: Claude Code CLI documentation
- **Bun Documentation**: https://bun.sh/docs
- **Astral uv Documentation**: https://docs.astral.sh/uv/
- **SQLite WAL Mode**: https://www.sqlite.org/wal.html

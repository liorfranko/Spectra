# Observability Components

Real-time multi-agent observability system for Claude Code, providing event capture, storage, and visualization.

## Attribution

This observability system is vendored from:

**Repository:** [claude-code-hooks-multi-agent-observability](https://github.com/disler/claude-code-hooks-multi-agent-observability)
**Author:** [disler](https://github.com/disler)
**License:** MIT
**Vendored Version:** `[PLACEHOLDER - update when vendoring]`
**Vendored Commit:** `[PLACEHOLDER - update when vendoring]`
**Vendored Date:** `[PLACEHOLDER - update when vendoring]`

## Overview

The observability system consists of three main components:

| Component | Technology | Description |
|-----------|------------|-------------|
| **Server** | Bun (TypeScript) | Event storage in SQLite, WebSocket broadcasting, REST API |
| **Client** | Vue (pre-built) | Real-time dashboard for event visualization |
| **Hooks** | Python | Event capture scripts integrated with Claude Code hooks |

### Architecture

```
Claude Code Hooks --> Python Scripts --> HTTP POST --> Bun Server --> SQLite
                                                           |
                                                           v
                                                      WebSocket
                                                           |
                                                           v
                                                     Vue Dashboard
```

## Prerequisites

- **Bun** >= 1.0 (for server)
- **uv** >= 0.1 (for Python hook scripts)
- **Python** >= 3.8 (for hook scripts)

## Quick Start

For detailed setup and usage instructions, see [quickstart.md](../docs/quickstart.md).

### Brief Overview

1. **Start the server** (port 4000):
   ```bash
   cd server && bun run start
   ```

2. **Start the client** (port 3000):
   ```bash
   cd client && bun run preview
   ```

3. **View dashboard**: Open http://localhost:3000

## Directory Structure

```
observability/
├── README.md           # This file
├── server/             # Bun server for event storage and WebSocket
│   ├── index.ts        # Main server entry point
│   ├── package.json    # Server dependencies
│   └── ...
├── client/             # Vue dashboard (pre-built)
│   ├── dist/           # Built client files
│   ├── package.json    # Client dependencies
│   └── ...
└── scripts/            # Python hook scripts
    ├── emit_event.py   # Core event emission logic
    └── ...
```

## Configuration

Observability is configured through the `.projspec/projspec.local.md` file using YAML frontmatter. This file should be created in your project root directory.

### Configuration File Location

```
your-project/
├── .projspec/
│   └── projspec.local.md    # Observability configuration
└── ...
```

### Configuration Format

Create or edit `.projspec/projspec.local.md` with YAML frontmatter:

```markdown
---
observability:
  enabled: true
  server_url: http://localhost:4000
  client_url: http://localhost:3000
---

# Project Observability Notes

Optional markdown content for project-specific notes.
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable or disable observability event capture |
| `server_url` | string | `http://localhost:4000` | URL of the observability server for event submission |
| `client_url` | string | `http://localhost:3000` | URL of the Vue dashboard for visualization |
| `source_app` | string | `projspec` | Application identifier included in all events |
| `summarize_events` | boolean | `false` | Enable event summarization before sending |
| `include_chat` | boolean | `false` | Include chat content in captured events |
| `max_chat_size` | integer | `1048576` | Maximum chat content size in bytes (1MB default) |
| `retention_days` | integer | `7` | Number of days to retain events before cleanup |

### Enabling Observability

To enable observability for your project:

1. **Create the configuration file**:
   ```bash
   mkdir -p .projspec
   cat > .projspec/projspec.local.md << 'EOF'
   ---
   observability:
     enabled: true
   ---
   EOF
   ```

2. **Start the server and client** (see [Quick Start](#quick-start))

3. **Use Claude Code normally** - events will be captured automatically

### Minimal Configuration

The simplest configuration to enable observability with all defaults:

```yaml
---
observability:
  enabled: true
---
```

### Full Configuration Example

A complete configuration with all options explicitly set:

```yaml
---
observability:
  enabled: true
  server_url: http://localhost:4000
  client_url: http://localhost:3000
  source_app: my-project
  summarize_events: false
  include_chat: true
  max_chat_size: 2097152  # 2MB
  retention_days: 14
---
```

## Usage Examples

### Starting and Stopping the System

Use the lifecycle scripts in the `scripts/` directory:

```bash
# Start the observability system
./scripts/start-observability.sh

# Check system status
./scripts/status-observability.sh

# Stop the observability system
./scripts/stop-observability.sh

# Clean up old events (older than 7 days)
./scripts/purge-events.sh

# Clean up events older than 30 days
./scripts/purge-events.sh --days=30
```

### Monitoring Multiple Projects

Run observability for multiple projects simultaneously:

```bash
# Project A configuration (.projspec/projspec.local.md)
---
observability:
  enabled: true
  source_app: project-alpha
---

# Project B configuration (.projspec/projspec.local.md)
---
observability:
  enabled: true
  source_app: project-beta
---
```

Filter by `source_app` in the dashboard to see events from specific projects.

### Debugging with Chat Transcripts

Enable full chat transcript capture for debugging:

```yaml
---
observability:
  enabled: true
  include_chat: true
  max_chat_size: 2097152  # 2MB for longer conversations
---
```

### Server Configuration

These settings affect the observability server behavior:

| Setting | Default | Description |
|---------|---------|-------------|
| Server Port | 4000 | HTTP and WebSocket server port |
| Client Port | 3000 | Dashboard preview port |
| Database | `events.db` | SQLite database file |
| Retention | 7 days | Automatic event cleanup period |

## License

The vendored components are licensed under the MIT License, consistent with the upstream repository.

See the upstream repository for the full license text: https://github.com/disler/claude-code-hooks-multi-agent-observability/blob/main/LICENSE

## Modifications

Any modifications made to the vendored code for projspec integration are documented below:

- `[PLACEHOLDER - document modifications when vendoring]`

---

*This README was created as part of projspec's multi-agent observability integration.*

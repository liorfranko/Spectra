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

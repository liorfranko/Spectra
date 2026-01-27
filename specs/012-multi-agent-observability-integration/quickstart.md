# Quickstart: Multi-Agent Observability Integration

Get started with multi-agent observability for projspec workflows in under 5 minutes.

## Prerequisites

Before you begin, ensure you have:

- [ ] **Claude Code CLI** installed and authenticated
- [ ] **Bun runtime** (>= 1.0) installed - [Install Bun](https://bun.sh)
- [ ] **Astral uv** (>= 0.1) installed - [Install uv](https://docs.astral.sh/uv/)
- [ ] **Python 3.8+** installed (usually pre-installed on macOS/Linux)
- [ ] **projspec plugin** installed in Claude Code

### Install Prerequisites

**Install Bun** (JavaScript runtime for the observability server):

```bash
curl -fsSL https://bun.sh/install | bash
```

**Install uv** (Python package manager for hook scripts):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Verify installations**:

```bash
bun --version  # Should show >= 1.0.0
uv --version   # Should show >= 0.1.0
python3 --version  # Should show >= 3.8
```

## Installation

The observability system is bundled with the projspec plugin. No additional installation required.

### Step 1: Verify Observability Components

Check that the observability components are present in the plugin:

```bash
ls ~/.claude/plugins/projspec/observability/
```

Expected output:
```
README.md  client/  hooks/  server/  tests/
```

### Step 2: Start the Observability System

Start the observability server and web client:

```bash
~/.claude/plugins/projspec/scripts/start-observability.sh
```

Expected output:
```
Starting observability server on port 4000...
Starting observability client on port 3000...

Observability system started successfully!
  Server: http://localhost:4000
  Client: http://localhost:3000

Open the client URL in your browser to view the dashboard.
```

### Step 3: Verify System is Running

Check the status of the observability system:

```bash
~/.claude/plugins/projspec/scripts/status-observability.sh
```

Expected output:
```
Observability System Status
===========================
Server: RUNNING (PID: 12345, Port: 4000)
Client: RUNNING (PID: 12346, Port: 3000)
Database: ~/.projspec/observability.db (1.2 MB)
Events: 0 stored
```

## Quick Start

Follow these steps to enable observability for your projspec workflows:

### 1. Enable Observability in Your Project

Create or edit `.projspec/projspec.local.md` in your project root:

```markdown
---
observability:
  enabled: true
  source_app: my-project
---

# Projspec Local Configuration

Observability is enabled for this project.
```

### 2. Open the Dashboard

Open your browser to the client URL shown during startup (default: http://localhost:3000).

You'll see an empty dashboard waiting for events.

### 3. Run a Projspec Command

In a new terminal, run any projspec command in Claude Code:

```bash
claude
```

Then in the Claude Code session:

```
/projspec:specify "Add a user login feature"
```

### 4. Watch Events in Real-Time

Switch back to your browser. You'll see events appearing in the dashboard as Claude Code executes:

- PreToolUse events (before each tool call)
- PostToolUse events (after tool completion)
- SessionStart/SessionEnd events
- And more...

## Basic Examples

### Example 1: Simple Observability Session

Enable observability and run a simple specification workflow:

```bash
# Start observability (if not running)
~/.claude/plugins/projspec/scripts/start-observability.sh

# Enable in your project
mkdir -p .projspec
cat > .projspec/projspec.local.md << 'EOF'
---
observability:
  enabled: true
---
EOF

# Start Claude Code and run a command
claude
# In Claude: /projspec:specify "Add dark mode support"
```

### Example 2: View Session Transcripts

To include full chat transcripts in events (for debugging):

```yaml
# In .projspec/projspec.local.md
---
observability:
  enabled: true
  include_chat: true
---
```

Then in the dashboard, click any event with a chat icon to view the full conversation.

### Example 3: Custom Source App Name

Track events from multiple projects by setting unique source_app names:

```yaml
# Project A: .projspec/projspec.local.md
---
observability:
  enabled: true
  source_app: project-a
---
```

```yaml
# Project B: .projspec/projspec.local.md
---
observability:
  enabled: true
  source_app: project-b
---
```

In the dashboard, filter by source_app to see events from specific projects.

### Example 4: Stop and Clean Up

When you're done monitoring:

```bash
# Stop observability processes
~/.claude/plugins/projspec/scripts/stop-observability.sh

# Optional: Purge old events (older than 7 days)
~/.claude/plugins/projspec/scripts/purge-events.sh

# Optional: Purge all events
~/.claude/plugins/projspec/scripts/purge-events.sh --all
```

## Configuration Reference

All configuration options for `.projspec/projspec.local.md`:

```yaml
---
observability:
  # Master toggle (default: false)
  enabled: false

  # Server URL (default: http://localhost:4000)
  server_url: http://localhost:4000

  # Client URL (default: http://localhost:3000)
  client_url: http://localhost:3000

  # Event source identifier (default: projspec)
  source_app: projspec

  # Enable AI event summarization (default: false)
  summarize_events: false

  # Include chat transcripts in events (default: false)
  include_chat: false

  # Maximum chat transcript size in bytes (default: 1MB)
  max_chat_size: 1048576

  # Days to retain events (default: 7)
  retention_days: 7
---
```

## Next Steps

- **Full Specification**: See [spec.md](./spec.md) for complete requirements
- **Implementation Details**: See [plan.md](./plan.md) for technical design
- **Data Model**: See [data-model.md](./data-model.md) for entity definitions
- **Contributing**: See [tasks.md](./tasks.md) for implementation tasks

## Troubleshooting

### Common Issues

**Issue: Bun not found**
```
command not found: bun
```
**Solution**: Install Bun and restart your terminal:
```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc  # or ~/.zshrc
```

**Issue: uv not found**
```
command not found: uv
```
**Solution**: Install uv and restart your terminal:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc  # or ~/.zshrc
```

**Issue: Port already in use**
```
Error: Port 4000 is already in use
```
**Solution**: The script will auto-increment to find an available port. Check the output for the actual port, or stop the conflicting process:
```bash
# Find what's using port 4000
lsof -i :4000

# Or specify a different port in your config
```

**Issue: No events appearing in dashboard**
```
Dashboard shows no events after running commands
```
**Solution**: Check that observability is enabled:
1. Verify `.projspec/projspec.local.md` exists with `enabled: true`
2. Check that the server is running: `status-observability.sh`
3. Verify the server URL matches your config
4. Check server logs: `tail -f ~/.projspec/observability.log`

**Issue: Events not persisting after restart**
```
Events disappear after server restart
```
**Solution**: Events older than `retention_days` are automatically cleaned up on server startup. This is expected behavior. To retain events longer:
```yaml
observability:
  retention_days: 30
```

**Issue: Chat transcripts not appearing**
```
Events show but no chat transcripts available
```
**Solution**: Enable chat transcript inclusion:
```yaml
observability:
  include_chat: true
```
Note: Chat transcripts are only captured for SessionEnd events.

### Getting Help

If you encounter issues not covered here:

1. Check the observability server logs: `~/.projspec/observability.log`
2. Check the status: `status-observability.sh`
3. Verify prerequisites are installed correctly
4. Open an issue on the projspec repository

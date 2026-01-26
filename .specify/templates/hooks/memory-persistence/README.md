# Memory Persistence Hooks

This directory contains Claude Code lifecycle hooks for session state persistence across Claude Code sessions.

## Purpose

These hooks enable:

- **Session continuity**: Resume work where you left off
- **Context preservation**: Save important state before compaction
- **Progress tracking**: Maintain session logs for reference

## Related Hooks

See also:

- **[Auto-Learn Hooks](../auto-learn/README.md)** - Automatic pattern detection and instinct building

## Hooks Overview

| Hook               | Event        | Purpose                           |
|--------------------|--------------|-----------------------------------|
| `session-start.sh` | SessionStart | Load previous session context     |
| `session-end.sh`   | Stop         | Persist session state to log      |
| `pre-compact.sh`   | PreCompact   | Save state before summarization   |

## Storage Locations

All session data is stored in the project repository:

```text
.specify/
├── sessions/           # Session logs
│   ├── YYYY-MM-DD-session.md  # Daily session logs
│   └── compaction-log.md      # Compaction events
├── memory/             # Persistent context
│   └── context.md      # Cross-session context
└── learning/           # Auto-learning data (see auto-learn hooks)
    ├── observations/
    ├── instincts/
    └── pending-analysis/
```

## Configuration

These hooks are configured in `.specify/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/memory-persistence/session-start.sh"}]
    }],
    "Stop": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/memory-persistence/session-end.sh"}]
    }],
    "PreCompact": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/memory-persistence/pre-compact.sh"}]
    }]
  }
}
```

## How It Works

### Session Start

When a new Claude Code session begins:

1. Checks for recent session logs (last 7 days)
2. Checks for learned skills in `.claude/skills/learned/`
3. Outputs status to stderr for context loading

### Session End

When a session ends (Stop event):

1. Creates or updates daily session log
2. Logs timestamp and session summary placeholder
3. Preserves notes for next session

### Pre-Compact

Before Claude Code compacts the conversation:

1. Logs compaction event with timestamp
2. Marks active session with compaction notice
3. Preserves critical context before summarization

## Git Integration

Session logs are markdown files designed to be git-tracked:

- Add `.specify/sessions/` to `.gitignore` for private sessions
- Commit session logs to share progress with team
- Use `.specify/memory/` for shared context

## Troubleshooting

**Hooks not running:**

1. Verify `.specify/settings.json` exists and is valid JSON
2. Check hook scripts have execute permissions: `chmod +x *.sh`
3. Ensure paths are relative to project root

**Permission errors:**

```bash
chmod +x .specify/hooks/memory-persistence/*.sh
```

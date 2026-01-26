# Auto-Learn Hooks

This directory contains hooks for the Spec-Kit auto-learning system. These hooks capture tool usage patterns, detect user corrections, and build atomic "instincts" with confidence scoring.

## Purpose

These hooks enable:

- **Correction detection**: Automatically detect user corrections via regex patterns
- **Pattern capture**: Record tool usage context for analysis
- **Instinct building**: Create atomic learnings with confidence scores
- **Skill evolution**: High-confidence instincts promote to reusable skills

## Related Hooks

See also:

- **[Memory Persistence Hooks](../memory-persistence/README.md)** - Session state persistence
- **[Strategic Compact Hooks](../strategic-compact/README.md)** - Compaction suggestions

## Architecture

```text
SessionStart → Initialize tracking
     ↓
PreToolUse → Capture tool context
     ↓
PostToolUse → Capture results, detect corrections
     ↓
Stop → Queue for analysis (NEVER BLOCKS)
     ↓
PreCompact → Snapshot high-confidence instincts
```

## Hooks Overview

| Hook | File | Purpose | Blocking? |
|------|------|---------|-----------|
| SessionStart | `session-start.sh` | Initialize session tracking, create observation directory | No |
| PreToolUse | `pre-tool-use.sh` | Capture tool context before execution | No |
| PostToolUse | `post-tool-use.sh` | Capture results, detect corrections via regex | No |
| Stop | `session-end.sh` | Queue session for background analysis | **NEVER** |
| PreCompact | `pre-compact.sh` | Snapshot high-confidence instincts | No |

## Correction Detection Patterns

The PostToolUse hook uses fast regex patterns to detect corrections in real-time:

### Direct Negations (NEGATIVE_PREFERENCE, confidence: 0.5)

```regex
^(no,|no |nope|wrong|incorrect)
```

### Redirections (NEGATIVE_PREFERENCE)

```regex
(don't|never|stop) (use|do|add)
(actually|instead),? (use|do|try)
```

### Explicit Corrections (ERROR_CORRECTION, confidence: 0.4)

```regex
(should be|was supposed to be)
(fix|correct|change) (that|this) to
(revert|undo|rollback|that broke)
```

### Project Conventions (PROJECT_CONVENTION, confidence: 0.6)

```regex
(in this (project|repo|codebase))
```

### Preferences (POSITIVE_PREFERENCE, confidence: 0.5)

```regex
(prefer|always|i want|we use)
```

## Data Storage

Session observations are stored in:

```text
.specify/learning/observations/YYYY-MM-DD-{session-id}/
├── tools.jsonl       # Tool use events
├── corrections.jsonl # Detected corrections
└── session-meta.json # Session metadata
```

Instincts are stored in:

```text
.specify/learning/instincts/instinct-{id}.json
```

Pending analysis queue:

```text
.specify/learning/pending-analysis/{session-id}.pending
```

## Confidence Model

| Score | Level | Meaning |
|-------|-------|---------|
| 0.3 | LOW | Single observation, needs reinforcement |
| 0.5 | MEDIUM | Confirmed or project convention |
| 0.7 | HIGH | Multiple reinforcements, skill candidate |
| 0.9 | MAXIMUM | Ready for auto-promotion to skill |

### Confidence Adjustments

- **+0.1**: Reinforced in new session
- **+0.15**: Explicit user confirmation via `/speckit.learn`
- **-0.05**: Decay per 7 days without reinforcement
- **-0.2**: User contradiction detected

## Background Analysis

Sessions are queued for background analysis (never blocking the Stop hook). To process:

```bash
# Process pending sessions
.specify/scripts/bash/analyze-pending.sh

# List pending sessions
.specify/scripts/bash/analyze-pending.sh --list

# Apply confidence decay
.specify/scripts/bash/analyze-pending.sh --decay

# Promote high-confidence instincts
.specify/scripts/bash/analyze-pending.sh --promote

# All operations
.specify/scripts/bash/analyze-pending.sh --all
```

## Instinct Format

```json
{
  "id": "instinct-a1b2c3d4",
  "created_at": "2026-01-26T10:30:00Z",
  "type": "NEGATIVE_PREFERENCE",
  "confidence": 0.5,
  "trigger": {
    "context": "Detected from user correction",
    "tool": "Edit",
    "pattern": ""
  },
  "action": {
    "dont": "Use 'var' for variable declarations",
    "do": "Use 'const' or 'let' instead"
  },
  "evidence": [...],
  "reinforcement_count": 0,
  "last_reinforced": "2026-01-26T10:30:00Z",
  "status": "active"
}
```

## Configuration

These hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/auto-learn/session-start.sh"}],
      "description": "Initialize auto-learning session tracking"
    }],
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/auto-learn/pre-tool-use.sh"}],
      "description": "Capture tool context for auto-learning"
    }],
    "PostToolUse": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/auto-learn/post-tool-use.sh"}],
      "description": "Capture tool results and detect corrections"
    }],
    "Stop": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/auto-learn/session-end.sh"}],
      "description": "Queue session for auto-learning analysis (non-blocking)"
    }],
    "PreCompact": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/auto-learn/pre-compact.sh"}],
      "description": "Snapshot high-confidence instincts before compaction"
    }]
  }
}
```

## Design Principles

1. **Non-blocking**: All hooks complete quickly and never block Claude
2. **Lightweight**: Minimal processing, just capture data
3. **Background analysis**: Heavy processing happens asynchronously
4. **Works everywhere**: Compatible with interactive and `claude -p` headless mode
5. **100% reliable**: Captures all tool calls via hooks (not probabilistic)

## Environment Variables and Hook Input

All hooks receive data from Claude Code in two ways:

### Environment Variables

- `CLAUDE_PROJECT_DIR` - Absolute path to the project root directory (used to find `.specify/` reliably)

### JSON Input via stdin

Hooks receive JSON data via stdin containing:

```json
{
  "session_id": "abc123-def456",
  "transcript_path": "/path/to/conversation.jsonl",
  "cwd": "/current/working/directory",
  "hook_event_name": "SessionStart",
  "source": "startup"
}
```

Key fields:

- `session_id` - Unique session identifier (used for tracking observations)
- `source` - For SessionStart: "startup", "resume", "clear", or "compact"
- `tool_name` - For PreToolUse/PostToolUse: name of the tool being used
- `tool_input` - For PreToolUse/PostToolUse: tool parameters

### Interactive vs Headless Mode

The hooks work identically in both modes:

- **Interactive mode**: Full session with user interaction
- **Headless mode** (`claude -p`): Single prompt execution

The `source` field in SessionStart indicates how the session started, but both modes use the same session ID mechanism.

## Commands

| Command | Purpose |
|---------|---------|
| `/speckit.learn` | Review instincts, promote to skills |
| `/speckit.learn list` | List all active instincts and skills |
| `/speckit.learn status` | Show learning system stats |
| `/speckit.learn analyze` | Trigger background analysis |
| `/speckit.learn promote` | Manually promote high-confidence instincts |

## Troubleshooting

**Hooks not running:**

1. Verify `.claude/settings.json` exists and is valid JSON
2. Check hook scripts have execute permissions: `chmod +x *.sh`
3. Ensure paths are relative to project root

**No corrections detected:**

1. Check that PostToolUse hook is configured
2. Verify correction messages match the regex patterns
3. Check `.specify/learning/observations/*/corrections.jsonl` for captured data

**Permission errors:**

```bash
chmod +x .specify/hooks/auto-learn/*.sh
chmod +x .specify/scripts/bash/analyze-pending.sh
```

## For More Information

See the [Memory Persistence Documentation](../../../docs/memory-persistence.md) for complete details.

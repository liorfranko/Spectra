# Claude Code Status Line Configuration

## When to Use
When setting up a custom status line in Claude Code to display tokens, cost, model info, or other session data.

## Configuration

Add to `.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```

## Example Script

Create `~/.claude/statusline.sh`:
```bash
#!/bin/bash
input=$(cat)
MODEL=$(echo "$input" | jq -r '.model.display_name')
TOKENS=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
COST=$(echo "$input" | jq -r '.cost.total_usd // 0')
echo "[$MODEL] Context: ${TOKENS}% | \$${COST}"
```

Make executable: `chmod +x ~/.claude/statusline.sh`

## Available JSON Fields

| Field | Description |
|-------|-------------|
| `.model.display_name` | Model name (e.g., "Opus 4.5") |
| `.context_window.used_percentage` | Context usage 0-100 |
| `.context_window.remaining_percentage` | Remaining context |
| `.cost.total_usd` | Total session cost |
| `.workspace.current_dir` | Current directory |
| `.session.duration_ms` | Session duration |

## Quick Setup Alternative
Run `/statusline` for interactive configuration.

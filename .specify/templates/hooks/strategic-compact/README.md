# Strategic Compact Hooks

This directory contains Claude Code hooks for suggesting compaction at logical workflow boundaries.

## Purpose

Strategic compaction helps:

- **Preserve focus**: Compact at natural breakpoints, not mid-task
- **Reduce context noise**: Clear completed work at logical boundaries
- **Maintain productivity**: Suggest compaction without disrupting flow

## Hooks Overview

| Hook                 | Event | Purpose                              |
|----------------------|-------|--------------------------------------|
| `suggest-compact.sh` | Stop  | Suggest compaction at logical breaks |

## Workflow Boundaries

The hook detects logical boundaries based on:

1. **Task completion**: All tasks in current phase completed
2. **Feature milestones**: Spec, plan, or implementation complete
3. **Session duration**: Extended sessions with accumulated context
4. **Git commits**: Significant commits made

## Configuration

This hook is configured in `.specify/settings.json`:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": ".specify/hooks/strategic-compact/suggest-compact.sh"}]
    }]
  }
}
```

## How It Works

### Stop Event

When a Claude Code session ends:

1. Checks for logical workflow boundaries
2. Analyzes session activity and completed work
3. Suggests compaction if appropriate
4. Outputs recommendation to stderr

## Customization

You can customize the compaction suggestions by modifying the detection criteria in `suggest-compact.sh`:

- Adjust task completion thresholds
- Add custom milestone detection
- Change session duration triggers

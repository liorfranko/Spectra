---
description: Review and manage auto-learned instincts and skills from session patterns.
argument-hint: "[list|status|analyze|promote] [options]"
---

## User Input

```text
$ARGUMENTS
```

## Overview

The `/projspec.learn` command manages the auto-learning system that captures corrections, patterns, and preferences across sessions. It provides access to:

- **Instincts**: Atomic learnings with confidence scores (stored in `.specify/learning/instincts/`)
- **Skills**: Promoted high-confidence patterns (stored in `.claude/skills/learned/`)

## Subcommands

### `/projspec.learn` (default)

Review current session patterns and any pending instincts. Interactively decide what to save or promote.

### `/projspec.learn list`

List all active instincts and learned skills.

**Actions:**

1. Read all instinct files from `.specify/learning/instincts/`
2. Read all skill files from `.claude/skills/learned/`
3. Display in a formatted table:

```markdown
## Active Instincts

| ID | Type | Confidence | Tool | Created | Reinforced |
|----|------|------------|------|---------|------------|
| instinct-123 | NEGATIVE_PREFERENCE | 0.6 | Edit | 2026-01-25 | 2x |

## Learned Skills

| File | Category | Source |
|------|----------|--------|
| skill-001.md | Error Resolution | Auto-promoted |
```

### `/projspec.learn status`

Show auto-learning system statistics.

**Actions:**

1. Count pending sessions in `.specify/learning/pending-analysis/`
2. Count active instincts by type and confidence level
3. Count learned skills
4. Report recent activity

**Output format:**

```markdown
## Auto-Learning Status

### Session Observations
- Total sessions tracked: 15
- Pending analysis: 2 session(s)
- Last session: 2026-01-26

### Instincts
- Total active: 8
- High confidence (≥0.7): 3 (candidates for promotion)
- Medium confidence (0.5-0.7): 4
- Low confidence (<0.5): 1

### By Type
- NEGATIVE_PREFERENCE: 3
- POSITIVE_PREFERENCE: 2
- PROJECT_CONVENTION: 2
- ERROR_CORRECTION: 1

### Skills
- Total learned skills: 5
- Recently promoted: 2

### Health
- Stale instincts (>7 days): 1
- Archived instincts: 0
```

### `/projspec.learn analyze`

Trigger background analysis of pending sessions.

**Actions:**

1. Run `.specify.specify/scripts/bash/analyze-pending.sh`
2. Report created/reinforced instincts
3. Suggest high-confidence instincts for review

### `/projspec.learn promote`

Manually promote high-confidence instincts to skills.

**Actions:**

1. List instincts with confidence ≥ 0.7
2. For each, present for user review:

```markdown
## Instinct: instinct-abc123

**Type**: PROJECT_CONVENTION
**Confidence**: 0.85
**Reinforced**: 4 times
**Tool Context**: Edit

**What to do**: Use `const` instead of `let` for immutable values
**What to avoid**: Using `var` for any variable declarations

**Promote to skill?** [Yes/No/Skip]
```

Then after review:

1. Create skill file for approved promotions
2. Mark instinct as "promoted"

## Confidence Model

| Score | Level | Meaning |
|-------|-------|---------|
| 0.3 | LOW | Single observation, needs reinforcement |
| 0.5 | MEDIUM | Confirmed or project convention detected |
| 0.7 | HIGH | Multiple reinforcements, skill candidate |
| 0.9 | MAXIMUM | Ready for auto-promotion |

**Confidence adjustments:**

- +0.1: Reinforced in new session
- +0.15: Explicit user confirmation via `/projspec.learn`
- -0.05: Decay per 7 days without reinforcement
- -0.2: User contradiction detected

## File Locations

```text
.specify/
├── learning/
│   ├── observations/        # Raw session data
│   │   └── YYYY-MM-DD-{id}/
│   │       ├── tools.jsonl
│   │       ├── corrections.jsonl
│   │       └── session-meta.json
│   ├── instincts/           # Atomic learnings
│   │   └── instinct-{id}.json
│   ├── pending-analysis/    # Sessions awaiting analysis
│   └── snapshots/           # Pre-compaction backups

.claude/
└── skills/
    └── learned/             # Promoted skills
        └── skill-{id}.md
```

## Instinct JSON Format

```json
{
  "id": "instinct-a1b2c3d4",
  "created_at": "2026-01-26T10:30:00Z",
  "type": "NEGATIVE_PREFERENCE",
  "confidence": 0.5,
  "trigger": {
    "context": "TypeScript file editing",
    "tool": "Edit",
    "pattern": "variable declaration"
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

## Session Pattern Analysis

When running without subcommands, analyze the current session for:

### Error Resolutions

- An error occurred
- Investigation or debugging happened
- A solution was found and applied

### User Corrections

- Claude made an incorrect assumption
- The user corrected the behavior
- Claude adjusted its approach

### Project-Specific Patterns

- Unique to this codebase
- Reflect team conventions
- Would help in future sessions

### Filter Low-Value Patterns

Skip patterns that are:

- Simple typos without broader applicability
- One-time fixes unlikely to recur
- External API issues outside project's control

## Notes

- Instincts are captured automatically via hooks during sessions
- Run `/projspec.learn analyze` to process pending sessions
- High-confidence instincts can be promoted to skills via `/projspec.learn promote`
- Skills in `.claude/skills/learned/` are automatically loaded by Claude Code
- Very high-confidence patterns may be added to CLAUDE.md for project-wide guidance

# Research: Token Count Visibility

## Overview

This research documents the technical decisions made for implementing token count visibility in projspec. The feature tracks **actual LLM API token usage** from Claude Code sessions, providing accurate visibility into token consumption when developing feature specifications.

## Technical Unknowns

### 1. Token Data Source

**Question**: Where can we find actual LLM API token usage data?

**Investigation**:
We explored Claude Code's internal data stores to find actual token metrics:

**Data Sources Examined**:
1. **`~/.claude/stats-cache.json`** - Daily activity stats (message/session counts, not tokens)
2. **`~/.claude/debug/`** - Debug logs with some token references (incomplete)
3. **`~/.claude/projects/[project-path]/*.jsonl`** - **FOUND: Actual API token usage data**

**Discovery**:
Claude Code stores session data in JSONL files under `~/.claude/projects/`. Each session file contains multiple entries, and assistant messages include a `usage` field with actual API token metrics:

```json
{
  "type": "assistant",
  "message": {
    "usage": {
      "input_tokens": 14,
      "cache_creation_input_tokens": 2618,
      "cache_read_input_tokens": 45000,
      "output_tokens": 1
    }
  }
}
```

**Project Path Mapping**:
The project directory name is the working directory path with slashes replaced by dashes:
- Working dir: `/Users/x/proj/worktrees/011-feature`
- Claude dir: `~/.claude/projects/-Users-x-proj-worktrees-011-feature/`

**Decision**: Read actual API usage from Claude Code session files

**Rationale**:
- **100% accurate**: No estimation needed, actual API consumption
- **Already available**: Claude Code stores this data for every session
- **No external dependencies**: Just file reading and JSON parsing
- **Comprehensive**: Includes all token types (input, output, cache)

**Trade-offs**:
- Depends on Claude Code's internal file structure (may change)
- Only available after session ends (not real-time)

---

### 2. Token Counting Algorithm (Superseded)

**Original Question**: How should tokens be estimated for specification artifacts?

**Options Considered**:
1. **Character-based estimation** - tokens ≈ characters / 4
2. **Word-based estimation** - tokens ≈ words × 1.3
3. **tiktoken library** - Exact tokenization

**Original Decision**: Word-based estimation

**SUPERSEDED**: After user clarification, we learned they want actual LLM API token usage, not file content estimates. This changes the approach entirely:

**New Decision**: Read actual API usage from session files (100% accurate)

**Rationale**:
- User's actual requirement was visibility into API token consumption, not artifact size
- Session files contain exact token counts from Claude's API
- No estimation error at all

---

### 3. Integration Point for Token Counting

**Question**: Where should token counting be triggered in the projspec workflow?

**Options Considered**:
1. **PostToolUse hook** - Trigger after file write operations
2. **Stop hook** - Trigger when session completes
3. **Command-level integration** - Add counting to each command's workflow

**Decision**: Stop hook

**Rationale**:
- Deterministic: runs automatically when session ends, no LLM involvement
- Natural timing: session files are complete when session ends
- Cumulative tracking: can aggregate all sessions for the project
- No risk of being forgotten or skipped

**Trade-offs**:
- Token counts not visible until session ends
- Runs on every session end (mitigated by checking for feature directory)

**Sources**:
- Claude Code hook documentation for Stop event

---

### 4. Token File Structure

**Question**: What JSON structure best supports session-based tracking with cumulative totals?

**Options Considered**:
1. **Flat array of sessions**
2. **Nested with summary** (adopted)
3. **Per-session with metrics**

**Decision**: Nested structure with cumulative totals and session history

```json
{
  "feature_id": "011-token-count-visibility-for",
  "total_input_tokens": 1192675,
  "total_output_tokens": 45234,
  "total_cache_read_tokens": 18052939,
  "session_count": 2,
  "last_updated": "2026-01-27T14:30:00Z",
  "sessions": [
    {
      "session_id": "9749a9f2-...",
      "input_tokens": 16247,
      "cache_creation_tokens": 1176428,
      "cache_read_tokens": 18052939,
      "output_tokens": 45000,
      "timestamp": "2026-01-27T12:30:00Z"
    }
  ]
}
```

**Rationale**:
- Provides cumulative totals at top level for quick reference
- Preserves per-session breakdown for analysis
- Includes all token types (input, cache, output)
- Session IDs allow deduplication on subsequent runs

---

### 5. Session Types

**Question**: What types of session files exist?

**Finding**:
Two types of session files in project directories:
1. **Main sessions**: `[UUID].jsonl` (e.g., `9749a9f2-26aa-404f-b410-6c680419eea8.jsonl`)
2. **Subagent sessions**: `agent-[hash].jsonl` (e.g., `agent-a37b3ed.jsonl`)

**Decision**: Include both session types in aggregation

**Rationale**:
- Subagent sessions represent real API consumption
- Users want total visibility into all token usage
- Both file patterns are easy to glob (`*.jsonl`)

---

## Key Findings

1. **Session files contain actual API token usage**: Each assistant message in session JSONL files has a `usage` field with exact token counts from the Claude API.

2. **Project path mapping is consistent**: Claude Code uses a simple `/` to `-` replacement to create project directory names.

3. **Multiple token types tracked**: The API tracks input_tokens, cache_creation_input_tokens, cache_read_input_tokens, and output_tokens.

4. **Session files grow incrementally**: Each API response is appended as a new line, making stream parsing efficient.

5. **Python is better suited than Bash**: JSONL parsing and path manipulation are cleaner in Python.

## Token Metrics Explained

| Metric | Description | Billing Impact |
|--------|-------------|----------------|
| `input_tokens` | Direct new tokens in context | Full input rate |
| `cache_creation_input_tokens` | Tokens added to prompt cache | Full input rate |
| `cache_read_input_tokens` | Tokens served from cache | ~90% cheaper rate |
| `output_tokens` | Tokens generated by model | Output rate |

## Recommendations

1. Create `scripts/count-tokens.py` as the main implementation (Python for robust JSONL handling)
2. Create Stop hook (`hooks/stop-count-tokens.md`) to call the script
3. Read actual API usage from `~/.claude/projects/[project-path]/*.jsonl`
4. Track cumulative totals with per-session history
5. Implement session deduplication to avoid counting same session twice
6. Handle missing/corrupted session files gracefully

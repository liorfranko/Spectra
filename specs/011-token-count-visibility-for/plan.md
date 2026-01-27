# Implementation Plan: Token Count Visibility

**Feature ID:** 011-token-count-visibility-for
**Branch:** `011-token-count-visibility-for`
**Created:** 2026-01-27
**Status:** Draft

---

## Summary

Add automatic token usage tracking via a Stop hook that reads actual LLM API token consumption from Claude Code session files and persists to `tokens.json` in the feature directory. When any projspec session ends, the hook aggregates token usage from `~/.claude/projects/` and updates the token file.

**Technical Approach:** Implement a Stop hook with a Python script (`count-tokens.py`) that reads Claude Code's session JSONL files to extract actual API token usage (input_tokens, output_tokens, cache metrics). The hook executes deterministically without LLM involvement, providing 100% accurate token counts.

---

## Technical Context

### Language & Runtime

| Aspect | Value |
|--------|-------|
| Primary Language | Python 3.8+ |
| Runtime/Version | Python 3.8+ (standard library only) |
| Package Manager | None (no external packages) |

### Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Python | 3.8+ | Script execution |
| json (stdlib) | - | JSONL parsing and JSON output |
| os (stdlib) | - | Path manipulation |
| glob (stdlib) | - | Session file discovery |
| datetime (stdlib) | - | ISO 8601 timestamp generation |

### Platform & Environment

| Aspect | Value |
|--------|-------|
| Target Platform | Claude Code plugin (projspec) |
| Minimum Requirements | Python 3.8+, macOS or Linux, Git |
| Environment Variables | `CLAUDE_PLUGIN_ROOT` (provided by Claude Code) |
| Data Source | `~/.claude/projects/[project-path]/*.jsonl` |

### Constraints

- Read actual API usage from Claude Code session files (100% accuracy)
- Project path mapping: convert cwd to dash-separated format
- `tokens.json` must reside within the feature directory root
- JSON format for universal tooling compatibility
- Stop hook aggregates all sessions when triggered (cumulative)
- Deterministic execution via Python script (no LLM involvement)
- Must handle missing or corrupted session files gracefully

### Testing Approach

| Aspect | Value |
|--------|-------|
| Test Framework | pytest |
| Test Location | projspec/plugins/projspec/tests/ |
| Required Coverage | Critical paths only |

**Test Types**:
- Unit: Yes - test count-tokens.py functions with mock session data
- Integration: Yes - test token aggregation with fixture JSONL files
- E2E: No - manual validation via session end trigger

---

## Constitution Check

**Constitution Source**: `projspec/plugins/projspec/memory/constitution.md`
**Check Date**: 2026-01-27

### Principle Compliance

| Principle | Description | Status | Notes |
|-----------|-------------|--------|-------|
| I. User-Centric Design | Features prioritize user experience | COMPLIANT | Token visibility helps users understand actual API usage |
| II. Maintainability First | Clear, explicit code | COMPLIANT | Simple Python script with clear functions |
| III. Incremental Delivery | Small, testable increments | COMPLIANT | Single script + hook |
| IV. Documentation as Code | Documentation is first-class | COMPLIANT | This plan documents the feature fully |
| V. Test-Driven Confidence | Tests accompany new functionality | COMPLIANT | pytest tests planned for count-tokens.py |

### Compliance Details

#### Principles with Full Compliance (PASS)

- **I. User-Centric Design**: Token counting provides visibility into actual LLM API consumption, helping users understand costs.
- **II. Maintainability First**: Implementation uses a single, well-documented Python script with clear functions.
- **III. Incremental Delivery**: Feature can be implemented and tested independently of other projspec features.
- **IV. Documentation as Code**: Complete specification, research, data model, and plan created.
- **V. Test-Driven Confidence**: Pytest tests will validate token extraction and aggregation logic.

### Gate Status

**Constitution Check Result**: PASS

**Criteria**: All principles are COMPLIANT with no violations.

**Action Required**: None - proceed to project structure.

---

## Project Structure

### Documentation Layout

```
specs/011-token-count-visibility-for/
├── spec.md              # Feature specification (requirements, scenarios)
├── research.md          # Technical research and decisions
├── data-model.md        # Entity definitions and schemas
├── plan.md              # This implementation plan
├── quickstart.md        # Getting started guide
├── tasks.md             # Implementation task list
└── checklists/          # Requirement validation checklists
```

### Source Code Layout

```
projspec/plugins/projspec/
├── scripts/
│   ├── common.sh              # Existing shared utilities
│   ├── count-tokens.py        # NEW: Token counting from session files
│   └── ...
├── hooks/
│   ├── hooks.json             # MODIFY: Register Stop hook
│   └── stop-count-tokens.md   # NEW: Stop hook definition
└── tests/
    └── test_count_tokens.py   # NEW: Token counting tests
```

### File Mapping

| File Path | Purpose | Spec Requirements |
|-----------|---------|-------------------|
| scripts/count-tokens.py | Read session files and aggregate usage | FR-001, FR-002, FR-003 |
| hooks/stop-count-tokens.md | Stop hook to trigger counting | FR-004, US-001 |
| hooks/hooks.json | Hook registration | FR-004 |
| tests/test_count_tokens.py | Test token extraction and aggregation | SC-001, SC-002, SC-003 |

### New Files to Create

| File Path | Type | Description |
|-----------|------|-------------|
| scripts/count-tokens.py | source | Main token counting implementation |
| hooks/stop-count-tokens.md | hook | Stop hook that calls count-tokens.py |
| tests/test_count_tokens.py | test | pytest tests for token counting |

### Files to Modify

| File Path | Type | Description |
|-----------|------|-------------|
| hooks/hooks.json | config | Add Stop hook registration |

---

## Complexity Tracking

### Complexity Score

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Lines of Code (estimated) | ~200 | 500 | OK |
| Number of Files | 4 (2 new, 1 test, 1 modified) | 10 | OK |
| External Dependencies | 0 (Python stdlib only) | 2 | OK |

### Violation Justifications

No violations. All metrics within acceptable limits.

---

## Implementation Notes

### Key Decisions

- **Read actual API usage**: Session files contain real token metrics from the Claude API. No estimation needed - 100% accurate.
- **Python implementation**: Better suited for JSONL parsing and path manipulation than Bash. Uses only stdlib.
- **Stop hook integration**: Deterministic execution via Claude Code Stop hook. Runs automatically when any session ends.
- **Cumulative aggregation**: Each hook run reads all session files and merges with existing tokens.json. Avoids duplicate session entries.
- **Project path mapping**: Convert `/path/to/project` to `-path-to-project` to locate session files.

### Session File Structure

Claude Code stores session data in `~/.claude/projects/[project-path]/[session-id].jsonl`:

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

### Algorithm Overview

1. **Find project directory**: Convert cwd to `~/.claude/projects/-Path-With-Dashes/`
2. **Discover session files**: Glob for `*.jsonl` in project directory
3. **Parse each session**: Read JSONL, extract `usage` from assistant messages, sum totals
4. **Load existing data**: Read tokens.json if exists
5. **Merge sessions**: Add new sessions, skip duplicates by session_id
6. **Write output**: Update tokens.json with cumulative totals

### Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Session files not found | Low | Medium | Graceful handling, log warning, continue |
| Large session files | Low | Low | Stream parsing (line by line), no memory issues |
| JSON corruption | Low | Medium | Validate JSON structure on read; reset to empty on parse failure |
| Missing project directory | Medium | Low | Exit cleanly if not in a feature context |

### Open Questions

- [x] Token count file format → Resolved: JSON
- [x] Counting algorithm → Resolved: Read actual API usage from session files
- [x] Display behavior → Resolved: file-only
- [x] History management → Resolved: cumulative with session deduplication
- [x] Data source → Resolved: `~/.claude/projects/[project-path]/*.jsonl`

---

## Approval

| Role | Approver | Date | Status |
|------|----------|------|--------|
| Technical Lead | - | - | PENDING |
| Stakeholder | - | - | PENDING |

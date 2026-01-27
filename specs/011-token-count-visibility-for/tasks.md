# Tasks: Token Count Visibility

Generated: 2026-01-27
Feature: specs/011-token-count-visibility-for
Source: plan.md, spec.md, data-model.md, research.md

## Overview

- Total Tasks: 18
- Phases: 4
- Estimated Complexity: Low-Medium
- Parallel Execution Groups: 2

## Task Legend

- `[ ]` - Incomplete task
- `[x]` - Completed task
- `[P]` - Can execute in parallel with other [P] tasks in same group
- `CHECKPOINT` - Review point before proceeding to next phase

---

## Phase 1: Setup

Verify directory structure and existing files.

- [ ] T001 Verify projspec plugin directory structure exists (projspec/plugins/projspec/)
- [ ] T002 Confirm scripts/ directory is present and writable (projspec/plugins/projspec/scripts/)
- [ ] T003 Confirm hooks/ directory exists with hooks.json (projspec/plugins/projspec/hooks/)

---

## Phase 2: Core Implementation

Implement the token counting script that reads Claude session files.

### Script Implementation

- [ ] T100 Create count-tokens.py script skeleton with imports and main() (scripts/count-tokens.py)
- [ ] T101 Implement get_project_path() to convert cwd to Claude project directory path (scripts/count-tokens.py)
- [ ] T102 Implement find_session_files() to locate all *.jsonl files in project directory (scripts/count-tokens.py)
- [ ] T103 Implement parse_session_file() to extract usage data from JSONL entries (scripts/count-tokens.py)
- [ ] T104 Implement aggregate_session_usage() to sum token metrics per session (scripts/count-tokens.py)
- [ ] T105 Implement find_feature_dir() to detect specs/NNN-feature/ directory from cwd (scripts/count-tokens.py)
- [ ] T106 Implement load_existing_tokens() to read existing tokens.json if present (scripts/count-tokens.py)
- [ ] T107 Implement merge_session_data() to add new sessions avoiding duplicates (scripts/count-tokens.py)
- [ ] T108 Implement write_tokens_json() to output final JSON with totals (scripts/count-tokens.py)
- [ ] T109 Implement main() to orchestrate: find project → parse sessions → merge → write (scripts/count-tokens.py)

### Checkpoint

- [ ] T110 CHECKPOINT: Verify count-tokens.py runs standalone and produces valid tokens.json

---

## Phase 3: Hook Integration

Create the Stop hook to trigger token counting.

- [ ] T200 Create stop-count-tokens.md hook definition file (hooks/stop-count-tokens.md)
- [ ] T201 Update hooks.json to register the Stop hook (hooks/hooks.json)

### Checkpoint

- [ ] T202 CHECKPOINT: Verify Stop hook triggers after session ends and updates tokens.json

---

## Phase 4: Testing & Validation

Create tests and validate the feature.

- [ ] T300 [P] Create test fixture: mock ~/.claude/projects/ directory with sample session files
- [ ] T301 [P] Write pytest test: get_project_path() correctly converts paths to Claude format
- [ ] T302 [P] Write pytest test: parse_session_file() extracts usage data correctly
- [ ] T303 Write pytest test: aggregate_session_usage() sums tokens correctly
- [ ] T304 Write pytest test: merge_session_data() avoids duplicate sessions
- [ ] T305 Write pytest test: tokens.json is created with valid structure
- [ ] T306 Run end-to-end test: work in feature dir, end session, verify tokens.json updated

### Checkpoint

- [ ] T307 CHECKPOINT: All tests pass, feature ready for PR

---

## Dependencies

### Phase Dependencies

| Phase | Depends On | Description |
|-------|------------|-------------|
| Phase 1: Setup | None | Initial verification |
| Phase 2: Core Implementation | Phase 1 | Requires directories to exist |
| Phase 3: Hook Integration | Phase 2 | Requires count-tokens.py to exist |
| Phase 4: Testing | Phase 2, Phase 3 | Requires implementation complete |

### Task Dependencies

| Task | Blocked By | Notes |
|------|------------|-------|
| T100 | T001, T002 | Script requires directory to exist |
| T101-T109 | T100 | Functions added to script skeleton |
| T110 | T109 | Checkpoint after script complete |
| T200-T201 | T110 | Hook created after script works |
| T202 | T200, T201 | Hook checkpoint |
| T300-T302 | T110 | Tests can run after implementation |
| T303-T306 | T202 | Full tests after hook integration |
| T307 | T303-T306 | Final checkpoint |

### Parallel Execution Groups

| Group | Tasks | Description |
|-------|-------|-------------|
| A | T001, T002, T003 | Initial directory verification |
| B | T300, T301, T302 | Independent test setup and basic tests |

---

## Dependency Diagram

```
PHASE 1: SETUP
┌─────────────────────────────────────────┐
│  T001 ──┬──> T100                       │
│  T002 ──┤                               │
│  T003 ──┘                               │
└─────────────────────────────────────────┘
                    │
                    ▼
PHASE 2: CORE IMPLEMENTATION
┌─────────────────────────────────────────────────────────────┐
│                      T100 (skeleton)                         │
│                           │                                  │
│                           ▼                                  │
│                    T101 ─ T109                               │
│                    (functions)                               │
│                           │                                  │
│                           ▼                                  │
│                   T110 CHECKPOINT                            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
PHASE 3: HOOK INTEGRATION
┌─────────────────────────────────────────┐
│         T200 (hook file)                │
│              │                          │
│              ▼                          │
│         T201 (hooks.json)               │
│              │                          │
│              ▼                          │
│         T202 CHECKPOINT                 │
└──────────────┬──────────────────────────┘
               │
               ▼
PHASE 4: TESTING
┌─────────────────────────────────────────┐
│    T300-T302 [P] (basic tests)          │
│              │                          │
│              ▼                          │
│         T303-T306                       │
│      (integration tests)                │
│              │                          │
│              ▼                          │
│         T307 CHECKPOINT                 │
└─────────────────────────────────────────┘
```

---

## Requirement Traceability

| Requirement | Tasks |
|-------------|-------|
| FR-001: Token Count Persistence | T108, T109 |
| FR-002: Session-Based Token Aggregation | T101, T102, T103, T104 |
| FR-003: Token Count File Format | T108, T305 |
| FR-004: Automatic Token Counting via Stop Hook | T200, T201, T202 |
| FR-005: Cumulative Total Calculation | T107, T108 |
| US-001: View Token Usage Per Spec | T200, T201, T306 |
| US-002: Access Historical Token Counts | T106, T107, T108 |
| SC-001: Token Count File Created | T305 |
| SC-002: Count Accuracy | T303 |
| SC-003: File Format Validity | T305 |

---

## Implementation Notes

### Why Python Instead of Bash

The implementation uses Python because:
1. JSON parsing is more robust (session files can be large)
2. JSONL processing is easier with Python's json module
3. Path manipulation for project directory mapping
4. Better error handling for malformed session data

### Key Algorithm: Project Path Mapping

```python
def get_project_path(cwd: str) -> str:
    """Convert /Users/x/proj to ~/.claude/projects/-Users-x-proj"""
    project_name = cwd.replace('/', '-')
    return os.path.expanduser(f"~/.claude/projects/{project_name}")
```

### Session File Processing

Each session file contains multiple JSONL entries. Only entries with `"type": "assistant"` contain usage data:

```python
for line in open(session_file):
    entry = json.loads(line)
    if entry.get('type') == 'assistant' and 'message' in entry:
        usage = entry['message'].get('usage', {})
        # Aggregate: input_tokens, cache_creation_input_tokens, etc.
```

# Research: End-to-End Tests for projspec Plugin

**Branch**: `006-add-e2e-tests` | **Date**: 2026-01-26

## Research Summary

This document captures research findings from analyzing the spec-kit test suite at `/Users/liorfr/Development/spec-kit/tests` to establish patterns for the projspec plugin E2E tests.

## Key Decisions

### 1. Test Framework Selection

**Decision**: pytest with custom markers and fixtures
**Rationale**:
- Aligns with existing Python tooling in the project
- pytest's fixture system enables clean test setup/teardown
- Custom markers (`@pytest.mark.stage(N)`) enable stage filtering
- Built-in timeout support via pytest-timeout

**Alternatives Considered**:
- unittest: Less flexible, no built-in fixture scoping
- nose2: Less widely used, smaller ecosystem

### 2. Helper Class Architecture

**Decision**: Four helper classes - ClaudeRunner, FileVerifier, GitVerifier, E2EProject
**Rationale**:
- Clear separation of concerns
- Each class has single responsibility
- Matches proven spec-kit patterns
- Enables reuse across test stages

**ClaudeRunner Responsibilities**:
- Execute `claude -p <prompt>` with timeout handling
- Capture stdout/stderr to log files
- Support debug mode with streaming output
- Return structured ClaudeResult dataclass

**FileVerifier Responsibilities**:
- Assert file/directory existence
- Assert file content matches patterns (regex)
- Assert minimum line counts
- Find files by pattern list

**GitVerifier Responsibilities**:
- Assert repository state
- Assert branch patterns
- Assert worktree existence
- Get worktree paths for stage discovery

**E2EProject Responsibilities**:
- Create timestamped test project directories
- Copy fixture files
- Initialize git repository
- Manage log file paths

### 3. Stage Dependency Model

**Decision**: Sequential stages with skip-on-failure
**Rationale**:
- projspec workflow is inherently sequential (init → specify → plan → tasks → implement)
- Skipping dependent stages on failure prevents cascading errors
- StageTracker singleton tracks first failure

**Stage Dependencies**:
```
Stage 1 (init) ← Stage 2 (constitution) ← Stage 3 (specify) ← Stage 4 (plan) ← Stage 5 (tasks) ← Stage 6 (implement)
```

### 4. Test Project Management

**Decision**: Session-scoped project persisted for debugging
**Rationale**:
- Single project instance per test run ensures stage continuity
- Timestamped directories prevent collisions
- Preserved artifacts enable post-mortem debugging
- Log files organized by run ID and stage name

**Directory Format**: `tests/e2e/output/test-projects/YYYYMMDD-HHMMSS-todo-app/`
**Log Format**: `tests/e2e/output/logs/YYYYMMDD-HHMMSS/NN-stage-name.log`

### 5. Claude CLI Integration

**Decision**: Use `claude -p` with allowed tools whitelist
**Rationale**:
- Non-interactive mode suitable for automated testing
- Allowed tools list restricts scope for safety
- Timeout handling prevents indefinite hangs

**Allowed Tools**: `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `LS`, `Task`, `WebFetch`, `WebSearch`, `NotebookEdit`, `Skill`

**Model**: claude-sonnet-4-5@20250929 (fast, reliable)

### 6. CLI Options Design

**Decision**: Three CLI options - `--stage`, `--e2e-debug`, `--timeout-all`
**Rationale**:
- `--stage N` or `--stage N-M` enables targeted testing
- `--e2e-debug` enables real-time output for troubleshooting
- `--timeout-all` allows tuning for slow environments

### 7. Default Timeouts

**Decision**: Stage-specific defaults with generous margins
**Rationale**:
- Claude API response times vary significantly
- Different stages have different complexity
- Defaults prevent flaky tests while catching real hangs

| Stage | Default Timeout |
|-------|----------------|
| 1 (init) | 120s |
| 2 (constitution) | 600s |
| 3 (specify) | 600s |
| 4 (plan) | 600s |
| 5 (tasks) | 600s |
| 6 (implement) | 1800s |

## Resolved Clarifications

### Q: How to handle test project cleanup?
**A**: Projects are NOT cleaned up automatically. They remain in `tests/e2e/output/test-projects/` for debugging. Users can manually delete old runs or add a cleanup script later.

### Q: How to handle Claude authentication failures?
**A**: Tests will fail fast with clear error message indicating Claude CLI is not authenticated. This is a precondition check rather than runtime handling.

### Q: How to find spec/plan files across worktrees?
**A**: GitVerifier's `get_worktree_path()` searches for worktree directories matching patterns like `worktrees/NNN-*`. Tests search multiple potential locations.

### Q: What fixture files are needed?
**A**: Minimal fixture - just a README.md or empty directory is sufficient since tests start with `specify init`. The fixture provides a clean starting point.

## References

- spec-kit test suite: `/Users/liorfr/Development/spec-kit/tests`
- pytest documentation: https://docs.pytest.org/
- pytest-timeout: https://pypi.org/project/pytest-timeout/

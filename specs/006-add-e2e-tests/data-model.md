# Data Model: End-to-End Tests for projspec Plugin

**Branch**: `006-add-e2e-tests` | **Date**: 2026-01-26

## Entity Definitions

### ClaudeResult

Immutable data class containing execution results from a Claude CLI command.

| Field | Type | Description |
|-------|------|-------------|
| success | bool | True if exit code is 0 and not timed out |
| stdout | str | Captured standard output |
| stderr | str | Captured standard error |
| timed_out | bool | True if command exceeded timeout |
| duration | float | Execution time in seconds |
| exit_code | int | Process exit code (0 = success) |

**Validation Rules**:
- `success` must be True only when `exit_code == 0` AND `timed_out == False`
- `duration` must be >= 0

### E2EConfig

Configuration object parsed from pytest CLI options.

| Field | Type | Description |
|-------|------|-------------|
| stage_filter | tuple[int, int] \| None | Range of stages to run (start, end inclusive) |
| debug | bool | Enable debug mode with streaming output |
| timeout_override | int \| None | Override all stage timeouts (seconds) |

**Validation Rules**:
- `stage_filter` range must be 1-6 inclusive
- `timeout_override` must be positive if set

### StageStatus

Enum representing test stage execution status.

| Value | Description |
|-------|-------------|
| PENDING | Stage not yet executed |
| PASSED | Stage completed successfully |
| FAILED | Stage failed with error |
| SKIPPED | Stage skipped due to dependency failure |

### StageTracker

Singleton tracking stage execution across test session.

| Field | Type | Description |
|-------|------|-------------|
| first_failure | int \| None | Stage number of first failure (None if all passed) |
| stage_status | dict[int, StageStatus] | Status of each stage |

**State Transitions**:
```
PENDING → PASSED (test passes)
PENDING → FAILED (test fails)
PENDING → SKIPPED (dependency failed)
```

**Business Rule**: If stage N fails, all stages > N are automatically SKIPPED.

### E2EProject

Manages test project lifecycle including directory creation and git initialization.

| Field | Type | Description |
|-------|------|-------------|
| project_name | str | Base name for test project (e.g., "todo-app") |
| project_path | Path \| None | Absolute path to created project (set after setup()) |
| log_dir | Path \| None | Timestamped log directory for this run |
| fixture_dir | Path | Source fixture directory (tests/fixtures/{project_name}/) |
| output_dir | Path | Base output directory (tests/e2e/output/) |
| timestamp | str | Run timestamp in YYYYMMDD-HHMMSS format |

**Validation Rules**:
- `project_path` is None until `setup()` is called
- `project_name` must be a valid directory name

### ClaudeRunner

Wrapper for executing Claude CLI commands with timeout handling.

| Field | Type | Description |
|-------|------|-------------|
| work_dir | Path | Working directory for command execution |
| log_dir | Path | Directory for log file output |
| debug | bool | Enable streaming output to terminal |
| timeout_override | int \| None | Override default timeouts |

**Constants**:
```python
DEFAULT_TIMEOUT_INIT = 120
DEFAULT_TIMEOUT_CONSTITUTION = 600
DEFAULT_TIMEOUT_SPECIFY = 600
DEFAULT_TIMEOUT_PLAN = 600
DEFAULT_TIMEOUT_TASKS = 600
DEFAULT_TIMEOUT_IMPLEMENT = 1800
MODEL = "claude-sonnet-4-5@20250929"
ALLOWED_TOOLS = ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "LS", "Task", "WebFetch", "WebSearch", "NotebookEdit", "Skill"]
```

### FileVerifier

Utility for asserting file existence and content.

| Field | Type | Description |
|-------|------|-------------|
| base_path | Path | Base directory for relative path resolution |

**Methods**:
| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| assert_exists | path: str, description: str | None | Raises AssertionError if file not found |
| assert_dir_exists | path: str, description: str | None | Raises AssertionError if directory not found |
| assert_contains | path: str, pattern: str, description: str | None | Raises AssertionError if pattern not found |
| assert_not_empty | path: str, description: str | None | Raises AssertionError if file is empty |
| assert_min_lines | path: str, min_lines: int, description: str | None | Raises AssertionError if file has fewer lines |
| count_pattern | path: str, pattern: str | int | Count regex matches in file |
| find_file | patterns: list[str] | Path \| None | Find first existing file from pattern list |

### GitVerifier

Utility for asserting git repository state.

| Field | Type | Description |
|-------|------|-------------|
| repo_path | Path | Path to git repository root |

**Methods**:
| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| assert_is_repo | | None | Raises AssertionError if not a git repo |
| assert_branch_matches | pattern: str, description: str | None | Raises if branch doesn't match pattern |
| assert_worktree_exists | pattern: str | None | Raises if no worktree matches pattern |
| get_worktree_path | pattern: str | Path \| None | Return path to first matching worktree |
| assert_min_commits | min_commits: int, description: str | None | Raises if fewer commits exist |
| assert_commits_with_pattern | pattern: str, min_count: int, description: str | None | Raises if insufficient matching commits |
| get_commit_count | | int | Return total commit count |
| count_worktrees | | int | Return worktree count |

## Relationships

```
E2EProject ──creates──> test project directory
     │
     └──provides──> Path to ClaudeRunner, FileVerifier, GitVerifier
                         │
                         v
                    ClaudeRunner ──executes──> Claude CLI
                         │
                         v
                    ClaudeResult
```

## Directory Structure Relationships

```
tests/e2e/output/
├── logs/
│   └── {timestamp}/           # E2EProject.log_dir
│       ├── 01-init.log
│       ├── 02-constitution.log
│       └── ...
└── test-projects/
    └── {timestamp}-{project_name}/  # E2EProject.project_path
        ├── .git/
        ├── .claude/
        ├── .specify/
        ├── worktrees/
        │   └── NNN-feature-name/
        │       └── specs/
        │           └── NNN-feature-name/
        │               ├── spec.md
        │               ├── plan.md
        │               └── tasks.md
        └── ...
```

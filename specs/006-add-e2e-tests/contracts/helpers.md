# Helper Class Contracts

**Branch**: `006-add-e2e-tests` | **Date**: 2026-01-26

This document defines the public interface contracts for E2E test helper classes.

## ClaudeRunner

### Constructor

```python
def __init__(
    self,
    work_dir: Path,
    log_dir: Path,
    debug: bool = False,
    timeout_override: int | None = None,
) -> None:
    """
    Initialize ClaudeRunner with execution context.

    Args:
        work_dir: Working directory for command execution
        log_dir: Directory for writing log files
        debug: Enable streaming output to terminal
        timeout_override: Override all default timeouts (seconds)
    """
```

### run()

```python
def run(
    self,
    prompt: str,
    timeout: int | None = None,
    log_file: Path | str | None = None,
) -> ClaudeResult:
    """
    Execute Claude CLI with given prompt.

    Args:
        prompt: The prompt to send to Claude (e.g., "/speckit.specify ...")
        timeout: Timeout in seconds (uses stage default if None)
        log_file: Path to write captured output

    Returns:
        ClaudeResult with execution details

    Behavior:
        - Runs: claude -p "{prompt}" --allowedTools '{...}' --model {MODEL}
        - Captures stdout/stderr to log_file if provided
        - Streams output if debug=True
        - Returns ClaudeResult with success, stdout, stderr, timed_out, duration, exit_code
    """
```

### get_stage_timeout()

```python
@staticmethod
def get_stage_timeout(stage: int) -> int:
    """
    Get default timeout for a stage.

    Args:
        stage: Stage number (1-6)

    Returns:
        Default timeout in seconds

    Raises:
        ValueError: If stage is not 1-6
    """
```

## FileVerifier

### Constructor

```python
def __init__(self, base_path: Path) -> None:
    """
    Initialize FileVerifier with base path for resolution.

    Args:
        base_path: Base directory for resolving relative paths
    """
```

### assert_exists()

```python
def assert_exists(self, path: str, description: str) -> None:
    """
    Assert file exists.

    Args:
        path: Relative or absolute path to file
        description: Human-readable description for error message

    Raises:
        AssertionError: "Expected {description} to exist at {full_path}"
    """
```

### assert_dir_exists()

```python
def assert_dir_exists(self, path: str, description: str) -> None:
    """
    Assert directory exists.

    Args:
        path: Relative or absolute path to directory
        description: Human-readable description for error message

    Raises:
        AssertionError: "Expected {description} directory to exist at {full_path}"
    """
```

### assert_contains()

```python
def assert_contains(self, path: str, pattern: str, description: str) -> None:
    """
    Assert file contains content matching regex pattern.

    Args:
        path: Path to file
        pattern: Regex pattern to search for
        description: What the pattern represents

    Raises:
        AssertionError: "Expected {description} in {path}, pattern '{pattern}' not found"
    """
```

### assert_not_empty()

```python
def assert_not_empty(self, path: str, description: str) -> None:
    """
    Assert file is not empty.

    Args:
        path: Path to file
        description: Human-readable description

    Raises:
        AssertionError: "Expected {description} at {path} to not be empty"
    """
```

### assert_min_lines()

```python
def assert_min_lines(self, path: str, min_lines: int, description: str) -> None:
    """
    Assert file has at least N lines.

    Args:
        path: Path to file
        min_lines: Minimum line count
        description: Human-readable description

    Raises:
        AssertionError: "Expected {description} at {path} to have >= {min_lines} lines, got {actual}"
    """
```

### count_pattern()

```python
def count_pattern(self, path: str, pattern: str) -> int:
    """
    Count regex matches in file.

    Args:
        path: Path to file
        pattern: Regex pattern to count

    Returns:
        Number of matches
    """
```

### find_file()

```python
def find_file(self, patterns: list[str]) -> Path | None:
    """
    Find first existing file from list of patterns.

    Args:
        patterns: List of paths/glob patterns to check

    Returns:
        Path to first existing file, or None if no match
    """
```

## GitVerifier

### Constructor

```python
def __init__(self, repo_path: Path) -> None:
    """
    Initialize GitVerifier with repository path.

    Args:
        repo_path: Path to git repository root
    """
```

### assert_is_repo()

```python
def assert_is_repo(self) -> None:
    """
    Assert directory is a valid git repository.

    Raises:
        AssertionError: "Expected {repo_path} to be a git repository"
    """
```

### assert_branch_matches()

```python
def assert_branch_matches(self, pattern: str, description: str) -> None:
    """
    Assert current branch matches regex pattern.

    Args:
        pattern: Regex pattern for branch name
        description: Human-readable description

    Raises:
        AssertionError: "Expected {description}, branch '{actual}' doesn't match '{pattern}'"
    """
```

### assert_worktree_exists()

```python
def assert_worktree_exists(self, pattern: str) -> None:
    """
    Assert at least one worktree matches pattern.

    Args:
        pattern: Regex pattern for worktree path

    Raises:
        AssertionError: "Expected worktree matching '{pattern}', none found"
    """
```

### get_worktree_path()

```python
def get_worktree_path(self, pattern: str) -> Path | None:
    """
    Get path to first worktree matching pattern.

    Args:
        pattern: Regex pattern for worktree path

    Returns:
        Path to matching worktree, or None if not found
    """
```

### assert_min_commits()

```python
def assert_min_commits(self, min_commits: int, description: str) -> None:
    """
    Assert repository has at least N commits.

    Args:
        min_commits: Minimum commit count
        description: Human-readable description

    Raises:
        AssertionError: "Expected {description}, got {actual} commits"
    """
```

### get_commit_count()

```python
def get_commit_count(self) -> int:
    """
    Get total commit count in repository.

    Returns:
        Number of commits
    """
```

### count_worktrees()

```python
def count_worktrees(self) -> int:
    """
    Count worktrees in repository.

    Returns:
        Number of worktrees (including main)
    """
```

## E2EProject

### Constructor

```python
def __init__(self, project_name: str = "todo-app") -> None:
    """
    Initialize E2EProject.

    Args:
        project_name: Base name for test project directory
    """
```

### setup()

```python
def setup(self) -> Path:
    """
    Create and initialize test project.

    Returns:
        Path to created project directory

    Behavior:
        1. Create timestamped directory under tests/e2e/output/test-projects/
        2. Create log directory under tests/e2e/output/logs/
        3. Copy fixture files if fixture_dir exists
        4. Initialize git repository with test credentials
        5. Create initial commit
    """
```

### get_log_file()

```python
def get_log_file(self, stage_name: str) -> Path:
    """
    Get log file path for a stage.

    Args:
        stage_name: Stage identifier (e.g., "01-init", "03-specify")

    Returns:
        Path to log file (e.g., logs/YYYYMMDD-HHMMSS/01-init.log)
    """
```

## ClaudeResult

### Fields

```python
@dataclass(frozen=True)
class ClaudeResult:
    """Immutable result from Claude CLI execution."""

    success: bool
    stdout: str
    stderr: str
    timed_out: bool
    duration: float
    exit_code: int
```

## E2EConfig

### Fields

```python
@dataclass(frozen=True)
class E2EConfig:
    """Configuration from pytest CLI options."""

    stage_filter: tuple[int, int] | None  # (start, end) inclusive
    debug: bool
    timeout_override: int | None
```

### should_run_stage()

```python
def should_run_stage(self, stage: int) -> bool:
    """
    Check if stage should run based on filter.

    Args:
        stage: Stage number to check

    Returns:
        True if stage is in filter range (or no filter set)
    """
```

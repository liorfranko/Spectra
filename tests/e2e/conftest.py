"""E2E test configuration for projspec.

This module provides shared fixtures, configuration, and utilities
for end-to-end tests that validate the complete projspec workflow
using Claude Code subprocess execution.
"""

from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Generator

import pytest

from .helpers import ClaudeRunner, E2EProject, FileVerifier, GitVerifier


class StageStatus(Enum):
    """Enum representing test stage execution status.

    Used by StageTracker to track the execution state of each test stage
    in the E2E test pipeline. Stages progress through these states during
    test execution.

    Attributes:
        PENDING: Stage not yet executed.
        PASSED: Stage completed successfully.
        FAILED: Stage failed with an error.
        SKIPPED: Stage skipped due to dependency failure.
    """

    PENDING = "pending"
    """Stage not yet executed."""

    PASSED = "passed"
    """Stage completed successfully."""

    FAILED = "failed"
    """Stage failed with error."""

    SKIPPED = "skipped"
    """Stage skipped due to dependency failure."""


class StageTracker:
    """Singleton tracking stage execution across test session.

    This class implements a singleton pattern to maintain consistent state
    across all test stages during an E2E test session. It tracks which stages
    have passed, failed, or been skipped, and enforces the business rule that
    if stage N fails, all stages > N are automatically skipped.

    Attributes:
        first_failure: Stage number of first failure (None if all passed).
        stage_status: Dictionary mapping stage numbers to their status.

    State Transitions:
        PENDING -> PASSED (test passes)
        PENDING -> FAILED (test fails)
        PENDING -> SKIPPED (dependency failed)

    Example:
        >>> tracker = StageTracker.get_instance()
        >>> tracker.reset()  # Ensure clean state for example
        >>> tracker.mark_passed(1)
        >>> tracker.mark_failed(2)
        >>> tracker.should_skip(3)  # Returns True because stage 2 failed
        True

    Verification of first_failure tracking:

        The first_failure attribute correctly records only the first failure
        and subsequent failures do not override it:

        >>> tracker = StageTracker.get_instance()
        >>> tracker.reset()  # Start with clean state
        >>> tracker.first_failure is None  # No failure recorded yet
        True
        >>> tracker.mark_failed(2)
        >>> tracker.first_failure  # First failure is recorded
        2
        >>> tracker.mark_failed(4)  # Another stage fails
        >>> tracker.first_failure  # Still shows the first failure, not overwritten
        2
        >>> tracker.mark_failed(1)  # Even an earlier stage number doesn't override
        >>> tracker.first_failure  # Remains 2 (first chronological failure)
        2

        The reset() method clears the first_failure:

        >>> tracker.reset()
        >>> tracker.first_failure is None  # Cleared after reset
        True
        >>> tracker.stage_status  # Stage status also cleared
        {}
    """

    _instance: "StageTracker | None" = None

    def __new__(cls) -> "StageTracker":
        """Create or return the singleton instance."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self) -> None:
        """Initialize the tracker with empty state.

        Only initializes on first call; subsequent calls are no-ops
        to maintain singleton state.
        """
        if self._initialized:
            return
        self.first_failure: int | None = None
        self.stage_status: dict[int, StageStatus] = {}
        self._initialized = True

    @classmethod
    def get_instance(cls) -> "StageTracker":
        """Get the singleton instance of StageTracker.

        Returns:
            The singleton StageTracker instance.
        """
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def mark_passed(self, stage: int) -> None:
        """Mark a stage as passed.

        Args:
            stage: The stage number that passed.
        """
        self.stage_status[stage] = StageStatus.PASSED

    def mark_failed(self, stage: int) -> None:
        """Mark a stage as failed and record first failure if applicable.

        When a stage fails, it is recorded as the first failure if no
        previous failure exists. This triggers automatic skipping of
        all subsequent stages.

        Args:
            stage: The stage number that failed.
        """
        self.stage_status[stage] = StageStatus.FAILED
        if self.first_failure is None:
            self.first_failure = stage

    def mark_skipped(self, stage: int) -> None:
        """Mark a stage as skipped.

        Args:
            stage: The stage number to skip.
        """
        self.stage_status[stage] = StageStatus.SKIPPED

    def should_skip(self, stage: int) -> bool:
        """Determine if a stage should be skipped based on prior failures.

        Implements the business rule: if stage N fails, all stages > N
        are automatically skipped.

        Args:
            stage: The stage number to check.

        Returns:
            True if the stage should be skipped, False otherwise.
        """
        if self.first_failure is None:
            return False
        return stage > self.first_failure

    def get_status(self, stage: int) -> StageStatus:
        """Get the status of a specific stage.

        Args:
            stage: The stage number to query.

        Returns:
            The status of the stage, or PENDING if not tracked yet.
        """
        return self.stage_status.get(stage, StageStatus.PENDING)

    def reset(self) -> None:
        """Reset all tracker state for test isolation.

        Clears all stage statuses and resets first_failure to None.
        Useful for ensuring clean state between test runs.
        """
        self.first_failure = None
        self.stage_status = {}


@dataclass
class E2EConfig:
    """Configuration object parsed from pytest CLI options.

    This dataclass holds configuration settings for E2E test execution,
    including stage filtering, debug mode, and timeout overrides.

    Attributes:
        stage_filter: Range of stages to run (start, end inclusive).
            If None, all stages are run.
        debug: Enable debug mode with streaming output.
        timeout_override: Override all stage timeouts in seconds.
            If None, default timeouts are used.

    Validation Rules:
        - stage_filter range must be 1-6 inclusive
        - timeout_override must be positive if set

    Example:
        >>> config = E2EConfig(stage_filter=(1, 3), debug=True)
        >>> config.should_run_stage(2)
        True
        >>> config.should_run_stage(5)
        False
    """

    stage_filter: tuple[int, int] | None = None
    debug: bool = False
    timeout_override: int | None = None

    def __post_init__(self) -> None:
        """Validate configuration after initialization.

        Raises:
            ValueError: If stage_filter values are not in range 1-6,
                or if timeout_override is not positive.
        """
        if self.stage_filter is not None:
            start, end = self.stage_filter
            if not (1 <= start <= 6):
                raise ValueError(
                    f"stage_filter start must be between 1 and 6, got {start}"
                )
            if not (1 <= end <= 6):
                raise ValueError(
                    f"stage_filter end must be between 1 and 6, got {end}"
                )
            if start > end:
                raise ValueError(
                    f"stage_filter start ({start}) must be <= end ({end})"
                )

        if self.timeout_override is not None and self.timeout_override <= 0:
            raise ValueError(
                f"timeout_override must be positive, got {self.timeout_override}"
            )

    def should_run_stage(self, stage: int) -> bool:
        """Determine if a stage should be run based on the stage filter.

        Args:
            stage: The stage number to check.

        Returns:
            True if the stage should be run (either no filter is set,
            or the stage is within the filter range inclusive).
        """
        if self.stage_filter is None:
            return True
        start, end = self.stage_filter
        return start <= stage <= end


def pytest_addoption(parser: pytest.Parser) -> None:
    """Register E2E test CLI options with pytest.

    This hook adds custom command-line options for controlling E2E test
    execution, including stage filtering, debug output, and timeout
    configuration.

    Args:
        parser: The pytest argument parser to add options to.

    Options:
        --stage: Filter which stages to run. Accepts "N" for a single stage
            or "N-M" for a range (e.g., "3" or "2-4"). Stages are 1-6.
        --e2e-debug: Enable real-time Claude output streaming for debugging.
            When enabled, subprocess output is not captured.
        --timeout-all: Override all stage timeouts to the specified number
            of seconds. Useful for slow environments or debugging.
    """
    parser.addoption(
        "--stage",
        action="store",
        default=None,
        help=(
            "Filter which stages to run. Use 'N' for a single stage "
            "or 'N-M' for a range (e.g., --stage 3 or --stage 2-4). "
            "Valid stages are 1-6."
        ),
    )
    parser.addoption(
        "--e2e-debug",
        action="store_true",
        default=False,
        help=(
            "Enable real-time Claude output streaming for debugging. "
            "When enabled, subprocess output is displayed in real-time "
            "instead of being captured."
        ),
    )
    parser.addoption(
        "--timeout-all",
        action="store",
        type=int,
        default=None,
        help=(
            "Override all stage timeouts to the specified number of seconds. "
            "Useful for slow environments or when debugging with breakpoints."
        ),
    )


def _parse_stage_filter(stage_str: str | None) -> tuple[int, int] | None:
    """Parse --stage option value into a stage range.

    Args:
        stage_str: The stage filter string from CLI, either "N" or "N-M" format.

    Returns:
        A tuple of (start, end) stage numbers (inclusive), or None if no filter.

    Raises:
        ValueError: If the stage string format is invalid.
    """
    if stage_str is None:
        return None

    stage_str = stage_str.strip()

    if "-" in stage_str:
        # Range format: "N-M"
        parts = stage_str.split("-")
        if len(parts) != 2:
            raise ValueError(f"Invalid stage range format: '{stage_str}'. Use 'N-M'.")
        try:
            start = int(parts[0].strip())
            end = int(parts[1].strip())
        except ValueError as e:
            raise ValueError(
                f"Invalid stage range: '{stage_str}'. Stage numbers must be integers."
            ) from e
        return (start, end)
    else:
        # Single stage format: "N"
        try:
            stage = int(stage_str)
        except ValueError as e:
            raise ValueError(
                f"Invalid stage: '{stage_str}'. Must be an integer."
            ) from e
        return (stage, stage)


def _get_stage_from_item(item: pytest.Item) -> int | None:
    """Extract stage number from a test item's markers.

    Looks for pytest.mark.stage(N) marker on the test item or its parent class.

    Args:
        item: The pytest test item to check.

    Returns:
        The stage number if found, or None if no stage marker exists.
    """
    # Check for stage marker on the item
    for marker in item.iter_markers(name="stage"):
        if marker.args:
            return int(marker.args[0])
    return None


def pytest_collection_modifyitems(
    config: pytest.Config, items: list[pytest.Item]
) -> None:
    """Sort and filter test items by stage number.

    This hook modifies the test collection to:
    1. Sort tests by their stage number (tests without stage marker go last)
    2. Filter out tests that don't match the --stage filter

    Args:
        config: The pytest configuration object.
        items: List of collected test items (modified in place).
    """
    # Parse the stage filter from CLI options
    stage_str = config.getoption("--stage", default=None)
    stage_filter = _parse_stage_filter(stage_str)

    # Sort items by stage number (None/no stage goes to end)
    def stage_sort_key(item: pytest.Item) -> tuple[int, str]:
        """Sort key: (stage_number, test_name). No stage = 999 (last)."""
        stage = _get_stage_from_item(item)
        return (stage if stage is not None else 999, item.nodeid)

    items.sort(key=stage_sort_key)

    # Filter items based on stage filter if provided
    if stage_filter is not None:
        start, end = stage_filter
        filtered_items = []
        for item in items:
            stage = _get_stage_from_item(item)
            # Include items without stage marker (infrastructure tests)
            # or items within the filter range
            if stage is None or (start <= stage <= end):
                filtered_items.append(item)
        # Modify items in place
        items[:] = filtered_items


def pytest_runtest_setup(item: pytest.Item) -> None:
    """Skip tests in stages that depend on failed earlier stages.

    This hook runs before each test and checks if the test's stage should
    be skipped based on prior stage failures. If an earlier stage has failed,
    all subsequent stages are automatically skipped.

    Args:
        item: The pytest test item about to be executed.

    Raises:
        pytest.skip.Exception: If the test should be skipped due to
            a prior stage failure.
    """
    stage = _get_stage_from_item(item)
    if stage is None:
        # No stage marker, don't apply stage-based skipping
        return

    tracker = StageTracker.get_instance()
    if tracker.should_skip(stage):
        pytest.skip(
            f"Stage {stage} skipped due to stage {tracker.first_failure} failure"
        )


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(
    item: pytest.Item, call: pytest.CallInfo
) -> Generator[None, pytest.TestReport, None]:
    """Track test pass/fail status for stage dependency management.

    This hook runs after each test phase (setup, call, teardown) and updates
    the StageTracker singleton with the test result. Only the "call" phase
    (actual test execution) is tracked.

    Args:
        item: The pytest test item that was executed.
        call: Information about the test call phase.

    Yields:
        None: Yields to get the report from the next hook in the chain.
    """
    outcome = yield
    report = outcome.get_result()

    # Only process the "call" phase (actual test execution)
    # Skip "setup" and "teardown" phases
    if report.when != "call":
        return

    stage = _get_stage_from_item(item)
    if stage is None:
        # No stage marker, don't track
        return

    tracker = StageTracker.get_instance()
    if report.passed:
        tracker.mark_passed(stage)
    elif report.failed:
        tracker.mark_failed(stage)


# =============================================================================
# Session-Scoped Fixtures
# =============================================================================


@pytest.fixture(scope="session")
def e2e_config(request: pytest.FixtureRequest) -> E2EConfig:
    """Parse CLI options and return E2E configuration.

    This session-scoped fixture parses the pytest command-line options
    and constructs an E2EConfig instance that can be used throughout
    the test session.

    Args:
        request: Pytest fixture request object providing access to config.

    Returns:
        E2EConfig instance with parsed stage filter, debug mode, and
        timeout override settings.

    Example:
        >>> def test_example(e2e_config):
        ...     if e2e_config.debug:
        ...         print("Debug mode enabled")
        ...     if e2e_config.should_run_stage(3):
        ...         # Run stage 3 logic
        ...         pass
    """
    stage_str = request.config.getoption("--stage", default=None)
    stage_filter = _parse_stage_filter(stage_str)

    debug = request.config.getoption("--e2e-debug", default=False)
    timeout_override = request.config.getoption("--timeout-all", default=None)

    return E2EConfig(
        stage_filter=stage_filter,
        debug=debug,
        timeout_override=timeout_override,
    )


@pytest.fixture(scope="session")
def test_project(request: pytest.FixtureRequest) -> E2EProject:
    """Create and set up an E2EProject for the test session.

    This session-scoped fixture creates an isolated test project directory
    with git initialization, fixture copying, and log directory creation.
    The project persists for the entire test session and is not cleaned up
    automatically (for debugging purposes).

    Args:
        request: Pytest fixture request object (unused but required for
            session-scoped fixtures that may need config access).

    Returns:
        E2EProject instance with setup() already called, ready for use
        in test stages.

    Example:
        >>> def test_example(test_project):
        ...     # Project path is ready to use
        ...     assert test_project.project_path.exists()
        ...     # Run Claude commands in project directory
        ...     runner.run(cwd=test_project.project_path)
    """
    # Detect tests root directory (tests/e2e/conftest.py -> tests/)
    tests_root = Path(__file__).parent.parent

    # Create the E2EProject instance
    project = E2EProject("todo-app", tests_root)

    # Set up the project (creates directories, copies fixtures, inits git)
    project.setup()

    return project


# =============================================================================
# Function-Scoped Fixtures
# =============================================================================


@pytest.fixture
def project_path(test_project: E2EProject) -> Path:
    """Provide the project path for test functions.

    This function-scoped fixture extracts the project path from the
    session-scoped test_project fixture for convenient access in tests.

    Args:
        test_project: The session-scoped E2EProject fixture.

    Returns:
        Path to the test project directory.

    Example:
        >>> def test_example(project_path):
        ...     assert project_path.exists()
        ...     config_file = project_path / "config.yaml"
    """
    return test_project.project_path


@pytest.fixture
def claude_runner(test_project: E2EProject, e2e_config: E2EConfig) -> ClaudeRunner:
    """Create a ClaudeRunner configured for the test project.

    This function-scoped fixture creates a ClaudeRunner instance configured
    with the test project's working directory and log directory, along with
    debug and timeout settings from the E2E configuration.

    Args:
        test_project: The session-scoped E2EProject fixture.
        e2e_config: The session-scoped E2EConfig fixture.

    Returns:
        ClaudeRunner instance ready for executing Claude CLI commands.

    Example:
        >>> def test_example(claude_runner):
        ...     result = claude_runner.run(
        ...         prompt="Create a file",
        ...         stage=1,
        ...         log_name="test"
        ...     )
        ...     assert result.success
    """
    return ClaudeRunner(
        work_dir=test_project.project_path,
        log_dir=test_project.log_dir,
        debug=e2e_config.debug,
        timeout_override=e2e_config.timeout_override,
    )


@pytest.fixture
def file_verifier(test_project: E2EProject) -> FileVerifier:
    """Create a FileVerifier for the test project.

    This function-scoped fixture creates a FileVerifier instance configured
    with the test project's base path for verifying file existence and content.

    Args:
        test_project: The session-scoped E2EProject fixture.

    Returns:
        FileVerifier instance for asserting file conditions.

    Example:
        >>> def test_example(file_verifier):
        ...     file_verifier.assert_exists("README.md", "Project readme")
        ...     file_verifier.assert_contains("config.py", r"DEBUG", "Debug setting")
    """
    return FileVerifier(base_path=test_project.project_path)


@pytest.fixture
def git_verifier(test_project: E2EProject) -> GitVerifier:
    """Create a GitVerifier for the test project.

    This function-scoped fixture creates a GitVerifier instance configured
    with the test project's repository path for verifying git state.

    Args:
        test_project: The session-scoped E2EProject fixture.

    Returns:
        GitVerifier instance for asserting git repository conditions.

    Example:
        >>> def test_example(git_verifier):
        ...     git_verifier.assert_is_repo()
        ...     git_verifier.assert_branch_matches(r"main", "main branch")
    """
    return GitVerifier(repo_path=test_project.project_path)

"""E2E test configuration for projspec.

This module provides shared fixtures, configuration, and utilities
for end-to-end tests that validate the complete projspec workflow
using Claude Code subprocess execution.
"""

from dataclasses import dataclass
from enum import Enum

import pytest


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
        >>> tracker.mark_passed(1)
        >>> tracker.mark_failed(2)
        >>> tracker.should_skip(3)  # Returns True because stage 2 failed
        True
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

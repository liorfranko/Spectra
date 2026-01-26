"""E2E test configuration for projspec.

This module provides shared fixtures, configuration, and utilities
for end-to-end tests that validate the complete projspec workflow
using Claude Code subprocess execution.
"""

from enum import Enum


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

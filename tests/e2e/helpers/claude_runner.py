"""Claude CLI runner utilities for E2E tests.

This module provides utilities for executing Claude CLI commands and
capturing their results in a structured format.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class ClaudeResult:
    """Immutable data class containing execution results from a Claude CLI command.

    This dataclass captures all relevant information from running a Claude CLI
    command, including output streams, timing, and success status.

    Attributes:
        success: True if exit code is 0 and command did not time out.
        stdout: Captured standard output from the command.
        stderr: Captured standard error from the command.
        timed_out: True if command exceeded the configured timeout.
        duration: Execution time in seconds (must be >= 0).
        exit_code: Process exit code (0 indicates success).

    Raises:
        ValueError: If validation rules are violated:
            - success=True but exit_code != 0
            - success=True but timed_out=True
            - duration < 0

    Example:
        >>> result = ClaudeResult(
        ...     success=True,
        ...     stdout="Hello, world!",
        ...     stderr="",
        ...     timed_out=False,
        ...     duration=1.5,
        ...     exit_code=0
        ... )
        >>> result.success
        True
    """

    success: bool
    stdout: str
    stderr: str
    timed_out: bool
    duration: float
    exit_code: int

    def __post_init__(self) -> None:
        """Validate the ClaudeResult fields after initialization.

        Raises:
            ValueError: If any validation rule is violated.
        """
        if self.success and self.exit_code != 0:
            raise ValueError(
                f"success=True requires exit_code=0, got exit_code={self.exit_code}"
            )

        if self.success and self.timed_out:
            raise ValueError(
                "success=True is incompatible with timed_out=True"
            )

        if self.duration < 0:
            raise ValueError(
                f"duration must be >= 0, got {self.duration}"
            )

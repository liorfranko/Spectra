"""Stage 6 tests for /speckit.implement command.

This module contains end-to-end tests that verify the /speckit.implement
command works correctly, executing tasks and producing implementation
artifacts.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier, GitVerifier


@pytest.mark.e2e
@pytest.mark.stage(6)
class TestSpeckitImplement:
    """Test class for /speckit.implement command functionality.

    Tests in this class verify that the implement command correctly
    executes the generated tasks and produces implementation artifacts.
    """

    def test_implement_runs_successfully(self, claude_runner: ClaudeRunner) -> None:
        """Test that /speckit.implement command executes successfully.

        This test runs the /speckit.implement command on the tasks
        generated in stage 5 and verifies that it completes without errors.
        Note: This stage has a longer timeout due to the implementation work.

        Args:
            claude_runner: Fixture providing a configured ClaudeRunner instance.
        """
        prompt = (
            "Run /speckit.implement to execute the implementation plan. "
            "Focus on completing at least the first few tasks to verify "
            "the implementation workflow is functional."
        )

        result = claude_runner.run(
            prompt=prompt,
            stage=6,
            log_name="implement_runs_successfully",
        )

        assert result.success, (
            f"/speckit.implement command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"Stderr: {result.stderr}\n"
            f"Stdout (last 500 chars): {result.stdout[-500:] if result.stdout else 'empty'}"
        )

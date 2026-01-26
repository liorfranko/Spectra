"""Stage 5 tests for /speckit.tasks command.

This module contains end-to-end tests that verify the /speckit.tasks
command works correctly, including task generation, proper formatting,
and phase organization.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier, GitVerifier


@pytest.mark.e2e
@pytest.mark.stage(5)
class TestSpeckitTasks:
    """Test class for /speckit.tasks command functionality.

    Tests in this class verify that the tasks command correctly
    generates actionable task lists from implementation plans,
    including proper checkbox formatting and phase organization.
    """

    def test_tasks_runs_successfully(self, claude_runner: ClaudeRunner) -> None:
        """Test that /speckit.tasks command executes successfully.

        This test runs the /speckit.tasks command on the feature plan
        created in stage 4 and verifies that it completes without errors.

        Args:
            claude_runner: Fixture providing a configured ClaudeRunner instance.
        """
        prompt = (
            "Run /speckit.tasks to generate actionable tasks from the "
            "current implementation plan."
        )

        result = claude_runner.run(
            prompt=prompt,
            stage=5,
            log_name="tasks_runs_successfully",
        )

        assert result.success, (
            f"/speckit.tasks command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"Stderr: {result.stderr}\n"
            f"Stdout (last 500 chars): {result.stdout[-500:] if result.stdout else 'empty'}"
        )

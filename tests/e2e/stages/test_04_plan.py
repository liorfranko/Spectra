"""Stage 4 tests for /speckit.plan command.

This module contains end-to-end tests that verify the /speckit.plan
command works correctly, including plan creation, content validation,
and proper technical context generation.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier, GitVerifier


@pytest.mark.e2e
@pytest.mark.stage(4)
class TestSpeckitPlan:
    """Test class for /speckit.plan command functionality.

    Tests in this class verify that the plan command correctly
    generates implementation plans from feature specifications,
    including technical context and project structure analysis.
    """

    def test_plan_runs_successfully(self, claude_runner: ClaudeRunner) -> None:
        """Test that /speckit.plan command executes successfully.

        This test runs the /speckit.plan command on the feature spec
        created in stage 3 and verifies that it completes without errors.

        Args:
            claude_runner: Fixture providing a configured ClaudeRunner instance.
        """
        prompt = (
            "Run /speckit.plan to generate an implementation plan for the "
            "current feature specification."
        )

        result = claude_runner.run(
            prompt=prompt,
            stage=4,
            log_name="plan_runs_successfully",
        )

        assert result.success, (
            f"/speckit.plan command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"Stderr: {result.stderr}\n"
            f"Stdout (last 500 chars): {result.stdout[-500:] if result.stdout else 'empty'}"
        )

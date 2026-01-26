"""Stage 6 tests for /projspec.implement command.

This module contains end-to-end tests that verify the /projspec.implement
command works correctly, executing tasks and producing implementation
artifacts.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier, GitVerifier


@pytest.mark.e2e
@pytest.mark.stage(6)
class TestProjspecImplement:
    """Test class for /projspec.implement command functionality.

    Tests in this class verify that the implement command correctly
    executes the generated tasks and produces implementation artifacts.
    """

    def test_01_implement_runs_successfully(self, claude_runner: ClaudeRunner) -> None:
        """Test that /projspec.implement command executes successfully.

        This test runs the /projspec.implement command on the tasks
        generated in stage 5 and verifies that it completes without errors.
        Note: This stage has a longer timeout due to the implementation work.

        Args:
            claude_runner: Fixture providing a configured ClaudeRunner instance.
        """
        prompt = (
            "/projspec.implement now. Do not ask for confirmation - just run it."
        )

        result = claude_runner.run(
            prompt=prompt,
            stage=6,
            log_name="implement_runs_successfully",
        )

        assert result.success, (
            f"/projspec.implement command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"Stderr: {result.stderr}\n"
            f"Stdout (last 500 chars): {result.stdout[-500:] if result.stdout else 'empty'}"
        )

    def test_02_implement_produces_code(
        self, git_verifier: GitVerifier
    ) -> None:
        """Test that /projspec.implement produces implementation artifacts.

        The /projspec.implement command should create new commits with
        implementation code. This test verifies that commits were made
        during the implementation process.

        Args:
            git_verifier: Fixture providing a configured GitVerifier instance.
        """
        # Get the worktree path for the feature
        worktree_path = git_verifier.get_worktree_path(pattern=r"worktrees/\d+-.*")
        assert worktree_path is not None, (
            "Could not find feature worktree. "
            "This test depends on earlier stage tests passing."
        )

        # Verify that implementation commits exist
        # The implement command should have created at least one commit
        # with implementation code (beyond the initial spec commits)
        git_verifier.assert_min_commits(
            count=1,
            message_pattern=r"\[T\d+\]",  # Task commit pattern
            path=worktree_path,
        )

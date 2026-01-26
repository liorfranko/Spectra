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

    def test_tasks_file_created(
        self, file_verifier: FileVerifier, git_verifier: GitVerifier
    ) -> None:
        """Test that tasks.md file is created in the feature spec directory.

        The /speckit.tasks command should create a tasks.md file within
        the specs/<feature-id>/ directory in the feature worktree.

        Args:
            file_verifier: Fixture providing a configured FileVerifier instance.
            git_verifier: Fixture providing a configured GitVerifier instance.
        """
        # Get the worktree path for the feature
        worktree_path = git_verifier.get_worktree_path(pattern=r"worktrees/\d+-.*")
        assert worktree_path is not None, (
            "Could not find feature worktree matching pattern 'worktrees/\\d+-.*'. "
            "The /speckit.specify command should have created a numbered worktree."
        )

        # Find the tasks.md file in the worktree's specs directory
        tasks_file = file_verifier.find_file(
            pattern=r"specs/\d+-.*/tasks\.md",
            base_path=worktree_path,
        )
        assert tasks_file is not None, (
            f"tasks.md not found in worktree at {worktree_path}. "
            "Expected a file matching pattern 'specs/<number>-<name>/tasks.md'. "
            "The /speckit.tasks command should create this file."
        )

    def test_tasks_has_checkboxes(
        self, file_verifier: FileVerifier, git_verifier: GitVerifier
    ) -> None:
        """Test that tasks.md contains task checkboxes.

        The /speckit.tasks command should generate a tasks.md file that
        includes markdown checkboxes (- [ ] or - [x]) for tracking task
        completion status.

        Args:
            file_verifier: Fixture providing a configured FileVerifier instance.
            git_verifier: Fixture providing a configured GitVerifier instance.
        """
        # Get the worktree path for the feature
        worktree_path = git_verifier.get_worktree_path(pattern=r"worktrees/\d+-.*")
        assert worktree_path is not None, (
            "Could not find feature worktree. "
            "This test depends on earlier stage tests passing."
        )

        # Find the tasks.md file
        tasks_file = file_verifier.find_file(
            pattern=r"specs/\d+-.*/tasks\.md",
            base_path=worktree_path,
        )
        assert tasks_file is not None, (
            "tasks.md not found. This test depends on test_tasks_file_created passing."
        )

        # Verify task checkboxes exist (unchecked or checked)
        checkbox_count = file_verifier.count_pattern(
            path=tasks_file,
            pattern=r"-\s*\[[ x]\]",
        )
        assert checkbox_count >= 1, (
            f"tasks.md at {tasks_file} does not contain any task checkboxes. "
            "Expected at least one '- [ ]' or '- [x]' pattern. "
            "The /speckit.tasks command should generate actionable tasks with checkboxes."
        )

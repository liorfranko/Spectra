"""Stage 3 tests for /speckit.specify command.

This module contains end-to-end tests that verify the /speckit.specify
command works correctly, including spec creation, content validation,
and proper file structure generation.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier, GitVerifier


@pytest.mark.e2e
@pytest.mark.stage(3)
class TestSpeckitSpecify:
    """Test class for /speckit.specify command functionality.

    Tests in this class verify that the specify command correctly
    generates feature specifications from natural language descriptions.
    """

    def test_specify_runs_successfully(self, claude_runner: ClaudeRunner) -> None:
        """Test that /speckit.specify command executes successfully.

        This test runs the /speckit.specify command with a sample feature
        description and verifies that it completes without errors.

        Args:
            claude_runner: Fixture providing a configured ClaudeRunner instance.
        """
        prompt = (
            "Run /speckit.specify with the following feature description: "
            "'Add a simple todo list feature that allows users to create, "
            "read, update, and delete todo items with a title and completion status.'"
        )

        result = claude_runner.run(
            prompt=prompt,
            stage=3,
            log_name="specify_runs_successfully",
        )

        assert result.success, (
            f"/speckit.specify command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"Stderr: {result.stderr}\n"
            f"Stdout (last 500 chars): {result.stdout[-500:] if result.stdout else 'empty'}"
        )

    def test_feature_branch_created(self, git_verifier: GitVerifier) -> None:
        """Test that /speckit.specify creates a feature worktree.

        The /speckit.specify command should create a worktree with a numbered
        feature branch for the specified feature. This test verifies that
        such a worktree exists after the specify command has run.

        Args:
            git_verifier: Fixture providing a configured GitVerifier instance.
        """
        git_verifier.assert_worktree_exists(
            pattern=r"worktrees/\d+-.*"
        )

    def test_spec_file_created(
        self, file_verifier: FileVerifier, git_verifier: GitVerifier
    ) -> None:
        """Test that spec.md file is created in the feature spec directory.

        The /speckit.specify command should create a spec.md file within
        the specs/<feature-id>/ directory in the feature worktree. This test
        locates the worktree and verifies the spec file exists.

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

        # Find the spec.md file in the worktree's specs directory
        spec_file = file_verifier.find_file(
            pattern=r"specs/\d+-.*/spec\.md",
            base_path=worktree_path,
        )
        assert spec_file is not None, (
            f"spec.md not found in worktree at {worktree_path}. "
            "Expected a file matching pattern 'specs/<number>-<name>/spec.md'. "
            "The /speckit.specify command should create this file."
        )

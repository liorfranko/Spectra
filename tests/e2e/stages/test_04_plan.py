"""Stage 4 tests for /projspec.plan command.

This module contains end-to-end tests that verify the /projspec.plan
command works correctly, including plan creation, content validation,
and proper technical context generation.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier, GitVerifier


@pytest.mark.e2e
@pytest.mark.stage(4)
class TestProjspecPlan:
    """Test class for /projspec.plan command functionality.

    Tests in this class verify that the plan command correctly
    generates implementation plans from feature specifications,
    including technical context and project structure analysis.
    """

    def test_01_plan_runs_successfully(self, claude_runner: ClaudeRunner) -> None:
        """Test that /projspec.plan command executes successfully.

        This test runs the /projspec.plan command on the feature spec
        created in stage 3 and verifies that it completes without errors.

        Args:
            claude_runner: Fixture providing a configured ClaudeRunner instance.
        """
        prompt = (
            "Run /projspec.plan to generate an implementation plan for the "
            "current feature specification."
        )

        result = claude_runner.run(
            prompt=prompt,
            stage=4,
            log_name="plan_runs_successfully",
        )

        assert result.success, (
            f"/projspec.plan command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"Stderr: {result.stderr}\n"
            f"Stdout (last 500 chars): {result.stdout[-500:] if result.stdout else 'empty'}"
        )

    def test_02_plan_file_created(
        self, file_verifier: FileVerifier, git_verifier: GitVerifier
    ) -> None:
        """Test that plan.md file is created in the feature spec directory.

        The /projspec.plan command should create a plan.md file within
        the specs/<feature-id>/ directory in the feature worktree.

        Args:
            file_verifier: Fixture providing a configured FileVerifier instance.
            git_verifier: Fixture providing a configured GitVerifier instance.
        """
        # Get the worktree path for the feature
        worktree_path = git_verifier.get_worktree_path(pattern=r"worktrees/\d+-.*")
        assert worktree_path is not None, (
            "Could not find feature worktree matching pattern 'worktrees/\\d+-.*'. "
            "The /projspec.specify command should have created a numbered worktree."
        )

        # Find the plan.md file in the worktree's specs directory
        plan_file = file_verifier.find_file(
            pattern=r"specs/\d+-.*/plan\.md",
            base_path=worktree_path,
        )
        assert plan_file is not None, (
            f"plan.md not found in worktree at {worktree_path}. "
            "Expected a file matching pattern 'specs/<number>-<name>/plan.md'. "
            "The /projspec.plan command should create this file."
        )

    def test_03_plan_has_technical_context(
        self, file_verifier: FileVerifier, git_verifier: GitVerifier
    ) -> None:
        """Test that plan.md contains a Technical Context section.

        The /projspec.plan command should generate a plan.md file that
        includes a Technical Context section describing the technologies,
        dependencies, and architecture relevant to the implementation.

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

        # Find the plan.md file
        plan_file = file_verifier.find_file(
            pattern=r"specs/\d+-.*/plan\.md",
            base_path=worktree_path,
        )
        assert plan_file is not None, (
            "plan.md not found. This test depends on test_plan_file_created passing."
        )

        # Verify Technical Context section exists
        file_verifier.assert_contains(
            path=plan_file,
            pattern=r"(?i)#.*technical\s+context",
            description="Technical Context section header",
        )

    def test_04_plan_has_project_structure(
        self, file_verifier: FileVerifier, git_verifier: GitVerifier
    ) -> None:
        """Test that plan.md contains a Project Structure section.

        The /projspec.plan command should generate a plan.md file that
        includes a Project Structure section describing the directory
        layout and file organization for the implementation.

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

        # Find the plan.md file
        plan_file = file_verifier.find_file(
            pattern=r"specs/\d+-.*/plan\.md",
            base_path=worktree_path,
        )
        assert plan_file is not None, (
            "plan.md not found. This test depends on test_plan_file_created passing."
        )

        # Verify Project Structure section exists
        file_verifier.assert_contains(
            path=plan_file,
            pattern=r"(?i)#.*project\s+structure",
            description="Project Structure section header",
        )

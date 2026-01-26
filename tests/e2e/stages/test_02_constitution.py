"""Stage 2 tests for /projspec.constitution command.

This module tests the constitution creation workflow, verifying that
the /projspec.constitution command properly creates and manages project
constitution files with foundational principles and constraints.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier


@pytest.mark.e2e
@pytest.mark.stage(2)
class TestProjspecConstitution:
    """Test class for /projspec.constitution command functionality.

    Tests verify that the constitution command creates proper project
    constitution files, handles user input for principles, and maintains
    consistency with dependent templates.
    """

    def test_01_constitution_setup(self, claude_runner: ClaudeRunner) -> None:
        """Test that /projspec.constitution command executes successfully.

        This test verifies that the /projspec.constitution command can be
        executed via Claude CLI without errors. It runs the constitution
        setup which creates foundational principles and constraints for
        the project.

        Args:
            claude_runner: ClaudeRunner fixture configured for the test project.
        """
        result = claude_runner.run(
            prompt="Run /projspec.constitution to set up the project constitution with foundational principles",
            stage=2,
            log_name="test_constitution_setup",
        )

        assert result.success, (
            f"/projspec.constitution command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"STDOUT:\n{result.stdout}\n"
            f"STDERR:\n{result.stderr}"
        )

    def test_02_constitution_file_created(self, file_verifier: FileVerifier) -> None:
        """Test that constitution.md file is created in the correct location.

        This test verifies that running the /projspec.constitution command
        creates the constitution.md file in the .specify/memory directory.

        Args:
            file_verifier: FileVerifier fixture for checking file existence.
        """
        file_verifier.assert_exists(
            ".specify/memory/constitution.md",
            "constitution file"
        )

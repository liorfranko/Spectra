"""Stage 1 tests for specify init command.

This module contains end-to-end tests that verify the `specify init` command
creates the correct directory structure for the projspec plugin. These tests
are the first stage in the E2E test pipeline and must pass before subsequent
stages can run.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier


@pytest.mark.e2e
@pytest.mark.stage(1)
class TestSpeckitInit:
    """Test class for verifying projspec plugin initialization.

    Tests in this class verify that the `specify init` command properly
    initializes the projspec plugin directory structure, including:
    - Creation of required directories
    - Generation of configuration files
    - Proper file permissions and content

    Test methods will be added in subsequent tasks (T025-T028).
    """

    def test_init_runs_successfully(self, claude_runner: ClaudeRunner) -> None:
        """Test that specify init command executes successfully.

        This test verifies that the `specify init` command can be executed
        via Claude CLI without errors. It serves as the foundational test
        for the initialization stage.

        Args:
            claude_runner: ClaudeRunner fixture configured for the test project.
        """
        result = claude_runner.run(
            prompt="Run specify init to initialize the projspec plugin for this project",
            stage=1,
            log_name="test_init_runs_successfully",
        )

        assert result.success, (
            f"specify init command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"STDOUT:\n{result.stdout}\n"
            f"STDERR:\n{result.stderr}"
        )

    def test_specify_dir_created(self, file_verifier: FileVerifier) -> None:
        """Test that .specify/ directory is created after initialization.

        This test verifies that the `specify init` command creates the
        .specify/ directory in the project root. This directory is the
        primary storage location for projspec plugin state and artifacts.

        Args:
            file_verifier: FileVerifier fixture configured for the test project.
        """
        file_verifier.assert_dir_exists(
            ".specify/",
            "projspec plugin configuration directory"
        )

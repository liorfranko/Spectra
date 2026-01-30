"""Stage 2 tests for /spectra:constitution command.

This module tests the constitution creation workflow, verifying that
the /spectra:constitution command properly creates and manages project
constitution files with foundational principles and constraints.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier


@pytest.mark.e2e
@pytest.mark.stage(2)
class TestSpectraConstitution:
    """Test class for /spectra:constitution command functionality.

    Tests verify that the constitution command creates proper project
    constitution files, handles user input for principles, and maintains
    consistency with dependent templates.
    """

    def test_01_constitution_setup(self, claude_runner: ClaudeRunner) -> None:
        """Test that /spectra:constitution command executes successfully.

        This test verifies that the /spectra:constitution command can be
        executed via Claude CLI without errors. It runs the constitution
        setup which creates foundational principles and constraints for
        the project.

        Args:
            claude_runner: ClaudeRunner fixture configured for the test project.
        """
        result = claude_runner.run(
            prompt="/spectra:constitution now. Do not ask for confirmation - just run it.",
            stage=2,
            log_name="test_constitution_setup",
        )

        assert result.success, (
            f"/spectra:constitution command failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"STDOUT:\n{result.stdout}\n"
            f"STDERR:\n{result.stderr}"
        )

    def test_02_spectra_dir_exists(self, file_verifier: FileVerifier) -> None:
        """Test that .spectra/ directory exists after constitution setup.

        This test verifies that the .spectra/ directory is created by the
        constitution command. This directory is the primary storage location
        for spectra plugin state and artifacts.

        Args:
            file_verifier: FileVerifier fixture configured for the test project.
        """
        file_verifier.assert_dir_exists(
            ".spectra/",
            "spectra plugin configuration directory"
        )

    def test_03_memory_dir_exists(self, file_verifier: FileVerifier) -> None:
        """Test that .spectra/memory/ directory exists after constitution setup.

        This test verifies that the .spectra/memory/ directory is created by the
        constitution command. This directory stores the constitution file.

        Args:
            file_verifier: FileVerifier fixture configured for the test project.
        """
        file_verifier.assert_dir_exists(
            ".spectra/memory/",
            "spectra memory directory"
        )

    def test_04_constitution_file_created(self, file_verifier: FileVerifier) -> None:
        """Test that constitution.md file is created in the correct location.

        This test verifies that running the /spectra:constitution command
        creates the constitution.md file in the .spectra/memory directory.

        Args:
            file_verifier: FileVerifier fixture for checking file existence.
        """
        file_verifier.assert_exists(
            ".spectra/memory/constitution.md",
            "constitution file"
        )

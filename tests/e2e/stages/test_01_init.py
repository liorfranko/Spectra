"""Stage 1 tests for projspec plugin auto-discovery.

This module contains end-to-end tests that verify Claude Code correctly
discovers and loads the projspec plugin from the .claude/ directory.
These tests are the first stage in the E2E test pipeline and must pass
before subsequent stages can run.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier


@pytest.mark.e2e
@pytest.mark.stage(1)
class TestProjspecInit:
    """Test class for verifying projspec plugin auto-discovery.

    Tests in this class verify that Claude Code correctly discovers
    the projspec plugin and that the plugin structure is properly
    configured, including:
    - Plugin configuration in .claude/ directory
    - Template files in .specify/templates/
    - Plugin commands are available
    """

    def test_01_plugin_discovered(self, claude_runner: ClaudeRunner) -> None:
        """Test that Claude Code discovers the projspec plugin.

        This test verifies that Claude Code can discover the projspec
        plugin and that the plugin's commands are available. The plugin
        is auto-discovered from the .claude/ directory.

        Args:
            claude_runner: ClaudeRunner fixture configured for the test project.
        """
        result = claude_runner.run(
            prompt="List available projspec commands. Just confirm that /projspec.specify, /projspec.plan, and /projspec.tasks are available.",
            stage=1,
            log_name="test_plugin_discovered",
        )

        assert result.success, (
            f"Plugin discovery check failed.\n"
            f"Exit code: {result.exit_code}\n"
            f"Timed out: {result.timed_out}\n"
            f"STDOUT:\n{result.stdout}\n"
            f"STDERR:\n{result.stderr}"
        )

    def test_02_specify_dir_exists(self, file_verifier: FileVerifier) -> None:
        """Test that .specify/ directory exists for plugin storage.

        This test verifies that the .specify/ directory exists in the
        project root. This directory is the primary storage location
        for projspec plugin state and artifacts.

        Args:
            file_verifier: FileVerifier fixture configured for the test project.
        """
        file_verifier.assert_dir_exists(
            ".specify/",
            "projspec plugin configuration directory"
        )

    def test_03_templates_exist(self, file_verifier: FileVerifier) -> None:
        """Test that .specify/templates/ directory contains required template files.

        This test verifies that the templates directory exists and contains
        the core template files needed for specification, planning, task
        generation, and checklists.

        Args:
            file_verifier: FileVerifier fixture configured for the test project.
        """
        # Verify templates directory exists
        file_verifier.assert_dir_exists(
            ".specify/templates/",
            "projspec templates directory"
        )

        # Verify core template files exist
        file_verifier.assert_exists(
            ".specify/templates/spec-template.md",
            "specification template"
        )
        file_verifier.assert_exists(
            ".specify/templates/plan-template.md",
            "implementation plan template"
        )
        file_verifier.assert_exists(
            ".specify/templates/tasks-template.md",
            "task generation template"
        )
        file_verifier.assert_exists(
            ".specify/templates/checklist-template.md",
            "checklist template"
        )

    def test_04_claude_plugin_configured(self, file_verifier: FileVerifier) -> None:
        """Test that .claude/ directory contains plugin configuration.

        This test verifies that the .claude/ directory exists in the
        project root, which is where Claude Code plugin configuration
        is stored. This directory is required for plugin auto-discovery.

        Args:
            file_verifier: FileVerifier fixture configured for the test project.
        """
        # Verify .claude/ directory exists
        file_verifier.assert_dir_exists(
            ".claude/",
            "Claude Code plugin configuration directory"
        )

        # Verify plugin settings file exists
        file_verifier.assert_exists(
            ".claude/settings.json",
            "Claude Code plugin settings"
        )

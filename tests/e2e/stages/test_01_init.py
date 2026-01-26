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
    - Plugin commands are available

    Note: The .projspec/ directory and templates are created by the
    constitution command and are tested in Stage 2.
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

    def test_02_claude_plugin_configured(self, file_verifier: FileVerifier) -> None:
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

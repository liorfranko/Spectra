"""Stage 1 tests for specify init command.

This module contains end-to-end tests that verify the `specify init` command
creates the correct directory structure for the projspec plugin. These tests
are the first stage in the E2E test pipeline and must pass before subsequent
stages can run.
"""

import pytest


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

    pass

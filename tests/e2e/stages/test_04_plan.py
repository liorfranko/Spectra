"""Stage 4 tests for /speckit.plan command.

This module contains end-to-end tests that verify the /speckit.plan
command works correctly, including plan creation, content validation,
and proper technical context generation.
"""

import pytest

from ..helpers import ClaudeRunner, FileVerifier, GitVerifier


@pytest.mark.e2e
@pytest.mark.stage(4)
class TestSpeckitPlan:
    """Test class for /speckit.plan command functionality.

    Tests in this class verify that the plan command correctly
    generates implementation plans from feature specifications,
    including technical context and project structure analysis.
    """

    pass

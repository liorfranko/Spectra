"""
Global pytest configuration for projspec tests.

This module provides shared pytest configuration, fixtures, and hooks
that apply to all test types across the test suite.

Note: E2E-specific fixtures are defined in tests/e2e/conftest.py.
"""

# Exclude generated test project directories from pytest collection
collect_ignore_glob = ["e2e/output/*"]

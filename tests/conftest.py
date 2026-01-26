"""Pytest fixtures for ProjSpec tests.

This module contains shared fixtures used across unit and integration tests.
Fixtures provide reusable test data, mock objects, and setup/teardown logic.
"""

from __future__ import annotations

import os
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Generator
from unittest.mock import MagicMock, patch

import pytest
from typer.testing import CliRunner

from projspec_cli.models.config import (
    ClaudeConfig,
    FeaturesConfig,
    GitConfig,
    NumberingConfig,
    ProjectConfig,
    ProjectMetadata,
)


@pytest.fixture
def cli_runner() -> CliRunner:
    """Create a Typer CLI test runner.

    Returns:
        CliRunner instance for testing CLI commands.
    """
    return CliRunner()


@pytest.fixture
def tmp_project_root(tmp_path: Path) -> Path:
    """Create a temporary directory as project root.

    This fixture provides a clean temporary directory for testing
    file operations without affecting the real filesystem.

    Args:
        tmp_path: Pytest's built-in temporary directory fixture.

    Returns:
        Path to the temporary project root directory.
    """
    project_root = tmp_path / "test_project"
    project_root.mkdir(parents=True, exist_ok=True)
    return project_root


@pytest.fixture
def tmp_git_repo(tmp_path: Path) -> Path:
    """Create a temporary git repository for testing.

    This fixture initializes a real git repository in a temporary
    directory, suitable for testing git-related functionality.

    Args:
        tmp_path: Pytest's built-in temporary directory fixture.

    Returns:
        Path to the temporary git repository root.
    """
    repo_path = tmp_path / "git_repo"
    repo_path.mkdir(parents=True, exist_ok=True)

    # Initialize git repository
    subprocess.run(
        ["git", "init"],
        cwd=repo_path,
        capture_output=True,
        check=True,
    )

    # Configure git user for commits (required for some operations)
    subprocess.run(
        ["git", "config", "user.email", "test@example.com"],
        cwd=repo_path,
        capture_output=True,
        check=True,
    )
    subprocess.run(
        ["git", "config", "user.name", "Test User"],
        cwd=repo_path,
        capture_output=True,
        check=True,
    )

    # Create initial commit (needed for worktree operations)
    readme = repo_path / "README.md"
    readme.write_text("# Test Repository\n")
    subprocess.run(
        ["git", "add", "."],
        cwd=repo_path,
        capture_output=True,
        check=True,
    )
    subprocess.run(
        ["git", "commit", "-m", "Initial commit"],
        cwd=repo_path,
        capture_output=True,
        check=True,
    )

    return repo_path


@pytest.fixture
def sample_config() -> ProjectConfig:
    """Create a sample ProjectConfig for testing.

    Returns:
        A fully populated ProjectConfig instance with test values.
    """
    return ProjectConfig(
        project=ProjectMetadata(
            name="test-project",
            version="0.1.0",
            created=datetime(2024, 1, 15, 10, 30, 0),
        ),
        features=FeaturesConfig(
            directory="specs",
            numbering=NumberingConfig(digits=3, start=1),
        ),
        git=GitConfig(
            main_branch="main",
            worktree_dir="worktrees",
        ),
        claude=ClaudeConfig(
            context_file="CLAUDE.md",
            auto_update_context=True,
        ),
    )


@pytest.fixture
def minimal_config() -> ProjectConfig:
    """Create a minimal ProjectConfig with only required fields.

    Returns:
        A ProjectConfig instance with minimal configuration.
    """
    return ProjectConfig(
        project=ProjectMetadata(name="minimal-project"),
    )


@pytest.fixture
def mock_git() -> Generator[MagicMock, None, None]:
    """Mock git utilities for testing without real git operations.

    Yields:
        A MagicMock that replaces the git module during tests.
    """
    with patch("projspec_cli.utils.git") as mock:
        # Set default return values
        mock.has_git.return_value = True
        mock.is_git_repo.return_value = True
        mock.get_repo_root.return_value = Path("/mock/repo")
        mock.get_main_repo_root.return_value = Path("/mock/repo")
        mock.get_current_branch.return_value = "main"
        mock.is_worktree.return_value = False
        mock.is_valid_feature_branch.return_value = True
        mock.list_worktrees.return_value = []
        yield mock


@pytest.fixture
def mock_is_git_repo() -> Generator[MagicMock, None, None]:
    """Mock only the is_git_repo function.

    Yields:
        A MagicMock that replaces is_git_repo during tests.
    """
    with patch("projspec_cli.services.init.is_git_repo") as mock:
        mock.return_value = True
        yield mock


@pytest.fixture
def mock_is_git_repo_false() -> Generator[MagicMock, None, None]:
    """Mock is_git_repo to return False.

    Yields:
        A MagicMock that replaces is_git_repo to simulate non-git directory.
    """
    with patch("projspec_cli.services.init.is_git_repo") as mock:
        mock.return_value = False
        yield mock


@pytest.fixture
def initialized_project(tmp_git_repo: Path) -> Path:
    """Create a fully initialized ProjSpec project for testing.

    Args:
        tmp_git_repo: A temporary git repository fixture.

    Returns:
        Path to the initialized project root.
    """
    from projspec_cli.services.init import initialize_project

    result = initialize_project(
        path=tmp_git_repo,
        project_name="initialized-test-project",
        force=False,
        no_git=False,
    )

    assert result.success, f"Failed to initialize project: {result.message}"
    return tmp_git_repo


@pytest.fixture
def project_with_features(initialized_project: Path) -> Path:
    """Create an initialized project with sample feature directories.

    Args:
        initialized_project: An initialized ProjSpec project.

    Returns:
        Path to the project root with sample features.
    """
    specs_dir = initialized_project / "specs"

    # Create sample feature directories
    feature_001 = specs_dir / "001-user-auth"
    feature_001.mkdir(parents=True, exist_ok=True)
    (feature_001 / "spec.md").write_text("# User Authentication\n\nFeature spec...")

    feature_002 = specs_dir / "002-data-model"
    feature_002.mkdir(parents=True, exist_ok=True)
    (feature_002 / "spec.md").write_text("# Data Model\n\nFeature spec...")
    (feature_002 / "plan.md").write_text("# Implementation Plan\n\nPlan details...")

    return initialized_project


@pytest.fixture
def chdir_to_tmp(tmp_path: Path) -> Generator[Path, None, None]:
    """Change to a temporary directory for the duration of the test.

    Args:
        tmp_path: Pytest's built-in temporary directory fixture.

    Yields:
        Path to the temporary directory (which is now the cwd).
    """
    original_cwd = os.getcwd()
    os.chdir(tmp_path)
    try:
        yield tmp_path
    finally:
        os.chdir(original_cwd)


@pytest.fixture
def chdir_to_git_repo(tmp_git_repo: Path) -> Generator[Path, None, None]:
    """Change to a temporary git repository for the duration of the test.

    Args:
        tmp_git_repo: A temporary git repository fixture.

    Yields:
        Path to the git repository (which is now the cwd).
    """
    original_cwd = os.getcwd()
    os.chdir(tmp_git_repo)
    try:
        yield tmp_git_repo
    finally:
        os.chdir(original_cwd)


@pytest.fixture
def sample_spec_content() -> str:
    """Provide sample spec.md content for testing.

    Returns:
        A string containing sample feature specification content.
    """
    return """# Feature: User Authentication

## Overview
Implement user authentication with JWT tokens.

## User Stories

### US1: User Registration
- As a new user
- I want to register an account
- So that I can access the system

### US2: User Login
- As a registered user
- I want to log in
- So that I can access protected features

## Requirements

1. Support email/password authentication
2. JWT token-based session management
3. Password hashing with bcrypt

## Out of Scope

- OAuth/SSO integration (future feature)
"""


@pytest.fixture
def sample_plan_content() -> str:
    """Provide sample plan.md content for testing.

    Returns:
        A string containing sample implementation plan content.
    """
    return """# Implementation Plan: User Authentication

## Architecture

### Components
1. AuthService - Core authentication logic
2. UserRepository - User data access
3. TokenManager - JWT token handling

## Implementation Phases

### Phase 1: Foundation
- Set up user model and repository
- Implement password hashing

### Phase 2: Authentication
- Implement login endpoint
- Implement JWT token generation

### Phase 3: Registration
- Implement registration endpoint
- Add email validation

## Testing Strategy

- Unit tests for AuthService
- Integration tests for API endpoints
- E2E tests for auth flow
"""


@pytest.fixture
def sample_tasks_content() -> str:
    """Provide sample tasks.md content for testing.

    Returns:
        A string containing sample tasks content.
    """
    return """# Tasks: User Authentication

## Task List

### T001: Create User Model
- **Status**: completed
- **User Story**: US1
- **Description**: Define the User pydantic model with email, password_hash, etc.

### T002: Implement Password Hashing
- **Status**: completed
- **User Story**: US1
- **Description**: Add bcrypt password hashing utility functions.

### T003: Create AuthService
- **Status**: in_progress
- **User Story**: US2
- **Description**: Implement core authentication service with login method.

### T004: Add JWT Token Generation
- **Status**: pending
- **User Story**: US2
- **Blocks**: T005
- **Description**: Implement JWT token creation and validation.

### T005: Create Login Endpoint
- **Status**: pending
- **User Story**: US2
- **Blocked By**: T004
- **Description**: Add /api/auth/login POST endpoint.

### T006: Create Registration Endpoint
- **Status**: pending
- **User Story**: US1
- **Blocked By**: T002
- **Description**: Add /api/auth/register POST endpoint.
"""

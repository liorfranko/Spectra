"""
Project initialization service.

Handles the logic for initializing a new ProjSpec project, including:
- Creating the .specify/ directory structure
- Creating the config.yaml configuration file
- Copying scripts and templates
- Setting up the constitution and CLAUDE.md files
"""

from __future__ import annotations

import shutil
import stat
from dataclasses import dataclass, field
from datetime import datetime
from importlib import resources
from importlib.abc import Traversable
from pathlib import Path

from projspec_cli.models.config import (
    ClaudeConfig,
    FeaturesConfig,
    GitConfig,
    ProjectConfig,
    ProjectMetadata,
)
from projspec_cli.utils.git import is_git_repo

# Exit codes as specified in CLI-INTERFACE.md
EXIT_SUCCESS = 0
EXIT_ALREADY_INITIALIZED = 1
EXIT_NOT_GIT_REPO = 2


@dataclass
class InitResult:
    """Result of project initialization."""

    success: bool
    message: str
    created_files: list[str] = field(default_factory=list)
    exit_code: int = EXIT_SUCCESS


def check_already_initialized(path: Path) -> bool:
    """
    Check if a ProjSpec project is already initialized at the given path.

    A project is considered initialized if:
    - .specify/config.yaml exists, OR
    - projspec.yaml exists (legacy)

    Args:
        path: The project root directory to check.

    Returns:
        True if already initialized, False otherwise.
    """
    specify_config = path / ".specify" / "config.yaml"
    legacy_config = path / "projspec.yaml"

    return specify_config.exists() or legacy_config.exists()


def create_directory_structure(path: Path) -> list[str]:
    """
    Create the ProjSpec directory structure.

    Creates:
    - .specify/
    - .specify/memory/
    - .specify/scripts/bash/
    - .specify/templates/
    - specs/
    - worktrees/

    Args:
        path: The project root directory.

    Returns:
        List of created directory paths (relative to path).
    """
    created: list[str] = []

    directories = [
        ".specify",
        ".specify/memory",
        ".specify/scripts",
        ".specify/scripts/bash",
        ".specify/templates",
        "specs",
        "worktrees",
    ]

    for dir_name in directories:
        dir_path = path / dir_name
        if not dir_path.exists():
            dir_path.mkdir(parents=True, exist_ok=True)
            created.append(dir_name)

    return created


def create_config_file(path: Path, project_name: str) -> str:
    """
    Create the config.yaml configuration file.

    Args:
        path: The project root directory.
        project_name: The name of the project.

    Returns:
        The relative path to the created config file.
    """
    config = ProjectConfig(
        project=ProjectMetadata(
            name=project_name,
            version="0.1.0",
            created=datetime.now(),
        ),
        features=FeaturesConfig(),
        git=GitConfig(),
        claude=ClaudeConfig(),
    )

    config_path = path / ".specify" / "config.yaml"
    config.save_to_file(config_path)

    return ".specify/config.yaml"


def _get_resource_files(
    package: str, subdir: str = ""
) -> list[tuple[str, Traversable]]:
    """
    Get all files from a resource package directory.

    Args:
        package: The package name (e.g., "projspec_cli.resources.templates").
        subdir: Optional subdirectory within the package.

    Returns:
        List of (filename, Traversable) tuples.
    """
    try:
        pkg_files = resources.files(package)
        if subdir:
            pkg_files = pkg_files.joinpath(subdir)

        result: list[tuple[str, Traversable]] = []
        for item in pkg_files.iterdir():
            if item.is_file() and not item.name.startswith("__"):
                result.append((item.name, item))
        return result
    except (ModuleNotFoundError, FileNotFoundError, TypeError):
        return []


def copy_scripts(path: Path) -> list[str]:
    """
    Copy bundled scripts to the project's .specify/scripts/ directory.

    Args:
        path: The project root directory.

    Returns:
        List of created script paths (relative to path).
    """
    created: list[str] = []

    scripts_dir = path / ".specify" / "scripts" / "bash"
    scripts_dir.mkdir(parents=True, exist_ok=True)

    # Get scripts from bundled resources
    script_files = _get_resource_files("projspec_cli.resources.scripts.bash")

    for filename, resource in script_files:
        if filename.endswith(".sh"):
            dest_path = scripts_dir / filename
            content = resource.read_text()
            dest_path.write_text(content)
            # Make scripts executable
            dest_path.chmod(dest_path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP)
            created.append(f".specify/scripts/bash/{filename}")

    return created


def copy_templates(path: Path) -> list[str]:
    """
    Copy bundled templates to the project's .specify/templates/ directory.

    Args:
        path: The project root directory.

    Returns:
        List of created template paths (relative to path).
    """
    created: list[str] = []

    templates_dir = path / ".specify" / "templates"
    templates_dir.mkdir(parents=True, exist_ok=True)

    # Get templates from bundled resources
    template_files = _get_resource_files("projspec_cli.resources.templates")

    for filename, resource in template_files:
        if filename.endswith(".md"):
            dest_path = templates_dir / filename
            content = resource.read_text()
            dest_path.write_text(content)
            created.append(f".specify/templates/{filename}")

    return created


def create_constitution(path: Path, project_name: str) -> str:
    """
    Create the initial constitution.md file in .specify/memory/.

    Args:
        path: The project root directory.
        project_name: The name of the project.

    Returns:
        The relative path to the created constitution file.
    """
    memory_dir = path / ".specify" / "memory"
    memory_dir.mkdir(parents=True, exist_ok=True)

    constitution_path = memory_dir / "constitution.md"

    # Try to load the template
    try:
        template_files = _get_resource_files("projspec_cli.resources.templates")
        template_content = ""
        for filename, resource in template_files:
            if filename == "constitution-template.md":
                template_content = resource.read_text()
                break

        if template_content:
            # Replace placeholders
            now = datetime.now()
            content = template_content.replace("{PROJECT_NAME}", project_name)
            content = content.replace("{VERSION}", "1.0.0")
            content = content.replace("{DATE}", now.strftime("%Y-%m-%d"))
        else:
            content = _get_default_constitution(project_name)
    except Exception:
        content = _get_default_constitution(project_name)

    constitution_path.write_text(content)
    return ".specify/memory/constitution.md"


def _get_default_constitution(project_name: str) -> str:
    """Get a minimal default constitution if template is not available."""
    now = datetime.now()
    return f"""# Project Constitution: {project_name}

**Version**: 1.0.0
**Created**: {now.strftime("%Y-%m-%d")}
**Last Updated**: {now.strftime("%Y-%m-%d")}

---

## Mission Statement

<!-- Define the core purpose of this project -->

---

## Core Principles

<!-- Add your guiding principles here -->

### 1. Quality First

**Statement**: We prioritize code quality and maintainability over speed of delivery.

**Rationale**: Technical debt compounds over time, making quality investments worthwhile.

---

## Technical Standards

### Code Quality

- All code must pass linting and formatting checks
- New code requires tests
- Documentation is required for public APIs

---

## Review Process

### When to Review

- Major version releases
- Significant architectural changes
- Annual review (at minimum)

---
"""


def create_claude_md(path: Path, project_name: str) -> str:
    """
    Create the CLAUDE.md file in the project root.

    Args:
        path: The project root directory.
        project_name: The name of the project.

    Returns:
        The relative path to the created CLAUDE.md file.
    """
    claude_md_path = path / "CLAUDE.md"

    # Try to load the template
    try:
        template_files = _get_resource_files("projspec_cli.resources.templates")
        template_content = ""
        for filename, resource in template_files:
            if filename == "agent-file-template.md":
                template_content = resource.read_text()
                break

        if template_content:
            # Replace placeholders with minimal initial values
            now = datetime.now()
            content = template_content.replace("{PROJECT_NAME}", project_name)
            content = content.replace("{DATE}", now.strftime("%Y-%m-%d"))
            content = content.replace(
                "{PROJECT_DESCRIPTION}",
                f"This is the {project_name} project.",
            )
            content = content.replace("{PROJECT_ROOT}", project_name)
        else:
            content = _get_default_claude_md(project_name)
    except Exception:
        content = _get_default_claude_md(project_name)

    claude_md_path.write_text(content)
    return "CLAUDE.md"


def _get_default_claude_md(project_name: str) -> str:
    """Get a minimal default CLAUDE.md if template is not available."""
    now = datetime.now()
    return f"""# {project_name} Development Guidelines

Auto-generated by ProjSpec. Last updated: {now.strftime("%Y-%m-%d")}

---

## Project Overview

This is the {project_name} project.

---

## Project Structure

```text
{project_name}/
├── .specify/           # ProjSpec configuration
│   ├── config.yaml     # Project configuration
│   ├── memory/         # Project memory (constitution, etc.)
│   ├── scripts/        # Helper scripts
│   └── templates/      # Document templates
├── specs/              # Feature specifications
├── worktrees/          # Git worktrees for features
└── CLAUDE.md           # This file
```

---

## Commands

<!-- Add project-specific commands here -->

---

## Code Style

<!-- Add code style guidelines here -->

---

<!-- MANUAL ADDITIONS START -->
<!-- Add any project-specific guidance that should persist across updates -->
<!-- MANUAL ADDITIONS END -->
"""


def initialize_project(
    path: Path,
    project_name: str,
    force: bool = False,
    no_git: bool = False,
) -> InitResult:
    """
    Initialize a new ProjSpec project.

    This is the main entry point for project initialization. It:
    1. Validates prerequisites (git repo, not already initialized)
    2. Creates the directory structure
    3. Creates the configuration file
    4. Copies scripts and templates
    5. Creates the constitution and CLAUDE.md files

    Args:
        path: The project root directory.
        project_name: The name of the project.
        force: If True, overwrite existing configuration.
        no_git: If True, skip git repository check.

    Returns:
        InitResult containing success status, message, and created files.
    """
    created_files: list[str] = []

    # Check if already initialized
    if check_already_initialized(path) and not force:
        return InitResult(
            success=False,
            message=f"ProjSpec is already initialized at {path}. Use --force to reinitialize.",
            exit_code=EXIT_ALREADY_INITIALIZED,
        )

    # Check if in git repository
    if not no_git and not is_git_repo(path):
        return InitResult(
            success=False,
            message=f"Not a git repository: {path}. Use --no-git to initialize anyway.",
            exit_code=EXIT_NOT_GIT_REPO,
        )

    # If force mode, clean up existing .specify directory
    if force:
        specify_dir = path / ".specify"
        if specify_dir.exists():
            shutil.rmtree(specify_dir)

    # Create directory structure
    created_dirs = create_directory_structure(path)
    created_files.extend(created_dirs)

    # Create config file
    config_file = create_config_file(path, project_name)
    created_files.append(config_file)

    # Copy scripts
    scripts = copy_scripts(path)
    created_files.extend(scripts)

    # Copy templates
    templates = copy_templates(path)
    created_files.extend(templates)

    # Create constitution
    constitution_file = create_constitution(path, project_name)
    created_files.append(constitution_file)

    # Create CLAUDE.md
    claude_md_file = create_claude_md(path, project_name)
    created_files.append(claude_md_file)

    return InitResult(
        success=True,
        message=f"Successfully initialized ProjSpec project '{project_name}' at {path}",
        created_files=created_files,
        exit_code=EXIT_SUCCESS,
    )

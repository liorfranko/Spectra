"""
Path resolution utilities.

Provides helper functions for path operations, including:
- Finding project root
- Resolving spec and worktree paths
- Configuration file location
"""

from __future__ import annotations

import re
from pathlib import Path

from projspec_cli.utils.git import get_main_repo_root, get_repo_root, is_worktree

# Pattern for feature directory names: NNN-feature-name (e.g., 001-user-auth)
FEATURE_DIR_PATTERN = re.compile(r"^(\d{3})-[a-z0-9]+(?:-[a-z0-9]+)*$")

# Directory and file names
SPECIFY_DIR_NAME = ".specify"
CONFIG_FILE_NAME = "config.yaml"
SPECS_DIR_NAME = "specs"
WORKTREES_DIR_NAME = "worktrees"
SPEC_FILE_NAME = "spec.md"
PLAN_FILE_NAME = "plan.md"
TASKS_FILE_NAME = "tasks.md"


def get_project_root(path: Path | None = None) -> Path | None:
    """
    Find the root directory of the ProjSpec project.

    This function locates the project root by looking for the .specify/ directory.
    It handles both main repository and worktree contexts:
    - In a worktree: follows symlinks to find the actual .specify/ directory
    - In main repo: looks for .specify/ directly

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the project root, or None if not found
    """
    cwd = path or Path.cwd()

    # If in a worktree, the .specify is typically a symlink to the main repo
    # We need to find where .specify actually lives
    if is_worktree(cwd):
        main_root = get_main_repo_root(cwd)
        if main_root is not None:
            specify_dir = main_root / SPECIFY_DIR_NAME
            if specify_dir.exists():
                return main_root

        # Also check if .specify exists in the worktree (could be a symlink)
        repo_root = get_repo_root(cwd)
        if repo_root is not None:
            specify_dir = repo_root / SPECIFY_DIR_NAME
            if specify_dir.exists():
                # Resolve symlink to get the actual root
                real_specify = specify_dir.resolve()
                return real_specify.parent

    # Not in a worktree or worktree check failed, look directly
    # Start from the given path and walk up
    current = cwd.resolve()
    while current != current.parent:
        specify_dir = current / SPECIFY_DIR_NAME
        if specify_dir.exists() and specify_dir.is_dir():
            return current
        current = current.parent

    # Check the root itself
    specify_dir = current / SPECIFY_DIR_NAME
    if specify_dir.exists() and specify_dir.is_dir():
        return current

    return None


def get_specify_dir(path: Path | None = None) -> Path | None:
    """
    Get the path to the .specify/ directory.

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the .specify/ directory, or None if not found
    """
    root = get_project_root(path)
    if root is None:
        return None

    specify_dir = root / SPECIFY_DIR_NAME
    if specify_dir.exists():
        return specify_dir

    return None


def get_config_path(path: Path | None = None) -> Path | None:
    """
    Get the path to the .specify/config.yaml configuration file.

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the config.yaml file, or None if not found
    """
    specify_dir = get_specify_dir(path)
    if specify_dir is None:
        return None

    config_path = specify_dir / CONFIG_FILE_NAME
    if config_path.exists():
        return config_path

    return None


def get_specs_dir(path: Path | None = None) -> Path | None:
    """
    Get the path to the specs/ directory.

    This handles both main repository and worktree contexts:
    - In worktree: specs/ may be a symlink to ../../specs
    - In main repo: specs/ is directly in the root

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the specs/ directory, or None if not found
    """
    root = get_project_root(path)
    if root is None:
        return None

    specs_dir = root / SPECS_DIR_NAME
    if specs_dir.exists():
        return specs_dir

    # If in a worktree, also check for specs/ in the current worktree root
    cwd = path or Path.cwd()
    if is_worktree(cwd):
        worktree_root = get_repo_root(cwd)
        if worktree_root is not None:
            specs_dir = worktree_root / SPECS_DIR_NAME
            if specs_dir.exists():
                return specs_dir

    return None


def get_worktrees_dir(path: Path | None = None) -> Path | None:
    """
    Get the path to the worktrees/ directory.

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the worktrees/ directory, or None if not found
    """
    root = get_project_root(path)
    if root is None:
        return None

    worktrees_dir = root / WORKTREES_DIR_NAME
    if worktrees_dir.exists():
        return worktrees_dir

    return None


def _find_feature_dir(feature_id: str, specs_dir: Path) -> Path | None:
    """
    Find a feature directory by its ID prefix or full name.

    Args:
        feature_id: Feature ID (e.g., "001" or "001-user-auth")
        specs_dir: Path to the specs directory

    Returns:
        Path to the feature directory, or None if not found
    """
    if not specs_dir.exists():
        return None

    # Normalize feature_id - extract just the number if full name given
    if FEATURE_DIR_PATTERN.match(feature_id):
        # Full feature name provided (e.g., "001-user-auth")
        feature_dir = specs_dir / feature_id
        if feature_dir.exists() and feature_dir.is_dir():
            return feature_dir
        return None

    # Just the number provided (e.g., "001" or "1")
    # Normalize to 3 digits
    try:
        feature_num = int(feature_id)
        feature_prefix = f"{feature_num:03d}-"
    except ValueError:
        return None

    # Scan for matching directory
    for item in specs_dir.iterdir():
        if (
            item.is_dir()
            and item.name.startswith(feature_prefix)
            and FEATURE_DIR_PATTERN.match(item.name)
        ):
            return item

    return None


def get_feature_dir(feature_id: str, path: Path | None = None) -> Path | None:
    """
    Get the path to a feature's directory in specs/.

    Args:
        feature_id: Feature ID (e.g., "001" or "001-user-auth")
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the feature directory (specs/NNN-feature-name/), or None if not found
    """
    specs_dir = get_specs_dir(path)
    if specs_dir is None:
        return None

    return _find_feature_dir(feature_id, specs_dir)


def get_feature_spec_path(feature_id: str, path: Path | None = None) -> Path | None:
    """
    Get the path to a feature's spec.md file.

    Args:
        feature_id: Feature ID (e.g., "001" or "001-user-auth")
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the spec.md file, or None if not found
    """
    feature_dir = get_feature_dir(feature_id, path)
    if feature_dir is None:
        return None

    spec_path = feature_dir / SPEC_FILE_NAME
    if spec_path.exists():
        return spec_path

    return None


def get_feature_plan_path(feature_id: str, path: Path | None = None) -> Path | None:
    """
    Get the path to a feature's plan.md file.

    Args:
        feature_id: Feature ID (e.g., "001" or "001-user-auth")
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the plan.md file, or None if not found
    """
    feature_dir = get_feature_dir(feature_id, path)
    if feature_dir is None:
        return None

    plan_path = feature_dir / PLAN_FILE_NAME
    if plan_path.exists():
        return plan_path

    return None


def get_feature_tasks_path(feature_id: str, path: Path | None = None) -> Path | None:
    """
    Get the path to a feature's tasks.md file.

    Args:
        feature_id: Feature ID (e.g., "001" or "001-user-auth")
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to the tasks.md file, or None if not found
    """
    feature_dir = get_feature_dir(feature_id, path)
    if feature_dir is None:
        return None

    tasks_path = feature_dir / TASKS_FILE_NAME
    if tasks_path.exists():
        return tasks_path

    return None


def list_features(path: Path | None = None) -> list[str]:
    """
    List all feature IDs (NNN-name format) in the specs/ directory.

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Sorted list of feature directory names (e.g., ["001-user-auth", "002-data-model"])
    """
    specs_dir = get_specs_dir(path)
    if specs_dir is None or not specs_dir.exists():
        return []

    features = []
    for item in specs_dir.iterdir():
        if item.is_dir() and FEATURE_DIR_PATTERN.match(item.name):
            features.append(item.name)

    # Sort by feature number
    return sorted(features)


def get_next_feature_number(path: Path | None = None) -> int:
    """
    Get the next available feature number.

    Scans the specs/ directory and returns the next sequential number.

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Next available feature number (e.g., if 001 and 002 exist, returns 3)
    """
    features = list_features(path)

    if not features:
        return 1

    # Extract numbers from feature names
    max_num = 0
    for feature_name in features:
        match = FEATURE_DIR_PATTERN.match(feature_name)
        if match:
            num = int(match.group(1))
            if num > max_num:
                max_num = num

    return max_num + 1


# Backwards compatibility aliases
def find_project_root() -> Path | None:
    """Find the root directory of the ProjSpec project.

    Deprecated: Use get_project_root() instead.
    """
    return get_project_root()

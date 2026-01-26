"""
Git utilities.

Provides helper functions for Git operations, including:
- Repository detection and validation
- Worktree management
- Branch operations
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

# Pattern for valid feature branch names: NNN-feature-name (e.g., 001-user-auth)
FEATURE_BRANCH_PATTERN = re.compile(r"^\d{3}-[a-z0-9]+(?:-[a-z0-9]+)*$")


def _run_git_command(
    args: list[str],
    cwd: Path | None = None,
    capture_output: bool = True,
) -> subprocess.CompletedProcess[str] | None:
    """
    Run a git command and return the result.

    Args:
        args: Git command arguments (without 'git' prefix)
        cwd: Working directory for the command
        capture_output: Whether to capture stdout/stderr

    Returns:
        CompletedProcess on success, None on failure
    """
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=cwd,
            capture_output=capture_output,
            text=True,
            check=False,
        )
        if result.returncode == 0:
            return result
        return None
    except (FileNotFoundError, OSError):
        return None


def has_git() -> bool:
    """
    Check if git is available on the system.

    Returns:
        True if git is available, False otherwise
    """
    result = _run_git_command(["--version"])
    return result is not None


def is_git_repo(path: Path | None = None) -> bool:
    """
    Check if the given path is inside a Git repository.

    Args:
        path: Path to check (defaults to current directory)

    Returns:
        True if inside a git repository, False otherwise
    """
    cwd = path or Path.cwd()
    result = _run_git_command(["rev-parse", "--git-dir"], cwd=cwd)
    return result is not None


def get_repo_root(path: Path | None = None) -> Path | None:
    """
    Find the repository root (handles worktrees).

    For a worktree, this returns the worktree's root directory,
    not the main repository root.

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to repository root, or None if not in a git repository
    """
    cwd = path or Path.cwd()
    result = _run_git_command(["rev-parse", "--show-toplevel"], cwd=cwd)
    if result is not None:
        return Path(result.stdout.strip())
    return None


def get_main_repo_root(path: Path | None = None) -> Path | None:
    """
    Find the main repository root (not worktree).

    For a worktree, this returns the main repository's root,
    not the worktree's directory.

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        Path to main repository root, or None if not in a git repository
    """
    cwd = path or Path.cwd()

    # First check if we're in a worktree
    result = _run_git_command(["rev-parse", "--git-common-dir"], cwd=cwd)
    if result is None:
        return None

    git_common_dir = Path(result.stdout.strip())

    # If it's an absolute path, resolve it; otherwise resolve relative to cwd
    if not git_common_dir.is_absolute():
        # Get the git dir first
        git_dir_result = _run_git_command(["rev-parse", "--git-dir"], cwd=cwd)
        if git_dir_result is None:
            return None
        git_dir = Path(git_dir_result.stdout.strip())
        if not git_dir.is_absolute():
            git_dir = cwd / git_dir
        git_common_dir = (git_dir / git_common_dir).resolve()

    # The common dir is the .git directory of the main repo
    # The main repo root is its parent (unless it's a bare repo)
    if git_common_dir.name == ".git":
        return git_common_dir.parent
    return git_common_dir.parent


def get_current_branch(path: Path | None = None) -> str | None:
    """
    Get the name of the current Git branch.

    Args:
        path: Path within the repository (defaults to current directory)

    Returns:
        Branch name, or None if not in a git repository or in detached HEAD state
    """
    cwd = path or Path.cwd()
    result = _run_git_command(["rev-parse", "--abbrev-ref", "HEAD"], cwd=cwd)
    if result is not None:
        branch = result.stdout.strip()
        # In detached HEAD state, git returns "HEAD"
        if branch != "HEAD":
            return branch
    return None


def is_worktree(path: Path | None = None) -> bool:
    """
    Check if the current directory is a git worktree.

    Args:
        path: Path to check (defaults to current directory)

    Returns:
        True if in a worktree, False otherwise
    """
    cwd = path or Path.cwd()

    # Get both the git-dir and git-common-dir
    git_dir_result = _run_git_command(["rev-parse", "--git-dir"], cwd=cwd)
    common_dir_result = _run_git_command(["rev-parse", "--git-common-dir"], cwd=cwd)

    if git_dir_result is None or common_dir_result is None:
        return False

    git_dir = git_dir_result.stdout.strip()
    common_dir = common_dir_result.stdout.strip()

    # In a worktree, git-dir and git-common-dir are different
    # Resolve paths to compare properly
    git_dir_path = Path(git_dir)
    common_dir_path = Path(common_dir)

    if not git_dir_path.is_absolute():
        git_dir_path = (cwd / git_dir_path).resolve()
    else:
        git_dir_path = git_dir_path.resolve()

    if not common_dir_path.is_absolute():
        common_dir_path = (cwd / git_dir_path.parent / common_dir_path).resolve()
    else:
        common_dir_path = common_dir_path.resolve()

    return git_dir_path != common_dir_path


def get_worktree_path(branch: str, repo_root: Path | None = None) -> Path | None:
    """
    Get the worktree path for a given branch.

    Args:
        branch: Branch name to find worktree for
        repo_root: Repository root (defaults to current repo)

    Returns:
        Path to the worktree, or None if no worktree exists for the branch
    """
    cwd = repo_root or Path.cwd()

    # List all worktrees
    worktrees = list_worktrees(cwd)

    for wt in worktrees:
        if wt.get("branch") == branch:
            path_str = wt.get("path")
            if path_str:
                return Path(path_str)

    return None


def list_worktrees(repo_root: Path | None = None) -> list[dict]:
    """
    List all worktrees in the repository.

    Args:
        repo_root: Repository root (defaults to current repo)

    Returns:
        List of dictionaries with worktree info:
        - path: Absolute path to worktree
        - head: HEAD commit SHA
        - branch: Branch name (or None for detached HEAD)
        - bare: Whether it's a bare worktree
        - locked: Whether the worktree is locked
        - prunable: Whether the worktree can be pruned
    """
    cwd = repo_root or Path.cwd()

    result = _run_git_command(["worktree", "list", "--porcelain"], cwd=cwd)
    if result is None:
        return []

    worktrees = []
    current_wt: dict = {}

    for line in result.stdout.strip().split("\n"):
        if not line:
            if current_wt:
                worktrees.append(current_wt)
                current_wt = {}
            continue

        if line.startswith("worktree "):
            current_wt["path"] = line[9:]
        elif line.startswith("HEAD "):
            current_wt["head"] = line[5:]
        elif line.startswith("branch "):
            # Branch is in refs/heads/name format
            branch_ref = line[7:]
            if branch_ref.startswith("refs/heads/"):
                current_wt["branch"] = branch_ref[11:]
            else:
                current_wt["branch"] = branch_ref
        elif line == "bare":
            current_wt["bare"] = True
        elif line == "detached":
            current_wt["branch"] = None
        elif line == "locked":
            current_wt["locked"] = True
        elif line == "prunable":
            current_wt["prunable"] = True

    # Don't forget the last worktree
    if current_wt:
        worktrees.append(current_wt)

    return worktrees


def is_valid_feature_branch(branch: str) -> bool:
    """
    Validate that a branch name follows the feature branch pattern.

    Valid pattern: NNN-feature-name (e.g., 001-user-auth, 002-projspec-claude-code)
    - NNN: Three digits
    - feature-name: Lowercase alphanumeric with hyphens

    Args:
        branch: Branch name to validate

    Returns:
        True if branch name is valid, False otherwise
    """
    return bool(FEATURE_BRANCH_PATTERN.match(branch))


def get_worktree_info(path: Path | None = None) -> dict | None:
    """
    Get information about the current worktree, if any.

    Args:
        path: Path to check (defaults to current directory)

    Returns:
        Dictionary with worktree info, or None if not in a worktree
    """
    cwd = path or Path.cwd()

    if not is_worktree(cwd):
        return None

    repo_root = get_repo_root(cwd)
    if repo_root is None:
        return None

    branch = get_current_branch(cwd)

    # Get the main repo root
    main_root = get_main_repo_root(cwd)

    return {
        "path": str(repo_root),
        "branch": branch,
        "main_repo": str(main_root) if main_root else None,
        "is_feature_branch": is_valid_feature_branch(branch) if branch else False,
    }


def extract_feature_id(branch: str) -> str | None:
    """
    Extract the feature ID (NNN) from a feature branch name.

    Args:
        branch: Branch name (e.g., "001-user-auth")

    Returns:
        Feature ID (e.g., "001"), or None if not a valid feature branch
    """
    if not is_valid_feature_branch(branch):
        return None
    return branch[:3]

"""Git repository verification utilities for E2E tests.

This module provides utilities for asserting git repository state,
including branch names, worktrees, and commit history.
"""

import re
import subprocess
from pathlib import Path


class GitVerifier:
    """Utility for asserting git repository state.

    This class provides methods to verify various aspects of a git repository,
    including whether it's a valid repo, branch names, worktree existence,
    and commit history.

    Attributes:
        repo_path: Path to the git repository root.

    Example:
        >>> verifier = GitVerifier(Path("/path/to/repo"))
        >>> verifier.assert_is_repo()
        >>> verifier.assert_branch_matches(r"feature/.*", "feature branch")
    """

    def __init__(self, repo_path: Path) -> None:
        """Initialize the GitVerifier.

        Args:
            repo_path: Path to the git repository root.
        """
        self.repo_path = repo_path

    def _run_git_command(self, args: list[str]) -> subprocess.CompletedProcess[str]:
        """Run a git command and return the result.

        Args:
            args: List of arguments to pass to git.

        Returns:
            CompletedProcess with stdout, stderr, and returncode.
        """
        return subprocess.run(
            ["git"] + args,
            cwd=self.repo_path,
            capture_output=True,
            text=True,
        )

    def assert_is_repo(self) -> None:
        """Assert that the path is a valid git repository.

        Raises:
            AssertionError: If the path is not a git repository.
        """
        result = self._run_git_command(["rev-parse", "--is-inside-work-tree"])
        if result.returncode != 0 or result.stdout.strip() != "true":
            raise AssertionError(
                f"Expected '{self.repo_path}' to be a git repository, "
                f"but git rev-parse failed: {result.stderr.strip()}"
            )

    def assert_branch_matches(self, pattern: str, description: str) -> None:
        """Assert that the current branch name matches a pattern.

        Args:
            pattern: Regular expression pattern to match against the branch name.
            description: Human-readable description of expected branch for error message.

        Raises:
            AssertionError: If the branch name doesn't match the pattern.
        """
        result = self._run_git_command(["branch", "--show-current"])
        if result.returncode != 0:
            raise AssertionError(
                f"Expected {description}, but failed to get current branch: "
                f"{result.stderr.strip()}"
            )

        branch_name = result.stdout.strip()
        if not re.search(pattern, branch_name):
            raise AssertionError(
                f"Expected {description} matching pattern '{pattern}', "
                f"but found branch '{branch_name}'"
            )

    def assert_worktree_exists(self, pattern: str) -> None:
        """Assert that a worktree matching the pattern exists.

        Args:
            pattern: Regular expression pattern to match against worktree paths.

        Raises:
            AssertionError: If no worktree matches the pattern.
        """
        result = self._run_git_command(["worktree", "list", "--porcelain"])
        if result.returncode != 0:
            raise AssertionError(
                f"Expected worktree matching '{pattern}', but failed to list worktrees: "
                f"{result.stderr.strip()}"
            )

        worktrees = self._parse_worktrees(result.stdout)
        for worktree_path in worktrees:
            if re.search(pattern, str(worktree_path)):
                return

        raise AssertionError(
            f"Expected worktree matching pattern '{pattern}', "
            f"but no matching worktree found. Available worktrees: {worktrees}"
        )

    def get_worktree_path(self, pattern: str) -> Path | None:
        """Return the path to the first worktree matching the pattern.

        Args:
            pattern: Regular expression pattern to match against worktree paths.

        Returns:
            Path to the first matching worktree, or None if no match found.
        """
        result = self._run_git_command(["worktree", "list", "--porcelain"])
        if result.returncode != 0:
            return None

        worktrees = self._parse_worktrees(result.stdout)
        for worktree_path in worktrees:
            if re.search(pattern, str(worktree_path)):
                return worktree_path

        return None

    def _parse_worktrees(self, porcelain_output: str) -> list[Path]:
        """Parse git worktree list --porcelain output.

        Args:
            porcelain_output: Output from git worktree list --porcelain.

        Returns:
            List of Path objects for each worktree.
        """
        worktrees = []
        for line in porcelain_output.split("\n"):
            if line.startswith("worktree "):
                path_str = line[len("worktree ") :]
                worktrees.append(Path(path_str))
        return worktrees

    def assert_min_commits(
        self,
        count: int,
        message_pattern: str | None = None,
        path: Path | None = None,
        description: str | None = None,
    ) -> None:
        """Assert that the repository has at least a minimum number of commits.

        Args:
            count: Minimum number of commits expected.
            message_pattern: Optional regex pattern to filter commits by message.
            path: Optional path to run git commands in (for worktrees).
            description: Human-readable description for error message.

        Raises:
            AssertionError: If fewer commits exist than required.
        """
        # Determine which path to use
        git_path = path if path is not None else self.repo_path

        # Build git command
        if message_pattern:
            # Filter by message pattern
            result = subprocess.run(
                ["git", "log", "--oneline", "--format=%s"],
                cwd=git_path,
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                raise AssertionError(
                    f"Failed to get commit log at '{git_path}': {result.stderr.strip()}"
                )

            commit_messages = result.stdout.strip().split("\n")
            matching_commits = [
                msg for msg in commit_messages if msg and re.search(message_pattern, msg)
            ]
            matching_count = len(matching_commits)

            if matching_count < count:
                desc = description or f"commits matching '{message_pattern}'"
                raise AssertionError(
                    f"Expected at least {count} {desc}, "
                    f"but found only {matching_count} matching commits. "
                    f"Recent commit messages: {commit_messages[:10]}"
                )
        else:
            # Count all commits
            result = subprocess.run(
                ["git", "rev-list", "--count", "HEAD"],
                cwd=git_path,
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                raise AssertionError(
                    f"Failed to count commits at '{git_path}': {result.stderr.strip()}"
                )

            try:
                commit_count = int(result.stdout.strip())
            except ValueError:
                commit_count = 0

            if commit_count < count:
                desc = description or "commits"
                raise AssertionError(
                    f"Expected at least {count} {desc}, "
                    f"but found only {commit_count} commits"
                )

    def assert_commits_with_pattern(
        self, pattern: str, min_count: int, description: str
    ) -> None:
        """Assert that sufficient commits exist with messages matching a pattern.

        Args:
            pattern: Regular expression pattern to match against commit messages.
            min_count: Minimum number of matching commits required.
            description: Human-readable description for error message.

        Raises:
            AssertionError: If insufficient matching commits exist.
        """
        result = self._run_git_command(["log", "--oneline", "--format=%s"])
        if result.returncode != 0:
            raise AssertionError(
                f"Expected {description} with commits matching '{pattern}', "
                f"but failed to get commit log: {result.stderr.strip()}"
            )

        commit_messages = result.stdout.strip().split("\n")
        matching_commits = [
            msg for msg in commit_messages if msg and re.search(pattern, msg)
        ]

        if len(matching_commits) < min_count:
            raise AssertionError(
                f"Expected {description} with at least {min_count} commits "
                f"matching pattern '{pattern}', but found only {len(matching_commits)} "
                f"matching commits. Matching: {matching_commits}"
            )

    def get_commit_count(self) -> int:
        """Return the total number of commits in the repository.

        Returns:
            Total commit count, or 0 if unable to count commits.
        """
        result = self._run_git_command(["rev-list", "--count", "HEAD"])
        if result.returncode != 0:
            return 0

        try:
            return int(result.stdout.strip())
        except ValueError:
            return 0

    def count_worktrees(self) -> int:
        """Return the number of worktrees in the repository.

        Returns:
            Number of worktrees, or 0 if unable to list worktrees.
        """
        result = self._run_git_command(["worktree", "list", "--porcelain"])
        if result.returncode != 0:
            return 0

        worktrees = self._parse_worktrees(result.stdout)
        return len(worktrees)

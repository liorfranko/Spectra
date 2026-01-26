"""File verification utilities for E2E tests.

This module provides utilities for asserting file existence, content patterns,
and other file-related conditions in a structured format.
"""

import re
from pathlib import Path


class FileVerifier:
    """Utility for asserting file existence and content.

    This class provides methods to verify file system conditions commonly
    needed in E2E tests, such as checking file existence, content patterns,
    and line counts.

    Attributes:
        base_path: Base directory for relative path resolution.

    Example:
        >>> verifier = FileVerifier(Path("/project"))
        >>> verifier.assert_exists("README.md", "Project README")
        >>> verifier.assert_contains("config.py", r"DEBUG\\s*=", "Debug setting")
    """

    def __init__(self, base_path: Path) -> None:
        """Initialize the FileVerifier.

        Args:
            base_path: Base directory for relative path resolution.
                All path arguments to methods are resolved relative to this.
        """
        self.base_path = base_path

    def _resolve_path(self, path: str) -> Path:
        """Resolve a relative path against the base path.

        Args:
            path: Relative path string.

        Returns:
            Absolute Path object.
        """
        return self.base_path / path

    def assert_exists(self, path: str, description: str) -> None:
        """Assert that a file exists at the given path.

        Args:
            path: Relative path to the file.
            description: Human-readable description for error messages.

        Raises:
            AssertionError: If the file does not exist or is not a file.

        Example:
            >>> verifier.assert_exists("src/main.py", "Main entry point")
        """
        full_path = self._resolve_path(path)

        if not full_path.exists():
            raise AssertionError(
                f"{description}: Expected file '{path}' to exist at "
                f"'{full_path}', but it was not found."
            )

        if not full_path.is_file():
            raise AssertionError(
                f"{description}: Expected '{path}' to be a file at "
                f"'{full_path}', but it is a directory."
            )

    def assert_dir_exists(self, path: str, description: str) -> None:
        """Assert that a directory exists at the given path.

        Args:
            path: Relative path to the directory.
            description: Human-readable description for error messages.

        Raises:
            AssertionError: If the directory does not exist or is not a directory.

        Example:
            >>> verifier.assert_dir_exists("src/", "Source directory")
        """
        full_path = self._resolve_path(path)

        if not full_path.exists():
            raise AssertionError(
                f"{description}: Expected directory '{path}' to exist at "
                f"'{full_path}', but it was not found."
            )

        if not full_path.is_dir():
            raise AssertionError(
                f"{description}: Expected '{path}' to be a directory at "
                f"'{full_path}', but it is a file."
            )

    def assert_contains(self, path: str, pattern: str, description: str) -> None:
        """Assert that a file contains content matching the given regex pattern.

        Args:
            path: Relative path to the file.
            pattern: Regular expression pattern to search for.
            description: Human-readable description for error messages.

        Raises:
            AssertionError: If the file does not exist or does not contain
                content matching the pattern.

        Example:
            >>> verifier.assert_contains(
            ...     "config.py",
            ...     r"API_KEY\\s*=",
            ...     "API key configuration"
            ... )
        """
        full_path = self._resolve_path(path)

        if not full_path.exists():
            raise AssertionError(
                f"{description}: Cannot check pattern in '{path}' - "
                f"file does not exist at '{full_path}'."
            )

        if not full_path.is_file():
            raise AssertionError(
                f"{description}: Cannot check pattern in '{path}' - "
                f"path is a directory, not a file."
            )

        try:
            content = full_path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as e:
            raise AssertionError(
                f"{description}: Cannot read file '{path}' at "
                f"'{full_path}': {e}"
            ) from e

        if not re.search(pattern, content):
            # Truncate content for error message if too long
            preview = content[:500] + "..." if len(content) > 500 else content
            raise AssertionError(
                f"{description}: Expected file '{path}' to contain pattern "
                f"'{pattern}', but pattern was not found.\n"
                f"File content preview:\n{preview}"
            )

    def assert_not_empty(self, path: str, description: str) -> None:
        """Assert that a file is not empty.

        Args:
            path: Relative path to the file.
            description: Human-readable description for error messages.

        Raises:
            AssertionError: If the file does not exist or is empty.

        Example:
            >>> verifier.assert_not_empty("output.log", "Output log file")
        """
        full_path = self._resolve_path(path)

        if not full_path.exists():
            raise AssertionError(
                f"{description}: Cannot check if '{path}' is empty - "
                f"file does not exist at '{full_path}'."
            )

        if not full_path.is_file():
            raise AssertionError(
                f"{description}: Cannot check if '{path}' is empty - "
                f"path is a directory, not a file."
            )

        try:
            content = full_path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as e:
            raise AssertionError(
                f"{description}: Cannot read file '{path}' at "
                f"'{full_path}': {e}"
            ) from e

        if not content.strip():
            raise AssertionError(
                f"{description}: Expected file '{path}' to not be empty, "
                f"but it is empty or contains only whitespace."
            )

    def assert_min_lines(self, path: str, min_lines: int, description: str) -> None:
        """Assert that a file has at least the specified number of lines.

        Args:
            path: Relative path to the file.
            min_lines: Minimum number of lines expected.
            description: Human-readable description for error messages.

        Raises:
            AssertionError: If the file does not exist or has fewer lines
                than the minimum.

        Example:
            >>> verifier.assert_min_lines("data.csv", 10, "Data file")
        """
        full_path = self._resolve_path(path)

        if not full_path.exists():
            raise AssertionError(
                f"{description}: Cannot count lines in '{path}' - "
                f"file does not exist at '{full_path}'."
            )

        if not full_path.is_file():
            raise AssertionError(
                f"{description}: Cannot count lines in '{path}' - "
                f"path is a directory, not a file."
            )

        try:
            content = full_path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as e:
            raise AssertionError(
                f"{description}: Cannot read file '{path}' at "
                f"'{full_path}': {e}"
            ) from e

        line_count = len(content.splitlines())

        if line_count < min_lines:
            raise AssertionError(
                f"{description}: Expected file '{path}' to have at least "
                f"{min_lines} lines, but found only {line_count} lines."
            )

    def count_pattern(self, path: str, pattern: str) -> int:
        """Count the number of regex pattern matches in a file.

        Args:
            path: Relative path to the file.
            pattern: Regular expression pattern to count.

        Returns:
            Number of non-overlapping matches found.

        Raises:
            FileNotFoundError: If the file does not exist.
            IsADirectoryError: If the path is a directory.
            OSError: If the file cannot be read.

        Example:
            >>> count = verifier.count_pattern("log.txt", r"ERROR:")
            >>> print(f"Found {count} errors")
        """
        full_path = self._resolve_path(path)

        if not full_path.exists():
            raise FileNotFoundError(
                f"Cannot count pattern in '{path}' - "
                f"file does not exist at '{full_path}'."
            )

        if not full_path.is_file():
            raise IsADirectoryError(
                f"Cannot count pattern in '{path}' - "
                f"path is a directory, not a file."
            )

        content = full_path.read_text(encoding="utf-8")
        matches = re.findall(pattern, content)
        return len(matches)

    def find_file(self, patterns: list[str]) -> Path | None:
        """Find the first existing file from a list of path patterns.

        Args:
            patterns: List of relative path patterns to check in order.

        Returns:
            Absolute Path to the first existing file, or None if no file
            is found.

        Example:
            >>> readme = verifier.find_file([
            ...     "README.md",
            ...     "readme.md",
            ...     "README.txt"
            ... ])
            >>> if readme:
            ...     print(f"Found readme at {readme}")
        """
        for pattern in patterns:
            full_path = self._resolve_path(pattern)
            if full_path.exists() and full_path.is_file():
                return full_path

        return None

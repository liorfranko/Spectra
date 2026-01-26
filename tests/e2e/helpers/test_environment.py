"""Test environment management for E2E tests.

This module provides utilities for managing test project lifecycle,
including directory creation, fixture copying, and git initialization.
"""

import shutil
import subprocess
from datetime import datetime
from pathlib import Path


class E2EProject:
    """Manages test project lifecycle for E2E tests.

    This class handles the creation and setup of isolated test project
    directories, including copying fixtures, initializing git repositories,
    and creating log directories.

    Projects are NOT automatically cleaned up after tests. They remain in
    `tests/e2e/output/test-projects/` for debugging purposes.

    Attributes:
        project_name: Base name for the test project (e.g., "todo-app").
        tests_root: Path to the tests directory root.
        project_path: Absolute path to created project (set after setup()).
        log_dir: Timestamped log directory for this run.
        fixture_dir: Source fixture directory (tests/fixtures/{project_name}/).
        output_dir: Base output directory (tests/e2e/output/).
        timestamp: Run timestamp in YYYYMMDD-HHMMSS format.

    Example:
        >>> project = E2EProject("todo-app", Path("/path/to/tests"))
        >>> project_path = project.setup()
        >>> print(f"Project created at: {project_path}")
        >>> log_file = project.get_log_file(1, "init")
        >>> print(f"Log file: {log_file}")
    """

    def __init__(self, project_name: str, tests_root: Path) -> None:
        """Initialize the E2EProject.

        Args:
            project_name: Base name for the test project. Must be a valid
                directory name (e.g., "todo-app").
            tests_root: Path to the tests directory root. Fixture and output
                directories are resolved relative to this path.

        Raises:
            ValueError: If project_name is empty or contains invalid characters.
        """
        if not project_name or not project_name.strip():
            raise ValueError("project_name cannot be empty")

        # Basic validation for directory name
        invalid_chars = ['/', '\\', '\0', ':', '*', '?', '"', '<', '>', '|']
        for char in invalid_chars:
            if char in project_name:
                raise ValueError(
                    f"project_name contains invalid character: '{char}'"
                )

        self.project_name = project_name
        self.tests_root = tests_root
        self.project_path: Path | None = None
        self.log_dir: Path | None = None
        self.fixture_dir = tests_root / "fixtures" / project_name
        self.output_dir = tests_root / "e2e" / "output"
        self.timestamp: str = ""
        self.plugin_dir: Path | None = None

    def setup(self) -> Path:
        """Create and initialize the test project directory.

        This method performs the following steps:
        1. Generates a timestamp for unique directory naming
        2. Creates the log directory: tests_root/e2e/output/logs/{timestamp}/
        3. Creates project directory: tests_root/e2e/output/test-projects/{timestamp}-{project_name}/
        4. Copies fixture files if the fixture directory exists
        5. Initializes a git repository
        6. Creates an initial commit

        Returns:
            Absolute path to the created project directory.

        Raises:
            RuntimeError: If git initialization or commit fails.
            OSError: If directory creation fails.

        Example:
            >>> project = E2EProject("todo-app", Path("/path/to/tests"))
            >>> project_path = project.setup()
            >>> assert project_path.exists()
        """
        # Generate timestamp
        self.timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

        # Create log directory
        self.log_dir = self.output_dir / "logs" / self.timestamp
        self.log_dir.mkdir(parents=True, exist_ok=True)

        # Create project directory
        project_dir_name = f"{self.timestamp}-{self.project_name}"
        self.project_path = self.output_dir / "test-projects" / project_dir_name
        self.project_path.mkdir(parents=True, exist_ok=True)

        # Copy fixture files if they exist
        if self.fixture_dir.exists() and self.fixture_dir.is_dir():
            self._copy_fixture()

        # Initialize git repository
        self._init_git_repository()

        # Locate projspec plugin directory
        self._locate_projspec_plugin()

        return self.project_path

    def _copy_fixture(self) -> None:
        """Copy fixture files to the project directory.

        Copies all files and directories from the fixture directory to the
        project directory, preserving directory structure.
        """
        if self.project_path is None:
            return

        for item in self.fixture_dir.iterdir():
            src = item
            dst = self.project_path / item.name

            if item.is_dir():
                shutil.copytree(src, dst)
            else:
                shutil.copy2(src, dst)

    def _init_git_repository(self) -> None:
        """Initialize a git repository and create an initial commit.

        Raises:
            RuntimeError: If git init or commit fails.
        """
        if self.project_path is None:
            return

        # Initialize git repository
        result = subprocess.run(
            ["git", "init"],
            cwd=self.project_path,
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(
                f"Failed to initialize git repository: {result.stderr}"
            )

        # Configure git user for commits (local to this repo)
        subprocess.run(
            ["git", "config", "user.email", "e2e-test@projspec.local"],
            cwd=self.project_path,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "E2E Test"],
            cwd=self.project_path,
            capture_output=True,
            text=True,
        )

        # Add all files if any exist
        subprocess.run(
            ["git", "add", "-A"],
            cwd=self.project_path,
            capture_output=True,
            text=True,
        )

        # Create initial commit
        result = subprocess.run(
            ["git", "commit", "--allow-empty", "-m", "Initial commit for E2E test"],
            cwd=self.project_path,
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(
                f"Failed to create initial commit: {result.stderr}"
            )

    def _locate_projspec_plugin(self) -> None:
        """Locate and install the projspec plugin into the test project.

        This method finds the projspec plugin from the local development
        path and copies the necessary directories (.specify/, .claude/)
        to the test project so Claude Code can use projspec commands.

        Raises:
            RuntimeError: If plugin directory cannot be found.
        """
        if self.project_path is None:
            return

        # Determine the projspec plugin path
        # The plugin is located at the repo root /projspec directory
        # We need to find the repo root by going up from tests_root
        repo_root = self.tests_root.parent
        plugin_path = repo_root / "projspec"

        # If running in a worktree, the plugin path may be different
        # Check if the plugin exists at the expected path
        if not plugin_path.exists():
            # Try to find it relative to the worktree structure
            # worktrees/XXX/tests -> ../../projspec
            potential_path = self.tests_root.parent.parent.parent / "projspec"
            if potential_path.exists():
                plugin_path = potential_path

        if not plugin_path.exists():
            raise RuntimeError(
                f"Could not find projspec plugin at {plugin_path}. "
                "Ensure the projspec plugin directory exists."
            )

        self.plugin_dir = plugin_path

        # Copy plugin directories to test project
        # The plugin structure contains .specify/ in the main repo
        # and plugin config in projspec/plugins/projspec/
        main_repo_root = plugin_path.parent

        # Copy .specify/ from main repo to test project
        source_specify = main_repo_root / ".specify"
        if source_specify.exists():
            dest_specify = self.project_path / ".specify"
            shutil.copytree(source_specify, dest_specify, dirs_exist_ok=True)

        # Copy .claude/ from main repo to test project (if exists)
        source_claude = main_repo_root / ".claude"
        if source_claude.exists():
            dest_claude = self.project_path / ".claude"
            shutil.copytree(source_claude, dest_claude, dirs_exist_ok=True)

    def get_log_file(self, stage: int, stage_name: str) -> Path:
        """Get the log file path for a specific stage.

        Returns a path in the format:
        tests_root/e2e/output/logs/{timestamp}/{NN}-{stage_name}.log

        Args:
            stage: Stage number (used for ordering, formatted as 2 digits).
            stage_name: Descriptive name for the stage (e.g., "init", "specify").

        Returns:
            Path to the log file for this stage.

        Raises:
            RuntimeError: If setup() has not been called yet.

        Example:
            >>> project = E2EProject("todo-app", tests_root)
            >>> project.setup()
            >>> log = project.get_log_file(1, "init")
            >>> # Returns: tests_root/e2e/output/logs/20260126-143022/01-init.log
        """
        if self.log_dir is None:
            raise RuntimeError(
                "Cannot get log file path before setup() is called"
            )

        log_filename = f"{stage:02d}-{stage_name}.log"
        return self.log_dir / log_filename

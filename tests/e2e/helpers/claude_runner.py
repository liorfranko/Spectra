"""Claude CLI runner utilities for E2E tests.

This module provides utilities for executing Claude CLI commands and
capturing their results in a structured format.
"""

import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ClaudeResult:
    """Immutable data class containing execution results from a Claude CLI command.

    This dataclass captures all relevant information from running a Claude CLI
    command, including output streams, timing, and success status.

    Attributes:
        success: True if exit code is 0 and command did not time out.
        stdout: Captured standard output from the command.
        stderr: Captured standard error from the command.
        timed_out: True if command exceeded the configured timeout.
        duration: Execution time in seconds (must be >= 0).
        exit_code: Process exit code (0 indicates success).

    Raises:
        ValueError: If validation rules are violated:
            - success=True but exit_code != 0
            - success=True but timed_out=True
            - duration < 0

    Example:
        >>> result = ClaudeResult(
        ...     success=True,
        ...     stdout="Hello, world!",
        ...     stderr="",
        ...     timed_out=False,
        ...     duration=1.5,
        ...     exit_code=0
        ... )
        >>> result.success
        True
    """

    success: bool
    stdout: str
    stderr: str
    timed_out: bool
    duration: float
    exit_code: int

    def __post_init__(self) -> None:
        """Validate the ClaudeResult fields after initialization.

        Raises:
            ValueError: If any validation rule is violated.
        """
        if self.success and self.exit_code != 0:
            raise ValueError(
                f"success=True requires exit_code=0, got exit_code={self.exit_code}"
            )

        if self.success and self.timed_out:
            raise ValueError(
                "success=True is incompatible with timed_out=True"
            )

        if self.duration < 0:
            raise ValueError(
                f"duration must be >= 0, got {self.duration}"
            )


class ClaudeRunner:
    """Wrapper for executing Claude CLI commands with timeout handling.

    This class provides a convenient interface for running Claude CLI commands
    in E2E tests, with support for stage-specific timeouts, logging, and
    optional debug output streaming.

    Attributes:
        work_dir: Working directory for command execution.
        log_dir: Directory for log file output.
        debug: Enable streaming output to terminal.
        timeout_override: Override default timeouts (optional).

    Constants:
        DEFAULT_TIMEOUT_INIT: Timeout for initialization stage (120s).
        DEFAULT_TIMEOUT_CONSTITUTION: Timeout for constitution stage (600s).
        DEFAULT_TIMEOUT_SPECIFY: Timeout for specification stage (600s).
        DEFAULT_TIMEOUT_PLAN: Timeout for planning stage (600s).
        DEFAULT_TIMEOUT_TASKS: Timeout for tasks stage (600s).
        DEFAULT_TIMEOUT_IMPLEMENT: Timeout for implementation stage (1800s).
        MODEL: Claude model to use for execution.
        ALLOWED_TOOLS: List of tools allowed for Claude CLI execution.

    Example:
        >>> runner = ClaudeRunner(work_dir=Path("/tmp"), log_dir=Path("/logs"))
        >>> result = runner.run("Create a hello world", stage=1, log_name="test")
        >>> result.success
        True
    """

    # Default timeouts in seconds for each stage
    DEFAULT_TIMEOUT_INIT = 120
    DEFAULT_TIMEOUT_CONSTITUTION = 600
    DEFAULT_TIMEOUT_SPECIFY = 600
    DEFAULT_TIMEOUT_PLAN = 600
    DEFAULT_TIMEOUT_TASKS = 600
    DEFAULT_TIMEOUT_IMPLEMENT = 1800

    # Claude model configuration
    MODEL = "claude-sonnet-4-5@20250929"

    # Allowed tools for CLI execution
    ALLOWED_TOOLS = [
        "Bash",
        "Read",
        "Write",
        "Edit",
        "Glob",
        "Grep",
        "LS",
        "Task",
        "WebFetch",
        "WebSearch",
        "NotebookEdit",
        "Skill",
    ]

    def __init__(
        self,
        work_dir: Path,
        log_dir: Path,
        debug: bool = False,
        timeout_override: int | None = None,
        plugin_dir: Path | None = None,
    ) -> None:
        """Initialize the ClaudeRunner.

        Args:
            work_dir: Working directory for command execution.
            log_dir: Directory for log file output.
            debug: Enable streaming output to terminal. Defaults to False.
            timeout_override: Override default timeouts. Defaults to None.
            plugin_dir: Path to plugin directory to load. Defaults to None.
        """
        self.work_dir = work_dir
        self.log_dir = log_dir
        self.debug = debug
        self.timeout_override = timeout_override
        self.plugin_dir = plugin_dir

    def get_stage_timeout(self, stage: int) -> int:
        """Get the timeout for a specific stage.

        Args:
            stage: Stage number (1-6) corresponding to the workflow stage.
                1: Init
                2: Constitution
                3: Specify
                4: Plan
                5: Tasks
                6: Implement

        Returns:
            Timeout in seconds for the specified stage.

        Raises:
            ValueError: If stage is not in the valid range (1-6).
        """
        if self.timeout_override is not None:
            return self.timeout_override

        stage_timeouts = {
            1: self.DEFAULT_TIMEOUT_INIT,
            2: self.DEFAULT_TIMEOUT_CONSTITUTION,
            3: self.DEFAULT_TIMEOUT_SPECIFY,
            4: self.DEFAULT_TIMEOUT_PLAN,
            5: self.DEFAULT_TIMEOUT_TASKS,
            6: self.DEFAULT_TIMEOUT_IMPLEMENT,
        }

        if stage not in stage_timeouts:
            raise ValueError(f"Invalid stage {stage}. Must be between 1 and 6.")

        return stage_timeouts[stage]

    def run(self, prompt: str, stage: int, log_name: str) -> ClaudeResult:
        """Execute a Claude CLI command with the given prompt.

        Runs the Claude CLI with the specified prompt, capturing output and
        handling timeouts appropriately. Output is logged to the configured
        log directory and optionally streamed to the terminal.

        Args:
            prompt: The prompt to send to Claude CLI.
            stage: Stage number (1-6) for timeout determination.
            log_name: Base name for the log file (without extension).

        Returns:
            ClaudeResult containing execution results including success status,
            output streams, timing, and exit code.

        Example:
            >>> runner = ClaudeRunner(Path("/tmp"), Path("/logs"))
            >>> result = runner.run("Hello", stage=1, log_name="hello_test")
            >>> print(result.stdout)
        """
        # Build the allowed tools argument
        tools_arg = ",".join(self.ALLOWED_TOOLS)

        # Build the command
        cmd = [
            "claude",
            "-p",
            prompt,
            "--model",
            self.MODEL,
            "--allowedTools",
            tools_arg,
        ]

        # Add plugin directory if configured
        if self.plugin_dir is not None:
            cmd.extend(["--plugin-dir", str(self.plugin_dir)])

        # Get timeout for this stage
        timeout = self.get_stage_timeout(stage)

        # Prepare log file path
        log_file = self.log_dir / f"{log_name}.log"

        # Track execution time
        start_time = time.time()
        timed_out = False
        stdout = ""
        stderr = ""
        exit_code = -1

        try:
            if self.debug:
                # Stream output to terminal while also capturing
                process = subprocess.Popen(
                    cmd,
                    cwd=self.work_dir,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )

                stdout_lines = []
                stderr_lines = []

                # Read stdout in real-time
                while True:
                    # Check if process has finished
                    return_code = process.poll()

                    # Read available output
                    if process.stdout:
                        line = process.stdout.readline()
                        if line:
                            stdout_lines.append(line)
                            sys.stdout.write(line)
                            sys.stdout.flush()

                    if return_code is not None:
                        # Process finished, read remaining output
                        if process.stdout:
                            remaining = process.stdout.read()
                            if remaining:
                                stdout_lines.append(remaining)
                                sys.stdout.write(remaining)
                                sys.stdout.flush()
                        if process.stderr:
                            stderr_content = process.stderr.read()
                            if stderr_content:
                                stderr_lines.append(stderr_content)
                                sys.stderr.write(stderr_content)
                                sys.stderr.flush()
                        break

                    # Check timeout
                    elapsed = time.time() - start_time
                    if elapsed > timeout:
                        process.kill()
                        process.wait()
                        timed_out = True
                        break

                stdout = "".join(stdout_lines)
                stderr = "".join(stderr_lines)
                exit_code = process.returncode if process.returncode is not None else -1

            else:
                # Non-streaming execution
                result = subprocess.run(
                    cmd,
                    cwd=self.work_dir,
                    capture_output=True,
                    text=True,
                    timeout=timeout,
                )
                stdout = result.stdout
                stderr = result.stderr
                exit_code = result.returncode

        except subprocess.TimeoutExpired as e:
            timed_out = True
            # e.stdout/stderr can be str or bytes depending on text= flag
            if e.stdout is not None:
                stdout = e.stdout if isinstance(e.stdout, str) else e.stdout.decode("utf-8", errors="replace")
            if e.stderr is not None:
                stderr = e.stderr if isinstance(e.stderr, str) else e.stderr.decode("utf-8", errors="replace")
            # Add timeout error message
            stderr = (
                f"Command timed out after {timeout} seconds (stage {stage}). "
                f"Consider increasing the timeout with --timeout-all option.\n\n"
                f"Original stderr:\n{stderr}"
            )
            exit_code = -1

        except FileNotFoundError:
            stderr = (
                "Claude CLI not found. Please ensure the 'claude' command is installed "
                "and available in your PATH. Install it with: npm install -g @anthropic-ai/claude-cli"
            )
            exit_code = -1

        except subprocess.SubprocessError as e:
            stderr = f"{type(e).__name__}: {e}"
            exit_code = -1

        finally:
            duration = time.time() - start_time

            # Write log file
            try:
                self.log_dir.mkdir(parents=True, exist_ok=True)
                with open(log_file, "w") as f:
                    f.write(f"=== Claude CLI Execution Log ===\n")
                    f.write(f"Stage: {stage}\n")
                    f.write(f"Timeout: {timeout}s\n")
                    f.write(f"Duration: {duration:.2f}s\n")
                    f.write(f"Timed Out: {timed_out}\n")
                    f.write(f"Exit Code: {exit_code}\n")
                    f.write(f"\n=== PROMPT ===\n{prompt}\n")
                    f.write(f"\n=== STDOUT ===\n{stdout}\n")
                    f.write(f"\n=== STDERR ===\n{stderr}\n")
            except OSError as log_error:
                # Warn about log write failure so users know logs are missing
                sys.stderr.write(
                    f"WARNING: Failed to write log file '{log_file}': {log_error}\n"
                    f"Claude output will not be persisted for debugging.\n"
                )

        # Determine success
        success = exit_code == 0 and not timed_out

        # Check for authentication errors
        auth_error_patterns = [
            "not authenticated",
            "authentication required",
            "please log in",
            "API key",
            "unauthorized",
        ]
        combined_output = (stdout + stderr).lower()
        for pattern in auth_error_patterns:
            if pattern.lower() in combined_output:
                stderr = (
                    f"Claude CLI authentication error detected. {stderr}\n\n"
                    "Please authenticate with: claude login"
                )
                success = False
                break

        return ClaudeResult(
            success=success,
            stdout=stdout,
            stderr=stderr,
            timed_out=timed_out,
            duration=duration,
            exit_code=exit_code,
        )

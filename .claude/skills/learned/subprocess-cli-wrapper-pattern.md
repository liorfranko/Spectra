# Subprocess CLI Wrapper Pattern

Pattern for wrapping CLI tools in Python with proper timeout handling, streaming output, and error detection.

## When to Use

When you need to:
- Execute CLI commands from Python tests
- Handle timeouts gracefully
- Stream output for debugging
- Detect authentication/configuration errors
- Capture detailed execution logs

## Core Implementation

### Result Dataclass

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class CLIResult:
    """Immutable result from CLI command execution."""
    success: bool
    stdout: str
    stderr: str
    timed_out: bool
    duration: float
    exit_code: int

    def __post_init__(self) -> None:
        """Validate result consistency."""
        if self.success and self.exit_code != 0:
            raise ValueError(f"success=True requires exit_code=0, got {self.exit_code}")
        if self.success and self.timed_out:
            raise ValueError("success=True incompatible with timed_out=True")
        if self.duration < 0:
            raise ValueError(f"duration must be >= 0, got {self.duration}")
```

### Runner Class with Streaming Support

```python
import subprocess
import sys
import time
from pathlib import Path

class CLIRunner:
    def __init__(
        self,
        work_dir: Path,
        log_dir: Path,
        debug: bool = False,
        timeout_override: int | None = None,
    ):
        self.work_dir = work_dir
        self.log_dir = log_dir
        self.debug = debug
        self.timeout_override = timeout_override

    def run(self, cmd: list[str], timeout: int, log_name: str) -> CLIResult:
        start_time = time.time()
        timed_out = False
        stdout = ""
        stderr = ""
        exit_code = -1

        try:
            if self.debug:
                # Streaming mode for debugging
                stdout, stderr, exit_code = self._run_streaming(cmd, timeout, start_time)
            else:
                # Non-streaming mode
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
            if e.stdout:
                stdout = e.stdout if isinstance(e.stdout, str) else e.stdout.decode("utf-8", errors="replace")
            if e.stderr:
                stderr = e.stderr if isinstance(e.stderr, str) else e.stderr.decode("utf-8", errors="replace")
            stderr = f"Timeout after {timeout}s. Use --timeout-all to increase.\n\n{stderr}"

        except FileNotFoundError:
            stderr = f"Command not found: {cmd[0]}. Ensure it is installed and in PATH."

        except subprocess.SubprocessError as e:
            stderr = str(e)

        finally:
            duration = time.time() - start_time
            self._write_log(log_name, cmd, stdout, stderr, timeout, duration, timed_out, exit_code)

        return CLIResult(
            success=exit_code == 0 and not timed_out,
            stdout=stdout,
            stderr=stderr,
            timed_out=timed_out,
            duration=duration,
            exit_code=exit_code,
        )

    def _run_streaming(self, cmd: list[str], timeout: int, start_time: float) -> tuple[str, str, int]:
        """Run command with real-time output streaming."""
        process = subprocess.Popen(
            cmd,
            cwd=self.work_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        stdout_lines = []
        while True:
            return_code = process.poll()

            if process.stdout:
                line = process.stdout.readline()
                if line:
                    stdout_lines.append(line)
                    sys.stdout.write(line)
                    sys.stdout.flush()

            if return_code is not None:
                # Process finished
                if process.stdout:
                    remaining = process.stdout.read()
                    if remaining:
                        stdout_lines.append(remaining)
                        sys.stdout.write(remaining)
                stderr = process.stderr.read() if process.stderr else ""
                break

            if time.time() - start_time > timeout:
                process.kill()
                process.wait()
                raise subprocess.TimeoutExpired(cmd, timeout)

        return "".join(stdout_lines), stderr, return_code

    def _write_log(self, log_name: str, cmd: list[str], stdout: str, stderr: str,
                   timeout: int, duration: float, timed_out: bool, exit_code: int) -> None:
        """Write execution details to log file."""
        try:
            self.log_dir.mkdir(parents=True, exist_ok=True)
            log_file = self.log_dir / f"{log_name}.log"
            with open(log_file, "w") as f:
                f.write(f"Command: {' '.join(cmd)}\n")
                f.write(f"Timeout: {timeout}s | Duration: {duration:.2f}s\n")
                f.write(f"Timed Out: {timed_out} | Exit Code: {exit_code}\n")
                f.write(f"\n=== STDOUT ===\n{stdout}\n")
                f.write(f"\n=== STDERR ===\n{stderr}\n")
        except OSError:
            pass  # Silently ignore log failures
```

## Authentication Error Detection

```python
def _check_auth_errors(self, stdout: str, stderr: str) -> str | None:
    """Detect authentication errors in output."""
    auth_patterns = [
        "not authenticated",
        "authentication required",
        "please log in",
        "API key",
        "unauthorized",
    ]
    combined = (stdout + stderr).lower()
    for pattern in auth_patterns:
        if pattern in combined:
            return f"Authentication error detected. Please authenticate first."
    return None
```

## Stage-Specific Timeouts

```python
class CLIRunner:
    DEFAULT_TIMEOUTS = {
        1: 120,   # Simple operations
        2: 600,   # Medium complexity
        3: 600,
        4: 600,
        5: 600,
        6: 1800,  # Complex operations
    }

    def get_timeout(self, stage: int) -> int:
        if self.timeout_override:
            return self.timeout_override
        return self.DEFAULT_TIMEOUTS.get(stage, 600)
```

## Key Benefits

1. **Immutable results**: Frozen dataclass prevents accidental modification
2. **Validation**: Post-init validates result consistency
3. **Streaming support**: Debug mode shows real-time output
4. **Detailed logging**: Every execution logged with full context
5. **Error detection**: Catches auth errors, timeouts, missing commands
6. **Graceful timeouts**: Captures partial output on timeout

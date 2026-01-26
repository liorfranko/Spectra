"""State management for ProjSpec specifications.

This module provides functions for loading and managing spec state from
the .projspec directory structure.
"""

import os
import tempfile
from pathlib import Path

import yaml
from pydantic import ValidationError

from projspec.models import SpecState


class StateLoadError(Exception):
    """Error raised when loading spec state fails.

    Provides detailed error information including file path and cause.
    """

    def __init__(self, file_path: Path, message: str, cause: Exception | None = None):
        """Initialize StateLoadError with context.

        Args:
            file_path: Path to the file that caused the error.
            message: Human-readable error description.
            cause: Original exception that caused this error.
        """
        self.file_path = file_path
        self.message = message
        self.cause = cause
        super().__init__(f"{file_path}: {message}")


def _format_yaml_error(error: yaml.YAMLError, file_path: Path) -> str:
    """Format a YAML error with line/column information if available.

    Args:
        error: The YAML parsing error.
        file_path: Path to the file that failed to parse.

    Returns:
        Formatted error message with location details.
    """
    if hasattr(error, "problem_mark") and error.problem_mark is not None:
        mark = error.problem_mark
        line = mark.line + 1  # YAML uses 0-indexed lines
        column = mark.column + 1
        problem = getattr(error, "problem", "unknown error")
        return f"YAML parsing error at line {line}, column {column}: {problem}"
    return f"YAML parsing error: {error}"


def _format_validation_error(error: ValidationError, file_path: Path) -> str:
    """Format a Pydantic validation error with field details.

    Args:
        error: The Pydantic validation error.
        file_path: Path to the file with invalid data.

    Returns:
        Formatted error message with validation details.
    """
    errors = error.errors()
    if not errors:
        return "Validation error: unknown"

    # Format each validation error
    error_messages = []
    for err in errors[:3]:  # Limit to first 3 errors
        loc = ".".join(str(x) for x in err.get("loc", []))
        msg = err.get("msg", "invalid value")
        if loc:
            error_messages.append(f"  - {loc}: {msg}")
        else:
            error_messages.append(f"  - {msg}")

    result = "Validation error(s):\n" + "\n".join(error_messages)
    if len(errors) > 3:
        result += f"\n  ... and {len(errors) - 3} more error(s)"
    return result


def load_spec_state(state_file: Path) -> SpecState:
    """Load a single spec state from a YAML file.

    Args:
        state_file: Path to the state.yaml file.

    Returns:
        The loaded SpecState object.

    Raises:
        StateLoadError: If the file cannot be read, parsed, or validated.
    """
    # Check if file exists
    if not state_file.exists():
        raise StateLoadError(
            state_file,
            "File not found. Ensure the spec directory is properly initialized.",
            cause=FileNotFoundError(str(state_file)),
        )

    # Read and parse YAML
    try:
        with open(state_file, encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        error_msg = _format_yaml_error(e, state_file)
        raise StateLoadError(state_file, error_msg, cause=e) from e
    except OSError as e:
        raise StateLoadError(
            state_file,
            f"Failed to read file: {e.strerror}",
            cause=e,
        ) from e

    # Handle empty files
    if data is None:
        raise StateLoadError(
            state_file,
            "File is empty or contains only comments. Expected valid YAML content.",
        )

    # Handle non-dict YAML content
    if not isinstance(data, dict):
        raise StateLoadError(
            state_file,
            f"Expected YAML mapping (dict), got {type(data).__name__}. "
            "Check that the file contains key-value pairs.",
        )

    # Validate with Pydantic
    try:
        return SpecState(**data)
    except ValidationError as e:
        error_msg = _format_validation_error(e, state_file)
        raise StateLoadError(state_file, error_msg, cause=e) from e
    except TypeError as e:
        raise StateLoadError(
            state_file,
            f"Invalid data structure: {e}",
            cause=e,
        ) from e


def load_active_specs(
    base_path: Path | None = None,
    *,
    strict: bool = False,
) -> list[SpecState]:
    """Load all active specs from the .projspec/specs/active/ directory.

    Args:
        base_path: Optional base path to search from. Defaults to current directory.
        strict: If True, raise StateLoadError on first error. If False (default),
                skip specs with errors and continue loading others.

    Returns:
        List of SpecState objects for all active specs.
        Returns empty list if no active specs found or directory doesn't exist.

    Raises:
        StateLoadError: If strict=True and any spec fails to load.
    """
    if base_path is None:
        base_path = Path.cwd()

    active_dir = base_path / ".projspec" / "specs" / "active"

    if not active_dir.exists() or not active_dir.is_dir():
        return []

    specs: list[SpecState] = []
    errors: list[StateLoadError] = []

    for spec_dir in active_dir.iterdir():
        if not spec_dir.is_dir():
            continue

        state_file = spec_dir / "state.yaml"
        if not state_file.exists():
            continue

        try:
            spec = load_spec_state(state_file)
            specs.append(spec)
        except StateLoadError as e:
            if strict:
                raise
            # In non-strict mode, collect errors but continue
            errors.append(e)
            continue

    return specs


def get_current_spec(base_path: Path | None = None) -> SpecState | None:
    """Find the most recently modified active spec.

    Searches through all active specs and returns the one whose state.yaml
    file has the most recent modification time.

    Args:
        base_path: Optional base path to search from. Defaults to current directory.

    Returns:
        The SpecState of the most recently modified spec, or None if no specs exist.
    """
    specs = load_active_specs(base_path)

    if not specs:
        return None

    if base_path is None:
        base_path = Path.cwd()

    active_dir = base_path / ".projspec" / "specs" / "active"

    most_recent_spec: SpecState | None = None
    most_recent_mtime: float = 0.0

    for spec in specs:
        state_file = active_dir / spec.spec_id / "state.yaml"
        if state_file.exists():
            mtime = state_file.stat().st_mtime
            if mtime > most_recent_mtime:
                most_recent_mtime = mtime
                most_recent_spec = spec

    return most_recent_spec


def save_spec_state(
    spec_id: str,
    state: SpecState,
    base_path: Path | None = None,
) -> None:
    """Save a spec's state to state.yaml using atomic file writes.

    This function writes the state to a temporary file first, then atomically
    replaces the target file using os.replace(). This prevents state corruption
    if the process is interrupted during the write operation.

    Args:
        spec_id: The spec identifier (8-character hex ID).
        state: The SpecState object to save.
        base_path: Optional base path. Defaults to current directory.

    Raises:
        FileNotFoundError: If the spec directory doesn't exist.
        OSError: If the atomic write operation fails.
    """
    if base_path is None:
        base_path = Path.cwd()

    spec_dir = base_path / ".projspec" / "specs" / "active" / spec_id
    state_file = spec_dir / "state.yaml"

    if not spec_dir.exists():
        raise FileNotFoundError(f"Spec directory not found: {spec_dir}")

    # Serialize the state to YAML
    # Use model_dump() for Pydantic v2 compatibility, with mode="json" for
    # proper datetime serialization
    state_dict = state.model_dump(mode="json")
    yaml_content = yaml.safe_dump(state_dict, default_flow_style=False, sort_keys=False)

    # Atomic write: write to temp file in same directory, then replace
    # Using the same directory ensures os.replace() works across filesystems
    temp_fd = None
    temp_path = None
    try:
        # Create a temporary file in the same directory as the target
        temp_fd, temp_path = tempfile.mkstemp(
            suffix=".yaml.tmp",
            prefix="state_",
            dir=spec_dir,
        )

        # Write the content to the temporary file
        with os.fdopen(temp_fd, "w", encoding="utf-8") as temp_file:
            temp_fd = None  # fdopen takes ownership of the fd
            temp_file.write(yaml_content)
            temp_file.flush()
            os.fsync(temp_file.fileno())  # Ensure data is written to disk

        # Atomically replace the target file
        os.replace(temp_path, state_file)
        temp_path = None  # Successfully moved, don't try to clean up

    finally:
        # Clean up the temp file if it still exists (error case)
        if temp_fd is not None:
            try:
                os.close(temp_fd)
            except OSError:
                pass
        if temp_path is not None:
            try:
                os.unlink(temp_path)
            except OSError:
                pass

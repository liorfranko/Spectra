# Pydantic + YAML Error Handling

## Pattern

When loading YAML files into Pydantic models, wrap all errors in a custom exception that provides actionable context.

## Implementation

```python
from pathlib import Path

import yaml
from pydantic import BaseModel, ValidationError


class StateLoadError(Exception):
    """Error with context for state loading failures."""

    def __init__(self, file_path: Path, message: str, cause: Exception | None = None):
        self.file_path = file_path
        self.message = message
        self.cause = cause
        super().__init__(f"{file_path}: {message}")


def _format_yaml_error(error: yaml.YAMLError) -> str:
    """Format YAML error with line/column if available."""
    if hasattr(error, "problem_mark") and error.problem_mark is not None:
        mark = error.problem_mark
        line = mark.line + 1  # YAML uses 0-indexed
        column = mark.column + 1
        problem = getattr(error, "problem", "unknown error")
        return f"YAML parsing error at line {line}, column {column}: {problem}"
    return f"YAML parsing error: {error}"


def _format_validation_error(error: ValidationError) -> str:
    """Format Pydantic error with field details."""
    errors = error.errors()
    if not errors:
        return "Validation error: unknown"

    messages = []
    for err in errors[:3]:  # Limit to first 3
        loc = ".".join(str(x) for x in err.get("loc", []))
        msg = err.get("msg", "invalid value")
        messages.append(f"  - {loc}: {msg}" if loc else f"  - {msg}")

    result = "Validation error(s):\n" + "\n".join(messages)
    if len(errors) > 3:
        result += f"\n  ... and {len(errors) - 3} more"
    return result


def load_model_from_yaml(file_path: Path, model_class: type[BaseModel]):
    """Load a Pydantic model from YAML with comprehensive error handling."""
    if not file_path.exists():
        raise StateLoadError(
            file_path,
            "File not found. Ensure the directory is properly initialized.",
            cause=FileNotFoundError(str(file_path)),
        )

    try:
        with open(file_path, encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        raise StateLoadError(file_path, _format_yaml_error(e), cause=e) from e
    except OSError as e:
        raise StateLoadError(file_path, f"Failed to read: {e.strerror}", cause=e) from e

    if data is None:
        raise StateLoadError(file_path, "File is empty or contains only comments.")

    if not isinstance(data, dict):
        raise StateLoadError(
            file_path,
            f"Expected YAML mapping, got {type(data).__name__}."
        )

    try:
        return model_class(**data)
    except ValidationError as e:
        raise StateLoadError(file_path, _format_validation_error(e), cause=e) from e
```

## Error Message Examples

**YAML syntax error:**
```
/path/to/file.yaml: YAML parsing error at line 6, column 11: expected a value
```

**Pydantic validation error:**
```
/path/to/file.yaml: Validation error(s):
  - name: Input should be a valid string
  - status: Input should be 'pending', 'in_progress', or 'completed'
```

## Key Points

- Always include file path in error messages
- Extract line/column from `yaml.YAMLError.problem_mark`
- Format Pydantic errors with field paths
- Chain exceptions with `from e` for traceability
- Handle empty files and non-dict YAML separately

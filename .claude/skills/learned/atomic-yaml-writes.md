# Atomic YAML File Writes in Python

## Pattern

When writing state files that must not be corrupted, use atomic writes:

1. Write to a temporary file in the same directory
2. Flush and fsync to ensure data is on disk
3. Use `os.replace()` to atomically swap the files

## Implementation

```python
import os
import tempfile
from pathlib import Path

import yaml

def save_state_atomically(file_path: Path, data: dict) -> None:
    """Save data to YAML file atomically."""
    yaml_content = yaml.safe_dump(data, default_flow_style=False)

    temp_fd = None
    temp_path = None
    try:
        # Create temp file in same directory (required for atomic replace)
        temp_fd, temp_path = tempfile.mkstemp(
            suffix=".yaml.tmp",
            prefix="state_",
            dir=file_path.parent,
        )

        # Write and sync
        with os.fdopen(temp_fd, "w", encoding="utf-8") as f:
            temp_fd = None  # fdopen takes ownership
            f.write(yaml_content)
            f.flush()
            os.fsync(f.fileno())

        # Atomic replace
        os.replace(temp_path, file_path)
        temp_path = None

    finally:
        # Cleanup on error
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
```

## Key Points

- Temp file must be in same directory for `os.replace()` to be atomic
- `os.fsync()` ensures data is written to disk before replace
- Finally block cleans up temp file on any error
- `fdopen` takes ownership of file descriptor, so set to None after

## When to Use

- State files that track progress (state.yaml, config files)
- Any file where partial writes would cause corruption
- Files that are read frequently and must always be valid

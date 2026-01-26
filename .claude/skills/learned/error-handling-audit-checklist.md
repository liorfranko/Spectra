# Error Handling Audit Checklist

## When to Use
When reviewing code for silent failures and inadequate error handling, especially in test infrastructure and helper utilities.

## Common Silent Failure Patterns

### 1. Return Default on Error
```python
# BAD: Masks the actual error
def get_count(self) -> int:
    result = run_command(["git", "rev-list", "--count", "HEAD"])
    if result.returncode != 0:
        return 0  # Silent failure!
    return int(result.stdout)

# GOOD: Raise or distinguish error from valid zero
def get_count(self) -> int:
    result = run_command(["git", "rev-list", "--count", "HEAD"])
    if result.returncode != 0:
        raise RuntimeError(f"git failed: {result.stderr}")
    return int(result.stdout)
```

### 2. Return None Without Context
```python
# BAD: Caller can't distinguish "not found" from "command failed"
def find_item(self, pattern: str) -> Path | None:
    result = run_command(...)
    if result.returncode != 0:
        return None  # Was it not found or did the command fail?

# GOOD: Raise on unexpected failure
def find_item(self, pattern: str) -> Path | None:
    result = run_command(...)
    if result.returncode != 0:
        raise RuntimeError(f"Search command failed: {result.stderr}")
    # Now None means "not found" specifically
```

### 3. Empty Except Blocks
```python
# BAD: Swallowed error
try:
    write_file(path, content)
except OSError:
    pass  # Log file not written, no one knows

# GOOD: At least warn
try:
    write_file(path, content)
except OSError as e:
    sys.stderr.write(f"WARNING: Failed to write {path}: {e}\n")
```

### 4. Missing Return Code Checks
```python
# BAD: Ignoring failure
subprocess.run(["git", "config", "user.email", "test@example.com"])
subprocess.run(["git", "commit", "-m", "Initial"])  # Fails cryptically

# GOOD: Check and fail early
result = subprocess.run(["git", "config", "user.email", "test@example.com"],
                        capture_output=True)
if result.returncode != 0:
    raise RuntimeError(f"git config failed: {result.stderr}")
```

### 5. Broad Exception Types
```python
# BAD: Loses exception type information
except subprocess.SubprocessError as e:
    stderr = str(e)  # What kind of error was it?

# GOOD: Preserve type info
except subprocess.SubprocessError as e:
    stderr = f"{type(e).__name__}: {e}"
```

## Audit Questions

1. **Does every subprocess call check its return code?**
2. **Does every except block either re-raise, log, or have documented justification?**
3. **Can callers distinguish between "not found" and "error"?**
4. **Are error messages actionable (include file paths, expected vs actual)?**
5. **Do catch blocks preserve exception type information?**
6. **Are cleanup operations (finally blocks) protected from failures?**

## Impact Assessment

For each silent failure found, document:
- **What errors could be caught?** (disk full, permission denied, etc.)
- **What user impact?** (confusing messages, lost data, etc.)
- **Recommended fix** (raise, log warning, return result object)

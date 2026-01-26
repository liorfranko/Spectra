# Running uv Projects from Outside Their Directory

## Pattern

When you need to run a CLI tool from a uv-managed project without being in that project's directory, use the `--project` flag:

```bash
uv run --project /path/to/project <command> [args...]
```

## Example

```bash
# Run projspec from anywhere
uv run --project /Users/liorfr/Development/projspec/worktrees/001-projspec-mvp projspec status
```

## Notes

- A warning about `VIRTUAL_ENV` mismatch may appear but can be safely ignored
- The command runs in the current working directory, not the project directory
- This is useful for CLIs in worktrees or subdirectories

## Alternatives

1. **Shell alias**: Add to `~/.zshrc` or `~/.bashrc`:
   ```bash
   alias projspec='uv run --project /path/to/project projspec'
   ```

2. **pipx install**: For global availability:
   ```bash
   pipx install /path/to/project
   ```

3. **Install in parent venv**:
   ```bash
   uv pip install -e /path/to/project
   ```

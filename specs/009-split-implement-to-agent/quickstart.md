# Quickstart: Split Implement Command Modes

Get started with the dual-mode implement command in under 5 minutes.

## Prerequisites

Before you begin, ensure you have:

- [ ] Claude Code CLI installed and authenticated
- [ ] A projspec project with `tasks.md` generated
- [ ] Git repository initialized with remote configured
- [ ] Clean git working directory (all changes committed)

## Understanding the Modes

The `/projspec.implement` command now supports two execution modes:

| Mode | Flag | Use When |
|------|------|----------|
| **Agent** (default) | `--agent` or none | You need isolated context per task, parallel execution, or easy rollback |
| **Direct** | `--direct` | You want faster execution for simple sequential tasks |

## Quick Start

### Using Agent Mode (Default)

Agent mode spawns a fresh context for each task, enabling parallel execution and isolated state.

```bash
# Run with explicit agent flag
/projspec.implement --agent

# Or simply (agent is the default)
/projspec.implement
```

**What happens**:
1. Each task spawns a dedicated agent with fresh context
2. Tasks marked with `[P]` run in parallel
3. Each task produces one commit: `[T001] Description`
4. Progress displayed after each agent completes

### Using Direct Mode

Direct mode executes tasks sequentially in your current conversation context—faster but no parallelization.

```bash
/projspec.implement --direct
```

**What happens**:
1. Tasks execute one-by-one in your current context
2. Parallel `[P]` markers are ignored (sequential execution with info message)
3. Each task still produces one commit: `[T001] Description`
4. Faster overall execution for sequential workloads

## Basic Examples

### Example 1: First-Time Implementation

You have a new feature with `tasks.md` ready. Use agent mode for isolation:

```bash
# Generate tasks first (if not done)
/projspec.tasks

# Run implementation
/projspec.implement
```

Expected output:
```
Executing tasks in agent mode (default)
✓ [T001] Create project structure - Committed and pushed
✓ [T002] Add configuration files - Committed and pushed
✓ [T003] Implement core feature - Committed and pushed
...
Implementation complete: 5 tasks = 5 commits ✓
```

### Example 2: Quick Sequential Tasks

You have simple, non-parallel tasks and want faster execution:

```bash
/projspec.implement --direct
```

Expected output:
```
Executing tasks in direct mode (sequential, no agents)
✓ [T001] Update documentation - Committed and pushed
✓ [T002] Add helper function - Committed and pushed
✓ [T003] Fix typo in config - Committed and pushed
...
Implementation complete: 3 tasks = 3 commits ✓
```

### Example 3: Mixed Tasks with Parallel Markers

Your `tasks.md` has some `[P]` parallel tasks but you want direct mode anyway:

```bash
/projspec.implement --direct
```

Expected output:
```
Executing tasks in direct mode (sequential, no agents)
✓ [T001] Setup phase - Committed and pushed
✓ [T002] [P] First parallel task - Committed and pushed
✓ [T003] [P] Second parallel task - Committed and pushed
Note: 2 parallel tasks ran sequentially in direct mode
✓ [T004] Final task - Committed and pushed
...
```

## Error Handling

Both modes offer the same recovery options when a task fails:

```
✗ [T003] Implement validation - FAILED

Error: Could not find required file src/validators/index.ts

Options:
  [R] Retry - Re-attempt this task
  [S] Skip - Mark as skipped, continue to next task
  [A] Abort - Stop implementation

Choose (R/S/A):
```

## Mode Comparison

| Aspect | Agent Mode | Direct Mode |
|--------|------------|-------------|
| Execution | Parallel possible | Sequential only |
| Context | Fresh per task | Accumulated |
| Speed | Slower (agent overhead) | Faster |
| Memory | Lower per-task | Higher overall |
| Rollback | Easier (isolated) | Same (per-commit) |
| Use case | Complex tasks, parallelism | Simple, sequential tasks |

## Common Issues

**Issue: "Cannot use both --agent and --direct flags"**
```
Error: Cannot use both --agent and --direct flags
```
**Solution**: Use only one flag. Remove either `--agent` or `--direct`.

**Issue: Parallel tasks not running in parallel**
```
Note: 3 parallel tasks ran sequentially in direct mode
```
**Solution**: This is expected in direct mode. Use `--agent` for parallel execution.

**Issue: Git working directory not clean**
```
Error: Git working directory has uncommitted changes
```
**Solution**: Commit or stash your changes before running implement.

## Next Steps

- **Full Specification**: See [spec.md](./spec.md) for complete requirements
- **Implementation Details**: See [plan.md](./plan.md) for technical design
- **Data Model**: See [data-model.md](./data-model.md) for entity definitions
- **Create PR**: After implementation, run `/projspec.review-pr`

## Tips

1. **Start with agent mode** for unfamiliar tasks—isolation makes debugging easier
2. **Use direct mode** for well-understood, simple task sets
3. **Check git log** after completion: `git log --oneline | head -10`
4. **Verify commit count** matches task count for audit trail

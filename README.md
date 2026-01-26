# ProjSpec

A spec-driven development workflow orchestrator for Claude Code. ProjSpec guides developers through structured phases from specification to implementation, with each spec running in an isolated git worktree.

## Features

- **Spec-Driven Workflow**: Progress through defined phases: new, spec, plan, tasks, implement, review, archive
- **Isolated Worktrees**: Each specification runs in its own git worktree for clean separation
- **State Persistence**: All workflow state is persisted in YAML files
- **Claude Code Integration**: Combines a minimal Python CLI with Claude Code commands for workflow logic
- **Progress Tracking**: Monitor active specs and their implementation progress

## Installation

ProjSpec requires Python 3.11+ and uses uv as the package manager.

```bash
# Clone the repository
git clone https://github.com/your-org/projspec.git
cd projspec

# Install with uv
uv pip install -e .
```

## Quick Start

1. Initialize ProjSpec in your project:
   ```bash
   projspec init
   ```

2. Create a new spec (in Claude Code):
   ```
   /projspec.new my-feature
   ```

3. Define your specification:
   ```
   /projspec.spec
   ```

4. Create an implementation plan:
   ```
   /projspec.plan
   ```

5. Generate tasks from the plan:
   ```
   /projspec.tasks
   ```

6. Implement tasks one at a time:
   ```
   /projspec.implement
   ```

7. Review the implementation:
   ```
   /projspec.review
   ```

8. Archive and merge when complete:
   ```
   /projspec.archive
   ```

## Commands

### CLI Commands

| Command | Description |
|---------|-------------|
| `projspec init` | Initialize ProjSpec in the current project |
| `projspec status` | Show active specs and their progress |

### Claude Code Commands

| Command | Description |
|---------|-------------|
| `/projspec.new <name>` | Create a new spec with its own worktree |
| `/projspec.spec` | Define or refine the specification |
| `/projspec.plan` | Create an implementation plan |
| `/projspec.tasks` | Generate a task list from the plan |
| `/projspec.implement` | Implement the next pending task |
| `/projspec.review` | Review the implementation |
| `/projspec.archive` | Merge changes and cleanup the worktree |

## License

MIT

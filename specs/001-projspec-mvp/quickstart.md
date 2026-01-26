# Quickstart: ProjSpec MVP

## Prerequisites

- Python 3.11+
- Git
- Claude Code CLI

## Installation

```bash
# Clone and install
git clone <repo-url>
cd projspec
uv sync  # or pip install -e .
```

## Quick Start

### 1. Initialize ProjSpec in your project

```bash
cd your-project
projspec init
```

This creates the `.projspec/` directory with default configuration.

### 2. Create a new spec

```
/projspec.new user-authentication
```

This creates:
- A new git worktree at `worktrees/spec-{id}-user-authentication`
- A state file at `.projspec/specs/active/{id}/state.yaml`
- A new branch `spec/{id}-user-authentication`

### 3. Define the specification

```
/projspec.spec
```

Claude will guide you through creating a structured specification document.

### 4. Create an implementation plan

```
/projspec.plan
```

Claude will create a plan.md with the implementation approach.

### 5. Generate tasks

```
/projspec.tasks
```

Claude breaks the plan into actionable tasks with dependencies.

### 6. Implement tasks

```
/projspec.implement
```

Claude finds the next ready task, loads context, and guides implementation.
Repeat until all tasks are complete.

### 7. Review

```
/projspec.review
```

Claude reviews the implementation against the specification.

### 8. Archive (merge and cleanup)

```
/projspec.archive
```

Merges the spec branch to main and cleans up the worktree.

## Workflow Diagram

```
projspec init
     ↓
/projspec.new <name>
     ↓
/projspec.spec
     ↓
/projspec.plan
     ↓
/projspec.tasks
     ↓
/projspec.implement (repeat)
     ↓
/projspec.review
     ↓
/projspec.archive
```

## File Structure

After initialization:

```
your-project/
├── .projspec/
│   ├── config.yaml        # Global configuration
│   ├── workflow.yaml      # Phase sequence
│   ├── phases/            # Phase prompt templates
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── tasks.md
│   │   ├── implement.md
│   │   └── review.md
│   └── specs/
│       ├── active/        # Currently active specs
│       └── completed/     # Archived specs
└── worktrees/             # Git worktrees (one per spec)
```

## Commands

| Command | Description |
|---------|-------------|
| `projspec init` | Initialize ProjSpec in project |
| `projspec status` | Show active specs and progress |
| `/projspec.new <name>` | Create new spec with worktree |
| `/projspec.spec` | Define specification |
| `/projspec.plan` | Create implementation plan |
| `/projspec.tasks` | Generate task list |
| `/projspec.implement` | Implement next task |
| `/projspec.review` | Review implementation |
| `/projspec.resume` | Continue from last state |
| `/projspec.archive` | Merge and cleanup |

## Tips

- **Resume work**: Use `/projspec.resume` to continue where you left off
- **Check status**: Run `projspec status` to see all active specs
- **Skip tasks**: During implementation, you can skip tasks with confirmation
- **Custom phases**: Add phase templates to `.projspec/phases/custom/`

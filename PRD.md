# ProjSpec - Product Requirements Document

## Vision

ProjSpec is a spec-driven development workflow orchestrator for Claude Code that transforms software development into a structured, traceable, and highly customizable process. Each specification flows through defined phases—from inception to review—while maintaining isolation, persistence, and learning capabilities.

**Implementation Language: Python 3.11+**

---

## Problem Statement

Modern AI-assisted development lacks:
1. **Structured workflows** - Ad-hoc prompting leads to inconsistent results
2. **Context isolation** - Tasks pollute each other's context, causing confusion
3. **Learning persistence** - Insights are lost between sessions
4. **Traceability** - No clear audit trail from spec to implementation
5. **Customizability** - Rigid workflows don't adapt to team needs

---

## Core Principles

1. **Specs are the source of truth** - Everything flows from specifications
2. **Isolation by default** - Each spec runs in its own git worktree
3. **Learn and adapt** - System improves through background reflection (Phase 2)
4. **Composable workflows** - Phases can be added, removed, or reordered
5. **Git-native** - Leverage worktrees for spec isolation
6. **Claude-driven** - Claude Code commands contain the logic; Python only bootstraps and reports

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        User (Interactive Claude)                 │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Claude Code Commands                         │
│  /projspec.new  /projspec.spec  /projspec.plan  /projspec.impl  │
│                                                                  │
│  Commands are prompt templates that guide Claude through         │
│  reading/writing files and executing the workflow.               │
└─────────────────────────────────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                              ▼
┌──────────────────────────────┐  ┌──────────────────────────────┐
│      Python CLI (minimal)     │  │      .projspec/ (state)       │
│                               │  │                               │
│  projspec init   - bootstrap  │  │  config.yaml                  │
│  projspec status - report     │  │  phases/*.md                  │
│                               │  │  specs/active/{id}/state.yaml │
└──────────────────────────────┘  └──────────────────────────────┘
                                                  │
                                                  ▼
                                   ┌──────────────────────────────┐
                                   │     Git Worktrees             │
                                   │                               │
                                   │  worktrees/spec-{id}-{name}/  │
                                   │  (one per spec, mandatory)    │
                                   └──────────────────────────────┘
```

---

## Technical Stack

```
projspec/
├── pyproject.toml              # Project configuration (using uv)
├── src/
│   └── projspec/
│       ├── __init__.py
│       ├── cli.py              # Minimal CLI: init, status
│       ├── models.py           # Pydantic models for config/state
│       └── state.py            # State reading utilities
└── tests/
    ├── unit/
    ├── integration/
    └── e2e/
        └── runner.py           # Test-only: runs claude -p
```

**Dependencies:**
- `pydantic` - Data validation and settings
- `pyyaml` - YAML configuration
- `rich` - Terminal output formatting
- `pytest` - Testing

---

## Workflow Overview

```
┌─────────────┐     ┌──────────┐     ┌──────────┐     ┌─────────┐
│     new     │────▶│   spec   │────▶│   plan   │────▶│  tasks  │
└─────────────┘     └──────────┘     └──────────┘     └─────────┘
                                                            │
                                                            ▼
┌─────────────┐     ┌──────────┐                      ┌──────────┐
│   archive   │◀────│  review  │◀─────────────────────│implement │
└─────────────┘     └──────────┘                      └──────────┘
```

### Phases

| Phase | Purpose | Inputs | Outputs |
|-------|---------|--------|---------|
| `new` | Create spec with worktree | User intent | Spec scaffold, worktree |
| `spec` | Define what to build | User requirements | Specification document |
| `plan` | Design how to build it | Spec document | Implementation plan |
| `tasks` | Break into actionable units | Plan | Task list with dependencies |
| `implement` | Execute tasks sequentially | Task definition | Code changes |
| `review` | Assess quality, verify implementation | All artifacts | Review report |

---

## Feature Requirements

### F1: Workflow Engine (Prompt-Driven)

The workflow engine is **prompt-driven, not code-driven**. Claude Code commands contain the logic; Python only bootstraps and reports.

**F1.1 - Phase Definitions (Prompt Templates)**

Each phase is a markdown file that guides Claude:

```
.projspec/
└── phases/
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    ├── implement.md
    └── review.md
```

Example phase template:

```markdown
<!-- .projspec/phases/spec.md -->
# Spec Phase

## Purpose
Transform user requirements into a structured specification document.

## Inputs
- User requirements (provided by user or in brief.md)

## Instructions
1. Read the user requirements in `.projspec/specs/active/{spec_id}/brief.md`
2. Discuss with user to clarify ambiguities
3. Create a specification document with:
   - Problem Statement
   - User Stories
   - Technical Requirements
   - Success Criteria
   - Out of Scope

## Output
Write the specification to: `.projspec/specs/active/{spec_id}/spec.md`

## Completion
After writing the spec, ask user if they're ready to proceed to planning.
```

**F1.2 - State Management**

State is stored in simple YAML files that Claude reads/writes directly:

```yaml
# .projspec/specs/active/abc123/state.yaml
spec_id: abc123
name: user-auth
phase: implement
created_at: 2024-01-15T10:30:00Z
branch: spec/abc123-user-auth
worktree_path: worktrees/spec-abc123-user-auth

tasks:
  - id: task-001
    name: "Create user model"
    status: completed
    depends_on: []
    summary: |
      - Created User model in src/models/user.py
      - Fields: id, email, password_hash, created_at
      - Added email uniqueness constraint
  - id: task-002
    name: "Implement registration endpoint"
    status: in_progress
    depends_on: [task-001]
  - id: task-003
    name: "Add authentication middleware"
    status: pending
    depends_on: [task-001]
```

**F1.3 - Phase Transitions**

Claude Code commands handle transitions by:
1. Reading current state from state.yaml
2. Validating phase completion (required outputs exist)
3. Updating state file
4. Loading next phase prompt template

**F1.4 - Custom Phases**

Users can create custom phases in `.projspec/phases/custom/`:
- Inherit structure from default phases
- Examples: `security-review.md`, `documentation.md`, `deploy.md`

**F1.5 - Workflow Configuration**

```yaml
# .projspec/workflow.yaml
workflow:
  name: default
  phases:
    - spec
    - plan
    - tasks
    - implement
    - review
```

---

### F2: Git Worktree Integration

Every spec gets its own worktree. This is mandatory and core to the isolation principle.

**Worktree Lifecycle:**

```
/project-root/
├── .git/
├── .projspec/
│   └── specs/
│       ├── active/
│       │   └── abc123/
│       │       ├── state.yaml
│       │       ├── brief.md
│       │       ├── spec.md
│       │       └── plan.md
│       └── completed/
│           └── def456/
│               └── ... (archived spec metadata)
├── src/
└── worktrees/
    └── spec-abc123-user-auth/   # Active worktree
        ├── .git -> ../../.git/worktrees/...
        ├── src/
        └── ...
```

**Worktree Operations (via git commands in Claude Code commands):**

```bash
# Create worktree for new spec
git worktree add -b spec/{spec_id}-{name} worktrees/spec-{spec_id}-{name}

# List worktrees
git worktree list

# Remove worktree on archive
git worktree remove worktrees/spec-{spec_id}-{name}

# Merge completed spec to main
git checkout main
git merge spec/{spec_id}-{name}
```

**Archive behavior:**
- Spec metadata moves from `active/` to `completed/`
- Worktree is deleted (saves disk space)
- Git branch remains in history (can restore if needed)

---

### F3: Context & Session Summaries

Context isolation happens naturally—each `/projspec.implement` invocation works on one task. Session summaries bridge context between tasks.

**Session Summary Flow:**

```
┌──────────┐    summary    ┌──────────┐    summary    ┌──────────┐
│ Task 001 │──────────────▶│ Task 002 │──────────────▶│ Task 003 │
└──────────┘               └──────────┘               └──────────┘
     │                          │                          │
     ▼                          ▼                          ▼
 Stored in               Stored in                  Stored in
 state.yaml              state.yaml                 state.yaml
```

**Task Context Injection:**

When starting a task, Claude loads:
1. The spec (`spec.md`)
2. The plan (`plan.md`)
3. Previous task summaries (from `state.yaml`)
4. Relevant source files for the task

**Summary Generation:**

After completing a task, Claude generates a 3-5 bullet summary:
- Decisions made
- Files changed
- Key implementation details
- Any gotchas or notes for future tasks

This summary is stored in `state.yaml` under the task entry.

---

### F4: Task Execution

Tasks execute sequentially in the interactive Claude session.

**Task Definition in state.yaml:**

```yaml
tasks:
  - id: task-001
    name: "Create user model"
    description: |
      Create the User model with fields for authentication.
      Include email validation and password hashing.
    status: pending  # pending | in_progress | completed | skipped
    depends_on: []
    context_files:
      - src/models/
      - src/db/
    summary: null  # Filled after completion
```

**Finding Next Task:**

```
For each task in tasks:
  If status == "pending":
    If all depends_on tasks have status == "completed":
      Return this task (it's ready)
Return null (no task ready, or all done)
```

**Task Status Transitions:**

```
pending ──▶ in_progress ──▶ completed
                │
                └──▶ skipped (user decision)
```

---

### F5: Checkpointing & Resume

Checkpointing is implicit in `state.yaml`. Every state change is written immediately.

**Resume Behavior:**

1. Find active spec in `.projspec/specs/active/`
2. Load `state.yaml`
3. Determine resume point:
   - If a task is `in_progress` → continue that task
   - If phase is not `implement` → continue current phase
   - Otherwise → find next ready task
4. Load context (spec, plan, previous summaries)
5. Continue work

---

### F6: Memory Persistence & Reflection (Phase 2)

> **Note:** This feature is deferred to Phase 2.

- Background reflection on completed phases
- Pattern extraction and storage
- Memory retrieval for context injection
- Skill candidate identification

---

### F7: Auto Skill Creation (Phase 2)

> **Note:** This feature is deferred to Phase 2.

- Detect recurring patterns across specs
- Generate skill files automatically
- Require user approval before activation

---

### F8: Python CLI (Minimal)

The Python CLI handles only initialization and status reporting. All development workflow is driven by Claude Code commands.

```python
# src/projspec/cli.py
"""
Minimal CLI for initialization and status.
All development workflow is handled by Claude Code commands.
"""
import argparse
import sys
from pathlib import Path
from datetime import datetime

import yaml
from rich.console import Console
from rich.table import Table

from projspec.models import SpecState
from projspec.state import load_active_specs

console = Console()

DEFAULT_CONFIG = """\
version: "1.0"

project:
  name: "{project_name}"

worktrees:
  base_path: "./worktrees"

context:
  always_include:
    - "CLAUDE.md"
"""

DEFAULT_WORKFLOW = """\
workflow:
  name: default
  phases:
    - spec
    - plan
    - tasks
    - implement
    - review
"""


def init():
    """Initialize ProjSpec in current project."""
    projspec_dir = Path(".projspec")

    if projspec_dir.exists():
        console.print("[yellow]ProjSpec already initialized.[/yellow]")
        return

    projspec_dir.mkdir()
    (projspec_dir / "phases").mkdir()
    (projspec_dir / "specs/active").mkdir(parents=True)
    (projspec_dir / "specs/completed").mkdir(parents=True)

    # Copy default phase templates
    _copy_default_phases(projspec_dir / "phases")

    # Create default config
    project_name = Path.cwd().name
    config_content = DEFAULT_CONFIG.format(project_name=project_name)
    (projspec_dir / "config.yaml").write_text(config_content)

    # Create default workflow
    (projspec_dir / "workflow.yaml").write_text(DEFAULT_WORKFLOW)

    console.print("[green]ProjSpec initialized[/green]")
    console.print("\nNext: Run [bold]/projspec.new <spec-name>[/bold] to create your first spec.")


def status():
    """Show current spec status."""
    projspec_dir = Path(".projspec")

    if not projspec_dir.exists():
        console.print("[red]ProjSpec not initialized.[/red]")
        console.print("Run [bold]projspec init[/bold] first.")
        return

    specs = load_active_specs(projspec_dir / "specs/active")

    if not specs:
        console.print("[dim]No active specs.[/dim]")
        console.print("Run [bold]/projspec.new <name>[/bold] to create one.")
        return

    for spec in specs:
        _print_spec_status(spec)


def _print_spec_status(spec: SpecState):
    """Print status for a single spec."""
    console.print(f"\n[bold]Spec: {spec.name}[/bold] ({spec.spec_id})")
    console.print(f"  Phase: [cyan]{spec.phase}[/cyan]")
    console.print(f"  Branch: {spec.branch}")
    console.print(f"  Worktree: {spec.worktree_path}")

    if spec.tasks:
        completed = sum(1 for t in spec.tasks if t.status == "completed")
        in_progress = sum(1 for t in spec.tasks if t.status == "in_progress")

        console.print(f"\n  Tasks: {completed}/{len(spec.tasks)} completed", end="")
        if in_progress:
            console.print(f", [yellow]{in_progress} in progress[/yellow]", end="")
        console.print()

        table = Table(show_header=True, header_style="bold")
        table.add_column("ID", width=10)
        table.add_column("Name", width=40)
        table.add_column("Status", width=12)

        for task in spec.tasks:
            status_style = {
                "completed": "green",
                "in_progress": "yellow",
                "pending": "dim",
                "skipped": "dim strikethrough"
            }.get(task.status, "")

            table.add_row(
                task.id,
                task.name,
                f"[{status_style}]{task.status}[/{status_style}]"
            )

        console.print(table)


def _copy_default_phases(phases_dir: Path):
    """Copy default phase templates."""
    # Phase templates are bundled with the package
    pass  # Implementation reads from package data


def main():
    parser = argparse.ArgumentParser(
        prog="projspec",
        description="Spec-driven development workflow orchestrator"
    )
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("init", help="Initialize ProjSpec in current project")
    subparsers.add_parser("status", help="Show current spec status")

    args = parser.parse_args()

    if args.command == "init":
        init()
    elif args.command == "status":
        status()
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
```

```python
# src/projspec/models.py
"""Pydantic models for configuration and state."""
from datetime import datetime
from pydantic import BaseModel


class TaskState(BaseModel):
    id: str
    name: str
    description: str = ""
    status: str = "pending"  # pending | in_progress | completed | skipped
    depends_on: list[str] = []
    context_files: list[str] = []
    summary: str | None = None


class SpecState(BaseModel):
    spec_id: str
    name: str
    phase: str = "new"
    created_at: datetime
    branch: str
    worktree_path: str
    tasks: list[TaskState] = []


class Config(BaseModel):
    version: str = "1.0"
    project: dict = {}
    worktrees: dict = {"base_path": "./worktrees"}
    context: dict = {"always_include": ["CLAUDE.md"]}
```

```python
# src/projspec/state.py
"""State reading utilities."""
from pathlib import Path
import yaml
from projspec.models import SpecState


def load_active_specs(active_dir: Path) -> list[SpecState]:
    """Load all active specs."""
    specs = []

    if not active_dir.exists():
        return specs

    for spec_dir in active_dir.iterdir():
        if spec_dir.is_dir():
            state_file = spec_dir / "state.yaml"
            if state_file.exists():
                data = yaml.safe_load(state_file.read_text())
                specs.append(SpecState(**data))

    return specs


def get_current_spec(active_dir: Path) -> SpecState | None:
    """Get the current spec (most recently modified)."""
    specs = load_active_specs(active_dir)
    if not specs:
        return None

    return max(specs, key=lambda s: s.created_at)
```

---

### F9: Claude Code Commands

Commands are the user interface. They contain prompts that guide Claude through each workflow step.

**Command List:**

| Command | Description |
|---------|-------------|
| `/projspec.init` | Initialize ProjSpec in current project |
| `/projspec.status` | Show current spec status |
| `/projspec.new <name>` | Create new spec with worktree |
| `/projspec.spec` | Run spec phase |
| `/projspec.plan` | Run plan phase |
| `/projspec.tasks` | Generate task list |
| `/projspec.implement` | Implement next task |
| `/projspec.review` | Run review phase |
| `/projspec.resume` | Resume from last state |
| `/projspec.archive` | Archive completed spec |
| `/projspec.next` | Proceed to next phase |

**Plugin Structure:**

```
.claude/plugins/projspec/
├── plugin.json
├── commands/
│   ├── init.md
│   ├── status.md
│   ├── new.md
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   ├── implement.md
│   ├── review.md
│   ├── resume.md
│   ├── archive.md
│   └── next.md
└── assets/
    └── phases/
        ├── spec.md
        ├── plan.md
        ├── tasks.md
        ├── implement.md
        └── review.md
```

**Example Commands:**

```markdown
<!-- commands/init.md -->
---
description: Initialize ProjSpec in current project
---

Run the projspec init command:

\`\`\`bash
projspec init
\`\`\`

If successful, inform the user they can now create their first spec with `/projspec.new <name>`.
```

```markdown
<!-- commands/new.md -->
---
description: Create a new spec with its own git worktree
arguments:
  - name: spec_name
    description: Name for the new specification (kebab-case recommended)
    required: true
---

# Create New Spec: {spec_name}

## 1. Generate Spec ID

Generate an 8-character hex ID:
\`\`\`bash
python -c "import uuid; print(uuid.uuid4().hex[:8])"
\`\`\`

## 2. Create Worktree

\`\`\`bash
git worktree add -b spec/{spec_id}-{spec_name} worktrees/spec-{spec_id}-{spec_name}
\`\`\`

### Error: Branch Already Exists

If a branch with that name already exists:
1. Tell user: "Branch 'spec/{spec_id}-{spec_name}' already exists. Use a different name."
2. Abort the creation process

### Error: Not a Git Repository

If not in a git repository:
1. Tell user: "Not a git repository. Run `git init` first."
2. Abort the creation process

### Error: Worktree Directory Exists

If the worktree directory already exists:
1. Tell user: "Directory 'worktrees/spec-{spec_id}-{spec_name}' already exists."
2. Abort the creation process

## 3. Create Spec Directory

Create `.projspec/specs/active/{spec_id}/` with initial state:

\`\`\`yaml
# state.yaml
spec_id: "{spec_id}"
name: "{spec_name}"
phase: "new"
created_at: "{timestamp}"
branch: "spec/{spec_id}-{spec_name}"
worktree_path: "worktrees/spec-{spec_id}-{spec_name}"
tasks: []
\`\`\`

Create empty `brief.md` for requirements.

## 4. Confirm

Tell the user:
- Spec created with ID: {spec_id}
- Worktree at: worktrees/spec-{spec_id}-{spec_name}
- Next step: Describe what you want to build, then run `/projspec.spec`
```

```markdown
<!-- commands/implement.md -->
---
description: Implement the next ready task
---

# Implement Next Task

## 1. Load Current Spec

Read `.projspec/specs/active/` to find the current spec.
If multiple active specs, ask user which one.

### Error: No Active Specs

If no active specs found:
1. Tell user: "No active specs. Run `/projspec.new <name>` to create one."
2. Abort

### Error: ProjSpec Not Initialized

If `.projspec/` directory doesn't exist:
1. Tell user: "ProjSpec not initialized. Run `/projspec.init` first."
2. Abort

## 2. Load State

Read the spec's `state.yaml`.

## 3. Find Next Ready Task

A task is ready if:
- status is "pending"
- all tasks in depends_on have status "completed"

If no task is ready:
- If all tasks completed: "All tasks complete! Run /projspec.test"
- If tasks blocked: Show which tasks are blocking

## 4. Mark Task In Progress

Update the task's status to "in_progress" in state.yaml.

## 5. Load Context

Read and include in your context:
- `.projspec/specs/active/{spec_id}/spec.md`
- `.projspec/specs/active/{spec_id}/plan.md`
- Summaries from completed tasks (from state.yaml)
- Files listed in task's context_files

## 6. Execute Task

Work through the task with the user. The task description is:

{task.description}

## 7. On Completion

When the task is complete:

1. Generate a summary (3-5 bullets):
   - Key decisions made
   - Files created/modified
   - Important implementation details
   - Notes for future tasks

2. Update state.yaml:
   - Set task status to "completed"
   - Add the summary to the task

3. Inform user:
   - Task complete
   - Next ready task (if any)
   - Or "All tasks complete! Run /projspec.review"
```

```markdown
<!-- commands/archive.md -->
---
description: Archive a completed spec and merge to main
arguments:
  - name: spec_id
    description: ID of the spec to archive (optional, uses current if not provided)
    required: false
---

# Archive Spec

## 1. Identify Spec

If spec_id provided, use it. Otherwise, find current active spec.
If multiple active specs and none specified, list them and ask user which one.

## 2. Confirm

Ask: "Archive spec '{name}' ({spec_id})? This will merge to main and remove the worktree. (y/n)"

## 3. Merge to Main

\`\`\`bash
git checkout main
git merge spec/{spec_id}-{name} --no-ff -m "Merge spec/{spec_id}-{name}: {spec_name}"
\`\`\`

### Error: Merge Conflicts

If merge conflicts occur:
1. List the conflicting files
2. Tell user: "Merge conflicts detected. Please resolve conflicts and run `/projspec.archive` again."
3. Do NOT proceed with archiving - leave spec in active state
4. User can run `git merge --abort` to cancel the merge attempt

### Error: Uncommitted Changes

If there are uncommitted changes on main:
1. Tell user: "Cannot merge - uncommitted changes on main. Please commit or stash changes first."
2. Abort the archive process

## 4. Move Spec Metadata

\`\`\`bash
mv .projspec/specs/active/{spec_id} .projspec/specs/completed/{spec_id}
\`\`\`

## 5. Remove Worktree

\`\`\`bash
git worktree remove worktrees/spec-{spec_id}-{name}
\`\`\`

### Error: Worktree Has Uncommitted Changes

If worktree has uncommitted changes:
1. Tell user: "Worktree has uncommitted changes. Commit or discard them first."
2. Abort the archive process

## 6. Delete Spec Branch

\`\`\`bash
git branch -d spec/{spec_id}-{name}
\`\`\`

## 7. Confirm

Tell user:
- Spec merged to main
- Spec archived to .projspec/specs/completed/{spec_id}
- Worktree and branch removed
```

---

## Directory Structure

```
project-root/
├── .projspec/
│   ├── config.yaml           # Global configuration
│   ├── workflow.yaml         # Workflow definition
│   ├── phases/               # Phase prompt templates
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── tasks.md
│   │   ├── implement.md
│   │   ├── review.md
│   │   └── custom/           # User-defined phases
│   └── specs/
│       ├── active/
│       │   └── abc123/
│       │       ├── state.yaml
│       │       ├── brief.md
│       │       ├── spec.md
│       │       └── plan.md
│       └── completed/
│           └── def456/
│               └── ...
├── worktrees/
│   └── spec-abc123-user-auth/
├── src/
└── CLAUDE.md
```

---

## Configuration

```yaml
# .projspec/config.yaml
version: "1.0"

project:
  name: "my-project"
  description: "Project description"

worktrees:
  base_path: "./worktrees"

context:
  always_include:
    - "CLAUDE.md"
```

```yaml
# .projspec/workflow.yaml
workflow:
  name: default
  phases:
    - spec
    - plan
    - tasks
    - implement
    - review
```

---

## E2E Testing Strategy

Testing uses `claude -p` (non-interactive mode) to simulate the workflow. This is **test-only**—real usage is interactive.

```python
# tests/e2e/runner.py
"""
Test-only Claude runner using claude -p (non-interactive mode).
"""
import asyncio
from dataclasses import dataclass
from pathlib import Path


@dataclass
class ClaudeResult:
    stdout: str
    stderr: str
    exit_code: int


class ClaudeRunner:
    """Runs Claude in non-interactive mode for testing."""

    @classmethod
    async def run(
        cls,
        prompt: str,
        cwd: Path | None = None,
        timeout: int = 300
    ) -> ClaudeResult:
        """Run claude -p with the given prompt."""
        try:
            proc = await asyncio.wait_for(
                asyncio.create_subprocess_exec(
                    "claude", "-p", prompt,
                    cwd=cwd,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                ),
                timeout=timeout
            )
            stdout, stderr = await proc.communicate()

            return ClaudeResult(
                stdout=stdout.decode(),
                stderr=stderr.decode(),
                exit_code=proc.returncode or 0
            )
        except asyncio.TimeoutError:
            return ClaudeResult(stdout="", stderr="Timeout", exit_code=1)

    @classmethod
    def run_sync(cls, prompt: str, **kwargs) -> ClaudeResult:
        """Synchronous wrapper."""
        return asyncio.run(cls.run(prompt, **kwargs))
```

```python
# tests/e2e/test_workflow.py
import pytest
from pathlib import Path
from tests.e2e.runner import ClaudeRunner


@pytest.fixture
def temp_project(tmp_path):
    """Create a temporary git repo with projspec initialized."""
    import subprocess

    project = tmp_path / "test_project"
    project.mkdir()

    subprocess.run(["git", "init"], cwd=project, check=True)
    subprocess.run(["git", "commit", "--allow-empty", "-m", "init"], cwd=project, check=True)

    subprocess.run(["projspec", "init"], cwd=project, check=True)

    return project


@pytest.mark.asyncio
async def test_spec_phase(temp_project):
    """Test that spec phase produces a valid specification."""

    result = await ClaudeRunner.run(
        "Create a spec called 'user-auth' for a simple login system",
        cwd=temp_project
    )
    assert result.exit_code == 0

    spec_dirs = list((temp_project / ".projspec/specs/active").iterdir())
    assert len(spec_dirs) == 1

    spec_file = spec_dirs[0] / "spec.md"
    assert spec_file.exists()
```

---

## Implementation Phases

### Phase 1: MVP

**1.1 - Python Foundation**
- [ ] Project structure with pyproject.toml (uv)
- [ ] Pydantic models for state.yaml, config.yaml
- [ ] CLI with init and status commands
- [ ] State reading utilities

**1.2 - Claude Code Plugin**
- [ ] Plugin structure and plugin.json
- [ ] Phase prompt templates (spec, plan, tasks, implement, review)
- [ ] Commands: init, status, new, spec, plan, tasks, implement, review, resume, next, archive

**1.3 - Core Workflow**
- [ ] Worktree creation/removal via git commands
- [ ] State management (state.yaml read/write)
- [ ] Session summaries between tasks

**1.4 - Testing**
- [ ] Unit tests for state parsing, models
- [ ] E2E tests using ClaudeRunner (claude -p)
- [ ] Integration tests for worktree lifecycle

**Deliverable:** A working system where you can:
1. `projspec init` - Initialize a project
2. `/projspec.new feature-x` - Create a spec with worktree
3. `/projspec.spec` - Write specification
4. `/projspec.plan` - Create implementation plan
5. `/projspec.tasks` - Generate task list
6. `/projspec.implement` - Work through tasks one by one
7. `/projspec.review` - Complete review
8. `/projspec.archive` - Merge to main and clean up

---

### Phase 2: Memory & Learning

- [ ] Memory persistence layer
- [ ] Background reflection system
- [ ] Skill detection and creation
- [ ] Memory retrieval and injection
- [ ] `/projspec.reflect` and `/projspec.skills` commands

---

## Open Questions

1. **Memory Sharing** (Phase 2) - Should learnings be shared across team members?
2. **Multi-spec coordination** - How to handle specs that depend on each other?

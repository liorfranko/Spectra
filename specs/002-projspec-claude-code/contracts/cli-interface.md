# CLI Interface Contract

**Feature**: 002-projspec-claude-code
**Date**: 2026-01-26

## Overview

ProjSpec exposes two interfaces:
1. **Python CLI** (`projspec`) - For initialization and status
2. **Claude Code Plugin** - Slash commands for workflow

---

## Python CLI Commands

### `projspec init [project-name]`

Initialize ProjSpec in a directory.

**Arguments**:
| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| project-name | string | No | Current directory name | Project name |

**Options**:
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--here` | flag | false | Initialize in current directory |
| `--force` | flag | false | Skip confirmation prompts |
| `--no-git` | flag | false | Skip git initialization |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Already initialized (with `--force`, continues anyway) |
| 2 | Not a git repository (unless `--no-git`) |

**Output**:
```
✓ Created .specify/config.yaml
✓ Created .specify/memory/constitution.md
✓ Created .specify/scripts/bash/
✓ Created .specify/templates/
✓ Created specs/
✓ Created worktrees/

ProjSpec initialized in /path/to/project

Features will be created in worktrees/ with isolated working directories.
Run /speckit.specify in Claude Code to create your first feature.
```

---

### `projspec status`

Display status of all active features.

**Options**:
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--json` | flag | false | Output as JSON |

**Output (default)**:
```
╭─ ProjSpec Status ─────────────────────────────────────────────╮
│                                                                │
│  Active Features: 2                                            │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ 001-user-auth                                            │  │
│  │ Phase: implement  │  Tasks: 5/8                          │  │
│  │ Worktree: worktrees/001-user-auth                        │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ 002-projspec-claude-code                                 │  │
│  │ Phase: plan  │  Tasks: 0/0                               │  │
│  │ Worktree: worktrees/002-projspec-claude-code             │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
╰────────────────────────────────────────────────────────────────╯
```

**Output (--json)**:
```json
{
  "features": [
    {
      "id": "001",
      "name": "user-auth",
      "phase": "implement",
      "tasks": {"total": 8, "completed": 5, "in_progress": 1},
      "branch": "001-user-auth",
      "worktree": "worktrees/001-user-auth"
    }
  ]
}
```

---

### `projspec check`

Verify installed tools and prerequisites.

**Output**:
```
╭─ Environment Check ───────────────────────────────────────────╮
│                                                                │
│  ✓ Python 3.11.4                                               │
│  ✓ Git 2.39.0                                                  │
│  ✓ Claude Code (claude-code 1.0.0)                             │
│  ✓ Bash 5.2.15                                                 │
│                                                                │
│  All prerequisites satisfied                                   │
│                                                                │
╰────────────────────────────────────────────────────────────────╯
```

---

### `projspec version`

Display version information.

**Output**:
```
projspec 1.0.0
Python 3.11.4
Platform: darwin (macOS 14.0)
```

---

## Command Prompt Templates

Commands are implemented as markdown prompt templates in `.specify/templates/commands/`. Users invoke them by asking Claude to read and follow the template.

**Usage**:
```
"Read .specify/templates/commands/specify.md and follow those instructions"
```

### `specify.md`

Create or update a feature specification.

**Triggers**: User describes a feature to implement
**Input**: Natural language feature description
**Output**: `specs/NNN-feature-name/spec.md`
**Side Effects** (for new features):
- Creates git worktree at `worktrees/NNN-feature-name/`
- Creates git branch `NNN-feature-name`
- Creates feature spec directory `specs/NNN-feature-name/`
- Creates symlinks in worktree to shared `specs/` and `.specify/`
- Updates `state.yaml` to phase: spec
- Outputs: "Open Claude Code in worktrees/NNN-feature-name/ to continue"

---

### `clarify.md`

Resolve ambiguities in the current specification.

**Prerequisites**: `spec.md` exists with `[NEEDS CLARIFICATION]` markers
**Input**: None (reads current spec)
**Output**: Updated `spec.md` with clarifications resolved
**Behavior**:
- Asks maximum 3 clarifying questions
- Updates spec with concrete answers

---

### `plan.md`

Generate implementation plan from specification.

**Prerequisites**: `spec.md` complete (no unresolved clarifications)
**Input**: None (reads current spec)
**Output**:
- `plan.md` - Implementation plan
- `research.md` - Technology decisions
- `data-model.md` - Entity definitions
- `quickstart.md` - Validation scenarios
- `contracts/` - API contracts
**Side Effects**:
- Updates `state.yaml` to phase: plan
- Updates CLAUDE.md with new technologies

---

### `tasks.md`

Generate task breakdown from plan.

**Prerequisites**: `plan.md` complete
**Input**: None (reads current plan)
**Output**: `tasks.md`
**Side Effects**:
- Updates `state.yaml` with task list
- Updates phase to: tasks

---

### `implement.md`

Execute tasks sequentially with context.

**Prerequisites**: `tasks.md` exists with pending tasks
**Input**: None
**Behavior**:
1. Find next ready task (dependencies satisfied)
2. Load context: spec, plan, previous task summaries
3. Mark task `in_progress`
4. Guide implementation
5. On completion: generate summary, mark `completed`
6. Continue to next task
**Output**: Source code changes per task
**Side Effects**:
- Updates task status in `state.yaml`
- Updates phase to: implement

---

### `analyze.md`

Validate consistency across artifacts.

**Prerequisites**: At least `spec.md` and `plan.md` exist
**Input**: None
**Output**: Consistency report showing:
- Requirement coverage
- Entity alignment
- Task completeness
- Potential gaps

---

### `checklist.md`

Generate quality verification checklist.

**Prerequisites**: `spec.md` exists
**Input**: Optional focus areas
**Output**: `checklists/requirements.md` or custom checklist

---

### `constitution.md`

Create or update project constitution.

**Input**: Principles and governance rules
**Output**: `.specify/memory/constitution.md`

---

### `taskstoissues.md`

Convert tasks to GitHub issues.

**Prerequisites**: `tasks.md` exists
**Input**: None
**Output**: GitHub issues created via `gh` CLI
**Behavior**:
- Creates issues with proper dependencies
- Links issues to parent feature issue
- Preserves task ordering

---

## Script Contracts

### `common.sh` Functions

| Function | Input | Output | Description |
|----------|-------|--------|-------------|
| `get_repo_root` | - | stdout: path | Find repository root (handles worktrees) |
| `get_main_repo_root` | - | stdout: path | Find main repo root (not worktree) |
| `get_current_branch` | - | stdout: branch | Current git branch |
| `has_git` | - | exit 0/1 | Check git availability |
| `is_worktree` | - | exit 0/1 | Check if cwd is a git worktree |
| `get_worktree_path` | branch | stdout: path | Get worktree path for branch |
| `check_feature_branch` | - | exit 0/1 | Validate branch naming |
| `get_feature_dir` | branch | stdout: path | Get feature spec directory |
| `get_feature_paths` | - | exports vars | Export FEATURE_SPEC, IMPL_PLAN, WORKTREE, etc. |

### `check-prerequisites.sh`

| Option | Description |
|--------|-------------|
| `--json` | JSON output format |
| `--require-tasks` | Require tasks.md |
| `--include-tasks` | Include tasks.md in checks |
| `--paths-only` | Output paths without validation |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | All prerequisites satisfied |
| 1 | Missing required files |
| 2 | Invalid branch/feature |

### `create-new-feature.sh`

Creates a new feature with worktree, branch, and spec directory.

| Option | Description |
|--------|-------------|
| `--short-name NAME` | Custom branch suffix |
| `--number N` | Manual feature number |
| `--json` | JSON output format |

**Behavior**:
1. Determines next feature number (scans existing specs/)
2. Creates git branch: `NNN-feature-name`
3. Creates git worktree: `worktrees/NNN-feature-name/`
4. Creates spec directory: `specs/NNN-feature-name/`
5. Creates symlinks in worktree:
   - `specs -> ../../specs`
   - `.specify -> ../../.specify`
6. Initializes `state.yaml` in spec directory

**Output (JSON)**:
```json
{
  "FEATURE_DIR": "/path/to/specs/001-feature",
  "FEATURE_SPEC": "/path/to/specs/001-feature/spec.md",
  "WORKTREE": "/path/to/worktrees/001-feature",
  "BRANCH": "001-feature",
  "NUMBER": "001"
}
```

**Instructions Output**:
```
✓ Created worktree: worktrees/001-feature
✓ Created branch: 001-feature
✓ Created spec directory: specs/001-feature

To continue, open Claude Code in the worktree:
  cd worktrees/001-feature && claude
```

### `setup-plan.sh`

**Output (JSON)**:
```json
{
  "FEATURE_SPEC": "/path/to/spec.md",
  "IMPL_PLAN": "/path/to/plan.md",
  "SPECS_DIR": "/path/to/specs/001-feature",
  "BRANCH": "001-feature",
  "HAS_GIT": "true"
}
```

### `update-agent-context.sh`

| Argument | Description |
|----------|-------------|
| agent | Agent type: "claude", "copilot", etc. |

**Behavior**:
- Extracts technologies from all plan.md files
- Updates CLAUDE.md with active technologies
- Preserves manual additions between markers

### `archive-feature.sh`

Archives a completed feature by merging and cleaning up the worktree.

| Option | Description |
|--------|-------------|
| `--feature NNN` | Feature number to archive (default: current) |
| `--no-merge` | Skip merge to main branch |
| `--delete-branch` | Delete the feature branch after merge |
| `--json` | JSON output format |

**Behavior**:
1. Validates all tasks are completed
2. Merges feature branch to main (unless `--no-merge`)
3. Removes git worktree: `git worktree remove worktrees/NNN-feature`
4. Updates feature state to `archived`
5. Optionally deletes branch (if `--delete-branch`)

**Safety Checks**:
- Aborts if uncommitted changes exist in worktree
- Aborts if merge conflicts detected
- Warns if tasks are incomplete (requires confirmation)

**Output**:
```
✓ Merged 001-user-auth to main
✓ Removed worktree: worktrees/001-user-auth
✓ Feature 001-user-auth archived

Spec artifacts preserved in: specs/001-user-auth/
```

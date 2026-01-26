# Data Model: Worktree-Based Feature Workflow

**Feature**: 007-worktree-workflow
**Date**: 2026-01-26

## Overview

This document defines the conceptual data model for worktree-based feature workflows. These entities are represented as bash variables and environment state rather than persistent database records.

---

## Entities

### WorktreeContext

Represents the current execution context, determining whether code is running in a worktree or the main repository.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `is_worktree` | boolean | True if current directory is inside a git worktree | `true` |
| `worktree_path` | string | Absolute path to the worktree root | `/Users/dev/projspec/worktrees/007-worktree-workflow` |
| `main_repo_path` | string | Absolute path to the main repository | `/Users/dev/projspec` |
| `branch_name` | string | Name of the branch checked out in this worktree | `007-worktree-workflow` |
| `git_dir` | string | Path to the .git directory/file | `/Users/dev/projspec/worktrees/007-worktree-workflow/.git` |
| `git_common_dir` | string | Path to the shared .git directory in main repo | `/Users/dev/projspec/.git` |

**Derivation Rules**:
- `is_worktree = (git_common_dir != git_dir)`
- `main_repo_path = git_common_dir | sed 's|/.git$||'`
- `worktree_path = git rev-parse --show-toplevel`

**Validation Rules**:
- `branch_name` should match pattern `^\d{3}-[a-z0-9-]+$`

---

### FeatureContext

Represents the paths and state associated with a specific feature being developed.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `feature_num` | string | 3-digit feature number | `007` |
| `feature_name` | string | Full branch/feature name | `007-worktree-workflow` |
| `feature_dir` | string | Path to feature's spec directory (context-dependent) | `/Users/dev/projspec/worktrees/007-worktree-workflow/specs/007-worktree-workflow` (during dev) or `/Users/dev/projspec/specs/007-worktree-workflow` (after merge) |
| `spec_file` | string | Path to spec.md | `{feature_dir}/spec.md` |
| `plan_file` | string | Path to plan.md | `{feature_dir}/plan.md` |
| `tasks_file` | string | Path to tasks.md | `{feature_dir}/tasks.md` |
| `research_file` | string | Path to research.md | `{feature_dir}/research.md` |
| `data_model_file` | string | Path to data-model.md | `{feature_dir}/data-model.md` |
| `quickstart_file` | string | Path to quickstart.md | `{feature_dir}/quickstart.md` |
| `contracts_dir` | string | Path to contracts directory | `{feature_dir}/contracts` |
| `checklists_dir` | string | Path to checklists directory | `{feature_dir}/checklists` |
| `worktree_path` | string | Path to worktree (if exists) | `/Users/dev/projspec/worktrees/007-worktree-workflow` |
| `has_worktree` | boolean | True if feature has an associated worktree | `true` |

**Derivation Rules**:
- `feature_num = feature_name | grep -o '^\d{3}'`
- `feature_dir` location depends on context:
  - During development (worktree exists): `{worktree_path}/specs/{feature_name}`
  - After PR merge (worktree removed): `{main_repo}/specs/{feature_name}`
- `worktree_path = git worktree list | find by branch`

**Validation Rules**:
- `spec_file` MUST exist for feature to be valid
- Other files are optional at various workflow stages

---

### RepoContext

Represents the overall repository state, including all worktrees and configuration.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `repo_root` | string | Absolute path to main repository root | `/Users/dev/projspec` |
| `has_git` | boolean | True if repository is git-initialized | `true` |
| `current_branch` | string | Currently checked out branch | `main` or `007-worktree-workflow` |
| `specs_dir` | string | Path to specs directory | `{repo_root}/specs` |
| `worktrees_dir` | string | Path to worktrees directory | `{repo_root}/worktrees` |
| `specify_dir` | string | Path to .specify configuration | `{repo_root}/.specify` |
| `worktrees` | list | List of all worktrees | See Worktree entity |

**Derivation Rules**:
- `repo_root = git rev-parse --show-toplevel` (from main repo)
- `worktrees` populated from `git worktree list --porcelain`

---

### Worktree (List Item)

Represents a single worktree entry from `git worktree list`.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `path` | string | Absolute path to worktree | `/Users/dev/projspec/worktrees/007-worktree-workflow` |
| `branch` | string | Branch checked out in worktree | `refs/heads/007-worktree-workflow` |
| `head` | string | Current HEAD commit SHA | `abc123def456...` |
| `is_bare` | boolean | True if bare worktree | `false` |
| `is_prunable` | boolean | True if worktree path no longer exists | `false` |

**Source**: `git worktree list --porcelain`

---

## Entity Relationships

```
RepoContext
    │
    ├── has many → Worktree (via worktrees list)
    │
    └── WorktreeContext (current execution context)
            │
            ├── references → RepoContext.repo_root (as main_repo_path)
            │
            └── associated with → FeatureContext
                                    │
                                    └── may have → Worktree (optional)
```

---

## State Transitions

### Feature Lifecycle

```
1. CREATED
   - Triggered by: /projspec.specify
   - Creates: FeatureContext with spec_file
   - Creates: Worktree (if git available)
   - State: has_worktree = true, worktree_path set

2. PLANNED
   - Triggered by: /projspec.plan
   - Creates: plan_file, research_file, data_model_file, quickstart_file
   - Requires: spec_file exists

3. TASKED
   - Triggered by: /projspec.tasks
   - Creates: tasks_file
   - Requires: plan_file exists

4. IMPLEMENTING
   - Triggered by: /projspec.implement
   - Modifies: Source files in worktree_path
   - Updates: tasks_file checkboxes
   - Requires: tasks_file exists, worktree_path valid

5. COMPLETED
   - All tasks marked complete
   - Ready for: PR creation, worktree cleanup

6. CLEANUP (optional)
   - Triggered by: git worktree remove
   - Removes: Worktree directory
   - Preserves: All specs in specs_dir
```

---

## Environment Variables

These environment variables are used to pass context between scripts:

| Variable | Purpose | Set By |
|----------|---------|--------|
| `SPECIFY_FEATURE` | Current feature name | create-new-feature.sh |
| `REPO_ROOT` | Main repository path | common.sh via get_repo_root() |
| `FEATURE_DIR` | Feature spec directory | common.sh via get_feature_paths() |

---

## Bash Output Format

Scripts output context as evaluable bash variables:

```bash
# From get_feature_paths()
REPO_ROOT='/Users/dev/projspec'
CURRENT_BRANCH='007-worktree-workflow'
HAS_GIT='true'
FEATURE_DIR='/Users/dev/projspec/specs/007-worktree-workflow'
FEATURE_SPEC='/Users/dev/projspec/specs/007-worktree-workflow/spec.md'
IMPL_PLAN='/Users/dev/projspec/specs/007-worktree-workflow/plan.md'
TASKS='/Users/dev/projspec/specs/007-worktree-workflow/tasks.md'
RESEARCH='/Users/dev/projspec/specs/007-worktree-workflow/research.md'
DATA_MODEL='/Users/dev/projspec/specs/007-worktree-workflow/data-model.md'
QUICKSTART='/Users/dev/projspec/specs/007-worktree-workflow/quickstart.md'
CONTRACTS_DIR='/Users/dev/projspec/specs/007-worktree-workflow/contracts'
```

Scripts can consume this via:
```bash
eval "$(get_feature_paths)"
echo "Feature spec at: $FEATURE_SPEC"
```

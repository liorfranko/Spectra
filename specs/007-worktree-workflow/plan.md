# Implementation Plan: Worktree-Based Feature Workflow

**Branch**: `007-worktree-workflow` | **Date**: 2026-01-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-worktree-workflow/spec.md`

## Summary

Enhance the projspec plugin to use git worktrees for feature isolation instead of simple branch switching. The current implementation already creates worktrees with specs stored directly in the worktree, but requires improvements to ensure all commands work correctly from worktree context, provide better navigation guidance, and update documentation to reflect worktree-based terminology.

## Technical Context

**Language/Version**: Bash 5.x (scripts), Markdown (commands/agents/skills)
**Primary Dependencies**: Claude Code plugin system, Git 2.5+ (worktrees)
**Storage**: N/A (file-based configuration only)
**Testing**: Manual verification + bash script tests
**Target Platform**: macOS/Linux
**Project Type**: Single project - CLI tool/plugin
**Performance Goals**: Sub-second script execution
**Constraints**: Must maintain backward compatibility with existing features
**Scale/Scope**: Single-developer workflow optimization

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution template is unpopulated (placeholder content only). Since no project-specific principles are defined, this plan proceeds with industry-standard best practices:

- [ ] **Simplicity**: Minimize new abstractions; extend existing patterns
- [ ] **Backward Compatibility**: Existing features must continue to work
- [ ] **Documentation**: All changes must be documented for users
- [ ] **Error Handling**: Provide clear guidance when things go wrong

**Status**: PASS (no constitution violations - template is unpopulated)

## Project Structure

### Documentation (this feature)

```text
specs/007-worktree-workflow/
├── plan.md              # This file
├── research.md          # Phase 0 output - worktree patterns research
├── data-model.md        # Phase 1 output - worktree context model
├── quickstart.md        # Phase 1 output - worktree workflow guide
├── contracts/           # Phase 1 output - script interfaces
│   └── worktree-context.md  # Worktree detection contract
└── tasks.md             # Phase 2 output (/projspec.tasks command)
```

### Source Code (repository root)

```text
.specify/
├── scripts/bash/
│   ├── common.sh                 # MODIFY: Enhanced worktree detection
│   ├── create-new-feature.sh     # REVIEW: Already has worktree creation
│   ├── setup-plan.sh             # REVIEW: Path resolution from worktrees
│   ├── check-prerequisites.sh    # REVIEW: Worktree context detection
│   └── update-agent-context.sh   # REVIEW: Path resolution
├── templates/
│   └── spec-template.md          # REVIEW: Worktree terminology
└── memory/
    └── constitution.md           # Reference only

.claude/
├── commands/
│   ├── projspec.specify.md       # REVIEW: Worktree guidance
│   ├── projspec.plan.md          # REVIEW: Path handling
│   ├── projspec.implement.md     # MODIFY: Source code in worktree context
│   └── ...other commands
└── skills/learned/
    └── worktree-based-feature-workflow.md  # EXISTS: Reference guide

worktrees/
└── <NNN-feature-name>/           # Created by create-new-feature.sh
    ├── .git                      # Worktree pointer file
    ├── specs/<NNN-feature-name>/ # Feature specs (committed to feature branch)
    └── <source files>            # Feature-specific code changes
```

**Structure Decision**: Single project structure with scripts in `.specify/scripts/bash/` and commands in `.claude/commands/`. Worktrees created in `worktrees/` directory with feature specs stored directly in worktree.

## Complexity Tracking

No constitution violations requiring justification. The implementation extends existing patterns rather than introducing new complexity.

---

## Phase 0: Research

### Research Tasks

Based on Technical Context analysis, the following areas need research:

1. **Git Worktree Edge Cases**: How git handles worktrees when:
   - Main repo is on a branch already checked out in a worktree
   - Worktree is deleted without proper cleanup

2. **Path Resolution Patterns**: Best practices for:
   - Detecting worktree vs main repo context
   - Resolving paths to `.specify/` resources from worktrees
   - Handling nested worktree scenarios (worktree of a worktree)

3. **Cross-Platform Considerations**: Verify:
   - Git worktree command compatibility across Git versions

### Current State Analysis

Based on code exploration, the current implementation already handles:

- ✅ Worktree creation in `create-new-feature.sh`
- ✅ Specs created in worktree for feature branch commits
- ✅ Basic path resolution via `get_repo_root()` using git rev-parse
- ✅ Branch detection via `get_current_branch()`

**Gaps identified requiring implementation**:

1. **FR-009**: `common.sh` needs dedicated worktree detection functions:
   - `is_worktree()` - detect if current dir is a worktree
   - `get_worktree_main_repo()` - get path to main repo from worktree
   - `get_worktree_path_for_branch()` - find worktree path for a branch

2. **FR-010**: Commands need context detection:
   - When user runs command from main repo with a branch checked out in a worktree
   - Provide guidance to navigate to appropriate worktree

3. **FR-006**: Verify source code modifications go to worktree:
   - Current implement command needs worktree-aware path handling
   - Source files must be created/modified in worktree, not main repo

4. **FR-007**: Documentation updates:
   - Replace "checkout branch" with "create worktree" terminology
   - Update help text and error messages

---

## Phase 1: Design

### Data Model

Key entities for worktree context:

| Entity | Description | Key Fields |
|--------|-------------|------------|
| WorktreeContext | Current execution context | `is_worktree`, `main_repo_path`, `worktree_path`, `branch_name` |
| FeatureContext | Feature-specific paths | `feature_dir`, `spec_file`, `plan_file`, `worktree_path` |
| RepoContext | Repository state | `repo_root`, `has_git`, `current_branch`, `worktrees[]` |

### Script Interface Contracts

#### `common.sh` Additions

```bash
# Detect if current directory is inside a git worktree
# Returns: 0 if worktree, 1 if not
is_worktree() {
    local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    local git_dir=$(git rev-parse --git-dir 2>/dev/null)
    [[ "$git_common_dir" != "$git_dir" ]]
}

# Get the main repository path from a worktree
# Returns: Absolute path to main repo, or empty if not in worktree
get_main_repo_from_worktree() {
    if is_worktree; then
        git rev-parse --git-common-dir 2>/dev/null | sed 's|/.git$||'
    fi
}

# Get worktree path for a given branch
# Returns: Worktree path or empty if branch not in a worktree
get_worktree_for_branch() {
    local branch="$1"
    git worktree list --porcelain 2>/dev/null | \
        awk -v branch="$branch" '
            /^worktree / { wt = substr($0, 10) }
            /^branch / && $2 ~ branch"$" { print wt }
        '
}
```

#### Context Detection for Commands

```bash
# Check if user should be in a worktree instead of main repo
# Prints guidance message and returns 1 if redirect needed
check_worktree_context() {
    local current_branch=$(get_current_branch)

    # Skip if we're already in a worktree
    if is_worktree; then
        return 0
    fi

    # Check if current branch has a worktree
    local worktree_path=$(get_worktree_for_branch "$current_branch")
    if [[ -n "$worktree_path" ]]; then
        echo "⚠️  Branch '$current_branch' is checked out in a worktree" >&2
        echo "   Worktree location: $worktree_path" >&2
        echo "   Navigate there with: cd $worktree_path" >&2
        return 1
    fi

    return 0
}
```

### Implementation Approach

1. **Enhance `common.sh`** with worktree utilities (non-breaking additions)
2. **Update scripts** to use worktree context detection
3. **Update commands** to provide worktree guidance
4. **Update documentation** with worktree terminology

### Acceptance Criteria Mapping

| Requirement | Implementation |
|-------------|----------------|
| FR-001 | Already implemented in `create-new-feature.sh` |
| FR-002 | Updated to create specs in worktree (committed to feature branch) |
| FR-003 | Already implemented (navigation instructions printed) |
| FR-004 | Verify path resolution works from worktree context |
| FR-005 | Verify `get_repo_root()` finds repo root from worktree |
| FR-006 | Update implement command for worktree-aware paths |
| FR-007 | Update documentation and help text |
| FR-008 | Standard git PR flow (specs merge with feature) |
| FR-009 | Add `is_worktree()`, `get_main_repo_from_worktree()`, etc. |
| FR-010 | Add `check_worktree_context()` to relevant scripts |

---

## Artifacts Generated

- [x] `plan.md` - This file
- [x] `research.md` - Git worktree patterns, edge cases, path resolution
- [x] `data-model.md` - WorktreeContext, FeatureContext, RepoContext entities
- [x] `quickstart.md` - Worktree workflow guide for developers
- [x] `contracts/worktree-context.md` - Script interface specifications for common.sh additions

---

## Next Steps

1. Run `/projspec.tasks` to generate the task breakdown
2. Implement tasks in order following the established workflow
3. Test all commands from worktree context
4. Update documentation with worktree terminology

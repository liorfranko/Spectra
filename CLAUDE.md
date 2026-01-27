# projspec Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-26

## Active Technologies
- Bash 5.x (scripts), Markdown (commands/agents/skills) + Claude Code plugin system, Gi (005-rename-speckit-projspec)
- N/A (file-based configuration only) (005-rename-speckit-projspec)
- Bash 5.x (scripts), Markdown (commands/agents/skills) + Claude Code plugin system, Git 2.5+ (worktrees) (007-worktree-workflow)

- Bash 5.x for scripts, Markdown for commands/skills/agents + Claude Code plugin system, Git, GitHub CLI (optional for issues) (003-claude-plugin-speckit)
- Python 3.11+ (CLI), Bash 4.0+ (scripts), Markdown (templates/commands) + typer, rich, pydantic, platformdirs (matching spec-kit's CLI stack) (002-projspec-claude-code)
- Python 3.11+ + pydantic, pyyaml, rich, pytest (001-projspec-mvp)

## Project Structure

```text
projspec/
specs/
```

## Commands

# No commands defined yet

## Code Style

Bash 5.x for scripts, Markdown for commands/skills/agents: Follow standard conventions
Python 3.11+ (CLI), Bash 4.0+ (scripts), Markdown (templates/commands): Follow standard conventions
Python 3.11+: Follow standard conventions

## Recent Changes
- 007-worktree-workflow: Added Bash 5.x (scripts), Markdown (commands/agents/skills) + Claude Code plugin system, Git 2.5+ (worktrees)
- 005-rename-speckit-projspec: Added Bash 5.x (scripts), Markdown (commands/agents/skills) + Claude Code plugin system, Gi

- 001-projspec-mvp: Added Python 3.11+ + pydantic, pyyaml, rich, pytest

<!-- MANUAL ADDITIONS START -->

## Worktree Workflow

This project uses git worktrees for feature isolation:
- New features are created in `worktrees/<NNN-feature-name>/`
- Feature specs live in `worktrees/<feature>/specs/<feature>/`
- Run projspec commands from the worktree directory
- After PR merge, specs appear in main repo's `specs/` directory

Key worktree functions in `.projspec/scripts/bash/common.sh`:
- `is_worktree()` - detect if in worktree context
- `get_main_repo_from_worktree()` - get main repo path
- `get_worktree_for_branch()` - find worktree by branch
- `check_worktree_context()` - warn if should navigate to worktree

<!-- MANUAL ADDITIONS END -->

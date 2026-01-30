# Spectra Development Guidelines

## Overview

Spectra is a Claude Code plugin for spec-driven development. It provides commands for creating specifications, generating implementation plans, breaking down tasks, and managing feature development workflows.

## Tech Stack

- **Plugin System**: Claude Code plugin (markdown commands, agents, skills, hooks)
- **Scripts**: Bash 5.x
- **Version Control**: Git with worktree-based feature isolation

## Project Structure

```
spectra/
├── plugins/spectra/     # Main plugin
│   ├── commands/         # Slash commands (/spectra:*)
│   ├── agents/           # Specialized agents
│   ├── scripts/          # Bash helper scripts
│   ├── templates/        # Document templates
│   ├── memory/           # Persistent context (constitution)
│   └── hooks/            # Event hooks
├── specs/                # Completed feature specs (merged from worktrees)
└── worktrees/            # Active feature branches
```

## Worktree Workflow

This project uses git worktrees for feature isolation:
- New features are created in `worktrees/<NNN-feature-name>/`
- Feature specs live in `worktrees/<feature>/specs/<feature>/`
- Run Spectra commands from the worktree directory
- After PR merge, specs appear in main repo's `specs/` directory

Key worktree functions in `spectra/plugins/spectra/scripts/common.sh`:
- `is_worktree()` - detect if in worktree context
- `get_main_repo_from_worktree()` - get main repo path
- `get_worktree_for_branch()` - find worktree by branch
- `check_worktree_context()` - warn if should navigate to worktree

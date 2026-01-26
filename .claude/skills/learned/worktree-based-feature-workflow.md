# Skill: Worktree-Based Feature Workflow

## When to Use
When working on features that use git worktrees for isolation, and the main repository contains configuration/scripts that aren't replicated in worktrees.

## Pattern

1. **Identify the worktree path**
   - Feature branches may be checked out in worktrees (e.g., `worktrees/001-feature-name/`)
   - The main repo can't checkout the same branch (`fatal: 'branch' is already checked out`)

2. **Access scripts from main repo**
   - Worktrees don't automatically have all directories from main (e.g., `.specify/`)
   - Use absolute paths to run scripts: `/path/to/main-repo/.specify/scripts/...`
   - Or `cd` to worktree and reference main repo scripts

3. **File operations in worktrees**
   - Specs and feature files belong in the worktree: `worktrees/001-feature/specs/...`
   - Session files and learned skills stay in main repo: `.specify/sessions/`, `.claude/skills/learned/`

4. **Running setup scripts**
   ```bash
   # From worktree directory, use absolute path to main repo script
   cd /path/to/worktrees/001-feature
   /path/to/main-repo/.specify/scripts/bash/setup-plan.sh --json
   ```

## Example

```bash
# Script in main repo, feature work in worktree
MAIN_REPO=/Users/dev/project
WORKTREE=/Users/dev/project/worktrees/001-feature

# Run setup from worktree using main repo script
cd $WORKTREE && $MAIN_REPO/.specify/scripts/bash/setup-plan.sh --json

# Create plan artifacts in worktree
# specs/001-feature/plan.md -> $WORKTREE/specs/001-feature/plan.md
```

## Key Insight
Keep a mental model of two workspaces: the main repo (configuration, scripts, session state) and the worktree (feature-specific code and specs). Use absolute paths when crossing between them.

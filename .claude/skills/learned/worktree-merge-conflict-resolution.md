# Resolving Worktree Merge Conflicts

## Pattern Summary

When merging a worktree branch back to main, symlinks used in the worktree may conflict with actual directories on main. Resolve by keeping the main version and committing the merge locally before pushing.

## When to Apply

- Merging a git worktree branch via GitHub API fails with "not mergeable"
- Error mentions "merge conflict between base and head"
- Worktree uses symlinks to parent repo directories (e.g., `specs -> ../../specs`)

## Common Conflict Types

### 1. Symlink vs Directory
```
CONFLICT (file/directory): directory in the way of specs from HEAD
```
- **Worktree**: `specs` is a symlink to `../../specs`
- **Main**: `specs` is an actual directory with contents
- **Resolution**: Keep the directory from main

### 2. Content Conflicts
```
CONFLICT (content): Merge conflict in .claude/settings.json
```
- Standard content conflict, resolve by editing file

## Resolution Steps

```bash
# 1. Fetch and attempt merge
git fetch origin main
git merge origin/main --no-commit

# 2. Check conflicts
git status --short
# Look for UU (both modified), AU (added by us), etc.

# 3. Resolve symlink conflicts - keep main's directory
git rm -f <file>~HEAD  # Remove the symlink version
git checkout origin/main -- <directory>  # Get directory from main

# 4. Resolve content conflicts - edit files
# Edit conflicted files, remove <<<< ==== >>>> markers

# 5. Stage and commit
git add -A
git commit -m "Merge main into <branch>"

# 6. Push and merge via API
git push origin <branch>
# Now GitHub API merge will work
```

## Example: specs Symlink Conflict

```bash
# Conflict shows:
# AU specs~HEAD  (symlink from worktree)
# D  specs       (deleted because it was symlink)
# A  specs/...   (directory contents from main)

# Resolution:
git rm -f specs~HEAD
git checkout origin/main -- specs
git add -A
git commit -m "Merge main - keep specs directory"
git push
```

## Why This Happens

Git worktrees often use symlinks to share directories with the parent repo:
```
worktrees/feature-branch/
├── specs -> ../../specs  # Symlink to parent
├── projspec/             # Actual feature work
└── .claude/              # Actual feature work
```

When main has actual content in `specs/`, the symlink conflicts because git sees two different things with the same name.

## Prevention

Consider whether worktree symlinks are necessary. If the main branch will have actual directories, avoid symlinking those paths in worktrees.

## Related Skills

- `tool-vs-product-in-renames.md` - Context for understanding project structure
- `parallel-pr-review-with-agents.md` - PR review before merge

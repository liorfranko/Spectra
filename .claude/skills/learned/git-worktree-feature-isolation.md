# Skill: Git Worktree Feature Isolation Pattern

**Learned**: 2026-01-26
**Context**: Designing ProjSpec's feature isolation strategy

## Pattern

Use git worktrees to provide complete filesystem isolation for each feature, enabling parallel work without branch switching or stashing.

### Directory Structure

```
project-root/                    # Main repo (typically on main branch)
├── .git/                        # Git database (shared by all worktrees)
├── .config/                     # Shared configuration directory
├── specs/                       # Shared specifications
└── worktrees/                   # Feature worktrees
    ├── 001-feature-a/           # Worktree for feature 001
    │   ├── .git                 # Worktree link file (not a directory)
    │   ├── specs -> ../../specs # Symlink to shared specs
    │   ├── .config -> ../../.config
    │   └── [source code]        # Feature-specific changes
    └── 002-feature-b/
        └── ...
```

### Key Commands

```bash
# Create worktree with new branch
git worktree add worktrees/001-feature -b 001-feature

# Create symlinks to shared directories
cd worktrees/001-feature
ln -s ../../specs specs
ln -s ../../.config .config

# List all worktrees
git worktree list

# Remove worktree (after merge)
git worktree remove worktrees/001-feature

# Prune stale worktrees
git worktree prune
```

### Symlink Strategy

Symlink shared directories into each worktree:
- Configuration files that apply to all features
- Specification/documentation directories
- Shared templates or assets

Keep in the worktree:
- Source code (feature-specific changes)
- Build artifacts (isolated per feature)
- Local configuration overrides

### Benefits

1. **Complete isolation**: Each feature has its own working directory
2. **Parallel work**: Work on multiple features simultaneously
3. **No stash juggling**: Never lose uncommitted work
4. **Clean context**: AI assistants see only one feature's changes
5. **Easy cleanup**: Remove worktree after merge

### Implementation Checklist

- [ ] Create worktree with feature branch
- [ ] Create symlinks to shared directories
- [ ] Initialize feature-specific state files
- [ ] Document worktree path in feature state
- [ ] On archive: merge, remove worktree, optionally delete branch

### Common Pitfalls

1. **Forgetting symlinks**: Worktree won't have access to shared config
2. **Absolute vs relative symlinks**: Use relative (`../../specs`) for portability
3. **Worktree in .gitignore**: Add `worktrees/` to prevent tracking worktree contents
4. **Branch deletion timing**: Delete branch only after worktree is removed

## When to Apply

- Multi-feature development workflows
- AI-assisted coding (limits context to relevant changes)
- Team workflows with parallel feature development
- Any project needing strong feature isolation

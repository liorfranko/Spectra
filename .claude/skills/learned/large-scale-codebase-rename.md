# Skill: Large-Scale Codebase Rename

## When to Use

Use this skill when renaming a product, package, or major component across an entire codebase. This applies when you need to:
- Rename a product (e.g., SpecKit → ProjSpec)
- Rename a package namespace
- Rebrand internal tooling
- Migrate from one naming convention to another

## Key Patterns

### 1. Order of Operations

Execute renames in this order to avoid broken references:

1. **Directory renames first** - Use `git mv` to preserve history
2. **File renames second** - All files renamed before content updates
3. **Configuration files third** - JSON/YAML configs (names, sources)
4. **Content updates fourth** - References within files
5. **Documentation last** - README, docs, comments

### 2. Reference Types to Check

Different reference types require different search patterns:

| Type | Example | Search Pattern |
|------|---------|----------------|
| Command references | `/speckit.plan` | `/oldname\.` |
| Agent references | `agent: speckit.plan` | `agent: oldname\.` |
| Path references | `speckit/commands/` | `oldname/` |
| JSON values | `"name": "speckit"` | `"oldname"` |
| Product names | `SpecKit provides...` | Case-sensitive search |

### 3. Validation Commands

Run these after completion to verify no references remain:

```bash
# Check for old filenames
find . -name "oldname*" -not -path "./.git/*"

# Check for old content references
grep -rc "oldname" src/ | grep -v ":0$"

# Check JSON config values
grep -r '"oldname"' **/*.json

# Case-insensitive full search
grep -ri "oldname" . --include="*.md" --include="*.json" --include="*.sh"
```

### 4. What to Preserve

Some references should NOT be renamed:

- **Historical feature/branch names**: `005-rename-speckit-projspec` is an identifier
- **Historical spec directories**: `specs/003-claude-plugin-speckit/` documents history
- **Session logs**: Historical session files document what was done
- **External references**: URLs, package names in dependencies

### 5. Case Convention Strategy

Define case conventions upfront:

| Context | Convention | Example |
|---------|------------|---------|
| Filenames | lowercase | `projspec.plan.md` |
| Directory names | lowercase | `projspec/` |
| Command names | lowercase | `/projspec.plan` |
| JSON values | lowercase | `"name": "projspec"` |
| Product name in docs | PascalCase | `ProjSpec provides...` |
| Titles | PascalCase | `# ProjSpec` |

### 6. Parallel Execution

Tasks that operate on different files can run in parallel:
- All file renames within a directory
- All content updates within different files
- All script comment updates

Tasks that must be sequential:
- Directory rename → File operations within
- Config updates → Content referencing config
- All renames → Validation checks

## Common Pitfalls

1. **Missing YAML frontmatter**: Agent references like `agent: oldname.xxx` are easy to miss

2. **Nested JSON properties**: A `plugins[0].name` is different from top-level `name`

3. **Example code in docs**: Documentation often has example paths like `"oldname/commands/implement.md"`

4. **Inconsistent casing**: Searching for `oldname` won't find `OldName`

5. **Symlinks**: Changes to symlinked directories may not appear in git status

## Verification Checklist

- [ ] `find . -name "oldname*"` returns empty
- [ ] `grep -rc "oldname" active-dirs/ | grep -v ":0$"` returns empty
- [ ] `grep -r '"oldname"' **/*.json` returns empty
- [ ] All commands execute without "not found" errors
- [ ] Git history preserved (check `git log --follow` on renamed files)

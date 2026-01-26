# Quickstart: Rename SpecKit to ProjSpec

**Feature Branch**: `005-rename-speckit-projspec`
**Created**: 2026-01-26

## Prerequisites

- Git installed and configured
- Access to repository root
- Claude Code CLI (for verification)

## Implementation Steps

### Step 1: Rename Directories

```bash
# Rename outer plugin directory
git mv speckit projspec

# Rename inner plugin directory
git mv projspec/plugins/speckit projspec/plugins/projspec
```

### Step 2: Rename Command Files

```bash
# Rename all .claude/commands/speckit.*.md to projspec.*.md
for file in .claude/commands/speckit.*.md; do
  newname="${file/speckit./projspec.}"
  git mv "$file" "$newname"
done
```

### Step 3: Update Plugin Configuration

Update `projspec/.claude-plugin/marketplace.json`:
- Change `"name": "speckit"` to `"name": "projspec"`
- Change `"source": "./plugins/speckit"` to `"source": "./plugins/projspec"`

Update `projspec/plugins/projspec/.claude-plugin/plugin.json`:
- Change `"name": "speckit"` to `"name": "projspec"`

### Step 4: Update Content References

```bash
# Update all /speckit. command references to /projspec.
# Run in projspec/ directory and .claude/commands/
find projspec .claude/commands -name "*.md" -exec sed -i '' 's|/speckit\.|/projspec.|g' {} \;

# Update script comment headers
find projspec/plugins/projspec/scripts -name "*.sh" -exec sed -i '' 's|# speckit/|# projspec/|g' {} \;

# Update README title and product name references
sed -i '' 's/# speckit/# projspec/g' projspec/README.md
sed -i '' 's/SpecKit/ProjSpec/g' projspec/README.md projspec/TESTING.md projspec/VERIFICATION.md
```

### Step 5: Update Project Metadata

Update `CLAUDE.md`:
- Change `speckit/` to `projspec/` in project structure section

## Verification

### Test 1: No speckit in command names
```bash
# Should return empty
find .claude/commands -name "speckit*"
```

### Test 2: No speckit in plugin configuration
```bash
# Should return empty
grep -r '"name": "speckit"' projspec/
```

### Test 3: No speckit in command references
```bash
# Should return empty (excluding specs/ historical directories)
grep -r '/speckit\.' projspec/ .claude/commands/
```

### Test 4: Commands execute successfully
```bash
# Each command should start without errors
/projspec.specify "test feature"
/projspec.plan
/projspec.tasks
```

## Rollback

If issues occur, revert the commit:
```bash
git reset --hard HEAD~1
```

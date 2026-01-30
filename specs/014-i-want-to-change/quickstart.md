# Quickstart: Rename Project to Spectra

Get the Spectra rename implemented in a systematic way.

## Prerequisites

Before you begin, ensure you have:

- [ ] Git installed and configured
- [ ] Access to the projspec repository
- [ ] Ability to push to the repository
- [ ] Access to GitHub repository settings (for repo rename)

## Implementation Steps

### Step 1: Rename Root Directory

```bash
# From repository root
git mv projspec spectra
```

### Step 2: Rename Nested Plugin Directory

```bash
git mv spectra/plugins/projspec spectra/plugins/spectra
```

### Step 3: Update plugin.json

Edit `spectra/plugins/spectra/.claude-plugin/plugin.json`:

```json
{
  "name": "spectra",
  "version": "2.0.0",
  "description": "Specification-driven development workflow automation"
}
```

### Step 4: Update All Command Files

For each file in `spectra/plugins/spectra/commands/`:

```bash
# Replace all occurrences of /projspec: with /spectra:
sed -i '' 's|/projspec:|/spectra:|g' spectra/plugins/spectra/commands/*.md

# Replace projspec with spectra in paths
sed -i '' 's|projspec|spectra|g' spectra/plugins/spectra/commands/*.md
```

### Step 5: Update Scripts

```bash
sed -i '' 's|projspec|spectra|g' spectra/plugins/spectra/scripts/*.sh
```

### Step 6: Update Templates

```bash
sed -i '' 's|projspec|spectra|g' spectra/plugins/spectra/templates/*.md
```

### Step 7: Update Agents

```bash
sed -i '' 's|projspec|spectra|g' spectra/plugins/spectra/agents/*.md
```

### Step 8: Update READMEs

Update branding in:
- `README.md` (root)
- `spectra/README.md`

Replace:
- "ProjSpec" → "Spectra"
- "projspec" → "spectra"
- `/projspec.` → `/spectra.`

### Step 9: Update CLAUDE.md

Update project description and paths in `CLAUDE.md`.

### Step 10: Verify No References Remain

```bash
# This should return no results
grep -ri "projspec" --include="*.md" --include="*.json" --include="*.sh" .
```

### Step 11: Commit Changes

```bash
git add -A
git commit -m "feat: Rename project from ProjSpec to Spectra

BREAKING CHANGE: All commands now use /spectra.* prefix instead of /projspec.*

- Rename projspec/ directory to spectra/
- Update plugin.json name to 'spectra'
- Update all command prefixes
- Update all internal references
- Update documentation branding
- Bump version to 2.0.0"
```

### Step 12: Rename GitHub Repository

1. Go to GitHub repository Settings
2. Under "General", find "Repository name"
3. Change from `projspec` to `spectra`
4. Confirm the rename

## Verification

After completing all steps, verify:

```bash
# 1. Check no old references remain
grep -ri "projspec" --include="*.md" --include="*.json" --include="*.sh" .

# 2. Check plugin.json has correct name
cat spectra/plugins/spectra/.claude-plugin/plugin.json

# 3. Test a command (after reinstalling plugin)
/spectra:specify test feature
```

## Next Steps

- **Generate Tasks**: Run `/projspec:tasks` to create detailed implementation tasks
- **Implement**: Run `/projspec:implement` to execute the rename
- **Test**: Verify all commands work with new prefix
- **Release**: Push changes and create a release

## Troubleshooting

### Issue: Commands not found after rename

**Solution**: Reinstall the plugin:
```bash
/plugin uninstall projspec
/plugin install spectra@path/to/spectra
```

### Issue: Old URLs still referenced

**Solution**: Update any hardcoded GitHub URLs in documentation:
- Badge URLs in README
- Clone URLs in documentation
- Link references

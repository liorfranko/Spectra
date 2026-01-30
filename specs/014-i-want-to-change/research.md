# Research: Rename Project from ProjSpec to Spectra

## Overview

This research documents the technical approach for renaming the ProjSpec project to Spectra. The rename involves directory restructuring, updating all internal references, and renaming the GitHub repository.

## Technical Unknowns

### 1. Scope of Name References

**Question**: Where does "projspec" appear in the codebase and what needs to be changed?

**Analysis**:

| Location | Type | Count | Action Required |
|----------|------|-------|-----------------|
| `projspec/` | Directory | 1 | Rename to `spectra/` |
| `projspec/plugins/projspec/` | Directory | 1 | Rename to `spectra/plugins/spectra/` |
| `plugin.json` | Config file | 1 | Update `name` field to "spectra" |
| `commands/*.md` | 12 files | Many | Update all `/projspec.*` references |
| `scripts/*.sh` | 5 files | Many | Update path and name references |
| `templates/*.md` | 4 files | Some | Update example references |
| `README.md` | Doc file | 2 | Update branding and examples |
| `CLAUDE.md` | Doc file | 1 | Update project description |
| `agents/*.md` | 6 files | Some | Update description references |

**Decision**: Systematic find-and-replace with manual verification for context-sensitive changes.

### 2. Directory Rename Strategy

**Question**: How to safely rename nested directories without breaking git history?

**Options Considered**:
1. `git mv` for each directory level
2. Direct rename with `mv` then `git add`
3. Create new structure, copy content, delete old

**Decision**: Use `git mv` for proper history tracking:
```bash
git mv projspec spectra
git mv spectra/plugins/projspec spectra/plugins/spectra
```

**Rationale**: Preserves git history and allows GitHub to track file renames.

### 3. GitHub Repository Rename

**Question**: What happens when the GitHub repo is renamed?

**Research Findings**:
- GitHub automatically creates redirects from old URL to new URL
- Existing clones continue to work (remote URL redirect)
- Forks are NOT automatically updated (may need to update remote)
- GitHub Pages URLs change immediately
- Badge URLs need updating

**Decision**: Rename repo via GitHub Settings → Repository name

**Trade-offs**:
- Pro: Complete brand consistency
- Con: Existing forks need to update remotes manually

### 4. Plugin Installation Path

**Question**: How does the plugin installation path work?

**Research**:
The Claude Code plugin system uses:
- Plugin name from `plugin.json` → `spectra`
- Installation creates: `~/.claude/plugins/cache/spectra/...`
- Commands registered as `/spectra.*`

**Decision**: Update `plugin.json` name field and all command prefixes.

## Key Findings

1. **12 command files** need prefix updates from `/projspec:` to `/spectra:`
2. **5 bash scripts** contain path references that need updating
3. **plugin.json** is the source of truth for the plugin name
4. **No external API dependencies** exist that would break
5. **Worktree workflow** uses branch names, not plugin names, so existing worktrees continue working

## Recommendations

1. **Atomic rename**: All changes should be committed together to avoid partial state
2. **Verification script**: Create a grep-based check to verify zero "projspec" occurrences post-rename
3. **Version bump**: Increment to 2.0.0 to indicate breaking change (new command prefix)
4. **Release notes**: Document the rename clearly for existing users

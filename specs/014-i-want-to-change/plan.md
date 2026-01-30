# Implementation Plan: Rename Project to Spectra

**Feature**: Rename Project from ProjSpec to Spectra
**Date**: 2026-01-30
**Status**: Ready for Implementation

---

## Technical Context

### Language & Runtime

| Aspect | Value |
|--------|-------|
| Primary Language | Markdown (commands), Bash (scripts) |
| Runtime/Version | Claude Code CLI, Bash 5.x |
| Package Manager | None (plugin system) |

### Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Claude Code CLI | Latest | Plugin host environment |
| Git | 2.x+ | Version control, worktree management |
| Bash | 5.x | Script execution |
| grep/sed | System | Text replacement |

### Platform & Environment

| Aspect | Value |
|--------|-------|
| Target Platform | Claude Code plugin |
| Minimum Requirements | Claude Code CLI, macOS/Linux |
| Environment Variables | CLAUDE_PLUGIN_ROOT (set by Claude) |

### Constraints

- Must work with Claude Code plugin system
- All renames must happen atomically in one commit
- Existing worktrees should continue functioning
- No deprecation period (clean break)

### Testing Approach

| Aspect | Value |
|--------|-------|
| Test Framework | Manual validation + grep verification |
| Test Location | Post-rename verification scripts |
| Required Coverage | All commands must execute |

**Test Types**:
- Unit: No (markdown/bash, not applicable)
- Integration: Yes (verify all commands work)
- E2E: Yes (full workflow test after rename)

---

## Constitution Check

**Constitution Source**: Default plugin constitution
**Check Date**: 2026-01-30

### Principle Compliance

| Principle | Description | Status | Notes |
|-----------|-------------|--------|-------|
| Atomic changes | Changes should be complete | PASS | All renames in one commit |
| Traceability | Maintain history | PASS | Using git mv for history |
| Documentation | Keep docs updated | PASS | READMEs updated as part of rename |

### Gate Status

**Constitution Check Result**: PASS

All principles satisfied. Proceeding with project structure.

---

## Project Structure

### Documentation Layout

```
specs/014-i-want-to-change/
├── spec.md              # Feature specification
├── research.md          # Technical research
├── data-model.md        # Entity definitions
├── plan.md              # This document
├── quickstart.md        # Implementation guide
└── tasks.md             # Task breakdown (to be generated)
```

### Source Code Layout (After Rename)

```
spectra/                          # Renamed from projspec/
├── plugins/
│   └── spectra/                  # Renamed from projspec/
│       ├── .claude-plugin/
│       │   └── plugin.json       # Updated name field
│       ├── commands/             # 12 command files to update
│       │   ├── accept.md
│       │   ├── analyze.md
│       │   ├── cancel.md
│       │   ├── clarify.md
│       │   ├── constitution.md
│       │   ├── implement.md
│       │   ├── issues.md
│       │   ├── merge.md
│       │   ├── plan.md
│       │   ├── review-pr.md
│       │   ├── specify.md
│       │   └── tasks.md
│       ├── agents/               # 6 agent files to update
│       ├── scripts/              # 5 scripts to update
│       ├── templates/            # 4 templates to update
│       ├── memory/
│       └── hooks/
└── README.md                     # Updated branding
```

### Files to Modify

| File/Directory | Action | Requirements Covered |
|----------------|--------|---------------------|
| `projspec/` → `spectra/` | Rename directory | FR-001 |
| `plugins/projspec/` → `plugins/spectra/` | Rename directory | FR-001 |
| `plugin.json` | Update name to "spectra" | FR-003 |
| `commands/*.md` (12 files) | Replace /projspec: with /spectra: | FR-002 |
| `scripts/*.sh` (5 files) | Update path references | FR-006 |
| `templates/*.md` (4 files) | Update example references | FR-006 |
| `agents/*.md` (6 files) | Update descriptions | FR-007 |
| `README.md` (root) | Update branding | FR-004 |
| `spectra/README.md` | Update branding | FR-004 |
| `CLAUDE.md` | Update project description | FR-005 |

### File-to-Requirement Mapping

| Planned Change | Primary Requirement(s) | Description |
|----------------|------------------------|-------------|
| Directory rename | FR-001 | Rename projspec/ to spectra/ |
| plugin.json update | FR-003 | Update plugin name |
| Command file updates | FR-002 | Update command prefixes |
| Script updates | FR-006 | Update internal references |
| README updates | FR-004 | Update documentation |
| CLAUDE.md update | FR-005 | Update project instructions |
| Agent updates | FR-007 | Update agent descriptions |
| GitHub repo rename | FR-008 | Rename repository |

---

## Implementation Phases

### Phase 1: Directory Rename
1. Use `git mv` to rename `projspec/` → `spectra/`
2. Use `git mv` to rename nested `plugins/projspec/` → `plugins/spectra/`
3. Verify git history is preserved

### Phase 2: Configuration Update
1. Update `plugin.json` name field to "spectra"
2. Update version to 2.0.0 (breaking change)

### Phase 3: Command Updates
1. Update all 12 command files
2. Replace `/projspec:` with `/spectra:` throughout
3. Replace `projspec` with `spectra` in paths

### Phase 4: Script Updates
1. Update path references in all bash scripts
2. Update variable names containing "projspec"

### Phase 5: Documentation Updates
1. Update root README.md
2. Update spectra/README.md
3. Update CLAUDE.md
4. Update template files

### Phase 6: Verification
1. Run grep to verify zero "projspec" occurrences
2. Test each command execution
3. Verify plugin loads correctly

### Phase 7: GitHub Repository Rename
1. Rename repository via GitHub Settings
2. Update any hardcoded GitHub URLs
3. Verify redirects work

---

## Verification Checklist

- [ ] `grep -ri "projspec" --include="*.md" --include="*.json" --include="*.sh"` returns empty
- [ ] `/spectra:specify` command executes
- [ ] `/spectra:plan` command executes
- [ ] `/spectra:tasks` command executes
- [ ] Plugin appears as "Spectra" in listings
- [ ] README displays "Spectra" branding
- [ ] GitHub repo accessible at new URL

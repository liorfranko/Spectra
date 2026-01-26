# Data Model: Rename SpecKit to ProjSpec

**Feature Branch**: `005-rename-speckit-projspec`
**Created**: 2026-01-26

## Entities

This feature does not introduce new entities. Instead, it defines the complete inventory of files requiring modification.

## File Inventory

### Category 1: Directory Renames

| Current Path | Target Path |
|--------------|-------------|
| `speckit/` | `projspec/` |
| `speckit/plugins/speckit/` | `projspec/plugins/projspec/` |

### Category 2: Command File Renames (13 files)

| Current Filename | Target Filename |
|------------------|-----------------|
| `.claude/commands/speckit.analyze.md` | `.claude/commands/projspec.analyze.md` |
| `.claude/commands/speckit.checklist.md` | `.claude/commands/projspec.checklist.md` |
| `.claude/commands/speckit.clarify.md` | `.claude/commands/projspec.clarify.md` |
| `.claude/commands/speckit.constitution.md` | `.claude/commands/projspec.constitution.md` |
| `.claude/commands/speckit.implement.md` | `.claude/commands/projspec.implement.md` |
| `.claude/commands/speckit.learn.md` | `.claude/commands/projspec.learn.md` |
| `.claude/commands/speckit.plan.md` | `.claude/commands/projspec.plan.md` |
| `.claude/commands/speckit.review-pr.md` | `.claude/commands/projspec.review-pr.md` |
| `.claude/commands/speckit.specify.md` | `.claude/commands/projspec.specify.md` |
| `.claude/commands/speckit.tasks.md` | `.claude/commands/projspec.tasks.md` |
| `.claude/commands/speckit.taskstoissues.md` | `.claude/commands/projspec.taskstoissues.md` |
| `.claude/commands/speckit.checkpoint.md` | `.claude/commands/projspec.checkpoint.md` |

### Category 3: Plugin Configuration Updates (2 files)

| File | Field | Current Value | Target Value |
|------|-------|---------------|--------------|
| `projspec/.claude-plugin/marketplace.json` | `name` | `"speckit"` | `"projspec"` |
| `projspec/.claude-plugin/marketplace.json` | `source` | `"./plugins/speckit"` | `"./plugins/projspec"` |
| `projspec/plugins/projspec/.claude-plugin/plugin.json` | `name` | `"speckit"` | `"projspec"` |

### Category 4: Content Updates - Templates (5 files)

| File | Update Required |
|------|-----------------|
| `projspec/plugins/projspec/templates/checklist-template.md` | `/speckit.*` → `/projspec.*` |
| `projspec/plugins/projspec/templates/plan-template.md` | `/speckit.*` → `/projspec.*` |
| `projspec/plugins/projspec/templates/spec-template.md` | `/speckit.*` → `/projspec.*` |
| `projspec/plugins/projspec/templates/tasks-template.md` | `/speckit.*` → `/projspec.*` |
| `projspec/plugins/projspec/templates/agent-file-template.md` | Review for speckit references |

### Category 5: Content Updates - Scripts (6 files)

| File | Update Required |
|------|-----------------|
| `projspec/plugins/projspec/scripts/common.sh` | Comment headers `# speckit/` → `# projspec/` |
| `projspec/plugins/projspec/scripts/setup-hooks.sh` | Comment headers |
| `projspec/plugins/projspec/scripts/setup-plan.sh` | Comment headers |
| `projspec/plugins/projspec/scripts/check-prerequisites.sh` | Comment headers |
| `projspec/plugins/projspec/scripts/update-agent-context.sh` | Comment headers |
| `projspec/plugins/projspec/scripts/create-new-feature.sh` | Comment headers |

### Category 6: Content Updates - Documentation (3 files)

| File | Update Required |
|------|-----------------|
| `projspec/README.md` | Title, all `/speckit.*` references, product name mentions |
| `projspec/TESTING.md` | All speckit references |
| `projspec/VERIFICATION.md` | All speckit references |

### Category 7: Content Updates - Plugin Commands (14 files)

All files in `projspec/plugins/projspec/commands/` need internal references updated from `/speckit.*` to `/projspec.*`.

### Category 8: Content Updates - Root Commands (13 files)

All files in `.claude/commands/projspec.*.md` (after rename) need internal references updated from `/speckit.*` to `/projspec.*`.

### Category 9: Project Metadata (1 file)

| File | Update Required |
|------|-----------------|
| `CLAUDE.md` | `speckit/` → `projspec/` in project structure |

## Validation Rules

1. **Zero speckit in command names**: `find .claude/commands -name "speckit*"` returns empty
2. **Zero speckit in plugin name**: `grep -r '"name": "speckit"' projspec/` returns empty
3. **Zero speckit in command references**: `grep -r '/speckit\.' projspec/ .claude/` returns empty (excluding historical specs)
4. **All commands functional**: Each `/projspec.*` command executes without error

## State Transitions

N/A—no stateful entities in this feature.

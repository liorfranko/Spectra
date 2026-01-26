# Rename Mapping Contract

**Feature Branch**: `005-rename-speckit-projspec`
**Created**: 2026-01-26

## Overview

This contract defines the complete mapping of all renames from "speckit" to "projspec". It serves as the authoritative reference for implementation and validation.

## String Replacement Rules

### Rule 1: Command Prefix
- **Pattern**: `/speckit.` → `/projspec.`
- **Scope**: All markdown files in `projspec/` and `.claude/commands/`
- **Example**: `/speckit.specify` → `/projspec.specify`

### Rule 2: Plugin Name (JSON)
- **Pattern**: `"name": "speckit"` → `"name": "projspec"`
- **Scope**: `marketplace.json`, `plugin.json`

### Rule 3: Plugin Source Path
- **Pattern**: `"./plugins/speckit"` → `"./plugins/projspec"`
- **Scope**: `marketplace.json`

### Rule 4: Script Comments
- **Pattern**: `# speckit/` → `# projspec/`
- **Scope**: All `.sh` files in `projspec/plugins/projspec/scripts/`

### Rule 5: README Title
- **Pattern**: `# speckit` → `# projspec`
- **Scope**: `projspec/README.md`

### Rule 6: Product Name (Title Case)
- **Pattern**: `SpecKit` → `ProjSpec`
- **Scope**: All documentation files (README.md, TESTING.md, VERIFICATION.md)

### Rule 7: Project Structure Reference
- **Pattern**: `speckit/` → `projspec/`
- **Scope**: `CLAUDE.md` project structure section

## File Rename Mapping

### Directory Renames
```
speckit/                    →  projspec/
speckit/plugins/speckit/    →  projspec/plugins/projspec/
```

### Command File Renames
```
.claude/commands/speckit.analyze.md       →  .claude/commands/projspec.analyze.md
.claude/commands/speckit.checklist.md     →  .claude/commands/projspec.checklist.md
.claude/commands/speckit.clarify.md       →  .claude/commands/projspec.clarify.md
.claude/commands/speckit.constitution.md  →  .claude/commands/projspec.constitution.md
.claude/commands/speckit.implement.md     →  .claude/commands/projspec.implement.md
.claude/commands/speckit.learn.md         →  .claude/commands/projspec.learn.md
.claude/commands/speckit.plan.md          →  .claude/commands/projspec.plan.md
.claude/commands/speckit.review-pr.md     →  .claude/commands/projspec.review-pr.md
.claude/commands/speckit.specify.md       →  .claude/commands/projspec.specify.md
.claude/commands/speckit.tasks.md         →  .claude/commands/projspec.tasks.md
.claude/commands/speckit.taskstoissues.md →  .claude/commands/projspec.taskstoissues.md
.claude/commands/speckit.checkpoint.md    →  .claude/commands/projspec.checkpoint.md
.claude/commands/speckit.validate.md      →  .claude/commands/projspec.validate.md
```

## Exclusions

The following paths are explicitly **excluded** from renaming:

1. **Historical spec directories**: `specs/003-claude-plugin-speckit/` and its contents
2. **Session files**: `.specify/sessions/*` (historical logs)
3. **Learned skills with historical context**: May retain references for accuracy

## Validation Queries

### Verify No Remaining "speckit" in Active Files

```bash
# Command files (should return 0 matches)
grep -rc "speckit" .claude/commands/ | grep -v ":0$"

# Plugin directory (should return 0 matches)
grep -rc "speckit" projspec/ | grep -v ":0$"

# Plugin config (should return 0 matches)
grep -r '"speckit"' projspec/.claude-plugin/ projspec/plugins/projspec/.claude-plugin/
```

### Verify All Commands Have projspec Prefix

```bash
# Should list 13 files all starting with "projspec."
ls -1 .claude/commands/projspec.*.md
```

### Verify Plugin Configuration Correct

```bash
# marketplace.json should show projspec
jq '.name, .source' projspec/.claude-plugin/marketplace.json

# plugin.json should show projspec
jq '.name' projspec/plugins/projspec/.claude-plugin/plugin.json
```

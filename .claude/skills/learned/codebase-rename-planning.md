# Skill: Codebase Rename Planning

**Learned**: 2026-01-26
**Context**: Feature 005-rename-speckit-projspec

## Pattern

When planning a large-scale rename/refactoring across a codebase, follow this systematic approach:

### 1. Comprehensive Inventory First

Before any planning, use an exploration agent to create a complete inventory:
- Directory paths containing the old name
- Files with the old name in their filename
- Configuration files with the old name as values
- Content references (command names, imports, comments)
- Documentation with product name mentions

### 2. Categorize Files by Update Type

Group files into categories for organized implementation:
- **Directory renames**: Must happen first
- **File renames**: Create new entry points
- **Config updates**: JSON/YAML value changes
- **Content updates**: String replacements in file contents
- **Documentation**: Human-readable text updates

### 3. Define Replacement Rules

Create explicit rules for each pattern:
```
Rule: Command Prefix
Pattern: /oldname. → /newname.
Scope: All markdown files in specific directories
```

### 4. Document Exclusions

Explicitly list what should NOT be renamed:
- Historical/archival directories
- Log files and session records
- External references that shouldn't change

### 5. Provide Validation Queries

Include commands to verify the rename is complete:
```bash
# Should return empty
grep -rc "oldname" target-dir/ | grep -v ":0$"
```

## When to Use

- Product/project rebranding
- Plugin/package name changes
- Namespace migrations
- Command prefix updates

## Key Insight

The implementation order matters: directories → files → content. This prevents broken references during the migration.

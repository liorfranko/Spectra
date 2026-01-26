# Research: Rename SpecKit to ProjSpec

**Feature Branch**: `005-rename-speckit-projspec`
**Created**: 2026-01-26

## Research Summary

This feature is a straightforward renaming/refactoring task with no technical unknowns requiring research. The codebase exploration yielded a complete inventory of all files and references.

## Decision Log

### Decision 1: Rename Strategy

**Decision**: Perform directory renames first, then file renames, then content updates.

**Rationale**: This order prevents broken references during the migration:
1. Directories must exist before files can be moved into them
2. File renames create the new command entry points
3. Content updates fix internal references

**Alternatives Considered**:
- Single atomic git mv operation: Not possible for content updates
- Content updates first: Would create broken references to non-existent files

### Decision 2: Historical Spec Directory Handling

**Decision**: Retain `specs/003-claude-plugin-speckit/` with original naming.

**Rationale**: Per spec assumption, historical spec directories document features as they were named at creation time. Renaming them would rewrite history and break any external references.

**Alternatives Considered**:
- Rename all historical references: Rejected to preserve historical accuracy

### Decision 3: Case Sensitivity for "ProjSpec" vs "projspec"

**Decision**: Use `projspec` (lowercase) for file names, directories, and command prefixes. Use "ProjSpec" (PascalCase) only in documentation titles and README headings.

**Rationale**: Follows existing convention where `speckit` (lowercase) was used in all technical artifacts while "SpecKit" appeared in human-readable docs.

**Alternatives Considered**:
- All lowercase everywhere: Less readable in documentation
- PascalCase everywhere: Would break command naming convention

## Dependencies & Integrations

### Claude Code Plugin System

**Pattern**: Plugins are discovered via `.claude-plugin/plugin.json` with a `name` field that determines the command prefix.

**Best Practice**: The plugin name in `plugin.json` directly maps to the slash command prefix (e.g., `"name": "projspec"` → `/projspec.*`).

### Git Rename Tracking

**Pattern**: Use `git mv` for renames to preserve history tracking.

**Best Practice**: Perform renames in small, logical commits to maintain bisectability.

## Open Items

None—all clarifications resolved during codebase exploration.

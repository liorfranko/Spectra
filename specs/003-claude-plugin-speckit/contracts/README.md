# Contracts: Not Applicable

**Feature**: Claude Code Spec Plugin (speckit)

## Why No API Contracts

The speckit plugin does not require traditional API contracts for the following reasons:

1. **No External APIs**: The plugin operates entirely within the Claude Code environment and does not expose HTTP endpoints, GraphQL schemas, or other network APIs.

2. **File-Based Interface**: All communication happens through markdown files. The "contract" is the file format specification documented in `data-model.md`.

3. **Claude Code Plugin Protocol**: The plugin follows the Claude Code plugin system's built-in protocols:
   - Commands are defined in markdown with YAML frontmatter
   - Agents are defined in markdown with YAML frontmatter
   - Hooks use JSON configuration

4. **No Inter-Service Communication**: The plugin does not communicate with external services (except optionally the GitHub CLI for issue creation).

## Alternative: File Format Specifications

Instead of API contracts, the speckit plugin defines file format contracts in `data-model.md`:

| File Type | Format | Schema Location |
|-----------|--------|-----------------|
| Commands | Markdown + YAML frontmatter | `data-model.md` - YAML Frontmatter section |
| Agents | Markdown + YAML frontmatter | `data-model.md` - YAML Frontmatter section |
| Hooks | JSON | `data-model.md` - JSON Hooks Configuration section |
| Specifications | Markdown | `templates/spec-template.md` |
| Plans | Markdown | `templates/plan-template.md` |
| Tasks | Markdown | `templates/tasks-template.md` |
| Session metadata | JSON | `data-model.md` - Session Metadata section |

## Validation

File format validation is handled by:
- Hook scripts that validate markdown structure
- Claude Code's built-in plugin validation
- Template-based generation that ensures correct structure

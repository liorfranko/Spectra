# Feature Specification: Rename SpecKit to ProjSpec

**Feature Branch**: `005-rename-speckit-projspec`
**Created**: 2026-01-26
**Status**: Draft
**Input**: User description: "I want to change the of commands and everything from speckit to projspec"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Use ProjSpec Commands (Priority: P1)

As a developer using the specification workflow, I want all commands to use the "projspec" prefix instead of "speckit" so that the tooling reflects the project's actual name and branding.

**Why this priority**: This is the core user-facing change that affects daily workflow. Users invoke commands frequently, and consistent naming improves discoverability and reduces confusion.

**Independent Test**: Can be fully tested by running `/projspec.specify`, `/projspec.plan`, `/projspec.tasks` and verifying all commands execute correctly with the new naming.

**Acceptance Scenarios**:

1. **Given** a user has the plugin installed, **When** they type `/projspec.specify "feature description"`, **Then** the specification workflow starts and creates appropriate files
2. **Given** a user has the plugin installed, **When** they type `/projspec.plan`, **Then** the planning workflow executes with the new command name
3. **Given** a user types an old command like `/speckit.specify`, **When** the command is executed, **Then** the system informs them the command no longer exists

---

### User Story 2 - Install and Configure Plugin (Priority: P2)

As a developer setting up the projspec workflow, I want the plugin to be named "projspec" in the configuration so that my IDE and tooling correctly identify it.

**Why this priority**: Plugin installation happens once per project, but the naming must be consistent for the plugin registry and discovery systems.

**Independent Test**: Can be fully tested by installing the plugin and verifying it appears as "projspec" in plugin listings and configuration files.

**Acceptance Scenarios**:

1. **Given** a new project, **When** the user installs the projspec plugin, **Then** the plugin.json shows name as "projspec"
2. **Given** the plugin is installed, **When** the user lists available plugins, **Then** the plugin appears as "projspec" not "speckit"

---

### User Story 3 - Reference Documentation and Files (Priority: P3)

As a developer reading documentation or exploring the codebase, I want all references to use "projspec" consistently so that there is no confusion about the product name.

**Why this priority**: Documentation accuracy is important for onboarding and support, but less critical than functional command usage.

**Independent Test**: Can be fully tested by searching the codebase for "speckit" and confirming zero occurrences in user-facing documentation.

**Acceptance Scenarios**:

1. **Given** the README files, **When** a user reads them, **Then** all product references say "projspec" or "ProjSpec"
2. **Given** help text or error messages, **When** displayed to the user, **Then** they reference "projspec" commands

---

### Edge Cases

- What happens when a user has existing sessions or files referencing "speckit"? Historical session files may retain old naming; only current/active files need updating.
- How does the system handle in-progress features that reference the old name? Internal spec references within 003-claude-plugin-speckit can retain historical naming as they document a past feature.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All slash commands MUST use the prefix `projspec.` instead of `speckit.` (e.g., `/projspec.specify`, `/projspec.plan`, `/projspec.tasks`)
- **FR-002**: The plugin.json MUST declare the plugin name as "projspec"
- **FR-003**: All command files MUST be renamed from `speckit.*.md` to `projspec.*.md`
- **FR-004**: Internal command references within markdown files MUST use the new `/projspec.*` naming
- **FR-005**: The plugin directory structure MUST be renamed from `speckit/plugins/speckit/` to `projspec/plugins/projspec/` (or equivalent unified structure)
- **FR-006**: README files and user-facing documentation MUST reference "projspec" or "ProjSpec"
- **FR-007**: Error messages and help text MUST use the new product name
- **FR-008**: The `.specify/templates/` references to speckit commands MUST be updated to projspec

### Key Entities

- **Plugin Configuration**: The plugin.json file that defines the plugin name and metadata
- **Slash Commands**: The markdown files in `.claude/commands/` that define available user commands
- **Plugin Commands**: The markdown files in the plugin's `commands/` directory
- **Templates**: The specification templates that reference command names in their instructions

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero occurrences of "speckit" in any command file names or command definitions
- **SC-002**: All user-invocable commands successfully execute with the `/projspec.*` prefix
- **SC-003**: Plugin appears with correct name "projspec" in any plugin listing or discovery mechanism
- **SC-004**: Users can complete the full specification workflow (/projspec.specify → /projspec.plan → /projspec.tasks → /projspec.implement) without encountering any "speckit" references

## Assumptions

- Historical spec directories (like `specs/003-claude-plugin-speckit/`) retain their existing names as they document a feature that was named at creation time
- Session files in `.specify/sessions/` may retain historical references as they are logs of past activity
- The core `.specify/` directory structure remains unchanged (only command naming within templates changes)
- Learned skills may retain historical context but any user-facing skill names should use projspec

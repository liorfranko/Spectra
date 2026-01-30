# Feature Specification: Rename Project from ProjSpec to Spectra

## Metadata

| Field | Value |
|-------|-------|
| Branch | `014-i-want-to-change` |
| Date | 2026-01-30 |
| Status | Draft |
| Input | Rename the project from "ProjSpec" to "Spectra" for better branding and marketability |

---

## User Scenarios & Testing

### Primary Scenarios

#### US-001: Developer installs plugin with new name

**As a** developer using Claude Code
**I want to** install the plugin using the new "Spectra" name
**So that** I can use the spec-driven development workflow with the rebranded tool

**Acceptance Criteria:**
- [ ] Plugin can be installed via `/plugin install spectra@claude-plugin-directory`
- [ ] All commands use the `/spectra.*` prefix (e.g., `/spectra.specify`, `/spectra.plan`)
- [ ] Plugin appears as "Spectra" in plugin listings
- [ ] Installation documentation reflects the new name

**Priority:** High

#### US-002: Existing user transitions to new name

**As an** existing ProjSpec user
**I want to** understand the transition from ProjSpec to Spectra
**So that** I can update my workflows and continue using the tool without confusion

**Acceptance Criteria:**
- [ ] README clearly communicates the rebranding
- [ ] All internal references are updated consistently
- [ ] No broken links or references to old name remain in user-facing documentation

**Priority:** High

#### US-003: Developer discovers the project

**As a** developer browsing GitHub
**I want to** find and understand what Spectra does
**So that** I can decide if it fits my spec-driven development needs

**Acceptance Criteria:**
- [ ] Repository name reflects "Spectra" branding
- [ ] README prominently displays the Spectra name and value proposition
- [ ] Project description uses the new name consistently

**Priority:** Medium

### Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| Old `/projspec.*` commands used | Commands do not exist (clean break); user must use `/spectra.*` |
| Mixed references in existing worktrees | Existing worktrees continue to work; new worktrees use new naming |
| External links to old repo name | GitHub automatically redirects `projspec` → `spectra` |
| Old plugin version installed | User can keep old version; new version requires uninstall/reinstall |

---

## Requirements

### Functional Requirements

#### FR-001: Rename plugin directory structure

The plugin directory must be renamed from `projspec/` to `spectra/` throughout the repository structure.

**Verification:** Directory structure inspection shows `spectra/plugins/spectra/` instead of `projspec/plugins/projspec/`

#### FR-002: Update all command prefixes

All slash commands must use the `/spectra.*` prefix instead of `/projspec.*`.

**Verification:** Running `/spectra.specify`, `/spectra.plan`, `/spectra.tasks`, etc. works correctly; old commands do not exist

#### FR-003: Update plugin.json metadata

The plugin.json file must reflect the new "Spectra" name, description, and any related metadata.

**Verification:** Plugin manifest shows "Spectra" as the plugin name and uses `spectra` as the identifier

#### FR-004: Update README documentation

Both README files must be updated to use "Spectra" branding consistently throughout.

**Verification:** Search for "projspec" (case-insensitive) in README files returns zero results; "Spectra" is used consistently

#### FR-005: Update CLAUDE.md project instructions

The CLAUDE.md file must reflect the new project name and any updated paths or conventions.

**Verification:** CLAUDE.md references "Spectra" and updated directory paths

#### FR-006: Update internal script references

All bash scripts, templates, and internal references must use the new naming.

**Verification:** Grep for "projspec" in scripts/ and templates/ directories returns zero results

#### FR-007: Update skill and agent descriptions

All skill descriptions in the system that reference "projspec" must be updated to "spectra".

**Verification:** Skill invocations use `/spectra.*` format; agent descriptions reference Spectra

#### FR-008: Rename GitHub repository

The GitHub repository must be renamed from `projspec` to `spectra` for complete brand consistency.

**Verification:** Repository is accessible at `github.com/liorfranko/spectra`; old URL redirects automatically

### Constraints

| Constraint | Description |
|------------|-------------|
| Backward Compatibility | Existing worktrees created with old naming should remain functional |
| Single Rename | All renames must happen atomically in one release to avoid partial states |

---

## Key Entities

### Plugin

**Description:** The Claude Code plugin package that provides spec-driven development capabilities

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| name | Display name of the plugin | Must be "Spectra" |
| identifier | Technical identifier used in commands | Must be "spectra" |
| directory | Root directory of the plugin | Must be "spectra/" |

### Command

**Description:** A slash command provided by the plugin

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| prefix | The command namespace prefix | Must be "spectra" (e.g., `/spectra.specify`) |
| name | The specific command name | Unchanged (specify, plan, tasks, etc.) |

### Entity Relationships

- Plugin contains multiple Commands
- Commands reference Plugin identifier in their prefix

---

## Success Criteria

### SC-001: Complete name replacement

**Measure:** Occurrences of "projspec" in codebase
**Target:** 0 occurrences (case-insensitive) in all user-facing files
**Verification Method:** Run `grep -ri "projspec" --include="*.md" --include="*.json" --include="*.sh"` and verify empty result

### SC-002: All commands functional

**Measure:** Command execution success rate
**Target:** 100% of `/spectra.*` commands execute without name-related errors
**Verification Method:** Run each command and verify it works: specify, clarify, plan, tasks, implement, review-pr, accept, merge, cancel, analyze, constitution, issues

### SC-003: Documentation consistency

**Measure:** Brand name consistency in documentation
**Target:** "Spectra" appears in all key locations (title, description, examples)
**Verification Method:** Manual review of README.md and projspec/README.md confirms consistent branding

---

## Assumptions

| ID | Assumption | Impact if Wrong | Validated |
|----|------------|-----------------|-----------|
| A-001 | No external systems depend on the "projspec" name | Would break external integrations | No |
| A-002 | GitHub repository can be renamed without breaking forks | Could break fork relationships | No |
| A-003 | Users are willing to update their workflows to new command names | User friction during transition | No |

---

## Open Questions

| ID | Question | Owner | Status |
|----|----------|-------|--------|
| Q-001 | Should the GitHub repository be renamed from `projspec` to `spectra`? | User | Resolved: Yes, rename repo for full rebrand with auto-redirect |
| Q-002 | Should there be a deprecation period with both `/projspec.*` and `/spectra.*` commands? | User | Resolved: No, clean break - only `/spectra.*` commands will work |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-01-30 | Claude (projspec) | Initial draft |
| 0.2 | 2026-01-30 | Claude (projspec/clarify) | Resolved Q-001 (rename repo: yes) and Q-002 (deprecation: no) |

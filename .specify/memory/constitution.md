<!--
Sync Impact Report:
- Version change: [No previous version] → 1.0.0
- Modified principles: N/A (initial version)
- Added sections: All core principles and governance sections
- Removed sections: N/A
- Templates requiring updates:
  ✅ plan-template.md (reviewed - Constitution Check section already present)
  ✅ spec-template.md (reviewed - aligns with user story requirements)
  ✅ tasks-template.md (reviewed - aligns with test-first and user story principles)
  ✅ commands/*.md (reviewed - no agent-specific references found, templates in .claude/commands/)
- Follow-up TODOs: None
-->

# projspec Constitution

## Core Principles

### I. Feature Specification First
Every feature begins with a clear, testable specification before any implementation planning or development.

**Rules:**
- Feature specifications MUST be written using the spec-template.md
- Each specification MUST include user stories with acceptance criteria in Given/When/Then format
- User stories MUST be prioritized (P1, P2, P3, etc.) and independently testable
- Specifications MUST define functional requirements (FR-XXX) and success criteria (SC-XXX)
- Specifications MUST clarify ambiguities using [NEEDS CLARIFICATION: ...] markers
- Edge cases and boundary conditions MUST be documented

**Rationale:** Clear specifications prevent wasted effort, ensure alignment between stakeholders and implementers, and provide a foundation for test-driven development.

### II. Design Before Implementation
Technical planning follows specification and precedes implementation.

**Rules:**
- Implementation plans MUST be created using the plan-template.md
- Plans MUST include technical context (language, dependencies, platform, testing framework)
- Plans MUST pass Constitution Check gates before proceeding
- Plans MUST define project structure and justify structural decisions
- Plans MUST document complexity and justify any violations of simplicity principles
- Research artifacts (research.md, data-model.md, contracts/) MUST be created as needed

**Rationale:** Thoughtful design reduces rework, identifies issues early, and ensures consistent architecture across features.

### III. Task Decomposition
Implementation is broken into discrete, traceable tasks organized by user story.

**Rules:**
- Tasks MUST be generated using the tasks-template.md
- Tasks MUST be grouped by user story to enable independent delivery
- Each task MUST include exact file paths
- Tasks that can run in parallel MUST be marked [P]
- Tasks MUST reference their user story with [USX] tags
- Dependencies between tasks MUST be explicitly documented
- Foundational tasks MUST be separated from user story tasks

**Rationale:** Task decomposition enables parallel development, incremental delivery, progress tracking, and clear assignment of work.

### IV. Test-First Development (CONDITIONAL)
When tests are required by the specification, they MUST be written before implementation.

**Rules:**
- Tests are OPTIONAL unless explicitly requested in the feature specification
- When tests are included, they MUST be written first and MUST fail before implementation
- Test tasks MUST appear before implementation tasks in tasks.md
- Tests MUST verify user story acceptance criteria
- Contract tests MUST be created for API boundaries and shared interfaces
- Integration tests MUST cover inter-component communication

**Rationale:** Test-first development catches defects early, ensures requirements are testable, and provides living documentation of expected behavior.

### V. Independent User Stories
Each user story represents a standalone slice of functionality that can be implemented, tested, and deployed independently.

**Rules:**
- User stories MUST be implementable in isolation after foundational phase completes
- User stories MUST be testable independently
- User stories MUST deliver incremental value
- User stories MUST follow priority order (P1 is MVP, P2+ are enhancements)
- Cross-story dependencies SHOULD be minimized; when necessary, document explicitly

**Rationale:** Independent user stories enable incremental delivery, parallel development, flexible prioritization, and early value delivery.

### VI. Documentation as Artifact
All design decisions, specifications, and implementation plans are preserved as versioned artifacts.

**Rules:**
- All feature artifacts MUST reside in specs/NNN-feature-name/ directory
- Artifact naming MUST follow conventions: spec.md, plan.md, tasks.md, research.md, etc.
- Artifacts MUST use standardized templates from .specify/templates/
- Session notes MUST be stored in .specify/sessions/ with ISO 8601 timestamp prefixes
- The constitution (this file) and context.md MUST be maintained in .specify/memory/

**Rationale:** Documented artifacts provide historical context, enable knowledge transfer, support auditing, and facilitate onboarding.

### VII. Simplicity and YAGNI
Favor simple, direct solutions over complex abstractions until complexity is justified.

**Rules:**
- Avoid premature abstraction and over-engineering
- Implement only what is specified; do not add unrequested features
- Complexity violations MUST be documented in the Complexity Tracking table
- Each complexity violation MUST justify why simpler alternatives were rejected
- Default to straightforward implementations unless requirements demand otherwise

**Rationale:** Simplicity reduces cognitive load, minimizes bugs, accelerates development, and keeps maintenance costs low.

## Development Workflow

### Feature Lifecycle
1. **Specification Phase**: Use `/projspec.specify` to create spec.md with user stories and requirements
2. **Clarification Phase** (optional): Use `/projspec.clarify` to resolve ambiguities in the specification
3. **Planning Phase**: Use `/projspec.plan` to create plan.md, research.md, data-model.md, and contracts/
4. **Task Generation**: Use `/projspec.tasks` to create tasks.md organized by user story
5. **Implementation Phase**: Use `/projspec.implement` to execute tasks in dependency order
6. **Validation Phase**: Use `/projspec.validate` to verify deliverables match specifications
7. **Analysis Phase** (optional): Use `/projspec.analyze` for cross-artifact consistency checks

### Branch and Numbering
- Each feature MUST have a unique sequential number (NNN format)
- Feature branches MUST use format: `NNN-short-feature-name`
- Feature directories MUST use format: `specs/NNN-feature-name/`
- The `.specify/scripts/bash/create-new-feature.sh` script MUST be used to ensure unique numbering

### Quality Gates
- **Pre-Planning Gate**: Specification must be approved before planning begins
- **Constitution Check Gate**: All plans must pass constitution compliance before proceeding
- **Pre-Implementation Gate**: Tasks must be reviewed and approved before implementation
- **Delivery Gate**: Implementation must pass validation before merging

## Governance

### Amendment Process
- Constitution changes MUST be versioned using semantic versioning (MAJOR.MINOR.PATCH)
- MAJOR version increments: Backward-incompatible governance or principle removal/redefinition
- MINOR version increments: New principle/section or material expansion of guidance
- PATCH version increments: Clarifications, wording fixes, non-semantic refinements
- All amendments MUST update the Sync Impact Report comment at the top of this file
- All amendments MUST update LAST_AMENDED_DATE to current date
- Template files MUST be reviewed and updated when constitution principles change

### Compliance and Review
- All PRs and reviews MUST verify compliance with this constitution
- Complexity violations MUST be explicitly justified in the Complexity Tracking table
- Constitution violations without justification MUST be rejected
- This constitution supersedes all other practices and guidelines

### Version History
- Changes to this constitution MUST be tracked in git history
- The Sync Impact Report MUST document all changes in each version
- Breaking changes MUST be communicated to all team members

**Version**: 1.0.0 | **Ratified**: 2026-01-27 | **Last Amended**: 2026-01-27

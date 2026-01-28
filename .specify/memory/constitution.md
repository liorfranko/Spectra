# speckit Constitution

<!--
Sync Impact Report - Version 1.0.0 Initial Ratification
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Version Change: NONE → 1.0.0 (Initial constitution)
Modified Principles: N/A (initial creation)
Added Sections:
  - Core Principles (5 principles)
  - Development Workflow
  - Quality Standards
  - Governance
Templates Requiring Updates:
  ✅ .specify/templates/plan-template.md - Constitution Check section already aligned
  ✅ .specify/templates/spec-template.md - Implementation independence enforced
  ✅ .specify/templates/tasks-template.md - User story independence reflected
Follow-up TODOs: None
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-->

## Core Principles

### I. Specification-First Development

Every feature MUST begin with a specification written in implementation-agnostic language. Specifications define user scenarios, functional requirements, and success criteria without prescribing technical solutions. No implementation work begins until the specification is approved and clear.

**Rationale:** Separating "what" from "how" ensures requirements are fully understood before costly implementation begins. Implementation-agnostic specs enable technology changes without rewriting requirements.

### II. User Story Independence

Each user story MUST be independently testable and deliverable. User stories are prioritized (P1, P2, P3...) and can be implemented, tested, and deployed without requiring other stories to be complete. Each story delivers standalone user value.

**Rationale:** Independent stories enable incremental delivery, parallel development, and flexible prioritization. Users receive value sooner, and teams can adapt to changing priorities without rework.

### III. Test-First for Critical Paths (When Tests Required)

When tests are explicitly required in specifications, they MUST be written before implementation and MUST fail initially. Tests define acceptance criteria. The Red-Green-Refactor cycle is strictly enforced: write test → verify failure → implement → verify pass → refactor.

**Rationale:** Test-first development ensures testable design, prevents scope creep, and provides living documentation. Failing tests prove they are testing real behavior.

### IV. Constitution Compliance Gates

All implementation plans MUST include a Constitution Check section that validates compliance with project principles. Violations MUST be explicitly justified with documented rationale and rejected alternatives in a Complexity Tracking table. Unjustified complexity is prohibited.

**Rationale:** Explicit compliance verification prevents architectural drift and accumulation of unjustified complexity. Forced justification surfaces better alternatives.

### V. Traceability and Documentation

All artifacts (spec.md, plan.md, tasks.md) MUST maintain bidirectional traceability. Requirements trace to tasks, tasks trace to user stories, implementations reference specifications. Documentation lives alongside code in version control and updates synchronously.

**Rationale:** Traceability enables impact analysis, audit trails, and onboarding. Co-located documentation stays current through code review processes.

## Development Workflow

The standard development workflow follows these mandatory phases:

1. **Specification** (`/speckit.specify`) - Define user scenarios and requirements in implementation-agnostic language
2. **Clarification** (`/speckit.clarify`) - Optional: Resolve ambiguities through targeted questions
3. **Planning** (`/speckit.plan`) - Generate implementation plan with constitution compliance check
4. **Task Generation** (`/speckit.tasks`) - Break down plan into dependency-ordered, user-story-grouped tasks
5. **Implementation** (`/speckit.implement`) - Execute tasks in dependency order with status tracking
6. **Review** (`/speckit.review-pr`) - Comprehensive quality review before PR creation

Skipping phases is prohibited except when explicitly justified and documented.

**Rationale:** Standardized workflow ensures consistency, enables automation, and creates audit trails. Each phase has specific outputs that feed subsequent phases.

## Quality Standards

### Artifact Completeness

- **spec.md** MUST include: user scenarios with priorities, functional requirements, success criteria, edge cases
- **plan.md** MUST include: technical context, constitution check, project structure, complexity justification if needed
- **tasks.md** MUST include: user story grouping, dependency markers, parallel task markers, exact file paths

### Implementation Independence

Specifications and success criteria MUST NOT reference specific technologies, frameworks, libraries, or implementation patterns. Technology decisions belong in plan.md, not spec.md.

**Rationale:** Implementation-agnostic specs survive technology changes and enable objective requirement validation.

### Validation Requirements

- All artifacts MUST pass `/speckit.validate` checks before proceeding to next phase
- Cross-artifact consistency MUST be verified via `/speckit.analyze` after task generation
- All requirements MUST be traceable to user scenarios
- All tasks MUST be traceable to requirements or technical constraints

## Governance

### Amendment Procedure

Constitution changes require:

1. Documented rationale for the change
2. Impact analysis on existing templates and workflows
3. Version increment following semantic versioning:
   - MAJOR: Principle removal or backward-incompatible governance changes
   - MINOR: New principles or materially expanded guidance
   - PATCH: Clarifications, wording improvements, non-semantic refinements
4. Synchronization of all dependent templates and documentation
5. Migration plan for features in progress if principles change

### Versioning Policy

Constitution versions follow MAJOR.MINOR.PATCH format. All changes MUST update the version line and Last Amended date. The Sync Impact Report MUST document all changes and affected templates.

### Compliance Review

- All PRs MUST verify compliance with current constitution version
- Constitution violations found in review MUST be addressed or explicitly justified
- The constitution supersedes all other practices and conventions
- Runtime development guidance (CLAUDE.md, README.md) MUST reference constitution for foundational rules

**Version**: 1.0.0 | **Ratified**: 2026-01-26 | **Last Amended**: 2026-01-26

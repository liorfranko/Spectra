# Project Constitution

> Foundational principles and constraints governing all development decisions.

**Version:** 1.0.0
**Effective Date:** 2026-01-30
**Last Amended:** 2026-01-30

---

## Core Principles

### I. User-Centric Design

All features must prioritize user experience and accessibility. Commands should be intuitive and provide clear feedback.

### II. Maintainability First

Code should be written for humans to read and maintain. Prefer clarity over cleverness.

### III. Incremental Delivery

Deliver working features in small, testable increments. Each increment should be usable.

### IV. Documentation as Code

Documentation is a first-class deliverable. Commands and workflows must be well-documented.

### V. Spec-Driven Development

Features must be specified before implementation. Specs serve as the source of truth for requirements.

---

## Constraints

### Technology Constraints

- **Runtime:** Bash 5.x or higher required
- **Compatibility:** Scripts must be POSIX-compatible where possible
- **Dependencies:** Git is a required dependency
- **Platform:** Must operate within Claude Code plugin system

### Compliance Constraints

- **Security:** No hardcoded credentials in any files
- **Validation:** Input validation required on all user inputs
- **Licensing:** Only MIT-compatible dependencies allowed

### Policy Constraints

- **Review:** Self-review required before merge
- **Commits:** Commit messages follow conventional commits format
- **Versioning:** Semantic versioning for releases

---

## Development Workflow

### Required Processes

1. **Specification:** Features must be specified before implementation (`/spectra:specify`)
2. **Planning:** Implementation plans must be reviewed for constitution compliance (`/spectra:plan`)
3. **Review:** Code changes require self-review using specialized agents (`/spectra:review-pr`)
4. **Documentation:** User-facing changes require documentation updates

### Quality Gates

- [ ] Lint checks pass
- [ ] Documentation updated
- [ ] Constitution compliance verified

---

## Governance

### Amendment Process

As a solo developer project, the author can amend the constitution freely with proper documentation. All amendments must be recorded in the version history with clear rationale.

### Override Rules

- Violations require explicit justification in the plan
- Emergency overrides must be documented and reviewed post-implementation
- No override is permanent; violations must be remediated or constitution amended

### Principle Hierarchy

In case of conflict between principles:

1. Security and compliance constraints take precedence
2. User-centric design overrides technical preferences
3. Maintainability overrides performance unless SLA-bound

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2026-01-30 | Initial constitution established | Claude (spectra) |

---

*This constitution is checked during `/spectra:plan` execution. Violations must be justified in the Complexity Tracking section of the plan.*

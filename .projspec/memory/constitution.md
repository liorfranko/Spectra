# Project Constitution

> Foundational principles and constraints governing all development decisions.

**Version:** 1.0.0
**Effective Date:** 2026-01-27
**Last Amended:** 2026-01-27

---

## Core Principles

### I. User-Centric Design

All features and implementations must prioritize user experience and accessibility. Technical elegance should never come at the expense of usability.

### II. Maintainability First

Code should be written for humans to read and maintain. Favor clarity over cleverness, and explicit over implicit behavior.

### III. Incremental Delivery

Deliver working software in small, testable increments. Large changes should be decomposed into reviewable units.

### IV. Documentation as Code

Documentation is a first-class deliverable. Undocumented features are incomplete features.

### V. Test-Driven Confidence

New functionality requires accompanying tests. Untested code is considered technical debt.

---

## Constraints

### Technology Constraints

- **Plugin Ecosystem:** Must be compatible with Claude Code plugin system and conventions
- **Markdown-Based:** Commands, skills, and agents defined in Markdown format
- **Shell Scripts:** Supporting scripts use Bash 5.x conventions

### Compliance Constraints

- **No Hardcoded Secrets:** Never store credentials, API keys, or tokens in code or configuration files

### Policy Constraints

- **Semantic Versioning:** Follow semver (MAJOR.MINOR.PATCH) for all releases
- **Changelog Required:** Maintain changelog with all notable changes per release
- **Self-Review:** Review own code before committing to catch obvious issues

---

## Development Workflow

### Required Processes

1. **Specification:** Features must be specified before implementation
2. **Planning:** Implementation plans must be reviewed for constitution compliance
3. **Review:** Self-review before commit; peer review when available
4. **Testing:** Automated tests must pass before merge
5. **Documentation:** User-facing changes require documentation updates

### Quality Gates

- [ ] Lint checks pass
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Documentation updated
- [ ] Constitution compliance verified

---

## Governance

### Amendment Process

As a solo developer project:
1. **Proposal:** Document the proposed change with rationale
2. **Self-Review:** Allow time to reconsider the change
3. **Documentation:** Amendments must be versioned and dated in the Version History

### Override Rules

- Constitution violations require explicit justification in the Complexity Tracking section
- Emergency overrides must be documented and reviewed post-implementation
- No override is permanent; violations must be remediated or the constitution amended

### Principle Hierarchy

In case of conflict between principles:
1. Security and compliance constraints take precedence
2. User-centric design overrides technical preferences
3. Maintainability overrides performance unless SLA-bound

---

## Version History

| Version | Date       | Changes                          | Author                |
|---------|------------|----------------------------------|-----------------------|
| 1.0.0   | 2026-01-27 | Initial constitution established | Claude (projspec)     |

---

*This constitution is checked during `/projspec.plan` execution. Violations must be justified in the Complexity Tracking section of the plan.*

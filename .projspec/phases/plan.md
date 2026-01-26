# Planning Phase Template

This template guides the creation of an implementation plan based on the completed specification. Reference the spec.md document to ensure alignment with requirements while planning the technical approach.

---

## Summary

<!-- Provide a brief overview of what will be built. This should be understandable by both technical and non-technical stakeholders. -->

**Project Name**: [Name from specification]

**Overview**: [2-3 sentences describing what will be built and its primary purpose]

**Key Deliverables**:
- [Primary deliverable]
- [Secondary deliverable]
- [Additional deliverable]

---

## Technical Context

<!-- Define the technical foundation: languages, frameworks, tools, and any constraints that shape the implementation. -->

### Technology Stack

| Category | Choice | Rationale |
|----------|--------|-----------|
| Language | [e.g., Python 3.11+] | [Why this choice] |
| Framework | [e.g., FastAPI, React] | [Why this choice] |
| Database | [e.g., PostgreSQL, SQLite] | [Why this choice] |
| Testing | [e.g., pytest, Jest] | [Why this choice] |

### Dependencies

```
# Key external dependencies
[dependency-name]==x.y.z    # [purpose]
[dependency-name]==x.y.z    # [purpose]
```

### Development Tools

- **Build System**: [e.g., setuptools, npm, cargo]
- **Code Quality**: [e.g., ruff, eslint, prettier]
- **CI/CD**: [e.g., GitHub Actions, none for MVP]

### Constraints

- [Technical constraint from spec, e.g., "Must run on Python 3.10+"]
- [Integration constraint, e.g., "Must work with existing API"]
- [Performance constraint, e.g., "Response time under 200ms"]

---

## Project Structure

<!-- Define the file and directory layout. Use a tree structure to show organization. -->

```
project-root/
├── src/
│   └── [package_name]/
│       ├── __init__.py
│       ├── [module].py           # [Purpose]
│       ├── [module].py           # [Purpose]
│       └── [subpackage]/
│           ├── __init__.py
│           └── [module].py       # [Purpose]
├── tests/
│   ├── __init__.py
│   ├── test_[module].py
│   └── conftest.py               # Shared fixtures
├── [config files]                # pyproject.toml, package.json, etc.
└── README.md
```

### Key Files Description

| File/Directory | Purpose |
|----------------|---------|
| `src/[package]/` | [Main package description] |
| `src/[package]/[key_module].py` | [What this module does] |
| `tests/` | [Testing approach] |

---

## Component Architecture

<!-- Describe how the pieces fit together. Include relationships between components. -->

### Component Overview

```
┌─────────────────┐     ┌─────────────────┐
│   [Component]   │────▶│   [Component]   │
└─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│   [Component]   │
└─────────────────┘
```

### Component Descriptions

| Component | Responsibility | Dependencies |
|-----------|---------------|--------------|
| [Component Name] | [What it does] | [What it depends on] |
| [Component Name] | [What it does] | [What it depends on] |
| [Component Name] | [What it does] | [What it depends on] |

### Data Flow

1. [Entry point or trigger]
2. [Processing step]
3. [Output or result]

### Interfaces

<!-- Define key interfaces between components -->

```python
# Example interface definition
class [InterfaceName]:
    def [method_name](self, [params]) -> [return_type]:
        """[What this method does]"""
        ...
```

---

## Build Order

<!-- Define the sequence of implementation. Tasks should be atomic and testable. -->

### Phase 1: Foundation

| Task | Description | Depends On | Estimated Effort |
|------|-------------|------------|------------------|
| T001 | [Setup project structure and configuration] | - | [S/M/L] |
| T002 | [Implement core data models] | T001 | [S/M/L] |
| T003 | [Create base utilities] | T001 | [S/M/L] |

### Phase 2: Core Implementation

| Task | Description | Depends On | Estimated Effort |
|------|-------------|------------|------------------|
| T004 | [Implement primary feature] | T002, T003 | [S/M/L] |
| T005 | [Implement secondary feature] | T004 | [S/M/L] |

### Phase 3: Integration

| Task | Description | Depends On | Estimated Effort |
|------|-------------|------------|------------------|
| T006 | [Connect components] | T005 | [S/M/L] |
| T007 | [Add CLI/API layer] | T006 | [S/M/L] |

### Phase 4: Polish

| Task | Description | Depends On | Estimated Effort |
|------|-------------|------------|------------------|
| T008 | [Error handling and edge cases] | T007 | [S/M/L] |
| T009 | [Documentation and examples] | T008 | [S/M/L] |

### Dependency Graph

```
T001 ─┬─▶ T002 ─┬─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009
      │         │
      └─▶ T003 ─┘
```

---

## Risk Assessment

<!-- Identify potential issues and how they will be addressed -->

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk description] | Low/Medium/High | Low/Medium/High | [How to prevent or address] |
| [Risk description] | Low/Medium/High | Low/Medium/High | [How to prevent or address] |

### Scope Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Scope creep area] | Low/Medium/High | Low/Medium/High | [How to manage] |

### External Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [External dependency issue] | Low/Medium/High | Low/Medium/High | [Contingency plan] |

### Unknowns

- [Area requiring investigation or spike]
- [Decision to be made during implementation]

---

## Testing Strategy

<!-- Define how the implementation will be tested -->

### Testing Levels

| Level | Scope | Tools | Coverage Target |
|-------|-------|-------|-----------------|
| Unit | Individual functions/methods | [e.g., pytest] | [e.g., 80%+] |
| Integration | Component interactions | [e.g., pytest] | [Key paths] |
| End-to-End | Full workflows | [e.g., CLI tests] | [Happy paths] |

### Test Organization

```
tests/
├── unit/
│   └── test_[module].py          # Unit tests per module
├── integration/
│   └── test_[workflow].py        # Integration scenarios
└── conftest.py                   # Shared fixtures
```

### Key Test Scenarios

1. **[Scenario Name]**: [What is being tested and expected outcome]
2. **[Scenario Name]**: [What is being tested and expected outcome]
3. **[Scenario Name]**: [What is being tested and expected outcome]

### Testing Approach

- [ ] Tests written alongside implementation (TDD/TFD where appropriate)
- [ ] Each task includes its own test coverage
- [ ] Critical paths have integration tests
- [ ] Edge cases documented and tested

---

**Phase Checklist**

Before moving to the implementation phase, ensure:

- [ ] Summary accurately reflects the specification
- [ ] Technology choices are justified and documented
- [ ] Project structure supports all planned features
- [ ] Component responsibilities are clear with no overlap
- [ ] Build order has no circular dependencies
- [ ] All tasks are atomic and independently testable
- [ ] Risks are identified with mitigation strategies
- [ ] Testing strategy covers acceptance criteria from spec
- [ ] Effort estimates are realistic for the scope

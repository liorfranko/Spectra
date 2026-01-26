# Tasks Phase Template

This template guides the creation of an actionable task breakdown from the implementation plan. Each task should be atomic, testable, and clearly scoped.

**Input**: `plan.md` - The implementation plan from the previous phase

---

## Task ID Convention

Tasks use the format `TXXX` where XXX is a zero-padded sequential number:

- `T001`, `T002`, `T003`, etc.
- IDs must be unique within the spec
- Never reuse IDs, even for deleted tasks

---

## Task Markers

Tasks can include optional markers to indicate special properties:

| Marker | Meaning | Example |
|--------|---------|---------|
| `[P]` | Parallel - Can run concurrently with other `[P]` tasks at same level | `T003 [P]` |
| `[USn]` | User Story - Links to user story from spec | `T005 [US1]` |
| `[Bn]` | Blocks - This task blocks task n | `T002 [B3]` |

Markers appear after the task ID, before the description.

---

## Task Format

Each task follows this structure:

```markdown
- [ ] T001 [markers] Brief description
  - Files: `path/to/file.py`, `path/to/other.py`
  - Depends: T000 (if any dependencies)
  - Context: Brief context or acceptance criteria
```

### Examples

```markdown
- [ ] T001 [P] Create project configuration in pyproject.toml
  - Files: `pyproject.toml`
  - Context: Define package metadata, dependencies, and build config

- [ ] T002 [US1] Implement User model with validation
  - Files: `src/models/user.py`, `tests/test_user.py`
  - Depends: T001
  - Context: Pydantic model with email, name, and created_at fields

- [ ] T003 [P] [US2] Create database connection utility
  - Files: `src/db/connection.py`
  - Depends: T001
  - Context: Async connection pool for PostgreSQL
```

---

## Task Categories

Organize tasks into these categories in order:

### 1. Setup Tasks

Foundation tasks that other work depends on:

- [ ] Project configuration files
- [ ] Directory structure creation
- [ ] Dependency installation
- [ ] Development tooling setup

### 2. Foundational Tasks

Core infrastructure before feature implementation:

- [ ] Base models and schemas
- [ ] Core utilities and helpers
- [ ] Shared interfaces or protocols
- [ ] Configuration loading

### 3. Feature Implementation Tasks

Main functionality mapped to user stories:

- [ ] `[USn]` Feature tasks linked to user stories
- [ ] Integration points between features
- [ ] Error handling and edge cases

### 4. Polish Tasks

Finalization and quality tasks:

- [ ] Documentation updates
- [ ] Test coverage improvements
- [ ] Performance optimizations
- [ ] Code cleanup and refactoring

---

## Dependency Rules

### Expressing Dependencies

- Use `Depends: TXXX` to indicate a task requires another to complete first
- Multiple dependencies: `Depends: T001, T002, T003`
- Dependencies must reference valid task IDs
- Avoid circular dependencies

### Parallel Execution

Tasks marked `[P]` can execute concurrently when:

1. They have no dependencies on each other
2. They modify different files
3. They are at the same category level

Example parallel group:
```markdown
- [ ] T005 [P] Create user routes
  - Files: `src/routes/users.py`
  - Depends: T004

- [ ] T006 [P] Create product routes
  - Files: `src/routes/products.py`
  - Depends: T004

- [ ] T007 [P] Create order routes
  - Files: `src/routes/orders.py`
  - Depends: T004
```

---

## Task Breakdown

<!-- Generate tasks from plan.md sections. Map each plan component to atomic tasks. -->

### Setup Tasks

- [ ] T001 [Description]
  - Files: `[file paths]`
  - Context: [Brief context]

### Foundational Tasks

- [ ] T002 [Description]
  - Files: `[file paths]`
  - Depends: T001
  - Context: [Brief context]

### Feature Implementation Tasks

- [ ] T003 [USn] [Description]
  - Files: `[file paths]`
  - Depends: [dependencies]
  - Context: [Brief context]

### Polish Tasks

- [ ] T0XX [Description]
  - Files: `[file paths]`
  - Depends: [dependencies]
  - Context: [Brief context]

---

## Task Summary

| Category | Count | Parallel | Sequential |
|----------|-------|----------|------------|
| Setup | 0 | 0 | 0 |
| Foundational | 0 | 0 | 0 |
| Feature | 0 | 0 | 0 |
| Polish | 0 | 0 | 0 |
| **Total** | **0** | **0** | **0** |

---

**Phase Checklist**

Before moving to the implementation phase, ensure:

- [ ] All tasks have unique IDs following TXXX format
- [ ] Each task maps to a specific deliverable
- [ ] Dependencies form a valid DAG (no cycles)
- [ ] Parallel tasks are marked with `[P]`
- [ ] User story tasks are linked with `[USn]`
- [ ] File paths are specified for each task
- [ ] Tasks are ordered by category (Setup -> Foundational -> Feature -> Polish)
- [ ] Task count is reasonable (typically 10-30 for MVP scope)

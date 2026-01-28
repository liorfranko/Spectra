# Task Generation Organized by User Story

Pattern for generating implementation tasks from feature specifications.

## When to Use

When converting a feature specification with multiple user stories into an actionable task list that enables:
- Independent implementation per story
- MVP-first delivery
- Parallel team execution

## Key Principles

1. **User stories are the primary organization unit** - not technical layers
2. **Each story should be independently testable** after completion
3. **Foundational phase blocks all stories** - complete before parallel work

## Phase Structure

```
Phase 1: Setup (shared infrastructure)
Phase 2: Foundational (BLOCKS all user stories)
Phase 3+: One phase per user story (in priority order)
Final Phase: Polish & cross-cutting concerns
```

## Task Format

```
- [ ] T001 [P] [US1] Description with exact file path
```

Components:
- `- [ ]` - Markdown checkbox (required)
- `T001` - Sequential task ID (required)
- `[P]` - Parallel marker if task can run independently
- `[US1]` - User story label (required for story phases)
- Description with file path (required)

## Dependency Rules

### Between Phases
- Setup → Foundational → User Stories → Polish
- Foundational is the critical blocker

### Within User Story
1. Tests first (if TDD requested)
2. Models before services
3. Services before endpoints
4. Core before integration

### Parallel Opportunities
- Different file tasks within same phase
- Different user story phases (with multiple developers)
- All setup tasks typically parallel

## MVP Strategy

```
1. Complete Setup
2. Complete Foundational (critical path)
3. Complete US1 (P1 priority)
4. STOP AND VALIDATE
5. Optionally continue to US2, US3...
```

## Example Mapping

```
spec.md User Stories → tasks.md Phases

User Story 1 (P1) → Phase 3
User Story 2 (P1) → Phase 4
User Story 3 (P1) → Phase 5
User Story 4 (P2) → Phase 6
User Story 5 (P2) → Phase 7
User Story 6 (P3) → Phase 8
```

## Metrics to Report

- Total task count
- Tasks per user story
- Parallel opportunities (count of [P] tasks)
- MVP scope (which phases/stories)
- Independent test criteria per story

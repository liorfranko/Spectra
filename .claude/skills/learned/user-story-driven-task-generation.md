# Skill: User Story-Driven Task Generation

## When to Use
When generating implementation tasks from a specification that contains prioritized user stories (P1, P2, P3...).

## Pattern

1. **Organize by User Story, Not Component**
   - Each user story gets its own phase
   - All related work (models, services, endpoints) stays together
   - Enables independent implementation and testing per story

2. **Identify Foundational Work**
   - What MUST exist before ANY user story can start?
   - Core models used by multiple stories → Foundational phase
   - Shared infrastructure → Foundational phase
   - Mark as "BLOCKS all user stories"

3. **Map Dependencies Between Stories**
   - Most stories should be independently testable
   - Some stories naturally build on others (e.g., "archive" needs "review")
   - Draw the dependency graph explicitly

4. **Identify Parallel Opportunities**
   - Different files = can run in parallel
   - Mark with [P] tag
   - Group parallel examples for easy execution

5. **Define MVP Scope**
   - Usually just the first 1-2 user stories
   - Should be independently demonstrable
   - Include "STOP and VALIDATE" checkpoints

## Task Format

```
- [ ] T001 [P] [US1] Action verb + specific file path
```

Components:
- Checkbox: `- [ ]`
- Sequential ID: `T001`, `T002`, ...
- Parallel marker: `[P]` if parallelizable
- Story label: `[US1]`, `[US2]` for story phases only
- Description with exact file path

## Example Organization

```
Phase 1: Setup (no story labels)
Phase 2: Foundational (no story labels) - BLOCKS stories
Phase 3: US1 - First Story (P1) ← MVP
Phase 4: US2 - Second Story (P1)
...
Phase N: Polish (no story labels)
```

## Key Insight
Organizing by user story instead of by layer (all models, then all services, then all endpoints) enables incremental delivery and independent testing. Each story phase should be a complete, working increment.

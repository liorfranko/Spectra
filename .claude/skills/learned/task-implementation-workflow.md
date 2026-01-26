# Skill: Task Implementation Workflow

## Pattern

When implementing tasks from a tasks.md file, follow this workflow:

1. **Read Prerequisites**: Run check-prerequisites.sh to get FEATURE_DIR and available docs
2. **Check Checklists**: Verify all checklists in checklists/ are complete before proceeding
3. **Load Context**: Read tasks.md, plan.md, spec.md, and supporting documents
4. **Identify Next Task**: Find first unchecked task with satisfied dependencies
5. **Spawn Agent**: Use Task tool with general-purpose subagent for each task
6. **One Task = One Commit**: Never batch multiple tasks into one commit
7. **Commit Format**: `[T###] Description` (single task ID only)
8. **Push After Each**: Push to remote after each commit for backup
9. **Update tasks.md**: Mark task as [X] only after successful commit+push

## Key Rules

- Each task gets its own spawned agent with fresh context
- Provide agent with: task details, relevant plan excerpts, constitution principles
- Never use range formats like `[T001-T005]` in commits
- Parallel tasks [P] can be spawned simultaneously but still get individual commits

## Benefits

- Clear git history showing task-by-task progress
- Easy rollback to specific task if needed
- Granular tracking of changes
- Each commit is a checkpoint

## Example

```yaml
Task tool:
  subagent_type: "general-purpose"
  description: "[T024] Create specify.md command template"
  prompt: |
    You are implementing a specific task in isolation.

    TASK DETAILS:
    - Task ID: T024
    - Description: Create specify.md command template
    - Files to create: templates/commands/specify.md

    CONTEXT FROM PLAN:
    [Relevant excerpts...]

    INSTRUCTIONS:
    1. Implement ONLY this specific task
    2. Follow architecture from plan
    3. Create/modify specified files

    When complete, report what was done.
```

# Skill: Task-Agent-Commit Workflow

## When to Use
When implementing a task breakdown (tasks.md) using spawned agents, following the "One Task = One Agent = One Commit" principle.

## Pattern

1. **One Task = One Agent**
   - Each task (T001, T002, etc.) spawns its own agent via Task tool
   - Agent receives isolated context: task details, relevant plan excerpts, file paths
   - Agent completes its work and reports what was created/modified

2. **One Task = One Commit**
   - After each agent completes, immediately commit:
     ```bash
     git add <files> && git commit -m "[T###] Brief description

     Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
     ```
   - Push after each commit (or batch of parallel tasks)
   - Never batch multiple task IDs in commit messages

3. **Parallel Tasks**
   - Tasks marked `[P]` can spawn multiple agents simultaneously
   - Use single message with multiple Task tool calls
   - Each parallel task still gets its own commit
   - Push all commits together after parallel batch completes

4. **Task Tracking**
   - Update tasks.md checkbox `[X]` only after successful commit + push
   - Report progress: "T### Description - Committed and pushed"

## Commit Message Format

```
[T001] Create project structure
[T012] [US1] Implement User model in src/models/user.py
[T015] [P] [US1] Create UserService (parallel task)
```

**Invalid formats (never use):**
- `[T001-T005]` - No ranges
- `[T001, T002]` - No multiple IDs
- `Setup for T001-T005` - No IDs at end

## Benefits

- **Rollback granularity**: Any task can be reverted via `git revert`
- **Clear audit trail**: Git history shows task-by-task progress
- **Fresh context**: Each agent starts clean, avoiding context pollution
- **Progress visibility**: Commits = checkpoints of completed work

## Key Insight
The number of commits should roughly equal the number of completed tasks. If you have 13 tasks done, you should have approximately 13 `[T###]` commits in your git history.

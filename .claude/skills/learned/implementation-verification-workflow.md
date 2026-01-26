# Skill: Implementation Verification Workflow

## When to Use
When running `/speckit.implement` on a project where tasks may already be partially or fully complete, verify implementation status before attempting to spawn new agents.

## Pattern

### 1. Check Task Completion in tasks.md
Count `[X]` vs `[ ]` checkboxes:
```bash
# Count completed
grep -c '\[X\]' tasks.md
# Count pending
grep -c '\[ \]' tasks.md
```

### 2. Verify Git Commit History
Count task commits matching the `[T###]` format:
```bash
git log --oneline | grep -E '^\w+ \[T[0-9]+\]' | wc -l
```

### 3. Compare Tasks vs Commits
- If all tasks are `[X]` and commit count is reasonable, implementation is complete
- Commit count may be less than task count due to:
  - Parallel tasks `[P]` implemented together
  - Sequential tasks on same file combined
  - This is acceptable if all work is done

### 4. Verify Branch Sync Status
```bash
git status
git log --oneline -1
```
Confirm branch is up to date with remote.

## Output Format
Provide clear summary table:
```
| Metric | Value |
|--------|-------|
| Total Tasks | 76 |
| Completed | 76 (100%) |
| Task Commits | 42 |
| Verification | Pass |
```

## Next Steps
If complete, recommend `/speckit.review-pr` for code review before PR creation.

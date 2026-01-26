# Parallel Agent PR Review Pattern

## When to Use
When performing comprehensive code reviews before PR creation, especially for large changesets spanning multiple files and concerns.

## Pattern

Launch multiple specialized review agents in parallel using the Task tool with `run_in_background: true`:

```
1. code-reviewer: General code quality, style, potential bugs
2. silent-failure-hunter: Error handling and silent failures
3. pr-test-analyzer: Test coverage quality and completeness
4. comment-analyzer: Documentation accuracy and completeness
5. type-design-analyzer: Type design quality (if types changed)
6. code-simplifier: Code clarity opportunities (optional, last)
```

## Implementation

```python
# Launch all applicable agents in parallel
Task(subagent_type="pr-review-toolkit:code-reviewer", run_in_background=True, ...)
Task(subagent_type="pr-review-toolkit:silent-failure-hunter", run_in_background=True, ...)
Task(subagent_type="pr-review-toolkit:pr-test-analyzer", run_in_background=True, ...)
Task(subagent_type="pr-review-toolkit:comment-analyzer", run_in_background=True, ...)

# Wait for all to complete
TaskOutput(task_id="...", block=True)
```

## Aggregation Template

After all agents complete, aggregate results into a report with:

1. **Overall Status Table**: Pass/Warning/Fail per aspect with counts
2. **Critical Issues**: Must fix before PR (grouped)
3. **Important Issues**: Should fix (grouped)
4. **Suggestions**: Nice to have
5. **Constitution Compliance**: Check against project principles
6. **Strengths**: What's done well
7. **Next Steps**: Prioritized action items

## Benefits

- Parallel execution is faster than sequential
- Specialized agents catch domain-specific issues
- Comprehensive coverage of code quality dimensions
- Structured output makes action items clear

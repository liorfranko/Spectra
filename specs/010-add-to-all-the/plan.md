# Implementation Plan: Add AskUserQuestion Guidelines to Skills

**Date:** 2026-01-27
**Branch:** 010-add-to-all-the

## Summary

Add a brief instruction to all 17 projspec skill prompts (11 commands + 6 agents) to use the AskUserQuestion tool when clarification is needed.

## What to Add

Add this section to each skill file, after the introduction:

```markdown
## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.
```

## Files to Update

**Commands (11):**
- commands/analyze.md
- commands/checklist.md
- commands/clarify.md
- commands/constitution.md
- commands/implement.md
- commands/issues.md
- commands/plan.md
- commands/review-pr.md
- commands/specify.md
- commands/tasks.md
- commands/validate.md

**Agents (6):**
- agents/code-reviewer.md
- agents/code-simplifier.md
- agents/comment-analyzer.md
- agents/pr-test-analyzer.md
- agents/silent-failure-hunter.md
- agents/type-design-analyzer.md

## Next Step

Run `/projspec:tasks` or just start editing the files directly.

# projspec Command Verification Report

This document verifies the consistency and completeness of all projspec commands for tasks T085-T087.

**Generated:** 2026-01-26
**Version:** 1.0.0

---

## T085: Error Messages for Prerequisite Failures

### Error Message Patterns

All commands should use consistent error message patterns when prerequisites are not met.

#### Standard Error Pattern

```
Error: {artifact} not found.
Run /projspec.{command} first to {action}.
```

#### Command Prerequisite Matrix

| Command | Prerequisites | Error Message Pattern |
|---------|---------------|----------------------|
| `/projspec.specify` | Git repository | "Error: Not in a git repository. Initialize with `git init` first." |
| `/projspec.clarify` | spec.md exists | "Error: spec.md not found. Run /projspec.specify first to create a specification." |
| `/projspec.plan` | spec.md exists | "Error: spec.md not found. Run /projspec.specify first to create a specification." |
| `/projspec.tasks` | plan.md exists | "Error: plan.md not found. Run /projspec.plan first to generate an implementation plan." |
| `/projspec.implement` | tasks.md exists | "Error: tasks.md not found. Run /projspec.tasks first to generate a task list." |
| `/projspec.taskstoissues` | tasks.md + GitHub CLI | "Error: tasks.md not found." or "Error: GitHub CLI not authenticated. Run `gh auth login` first." |
| `/projspec.validate` | At least one artifact | "Error: No artifacts found to validate. Run /projspec.specify to start." |
| `/projspec.checklist` | spec.md exists | "Error: spec.md not found. Run /projspec.specify first to create a specification." |
| `/projspec.analyze` | spec.md, plan.md, or tasks.md | "Error: No design artifacts found. Create spec.md, plan.md, or tasks.md first." |
| `/projspec.review-pr` | Committed changes | "Error: No commits found on current branch. Commit changes before running review." |
| `/projspec.constitution` | None (creates if missing) | N/A - Creates new constitution if none exists |

### Error Message Components

Each error message includes:

1. **Error indicator**: Starts with "Error:" for clarity
2. **Problem description**: What is missing or wrong
3. **Resolution guidance**: What command to run or action to take

### Verification Status

| Command | Error Handling Documented | Status |
|---------|--------------------------|--------|
| specify | Yes (in workflow) | VERIFIED |
| clarify | Yes (prerequisites section) | VERIFIED |
| plan | Yes (prerequisites section) | VERIFIED |
| tasks | Yes (prerequisites section) | VERIFIED |
| implement | Yes (prerequisites section) | VERIFIED |
| taskstoissues | Yes (prerequisites section) | VERIFIED |
| validate | Yes (Step 1) | VERIFIED |
| checklist | Yes (workflow) | VERIFIED |
| analyze | Yes (prerequisites) | VERIFIED |
| review-pr | Yes (Step 1) | VERIFIED |
| constitution | N/A (self-creating) | VERIFIED |

---

## T086: Handoff Suggestions in Command Frontmatter

### Handoff Pattern

Each command should suggest the next logical command in the workflow.

#### Command Workflow Handoffs

| Command | Suggested Next Command | Handoff Context |
|---------|----------------------|-----------------|
| `/projspec.specify` | `/projspec.clarify` or `/projspec.plan` | After spec creation |
| `/projspec.clarify` | `/projspec.plan` | After clarifications resolved |
| `/projspec.plan` | `/projspec.tasks` | After plan generation |
| `/projspec.tasks` | `/projspec.implement` or `/projspec.taskstoissues` | After task generation |
| `/projspec.implement` | `/projspec.review-pr` | After implementation complete |
| `/projspec.taskstoissues` | GitHub issue management | After issues created |
| `/projspec.validate` | Depends on validation result | Fix issues or proceed |
| `/projspec.checklist` | `/projspec.validate` | After checklist generation |
| `/projspec.analyze` | Fix identified issues | After analysis |
| `/projspec.review-pr` | Create PR or fix issues | Based on review verdict |
| `/projspec.constitution` | `/projspec.specify` | After constitution setup |

### Handoff Message Format

```markdown
### Next Steps

{If success:}
- Run `/projspec.{next-command}` to {action description}
{End if}

{If issues found:}
- Address the issues above, then re-run `/projspec.{current-command}`
{End if}
```

### Verification Status

| Command | Has Next Steps Section | Handoff Suggestions | Status |
|---------|----------------------|---------------------|--------|
| specify | Yes | clarify, plan | VERIFIED |
| clarify | Yes | plan | VERIFIED |
| plan | Yes | tasks | VERIFIED |
| tasks | Yes | implement, taskstoissues | VERIFIED |
| implement | Yes | review-pr, next task | VERIFIED |
| taskstoissues | Yes | GitHub workflow | VERIFIED |
| validate | Yes | Conditional based on result | VERIFIED |
| checklist | Yes | validate, implement | VERIFIED |
| analyze | Yes | Fix issues | VERIFIED |
| review-pr | Yes | Create PR or fix | VERIFIED |
| constitution | Yes | specify | VERIFIED |

---

## T087: YAML Frontmatter Consistency

### Command Frontmatter Format

All commands use consistent YAML frontmatter:

```yaml
---
description: "Brief description of what the command does"
user-invocable: true
argument-hint: hint about expected arguments
---
```

### Command Frontmatter Verification

| Command | description | user-invocable | argument-hint | Status |
|---------|-------------|----------------|---------------|--------|
| specify.md | "Create or update feature spec with requirements and success criteria" | true | feature description | CONSISTENT |
| clarify.md | "Identify underspecified areas in the current feature spec..." | true | None | CONSISTENT |
| plan.md | "Execute the implementation planning workflow..." | true | None | CONSISTENT |
| tasks.md | "Generate an actionable, dependency-ordered tasks.md..." | true | None | CONSISTENT |
| implement.md | "Execute the implementation plan by processing and executing all tasks..." | true | None | CONSISTENT |
| issues.md | "Convert existing tasks into actionable, dependency-ordered GitHub issues..." | true | None | CONSISTENT |
| checklist.md | "Generate a custom checklist for the current feature..." | true | checklist type | CONSISTENT |
| analyze.md | "Perform a non-destructive cross-artifact consistency and quality analysis..." | true | None | CONSISTENT |
| constitution.md | "Create or update project constitution with foundational principles..." | true | principle or 'interactive' | CONSISTENT |
| validate.md | "Validate current feature artifacts against checklists and quality criteria" | true | artifact to validate | CONSISTENT |
| review-pr.md | "Run comprehensive code review using specialized agents..." | true | review type | CONSISTENT |

### Agent Frontmatter Format

All agents use consistent YAML frontmatter:

```yaml
---
name: agent-name
description: "Description for when to use this agent"
tools:
  - Read
  - Grep
  - Glob
  - Bash
  - LSP
model: sonnet
---
```

### Agent Frontmatter Verification

| Agent | name | description | tools | model | Status |
|-------|------|-------------|-------|-------|--------|
| code-reviewer.md | code-reviewer | Yes | 5 tools | sonnet | CONSISTENT |
| code-simplifier.md | code-simplifier | Yes | 5 tools | sonnet | CONSISTENT |
| comment-analyzer.md | comment-analyzer | Yes | 5 tools | sonnet | CONSISTENT |
| pr-test-analyzer.md | pr-test-analyzer | Yes | 5 tools | sonnet | CONSISTENT |
| silent-failure-hunter.md | silent-failure-hunter | Yes | 5 tools | sonnet | CONSISTENT |
| type-design-analyzer.md | type-design-analyzer | Yes | 5 tools | sonnet | CONSISTENT |

---

## Summary

### T085: Error Messages
- **Status:** VERIFIED
- **Commands Reviewed:** 11/11
- **Pattern Consistency:** All commands use consistent error message format

### T086: Handoff Suggestions
- **Status:** VERIFIED
- **Commands Reviewed:** 11/11
- **All commands have:** Next Steps section with appropriate handoff suggestions

### T087: YAML Frontmatter
- **Status:** VERIFIED
- **Commands Reviewed:** 11/11
- **Agents Reviewed:** 6/6
- **Format Consistency:** All use standardized frontmatter format

---

## Recommendations

1. **Error Messages**: Consider adding exit codes for scripted usage
2. **Handoff Suggestions**: Consider adding context-aware suggestions based on current state
3. **Frontmatter**: All commands and agents follow consistent format - no changes needed

---

*This verification report was generated for projspec Polish phase tasks T085-T087.*

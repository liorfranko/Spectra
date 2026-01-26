# Skill: Parallel PR Review with Specialized Agents

## When to Use
When performing comprehensive code review before creating a PR, use multiple specialized agents in parallel to analyze different aspects of code quality simultaneously.

## Pattern

### 1. Identify Changed Files
```bash
git diff --name-only main...HEAD
```

### 2. Launch Agents in Parallel
Use a single message with multiple Task tool calls to spawn agents simultaneously:

```yaml
Agents to launch:
  - pr-review-toolkit:code-reviewer - General quality, bugs, style
  - pr-review-toolkit:silent-failure-hunter - Error handling issues
  - pr-review-toolkit:type-design-analyzer - Type/model quality
  - pr-review-toolkit:code-simplifier - Clarity improvements
```

### 3. Agent Prompt Structure
Each agent needs:
- List of files to review
- Specific focus areas
- Expected output format (severity levels, file:line references)
- Project context (tech stack, patterns)

### 4. Aggregate Results
After all agents complete, create a summary table:

```markdown
| Review Aspect | Status | Critical | Important | Suggestions |
|---------------|--------|----------|-----------|-------------|
| Code Quality  | ⚠      | 1        | 3         | 4           |
| Error Handling| ⚠      | 2        | 3         | 3           |
```

### 5. Save Report
Write to `{FEATURE_DIR}/checklists/pr-review-report.md`

## Benefits
- Faster than sequential review (parallel execution)
- Specialized focus per agent produces deeper analysis
- Consistent output format for actionable items
- Comprehensive coverage of code quality dimensions

## Example Agent Invocation
```
Task tool:
  subagent_type: "pr-review-toolkit:silent-failure-hunter"
  description: "Hunt silent failures"
  prompt: |
    Review error handling in these files:
    - src/projspec/state.py
    - src/projspec/cli.py

    Look for:
    1. Silent failures (empty catch blocks)
    2. Missing error logging
    3. Errors that should propagate

    Report severity as CRITICAL, HIGH, or MEDIUM with file:line locations.
```

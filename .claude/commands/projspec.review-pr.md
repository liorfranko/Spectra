---
description: Comprehensive pull request review using specialized agents to ensure code quality before PR creation
argument-hint: "[review-aspects] (e.g., tests errors, all, all parallel)"
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Goal: Perform a comprehensive pull request review using multiple specialized agents from the pr-review-toolkit, each analyzing different aspects of code quality. This command should be run after `/speckit.implement` is complete and before creating a pull request.

## Available Review Agents

The following specialized agents are available (located in `.specify/templates/agents/`):

- **code-reviewer**: General code quality, style violations, and bug detection
- **silent-failure-hunter**: Error handling and silent failures
- **pr-test-analyzer**: Test coverage quality and completeness
- **type-design-analyzer**: Type design quality and invariants
- **comment-analyzer**: Documentation accuracy and completeness
- **code-simplifier**: Code clarity and simplification opportunities

## Execution Steps

### 1. Identify Review Scope

Run `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` from repo root and parse the output to determine:

- Current branch/worktree context
- Feature directory location
- Whether we're in a worktree or regular branch

Determine what files have changed:

```bash
# Get all modified files compared to main branch
git diff --name-only main...HEAD

# Get current git status for unstaged/staged changes
git status --porcelain
```

For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Parse Review Scope from User Input

Support these usage patterns:

**Full review (default)**:

```text
/speckit.review-pr
/speckit.review-pr all
```

**Targeted review**:

```text
/speckit.review-pr tests errors
/speckit.review-pr code simplify
/speckit.review-pr tests
```

**Parallel execution**:

```text
/speckit.review-pr all parallel
/speckit.review-pr tests code parallel
```

Parse the arguments to determine:

- Which review aspects to run: `comments`, `tests`, `errors`, `types`, `code`, `simplify`, or `all`
- Execution mode: `sequential` (default) or `parallel`
- Focus files: specific paths if provided

**Aspect mapping to agents:**

- `code` → code-reviewer
- `errors` → silent-failure-hunter
- `tests` → pr-test-analyzer
- `types` → type-design-analyzer
- `comments` → comment-analyzer
- `simplify` → code-simplifier
- `all` → all of the above

### 3. Constitution Pre-Check

**REQUIRED**: Load and review `.specify.specify/memory/constitution.md` if it exists.

Before running detailed reviews, perform a quick constitution alignment check:

- Read the constitution to understand project principles
- Identify any MUST requirements that should be validated
- Note quality standards, testing requirements, and code style expectations
- This context will inform all subsequent review agents

### 4. Determine Applicable Reviews

Based on the changed files and user request, determine which reviews to run:

**Auto-detection logic** (if user didn't specify aspects):

- If test files changed (*.test.*, *.spec.*, **tests**/) → include `tests` review
- If error handling code changed (try/catch, error classes) → include `errors` review
- If type definitions changed (interfaces, types, classes, *.d.ts) → include `types` review
- If comments/documentation changed → include `comments` review
- Always include `code` review for general quality
- Optionally include `simplify` at the end for polish

**User-specified** (if aspects provided):

- Use exactly the aspects requested
- If `all` specified, run all 6 reviews

### 5. Execute Review Agents

For each review aspect, use the Task tool to spawn the appropriate specialized agent.

**IMPORTANT**: Agent names for Task tool are just the agent file name (e.g., "code-reviewer", not "pr-review-toolkit:code-reviewer").

#### Agent Execution Templates

For each agent, construct a detailed prompt that includes:

1. The files to review (from git diff)
2. The specific focus area
3. Relevant constitution excerpts
4. Expected output format

**Example for code-reviewer agent:**

```text
Review code for adherence to project guidelines and quality standards.

Changed files:
{file_list}

Focus on:
1. Compliance with project coding standards
2. Potential bugs or logic errors
3. Security vulnerabilities
4. Performance issues
5. Code style consistency

Constitution requirements:
{relevant_constitution_points}

Only report issues with confidence ≥ 80. Group by severity (Critical: 90-100, Important: 80-89).
```

**Example for silent-failure-hunter agent:**

```text
Review error handling in the following changed files for silent failures and inadequate error handling:

{file_list}

Look for:
1. Silent failures (empty catch blocks, swallowed errors)
2. Missing error logging
3. Inappropriate fallback behavior
4. Errors that should propagate but don't

Constitution error handling requirements:
{relevant_constitution_points}

Report severity as CRITICAL, HIGH, or MEDIUM with specific file locations.
```

**Example for pr-test-analyzer agent:**

```text
Review test coverage and quality for the changes in this PR.

Changed files:
{file_list}

Analyze:
1. Are all critical code paths tested?
2. Are edge cases covered?
3. Do tests verify behavior, not just execution?
4. Are error conditions tested?

Constitution testing requirements:
{relevant_constitution_points}

Rate test gaps on 1-10 scale (10 = critical gap, 1 = minor nice-to-have).
```

**Example for type-design-analyzer agent:**

```text
Review type design quality for types introduced or modified in this PR:

{type_file_list}

Evaluate each type on four dimensions (1-10 scale):
1. Encapsulation: Does it hide implementation details?
2. Invariant Expression: Are constraints clearly expressed?
3. Usefulness: Does it prevent invalid states?
4. Enforcement: Are invariants actually enforced?

Constitution type design requirements:
{relevant_constitution_points}
```

**Example for comment-analyzer agent:**

```text
Analyze code comments for accuracy, completeness, and maintainability:

{file_list}

Focus on:
1. Comments that don't match the actual code behavior
2. Outdated documentation after code changes
3. Missing documentation for complex logic
4. Comments that will become technical debt

Constitution documentation requirements:
{relevant_constitution_points}

Categorize as Critical, Important, or Suggestions.
```

**Example for code-simplifier agent:**

```text
Review code for opportunities to improve clarity and reduce unnecessary complexity:

{file_list}

Look for:
1. Overly complex logic that could be simplified
2. Unnecessary abstractions or indirection
3. Code that's too clever or compact
4. Opportunities for better naming or structure

Only suggest simplifications that maintain or improve clarity.

Constitution simplicity requirements:
{relevant_constitution_points}
```

### 6. Execution Strategy

**Sequential Mode** (default):
Run agents one at a time in this order using the Task tool:

1. Launch `code-reviewer` first (general quality baseline)
2. Wait for completion, review results
3. Launch `silent-failure-hunter` (critical errors)
4. Wait for completion, review results
5. Launch `pr-test-analyzer` (coverage verification)
6. Wait for completion, review results
7. Launch `type-design-analyzer` if types changed
8. Wait for completion, review results
9. Launch `comment-analyzer` if docs changed
10. Wait for completion, review results
11. Launch `code-simplifier` last (final polish)
12. Wait for completion, review results

**Parallel Mode**:
Use the Task tool to launch multiple agents simultaneously in a single message with multiple Task tool calls:

```text
Launch all applicable agents at once:
- code-reviewer
- silent-failure-hunter
- pr-test-analyzer
- type-design-analyzer (if applicable)
- comment-analyzer (if applicable)
- code-simplifier

Wait for all to complete, then aggregate results.
```

### 7. Aggregate Review Results

After all selected reviews complete, create a comprehensive summary:

```markdown
# PR Review Summary

**Feature**: {feature_name}
**Branch**: {branch_name}
**Files Changed**: {file_count}
**Review Date**: {timestamp}

## Overall Status

| Review Aspect | Status | Critical | Important | Suggestions |
|---------------|--------|----------|-----------|-------------|
| Code Quality  | ✓/⚠/✗  | N        | N         | N           |
| Error Handling| ✓/⚠/✗  | N        | N         | N           |
| Test Coverage | ✓/⚠/✗  | N        | N         | N           |
| Type Design   | ✓/⚠/✗  | N        | N         | N           |
| Documentation | ✓/⚠/✗  | N        | N         | N           |
| Code Clarity  | ✓/⚠/✗  | N        | N         | N           |

**Legend**: ✓ Pass | ⚠ Pass with warnings | ✗ Needs attention

## Critical Issues (Must Fix Before PR)

{List all critical issues from all agents with file:line references}

## Important Issues (Should Fix)

{List all important issues from all agents with file:line references}

## Suggestions (Nice to Have)

{List all suggestions from all agents}

## Constitution Compliance

- ✓ All MUST requirements met
- ⚠ Some SHOULD requirements not met: {list}
- ✗ MUST requirement violations: {list}

## Strengths

{What's well-done in this PR - positive observations from agents}

## Next Steps

{Recommended actions based on findings}
```

### 8. Save Review Report

Write the aggregated review report to:

- `{FEATURE_DIR}/checklists/pr-review-report.md`

Include timestamp and agent versions used.

### 9. Provide Action Recommendations

Based on the aggregated results:

**If critical issues found**:

- Display critical issues prominently
- Recommend: "Fix critical issues before creating PR"
- List specific action items
- Offer to help fix issues if requested

**If only important/suggestions**:

- Display summary
- Recommend: "Consider addressing important issues, then proceed to PR creation"
- Note: "Suggestions can be addressed in follow-up PRs"

**If all clear**:

- Congratulate the user
- Recommend: "Ready to create PR! Use `gh pr create` or your PR creation workflow"
- Optionally remind about constitution compliance

## Behavioral Guidelines

### Agent Invocation

When using the Task tool to spawn agents:

- Use subagent_type as just the agent name (e.g., "code-reviewer")
- Provide a clear, focused prompt for each agent
- Include relevant file lists and constitution excerpts
- Specify expected output format
- Set appropriate model if needed (opus for complex reviews)

**Example Task tool call:**

```text
Task tool:
  subagent_type: "code-reviewer"
  description: "Review code quality"
  prompt: "Review the following files for adherence to project guidelines:\n\n{file_list}\n\nFocus on: compliance, bugs, quality issues.\n\nConstitution: {excerpt}\n\nReport only issues ≥80 confidence."
```

### Review Scope Determination

- **Default**: Review all files changed compared to main branch
- **Worktree context**: Automatically detect worktree and review worktree changes
- **User-specified files**: Honor specific file paths if provided
- **Incremental reviews**: Support reviewing only new changes since last review

### Agent Selection Intelligence

- **Smart defaults**: Auto-select relevant agents based on file types
- **User override**: Always honor explicit user requests
- **Efficiency**: Don't run type analyzer if no types changed
- **Completeness**: Always run code-reviewer for baseline quality

### Constitution Integration

- **Authority**: Constitution principles are non-negotiable
- **Context**: Pass relevant constitution excerpts to each agent
- **Reporting**: Explicitly note constitution violations
- **Remediation**: Suggest fixes that align with constitution

### Output Quality

- **Actionable**: Every issue includes file, line, and suggested fix
- **Prioritized**: Critical > Important > Suggestions
- **Concise**: Summarize similar issues, don't repeat
- **Confident**: Only report issues with high confidence (80+ score)

### Performance Optimization

- **Parallel when requested**: Use parallel mode for speed
- **Incremental**: Support reviewing only changed files
- **Smart filtering**: Filter out low-confidence findings
- **Progressive disclosure**: Show summary first, details on request

## Example Usage

```bash
# Full review before PR creation
/speckit.review-pr

# Quick review of tests and error handling
/speckit.review-pr tests errors

# Comprehensive parallel review
/speckit.review-pr all parallel

# Review just code quality and simplification
/speckit.review-pr code simplify

# Review everything sequentially (most thorough)
/speckit.review-pr all
```

## Integration Points

This command works best:

- **After** `/speckit.implement` completes
- **Before** creating a pull request
- **In combination with** `/speckit.validate` for full artifact validation
- **Iteratively** after fixing issues and re-running review

## Notes

- Agents are defined in `.specify/templates/agents/` directory
- Each agent specializes in a specific aspect of code quality
- Reviews are comprehensive but respect user time
- Constitution alignment is checked throughout
- Reports are saved for tracking and reference
- Use sequential mode for better understanding
- Use parallel mode for faster results when time matters

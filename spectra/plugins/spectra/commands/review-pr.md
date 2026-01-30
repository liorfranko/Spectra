---
description: "Run comprehensive code review using specialized agents before PR creation"
user-invocable: true
argument-hint: review type (full, quick, security, performance)
---

# Review PR Command

Perform a comprehensive pull request review using specialized agents to ensure code quality before PR creation. This command analyzes changes, runs multiple review perspectives, and provides actionable feedback.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Arguments

The `$ARGUMENTS` variable contains the review type:
- `full` - Complete review with all specialized agents
- `quick` - Fast review focusing on critical issues
- `security` - Security-focused review
- `performance` - Performance-focused review
- `style` - Code style and consistency review
- (empty) - Default to `full` review

## Prerequisites

Before running this command:
1. Changes must be committed (or staged for review)
2. Feature artifacts should exist for context (optional but recommended)

## Workflow

### Step 1: Gather Review Context

**1.1: Check git state and gather changes**

```bash
# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get base branch (usually main or master)
BASE_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)

# Get list of changed files
CHANGED_FILES=$(git diff --name-only $BASE_BRANCH..HEAD)

# Get the full diff
FULL_DIFF=$(git diff $BASE_BRANCH..HEAD)

# Get commit history for this branch
COMMITS=$(git log --oneline $BASE_BRANCH..HEAD)
```

Store git context:
```
gitContext = {
  currentBranch: "feature-branch",
  baseBranch: "main",
  changedFiles: ["file1.ts", "file2.md", ...],
  commitCount: 5,
  commits: [
    { hash: "abc123", message: "..." },
    ...
  ],
  diffStats: {
    filesChanged: 10,
    insertions: 250,
    deletions: 50
  }
}
```

**1.2: Gather feature context if available**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --json
```

If in a feature directory, read:
- spec.md - For requirements context
- plan.md - For architecture context
- tasks.md - For task completion status

**1.3: Report review scope**

```markdown
## Review Scope

**Branch:** {gitContext.currentBranch}
**Base:** {gitContext.baseBranch}
**Commits:** {gitContext.commitCount}
**Files Changed:** {gitContext.diffStats.filesChanged}

### Change Summary

| Metric | Count |
|--------|-------|
| Files Changed | {filesChanged} |
| Lines Added | +{insertions} |
| Lines Removed | -{deletions} |

### Files to Review

{For each category of files:}
**{category}** ({count} files):
{For each file (max 10 per category):}
- `{file_path}` (+{additions}/-{deletions})
{End for}
{End for}

### Review Type: {$ARGUMENTS or "full"}

Starting review...
```

### Step 2: Determine Review Strategy

**2.1: Select agents based on review type**

| Review Type | Agents Invoked |
|-------------|----------------|
| `full` | All agents: code-quality, security, performance, style, requirements, **code-simplifier** |
| `quick` | code-quality, critical-issues |
| `security` | security-deep, vulnerability-scan |
| `performance` | performance-analysis, resource-usage |
| `style` | style-consistency, formatting, **code-simplifier** |

**2.2: Order agents by priority**

For `full` review, execute in order:
1. **Critical Issues** - Blocking problems
2. **Security** - Vulnerabilities and security concerns
3. **Code Quality** - Logic, patterns, maintainability
4. **Code Simplifier** - Complexity reduction and refactoring opportunities (HIGH PRIORITY)
5. **Requirements** - Spec compliance
6. **Performance** - Optimization opportunities
7. **Style** - Formatting and conventions

### Step 3: Execute Review Agents

**3.1: Critical Issues Agent**

```markdown
### Agent: Critical Issues

Looking for blocking problems that must be fixed...

**Checks:**
- [ ] Syntax errors
- [ ] Runtime errors
- [ ] Breaking changes without migration
- [ ] Security vulnerabilities (critical)
- [ ] Data loss risks
- [ ] API contract violations
```

Spawn agent with context:
```yaml
Task:
  description: "Critical Issues Review"
  prompt: |
    Review the following code changes for critical issues that would block merge.

    Focus on:
    1. Syntax and runtime errors
    2. Breaking changes to public APIs
    3. Security vulnerabilities (injection, auth bypass, data exposure)
    4. Data integrity issues
    5. Unhandled error cases that could crash the application

    DIFF:
    {FULL_DIFF}

    CHANGED FILES:
    {CHANGED_FILES}

    Report format:
    - CRITICAL: [file:line] Description of issue
    - HIGH: [file:line] Description of issue

    If no critical issues found, report "No critical issues found."
```

Parse agent response and categorize:
```
criticalIssues = {
  critical: [
    { file: "path/file.ts", line: 42, issue: "SQL injection vulnerability" }
  ],
  high: [
    { file: "path/file.ts", line: 100, issue: "Unhandled promise rejection" }
  ]
}
```

**3.2: Security Review Agent**

```markdown
### Agent: Security Review

Analyzing for security vulnerabilities...

**Checks:**
- [ ] Input validation
- [ ] Authentication/authorization
- [ ] Data sanitization
- [ ] Secure communication
- [ ] Credential handling
- [ ] Dependency vulnerabilities
```

Spawn security-focused agent:
```yaml
Task:
  description: "Security Review"
  prompt: |
    Perform a security review of the following changes.

    Check for:
    1. Injection vulnerabilities (SQL, XSS, command injection)
    2. Authentication bypass possibilities
    3. Authorization issues (privilege escalation)
    4. Sensitive data exposure (logging, error messages)
    5. Insecure cryptographic practices
    6. Hardcoded credentials or secrets
    7. SSRF or path traversal risks
    8. Dependency vulnerabilities

    DIFF:
    {FULL_DIFF}

    Report format:
    - [SEVERITY]: [CWE-XXX if applicable] [file:line] Description
    - Recommendation: How to fix

    If no security issues found, report "No security issues found."
```

Parse and categorize security findings.

**3.3: Code Quality Agent**

```markdown
### Agent: Code Quality

Evaluating code quality and maintainability...

**Checks:**
- [ ] Logic correctness
- [ ] Error handling
- [ ] Code organization
- [ ] Naming conventions
- [ ] Documentation
- [ ] Test coverage
```

Spawn code quality agent:
```yaml
Task:
  description: "Code Quality Review"
  prompt: |
    Review code quality and maintainability of the following changes.

    Evaluate:
    1. Logic correctness - Does the code do what it intends?
    2. Error handling - Are errors handled appropriately?
    3. Code organization - Is the code well-structured?
    4. Naming - Are names clear and descriptive?
    5. Documentation - Are complex parts documented?
    6. DRY - Is there unnecessary duplication?
    7. SOLID principles - Are design principles followed?
    8. Testability - Is the code testable?

    DIFF:
    {FULL_DIFF}

    Report format:
    - [ISSUE TYPE]: [file:line] Description
    - Suggestion: How to improve

    Also note positive patterns worth keeping.
```

**3.4: Code Simplifier Agent (HIGH PRIORITY)**

```markdown
### Agent: Code Simplifier

**This agent is critical for maintaining code quality.** Analyzing complexity and identifying simplification opportunities...

**Checks:**
- [ ] Cyclomatic complexity
- [ ] Function length and nesting depth
- [ ] Code duplication (DRY violations)
- [ ] Over-engineering and unnecessary abstractions
- [ ] Naming clarity and self-documenting code
- [ ] Cognitive load per function
```

Spawn the code-simplifier agent using the Task tool:
```yaml
Task:
  subagent_type: "spectra:code-simplifier"
  description: "Code Simplification Review"
  prompt: |
    **IMPORTANT: This is a high-priority review step.**

    Analyze the following code changes for complexity issues and simplification opportunities.

    Focus on:
    1. Functions with high cyclomatic complexity (>10)
    2. Deeply nested conditionals (>3 levels)
    3. Long functions (>50 lines)
    4. Code duplication across the changes
    5. Over-engineered abstractions that add complexity without value
    6. Unclear naming that requires comments to understand
    7. "Clever" code that sacrifices readability
    8. Opportunities to apply guard clauses and early returns

    DIFF:
    {FULL_DIFF}

    CHANGED FILES:
    {CHANGED_FILES}

    Report format:
    ## Complexity Issues Found

    ### Critical Complexity (Must Simplify)
    - [file:line] Description - Why it's complex and how to simplify

    ### High Complexity (Should Simplify)
    - [file:line] Description - Suggested refactoring

    ### Simplification Opportunities
    - [file:line] Quick win that improves readability

    ### Positive Patterns
    - Note any well-structured, clean code worth preserving

    If code is already clean and simple, report "Code complexity is acceptable. No simplification needed."
```

Parse agent response and categorize:
```
simplificationIssues = {
  critical: [
    { file: "path/file.ts", line: 42, issue: "Function has cyclomatic complexity of 25", suggestion: "Extract into smaller functions" }
  ],
  high: [
    { file: "path/file.ts", line: 100, issue: "5 levels of nesting", suggestion: "Use guard clauses" }
  ],
  opportunities: [
    { file: "path/file.ts", line: 150, issue: "Duplicate logic", suggestion: "Extract helper function" }
  ]
}
```

**Note:** Code simplification findings should be weighted heavily in the final review score. Complex code that passes other checks should still be flagged for improvement.

**3.5: Requirements Compliance Agent** (if spec.md available)

```markdown
### Agent: Requirements Compliance

Verifying implementation matches specification...

**Checks:**
- [ ] All requirements implemented
- [ ] Acceptance criteria met
- [ ] Edge cases handled
- [ ] Success criteria achievable
```

Spawn requirements agent:
```yaml
Task:
  description: "Requirements Compliance Review"
  prompt: |
    Verify that the implementation matches the specification.

    SPECIFICATION:
    {spec.md content}

    IMPLEMENTATION:
    {FULL_DIFF}

    Check:
    1. Each FR-### has corresponding implementation
    2. Each US-### acceptance criteria is met
    3. Edge cases from spec are handled
    4. Success criteria SC-### are achievable

    Report format:
    - [REQUIREMENT_ID]: [PASS/PARTIAL/FAIL] - Notes
    - Missing: List any unimplemented requirements
```

**3.6: Performance Review Agent**

```markdown
### Agent: Performance Review

Analyzing performance implications...

**Checks:**
- [ ] Algorithm efficiency
- [ ] Resource usage
- [ ] Memory management
- [ ] I/O operations
- [ ] Caching opportunities
```

Spawn performance agent:
```yaml
Task:
  description: "Performance Review"
  prompt: |
    Review performance implications of the following changes.

    Analyze:
    1. Algorithm complexity (time and space)
    2. Database query efficiency
    3. Memory allocations and leaks
    4. I/O blocking operations
    5. Network call patterns
    6. Caching opportunities
    7. Lazy loading potential

    DIFF:
    {FULL_DIFF}

    Report format:
    - [SEVERITY]: [file:line] Performance concern
    - Impact: Expected impact on performance
    - Suggestion: How to optimize
```

**3.7: Style Consistency Agent**

```markdown
### Agent: Style Consistency

Checking code style and formatting...

**Checks:**
- [ ] Formatting rules
- [ ] Naming conventions
- [ ] Import organization
- [ ] Comment style
- [ ] Consistency with codebase
```

Spawn style agent:
```yaml
Task:
  description: "Style Consistency Review"
  prompt: |
    Review code style and consistency.

    Check:
    1. Formatting matches project standards
    2. Naming follows conventions
    3. Imports are organized
    4. Comments are appropriate
    5. Consistency with existing codebase patterns

    DIFF:
    {FULL_DIFF}

    Report format:
    - [file:line] Style issue description
    - Fix: How to correct

    Note: Focus on consistency, not personal preference.
```

### Step 4: Compile Review Results

**4.1: Aggregate findings from all agents**

```
reviewResults = {
  critical: [...],        // Must fix before merge
  high: [...],            // Should fix before merge
  medium: [...],          // Recommended to fix
  low: [...],             // Nice to fix
  suggestions: [...],     // Optional improvements
  positives: [...],       // Good patterns to keep
  simplification: {       // Code complexity issues (HIGH PRIORITY)
    critical: [...],      // Must simplify before merge
    high: [...],          // Should simplify
    opportunities: [...]  // Quick wins for readability
  }
}
```

**4.2: Calculate review score**

```
reviewScore = {
  critical: criticalIssues.critical.length,
  high: criticalIssues.high.length + securityIssues.high.length,
  medium: qualityIssues.length + performanceIssues.length,
  low: styleIssues.length,

  // Code simplification issues (weighted heavily)
  simplificationCritical: simplificationIssues.critical.length,
  simplificationHigh: simplificationIssues.high.length,

  // Aggregate score (0-100)
  overallScore: calculateScore(...)
}
```

Score calculation:
- Start at 100
- -20 for each critical issue
- **-15 for each critical simplification issue (complexity debt is expensive)**
- -10 for each high issue
- **-8 for each high simplification issue**
- -5 for each medium issue
- -1 for each low issue
- Minimum score: 0

**Note:** Code simplification issues are weighted heavily because complex code:
- Is harder to maintain and debug
- Contains more hidden bugs
- Slows down future development
- Makes onboarding difficult

**4.3: Determine review verdict**

| Score | Verdict | Action |
|-------|---------|--------|
| 90-100 | APPROVED | Ready to merge |
| 70-89 | APPROVED_WITH_COMMENTS | Can merge, address comments |
| 50-69 | CHANGES_REQUESTED | Must address before merge |
| 0-49 | BLOCKED | Critical issues must be resolved |

### Step 5: Generate Review Report

**5.1: Create structured review report**

```markdown
## Code Review Report

**Branch:** {currentBranch} -> {baseBranch}
**Review Type:** {reviewType}
**Score:** {overallScore}/100
**Verdict:** {verdict}

---

### Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | {count} | {Must Fix} |
| **Complexity Critical** | {simplificationCritical} | **Must Simplify** |
| High | {count} | {Should Fix} |
| **Complexity High** | {simplificationHigh} | **Should Simplify** |
| Medium | {count} | {Recommended} |
| Low | {count} | {Optional} |

---

{If critical issues exist:}
## Critical Issues (Must Fix)

These issues must be resolved before the PR can be merged.

{For each critical issue:}
### {index}. {issue.title}

**File:** `{issue.file}:{issue.line}`
**Type:** {issue.type}

**Issue:**
{issue.description}

**Impact:**
{issue.impact}

**Fix:**
```{language}
{issue.suggestion}
```

{End for}

---
{End if}

{If high issues exist:}
## High Priority Issues

These issues should be addressed before merge.

{For each high issue:}
### {index}. {issue.title}

**File:** `{issue.file}:{issue.line}`

{issue.description}

**Suggestion:** {issue.suggestion}

{End for}

---
{End if}

{If simplification issues exist:}
## Code Simplification Required (HIGH PRIORITY)

**Complex code is technical debt.** These issues significantly impact maintainability and should be addressed.

{If simplificationIssues.critical exist:}
### Critical Complexity (Must Simplify)

These complexity issues are blocking and must be resolved before merge:

{For each simplificationIssues.critical:}
#### {index}. {issue.file}:{issue.line}

**Problem:** {issue.issue}

**Impact:** High complexity increases bug risk and maintenance cost

**Suggested Fix:**
{issue.suggestion}

{End for}
{End if}

{If simplificationIssues.high exist:}
### High Complexity (Should Simplify)

These issues should be addressed for long-term code health:

{For each simplificationIssues.high:}
- **`{issue.file}:{issue.line}`** - {issue.issue}
  - Fix: {issue.suggestion}
{End for}
{End if}

{If simplificationIssues.opportunities exist:}
### Quick Wins

Easy improvements that enhance readability:

{For each simplificationIssues.opportunities:}
- `{issue.file}:{issue.line}` - {issue.issue}
{End for}
{End if}

---
{End if}

{If medium issues exist:}
## Recommendations

Consider addressing these improvements:

{For each medium issue:}
- **{issue.file}:{issue.line}** - {issue.description}
  - Suggestion: {issue.suggestion}
{End for}

---
{End if}

{If low issues exist:}
## Minor Issues

Optional improvements for cleaner code:

{For each low issue:}
- `{issue.file}:{issue.line}` - {issue.description}
{End for}

---
{End if}

{If positives exist:}
## Positive Patterns

Good practices observed in this PR:

{For each positive:}
- {positive.description}
{End for}

---
{End if}

## Requirements Compliance

{If spec context available:}
| Requirement | Status | Notes |
|-------------|--------|-------|
{For each requirement:}
| {req.id} | {PASS/PARTIAL/FAIL} | {notes} |
{End for}

Coverage: {covered}/{total} requirements ({percentage}%)

{Else:}
No specification context available. Run from feature directory for requirements check.
{End if}

---

## Next Steps

{If verdict is BLOCKED:}
### Action Required

1. Fix all {critical_count} critical issues
2. Re-run review: `/spectra:review-pr`

Do not create PR until critical issues are resolved.

{Else if verdict is CHANGES_REQUESTED:}
### Recommended Actions

1. Address high priority issues ({high_count})
2. Consider medium priority suggestions ({medium_count})
3. Re-run review or create PR with comments

{Else if verdict is APPROVED_WITH_COMMENTS:}
### Ready for PR

Issues found are minor. You can:
1. Create PR now and address in follow-up
2. Fix remaining issues then create PR

**Next Steps:**
1. Run `/spectra:accept` to validate feature readiness
2. Run `/spectra:merge --push` to merge and cleanup


{Else:}
### Approved

Code looks good! Ready to merge.

**Next Steps:**
1. Run `/spectra:accept` to validate feature readiness
2. Run `/spectra:merge --push` to merge and cleanup

{End if}
```

### Step 6: Offer Automated Fixes

**6.1: Identify auto-fixable issues**

Some issues can be automatically fixed:
- Formatting issues (via prettier/eslint --fix)
- Import organization
- Simple type annotations
- Unused variable removal

```markdown
## Automated Fixes Available

The following issues can be fixed automatically:

| Issue Type | Count | Auto-fixable |
|------------|-------|--------------|
| Formatting | {count} | Yes |
| Import order | {count} | Yes |
| Lint errors | {count} | Partial |
| Type issues | {count} | Partial |

Would you like to apply auto-fixes? (y/n)
```

**6.2: Apply fixes if confirmed**

```bash
# Run linter auto-fix
npm run lint -- --fix

# Run formatter
npm run format

# Stage fixed files
git add -A
```

**6.3: Report fix results**

```markdown
## Auto-fixes Applied

| Category | Fixed | Remaining |
|----------|-------|-----------|
| Formatting | {count} | 0 |
| Lint errors | {count} | {remaining} |

Files modified:
{For each modified file:}
- `{file_path}`
{End for}

Changes have been staged. Review with `git diff --staged`.
```

### Step 7: Create PR (Optional)

**7.1: Offer to create PR if review passes**

If verdict is APPROVED or APPROVED_WITH_COMMENTS:

```markdown
## Create Pull Request?

The review has passed. Would you like to create a pull request?

**PR Details:**
- **Title:** [Feature] {feature_name or branch_name}
- **Base:** {baseBranch}
- **Head:** {currentBranch}

Options:
1. Create PR now
2. Create PR with review comments included
3. Skip PR creation

Your choice (1/2/3):
```

**7.2: Generate PR description**

```markdown
## Summary

{Auto-generated summary from commits and spec}

## Changes

{For each category of changes:}
### {category}
{For each change:}
- {change_description}
{End for}
{End for}

## Testing

{Testing notes from review}

## Review Notes

{If review had findings:}
The following items were noted during automated review:
{Summary of medium/low issues}
{End if}

## Checklist

- [x] Code review completed (Score: {score}/100)
- [x] All critical issues resolved
- [ ] Manual testing completed
- [ ] Documentation updated

---

Generated by spectra `/review-pr`
```

**7.3: Create PR using gh CLI**

```bash
gh pr create \
  --title "[Feature] {title}" \
  --body "$(cat <<'EOF'
{PR description}
EOF
)" \
  --base {baseBranch} \
  --head {currentBranch}
```

Report PR creation:
```markdown
## Pull Request Created

**PR:** #{pr_number}
**URL:** {pr_url}

The PR has been created and is ready for human review.
```

## Output

Upon completion, this command produces:

### Console Output

| Output | When Displayed |
|--------|----------------|
| Review scope | At command start |
| Agent progress | During each agent review |
| Review report | After all agents complete |
| Fix options | If auto-fixable issues exist |
| PR creation | If user opts to create PR |

### Review Artifacts

| Artifact | Description |
|----------|-------------|
| Review report | Detailed findings in console |
| Fixed files | If auto-fixes applied |
| Pull request | If user creates PR |

## Usage

```
/spectra:review-pr [type]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `full` | Complete review with all agents (default) |
| `quick` | Fast review for critical issues only |
| `security` | Security-focused review |
| `performance` | Performance-focused review |
| `style` | Code style review only |

### Examples

```bash
# Full review (default)
/spectra:review-pr

# Quick review for critical issues
/spectra:review-pr quick

# Security-focused review
/spectra:review-pr security

# Performance analysis
/spectra:review-pr performance

# Style check only
/spectra:review-pr style
```

## Notes

- Review is based on diff from base branch to current branch
- Feature context (spec.md) enhances requirements verification
- Critical issues block PR creation
- Auto-fixes are optional and can be reviewed before commit
- Human review is still recommended after automated review
- Review score provides quick quality indicator

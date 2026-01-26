# Parallel PR Review with Specialized Agents

## Pattern Summary

Run multiple specialized review agents in parallel to perform comprehensive PR reviews efficiently. Each agent focuses on a specific aspect of code quality, and results are aggregated into a single report.

## When to Use

- Before creating a pull request
- After completing a feature implementation
- When reviewing large changesets (50+ files)
- When multiple quality aspects need verification

## Implementation

### 1. Identify Review Scope

```bash
# Get changed files compared to main
git diff --name-only main...HEAD

# Get current status
git status --porcelain
```

### 2. Select Applicable Agents

Based on file types changed:
- **Shell scripts (.sh)** → code-reviewer, silent-failure-hunter, code-simplifier
- **Documentation (.md)** → comment-analyzer
- **Type definitions** → type-design-analyzer
- **Test files** → pr-test-analyzer

### 3. Launch Agents in Parallel

Use the Task tool with multiple invocations in a single message:

```
Task tool #1:
  subagent_type: "feature-dev:code-reviewer"
  description: "Review code quality"
  prompt: "Review the following files for quality issues..."

Task tool #2:
  subagent_type: "feature-dev:code-reviewer"
  description: "Hunt silent failures"
  prompt: "Review error handling in shell scripts..."

Task tool #3:
  subagent_type: "feature-dev:code-reviewer"
  description: "Analyze documentation"
  prompt: "Check documentation accuracy..."
```

### 4. Aggregate Results

Combine findings from all agents into a single report with:
- Status table by review aspect
- Critical issues (must fix)
- Important issues (should fix)
- Suggestions (nice to have)
- Constitution compliance check
- Strengths observed

### 5. Save Report

Write to `{FEATURE_DIR}/checklists/pr-review-report.md`

## Key Insights

1. **Parallel execution saves time**: 4 agents complete faster than sequential
2. **Specialized focus finds more issues**: Each agent has deep expertise
3. **Aggregation provides clarity**: Single report easier to action
4. **Constitution integration ensures compliance**: Project principles checked throughout

## Example Prompt Structure

For each agent, provide:
1. Clear list of files to review
2. Specific focus areas
3. Relevant constitution excerpts
4. Expected output format
5. Confidence threshold (recommend 80+)

## Related Skills

- `large-scale-codebase-rename.md` - For understanding rename scope
- `codebase-rename-planning.md` - For planning comprehensive changes

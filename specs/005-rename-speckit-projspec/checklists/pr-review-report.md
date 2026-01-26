# PR Review Summary

**Feature**: 005-rename-speckit-projspec
**Branch**: 005-rename-speckit-projspec
**Files Changed**: 74
**Review Date**: 2026-01-26

## Overall Status

| Review Aspect | Status | Critical | Important | Suggestions |
|---------------|--------|----------|-----------|-------------|
| Code Quality  | ⚠      | 5        | 1         | 0           |
| Error Handling| ⚠      | 1        | 4         | 0           |
| Documentation | ⚠      | 4        | 2         | 0           |
| Code Clarity  | ✓      | 0        | 4         | 2           |

**Legend**: ✓ Pass | ⚠ Pass with warnings | ✗ Needs attention

---

## Critical Issues (Must Fix Before PR)

### 1. Incomplete Rename in `.specify/` Directory Files

**Location**: `.specify/scripts/bash/check-prerequisites.sh` (lines 105, 111, 118)
```bash
# Current (incorrect):
echo "Run /speckit.specify first to create the feature structure." >&2
echo "Run /speckit.plan first to create the implementation plan." >&2
echo "Run /speckit.tasks first to create the task list." >&2

# Required:
echo "Run /projspec.specify first to create the feature structure." >&2
echo "Run /projspec.plan first to create the implementation plan." >&2
echo "Run /projspec.tasks first to create the task list." >&2
```

### 2. Incomplete Rename in `.specify/scripts/bash/setup-hooks.sh`

**Location**: Lines 63, 239, 266, 267
```bash
# Current (incorrect):
# Check if we're in the spec-kit repo itself
log_error "Template directory not found. Run from spec-kit repo or after 'specify init'."
log_info "  3. Use /speckit.learn to extract patterns"
log_info "  4. Use /speckit.checkpoint to save state"

# Required:
# Check if we're in the projspec repo itself
log_error "Template directory not found. Run from projspec repo or after 'specify init'."
log_info "  3. Use /projspec.learn to extract patterns"
log_info "  4. Use /projspec.checkpoint to save state"
```

### 3. Template Files Contain Old Command References

**Locations**:
- `.specify/templates/plan-template.md` (lines 6, 42-47) - 8 `/speckit.*` references
- `.specify/templates/checklist-template.md` (lines 7, 13) - 2 `/speckit.*` references
- `.specify/templates/tasks-template.md` (line 32) - 1 `/speckit.*` reference

All `/speckit.*` command references must be updated to `/projspec.*`.

### 4. CLAUDE.md Has Truncated Technology Descriptions

**Location**: `CLAUDE.md` (lines 6, 31)
```markdown
# Current (truncated):
- Bash 5.x (scripts), Markdown (commands/agents/skills) + Claude Code plugin system, Gi (005-rename-speckit-projspec)

# Required:
- Bash 5.x (scripts), Markdown (commands/agents/skills) + Claude Code plugin system, Git, GitHub CLI (optional for issues) (005-rename-speckit-projspec)
```

### 5. Temporary File Cleanup Not Guaranteed

**Location**: `projspec/plugins/projspec/scripts/update-agent-context.sh` (lines 271, 342)

Temporary files created with `mktemp` are not cleaned up if the script fails between creation and removal.

**Fix**: Add trap handler at the start of main():
```bash
trap 'rm -f "$temp_file" 2>/dev/null' EXIT ERR INT TERM
```

---

## Important Issues (Should Fix)

### 1. Silent Directory Creation Failures

**Location**: `projspec/plugins/projspec/scripts/setup-hooks.sh` (lines 120-123)

`mkdir -p` commands have no error checking. Should add `|| error "message"` pattern.

### 2. Inadequate Copy Operation Error Reporting

**Location**: `projspec/plugins/projspec/scripts/setup-hooks.sh` (lines 138-146, 157-159)

Copy operations use `2>/dev/null` which swallows errors. Users may think setup succeeded when files failed to copy.

### 3. Missing File Write Validation

**Location**: `projspec/plugins/projspec/scripts/setup-hooks.sh` (lines 171-194, 207-230)

Heredoc write operations (`cat > file`) have no error checking.

### 4. Grep Extraction Without Structure Validation

**Location**: `projspec/plugins/projspec/scripts/update-agent-context.sh` (lines 89-93, 109-114, 124-128)

Grep operations assume plan.md has expected structure without validation.

### 5. Historical "spec-kit" Reference in CLAUDE.md

**Location**: `CLAUDE.md` (line 10)
```markdown
(matching spec-kit's CLI stack)
```
Consider updating to "projspec's CLI stack" for consistency.

### 6. Redundant Error Handling Pattern

**Location**: Multiple files (check-prerequisites.sh, setup-plan.sh)

Duplicate `if JSON_OUTPUT then json_error else error` pattern could be consolidated into single `error()` function.

---

## Suggestions (Nice to Have)

### 1. Consolidate JSON Escaping Logic

Three different JSON escaping implementations exist. Consider creating a single `json_escape()` function.

### 2. Simplify `slugify()` Function

The word-counting logic in `common.sh` (lines 229-248) uses complex `tr | wc` pipeline. Could use simpler bash string manipulation.

---

## Constitution Compliance

- ✓ **Maintainability First**: Code is generally clear and well-structured
- ⚠ **Documentation as Code**: Template documentation has outdated command references
- ✓ **Incremental Delivery**: Changes are well-decomposed and reviewable
- ✓ **Test-Driven Confidence**: N/A (no test files in this rename PR)
- ⚠ **Code Review**: This review identified issues requiring attention

---

## Strengths

1. **Comprehensive Rename**: The core `projspec/` directory is fully renamed with no remaining "speckit" references
2. **Well-Structured Scripts**: All scripts use `set -euo pipefail` and have proper error handling patterns
3. **Clear Documentation**: README.md, TESTING.md, VERIFICATION.md are properly updated
4. **Good Organization**: Plugin structure follows Claude Code conventions correctly
5. **JSON Output Support**: All scripts support both human-readable and JSON output modes

---

## Files Verified Clean

The following directories have been verified to contain no remaining "speckit" references:
- ✅ `projspec/` - All 52 files clean
- ✅ `.claude/commands/` - All 14 command files use `/projspec.*`
- ✅ `projspec/plugins/projspec/` - Properly renamed

---

## Next Steps

### Before Creating PR:

1. **Fix Critical Issues** (5 items):
   - Update `.specify/scripts/bash/check-prerequisites.sh` - 3 command references
   - Update `.specify/scripts/bash/setup-hooks.sh` - 4 references
   - Update `.specify/templates/*.md` - 11 command references total
   - Fix `CLAUDE.md` truncated descriptions
   - Add temp file cleanup trap to `update-agent-context.sh`

2. **Consider Important Issues** (6 items):
   - Add error checking to file operations in setup-hooks.sh
   - Validate plan.md structure before extraction
   - Update historical "spec-kit" reference

### After Fixing:

Run `/projspec.review-pr` again to verify all issues are resolved, then proceed with PR creation.

---

## Review Metadata

| Reviewer | Agent Type | Model |
|----------|------------|-------|
| code-reviewer | feature-dev:code-reviewer | sonnet |
| silent-failure-hunter | feature-dev:code-reviewer | sonnet |
| comment-analyzer | feature-dev:code-reviewer | sonnet |
| code-simplifier | feature-dev:code-reviewer | sonnet |

**Review Mode**: Parallel
**Total Issues**: 11 Critical + 6 Important + 2 Suggestions = 19 findings

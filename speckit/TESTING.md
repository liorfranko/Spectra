# speckit Manual Testing Checklists

This document provides manual testing checklists for verifying speckit functionality (tasks T088-T091).

**Generated:** 2026-01-26
**Version:** 1.0.0

---

## T088: Core Workflow Testing

### Test: specify -> plan -> tasks -> implement

This test verifies the complete development workflow from specification to implementation.

#### Prerequisites

- [ ] Claude Code CLI installed and working
- [ ] speckit plugin loaded (`claude --plugin-dir /path/to/speckit`)
- [ ] Git repository initialized
- [ ] Clean working directory (no uncommitted changes)

#### Test Steps

##### 1. Specify Command

```bash
/speckit.specify create a simple CLI tool that converts markdown to HTML
```

**Expected Results:**
- [ ] Command executes without error
- [ ] `specs/{feature-id}/spec.md` file created
- [ ] spec.md contains:
  - [ ] User Scenarios section with US-### format
  - [ ] Functional Requirements section with FR-### format
  - [ ] Success Criteria section with SC-### format
  - [ ] Edge Cases section
  - [ ] Assumptions section
- [ ] Next steps guidance displayed suggesting `/speckit.plan`

##### 2. Plan Command

```bash
/speckit.plan
```

**Expected Results:**
- [ ] Command executes without error
- [ ] `plan.md` file created in feature directory
- [ ] plan.md contains:
  - [ ] Technical Context section
  - [ ] Constitution Check section
  - [ ] Project Structure section
  - [ ] Implementation phases
- [ ] Next steps guidance displayed suggesting `/speckit.tasks`

##### 3. Tasks Command

```bash
/speckit.tasks
```

**Expected Results:**
- [ ] Command executes without error
- [ ] `tasks.md` file created in feature directory
- [ ] tasks.md contains:
  - [ ] Tasks organized by phase
  - [ ] Task IDs in T### format
  - [ ] Dependencies documented
  - [ ] Status markers ([ ] for pending)
- [ ] Next steps guidance displayed suggesting `/speckit.implement`

##### 4. Implement Command

```bash
/speckit.implement
```

**Expected Results:**
- [ ] Command identifies first pending task
- [ ] Task details displayed
- [ ] Implementation guidance provided
- [ ] After implementation:
  - [ ] Task status updated to [x]
  - [ ] Changes committed (if configured)
  - [ ] Next task suggested

##### 5. Workflow Completion

**Verification:**
- [ ] All artifacts created in correct directory structure
- [ ] Traceability maintained between artifacts
- [ ] No orphaned references (all FR-### referenced in tasks, etc.)

---

## T089: GitHub Issues Integration Testing

### Test: taskstoissues Command

This test verifies GitHub issue creation from tasks.

#### Prerequisites

- [ ] GitHub CLI installed (`gh --version`)
- [ ] GitHub CLI authenticated (`gh auth status`)
- [ ] Repository connected to GitHub remote
- [ ] tasks.md exists with pending tasks

#### Test Steps

##### 1. Check Prerequisites

```bash
gh auth status
```

**Expected Results:**
- [ ] Shows authenticated user
- [ ] Shows correct account

##### 2. Run taskstoissues Command

```bash
/speckit.taskstoissues
```

**Expected Results:**
- [ ] Command executes without error (or clear error if not authenticated)
- [ ] Preview of issues to be created displayed
- [ ] User confirmation requested before creation

##### 3. Verify Issue Creation

```bash
gh issue list
```

**Expected Results:**
- [ ] Issues created for each task
- [ ] Issue titles match task titles
- [ ] Issue bodies contain:
  - [ ] Task description
  - [ ] Acceptance criteria
  - [ ] Dependency references
- [ ] Labels applied correctly
- [ ] Milestone assigned (if configured)

##### 4. Error Handling

**Test: No GitHub CLI**
- [ ] Remove gh from PATH temporarily
- [ ] Run `/speckit.taskstoissues`
- [ ] Verify clear error message about GitHub CLI requirement

**Test: No Authentication**
- [ ] Run `gh auth logout`
- [ ] Run `/speckit.taskstoissues`
- [ ] Verify clear error message about authentication

**Test: No tasks.md**
- [ ] Navigate to directory without tasks.md
- [ ] Run `/speckit.taskstoissues`
- [ ] Verify clear error message suggesting `/speckit.tasks`

---

## T090: Clarify and Analyze Commands Testing

### Test: clarify Command

This test verifies the clarification workflow.

#### Prerequisites

- [ ] spec.md exists with some ambiguous areas
- [ ] Feature directory context established

#### Test Steps

##### 1. Run Clarify Command

```bash
/speckit.clarify
```

**Expected Results:**
- [ ] Command analyzes spec.md
- [ ] Up to 5 clarification questions generated
- [ ] Questions are relevant to ambiguous areas
- [ ] Interactive prompts for answers

##### 2. Answer Questions

Provide answers to each clarification question.

**Expected Results:**
- [ ] Answers acknowledged
- [ ] spec.md updated with clarifications
- [ ] `[NEEDS CLARIFICATION]` markers reduced
- [ ] Next steps guidance displayed

##### 3. Verify Updates

Read updated spec.md.

**Expected Results:**
- [ ] Clarifications encoded in appropriate sections
- [ ] Original structure preserved
- [ ] No data loss

### Test: analyze Command

This test verifies cross-artifact analysis.

#### Prerequisites

- [ ] spec.md exists
- [ ] plan.md exists
- [ ] tasks.md exists

#### Test Steps

##### 1. Run Analyze Command

```bash
/speckit.analyze
```

**Expected Results:**
- [ ] Command executes without error
- [ ] Analysis report generated with:
  - [ ] Consistency checks between artifacts
  - [ ] Traceability verification
  - [ ] Quality assessment
  - [ ] Identified issues (if any)

##### 2. Verify Analysis Categories

**Expected Analysis:**
- [ ] Spec-to-Plan consistency
- [ ] Plan-to-Tasks traceability
- [ ] Requirement coverage
- [ ] Missing elements identified
- [ ] Recommendations provided

##### 3. Error Handling

**Test: Missing artifacts**
- [ ] Remove plan.md temporarily
- [ ] Run `/speckit.analyze`
- [ ] Verify graceful handling (analyze what exists)

---

## T091: Installation and First-Use Guide Verification

### Test: Fresh Installation

This test verifies the installation process and first-use experience.

#### Prerequisites

- [ ] Clean environment (no previous speckit installation)
- [ ] Claude Code CLI installed

#### Test Steps

##### 1. Plugin Installation

```bash
claude --plugin-dir /path/to/speckit
```

**Expected Results:**
- [ ] No error messages during load
- [ ] Plugin recognized and loaded

##### 2. Verify Commands Available

```bash
# In Claude Code session
/help
```

**Expected Results:**
- [ ] speckit commands listed
- [ ] All 13 commands visible:
  - [ ] /speckit.specify
  - [ ] /speckit.clarify
  - [ ] /speckit.plan
  - [ ] /speckit.tasks
  - [ ] /speckit.implement
  - [ ] /speckit.taskstoissues
  - [ ] /speckit.validate
  - [ ] /speckit.checklist
  - [ ] /speckit.analyze
  - [ ] /speckit.review-pr
  - [ ] /speckit.constitution

##### 3. First Command Execution

```bash
/speckit.specify
```

**Expected Results:**
- [ ] Command executes or prompts for input
- [ ] No cryptic errors
- [ ] Clear guidance provided

##### 4. README Verification

Review README.md for accuracy:

- [ ] Prerequisites listed correctly
- [ ] Installation instructions work
- [ ] Quick Start guide accurate
- [ ] Command reference complete
- [ ] Examples work as documented

##### 5. Error Message Quality

Test various error conditions:

**Test: No git repository**
```bash
cd /tmp && mkdir test && cd test
/speckit.specify
```
- [ ] Clear error about git requirement

**Test: Missing prerequisites**
```bash
/speckit.plan  # Without spec.md
```
- [ ] Clear error about missing spec.md
- [ ] Suggests running /speckit.specify

---

## Test Results Template

### Test Session Information

| Field | Value |
|-------|-------|
| Date | YYYY-MM-DD |
| Tester | Name |
| speckit Version | 1.0.0 |
| Claude Code Version | X.X.X |
| Platform | macOS/Linux |

### Summary

| Test Suite | Pass | Fail | Skip |
|------------|------|------|------|
| T088: Core Workflow | /5 | /5 | /5 |
| T089: GitHub Integration | /5 | /5 | /5 |
| T090: Clarify/Analyze | /5 | /5 | /5 |
| T091: Installation | /5 | /5 | /5 |

### Issues Found

| # | Test | Issue Description | Severity | Status |
|---|------|-------------------|----------|--------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

### Notes

(Add any observations, edge cases discovered, or improvement suggestions)

---

## Regression Testing

### Quick Smoke Test

After any changes, run this minimal test:

1. [ ] `/speckit.specify "test feature"` - Creates spec.md
2. [ ] `/speckit.plan` - Creates plan.md
3. [ ] `/speckit.tasks` - Creates tasks.md
4. [ ] `/speckit.validate` - Validates all artifacts

**Pass Criteria:** All commands complete without error, artifacts created correctly.

---

*This testing document was generated for speckit Polish phase tasks T088-T091.*

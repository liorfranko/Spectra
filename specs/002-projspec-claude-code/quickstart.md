# Quickstart: ProjSpec Validation Scenarios

**Feature**: 002-projspec-claude-code
**Date**: 2026-01-26

## Purpose

This document provides validation scenarios to verify the implementation works correctly. Each scenario can be tested independently.

---

## Scenario 1: Initialize a New Project

**User Story**: US1 - Initialize a New Project with Spec-Driven Workflow

### Steps

```bash
# Create a new project directory
mkdir my-project && cd my-project

# Initialize git (required)
git init

# Install projspec
uv tool install projspec-cli  # or pip install projspec-cli

# Initialize ProjSpec
projspec init
```

### Expected Results

1. Directory structure created:
```
my-project/
├── .specify/
│   ├── config.yaml
│   ├── memory/
│   │   └── constitution.md
│   ├── scripts/
│   │   └── bash/
│   │       ├── common.sh
│   │       ├── check-prerequisites.sh
│   │       ├── create-new-feature.sh
│   │       ├── setup-plan.sh
│   │       ├── archive-feature.sh
│   │       └── update-agent-context.sh
│   └── templates/
│       ├── spec-template.md
│       ├── plan-template.md
│       ├── tasks-template.md
│       └── checklist-template.md
├── specs/                     # Feature specifications (shared)
├── worktrees/                 # Feature worktrees (created per feature)
└── CLAUDE.md
```

2. Success message displayed with worktree information
3. Exit code 0

### Edge Cases

- **Already initialized**: Running `projspec init` again shows warning, doesn't overwrite
- **Not a git repo**: Shows error suggesting `git init`
- **With --no-git**: Initializes without git checks

---

## Scenario 2: Create a Feature Specification

**User Story**: US2 - Create Feature Specifications from Natural Language

### Steps

```bash
# In Claude Code (from main repo), ask:
"Read .specify/templates/commands/specify.md and follow those instructions"

# Provide feature description:
"I want to add user authentication with email/password login and password reset"
```

### Expected Results

1. Git worktree created: `worktrees/001-user-auth/`
2. Git branch created: `001-user-auth`
3. Feature spec directory created: `specs/001-user-auth/`
4. Symlinks created in worktree:
   - `worktrees/001-user-auth/specs -> ../../specs`
   - `worktrees/001-user-auth/.specify -> ../../.specify`
5. Files created:
   - `specs/001-user-auth/spec.md` with all sections filled
   - `specs/001-user-auth/state.yaml` with phase: spec
6. Spec contains:
   - User stories with priorities
   - Acceptance scenarios (Given/When/Then)
   - Functional requirements
   - Key entities
   - Success criteria
7. Output instructs user to open Claude Code in worktree:
   ```
   ✓ Created worktree: worktrees/001-user-auth
   ✓ Created branch: 001-user-auth

   To continue working on this feature:
     cd worktrees/001-user-auth && claude
   ```

### Validation Checklist

- [ ] Feature number is sequential (001, 002, ...)
- [ ] Branch name follows pattern: `NNN-slug`
- [ ] Worktree created at correct path
- [ ] Symlinks work correctly
- [ ] Spec has all mandatory sections
- [ ] User stories have priorities (P1, P2, P3)
- [ ] Each user story has acceptance scenarios

---

## Scenario 3: Handle Ambiguous Requirements

**User Story**: US2 - Clarification for ambiguous descriptions

### Steps

```bash
# In Claude Code, ask:
"Read .specify/templates/commands/specify.md and follow those instructions"

# Provide vague description:
"Add login"
```

### Expected Results

1. System identifies ambiguity
2. Asks targeted clarifying questions (max 3):
   - "What authentication methods should be supported?"
   - "Should users be able to reset passwords?"
   - "Are there any roles or permissions needed?"
3. Updates spec with concrete answers

### Validation Checklist

- [ ] Maximum 3 questions asked
- [ ] Questions are specific, not open-ended
- [ ] Answers are incorporated into spec

---

## Scenario 4: Generate Implementation Plan

**User Story**: US3 - Generate Implementation Plans from Specifications

### Steps

```bash
# Ensure spec.md exists and is complete
# In Claude Code, ask:
"Read .specify/templates/commands/plan.md and follow those instructions"
```

### Expected Results

1. Files created:
   - `plan.md` - Technical implementation plan
   - `research.md` - Technology decisions
   - `data-model.md` - Entity definitions
   - `quickstart.md` - Validation scenarios
   - `contracts/` - API contracts
2. State updated: phase: plan
3. CLAUDE.md updated with new technologies

### Validation Checklist

- [ ] Plan references spec requirements
- [ ] Technical context is complete (no NEEDS CLARIFICATION)
- [ ] Constitution check passes
- [ ] Project structure is defined
- [ ] Research decisions documented with rationale

---

## Scenario 5: Generate Task Breakdown

**User Story**: US4 - Generate Actionable Tasks from Plans

### Steps

```bash
# Ensure plan.md exists
# In Claude Code, ask:
"Read .specify/templates/commands/tasks.md and follow those instructions"
```

### Expected Results

1. `tasks.md` created with phased structure:
   - Phase 0: Setup
   - Phase 1: Foundation
   - Phase 2: User Stories (P1)
   - Phase 3: User Stories (P2/P3)
   - Phase 4: Polish
2. State updated with task list
3. Each task has:
   - Unique ID (T001, T002, ...)
   - Priority (P1, P2, P3)
   - Dependencies
   - Context files

### Validation Checklist

- [ ] Tasks are in dependency order
- [ ] P1 user stories before P2/P3
- [ ] Task dependencies are valid (no circular refs)
- [ ] Each task is specific and actionable

---

## Scenario 6: Implement Tasks Sequentially

**User Story**: US5 - Execute Implementation Based on Tasks

### Steps

```bash
# Ensure tasks.md exists with pending tasks
# In Claude Code, ask:
"Read .specify/templates/commands/implement.md and follow those instructions"
```

### Expected Results

1. Next ready task identified (dependencies satisfied)
2. Context loaded:
   - Feature spec
   - Implementation plan
   - Previous task summaries
3. Task marked `in_progress`
4. Implementation guidance provided
5. On completion:
   - 3-5 bullet summary generated
   - Task marked `completed`
   - Next task presented

### Validation Checklist

- [ ] Only tasks with satisfied dependencies are started
- [ ] Context includes all previous summaries
- [ ] Summary captures key changes
- [ ] Progress persists across sessions

---

## Scenario 7: Resume Interrupted Work

**User Story**: Related to US5 - Session continuity

### Steps

```bash
# Start implementing a feature
# Ask: "Read .specify/templates/commands/implement.md and follow those instructions"

# Close terminal (simulate interruption)
# Reopen and ask the same:
# "Read .specify/templates/commands/implement.md and follow those instructions"
```

### Expected Results

1. System detects in-progress task
2. Resumes from last state
3. Context is fully restored

### Validation Checklist

- [ ] In-progress task identified
- [ ] No duplicate work
- [ ] Context fully restored

---

## Scenario 8: Project Status Check

**Related**: FR-002 status command

### Steps

```bash
projspec status
```

### Expected Results

```
╭─ ProjSpec Status ─────────────────────────────────────────────╮
│                                                                │
│  Active Features: 1                                            │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ 001-user-auth                                            │  │
│  │ Phase: implement  │  Tasks: 3/8                          │  │
│  │ Worktree: worktrees/001-user-auth                        │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
╰────────────────────────────────────────────────────────────────╯
```

### Validation Checklist

- [ ] All active features listed
- [ ] Phase correctly displayed
- [ ] Task progress accurate
- [ ] Worktree path displayed
- [ ] JSON output works with `--json`

---

## Scenario 9: Convert Tasks to GitHub Issues

**User Story**: US4 - Tasks to GitHub issues

### Steps

```bash
# Ensure tasks.md exists
# In Claude Code, ask:
"Read .specify/templates/commands/taskstoissues.md and follow those instructions"
```

### Expected Results

1. GitHub issues created for each task
2. Dependencies represented as issue links
3. Labels applied (priority, phase)
4. Parent issue created for feature

### Validation Checklist

- [ ] Issues created successfully
- [ ] Dependencies linked
- [ ] Labels applied
- [ ] Handles network failures gracefully

---

## Scenario 10: Prevent Accidental Overwrites

**Related**: FR-014

### Steps

```bash
# Initialize project
projspec init

# Try to initialize again
projspec init
```

### Expected Results

1. Warning message displayed
2. No files overwritten
3. User can force with `--force` if needed

### Validation Checklist

- [ ] Warning shown for existing init
- [ ] No data loss
- [ ] `--force` bypasses warning

---

## End-to-End Workflow Test

### Full Cycle

```bash
# 1. Initialize project
mkdir test-project && cd test-project
git init && git commit --allow-empty -m "Initial commit"
projspec init

# 2. Create feature spec (from main repo)
# In Claude Code, ask: "Read .specify/templates/commands/specify.md and follow those instructions"
# Input: "Add a simple counter that can increment and decrement"
# This creates worktree at worktrees/001-counter/

# 3. Switch to feature worktree
cd worktrees/001-counter

# 4. Generate plan (from worktree)
# In Claude Code, ask: "Read .specify/templates/commands/plan.md and follow those instructions"

# 5. Generate tasks
# In Claude Code, ask: "Read .specify/templates/commands/tasks.md and follow those instructions"

# 6. Implement (work happens in the worktree)
# In Claude Code, ask: "Read .specify/templates/commands/implement.md and follow those instructions"
# (Complete all tasks - source code is in this worktree)

# 7. Verify from main repo
cd ../..  # Back to main repo
projspec status
# Phase should be: implement or review
# All tasks should be completed

# 8. Archive feature (merge and cleanup worktree)
.specify/scripts/bash/archive-feature.sh --feature 001
# Merges to main, removes worktree, preserves specs
```

### Success Criteria

- [ ] Entire workflow completes without errors
- [ ] Worktree created and isolated correctly
- [ ] Symlinks to specs/ and .specify/ work
- [ ] All artifacts generated correctly
- [ ] State persists across sessions
- [ ] Commands are familiar to spec-kit users (SC-010)

<div align="center">

# 📋 Spectra

### Complete Plugin Documentation

[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-7C3AED?style=flat-square)](https://github.com/anthropics/claude-code)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](../LICENSE)

**Specification-driven development workflow automation for Claude Code**

</div>

---

Spectra provides a structured approach to feature development by guiding you through specification, planning, task generation, and implementation phases. It ensures consistency and traceability throughout the development lifecycle.

## 📋 Table of Contents

- [Prerequisites](#️-prerequisites)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Commands Reference](#-commands-reference)
- [Agents Reference](#-agents-reference)
- [Workflow Overview](#-workflow-overview)
- [Feature Directory Structure](#-feature-directory-structure)
- [Git Worktree Integration](#-git-worktree-integration)

---

## ⚙️ Prerequisites

| Requirement | Description |
|-------------|-------------|
| **Claude Code CLI** | The Claude Code command-line interface |
| **Git** | Version control (repository must be initialized) |
| **macOS or Linux** | Currently supported platforms |
| **GitHub CLI** | Optional — required for `/spectra.issues` command |

---

## 📦 Installation

Install directly in Claude Code:

```
/plugin install spectra@claude-plugin-directory
```

Or browse available plugins:

```bash
/plugin > Discover
```

---

## 🚀 Quick Start

### 1️⃣ Create a Specification

Define your feature requirements:

```
/spectra.specify my new feature that handles user authentication
```

This creates a structured specification with user scenarios, functional requirements, and success criteria.

### 2️⃣ Clarify Requirements (Optional)

Identify and resolve ambiguous areas:

```
/spectra.clarify
```

Asks up to 5 targeted questions and encodes answers back into the spec.

### 3️⃣ Generate a Plan

Create an implementation plan from your spec:

```
/spectra.plan
```

This produces a detailed design with architecture decisions and constitution compliance checks.

### 4️⃣ Generate Tasks

Break down the plan into actionable tasks:

```
/spectra.tasks
```

Creates a dependency-ordered task list ready for implementation.

### 5️⃣ Implement

Execute the implementation plan:

```
/spectra.implement           # Agent mode with smart grouping (default)
/spectra.implement --direct  # Direct mode (sequential, no agents)
```

Processes and executes all tasks defined in tasks.md. Agent mode uses smart grouping to batch related tasks into a single agent context while preserving per-task commits. Use `--direct` for simpler sequential execution without agents.

### 6️⃣ Review Before PR

Run comprehensive code review:

```
/spectra.review-pr
```

Uses specialized agents to ensure code quality before PR creation.

---

## 📖 Commands Reference

Spectra includes 12 commands for the complete development workflow.

### 🔄 Core Workflow Commands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `/spectra.specify` | Create or update feature spec with requirements and success criteria | Feature description or empty for interactive |
| `/spectra.clarify` | Identify underspecified areas and ask up to 5 targeted clarification questions | None |
| `/spectra.plan` | Generate implementation plan with constitution compliance | None |
| `/spectra.tasks` | Generate structured, dependency-ordered task list from plan | None |
| `/spectra.implement` | Implement tasks from task list with guided workflow | `--agent`, `--direct`, or Task ID |

### ✅ Quality & Delivery Commands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `/spectra.analyze` | Perform cross-artifact consistency and quality analysis | None |
| `/spectra.review-pr` | Comprehensive PR review using specialized agents | `full`, `quick`, `security`, `performance`, `style` |
| `/spectra.accept` | Validate feature readiness before merge | `--lenient`, `--skip-tests` |
| `/spectra.merge` | Merge feature branch into main and cleanup | `--push`, `--squash`, `--keep-branch` |

### ⚙️ Configuration & Lifecycle Commands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `/spectra.constitution` | Create or update project constitution with foundational principles | `interactive`, `add "principle"`, `update`, or empty |
| `/spectra.cancel` | Cancel feature and cleanup resources (branch, worktree) | `--delete`, `--force`, `--reason` |
| `/spectra.issues` | Convert tasks into GitHub issues (requires GitHub CLI) | None |

---

## 📝 Command Details & Examples

### /spectra.specify

Create or update a feature specification from a natural language description.

```bash
# Interactive mode
/spectra.specify

# With feature description
/spectra.specify implement user authentication with OAuth support

# Update existing spec
/spectra.specify  # Then follow prompts to update
```

**Output:** Creates `spec.md` with user scenarios, functional requirements, success criteria, and edge cases.

---

### /spectra.clarify

Identify underspecified areas and ask targeted clarification questions.

```bash
/spectra.clarify
```

**Behavior:** Analyzes current spec.md, identifies up to 5 areas needing clarification, asks questions interactively, and updates the spec with answers.

---

### /spectra.plan

Generate an implementation plan with constitution compliance checks.

```bash
/spectra.plan
```

**Prerequisites:** Requires `spec.md` to exist.

**Output:** Creates `plan.md` with technical context, constitution check, project structure, and implementation phases.

---

### /spectra.tasks

Generate a structured, dependency-ordered task list from the implementation plan.

```bash
/spectra.tasks
```

**Prerequisites:** Requires `plan.md` to exist.

**Output:** Creates `tasks.md` with phased tasks, dependencies, and acceptance criteria.

---

### /spectra.implement

Execute the implementation plan by processing tasks. Supports two execution modes:

| Mode | Flag | Description |
|------|------|-------------|
| **Agent** (default) | `--agent` | Uses smart grouping to batch related tasks by phase/user story into single agent contexts. Each task still gets its own commit. |
| **Direct** | `--direct` | Executes tasks sequentially in current context. Simpler for small task sets. |

```bash
# Agent mode (default) - smart grouping enabled
/spectra.implement
/spectra.implement --agent

# Direct mode - sequential, no agents
/spectra.implement --direct

# Implement specific task
/spectra.implement T015
```

**Prerequisites:** Requires `tasks.md` to exist.

**Behavior:**
- Processes tasks in dependency order
- Each task produces exactly one commit: `[T###] Description`
- Updates task checkboxes after successful commit
- Agent mode: Groups tasks by phase and user story, spawns one agent per group
- Direct mode: Executes all tasks sequentially in current context

**Smart Grouping (Agent Mode):**
- Groups tasks by phase boundaries (Setup, Foundational, User Stories, Polish)
- Within phases, groups by user story (`[US1]`, `[US2]`, etc.)
- Maximum 5-7 tasks per group to avoid context overload
- One agent per group, but each task still gets its own commit
- Push happens after each group completes (not after each task)

**Mode Comparison:**

| Aspect | Agent Mode | Direct Mode |
|--------|------------|-------------|
| Execution | Grouped by phase/story | Sequential only |
| Context | Shared within group | Accumulated |
| Commits | Per task | Per task |
| Push | Per group | Per task |
| Use case | Complex features with many tasks | Simple, small task sets |

---

### /spectra.issues

Convert tasks into actionable GitHub issues.

```bash
/spectra.issues
```

**Prerequisites:** Requires `tasks.md` and GitHub CLI (`gh`) authenticated.

**Output:** Creates GitHub issues with proper labels, descriptions, and dependency references.

---

### /spectra.checklist

Generate a custom checklist for the current feature.

```bash
/spectra.checklist requirements
/spectra.checklist implementation
```

**Output:** Creates checklists based on spec requirements and project constitution.

---

### /spectra.analyze

Perform cross-artifact consistency and quality analysis.

```bash
/spectra.analyze
```

**Behavior:** Analyzes spec.md, plan.md, and tasks.md for consistency, missing traceability, and quality issues.

---

### /spectra.review-pr

Comprehensive pull request review using specialized agents.

```bash
# Full review (default)
/spectra.review-pr

# Quick review for critical issues
/spectra.review-pr quick

# Security-focused review
/spectra.review-pr security

# Performance analysis
/spectra.review-pr performance

# Style check only
/spectra.review-pr style
```

**Review agents invoked:**
- Critical Issues Agent - Blocking problems
- Security Review Agent - Vulnerabilities
- Code Quality Agent - Maintainability
- Requirements Agent - Spec compliance
- Performance Agent - Optimization
- Style Agent - Formatting

**Output:** Review report with score, findings by severity, and fix suggestions.

---

### /spectra.constitution

Create or update the project constitution with foundational principles.

```bash
# View current constitution
/spectra.constitution

# Interactive creation/update
/spectra.constitution interactive

# Add a specific principle
/spectra.constitution add "All API endpoints must have rate limiting"

# Update existing
/spectra.constitution update
```

**Output:** Creates/updates `.spectra/memory/constitution.md` with principles, constraints, quality gates, and governance rules.

---

### /spectra.accept

Validate that a feature is ready for merge by checking task completion, running quality gates, and confirming acceptance criteria.

```bash
# Standard acceptance check
/spectra.accept

# Lenient mode (allows minor issues)
/spectra.accept --lenient

# Skip test execution
/spectra.accept --skip-tests
```

**Prerequisites:** Requires `tasks.md` to exist, must be on a feature branch.

**Checks performed:**
- All tasks marked complete [X]
- Required documents exist (spec.md, plan.md, tasks.md)
- No unresolved markers (TODO, FIXME, TBD)
- Git state is clean
- Tests pass (if detected)
- No merge conflicts with base branch

**Output:** Validation report with pass/fail status and recommended next steps.

---

### /spectra.merge

Merge a completed feature branch into main and cleanup resources.

```bash
# Standard merge
/spectra.merge

# Merge and push to remote
/spectra.merge --push

# Squash commits into one
/spectra.merge --squash --push

# Preview without executing
/spectra.merge --dry-run

# Keep branch after merge
/spectra.merge --push --keep-branch
```

**Prerequisites:** Should have passed `/spectra.accept` first.

**Behavior:**
- Merges feature branch into main/master
- Optionally pushes to remote (`--push`)
- Cleans up local and remote feature branch
- Removes associated worktree

**Options:** `--push`, `--squash`, `--rebase`, `--keep-branch`, `--keep-worktree`, `--dry-run`

---

### /spectra.cancel

Cancel a feature that you decided not to develop and cleanup resources.

```bash
# Cancel current feature (keep spec files)
/spectra.cancel

# Cancel and delete everything
/spectra.cancel --delete

# Cancel with reason
/spectra.cancel --reason "Requirements changed"

# Force cancel without prompts
/spectra.cancel --force
```

**Behavior:**
- Deletes local and remote feature branch
- Removes associated worktree
- By default, keeps spec files with a `CANCELLED.md` marker
- Use `--delete` to remove spec files entirely

**Options:** `--delete`, `--keep-spec`, `--force`, `--reason <text>`

---

## 🤖 Agents Reference

Spectra includes 6 specialized agents for code analysis and review tasks.

| Agent | Description | Primary Use |
|-------|-------------|-------------|
| `code-reviewer` | Comprehensive code review focusing on correctness, maintainability, security | Full code review during PR |
| `code-simplifier` | Reduce code complexity, identify refactoring opportunities | Simplify complex code sections |
| `comment-analyzer` | Audit code comments for accuracy, necessity, quality | Comment cleanup and improvement |
| `pr-test-analyzer` | Analyze test coverage and quality for PR changes | Ensure adequate test coverage |
| `silent-failure-hunter` | Detect code that fails silently without proper error handling | Find missing error handling |
| `type-design-analyzer` | Analyze type system design, interface contracts, data model quality | Improve type safety |

### Agent Tools

All agents have access to:
- `Read` - Read file contents
- `Grep` - Search file contents
- `Glob` - Find files by pattern
- `Bash` - Execute commands
- `LSP` - Language server protocol for code intelligence

---

## 🔄 Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CORE WORKFLOW                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   specify ──► plan ──► tasks ──► implement ──► review-pr            │
│      │         │                                    │                │
│      ▼         ▼                                    ▼                │
│   clarify   analyze                              accept              │
│  (optional) (optional)                              │                │
│                                                     ▼                │
│                                                   merge              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐    ┌─────────────────────────┐
│  SETUP (Once)           │    │  LIFECYCLE              │
├─────────────────────────┤    ├─────────────────────────┤
│  constitution           │    │  cancel (abandon)       │
└─────────────────────────┘    └─────────────────────────┘
```

### Command Categories

| Category | Commands |
|----------|----------|
| **Core Flow** | specify → plan → tasks → implement |
| **Quality** | clarify, analyze, review-pr |
| **Delivery** | accept, merge |
| **Lifecycle** | cancel |
| **Setup** | constitution |

---

## 📁 Feature Directory Structure

Each feature creates artifacts in a dedicated directory:

```
specs/{feature-id}/
├── spec.md           # Feature specification
├── plan.md           # Implementation plan
├── tasks.md          # Task list
├── research.md       # Technical research (optional)
├── data-model.md     # Data model design (optional)
├── checklists/       # Generated checklists
└── checkpoints/      # Session checkpoints
```

---

## 🌳 Git Worktree Integration

Spectra uses git worktrees to provide isolated development environments for each feature.

### Why Worktrees?

- **Parallel Development** — Work on multiple features simultaneously without stashing
- **Clean Context** — Each feature has its own file state with no cross-contamination
- **Fresh Claude Sessions** — Start Claude in a worktree for focused context
- **Safe Experimentation** — Break things without affecting other features

### Worktree Structure

```
your-repo/
├── worktrees/
│   ├── 001-user-auth/           # Feature 1 (isolated)
│   │   ├── specs/001-user-auth/
│   │   └── [full repo copy]
│   │
│   └── 002-dashboard/           # Feature 2 (parallel)
│       ├── specs/002-dashboard/
│       └── [full repo copy]
│
└── specs/                       # Merged specs land here
```

### Working with Worktrees

**Option A: Parallel Features** — Best for multiple simultaneous features

```bash
# 1. Create the feature (worktree is auto-created)
/spectra.specify implement user authentication

# 2. Navigate to worktree and start fresh Claude session
cd worktrees/001-user-auth
claude

# 3. Continue workflow in isolation
/spectra.plan
/spectra.tasks
/spectra.implement
/spectra.merge --push
```

**Option B: Single Feature** — Simpler sequential workflow

```bash
# Stay in main repo - Claude helpers manage worktree context
/spectra.specify implement user authentication
/spectra.plan
/spectra.tasks
/spectra.implement
/spectra.merge --push
```

### Worktree Lifecycle

| Command | Worktree Action |
|---------|-----------------|
| `/spectra.specify` | Creates worktree + feature branch |
| `/spectra.merge` | Merges branch, removes worktree |
| `/spectra.cancel` | Deletes branch, removes worktree |

---

## ⚠️ Error Handling

If prerequisites are not met, commands provide clear error messages:

```
Error: spec.md not found.
Run /spectra.specify first to create a specification.
```

```
Error: Not in a feature directory.
Navigate to a feature directory under specs/ or run /spectra.specify to start.
```

---

## 📄 License

MIT — see [LICENSE](../LICENSE) for details.

---

<div align="center">

**[⬆ Back to top](#-spectra)**

</div>

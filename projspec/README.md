# ProjSpec

Specification-driven development workflow automation for Claude Code.

ProjSpec provides a structured approach to feature development by guiding you through specification, planning, task generation, and implementation phases. It ensures consistency and traceability throughout the development lifecycle.

## Prerequisites

- **Claude Code CLI** - The Claude Code command-line interface
- **Git** - Version control (repository must be initialized)
- **macOS or Linux** - Currently supported platforms
- **GitHub CLI** (optional) - Required for `/projspec.issues` command

## Installation

Install directly in Claude Code:

```
/plugin install projspec@claude-plugin-directory
```

Or browse available plugins:

```
/plugin > Discover
```

## Quick Start

### 1. Create a Specification

Define your feature requirements:

```
/projspec.specify my new feature that handles user authentication
```

This creates a structured specification with user scenarios, functional requirements, and success criteria.

### 2. Clarify Requirements (Optional)

Identify and resolve ambiguous areas:

```
/projspec.clarify
```

Asks up to 5 targeted questions and encodes answers back into the spec.

### 3. Generate a Plan

Create an implementation plan from your spec:

```
/projspec.plan
```

This produces a detailed design with architecture decisions and constitution compliance checks.

### 4. Generate Tasks

Break down the plan into actionable tasks:

```
/projspec.tasks
```

Creates a dependency-ordered task list ready for implementation.

### 5. Implement

Execute the implementation plan:

```
/projspec.implement           # Agent mode (default)
/projspec.implement --direct  # Direct mode (faster, sequential)
```

Processes and executes all tasks defined in tasks.md. Use `--direct` for faster execution when task isolation is not needed.

### 6. Review Before PR

Run comprehensive code review:

```
/projspec.review-pr
```

Uses specialized agents to ensure code quality before PR creation.

---

## Commands Reference

ProjSpec includes 10 commands for the complete development workflow.

### Core Workflow Commands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `/projspec.specify` | Create or update feature spec with requirements and success criteria | Feature description or empty for interactive |
| `/projspec.clarify` | Identify underspecified areas and ask up to 5 targeted clarification questions | None |
| `/projspec.plan` | Generate implementation plan with constitution compliance | None |
| `/projspec.tasks` | Generate structured, dependency-ordered task list from plan | None |
| `/projspec.implement` | Implement tasks from task list with guided workflow | `--agent`, `--direct`, or Task ID |
| `/projspec.issues` | Convert tasks into GitHub issues (requires GitHub CLI) | None |

### Quality & Validation Commands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `/projspec.checklist` | Generate a custom checklist for the current feature based on requirements | Checklist type |
| `/projspec.analyze` | Perform cross-artifact consistency and quality analysis | None |
| `/projspec.review-pr` | Comprehensive PR review using specialized agents | `full`, `quick`, `security`, `performance`, `style` |

### Project Configuration Commands

| Command | Description | Arguments |
|---------|-------------|-----------|
| `/projspec.constitution` | Create or update project constitution with foundational principles | `interactive`, `add "principle"`, `update`, or empty |

---

## Command Details & Examples

### /projspec.specify

Create or update a feature specification from a natural language description.

```bash
# Interactive mode
/projspec.specify

# With feature description
/projspec.specify implement user authentication with OAuth support

# Update existing spec
/projspec.specify  # Then follow prompts to update
```

**Output:** Creates `spec.md` with user scenarios, functional requirements, success criteria, and edge cases.

---

### /projspec.clarify

Identify underspecified areas and ask targeted clarification questions.

```bash
/projspec.clarify
```

**Behavior:** Analyzes current spec.md, identifies up to 5 areas needing clarification, asks questions interactively, and updates the spec with answers.

---

### /projspec.plan

Generate an implementation plan with constitution compliance checks.

```bash
/projspec.plan
```

**Prerequisites:** Requires `spec.md` to exist.

**Output:** Creates `plan.md` with technical context, constitution check, project structure, and implementation phases.

---

### /projspec.tasks

Generate a structured, dependency-ordered task list from the implementation plan.

```bash
/projspec.tasks
```

**Prerequisites:** Requires `plan.md` to exist.

**Output:** Creates `tasks.md` with phased tasks, dependencies, and acceptance criteria.

---

### /projspec.implement

Execute the implementation plan by processing tasks. Supports two execution modes:

| Mode | Flag | Description |
|------|------|-------------|
| **Agent** (default) | `--agent` | Spawns isolated agent per task with fresh context. Enables parallel execution of [P] tasks. |
| **Direct** | `--direct` | Executes tasks sequentially in current context. Faster for simple task sets. |

```bash
# Agent mode (default) - isolated context per task
/projspec.implement
/projspec.implement --agent

# Direct mode - sequential, no agents
/projspec.implement --direct

# Implement specific task
/projspec.implement T015
```

**Prerequisites:** Requires `tasks.md` to exist.

**Behavior:**
- Processes tasks in dependency order
- Each task produces exactly one commit: `[T###] Description`
- Updates task checkboxes after successful commit
- Agent mode: Tasks marked with [P] run in parallel
- Direct mode: Parallel markers are noted but tasks run sequentially

**Mode Comparison:**

| Aspect | Agent Mode | Direct Mode |
|--------|------------|-------------|
| Execution | Parallel possible | Sequential only |
| Context | Fresh per task | Accumulated |
| Speed | Slower (agent overhead) | Faster |
| Use case | Complex tasks, parallelism | Simple, sequential tasks |

---

### /projspec.issues

Convert tasks into actionable GitHub issues.

```bash
/projspec.issues
```

**Prerequisites:** Requires `tasks.md` and GitHub CLI (`gh`) authenticated.

**Output:** Creates GitHub issues with proper labels, descriptions, and dependency references.

---

### /projspec.checklist

Generate a custom checklist for the current feature.

```bash
/projspec.checklist requirements
/projspec.checklist implementation
```

**Output:** Creates checklists based on spec requirements and project constitution.

---

### /projspec.analyze

Perform cross-artifact consistency and quality analysis.

```bash
/projspec.analyze
```

**Behavior:** Analyzes spec.md, plan.md, and tasks.md for consistency, missing traceability, and quality issues.

---

### /projspec.review-pr

Comprehensive pull request review using specialized agents.

```bash
# Full review (default)
/projspec.review-pr

# Quick review for critical issues
/projspec.review-pr quick

# Security-focused review
/projspec.review-pr security

# Performance analysis
/projspec.review-pr performance

# Style check only
/projspec.review-pr style
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

### /projspec.constitution

Create or update the project constitution with foundational principles.

```bash
# View current constitution
/projspec.constitution

# Interactive creation/update
/projspec.constitution interactive

# Add a specific principle
/projspec.constitution add "All API endpoints must have rate limiting"

# Update existing
/projspec.constitution update
```

**Output:** Creates/updates `.projspec/memory/constitution.md` with principles, constraints, quality gates, and governance rules.

---

## Agents Reference

ProjSpec includes 6 specialized agents for code analysis and review tasks.

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

## Workflow Overview

```
                    +------------------+
                    |                  |
                    v                  |
specify --> clarify --> plan --> tasks --> implement
                                   |
                                   v
                              issues (optional)
                                   |
                                   v
                              review-pr
```

### Supporting Commands

```
constitution  <-- Define project principles (run once at project start)
analyze       <-- Cross-artifact consistency (run after tasks)
checklist     <-- Generate custom checklists (run at any phase)
```

---

## Feature Directory Structure

Each feature creates artifacts in a dedicated directory:

```
specs/{feature-id}/
  spec.md           # Feature specification
  plan.md           # Implementation plan
  tasks.md          # Task list
  research.md       # Technical research (optional)
  data-model.md     # Data model design (optional)
  checklists/       # Generated checklists
  checkpoints/      # Session checkpoints
```

---

## Error Handling

If prerequisites are not met, commands provide clear error messages:

```
Error: spec.md not found.
Run /projspec.specify first to create a specification.
```

```
Error: Not in a feature directory.
Navigate to a feature directory under specs/ or run /projspec.specify to start.
```

---

## License

MIT

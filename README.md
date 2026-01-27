# ProjSpec

A Claude Code plugin for specification-driven development workflows.

## Overview

ProjSpec provides a structured approach to feature development by guiding you through specification, planning, task generation, and implementation phases. It ensures consistency and traceability throughout the development lifecycle.

## Development Workflow

```mermaid
flowchart TD
    subgraph setup["Project Setup (Once)"]
        constitution["/projspec.constitution<br/>Define principles"]
    end

    subgraph core["Core Development Flow"]
        specify["/projspec.specify<br/>Create feature spec"]
        clarify["/projspec.clarify<br/>(Optional)"]
        plan["/projspec.plan<br/>Design implementation"]
        tasks["/projspec.tasks<br/>Generate task list"]
        implement["/projspec.implement<br/>Execute tasks"]
    end

    subgraph delivery["Delivery"]
        issues["/projspec.issues<br/>Create GitHub issues"]
        review["/projspec.review-pr<br/>Code review"]
        pr["Pull Request"]
    end

    subgraph quality["Quality (Run Anytime)"]
        analyze["/projspec.analyze"]
        checklist["/projspec.checklist"]
    end

    constitution -.-> specify
    specify --> plan
    specify -.-> clarify
    clarify -.-> plan
    plan --> tasks
    tasks --> implement
    implement --> issues
    issues --> review
    review --> pr

    tasks -.-> issues

    analyze -.-> core
    checklist -.-> core

    style constitution fill:#e1f5fe
    style specify fill:#fff3e0
    style clarify fill:#fff8e1,stroke-dasharray: 5 5
    style plan fill:#fff3e0
    style tasks fill:#fff3e0
    style implement fill:#fff3e0
    style issues fill:#e8f5e9
    style review fill:#e8f5e9
    style pr fill:#c8e6c9
```

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

```bash
# 1. Set up project principles (optional but recommended)
/projspec.constitution

# 2. Create a feature specification
/projspec.specify implement user authentication

# 3. Generate implementation plan
/projspec.plan

# 4. Generate tasks
/projspec.tasks

# 5. Implement (choose execution mode)
/projspec.implement           # Agent mode (default) - isolated context per task
/projspec.implement --direct  # Direct mode - faster, sequential execution

# 6. Review before PR
/projspec.review-pr
```

## Documentation

See [projspec/README.md](projspec/README.md) for complete documentation including:

- All 11 commands with usage examples
- 6 specialized agents for code review
- Workflow diagrams
- Feature directory structure

## Repository Structure

```
projspec/
  projspec/                    # The Claude Code plugin
    plugins/projspec/
      commands/                # Slash commands (/projspec.*)
      agents/                  # Specialized review agents
      templates/               # Spec, plan, task templates
      scripts/                 # Helper bash scripts
      memory/                  # Default constitution and context
  specs/                       # Feature specifications (this repo's own specs)
  tests/                       # E2E tests for the plugin
```

## Development

This project uses git worktrees for feature isolation:

```bash
# Feature development happens in worktrees
worktrees/<NNN-feature-name>/

# Feature specs live in the worktree
worktrees/<feature>/specs/<feature>/

# After PR merge, specs appear in main repo
specs/
```

### Running Tests

```bash
# Run E2E tests
pytest tests/e2e/ -v
```

## License

MIT

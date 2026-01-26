# speckit

Specification-driven development workflow automation for Claude Code.

speckit provides a structured approach to feature development by guiding you through specification, planning, task generation, and implementation phases. It ensures consistency and traceability throughout the development lifecycle.

## Prerequisites

- **Claude Code CLI** - The Claude Code command-line interface
- **Git** - Version control (repository must be initialized)
- **macOS or Linux** - Currently supported platforms
- **GitHub CLI** (optional) - Required for `/speckit:taskstoissues` command

## Installation

For local development, add the plugin using the `--plugin-dir` flag:

```bash
claude --plugin-dir /path/to/speckit
```

Or add it to your Claude Code configuration for persistent use.

## Quick Start

1. **Create a specification** - Define your feature requirements:
   ```
   /speckit:specify
   ```
   Describe your feature when prompted. This creates a structured specification.

2. **Generate a plan** - Create an implementation plan from your spec:
   ```
   /speckit:plan
   ```
   This produces a detailed design with architecture decisions.

3. **Generate tasks** - Break down the plan into actionable tasks:
   ```
   /speckit:tasks
   ```
   Creates a dependency-ordered task list ready for implementation.

4. **Implement** - Execute the implementation plan:
   ```
   /speckit:implement
   ```
   Processes and executes all tasks defined in tasks.md.

## Available Commands

| Command | Description |
|---------|-------------|
| `/speckit:specify` | Create or update a feature specification from a natural language description |
| `/speckit:clarify` | Identify underspecified areas and ask targeted clarification questions |
| `/speckit:plan` | Generate an implementation plan with design artifacts |
| `/speckit:tasks` | Create a dependency-ordered task list from design artifacts |
| `/speckit:taskstoissues` | Convert tasks into GitHub issues (requires GitHub CLI) |
| `/speckit:implement` | Execute the implementation plan by processing all tasks |
| `/speckit:checklist` | Generate a custom checklist for the current feature |
| `/speckit:validate` | Validate user input against specifications |
| `/speckit:analyze` | Perform cross-artifact consistency and quality analysis |
| `/speckit:constitution` | Create or update the project constitution |
| `/speckit:checkpoint` | Create an explicit session checkpoint |
| `/speckit:learn` | Review and manage auto-learned patterns from sessions |
| `/speckit:review-pr` | Comprehensive pull request review using specialized agents |

## Workflow Overview

```
specify --> clarify --> plan --> tasks --> implement
                                   |
                                   v
                            taskstoissues (optional)
```

Each phase builds upon the previous, creating a traceable chain from requirements to implementation.

## License

MIT

# Quickstart: speckit Plugin

Get started with the speckit plugin in under 5 minutes.

## Prerequisites

- **Claude Code CLI** installed and configured
- **Git** installed and configured
- **macOS or Linux** operating system
- **GitHub CLI** (optional, for `/speckit:issues` command)

Verify prerequisites:
```bash
# Check Claude Code
claude --version

# Check Git
git --version

# Check GitHub CLI (optional)
gh --version
```

---

## Installation

### Option 1: Local Development

```bash
# Clone the plugin
git clone https://github.com/yourorg/speckit.git

# Start Claude Code with the plugin loaded
claude --plugin-dir ./speckit
```

### Option 2: Install from Marketplace

Add to your Claude Code settings (`.claude/settings.json`):
```json
{
  "plugins": [
    { "source": "github:yourorg/speckit", "version": "latest" }
  ]
}
```

Then restart Claude Code.

---

## Core Workflow

The speckit plugin follows a specification-driven development workflow:

```
/speckit:specify → /speckit:plan → /speckit:tasks → /speckit:implement
```

### Step 1: Create a Specification

```
/speckit:specify Add user authentication with email/password login
```

This creates:
- Git branch: `001-user-auth`
- Spec file: `specs/001-user-auth/spec.md`
- Quality checklist: `specs/001-user-auth/checklists/requirements.md`

### Step 2: Clarify Requirements (Optional)

If the specification has unclear areas:
```
/speckit:clarify
```

This presents up to 5 targeted questions and updates the spec with your answers.

### Step 3: Generate Implementation Plan

```
/speckit:plan
```

This creates:
- Research findings: `specs/001-user-auth/research.md`
- Data model: `specs/001-user-auth/data-model.md`
- Implementation plan: `specs/001-user-auth/plan.md`
- Quickstart guide: `specs/001-user-auth/quickstart.md`

### Step 4: Generate Tasks

```
/speckit:tasks
```

This creates:
- Task list: `specs/001-user-auth/tasks.md`

Tasks are dependency-ordered and ready for implementation.

### Step 5: Implement

```
/speckit:implement
```

This processes tasks sequentially, updating status as work progresses.

---

## Optional Commands

### Analyze Consistency

Check that spec, plan, and tasks are aligned:
```
/speckit:analyze
```

### Generate Checklist

Create a custom validation checklist:
```
/speckit:checklist
```

### Convert Tasks to GitHub Issues

```
/speckit:issues
```

Requires GitHub CLI (`gh`) to be authenticated.

### Create Session Checkpoint

```
/speckit:checkpoint
```

Saves current session state for later reference.

### Review Code (PR Review)

```
/speckit:review-pr
```

Runs comprehensive code review using specialized agents.

---

## Project Structure After Setup

```
your-project/
├── .specify/
│   ├── memory/
│   │   ├── constitution.md      # Project principles
│   │   └── context.md           # Persistent context
│   ├── sessions/                # Session logs
│   ├── learning/                # Auto-learned patterns
│   ├── hooks/                   # Active hooks
│   ├── scripts/                 # Utility scripts
│   └── templates/               # Document templates
│
└── specs/
    └── 001-user-auth/           # Your first feature
        ├── spec.md              # Specification
        ├── plan.md              # Implementation plan
        ├── research.md          # Research findings
        ├── data-model.md        # Data model
        ├── quickstart.md        # Feature quickstart
        ├── tasks.md             # Task list
        └── checklists/
            └── requirements.md  # Spec validation checklist
```

---

## Tips

### Use Git Worktrees

speckit uses git worktrees for feature isolation. Each feature gets its own worktree:
```bash
ls ../worktrees/
# 001-user-auth/
# 002-payment-integration/
```

### Track Progress

Feature status is tracked in each artifact's header:
- `Draft` - Specification created
- `Planned` - Implementation plan completed
- `Tasked` - Tasks generated
- `In Progress` - Implementation started
- `Completed` - All tasks done

### Constitution Principles

Set up project principles in `.specify/memory/constitution.md` to ensure all features follow your standards:
```
/speckit:constitution
```

---

## Troubleshooting

### Command Not Found

Ensure the plugin is loaded:
```bash
claude --plugin-dir ./speckit
```

Check available commands:
```
/help
```

### Prerequisite Errors

If a command fails with prerequisite errors:
1. Check the error message for the missing artifact
2. Run the prerequisite command first (e.g., `/speckit:specify` before `/speckit:plan`)

### Git Worktree Issues

If worktree creation fails:
```bash
# List existing worktrees
git worktree list

# Remove stale worktrees
git worktree prune
```

---

## Next Steps

1. **Create your first feature**: `/speckit:specify "your feature description"`
2. **Set up project constitution**: `/speckit:constitution`
3. **Explore all commands**: `/help`

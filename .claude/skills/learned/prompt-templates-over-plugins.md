# Skill: Prompt Templates Over Plugins

**Learned**: 2026-01-26
**Context**: Designing ProjSpec command delivery without Claude Code plugin

## Pattern

Deliver AI assistant commands as markdown prompt templates that users load via the Read tool, instead of packaging as a plugin.

### Why Choose Templates Over Plugins

| Aspect | Plugin | Prompt Templates |
|--------|--------|------------------|
| Installation | Requires plugin install | Just copy files |
| Version compatibility | May break with updates | Always works |
| Distribution | Needs marketplace/registry | Git clone or copy |
| Customization | Harder to modify | Edit markdown directly |
| Debugging | Opaque | Transparent |

### Template Structure

```markdown
# Command: [name]

## Purpose
[What this command does]

## Prerequisites
[Required state before running - files that must exist, phase requirements]

## Workflow
1. [Step 1 - what Claude should do]
2. [Step 2]
...

## Output
[What files/artifacts get created or modified]

## Side Effects
[State changes, git operations, etc.]
```

### Template Location

```
.specify/templates/commands/
├── analyze.md
├── checklist.md
├── clarify.md
├── constitution.md
├── implement.md
├── plan.md
├── specify.md
├── tasks.md
└── taskstoissues.md
```

### Usage Pattern

User asks Claude:
```
"Read .specify/templates/commands/specify.md and follow those instructions"
```

Or more naturally:
```
"I want to create a new feature specification. Read the specify command template and help me."
```

### Benefits

1. **No installation friction** - Works immediately after cloning
2. **Transparent** - Users can read and understand what will happen
3. **Customizable** - Teams can modify templates for their needs
4. **Version-proof** - No plugin API changes to worry about
5. **Debuggable** - If something goes wrong, the logic is visible

### When to Use

- CLI tools that work with AI assistants
- Workflows that need to be customizable per-project
- When avoiding plugin installation complexity is valuable
- When transparency of AI instructions matters

### When Plugin May Be Better

- Need slash command auto-completion
- Need hooks or event-driven behavior
- Distribution through marketplace is important
- Need to hide implementation details

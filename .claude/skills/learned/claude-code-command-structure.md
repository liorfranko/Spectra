# Claude Code Command Structure

## Pattern

Claude Code commands are markdown files that guide Claude through multi-step workflows. They use YAML frontmatter for metadata and structured markdown for instructions.

## File Structure

```markdown
---
description: Brief description of what the command does
arguments:
  - name: arg_name
    description: What the argument is for
    required: false
  - name: --flag
    description: Optional flag description
    required: false
---

# /command.name

Brief intro paragraph explaining the purpose.

## Quick Reference

\`\`\`
/command.name [optional-arg]
/command.name --flag
\`\`\`

## Use Cases

- When to use this command
- Another scenario

## Prerequisites

- What must exist before running
- Required state or files

## Execution Steps

### Step 1: Description

Explain what this step does.

\`\`\`bash
command to run
\`\`\`

**Interpretation:**
- If X, then Y
- If Z, then W

### Step 2: Next Step

...

## Error Handling

### Error Type 1

\`\`\`
Error message template
\`\`\`

## Example Usage

### Example 1: Common Case

\`\`\`
User: /command.name
Claude: [shows expected output]
\`\`\`

## See Also

- `/related.command` - Description
- `/another.command` - Description

## Notes

- Important considerations
- Edge cases
```

## Key Principles

1. **YAML Frontmatter**: Always include `description` and optional `arguments`
2. **Quick Reference**: Show command syntax at a glance
3. **Step-by-Step**: Number steps with bash commands and interpretation
4. **Error Handling**: Anticipate failures with clear messages
5. **Examples**: Show realistic usage scenarios
6. **See Also**: Link to related commands for discoverability

## Location

- Plugin commands: `.claude/plugins/<plugin-name>/commands/`
- Installed commands: `.claude/commands/`

## Naming Convention

- Use lowercase with dots: `projspec.init.md`
- Match the command invocation: `/projspec.init` -> `projspec.init.md`

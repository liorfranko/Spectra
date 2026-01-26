---
description: Show status of all active specs
---

# /projspec.status Command

This command displays the status of all active specs by running the Python CLI.

## Quick Reference

```
/projspec.status
```

Shows a summary table of all active specs with their current phase and progress.

## Use Cases

- Checking the current state of all active specs
- Finding which spec to work on next
- Reviewing progress across multiple features
- Identifying blocked or stalled specs

## Execution

Run the following command:

```bash
projspec status
```

Display the output to the user.

## Understanding the Output

The status table shows:
- **ID**: Unique 8-character spec identifier
- **Name**: Spec name in kebab-case
- **Phase**: Current workflow phase (new, spec, plan, tasks, implement, review)
- **Progress**: Task completion (X/Y completed, or "-" if no tasks yet)
- **Branch**: Git branch for the spec's worktree

## Example Usage

```
User: /projspec.status

Claude:
Active Specs
============

| ID       | Name          | Phase     | Progress | Branch                    |
|----------|---------------|-----------|----------|---------------------------|
| a1b2c3d4 | user-auth     | implement | 4/6      | spec/a1b2c3d4-user-auth   |
| e5f6g7h8 | payment-api   | plan      | -        | spec/e5f6g7h8-payment-api |

Total: 2 active specs
```

### When No Specs Exist

```
User: /projspec.status

Claude:
No active specs found.

To get started:
  1. Initialize ProjSpec: /projspec.init
  2. Create a new spec: /projspec.new <spec-name>
```

## See Also

- `/projspec.new` - Create a new spec
- `/projspec.resume` - Resume work on a specific spec
- `/projspec.init` - Initialize ProjSpec if not already done

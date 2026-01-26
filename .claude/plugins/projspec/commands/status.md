---
description: Show status of all active specs
---

# /projspec.status Command

This command displays the status of all active specs by running the Python CLI.

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
- **Progress**: Task completion (X/Y completed, or "—" if no tasks yet)
- **Branch**: Git branch for the spec's worktree

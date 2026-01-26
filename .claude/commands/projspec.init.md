---
description: Initialize ProjSpec in the current directory
---

# /projspec.init Command

This command initializes ProjSpec in the current directory by running the Python CLI.

## Quick Reference

```
/projspec.init
```

Initializes the `.projspec/` directory structure for spec-driven development.

## Use Cases

- Setting up ProjSpec in a new repository
- Re-initializing after manual cleanup
- First-time project setup

## Execution

Run the following command:

```bash
projspec init
```

Report the output to the user.

## What It Creates

```
.projspec/
├── specs/
│   ├── active/     # Active specs in development
│   └── completed/  # Archived specs
└── config.yaml     # Configuration (optional)
```

## Example Usage

```
User: /projspec.init

Claude:
Initializing ProjSpec in /Users/dev/my-project...

Created:
  - .projspec/specs/active/
  - .projspec/specs/completed/

ProjSpec initialized successfully!

Next steps:
  1. Run /projspec.new <name> to create your first spec
```

## Next Steps

If initialization was successful, suggest:
- Run `/projspec.new <name>` to create a new spec

## See Also

- `/projspec.new` - Create a new spec after initialization
- `/projspec.status` - View active specs (will be empty initially)

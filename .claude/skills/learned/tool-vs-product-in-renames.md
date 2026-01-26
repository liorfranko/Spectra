# Distinguishing Tool from Product in Rename Operations

## Pattern Summary

When renaming a codebase, distinguish between the **tool managing the project** and the **product being built**. Only rename references to the product, not the tool.

## When to Apply

- Renaming a project/product name
- PR reviews flagging "missed" rename locations
- Any codebase where one tool builds another product

## Key Distinction

| Folder | Purpose | Should Rename? |
|--------|---------|----------------|
| `.specify/` or `.speckit/` | Tool managing the project | NO - tool references stay |
| `projspec/` or `src/` | Product being built | YES - rename these |
| `.claude/commands/` | Commands for THIS project | YES - if they reference the product |

## Example: speckit building projspec

```
repo/
├── .specify/              # speckit TOOL - DO NOT rename
│   ├── scripts/           # Uses /speckit.* commands (correct)
│   ├── templates/         # References speckit (correct)
│   └── sessions/          # Tool session files
├── projspec/              # projspec PRODUCT - rename these
│   ├── plugins/projspec/  # Product code, use projspec
│   └── README.md          # Document the product
└── .claude/commands/      # Commands for THIS project
    └── projspec.*.md      # Invoke projspec product commands
```

## False Positive Detection

When a PR review flags "missed renames" in tool folders:
1. Ask: "Is this folder the tool or the product?"
2. If tool folder (`.specify/`, `.speckit/`): These are intentional, not missed
3. If product folder: These should be renamed

## Why This Matters

Renaming tool references would break:
- The tool's own command invocations
- Template file processing
- Script execution
- Session management

## Related Patterns

- `large-scale-codebase-rename.md` - Overall rename strategy
- `parallel-pr-review-with-agents.md` - Review process that may flag false positives

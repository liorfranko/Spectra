# Contracts: Modify Tests to Use Projspec Commands

**Feature**: 008-projspec-test-commands
**Date**: 2026-01-27

## Summary

No API contracts are defined for this feature. This is a pure refactoring task that modifies existing test files by replacing string patterns. No new APIs, interfaces, or contracts are introduced.

## Existing Contracts (Unchanged)

The projspec plugin commands being tested have the following existing interfaces (no changes made by this feature):

| Command | Interface | Notes |
|---------|-----------|-------|
| `/projspec.constitution` | Interactive prompt-based | Creates constitution.md |
| `/projspec.specify` | Accepts feature description | Creates spec.md |
| `/projspec.plan` | Reads spec.md | Creates plan.md and artifacts |
| `/projspec.tasks` | Reads plan.md | Creates tasks.md |
| `/projspec.implement` | Reads tasks.md | Executes implementation |

These interfaces are documented in the projspec plugin itself, not in this feature.

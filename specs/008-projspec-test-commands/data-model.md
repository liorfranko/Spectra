# Data Model: Modify Tests to Use Projspec Commands

**Feature**: 008-projspec-test-commands
**Date**: 2026-01-27

## Summary

No new data models are introduced by this feature. This is a pure string replacement refactoring task that modifies existing test files without changing any data structures or adding new entities.

## Entities

### Existing Entities (No Changes)

The following entities exist in the test framework and remain unchanged:

| Entity | Description | Location |
|--------|-------------|----------|
| `ClaudeResult` | Data class for command execution results | `tests/e2e/helpers/claude_runner.py` |
| `E2EConfig` | Configuration for E2E tests | `tests/e2e/conftest.py` |
| `E2EProject` | Test project lifecycle management | `tests/e2e/helpers/test_environment.py` |

### No New Entities

This feature introduces no new data models, schemas, or entity definitions.

## Relationships

No relationship changes.

## State Transitions

No state transition changes.

## Validation Rules

No new validation rules introduced.

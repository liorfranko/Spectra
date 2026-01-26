# Research: Modify Tests to Use Projspec Commands

**Feature**: 008-projspec-test-commands
**Date**: 2026-01-27

## Summary

No research needed for this feature. This is a pure string replacement refactoring task where:

1. All source files to modify have been identified
2. All replacement patterns are known
3. No technology decisions required
4. No external dependencies involved

## Findings

### Decision: Replacement Scope

**Decision**: Replace all 92 occurrences of "speckit" across 7 test files.

**Rationale**: The spec requires consistent naming throughout the test suite. A complete replacement ensures no confusion between old and new naming conventions.

**Alternatives Considered**:
- Partial replacement (commands only): Rejected because it would leave inconsistent naming in class names and documentation.
- Automated migration script: Rejected as overkill for a one-time 92-occurrence replacement.

### Decision: Case Sensitivity

**Decision**: Use case-sensitive replacement to preserve capitalization patterns.

**Rationale**: Python class names use PascalCase (`TestSpeckit*` → `TestProjspec*`) while commands and documentation use lowercase (`speckit` → `projspec`). Both patterns must be preserved.

**Alternatives Considered**:
- Case-insensitive replacement: Rejected because it could corrupt capitalization.

### Decision: No Behavioral Changes

**Decision**: Tests remain functionally identical; only naming changes.

**Rationale**: Per the spec assumptions, the projspec commands have identical interfaces to speckit commands. No test logic needs modification.

**Alternatives Considered**: None - this is a constraint from the spec.

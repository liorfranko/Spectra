# Implementation Plan: Modify Tests to Use Projspec Commands

**Branch**: `008-projspec-test-commands` | **Date**: 2026-01-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-projspec-test-commands/spec.md`

**Note**: This template is filled in by the `/projspec.plan` command.

## Summary

Update the E2E test suite to replace all "speckit" references with "projspec" references. This includes command names (`/speckit.*` → `/projspec.*`), class names (`TestSpeckit*` → `TestProjspec*`), docstrings, and error messages. Total of 92 occurrences across 6 test stage files plus the stages `__init__.py`.

## Technical Context

**Language/Version**: Python 3.11+
**Primary Dependencies**: pytest (test framework)
**Storage**: N/A (test files only)
**Testing**: pytest with custom fixtures and markers
**Target Platform**: Cross-platform (macOS/Linux)
**Project Type**: Single project - test modification only
**Performance Goals**: N/A (test refactoring)
**Constraints**: All tests must pass after modification
**Scale/Scope**: 6 test stage files, 92 total "speckit" occurrences to replace

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution file is a template with placeholder values. No specific gates defined. This feature is a simple string replacement refactoring task with no architectural changes, new dependencies, or complexity increases. **PASS** - no violations.

## Project Structure

### Documentation (this feature)

```text
specs/008-projspec-test-commands/
├── plan.md              # This file (/projspec.plan command output)
├── research.md          # Phase 0 output - N/A for refactoring
├── data-model.md        # Phase 1 output - N/A for refactoring
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output - N/A for refactoring
└── tasks.md             # Phase 2 output (/projspec.tasks command)
```

### Source Code (files to modify)

```text
tests/e2e/
├── conftest.py              # No changes needed (no speckit references)
├── stages/
│   ├── __init__.py          # 1 speckit reference
│   ├── test_01_init.py      # TestSpeckitInit class name only
│   ├── test_02_constitution.py  # 9 speckit references
│   ├── test_03_specify.py   # 10 speckit references
│   ├── test_04_plan.py      # 12 speckit references
│   ├── test_05_tasks.py     # 11 speckit references
│   └── test_06_implement.py # 9 speckit references
└── helpers/
    ├── claude_runner.py     # No changes needed
    ├── file_verifier.py     # No changes needed
    ├── git_verifier.py      # No changes needed
    └── test_environment.py  # No changes needed
```

**Structure Decision**: No structural changes. This is an in-place string replacement refactoring.

## Complexity Tracking

> No complexity violations - this is a straightforward find/replace refactoring task.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| N/A       | N/A        | N/A                                  |

## Change Summary

### Category 1: Command Names (in test code and assertions)

| Old Pattern | New Pattern | Occurrences |
|-------------|-------------|-------------|
| `/speckit.constitution` | `/projspec.constitution` | ~3 |
| `/speckit.specify` | `/projspec.specify` | ~3 |
| `/speckit.plan` | `/projspec.plan` | ~3 |
| `/speckit.tasks` | `/projspec.tasks` | ~3 |
| `/speckit.implement` | `/projspec.implement` | ~3 |

### Category 2: Class Names

| Old Pattern | New Pattern | File |
|-------------|-------------|------|
| `TestSpeckitInit` | `TestProjspecInit` | test_01_init.py |
| `TestSpeckitConstitution` | `TestProjspecConstitution` | test_02_constitution.py |
| `TestSpeckitSpecify` | `TestProjspecSpecify` | test_03_specify.py |
| `TestSpeckitPlan` | `TestProjspecPlan` | test_04_plan.py |
| `TestSpeckitTasks` | `TestProjspecTasks` | test_05_tasks.py |
| `TestSpeckitImplement` | `TestProjspecImplement` | test_06_implement.py |

### Category 3: Docstrings and Comments

All references to "speckit" in module docstrings, class docstrings, and comments will be changed to "projspec".

## Implementation Approach

1. **Automated replacement**: Use case-sensitive find/replace to change all occurrences
2. **Pattern preservation**: Maintain exact casing patterns (`speckit` → `projspec`, `Speckit` → `Projspec`)
3. **Verification**: Run `pytest tests/e2e/` to confirm all tests still pass
4. **Final check**: `grep -r "speckit" tests/e2e/` should return zero results

## Risk Assessment

**Low Risk**: This is a pure string replacement with no behavioral changes. The command interface is identical between speckit and projspec (same parameters, same output format per spec assumptions).

## Dependencies

None - no external research needed. The replacement mapping is straightforward.

# Quickstart: Modify Tests to Use Projspec Commands

## Overview

This feature updates the E2E test suite to use the new `projspec` command naming convention instead of the deprecated `speckit` naming. This is a pure refactoring task with no behavioral changes.

## Prerequisites

- Python 3.11+ installed
- pytest installed (`pip install pytest`)
- Access to the test files in `tests/e2e/`

## What Changes

### Files Modified

| File | Changes |
|------|---------|
| `tests/e2e/stages/__init__.py` | 1 reference |
| `tests/e2e/stages/test_01_init.py` | Class name only |
| `tests/e2e/stages/test_02_constitution.py` | 9 references |
| `tests/e2e/stages/test_03_specify.py` | 10 references |
| `tests/e2e/stages/test_04_plan.py` | 12 references |
| `tests/e2e/stages/test_05_tasks.py` | 11 references |
| `tests/e2e/stages/test_06_implement.py` | 9 references |

### Replacement Patterns

```
/speckit.constitution  →  /projspec.constitution
/speckit.specify       →  /projspec.specify
/speckit.plan          →  /projspec.plan
/speckit.tasks         →  /projspec.tasks
/speckit.implement     →  /projspec.implement
TestSpeckitX           →  TestProjspecX
speckit (in docs)      →  projspec (in docs)
```

## Verification

After implementation, run:

```bash
# Verify no remaining speckit references
grep -r "speckit" tests/e2e/
# Expected: no output

# Run tests to verify they still work
pytest tests/e2e/ -v
# Expected: all tests pass
```

## Implementation Time

Estimated: Straightforward find/replace operation. All changes are mechanical string substitutions with no logic changes.

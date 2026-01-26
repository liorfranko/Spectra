# Quickstart: E2E Tests for projspec Plugin

**Branch**: `006-add-e2e-tests` | **Date**: 2026-01-26

## Prerequisites

1. **Python 3.11+** installed
2. **Claude CLI** installed and authenticated (`claude --version`)
3. **Git** configured with user.name and user.email
4. **pytest** and **pytest-timeout** installed

## Installation

```bash
# Install test dependencies
pip install pytest pytest-timeout
```

## Running Tests

### Run All E2E Tests

```bash
# From repository root
pytest tests/e2e/
```

### Run Specific Stage

```bash
# Run only stage 3 (specify)
pytest tests/e2e/ --stage 3

# Run stages 2 through 4
pytest tests/e2e/ --stage 2-4
```

### Debug Mode

```bash
# Enable real-time Claude output streaming
pytest tests/e2e/ --e2e-debug
```

### Override Timeouts

```bash
# Set all timeouts to 5 minutes
pytest tests/e2e/ --timeout-all 300
```

### Combined Options

```bash
# Run stage 3 with debug output and custom timeout
pytest tests/e2e/ --stage 3 --e2e-debug --timeout-all 600
```

## Test Output

### Log Files

After each run, logs are saved to:
```
tests/e2e/output/logs/YYYYMMDD-HHMMSS/
├── 01-init.log
├── 02-constitution.log
├── 03-specify.log
├── 04-plan.log
├── 05-tasks.log
└── 06-implement.log
```

### Test Projects

Test projects are preserved for debugging:
```
tests/e2e/output/test-projects/YYYYMMDD-HHMMSS-todo-app/
├── .git/
├── .claude/
├── .specify/
├── worktrees/
│   └── NNN-feature-name/
└── ...
```

## Test Stages

| Stage | Name | What It Tests | Default Timeout |
|-------|------|---------------|-----------------|
| 1 | init | `specify init` creates proper directory structure | 120s |
| 2 | constitution | `/speckit.constitution` setup (if applicable) | 600s |
| 3 | specify | `/speckit.specify` creates feature spec | 600s |
| 4 | plan | `/speckit.plan` creates implementation plan | 600s |
| 5 | tasks | `/speckit.tasks` generates task list | 600s |
| 6 | implement | `/speckit.implement` executes tasks | 1800s |

## Troubleshooting

### Claude CLI Not Authenticated

```
Error: Claude CLI not authenticated
```

**Solution**: Run `claude` interactively first to complete authentication.

### Stage Skipped

```
SKIPPED: Stage 3 skipped due to stage 2 failure
```

**Solution**: Check the log file for the failed stage. Fix the issue and re-run.

### Timeout Exceeded

```
FAILED: Command timed out after 600s
```

**Solution**: Use `--timeout-all` to increase timeout, or run with `--e2e-debug` to see where Claude is stuck.

### Test Project Already Exists

Test projects are timestamped, so collisions are rare. If needed, manually delete:
```bash
rm -rf tests/e2e/output/test-projects/
```

## Architecture Overview

```
tests/e2e/
├── conftest.py          # Fixtures, stage tracking, CLI options
├── helpers/
│   ├── claude_runner.py # Claude CLI wrapper
│   ├── file_verifier.py # File assertion utilities
│   ├── git_verifier.py  # Git state assertions
│   └── test_environment.py  # Test project lifecycle
└── stages/
    ├── test_01_init.py  # Stage 1 tests
    ├── test_02_constitution.py
    ├── test_03_specify.py
    ├── test_04_plan.py
    ├── test_05_tasks.py
    └── test_06_implement.py
```

## Writing New Tests

### Add Test to Existing Stage

```python
# In tests/e2e/stages/test_03_specify.py

@pytest.mark.e2e
@pytest.mark.stage(3)
class TestSpeckitSpecify:
    def test_new_assertion(self, file_verifier: FileVerifier) -> None:
        file_verifier.assert_contains(
            "worktrees/001-test-feature/specs/001-test-feature/spec.md",
            r"## Requirements",
            "Requirements section",
        )
```

### Add New Stage

1. Create `tests/e2e/stages/test_NN_stage_name.py`
2. Add stage marker: `@pytest.mark.stage(N)`
3. Add timeout constant to `ClaudeRunner.DEFAULT_TIMEOUT_*`
4. Update `conftest.py` if new dependencies needed

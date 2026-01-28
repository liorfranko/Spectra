# E2E Test Patterns for CLI Tools

Pattern for creating end-to-end tests for CLI tools that interact with AI assistants.

## When to Use

When building E2E tests for CLI tools that:
- Execute commands via subprocess
- Require timeout handling
- Have sequential stage dependencies
- Need artifact verification

## Structure

```
tests/
├── conftest.py              # Global pytest config
├── fixtures/                # Test project templates
└── e2e/
    ├── conftest.py          # Stage tracking, CLI options
    ├── helpers/
    │   ├── runner.py        # Command execution wrapper
    │   ├── file_verifier.py # File assertion utilities
    │   ├── git_verifier.py  # Git state assertions
    │   └── test_env.py      # Test project lifecycle
    └── stages/
        └── test_NN_stage.py # Stage-specific tests
```

## Key Patterns

### Stage Dependency Tracking

```python
class StageTracker:
    first_failure: int | None = None

    def record_failure(self, stage: int) -> None:
        if self.first_failure is None:
            self.first_failure = stage

    def should_skip(self, stage: int) -> bool:
        return self.first_failure is not None and stage > self.first_failure
```

### Command Result Dataclass

```python
@dataclass(frozen=True)
class CommandResult:
    success: bool
    stdout: str
    stderr: str
    timed_out: bool
    duration: float
    exit_code: int
```

### Session-Scoped Test Project

```python
@pytest.fixture(scope="session")
def test_project():
    project = E2EProject("test-app")
    project.setup()
    yield project
    # Don't cleanup - preserve for debugging
```

### CLI Options for Test Control

```python
def pytest_addoption(parser):
    parser.addoption("--stage", help="Run specific stage(s)")
    parser.addoption("--debug", action="store_true", help="Enable streaming output")
    parser.addoption("--timeout-all", type=int, help="Override all timeouts")
```

## Timeouts by Stage Complexity

| Stage Type | Default Timeout |
|------------|-----------------|
| Simple (init) | 120s |
| Medium (specify, plan) | 600s |
| Complex (implement) | 1800s |

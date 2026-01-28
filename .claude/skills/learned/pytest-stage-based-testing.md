# Pytest Stage-Based Testing Pattern

Pattern for implementing sequential stage-based E2E tests with automatic skip-on-failure behavior.

## When to Use

When building E2E test suites where:
- Tests must run in a specific order
- Later stages depend on earlier stages completing successfully
- You want automatic skipping when dependencies fail
- You need flexible CLI options for debugging

## Core Implementation

### Custom Markers

```python
# Register in conftest.py
def pytest_configure(config):
    config.addinivalue_line("markers", "e2e: marks tests as end-to-end tests")
    config.addinivalue_line("markers", "stage(n): marks test with stage number")
```

### Stage Tracker Singleton

```python
class StageTracker:
    """Singleton to track stage failures across the test session."""
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.first_failure = None
        return cls._instance

    def record_failure(self, stage: int) -> None:
        if self.first_failure is None:
            self.first_failure = stage

    def should_skip(self, stage: int) -> bool:
        return self.first_failure is not None and stage > self.first_failure
```

### Collection Hook for Ordering

```python
def pytest_collection_modifyitems(session, config, items):
    """Sort tests by stage number and filter by --stage option."""

    def get_stage(item):
        for marker in item.iter_markers("stage"):
            return marker.args[0]
        return 0

    # Sort by stage
    items.sort(key=get_stage)

    # Filter by --stage option if provided
    stage_str = config.getoption("--stage", default=None)
    if stage_str:
        min_stage, max_stage = parse_stage_range(stage_str)
        items[:] = [item for item in items if min_stage <= get_stage(item) <= max_stage]
```

### Setup Hook for Skipping

```python
def pytest_runtest_setup(item):
    """Skip tests in later stages if an earlier stage failed."""
    tracker = StageTracker()

    for marker in item.iter_markers("stage"):
        stage = marker.args[0]
        if tracker.should_skip(stage):
            pytest.skip(f"Skipping stage {stage}: stage {tracker.first_failure} failed")
```

### Report Hook for Recording Failures

```python
@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Record first failure stage for skip-on-failure behavior."""
    outcome = yield
    report = outcome.get_result()

    if report.when == "call" and report.failed:
        for marker in item.iter_markers("stage"):
            StageTracker().record_failure(marker.args[0])
```

## CLI Options

```python
def pytest_addoption(parser):
    parser.addoption(
        "--stage",
        metavar="N or N-M",
        help="Run specific stage (e.g., --stage 3 or --stage 2-4)"
    )
    parser.addoption(
        "--e2e-debug",
        action="store_true",
        help="Enable streaming output for debugging"
    )
    parser.addoption(
        "--timeout-all",
        type=int,
        help="Override all stage timeouts"
    )

def parse_stage_range(stage_str: str) -> tuple[int, int]:
    if "-" in stage_str:
        parts = stage_str.split("-")
        return int(parts[0]), int(parts[1])
    stage = int(stage_str)
    return stage, stage
```

## Test Class Pattern

```python
@pytest.mark.e2e
@pytest.mark.stage(3)
class TestStage3Feature:
    """All methods inherit the stage(3) marker."""

    def test_feature_runs_successfully(self, runner):
        result = runner.run(prompt="...", stage=3, log_name="feature_test")
        assert result.success, f"Failed: {result.stderr}"

    def test_artifact_created(self, file_verifier):
        file_verifier.assert_exists("output.md", "Feature output")
```

## Usage Examples

```bash
# Run all E2E tests in order
pytest tests/e2e/

# Run only stage 3
pytest tests/e2e/ --stage 3

# Run stages 2 through 4
pytest tests/e2e/ --stage 2-4

# Debug mode with streaming output
pytest tests/e2e/ --e2e-debug -v

# Override all timeouts to 5 minutes
pytest tests/e2e/ --timeout-all 300
```

## Key Benefits

1. **Automatic ordering**: Tests always run in stage order
2. **Fail-fast behavior**: Later stages skip when earlier stages fail
3. **Flexible filtering**: Run specific stages during development
4. **Debug support**: Streaming output for troubleshooting
5. **Timeout control**: Stage-specific defaults with CLI override

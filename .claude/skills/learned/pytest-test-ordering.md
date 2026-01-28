# Pytest Test Ordering Pattern

Pattern for ensuring tests run in a specific order within a test class.

## When to Use

When you have tests that:
- Must run in a specific sequence (e.g., setup before verification)
- Depend on side effects from earlier tests
- Need deterministic execution order

## Problem

Pytest runs tests within a class in **alphabetical order by method name**, not by definition order.

```python
class TestExample:
    def test_verify_file(self):  # Runs FIRST (alphabetically)
        pass

    def test_create_file(self):  # Runs SECOND (alphabetically)
        pass
```

This fails because verification runs before creation!

## Solution: Numeric Prefixes

Add numeric prefixes to test method names:

```python
class TestExample:
    def test_01_create_file(self):  # Runs first
        pass

    def test_02_verify_file(self):  # Runs second
        pass

    def test_03_cleanup(self):  # Runs third
        pass
```

## Naming Convention

| Pattern | Purpose |
|---------|---------|
| `test_01_*` | Command/action tests that produce side effects |
| `test_02_*` | First verification tests |
| `test_03_*` | Secondary verification tests |
| `test_04_*` | Additional assertions |

## Example: E2E Stage Tests

```python
@pytest.mark.stage(1)
class TestInit:
    def test_01_init_runs_successfully(self, runner):
        """Run the init command first."""
        result = runner.run("init")
        assert result.success

    def test_02_config_dir_created(self, verifier):
        """Verify directory exists after init ran."""
        verifier.assert_dir_exists(".config/")

    def test_03_config_file_created(self, verifier):
        """Verify config file exists."""
        verifier.assert_exists(".config/settings.json")
```

## Alternatives

1. **pytest-ordering plugin**: Use `@pytest.mark.order(N)` decorators
2. **pytest-dependency plugin**: Use `@pytest.mark.dependency()` for explicit deps
3. **Single test method**: Combine all assertions in one test

## When NOT to Use

- Unit tests that should be independent
- Tests that can run in parallel
- Tests where order doesn't matter

Prefer independent tests when possible - use this pattern only for true sequential dependencies like E2E workflows.

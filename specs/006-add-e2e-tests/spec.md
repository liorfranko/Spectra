# Feature Specification: End-to-End Tests for projspec Plugin

**Feature Branch**: `006-add-e2e-tests`
**Created**: 2026-01-26
**Status**: Draft
**Input**: User description: "add tests, look here /Users/liorfr/Development/spec-kit/tests for example how to do it"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run E2E Tests to Validate Plugin Commands (Priority: P1)

As a developer, I want to run end-to-end tests that validate the projspec plugin commands work correctly so that I can ensure code changes don't break existing functionality.

**Why this priority**: E2E tests are the foundation for confidence in the plugin's behavior. Without them, developers cannot safely make changes or verify that all commands work as expected in a realistic environment.

**Independent Test**: Can be fully tested by running `pytest tests/e2e/` and verifying all stage tests pass, demonstrating the plugin works end-to-end.

**Acceptance Scenarios**:

1. **Given** a fresh test project with no projspec setup, **When** I run the E2E test suite, **Then** all stage tests execute in order and produce pass/fail results.
2. **Given** the E2E test suite is running, **When** a stage fails, **Then** subsequent dependent stages are skipped with clear indication of why.
3. **Given** the E2E tests are complete, **When** I review the output, **Then** I can see which tests passed, failed, and were skipped with their durations.

---

### User Story 2 - Verify projspec Plugin Initialization (Priority: P1)

As a developer, I want E2E tests that verify the projspec plugin initialization creates the correct directory structure and files so that I can ensure new users have a proper setup experience.

**Why this priority**: Initialization is the entry point for all users. If init fails, no other commands will work.

**Independent Test**: Can be tested by running Stage 1 tests which verify `.specify/` directory structure, templates, and plugin configuration are created correctly.

**Acceptance Scenarios**:

1. **Given** a git-initialized directory, **When** the init stage test runs, **Then** it verifies `.specify/` directory is created with required subdirectories.
2. **Given** init has completed, **When** the test inspects the project, **Then** template files exist in `.specify/templates/`.
3. **Given** init has completed, **When** the test inspects the project, **Then** the `.claude/` directory contains proper plugin configuration.

---

### User Story 3 - Verify /speckit.specify Command (Priority: P1)

As a developer, I want E2E tests that verify the `/speckit.specify` command creates a proper feature specification so that I can ensure the spec workflow functions correctly.

**Why this priority**: The specify command is the core workflow entry point and creates the foundation for planning and implementation.

**Independent Test**: Can be tested by running Stage 3 tests which execute `/speckit.specify` with a sample feature description and verify the resulting spec file.

**Acceptance Scenarios**:

1. **Given** a projspec-initialized project, **When** the specify stage test runs with a feature description, **Then** Claude executes the command and creates a feature branch.
2. **Given** `/speckit.specify` has executed, **When** the test inspects the worktree, **Then** a `spec.md` file exists in the appropriate specs directory.
3. **Given** the spec file exists, **When** the test validates its content, **Then** it contains required sections: user scenarios, requirements, and success criteria.

---

### User Story 4 - Verify /speckit.plan Command (Priority: P2)

As a developer, I want E2E tests that verify the `/speckit.plan` command creates implementation planning documents so that I can ensure the planning workflow functions correctly.

**Why this priority**: Planning is important but depends on a working spec. It's a secondary workflow step.

**Independent Test**: Can be tested by running Stage 4 tests which execute `/speckit.plan` and verify the resulting plan file.

**Acceptance Scenarios**:

1. **Given** a feature with a complete spec, **When** the plan stage test runs, **Then** Claude executes `/speckit.plan` and creates a `plan.md` file.
2. **Given** the plan file exists, **When** the test validates its content, **Then** it contains architecture and implementation approach information.

---

### User Story 5 - Verify /speckit.tasks Command (Priority: P2)

As a developer, I want E2E tests that verify the `/speckit.tasks` command generates a task list so that I can ensure developers get actionable work items.

**Why this priority**: Task generation is important but depends on working spec and plan.

**Independent Test**: Can be tested by running Stage 5 tests which execute `/speckit.tasks` and verify the resulting tasks file.

**Acceptance Scenarios**:

1. **Given** a feature with a complete plan, **When** the tasks stage test runs, **Then** Claude executes `/speckit.tasks` and creates a `tasks.md` file.
2. **Given** the tasks file exists, **When** the test validates its content, **Then** it contains actionable task items with dependencies.

---

### User Story 6 - Debug and Iterate on E2E Tests (Priority: P3)

As a developer, I want the ability to run specific test stages and see debug output so that I can efficiently troubleshoot failing tests.

**Why this priority**: This is a developer experience enhancement that becomes valuable once the core tests exist.

**Independent Test**: Can be tested by running tests with `--stage 3` and `--e2e-debug` flags and verifying filtered/verbose output.

**Acceptance Scenarios**:

1. **Given** I want to run only stage 3 tests, **When** I execute `pytest tests/e2e --stage 3`, **Then** only stage 3 tests run.
2. **Given** I want to debug a failing test, **When** I run with `--e2e-debug`, **Then** I see real-time Claude CLI output.
3. **Given** I want to override timeouts, **When** I run with `--timeout-all 1200`, **Then** all stage timeouts use the specified value.

---

### Edge Cases

- What happens when Claude CLI is not installed or not authenticated?
- How does the system handle when a test project already exists from a previous run?
- What happens when Claude times out during a stage?
- How does the system handle network failures during Claude execution?
- What happens when the projspec plugin is not properly installed?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Test suite MUST use pytest as the testing framework with appropriate markers and fixtures.
- **FR-002**: Test suite MUST support running individual stages via `--stage N` CLI option.
- **FR-003**: Test suite MUST automatically skip dependent stages when an earlier stage fails.
- **FR-004**: Test suite MUST create isolated test projects for each test run to avoid interference.
- **FR-005**: Test suite MUST preserve test artifacts for debugging with clear location indication.
- **FR-006**: Test suite MUST provide a `ClaudeRunner` helper that executes `claude -p` commands with configurable timeouts.
- **FR-007**: Test suite MUST provide a `FileVerifier` helper that validates file existence and content patterns.
- **FR-008**: Test suite MUST provide a `GitVerifier` helper that validates git repository state and worktrees.
- **FR-009**: Test suite MUST provide an `E2EProject` helper that manages test project lifecycle.
- **FR-010**: Test suite MUST log Claude CLI output to files for post-mortem analysis.
- **FR-011**: Test suite MUST support debug mode with `--e2e-debug` for real-time output streaming.
- **FR-012**: Test suite MUST support timeout override with `--timeout-all` option.
- **FR-013**: Each test stage MUST have its own test file following the `test_NN_stage_name.py` naming convention.

### Test Stages

The E2E test suite is organized into sequential stages that mirror the projspec workflow:

| Stage | Name        | Description                              | Default Timeout |
|-------|-------------|------------------------------------------|-----------------|
| 1     | Init        | Verify plugin initialization             | 120s            |
| 2     | Constitution| Verify constitution setup (if applicable)| 600s            |
| 3     | Specify     | Verify `/speckit.specify` command        | 600s            |
| 4     | Plan        | Verify `/speckit.plan` command           | 600s            |
| 5     | Tasks       | Verify `/speckit.tasks` command          | 600s            |
| 6     | Implement   | Verify `/speckit.implement` command      | 1800s           |

### Key Entities

- **E2EProject**: Manages test project lifecycle including creation, git initialization, fixture copying, and path management.
- **ClaudeRunner**: Wrapper for executing Claude CLI commands with timeout handling, output capture, and logging.
- **ClaudeResult**: Data class containing execution results including success status, stdout/stderr, timeout flag, and duration.
- **FileVerifier**: Utility for asserting file existence, content patterns, and minimum line counts.
- **GitVerifier**: Utility for asserting git repository state, branch patterns, worktree existence, and commit history.
- **StageTracker**: Tracks stage execution status to enable dependent stage skipping.
- **E2EConfig**: Configuration object containing CLI options for stage filtering, debug mode, and timeout override.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Test suite can execute all 6 stages in sequence when run without filters.
- **SC-002**: Test suite correctly skips stages 4-6 when stage 3 fails.
- **SC-003**: 100% of tests produce clear pass/fail results with descriptive error messages.
- **SC-004**: Test logs are written to `tests/e2e/output/logs/` for every run.
- **SC-005**: Test projects are preserved in `tests/e2e/output/test-projects/` for debugging.
- **SC-006**: `--stage N` option correctly filters to run only the specified stage(s).
- **SC-007**: `--e2e-debug` option produces real-time streaming output during test execution.
- **SC-008**: All helper classes provide clear assertion error messages indicating expected vs actual state.

## Assumptions

- Claude CLI (`claude`) is installed and authenticated on the test machine.
- The projspec plugin is available via `specify init` or equivalent initialization.
- Git is installed and configured on the test machine.
- Python 3.11+ is available with pytest installed.
- Test execution requires network access for Claude API calls.
- Test timeouts account for variable Claude response times (defaults are generous).

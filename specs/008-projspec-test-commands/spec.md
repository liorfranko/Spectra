# Feature Specification: Modify Tests to Use Projspec Commands

**Feature Branch**: `008-projspec-test-commands`
**Created**: 2026-01-27
**Status**: Draft
**Input**: User description: "modify the tests to use the projspec commands"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run E2E Tests with Projspec Commands (Priority: P1)

A developer runs the end-to-end test suite to verify that all projspec workflow stages (init, constitution, specify, plan, tasks, implement) work correctly using the new `/projspec.*` command naming convention.

**Why this priority**: This is the core functionality - the test suite must accurately test the current projspec plugin command names rather than the deprecated speckit names. Without this change, tests would fail or test the wrong commands.

**Independent Test**: Can be fully tested by running `pytest tests/e2e/` and verifying all tests pass with the new command naming. Delivers immediate value by ensuring test coverage matches actual implementation.

**Acceptance Scenarios**:

1. **Given** a configured test project, **When** the test suite executes stage 1 (init), **Then** the test uses projspec initialization commands
2. **Given** a test project with projspec initialized, **When** the test suite executes stage 2 (constitution), **Then** the test uses `/projspec.constitution` instead of `/speckit.constitution`
3. **Given** a test project with constitution set up, **When** the test suite executes stage 3 (specify), **Then** the test uses `/projspec.specify` instead of `/speckit.specify`
4. **Given** a test project with a specification, **When** the test suite executes stage 4 (plan), **Then** the test uses `/projspec.plan` instead of `/speckit.plan`
5. **Given** a test project with an implementation plan, **When** the test suite executes stage 5 (tasks), **Then** the test uses `/projspec.tasks` instead of `/speckit.tasks`
6. **Given** a test project with generated tasks, **When** the test suite executes stage 6 (implement), **Then** the test uses `/projspec.implement` instead of `/speckit.implement`

---

### User Story 2 - Consistent Documentation in Tests (Priority: P2)

A developer reading the test source code sees consistent references to "projspec" throughout all docstrings, class names, comments, and error messages.

**Why this priority**: Consistency in documentation and naming improves maintainability and reduces confusion. This is important but secondary to functional correctness.

**Independent Test**: Can be verified by code review or grep search for any remaining "speckit" references in test files. Delivers value by ensuring code clarity.

**Acceptance Scenarios**:

1. **Given** any test file in the e2e test suite, **When** a developer reads class docstrings, **Then** they see references to "projspec" rather than "speckit"
2. **Given** any test file in the e2e test suite, **When** a developer reads test method descriptions, **Then** error messages reference "projspec" commands
3. **Given** any test file in the e2e test suite, **When** a developer reviews test class names, **Then** classes are named appropriately for the projspec plugin (e.g., `TestProjspecSpecify` rather than `TestSpeckitSpecify`)

---

### Edge Cases

- What happens when a test references both old and new naming? All tests should consistently use only the new projspec naming.
- What if some projspec commands have different behavior than speckit commands? Tests should be updated to match the actual projspec command behavior and output expectations.
- What about helper files and fixtures? Any references to speckit in helper modules should also be updated to projspec.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Test suite MUST use `/projspec.constitution` command instead of `/speckit.constitution` in stage 2 tests
- **FR-002**: Test suite MUST use `/projspec.specify` command instead of `/speckit.specify` in stage 3 tests
- **FR-003**: Test suite MUST use `/projspec.plan` command instead of `/speckit.plan` in stage 4 tests
- **FR-004**: Test suite MUST use `/projspec.tasks` command instead of `/speckit.tasks` in stage 5 tests
- **FR-005**: Test suite MUST use `/projspec.implement` command instead of `/speckit.implement` in stage 6 tests
- **FR-006**: Stage 1 initialization tests MUST use projspec-appropriate initialization approach
- **FR-007**: All test class names MUST be updated from `TestSpeckit*` to `TestProjspec*` pattern
- **FR-008**: All docstrings and comments referencing speckit MUST be updated to reference projspec
- **FR-009**: All error messages in assertions MUST reference the correct projspec command names
- **FR-010**: Helper modules and fixtures MUST be reviewed and updated for any speckit references

### Key Entities

- **Test Stage Files**: Individual test modules for each workflow stage (test_01_init.py through test_06_implement.py)
- **Helper Modules**: claude_runner.py, file_verifier.py, git_verifier.py - utilities used across tests
- **Fixtures**: Pytest fixtures in conftest.py files that set up test environments

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All e2e tests pass when executed with `pytest tests/e2e/`
- **SC-002**: Zero occurrences of "speckit" remain in test file content (commands, class names, docstrings, error messages)
- **SC-003**: All 6 test stages correctly invoke their corresponding projspec commands
- **SC-004**: Test output and logs reference projspec commands rather than speckit commands
- **SC-005**: No regression in test coverage - all previously tested behaviors remain tested

## Assumptions

- The projspec plugin commands (`/projspec.specify`, `/projspec.plan`, etc.) are already implemented and functional
- The command interface (parameters, output format) is consistent between the old speckit and new projspec naming
- The test helper utilities (ClaudeRunner, FileVerifier, GitVerifier) do not require functional changes, only naming updates if any speckit references exist
- Git worktree patterns and file path expectations remain unchanged

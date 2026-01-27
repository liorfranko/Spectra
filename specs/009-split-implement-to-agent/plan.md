# Implementation Plan: Split Implement Command into Agent and Direct Modes

**Feature**: Split Implement Command into Agent and Direct Modes
**Date**: 2026-01-27
**Status**: Ready for Implementation

---

## Technical Context

### Language & Runtime

| Aspect | Value |
|--------|-------|
| Primary Language | Markdown (Claude Code plugin command format) |
| Runtime/Version | Claude Code CLI (any version supporting plugins) |
| Package Manager | None (file-based plugin system) |
| Supporting Scripts | Bash 5.x |

### Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Claude Code CLI | latest | Plugin runtime environment |
| Git | 2.0+ | Version control for commits |
| Bash | 5.x | Prerequisite check scripts |

All dependencies are pre-existing in the project. No new external dependencies required.

### Platform & Environment

| Aspect | Value |
|--------|-------|
| Target Platform | Claude Code plugin (CLI extension) |
| Minimum Requirements | Claude Code CLI installed, Git repository |
| Environment Variables | `$ARGUMENTS` (provided by plugin system), `$CLAUDE_PLUGIN_ROOT` |

### Constraints

- **Plugin Format**: Must follow Claude Code plugin markdown command conventions
- **Backward Compatibility**: Existing `/projspec.implement` invocations must continue to work unchanged
- **Single File Modification**: Changes should be contained to implement.md for maintainability
- **Git State**: Both modes require a clean git working directory before starting
- **Commit Granularity**: Each task must produce exactly one commit regardless of mode

### Testing Approach

| Aspect | Value |
|--------|-------|
| Test Framework | Manual validation + bash scripts |
| Test Location | Manual testing with sample tasks.md files |
| Required Coverage | Both modes tested with identical task sets |

**Test Types**:
- Unit: No (Markdown commands don't have traditional unit tests)
- Integration: Yes (test full command execution in both modes)
- E2E: Yes (verify complete workflow from invocation to commits)

---

## Constitution Check

**Constitution Source**: `.projspec/memory/constitution.md`
**Check Date**: 2026-01-27

### Principle Compliance

| Principle | Description | Status | Notes |
|-----------|-------------|--------|-------|
| P-001 | User-Centric Design | PASS | Both modes serve user needs; default preserves existing UX |
| P-002 | Maintainability First | PASS | Single-file modification with clear conditional structure |
| P-003 | Incremental Delivery | PASS | Feature can be implemented in small, testable tasks |
| P-004 | Documentation as Code | PASS | Command help will document both modes |
| P-005 | Test-Driven Confidence | PARTIAL | Manual testing planned; no automated tests for Markdown commands |

### Compliance Details

#### Principles with Full Compliance (PASS)

- **P-001 (User-Centric Design)**: The feature provides user choice between modes. Default mode (agent) maintains backward compatibility, protecting existing workflows. Users are informed which mode is active.

- **P-002 (Maintainability First)**: Implementation modifies a single file (implement.md) with clear conditional logic. Mode-specific code is isolated to task execution sections. Shared logic (git, progress, errors) remains unified.

- **P-003 (Incremental Delivery)**: The implementation can be broken into discrete tasks: flag parsing, mode indicator display, direct mode execution, parallel task handling, testing.

- **P-004 (Documentation as Code)**: The command file itself documents available flags. Research and plan documents explain the feature design.

#### Principles with Partial Compliance (PARTIAL)

**P-005: Test-Driven Confidence**
- **Requirement**: New functionality requires accompanying tests
- **Current Plan**: Manual testing with sample tasks.md files; verification of identical outcomes between modes
- **Justification**: Claude Code plugin Markdown commands lack a standard automated testing framework. The plugin system doesn't provide test harnesses for .md commands.
- **Mitigation**:
  - Create sample tasks.md files that exercise edge cases
  - Document manual test procedures
  - Verify git history produces expected commit format
  - Compare outputs of both modes on identical inputs

### Gate Status

**Constitution Check Result**: PASS

**Criteria**: All principles are PASS or PARTIAL with documented justification.

**Action Required**: None - proceed to project structure.

---

## Complexity Tracking

### Constitution Deviations

| Item | Principle | Impact | Justification | Status |
|------|-----------|--------|---------------|--------|
| Manual testing only | P-005 | Low | No automated test framework for Markdown plugin commands | Accepted with mitigation |

### Mitigation Details

**Manual Testing Approach**:
1. Create `test-tasks-sequential.md` with 3 sequential tasks
2. Create `test-tasks-parallel.md` with 2 parallel [P] tasks
3. Run both modes on each file
4. Verify:
   - Correct number of commits created
   - Commit messages follow `[T###]` format
   - Git history identical between modes for same input
   - Parallel markers produce info message in direct mode

---

## Project Structure

### Documentation Layout

```
specs/009-split-implement-to-agent/
├── spec.md              # Feature specification (requirements, scenarios)
├── research.md          # Technical research and decisions
├── data-model.md        # Entity definitions and schemas
├── plan.md              # Implementation plan (this document)
├── quickstart.md        # Getting started guide
├── tasks.md             # Implementation task list (to be generated)
└── checklists/          # Validation checklists
    └── requirements.md
```

### Source Code Layout

Based on project type: Claude Code Plugin

```
projspec/plugins/projspec/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   └── implement.md         # PRIMARY FILE TO MODIFY
├── skills/
│   └── *.md
├── agents/
│   └── *.md
├── scripts/
│   └── bash/
│       └── check-prerequisites.sh
├── memory/
│   └── constitution.md
└── tests/                   # NEW: Manual test fixtures
    ├── test-tasks-sequential.md
    └── test-tasks-parallel.md
```

### Directory Purposes

| Directory | Purpose |
|-----------|---------|
| commands/ | Slash commands invoked by users |
| scripts/bash/ | Shell scripts supporting commands |
| memory/ | Persistent context and constitution |
| tests/ | Manual test fixtures for validation |

### File-to-Requirement Mapping

| File | Requirements | Purpose |
|------|--------------|---------|
| commands/implement.md | FR-001, FR-002, FR-003, FR-004, FR-005 | Main command with mode selection and execution logic |
| tests/test-tasks-sequential.md | SC-001, SC-002 | Test fixture for sequential task execution |
| tests/test-tasks-parallel.md | SC-001, FR-002 | Test fixture for parallel task handling |

### New Files to Create

| File Path | Type | Description |
|-----------|------|-------------|
| tests/test-tasks-sequential.md | test | Sample tasks.md with 3 sequential tasks for testing |
| tests/test-tasks-parallel.md | test | Sample tasks.md with 2 parallel [P] tasks for testing |

### Files to Modify

| File Path | Changes Required |
|-----------|------------------|
| commands/implement.md | Add flag parsing, mode selection, direct execution path, parallel task handling |

---

## Implementation Approach

### High-Level Changes to implement.md

1. **Add Flag Parsing Section** (new, after prerequisites)
   - Parse `$ARGUMENTS` for `--agent` and `--direct` flags
   - Detect conflict (both flags) → error
   - Set `MODE` variable: "agent" or "direct"
   - Display mode indicator message

2. **Modify Task Execution Section** (existing section 6)
   - Add conditional branch based on `MODE`
   - Agent mode: existing Task tool spawning logic
   - Direct mode: inline execution without spawning

3. **Add Direct Mode Execution Logic** (new subsection)
   - Read task details
   - Execute implementation inline (no Task tool)
   - Handle parallel markers with info message
   - Follow same git commit workflow as agent mode

4. **Update Progress Tracking** (existing section 9)
   - Include mode in startup message
   - Maintain consistent output format between modes

5. **Update Error Handling** (existing section 9)
   - Ensure retry/skip/abort available in both modes
   - Handle direct mode retry (re-read task, re-attempt)

### Pseudocode Structure

```
# At start of command, after prerequisites:
IF $ARGUMENTS contains "--direct" AND "--agent":
  ERROR "Cannot use both --agent and --direct flags"
  EXIT
ELIF $ARGUMENTS contains "--direct":
  MODE = "direct"
  DISPLAY "Executing tasks in direct mode (sequential, no agents)"
ELIF $ARGUMENTS contains "--agent":
  MODE = "agent"
  DISPLAY "Executing tasks in agent mode (isolated context per task)"
ELSE:
  MODE = "agent"  # default for backward compatibility
  DISPLAY "Executing tasks in agent mode (default)"

# In task execution loop:
FOR each task in tasks.md:
  IF MODE == "agent":
    # Existing logic: spawn Task tool agent
    Task tool with task context...
  ELSE:  # direct mode
    IF task has [P] marker:
      parallel_count++
    # Execute task inline without spawning
    Read task requirements
    Implement changes directly

  # Git workflow (same for both modes)
  git add -A
  git commit -m "[TaskID] Description"
  git push

# After parallel batch in direct mode:
IF parallel_count > 0 AND MODE == "direct":
  DISPLAY "Note: {parallel_count} parallel tasks ran sequentially in direct mode"
```

---

## Success Metrics

| Metric | Target | Verification |
|--------|--------|--------------|
| Mode availability | Both modes accessible | Run with --agent, --direct, and no flag |
| Execution parity | Identical outcomes | Compare file contents and commit counts |
| Commit format | Single task ID per commit | Inspect git log |
| Backward compatibility | No flag = agent mode | Run without flags, verify agent behavior |
| Performance | Direct mode faster | Time comparison on sequential tasks |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Direct mode context overflow on large task sets | Medium | Medium | Document limitation; suggest agent mode for many tasks |
| Flag parsing edge cases (quoted strings, etc.) | Low | Low | Simple contains check; complex args not expected |
| Inconsistent behavior between modes | Low | High | Test with identical inputs; compare outputs |

---

## Next Steps

1. Generate tasks.md with `/projspec.tasks`
2. Implement flag parsing (T001)
3. Implement direct mode execution (T002-T003)
4. Add parallel task handling for direct mode (T004)
5. Create test fixtures (T005)
6. Validate with manual testing (T006)

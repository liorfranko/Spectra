# Feature Specification: Split Implement Command into Agent and Direct Modes

## Metadata

| Field | Value |
|-------|-------|
| Branch | `009-split-implement-to-agent` |
| Date | 2026-01-27 |
| Status | Clarified |
| Input | Split the implement command to offer two modes: one with an agent per task, and one without agents (direct execution) |

---

## User Scenarios & Testing

### Primary Scenarios

#### US-001: Execute Tasks with Agent Isolation

**As a** developer using projspec
**I want to** run implement with agent-per-task mode
**So that** each task runs in isolated context with fresh state, enabling parallel execution and easier rollback

**Acceptance Criteria:**
- [ ] When running `/projspec.implement --agent` or `/projspec.implement-agent`, each task spawns a dedicated agent
- [ ] Each agent receives only the context relevant to its specific task
- [ ] Tasks marked with [P] in tasks.md are executed in parallel by multiple agents
- [ ] Each completed task results in exactly one commit with format `[T###] Description`

**Priority:** High

#### US-002: Execute Tasks Directly Without Agents

**As a** developer using projspec
**I want to** run implement in direct mode without spawning agents
**So that** I can execute tasks faster with lower overhead when isolation is not needed

**Acceptance Criteria:**
- [ ] When running `/projspec.implement --direct` or `/projspec.implement-direct`, tasks execute sequentially in the current context
- [ ] No agent spawning occurs during direct mode execution
- [ ] Each completed task still results in exactly one commit with format `[T###] Description`
- [ ] Progress is reported after each task completion

**Priority:** High

#### US-003: Use Default Mode When No Flag Provided

**As a** developer using projspec
**I want to** have a sensible default mode when I don't specify a flag
**So that** I can quickly run implement without needing to remember flags

**Acceptance Criteria:**
- [ ] When running `/projspec.implement` without flags, agent mode is used (backward compatibility)
- [ ] The default behavior matches existing workflows
- [ ] Users are informed which mode is being used when no flag is specified

**Priority:** Medium

**Clarification Note:** Configuration-based defaults were considered but rejected in favor of simplicity. Users must always specify `--direct` explicitly if they want direct mode.

### Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| tasks.md contains no tasks | Display message "No tasks found" and exit gracefully |
| User provides both --agent and --direct flags | Display error: "Cannot use both --agent and --direct flags" and exit |
| Agent mode task fails | Report error, offer retry/skip/abort options, do not commit failed task |
| Direct mode task fails | Report error, offer retry/skip/abort options, do not commit failed task |
| Task file references non-existent files | Report warning, proceed with available files, log missing files |
| Direct mode with [P] parallel tasks | Execute sequentially with info message: "Note: N parallel tasks running sequentially in direct mode" |

---

## Requirements

### Functional Requirements

#### FR-001: Command Flags for Mode Selection

The system must provide mode selection via flags on the single `/projspec.implement` command:
- `/projspec.implement --agent` - Runs in agent mode (one agent per task)
- `/projspec.implement --direct` - Runs in direct mode (sequential, no agents)
- `/projspec.implement` (no flag) - Defaults to agent mode for backward compatibility

**Verification:** Invoke each variant and confirm the corresponding execution mode is used.

#### FR-002: Agent Mode Preserves Current Behavior

When agent mode is selected, the implementation must:
- Spawn a dedicated agent for each task using the Task tool
- Provide each agent with isolated context (task details, relevant plan excerpts, constitution principles)
- Execute parallel tasks [P] concurrently via simultaneous agent spawns
- Commit and push after each agent completes its task

**Verification:** Run agent mode on a tasks.md with 3 sequential tasks and 2 parallel tasks. Verify 5 agents are spawned and 5 commits are created.

#### FR-003: Direct Mode Sequential Execution

When direct mode is selected, the implementation must:
- Execute each task sequentially in the current conversation context
- NOT spawn any agents
- Commit and push after each task completion
- Maintain progress tracking identical to agent mode
- Handle [P] parallel-marked tasks sequentially with info message: "Note: N parallel tasks running sequentially in direct mode"
- Offer retry/skip/abort options on task failure (same as agent mode)

**Verification:** Run direct mode on a tasks.md with 5 tasks (including 2 with [P] markers). Verify no agents are spawned, 5 commits are created, and parallel marker info message is displayed.

#### FR-004: Consistent Commit Format Across Modes

Both agent and direct modes must produce commits with the same format:
- Single task ID per commit: `[T###] Description`
- Co-authored-by trailer included
- No batch commits or range formats

**Verification:** Compare git log output from agent mode and direct mode implementations of the same tasks.md. Commit message formats must be identical.

#### FR-005: Mode Selection Logic

Mode selection follows simple rules:
1. If `--agent` flag is provided: use agent mode
2. If `--direct` flag is provided: use direct mode
3. If no flag is provided: use agent mode (default for backward compatibility)

No configuration file support is provided; explicit flags are always required to change from default.

**Verification:** Test with each flag and without flags to confirm correct mode selection.

### Constraints

| Constraint | Description |
|------------|-------------|
| Backward Compatibility | Existing workflows using the current implement command must continue to work |
| Single Responsibility | Each command variant handles only its specific execution mode |
| Git State | Both modes require a clean git working directory before starting |

---

## Key Entities

### Execution Mode

**Description:** The method by which tasks are executed during implementation

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| mode_type | Whether agent-based or direct execution | Enum: "agent" or "direct" |
| parallel_support | Whether parallel task execution is supported | Agent mode: yes, Direct mode: no |
| context_isolation | Whether each task gets fresh context | Agent mode: yes, Direct mode: no |

### Task

**Description:** A unit of work defined in tasks.md to be implemented

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| task_id | Unique identifier | Format: T### (e.g., T001, T012) |
| description | What the task accomplishes | Non-empty string |
| parallel_marker | Whether task can run in parallel | Boolean, indicated by [P] |
| status | Completion state | Enum: pending, in_progress, completed, failed |
| files | Files to create or modify | List of file paths |

### Entity Relationships

- Execution Mode determines how Tasks are processed
- Each Task produces exactly one Commit regardless of Execution Mode

---

## Success Criteria

### SC-001: Mode Availability

**Measure:** Both execution modes are accessible and functional
**Target:** 100% of invocations with valid mode selection execute in the specified mode
**Verification Method:** Run both modes 10 times each with the same tasks.md; verify correct mode execution each time

### SC-002: Execution Parity

**Measure:** Final codebase state after running both modes on identical inputs
**Target:** Identical file contents and commit history structure (task IDs and count match)
**Verification Method:** Run agent mode and direct mode on the same feature from tasks.md; diff the resulting codebases

### SC-003: Direct Mode Performance Improvement

**Measure:** Time to complete implementation in direct mode vs agent mode
**Target:** Direct mode completes at least 20% faster than agent mode for sequential tasks
**Verification Method:** Time both modes executing the same 10 sequential tasks; compare completion times

---

## Assumptions

| ID | Assumption | Impact if Wrong | Validated |
|----|------------|-----------------|-----------|
| A-001 | Users want direct mode primarily for speed benefits when isolation isn't critical | May need different default mode or different use cases | No |
| A-002 | Parallel execution is only beneficial with agent mode due to context isolation | Would need to reconsider direct mode parallel support | No |
| A-003 | The current commit-per-task strategy is desired in both modes | May need mode-specific commit strategies | No |

---

## Open Questions

### Q-001: Default Mode Selection

- **Question**: Which mode should be the default when no flag is provided: agent mode (current behavior) or direct mode?
- **Why Needed**: Affects user experience and backward compatibility. Current behavior uses agents, but direct mode may be preferred for simplicity.
- **Resolution**: Agent mode is the default (maintains backward compatibility with existing workflows)
- **Status**: Resolved
- **Impacts**: FR-005, US-003

### Q-002: Invocation Style

- **Question**: Should the modes be invoked via separate commands (`/projspec.implement-agent`, `/projspec.implement-direct`) or via flags on a single command (`/projspec.implement --agent`, `/projspec.implement --direct`)?
- **Why Needed**: Affects command structure, discoverability, and documentation. Separate commands are more explicit but add to the command surface.
- **Resolution**: Single command with flags (`/projspec.implement --agent`, `/projspec.implement --direct`)
- **Status**: Resolved
- **Impacts**: FR-001, US-001, US-002

### Q-003: Parallel Tasks in Direct Mode

- **Question**: How should tasks marked with [P] be handled in direct mode, given that parallel execution requires agent isolation?
- **Why Needed**: Direct mode cannot truly parallelize without agents. Need to define behavior for [P] tasks.
- **Resolution**: Execute [P] tasks sequentially with an informational message: "Note: N parallel tasks running sequentially in direct mode"
- **Status**: Resolved
- **Impacts**: FR-003, US-002

### Q-004: Configuration Support

- **Question**: Should users be able to configure a default mode in project settings?
- **Why Needed**: Convenience for users who prefer one mode over another.
- **Resolution**: No configuration support. Always require explicit `--direct` flag for direct mode. Simplicity over configurability.
- **Status**: Resolved
- **Impacts**: FR-005, US-003

### Q-005: Failure Handling Consistency

- **Question**: Should both modes offer the same recovery options (retry/skip/abort) on task failure?
- **Why Needed**: Ensures consistent user experience across execution modes.
- **Resolution**: Yes, both modes offer retry/skip/abort options on failure. Consistent behavior regardless of mode.
- **Status**: Resolved
- **Impacts**: Edge Cases, FR-002, FR-003

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2025-01-27 | Claude (projspec) | Initial draft from feature description |
| 0.2 | 2026-01-27 | Claude (projspec/clarify) | Resolved 5 clarification questions: default mode (agent), invocation style (flags), parallel task handling, no config support, consistent failure handling |

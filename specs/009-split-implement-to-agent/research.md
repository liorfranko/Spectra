# Research: Split Implement Command into Agent and Direct Modes

## Overview

This research document captures the technical decisions made for implementing dual execution modes in the `/projspec.implement` command. The feature adds a `--direct` flag for sequential in-context execution alongside the existing agent-based approach, while maintaining backward compatibility.

## Technical Unknowns

### 1. Flag Parsing in Markdown Commands

**Question**: How should command-line flags be parsed and validated in a Claude Code plugin command written in Markdown?

**Options Considered**:
1. Parse `$ARGUMENTS` string manually in the Markdown command logic
2. Use a bash script to pre-process arguments and return structured JSON
3. Handle flag parsing inline with simple string matching patterns

**Decision**: Parse `$ARGUMENTS` inline with simple pattern matching

**Rationale**:
- The plugin system already provides `$ARGUMENTS` as the user input
- Only two mutually-exclusive flags need to be detected (`--agent`, `--direct`)
- A simple string matching approach (e.g., checking if `$ARGUMENTS` contains `--direct`) is sufficient
- Adding a script would be over-engineering for two flags

**Trade-offs**:
- Less robust than a formal argument parser
- Limited to simple flag detection (no complex options needed for this feature)

**Sources**:
- Existing implement.md command structure
- Claude Code plugin documentation conventions

---

### 2. Preserving Current Behavior vs Refactoring

**Question**: Should the existing implement.md command be modified in-place, or should the logic be refactored into separate components?

**Options Considered**:
1. Modify implement.md in-place with conditional logic based on mode
2. Create separate agent execution and direct execution helper scripts
3. Create separate command files (implement-agent.md, implement-direct.md) with shared includes

**Decision**: Modify implement.md in-place with conditional logic

**Rationale**:
- Single entry point maintains unified UX per the spec requirement
- Conditional branching is manageable since the difference is primarily whether to spawn agents
- Most workflow logic (git commits, progress tracking, error handling) is shared between modes
- Avoids duplication and maintenance burden of multiple files

**Trade-offs**:
- Single file becomes longer and more complex
- Testing requires exercising both code paths

**Sources**:
- FR-001 specifying single command with flags approach
- Existing implement.md structure

---

### 3. Direct Mode Task Execution Pattern

**Question**: In direct mode, how should task instructions be "executed" without spawning agents?

**Options Considered**:
1. Execute tasks inline by reading task details and performing actions directly in the conversation
2. Use a loop that reads each task and processes it sequentially with the same context
3. Generate a consolidated "implementation script" that runs all tasks

**Decision**: Execute tasks inline sequentially in the current conversation context

**Rationale**:
- Direct mode's value proposition is avoiding agent overhead while maintaining per-task commits
- Current conversation context is preserved between tasks, reducing re-reading of plan documents
- Mirrors the agent workflow structure but without Task tool invocation
- Allows for user interaction on failure (retry/skip/abort) identical to agent mode

**Trade-offs**:
- Context grows throughout execution (no fresh context per task)
- Cannot parallelize tasks in direct mode
- If context limit is reached during long implementation, may need to compact

**Sources**:
- FR-003 defining direct mode behavior
- US-002 acceptance criteria

---

### 4. Parallel Task Handling in Direct Mode

**Question**: How should the command handle tasks marked with `[P]` (parallel) when running in direct mode?

**Options Considered**:
1. Error and refuse to execute if parallel tasks exist
2. Execute sequentially with a warning message
3. Silently execute sequentially with no indication
4. Batch parallel tasks into a single execution unit

**Decision**: Execute sequentially with an informational message

**Rationale**:
- Blocking on parallel markers would be overly restrictive
- Users should know their parallel markers are being ignored
- Sequential execution still produces correct results, just slower
- Message format: "Note: N parallel tasks running sequentially in direct mode"

**Trade-offs**:
- User may not realize performance difference until seeing the message
- No true parallelization benefit in direct mode

**Sources**:
- Q-003 resolution in spec.md
- Edge case: "Direct mode with [P] parallel tasks"

---

### 5. Error Handling Consistency

**Question**: Should error handling (retry/skip/abort) be identical between modes, or optimized per mode?

**Options Considered**:
1. Same UX in both modes (retry/skip/abort prompts)
2. Direct mode stops immediately on error (simpler, since context is shared)
3. Different recovery options based on mode characteristics

**Decision**: Same retry/skip/abort options in both modes

**Rationale**:
- Consistent user experience regardless of execution mode
- Users shouldn't need to remember different error handling behaviors
- "Skip" still makes sense in direct mode (move to next task)
- "Retry" in direct mode means re-read task and re-attempt implementation

**Trade-offs**:
- "Retry" in direct mode works differently (no fresh context) but produces similar outcome

**Sources**:
- Q-005 resolution in spec.md
- Edge cases table showing consistent behavior

---

### 6. Mode Indicator in Progress Output

**Question**: Should the progress output indicate which mode is being used?

**Options Considered**:
1. Show mode only at startup: "Running in agent/direct mode"
2. Show mode with each task: "[Agent] ✓ T001 Description"
3. No mode indication in output
4. Show mode in commit messages

**Decision**: Show mode at startup and in status updates

**Rationale**:
- Users should know which mode they're in, especially when using default (no flag)
- Per-task indicator unnecessary clutter
- Commit messages remain identical between modes (per FR-004)
- Startup message: "Executing tasks in {mode} mode"

**Trade-offs**:
- Slight increase in output verbosity at startup

**Sources**:
- US-003: "Users are informed which mode is being used when no flag is specified"

---

## Key Findings

1. **Minimal Code Changes**: The implementation requires modifying a single file (implement.md) with conditional logic, not a major refactor

2. **Shared Logic**: 80%+ of the existing implement command logic is shared between modes:
   - Prerequisites checking
   - Context loading (tasks.md, plan.md, etc.)
   - Git commit workflow
   - Progress tracking
   - Error handling UI

3. **Mode-Specific Logic**: Only two areas differ:
   - Task execution: `Task tool spawn` vs `inline execution`
   - Parallel handling: `simultaneous agent spawns` vs `sequential with message`

4. **Backward Compatibility**: Default to agent mode means existing scripts/workflows work unchanged

5. **Testing Strategy**: Both modes should be tested with the same tasks.md to verify identical outcomes

## Recommendations

1. **Implementation Approach**: Add a mode detection block at the start of implement.md that sets a mode variable, then use conditionals only where behavior differs

2. **Mode Detection Logic**:
   ```
   if $ARGUMENTS contains "--direct" AND "--agent":
     ERROR: "Cannot use both --agent and --direct flags"
   elif $ARGUMENTS contains "--direct":
     MODE = "direct"
   else:
     MODE = "agent"  # default for backward compatibility
   ```

3. **Shared Code Structure**: Extract task execution into a conceptual "execute task" section that has mode-specific branches only for the agent spawn vs inline execution

4. **Documentation**: Update command help to document both modes with examples

5. **Future Consideration**: If direct mode proves popular, consider making it the default in a future major version (would require constitution amendment for breaking change)

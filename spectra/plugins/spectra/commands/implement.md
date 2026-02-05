---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Mode Selection

Parse the `$ARGUMENTS` to determine execution mode:

1. **Check for conflicting flags**:
   - If `$ARGUMENTS` contains BOTH `--agent` AND `--direct`:
     - Display error: "Error: Cannot use both --agent and --direct flags. Please choose one mode."
     - **STOP execution immediately**

2. **Determine execution mode**:
   - If `$ARGUMENTS` contains `--direct`: Set `MODE = "direct"`
   - If `$ARGUMENTS` contains `--agent`: Set `MODE = "agent"`
   - If neither flag is present: Set `MODE = "agent"` (default for backward compatibility)

3. **Store the MODE variable** for use in task execution steps below.

5. **Display mode indicator**:
   - If `MODE = "agent"` AND `--agent` flag was explicitly provided:
     - Display: "Executing tasks in agent mode (smart grouping enabled)"
   - If `MODE = "agent"` AND no flag was provided (default):
     - Display: "Executing tasks in agent mode (smart grouping enabled) (default)"
   - If `MODE = "direct"`:
     - Display: "Executing tasks in direct mode (sequential, no agents)"

**Backward Compatibility Note:** Running `/spectra:implement` without any flags maintains the same behavior as before - tasks will be executed in agent mode. Smart grouping is now the default agent behavior, grouping related tasks to reduce context overhead while preserving per-task commit granularity.

## Outline

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

4. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* exists → create/verify .eslintignore
   - Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

5. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

6. **Task Execution Strategy - Smart Grouping**:

   <!-- BEGIN AGENT MODE SECTION (MODE == "agent") -->
   **When MODE = "agent" (Agent Mode Execution):**

   The following agent-based execution strategy applies when running in agent mode.
   Tasks are **smartly grouped** to reduce context overhead while preserving per-task commit granularity.

   **CRITICAL - ONE GROUP = ONE AGENT, ONE TASK = ONE COMMIT**:
   - Related tasks are grouped together and implemented by a single agent
   - Each task MUST still result in exactly ONE commit with format `[T001] Description`
   - NEVER batch multiple tasks into one commit (even within the same group)
   - NEVER use range formats like `[T001-T005]` or `[T001, T002]` in commits
   - The agent commits after EACH task, not after the group
   - This ensures: rollback granularity, clear audit trail, reduced context overhead

   ### Smart Grouping Algorithm

   Before executing tasks, analyze and group them for optimal agent efficiency:

   **Step 1: Parse All Tasks**
   - Extract all tasks from tasks.md with their attributes:
     - Task ID (T001, T002, etc.)
     - Phase (Setup, Foundational, User Stories, Polish)
     - User Story marker if present ([US1], [US2], etc.)
     - Parallel marker if present ([P])
     - Description and file paths mentioned

   **Step 2: Partition by Phase (HARD constraint)**
   - NEVER group tasks across different phases
   - Phases act as synchronization points
   - Create separate groups for: Setup, Foundational, each User Story section, Polish

   **Step 3: Within Phase, Group by User Story (PRIMARY grouping)**
   - Group all tasks with the same `[USn]` marker together
   - Example: T007 [US1], T008 [US1], T009 [US1] → one group
   - Tasks without user story markers form their own groups within the phase

   **Step 4: Analyze File Overlap (SECONDARY grouping)**
   - Parse file paths from task descriptions
   - Tasks touching the same files benefit from being grouped
   - Use this to refine groups or split large ones

   **Step 5: Apply Group Size Limit**
   - Maximum 5-7 tasks per group to avoid context overload
   - If a logical group exceeds this limit, split by file overlap
   - Prefer keeping related tasks together when splitting

   **Step 6: Respect Parallel/Sequential Constraints**
   - Non-parallel tasks in sequence → can be grouped together
   - Parallel [P] tasks → can be grouped together (within same phase/story)
   - Mixed parallel and non-parallel within same story → same group is fine

   **Grouping Output Format**:
   ```
   Group 1 (Phase 1 - Setup): T001, T002, T003
   Group 2 (Phase 2 - Foundational): T004, T005, T006
   Group 3 (US1 - User Registration): T007, T008, T009, T010
   Group 4 (US2 - Login): T011, T012, T013
   Group 5 (Phase 4 - Polish): T014, T015
   ```

   ### Display Group Plan

   Before executing, display the grouping plan to the user:

   ```
   Smart Grouping Plan:
   ┌─────────────────────────────────────────────────────────────┐
   │ Group 1 (Phase 1 - Setup): T001, T002, T003                │
   │ Group 2 (Phase 2 - Foundational): T004, T005, T006         │
   │ Group 3 (US1 - User Registration): T007, T008, T009, T010  │
   │ Group 4 (US2 - Login): T011, T012, T013                    │
   │ Group 5 (Phase 4 - Polish): T014, T015                     │
   └─────────────────────────────────────────────────────────────┘
   Total: 5 groups, 15 tasks
   ```

   ### Group Execution Strategy

   **For Each Group**:
   1. Spawn ONE agent with all tasks in the group
   2. Agent implements tasks sequentially in order
   3. Agent commits after EACH task (not after the group)
   4. Agent pushes after completing all tasks in the group
   5. Update tasks.md checkboxes for all completed tasks
   6. Report group completion before moving to next group

   **For Parallel Groups** (groups that can run concurrently):
   - If multiple groups have no dependencies between them (e.g., separate user stories after foundational phase)
   - Can spawn multiple group agents simultaneously
   - Each agent still commits per-task within its group
   - Wait for all parallel groups to complete before dependent groups

   **Group Agent Invocation Template**:

   ```yaml
   Task tool:
     subagent_type: "general-purpose"
     model: "opus"
     description: "Group N: [Phase/Story name] - Tasks T00X-T00Y"
     prompt: |
       You are implementing a GROUP of related tasks.
       Implement each task in order and commit after EACH one.

       TASK GROUP:
       1. T001: [Description] [FILES: path1, path2]
       2. T002: [Description] [FILES: path2, path3]
       3. T003: [Description] [FILES: path1]

       EXECUTION ORDER:
       For each task in order:
       1. Implement the task
       2. Stage all changes: git add -A
       3. Commit with format: git commit -m "[T###] Description

          Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
       4. Report: "✓ [T###] Description - Committed"
       5. Move to next task

       After ALL tasks in this group are committed:
       - Push all commits: git push
       - Report: "Group N complete: X tasks committed and pushed"

       CONTEXT:
       [Relevant plan.md excerpts for this group]
       [Relevant spec.md user stories for this group]
       [Relevant data-model.md entities if applicable]

       CONSTITUTION PRINCIPLES:
       [Key principles from constitution.md]

       INSTRUCTIONS:
       1. Implement tasks IN ORDER (T001 before T002, etc.)
       2. Commit AFTER EACH TASK (not at the end)
       3. Each commit message: "[T###] Description"
       4. You can reference earlier task implementations in later tasks
       5. Follow the architecture and patterns from the plan
       6. Adhere to constitution principles
       7. Ensure code is production-ready

       DO NOT:
       - Skip any task in the group
       - Batch multiple tasks into one commit
       - Use range formats like [T001-T003] in commits
       - Deviate from the plan
       - Skip error handling

       When complete, report all files created/modified and confirm all commits.
   ```

   ### Progress Tracking for Groups

   After each group completes:
   ```
   ✓ Group 1 (Phase 1 - Setup) complete:
     - [T001] Create project structure - Committed
     - [T002] Initialize dependencies - Committed
     - [T003] Configure tooling - Committed
     Pushed 3 commits to remote

   Executing Group 2 (Phase 2 - Foundational): T004, T005, T006...
   ```

   ### Verification After Group Completion

   After each group:
   1. Verify expected commits exist: `git log --oneline -n [group_size]`
   2. Confirm each task has its own `[T###]` commit
   3. Update tasks.md checkboxes for all tasks in group
   4. If any task failed within group, report and ask user for action

   <!-- END AGENT MODE SECTION -->

   <!-- BEGIN DIRECT MODE SECTION (MODE == "direct") -->
   **When MODE = "direct" (Direct Mode Execution):**

   The following inline execution strategy applies when running in direct mode.
   Tasks are executed sequentially in the current conversation context without spawning agents.

   **CRITICAL - ONE TASK = ONE COMMIT**:
   - Each task (T001, T002, etc.) MUST be implemented sequentially in the current context
   - Each task MUST result in exactly ONE commit with format `[T001] Description`
   - NEVER batch multiple tasks into one commit
   - NEVER use range formats like `[T001-T005]` or `[T001, T002]` in commits
   - NO agents are spawned - all work happens in this conversation
   - This ensures: rollback granularity, clear audit trail, simpler execution

   **For Sequential Tasks**:
   - Parse tasks from tasks.md in order
   - For each task:
     1. Read the task details (ID, description, file paths)
     2. Load relevant context from plan.md, spec.md, data-model.md, constitution.md
     3. Implement the task changes directly in the current context
     4. Stage all changes: `git add -A`
     5. Commit with task ID and description: `git commit -m "[TaskID] Task description"`
     6. Push to remote: `git push`
     7. Mark task as [X] in tasks.md file
   - Move to next task

   **For Parallel Tasks [P]**:
   - In direct mode, parallel-marked tasks [P] are executed sequentially (direct mode cannot parallelize)
   - Track the count of [P] tasks encountered in each batch as you process them
   - Execute each [P] task one after another using the same workflow as sequential tasks:
     1. Read the task details (ID, description, file paths)
     2. Load relevant context from plan.md, spec.md, data-model.md, constitution.md
     3. Implement the task changes directly in the current context
     4. Stage all changes: `git add -A`
     5. Commit with task ID and description: `git commit -m "[TaskID] Task description"`
     6. Push to remote: `git push`
     7. Mark task as [X] in tasks.md file
   - After completing all [P] tasks in a batch, display info message:
     - `"Note: N parallel tasks ran sequentially in direct mode"` (where N is the count of [P] tasks in that batch)
   - This informs users that parallelization was not applied and why
   - Then proceed to the next batch or sequential task

   **Direct Execution Template**:

   For each task, follow this pattern:

   ```text
   1. IDENTIFY: Parse task [TaskID] from tasks.md
      - Task description
      - Files to create/modify
      - Dependencies on previous tasks

   2. CONTEXT: Load relevant information
      - plan.md: Architecture, tech stack, file structure
      - spec.md: Requirements this task addresses
      - data-model.md: Entities if applicable
      - constitution.md: Principles to follow

   3. IMPLEMENT: Make the changes
      - Create/modify specified files
      - Follow patterns from the plan
      - Adhere to constitution principles
      - Ensure code is production-ready

   4. COMMIT: Save progress
      - git add -A
      - git commit -m "[TaskID] Description"
      - git push

   5. TRACK: Update progress
      - Mark [X] in tasks.md
      - Report: "✓ [TaskID] Description - Committed and pushed"
   ```

   **Benefits of Direct Mode**:
   - Simpler execution without agent coordination overhead
   - Full context accumulation across tasks (can reference earlier changes)
   - Lower latency per task (no agent spawn time)
   - Better for smaller task sets or when context sharing is valuable

   **Trade-offs**:
   - No isolated context per task (context accumulates)
   - Sequential only (no parallel execution)
   - Context window may fill with large implementations

   <!-- END DIRECT MODE SECTION -->

7. **Phase-by-Phase Execution** (applies to both modes, agent mode uses grouping):
   - **Phase 1 - Setup**:
     - Agent mode: One group for all setup tasks → single agent, commit per task, push after group
     - Direct mode: Execute setup tasks sequentially, commit + push after each
   - **Phase 2 - Foundational**:
     - Agent mode: One group for foundational tasks → single agent, commit per task, push after group
     - Direct mode: Execute foundational tasks sequentially, commit + push after each
   - **Phase 3+ - User Stories**:
     - Agent mode: One group per user story (e.g., Group 3 = all US1 tasks, Group 4 = all US2 tasks)
       - Each story group gets its own agent with shared context
       - Agent commits per task, pushes after story group completes
       - Independent story groups can run in parallel if no dependencies
     - Direct mode: Execute story tasks sequentially, commit + push after each
   - **Final Phase - Polish**:
     - Agent mode: One group for polish tasks → single agent, commit per task, push after group
     - Direct mode: Execute polish tasks sequentially, commit + push after each

8. **Git Commit Strategy**:

   **This section applies to BOTH agent mode and direct mode. All commits must follow this format regardless of execution mode.**

   **Commit Message Format** (SINGLE task ID only):

   ```text
   [T001] Create project structure per implementation plan
   [T012] [US1] Implement User model in src/models/user.py
   [T015] [P] [US1] Create UserService in src/services/user_service.py
   ```

   **INVALID commit formats** (NEVER use these):

   ```text
   [T001-T005] Setup phase          # NO ranges
   [T001, T002] Multiple tasks      # NO multiple IDs
   [T001-T005, T010] Mixed          # NO combinations
   Setup phase for T001-T005        # NO task IDs at end
   ```

   **After Each Task Completion** (within a group in agent mode):

   ```bash
   # Stage all changes
   git add -A

   # Commit with task ID and description
   git commit -m "[TaskID] Task description

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

   # Update tasks.md - mark the task checkbox as complete
   # Change: - [ ] T001: Description
   # To:     - [X] T001: Description
   ```

   **After Each Group Completion** (agent mode only):

   ```bash
   # Push all commits from this group to remote
   git push
   ```

   **After Each Task** (direct mode):

   ```bash
   # Stage, commit, AND push after each task
   git add -A && git commit -m "[TaskID] Description" && git push
   ```

   **Benefits**:
   - Clear git history showing task-by-task progress
   - Easy rollback to specific task if needed
   - Remote backup after each group (agent mode) or task (direct mode)
   - Granular tracking of what changed when
   - Each commit is a checkpoint
   - Grouped pushes reduce network overhead in agent mode

9. **Progress Tracking and Error Handling**:

   **This section applies to BOTH agent mode and direct mode. Error handling behavior is consistent regardless of execution mode.**

   **Agent Mode (Group-Level Tracking)**:
   - Display group plan before execution starts
   - Report progress after each group completes:
     ```
     ✓ Group 1 (Phase 1 - Setup) complete:
       - [T001] Create project structure - Committed
       - [T002] Initialize dependencies - Committed
       - [T003] Configure tooling - Committed
       Pushed 3 commits to remote

     Executing Group 2 (Phase 2 - Foundational): T004, T005, T006...
     ```
   - If a task fails within a group:
     - The agent should report which task failed
     - Commits for successfully completed tasks in the group are preserved
     - Show error output from the group agent
     - Ask user whether to retry the failed task, skip it, or abort

   **Direct Mode (Task-Level Tracking)**:
   - Report progress after each task completes
   - Display: "✓ [TaskID] Description - Committed and pushed"

   **Error Handling (Both Modes)**:
   - Halt execution if any blocking task fails
   - For parallel tasks [P] or parallel groups:
     - Continue with successful tasks/groups
     - Report failed tasks clearly
     - Commit successful tasks
     - Provide clear error messages for failed tasks
   - If task fails:
     - Show error output (from agent in agent mode, or from current context in direct mode)
     - Suggest fixes or next steps
     - Ask user whether to retry, skip, or abort:
       - **Retry**: In agent mode, respawn the group agent for remaining tasks. In direct mode, re-read the task details from tasks.md, reload context from plan.md/spec.md, and re-attempt the implementation in the current conversation.
       - **Skip**: Mark task as skipped and continue to next task (not recommended).
       - **Abort**: Stop implementation entirely and allow user to review the issue.
   - **IMPORTANT**: Update tasks.md checkbox [X] only after successful commit

10. **Completion Validation**:

- Verify all required tasks are completed (all checkboxes [X])
- Check that implemented features match the original specification
- Validate that tests pass and coverage meets requirements
- Confirm the implementation follows the technical plan
- Review git history: `git log --oneline | head -20` to see task progression
- **Validate commit format**: Every commit should have format `[T###] Description` (single task ID)
- **Validate commit count**: Number of `[T###]` commits should equal number of tasks implemented
- **Agent mode validation**: Verify number of groups executed matches planned groups
- Report final status with:
  - Total tasks completed
  - Total groups executed (agent mode only)
  - Total commits made (should match tasks completed)
  - Verification: "X tasks = X commits ✓" or warning if mismatch
  - Summary of completed work by phase/group
  - Next steps in the workflow:
    1. `/spectra:review-pr` - Run code review
    2. `/spectra:accept` - Validate feature readiness
    3. `/spectra:merge --push` - Merge to main and cleanup

## Important Notes

- **ONE GROUP = ONE AGENT, ONE TASK = ONE COMMIT**: Smart grouping batches related tasks into a single agent context, but each task still gets its own commit for rollback granularity.
- **Smart Grouping Benefits**: Reduced context overhead, better coherence for related tasks, shared understanding within a group, fewer agent spawns.
- **Git as Progress Tracker**: Git history becomes a detailed audit trail of task-by-task implementation. You should have as many commits as tasks.
- **Group Efficiency**: Related tasks (same phase, same user story) share context, enabling the agent to build on earlier work within the group.
- **Constitution Compliance**: Every spawned agent must receive relevant constitution principles
- **Rollback Safety**: Any task can be rolled back via `git revert` using the task ID in commit message. This only works if each task has its own commit.
- **Remote Backup**: Pushing after each group ensures work is backed up at logical boundaries
- **Validation**: After implementation, verify `git log --oneline | wc -l` roughly equals the number of tasks

## Prerequisites

- Complete task breakdown exists in tasks.md (run `/spectra:tasks` if missing)
- Git repository is initialized and has a remote configured
- Working directory is clean or all changes are committed
- User has push permissions to remote repository

## Error Recovery

**This section applies to BOTH agent mode and direct mode.**

**Flag Conflict Error**: If you see "Cannot use both --agent and --direct flags", remove one of the flags and re-run the command.

**Agent Mode - Group Failure Recovery**:

If a task fails within a group:
1. Review the error output from the group agent
2. Commits for completed tasks in the group are preserved
3. Determine if it's a transient error (network, etc.) or code error
4. Options:
   - **Retry Task**: Spawn a new group agent for the remaining tasks (starting from the failed task)
   - **Retry Group**: Re-run the entire group (may re-implement already committed tasks)
   - **Fix & Continue**: Fix the issue manually, commit the failed task, then spawn agent for remaining tasks
   - **Skip Task**: Mark task as skipped and continue with remaining tasks in group (not recommended)
   - **Abort Group**: Stop this group, ask if user wants to continue with next group

**Direct Mode - Task Failure Recovery**:

If a task fails:
1. Review the error output from current context
2. Determine if it's a transient error (network, etc.) or code error
3. Options:
   - **Retry**: Re-read the task details from tasks.md, reload context from plan.md/spec.md, and re-attempt the implementation in the current conversation.
   - **Fix & Retry**: Fix the issue manually, commit, then continue with the next task
   - **Skip**: Mark task as skipped and move to next (not recommended)
   - **Abort**: Stop implementation, review task breakdown
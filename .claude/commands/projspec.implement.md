---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. Load and analyze the implementation context:
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

6. **Task Execution Strategy - Isolated Context Per Task**:

   Each task runs in a **fresh context** via spawned agents to ensure isolation and clean state.

   **CRITICAL - ONE TASK = ONE AGENT = ONE COMMIT**:
   - Each task (T001, T002, etc.) MUST be implemented by its own spawned agent
   - Each task MUST result in exactly ONE commit with format `[T001] Description`
   - NEVER batch multiple tasks into one agent or one commit
   - NEVER use range formats like `[T001-T005]` or `[T001, T002]` in commits
   - If a task is too small, still give it its own agent and commit
   - This ensures: rollback granularity, clear audit trail, fresh context per task

   **For Sequential Tasks**:
   - Spawn a new agent using the Task tool for each task
   - Provide the agent with:
     - Task ID and description
     - Relevant excerpts from plan.md, spec.md, data-model.md
     - Constitution principles from `.specify.specify/memory/constitution.md`
     - Specific file paths to create/modify
   - Wait for agent completion
   - After agent completes:
     1. Stage all changes: `git add -A`
     2. Commit with task ID and description: `git commit -m "[TaskID] Task description"`
     3. Push to remote: `git push`
     4. Mark task as [X] in tasks.md file
   - Move to next sequential task

   **For Parallel Tasks [P]**:
   - Identify all tasks marked with [P] in the same batch
   - Spawn multiple agents simultaneously (single message with multiple Task tool calls)
   - Each agent gets the same context package (task details, plan excerpts, constitution)
   - Wait for all parallel agents to complete
   - After all complete, for each task in completion order:
     1. Stage changes for that task: `git add [task-specific-files]` or `git add -A` if files overlap
     2. Commit individually: `git commit -m "[TaskID] Task description"`
     3. Mark task as [X] in tasks.md
   - Push all commits together: `git push`
   - Move to next batch

   **Agent Invocation Template**:

   ```yaml
   Task tool:
     subagent_type: "general-purpose"
     description: "[TaskID] Brief description"
     prompt: |
       You are implementing a specific task in isolation with a fresh context.

       TASK DETAILS:
       - Task ID: [TaskID]
       - Description: [Full task description]
       - Files to modify: [file paths]

       CONTEXT:
       [Relevant plan.md excerpts]
       [Relevant spec.md user stories]
       [Relevant data-model.md entities if applicable]

       CONSTITUTION PRINCIPLES:
       [Key principles from constitution.md]

       INSTRUCTIONS:
       1. Implement ONLY this specific task
       2. Follow the architecture and patterns from the plan
       3. Adhere to constitution principles
       4. Create/modify the specified files
       5. Ensure code is production-ready

       DO NOT:
       - Implement other tasks
       - Deviate from the plan
       - Skip error handling
       - Ignore constitution requirements

       When complete, report what files were created/modified.
   ```

7. **Phase-by-Phase Execution**:
   - **Phase 1 - Setup**:
     - Spawn agents for setup tasks (project structure, dependencies, config)
     - Commit + push after each setup task
   - **Phase 2 - Foundational**:
     - Spawn agents for blocking prerequisites
     - Commit + push after each foundational task
   - **Phase 3+ - User Stories**:
     - For each user story phase (US1, US2, US3...):
       - Spawn agents for story tasks (models → services → endpoints)
       - Commit + push after each task
       - Validate story completion before next story
   - **Final Phase - Polish**:
     - Spawn agents for cross-cutting concerns
     - Commit + push after each polish task

8. **Git Commit Strategy**:

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

   **After Each Task Completion**:

   ```bash
   # Stage all changes
   git add -A

   # Commit with task ID and description
   git commit -m "[TaskID] Task description

   Co-Authored-By: Claude Sonnet 4.5 (1M context) <noreply@anthropic.com>"

   # Push to remote
   git push
   ```

   **Benefits**:
   - Clear git history showing task-by-task progress
   - Easy rollback to specific task if needed
   - Remote backup after each task
   - Granular tracking of what changed when
   - Each commit is a checkpoint

9. **Progress Tracking and Error Handling**:
   - Report progress after each spawned agent completes
   - Display: "✓ [TaskID] Description - Committed and pushed"
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P]:
     - Continue with successful tasks
     - Report failed tasks clearly
     - Commit successful tasks
     - Provide clear error messages for failed tasks
   - If task fails:
     - Show agent error output
     - Suggest fixes or next steps
     - Ask user whether to retry, skip, or abort
   - **IMPORTANT**: Update tasks.md checkbox [X] only after successful commit + push

10. **Completion Validation**:

- Verify all required tasks are completed (all checkboxes [X])
- Check that implemented features match the original specification
- Validate that tests pass and coverage meets requirements
- Confirm the implementation follows the technical plan
- Review git history: `git log --oneline | head -20` to see task progression
- **Validate commit format**: Every commit should have format `[T###] Description` (single task ID)
- **Validate commit count**: Number of `[T###]` commits should equal number of tasks implemented
- Report final status with:
  - Total tasks completed
  - Total commits made (should match tasks completed)
  - Verification: "X tasks = X commits ✓" or warning if mismatch
  - Summary of completed work by phase
  - Next suggested step: `/speckit.review-pr`

## Important Notes

- **ONE TASK = ONE AGENT = ONE COMMIT**: This is the core principle. Never batch tasks together. Each T### gets its own spawned agent and its own `[T###]` commit.
- **Fresh Context Per Task**: Each spawned agent starts with a clean slate, only seeing the explicit context provided in the prompt
- **Git as Progress Tracker**: Git history becomes a detailed audit trail of task-by-task implementation. You should have as many commits as tasks.
- **Parallel Efficiency**: Tasks marked [P] can run simultaneously for faster completion, but each still gets its own commit
- **Constitution Compliance**: Every spawned agent must receive relevant constitution principles
- **Rollback Safety**: Any task can be rolled back via `git revert` using the task ID in commit message. This only works if each task has its own commit.
- **Remote Backup**: Pushing after each task ensures work is backed up continuously
- **Validation**: After implementation, verify `git log --oneline | wc -l` roughly equals the number of tasks

## Prerequisites

- Complete task breakdown exists in tasks.md (run `/speckit.tasks` if missing)
- Git repository is initialized and has a remote configured
- Working directory is clean or all changes are committed
- User has push permissions to remote repository

## Error Recovery

If a task fails:

1. Review the agent's error output
2. Determine if it's a transient error (network, etc.) or code error
3. Options:
   - **Retry**: Spawn the same agent again with same prompt
   - **Fix & Retry**: Fix the issue manually, commit, then continue
   - **Skip**: Mark task as skipped and move to next (not recommended)
   - **Abort**: Stop implementation, review task breakdown

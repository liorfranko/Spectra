# Tasks: Claude Code Spec Plugin (speckit)

**Input**: Design documents from `/specs/003-claude-plugin-speckit/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

**Tests**: No automated tests requested. Manual testing via `claude --plugin-dir ./speckit`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Plugin structure:
```
speckit/
├── .claude-plugin/plugin.json
├── commands/
├── agents/
├── hooks/
├── scripts/
├── templates/
└── memory/
```

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create plugin directory structure and core configuration

- [x] T001 Create plugin root directory structure at speckit/
- [x] T002 Create plugin manifest at speckit/.claude-plugin/plugin.json with name, version, and component paths
- [x] T003 [P] Create empty directories: speckit/commands/, speckit/agents/, speckit/hooks/, speckit/scripts/, speckit/templates/, speckit/memory/
- [x] T004 [P] Create plugin README at speckit/README.md with installation and usage instructions

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core scripts and templates that ALL commands depend on

**CRITICAL**: No command implementation can begin until this phase is complete

- [x] T005 Create common utilities script at speckit/scripts/common.sh with shared bash functions (path helpers, JSON output, error handling)
- [x] T006 [P] Create prerequisite checker at speckit/scripts/check-prerequisites.sh to validate git, gh CLI, and feature directory structure
- [x] T007 [P] Create feature creation script at speckit/scripts/create-new-feature.sh to handle branch creation and directory setup
- [x] T008 [P] Create plan setup script at speckit/scripts/setup-plan.sh to initialize plan workflow
- [x] T009 Create spec template at speckit/templates/spec-template.md with all required sections (User Scenarios, Requirements, Success Criteria)
- [x] T010 [P] Create plan template at speckit/templates/plan-template.md with Technical Context, Constitution Check, Project Structure sections
- [x] T011 [P] Create tasks template at speckit/templates/tasks-template.md with phase structure and task format
- [x] T012 [P] Create checklist template at speckit/templates/checklist-template.md with validation items
- [x] T013 Create constitution template at speckit/memory/constitution.md with placeholder principles
- [x] T014 [P] Create context template at speckit/memory/context.md with project overview structure
- [x] T015 Create hooks configuration at speckit/hooks/hooks.json with SessionStart and PreToolUse event handlers

**Checkpoint**: Foundation ready - command implementation can now begin

---

## Phase 3: User Story 1 - Create Feature Specification (Priority: P1) MVP

**Goal**: Enable developers to create structured specifications from natural language descriptions via `/speckit:specify`

**Independent Test**: Run `/speckit:specify "Add user login"` and verify spec.md is created with all required sections in a new feature directory

### Implementation for User Story 1

- [x] T016 [US1] Create specify command at speckit/commands/specify.md with YAML frontmatter (description, user-invocable, argument-hint)
- [x] T017 [US1] Add specify command workflow in speckit/commands/specify.md: parse description, generate short name, call create-new-feature.sh
- [x] T018 [US1] Add specify command logic in speckit/commands/specify.md: load spec template, extract concepts, fill sections
- [x] T019 [US1] Add clarification handling in speckit/commands/specify.md: mark max 3 NEEDS CLARIFICATION items with structured questions
- [x] T020 [US1] Add spec validation in speckit/commands/specify.md: check mandatory sections, no implementation details, testable requirements
- [x] T021 [US1] Add checklist generation in speckit/commands/specify.md: create checklists/requirements.md for spec quality validation

**Checkpoint**: `/speckit:specify` command is fully functional - developers can create structured specifications

---

## Phase 4: User Story 2 - Generate Implementation Plan (Priority: P1)

**Goal**: Enable developers to generate implementation plans from specifications via `/speckit:plan`

**Independent Test**: Run `/speckit:plan` on a completed spec.md and verify plan.md, research.md, data-model.md, quickstart.md are created

### Implementation for User Story 2

- [x] T022 [US2] Create plan command at speckit/commands/plan.md with YAML frontmatter and prerequisite check for spec.md
- [x] T023 [US2] Add plan command Phase 0 logic in speckit/commands/plan.md: generate research.md by identifying and resolving unknowns
- [x] T024 [US2] Add plan command Phase 1 logic in speckit/commands/plan.md: generate data-model.md from spec entities
- [x] T025 [US2] Add plan command Phase 1 logic in speckit/commands/plan.md: fill Technical Context section (language, dependencies, platform)
- [x] T026 [US2] Add plan command Phase 1 logic in speckit/commands/plan.md: generate quickstart.md with getting started guide
- [x] T027 [US2] Add constitution check in speckit/commands/plan.md: validate against project principles, track violations
- [x] T028 [US2] Add project structure generation in speckit/commands/plan.md: define source code layout based on project type
- [x] T029 [P] [US2] Create update-agent-context script at speckit/scripts/update-agent-context.sh to update CLAUDE.md with new technologies

**Checkpoint**: `/speckit:plan` command is fully functional - developers can generate implementation plans

---

## Phase 5: User Story 3 - Generate Tasks from Plan (Priority: P1)

**Goal**: Enable developers to generate dependency-ordered tasks from plans via `/speckit:tasks`

**Independent Test**: Run `/speckit:tasks` on a completed plan.md and verify tasks.md is created with ordered, actionable items

### Implementation for User Story 3

- [x] T030 [US3] Create tasks command at speckit/commands/tasks.md with YAML frontmatter and prerequisite check for plan.md
- [x] T031 [US3] Add tasks command logic in speckit/commands/tasks.md: call check-prerequisites.sh and parse available docs
- [x] T032 [US3] Add tasks command logic in speckit/commands/tasks.md: extract user stories from spec.md with priorities
- [x] T033 [US3] Add tasks command logic in speckit/commands/tasks.md: map entities from data-model.md to user stories
- [x] T034 [US3] Add tasks command logic in speckit/commands/tasks.md: generate Setup and Foundational phases
- [x] T035 [US3] Add tasks command logic in speckit/commands/tasks.md: generate User Story phases with proper [P] and [Story] markers
- [x] T036 [US3] Add tasks command logic in speckit/commands/tasks.md: generate dependency graph and parallel execution examples
- [x] T037 [US3] Add tasks command validation in speckit/commands/tasks.md: verify task format, no circular dependencies

**Checkpoint**: `/speckit:tasks` command is fully functional - developers can generate task lists

---

## Phase 6: User Story 3 (continued) - Implement Tasks (Priority: P1)

**Goal**: Enable developers to execute tasks sequentially with progress tracking via `/speckit:implement`

**Independent Test**: Run `/speckit:implement` on tasks.md and verify tasks are processed with status updates

### Implementation for User Story 3 (continued)

- [x] T038 [US3] Create implement command at speckit/commands/implement.md with YAML frontmatter and prerequisite check for tasks.md
- [x] T039 [US3] Add implement command logic in speckit/commands/implement.md: parse tasks.md and identify next pending task
- [x] T040 [US3] Add implement command logic in speckit/commands/implement.md: execute task and update status from [ ] to [x]
- [x] T041 [US3] Add implement command logic in speckit/commands/implement.md: track progress and report completion percentage
- [x] T042 [US3] Add implement command logic in speckit/commands/implement.md: handle blocked tasks and dependency resolution

**Checkpoint**: Core workflow (specify → plan → tasks → implement) is complete

---

## Phase 7: User Story 4 - Convert Tasks to GitHub Issues (Priority: P2)

**Goal**: Enable developers to convert tasks to GitHub issues via `/speckit:issues`

**Independent Test**: Run `/speckit:issues` with tasks.md and verify GitHub issues are created with proper labels and dependencies

### Implementation for User Story 4

- [x] T043 [US4] Create issues command at speckit/commands/issues.md with YAML frontmatter and prerequisite check for tasks.md
- [x] T044 [US4] Add issues command logic in speckit/commands/issues.md: check gh CLI authentication status
- [x] T045 [US4] Add issues command logic in speckit/commands/issues.md: parse tasks.md and extract task details
- [x] T046 [US4] Add issues command logic in speckit/commands/issues.md: create GitHub issues with descriptions and labels using gh CLI
- [x] T047 [US4] Add issues command logic in speckit/commands/issues.md: add dependency references between issues
- [x] T048 [US4] Add issues command error handling in speckit/commands/issues.md: graceful failure when GitHub API unavailable

**Checkpoint**: `/speckit:issues` command is functional - developers can create GitHub issues from tasks

---

## Phase 8: User Story 5 - Run Clarification Questions (Priority: P2)

**Goal**: Enable developers to clarify ambiguous specification areas via `/speckit:clarify`

**Independent Test**: Run `/speckit:clarify` on a spec with NEEDS CLARIFICATION markers and verify questions are presented and answers integrated

### Implementation for User Story 5

- [x] T049 [US5] Create clarify command at speckit/commands/clarify.md with YAML frontmatter
- [x] T050 [US5] Add clarify command logic in speckit/commands/clarify.md: scan spec.md for NEEDS CLARIFICATION markers
- [x] T051 [US5] Add clarify command logic in speckit/commands/clarify.md: analyze spec for additional underspecified areas
- [x] T052 [US5] Add clarify command logic in speckit/commands/clarify.md: present up to 5 targeted questions with suggested answers
- [x] T053 [US5] Add clarify command logic in speckit/commands/clarify.md: integrate user answers back into spec.md

**Checkpoint**: `/speckit:clarify` command is functional - developers can refine specifications

---

## Phase 9: User Story 6 - Analyze Specification Consistency (Priority: P3)

**Goal**: Enable developers to verify consistency across spec, plan, and tasks via `/speckit:analyze`

**Independent Test**: Run `/speckit:analyze` on a feature with all artifacts and verify a consistency report is generated

### Implementation for User Story 6

- [x] T054 [US6] Create analyze command at speckit/commands/analyze.md with YAML frontmatter
- [x] T055 [US6] Add analyze command logic in speckit/commands/analyze.md: check all three artifacts exist (spec.md, plan.md, tasks.md)
- [x] T056 [US6] Add analyze command logic in speckit/commands/analyze.md: compare requirements in spec against plan coverage
- [x] T057 [US6] Add analyze command logic in speckit/commands/analyze.md: compare plan files against tasks coverage
- [x] T058 [US6] Add analyze command logic in speckit/commands/analyze.md: identify gaps, conflicts, and drift between artifacts
- [x] T059 [US6] Add analyze command logic in speckit/commands/analyze.md: generate consistency report with findings

**Checkpoint**: `/speckit:analyze` command is functional - developers can verify artifact consistency

---

## Phase 10: Supporting Commands

**Purpose**: Additional commands that enhance the core workflow

### Checklist Command

- [x] T060 [P] Create checklist command at speckit/commands/checklist.md with YAML frontmatter
- [x] T061 Add checklist command logic in speckit/commands/checklist.md: generate custom validation checklists based on feature type

### Constitution Command

- [x] T062 [P] Create constitution command at speckit/commands/constitution.md with YAML frontmatter
- [x] T063 Add constitution command logic in speckit/commands/constitution.md: interactive creation/update of project principles

### Validate Command

- [x] T064 [P] Create validate command at speckit/commands/validate.md with YAML frontmatter
- [x] T065 Add validate command logic in speckit/commands/validate.md: validate current feature artifacts against checklists

### Checkpoint Command

- [x] T066 [P] Create checkpoint command at speckit/commands/checkpoint.md with YAML frontmatter
- [x] T067 Add checkpoint command logic in speckit/commands/checkpoint.md: save explicit session state for later reference

### Learn Command

- [x] T068 [P] Create learn command at speckit/commands/learn.md with YAML frontmatter
- [x] T069 Add learn command logic in speckit/commands/learn.md: review and manage auto-learned patterns from sessions

### Review-PR Command

- [x] T070 [P] Create review-pr command at speckit/commands/review-pr.md with YAML frontmatter
- [x] T071 Add review-pr command logic in speckit/commands/review-pr.md: run code review using specialized agents

**Checkpoint**: All supporting commands are implemented

---

## Phase 11: Agents

**Purpose**: Specialized subagents for complex tasks

- [x] T072 [P] Create code-reviewer agent at speckit/agents/code-reviewer.md with system prompt for reviewing code quality
- [x] T073 [P] Create code-simplifier agent at speckit/agents/code-simplifier.md with system prompt for simplifying code
- [x] T074 [P] Create comment-analyzer agent at speckit/agents/comment-analyzer.md with system prompt for analyzing comments
- [x] T075 [P] Create pr-test-analyzer agent at speckit/agents/pr-test-analyzer.md with system prompt for analyzing PR tests
- [x] T076 [P] Create silent-failure-hunter agent at speckit/agents/silent-failure-hunter.md with system prompt for finding error handling issues
- [x] T077 [P] Create type-design-analyzer agent at speckit/agents/type-design-analyzer.md with system prompt for analyzing type design
- [x] T078 [P] Create agent-file-template at speckit/templates/agent-file-template.md for defining new agents

**Checkpoint**: All agents are implemented

---

## Phase 12: Hooks and Automation

**Purpose**: Event-driven automation for the plugin

- [x] T079 Update hooks configuration at speckit/hooks/hooks.json with SessionStart event to load feature context
- [x] T080 [P] Create session-start hook script at speckit/scripts/session-start.sh to load current feature state
- [x] T081 [P] Create setup-hooks script at speckit/scripts/setup-hooks.sh to initialize hooks in user project
- [x] T082 [P] Create analyze-pending script at speckit/scripts/analyze-pending.sh to analyze pending learning observations
- [x] T083 [P] Create evaluate-session script at speckit/scripts/evaluate-session.sh to evaluate session patterns

**Checkpoint**: All hooks and automation scripts are implemented

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and documentation

- [x] T084 Update plugin README at speckit/README.md with complete command reference and examples
- [x] T085 [P] Add error messages to all commands for prerequisite failures
- [x] T086 [P] Add handoff suggestions in command frontmatter for workflow guidance
- [x] T087 Verify all commands have consistent YAML frontmatter format
- [x] T088 Run manual testing: complete specify → plan → tasks → implement workflow
- [x] T089 Run manual testing: verify issues command with GitHub integration
- [x] T090 Run manual testing: verify clarify and analyze commands
- [x] T091 Document plugin in quickstart.md with installation and first-use guide

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-9)**: All depend on Foundational phase completion
  - US1, US2, US3 are all P1 - implement sequentially or in parallel
  - US4, US5 are P2 - can start after foundational
  - US6 is P3 - can start after foundational
- **Supporting Commands (Phase 10)**: Can run in parallel with user stories
- **Agents (Phase 11)**: Can run in parallel with user stories
- **Hooks (Phase 12)**: Depends on scripts from Foundational
- **Polish (Phase 13)**: Depends on all phases complete

### User Story Dependencies

| Story | Command | Depends On | Independent Test |
|-------|---------|------------|------------------|
| US1 (P1) | /specify | Foundational | Yes - creates spec from scratch |
| US2 (P1) | /plan | US1 (spec.md exists) | Yes - requires any valid spec |
| US3 (P1) | /tasks, /implement | US2 (plan.md exists) | Yes - requires any valid plan |
| US4 (P2) | /issues | US3 (tasks.md exists) | Yes - requires any valid tasks |
| US5 (P2) | /clarify | Foundational | Yes - works on any spec |
| US6 (P3) | /analyze | Foundational | Yes - checks if artifacts exist |

### Parallel Opportunities

**Within Foundational (Phase 2)**:
```
T005 (common.sh) → T006, T007, T008 (depend on common.sh)
T009, T010, T011, T012, T013, T014, T015 can all run in parallel
```

**Within User Story Phases**:
- Tasks marked [P] within each phase can run in parallel
- Different user story phases can be worked on in parallel by different team members

**Supporting Commands (Phase 10)**:
- All T060-T071 are independent and can run in parallel

**Agents (Phase 11)**:
- All T072-T078 are independent and can run in parallel

---

## Parallel Example: Foundational Phase

```bash
# First: Create common utilities (dependency for other scripts)
Task: T005 Create common utilities script at speckit/scripts/common.sh

# Then these can run in parallel:
Task: T006 [P] Create prerequisite checker at speckit/scripts/check-prerequisites.sh
Task: T007 [P] Create feature creation script at speckit/scripts/create-new-feature.sh
Task: T008 [P] Create plan setup script at speckit/scripts/setup-plan.sh

# Templates can all run in parallel (no dependencies):
Task: T009 Create spec template at speckit/templates/spec-template.md
Task: T010 [P] Create plan template at speckit/templates/plan-template.md
Task: T011 [P] Create tasks template at speckit/templates/tasks-template.md
Task: T012 [P] Create checklist template at speckit/templates/checklist-template.md
```

---

## Implementation Strategy

### MVP First (User Stories 1-3 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T015)
3. Complete Phase 3: User Story 1 - /specify (T016-T021)
4. **STOP and VALIDATE**: Test `/speckit:specify` independently
5. Complete Phase 4: User Story 2 - /plan (T022-T029)
6. **STOP and VALIDATE**: Test `/speckit:plan` independently
7. Complete Phases 5-6: User Story 3 - /tasks, /implement (T030-T042)
8. **STOP and VALIDATE**: Test complete workflow
9. Deploy/demo MVP (core workflow working)

### Incremental Delivery After MVP

1. Add User Story 4 - /issues (T043-T048) → GitHub integration
2. Add User Story 5 - /clarify (T049-T053) → Spec refinement
3. Add User Story 6 - /analyze (T054-T059) → Consistency checking
4. Add Supporting Commands (T060-T071) → Enhanced workflow
5. Add Agents (T072-T078) → Code review capabilities
6. Add Hooks (T079-T083) → Automation
7. Polish (T084-T091) → Final testing and docs

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Tasks** | 91 |
| **Setup Phase** | 4 |
| **Foundational Phase** | 11 |
| **US1 (specify)** | 6 |
| **US2 (plan)** | 8 |
| **US3 (tasks/implement)** | 13 |
| **US4 (issues)** | 6 |
| **US5 (clarify)** | 5 |
| **US6 (analyze)** | 6 |
| **Supporting Commands** | 12 |
| **Agents** | 7 |
| **Hooks/Automation** | 5 |
| **Polish** | 8 |
| **Parallel Opportunities** | 42 tasks marked [P] |

### MVP Scope (Recommended)

- **Phases 1-6**: Setup + Foundational + US1 + US2 + US3
- **Task Count**: 42 tasks
- **Deliverable**: Complete specify → plan → tasks → implement workflow

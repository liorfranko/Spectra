---
description: "Generate dependency-ordered tasks from an implementation plan"
user-invocable: true
---

# Tasks Command

Generate an actionable, dependency-ordered `tasks.md` file from the implementation plan and feature specification. This command analyzes the plan's architecture decisions, technical components, and integration points to produce granular development tasks organized into logical phases.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Prerequisites

This command requires that `plan.md` exists in the current feature directory. The plan provides the architectural foundation and component breakdown needed to generate meaningful tasks.

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-plan
```

If the prerequisite check fails, run `/spectra:plan` first to generate the implementation plan.

## Workflow

### Step 1: Check Prerequisites and Parse Available Documents

**1.1: Run prerequisite check script**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-plan --json --include-tasks
```

**1.2: Parse JSON output to extract:**
- `FEATURE_DIR` - The path to the current feature directory
- `AVAILABLE_DOCS` - List of documents that exist in the feature directory

**1.3: Verify plan.md exists**

If plan.md is not found in AVAILABLE_DOCS, display an error message instructing the user to run `/spectra:plan` first, then stop execution.

**1.4: Read available documents and extract context:**

| Document | Required | Extract |
|----------|----------|---------|
| `plan.md` | Yes | Technical Context section, Project Structure section, Component breakdown, Architecture decisions |
| `spec.md` | Yes | User Stories section, Requirements section, Acceptance criteria |
| `data-model.md` | No | Entity definitions, Relationships between entities |
| `research.md` | No | Key Decisions section, Technology choices |

For each document:
- Check if it exists in AVAILABLE_DOCS
- If required and missing, display error and stop
- If optional and missing, continue without that context
- Parse the relevant sections and store the extracted information

**1.5: Store parsed context for subsequent steps**

Create a structured context object containing:
- Feature directory path
- Parsed plan content (technical context, project structure, components)
- Parsed spec content (user stories, requirements)
- Parsed data model content (entities, relationships) - if available
- Parsed research content (decisions) - if available

This context will be used by Steps 2-7 to generate the tasks.

### Step 2: Extract User Stories from spec.md

**2.1: Parse the User Scenarios section from spec.md**

Locate the "User Scenarios" or "User Stories" section in the parsed spec.md content. This section contains the primary user-facing functionality that drives task generation.

**2.2: For each user scenario, extract the following fields:**

| Field | Format | Description |
|-------|--------|-------------|
| Story ID | `US-###` | Unique identifier for the user story (e.g., US-001, US-002) |
| Title/Description | String | Brief description of what the user wants to accomplish |
| Priority | `P1`, `P2`, `P3` | Priority level where P1 is highest priority |
| Acceptance Criteria | List | Testable conditions that define story completion |
| Related Requirements | `FR-###` | Functional requirement identifiers this story satisfies |

For each story found, create a structured object:
```
{
  id: "US-###",
  title: "Story title",
  description: "Full story description",
  priority: "P1" | "P2" | "P3",
  acceptanceCriteria: ["Criterion 1", "Criterion 2", ...],
  relatedRequirements: ["FR-001", "FR-002", ...]
}
```

**2.3: Sort stories by priority**

Order the extracted stories by priority level:
1. P1 stories first (critical path, must-have functionality)
2. P2 stories second (important but not blocking)
3. P3 stories last (nice-to-have, can be deferred)

Within the same priority level, maintain the original document order.

**2.4: Create a story-to-tasks mapping structure**

Initialize a mapping structure that will be populated in subsequent steps:
```
storyToTasksMap = {
  "US-001": {
    story: { ... },      // The extracted story object
    tasks: [],           // Will be populated with generated task IDs
    dependencies: [],    // Other story IDs this story depends on
    entities: []         // Entity names this story interacts with (from Step 3)
  },
  ...
}
```

This mapping structure enables:
- Traceability from tasks back to user stories
- Dependency analysis between stories
- Phase organization based on story priorities
- Validation that all stories have corresponding tasks

### Step 3: Map Entities from data-model.md to User Stories

This step creates a mapping between data model entities and the user stories that depend on them. This mapping is essential for identifying foundational entities that must be implemented early and for ensuring proper task ordering.

**3.1: Read entities from data-model.md (if exists)**

Check if `data-model.md` exists in the AVAILABLE_DOCS from Step 1. If the file does not exist, skip to Step 4 with an empty entity mapping.

If `data-model.md` exists, parse the entity definitions section. Entities are typically defined with the following structure:
- Entity name (heading level 3 or 4)
- Attributes/fields list
- Relationships to other entities
- Validation rules or constraints

**3.2: For each entity, identify required information**

For each entity found in data-model.md, extract and record:

| Information | Description | Example |
|-------------|-------------|---------|
| Entity Name | The name of the data entity | `User`, `Project`, `Task` |
| Attributes | List of fields/properties | `id`, `name`, `createdAt` |
| Relationships | References to other entities | `belongsTo: User`, `hasMany: Tasks` |
| Required Tasks | Standard implementation tasks needed | See below |

For each entity, the following tasks are typically required:

```
entityTasks = {
  modelDefinition: "Define {Entity} model/schema",
  validation: "Implement {Entity} validation rules",
  persistence: "Create {Entity} storage/repository layer",
  serialization: "Add {Entity} serialization/deserialization"
}
```

**3.3: Create entity-to-story mapping**

Cross-reference entities with the user stories extracted in Step 2. For each entity, identify which user stories interact with it by:

1. Scanning story descriptions for entity name mentions
2. Checking acceptance criteria for entity-related operations (create, read, update, delete)
3. Analyzing related requirements that reference the entity

Build the mapping structure:
```
entityToStoryMap = {
  "EntityName": {
    name: "EntityName",
    attributes: [...],
    relationships: [...],
    usedByStories: ["US-001", "US-003", ...],  // Story IDs that use this entity
    dependsOnEntities: [...],                   // Other entities this one references
    requiredTasks: [...]                        // Tasks needed to implement this entity
  },
  ...
}
```

Also update the storyToTasksMap from Step 2.4 to include entity references:
```
storyToTasksMap["US-001"].entities = ["EntityName1", "EntityName2", ...]
```

**3.4: Identify foundation entities (used by multiple stories)**

Analyze the entityToStoryMap to identify entities that are foundational to the system:

```
foundationEntities = entities where:
  - usedByStories.length >= 2, OR
  - entity is referenced by other entities (is a dependency), OR
  - entity represents core domain concepts (User, Config, etc.)
```

For each entity, calculate a "foundation score":
```
foundationScore = (usedByStories.count * 2) + (referencedByEntities.count * 3)
```

Entities with a foundation score >= 4 should be considered foundational.

**3.5: Flag entities that need to be in Foundational phase**

Mark entities for inclusion in the Foundational phase (Phase 1) based on:

1. **Dependency Analysis**: Entities that other entities depend on must be implemented first
2. **Cross-Story Usage**: Entities used by multiple P1 stories are foundational
3. **Core Domain Status**: Entities representing fundamental domain concepts

Create a prioritized list for foundational implementation:
```
foundationalEntities = [
  {
    entity: "EntityName",
    reason: "Used by 3 user stories" | "Required by Entity X, Y" | "Core domain entity",
    phase: 1,  // Foundational phase
    implementationOrder: 1  // Order within the phase
  },
  ...
]
```

Non-foundational entities are assigned to later phases based on which user story first requires them:
```
storyPhaseEntities = [
  {
    entity: "EntityName",
    reason: "First used by US-003",
    phase: 3,  // Phase number matching the user story
    implementationOrder: 1  // Implemented before story-specific logic
  },
  ...
]
```

Store both lists for use in Step 4 (Foundational phase generation) and Step 5 (User story phase generation).

### Step 4: Generate Setup and Foundational Phases

This step creates the initial phases that establish project infrastructure and shared components before user story implementation begins.

**4.1: Create Phase 1 - Setup tasks**

Generate tasks for project initialization and environment setup. These tasks have no dependencies and can often run in parallel.

| Category | Task Type | Description |
|----------|-----------|-------------|
| Structure | Directory creation | Create project directory structure as defined in plan.md Project Structure section |
| Structure | File scaffolding | Create placeholder files for main entry points |
| Configuration | Config files | Generate configuration files (package.json, tsconfig.json, etc. based on technology stack) |
| Configuration | Environment setup | Create environment variable templates (.env.example) |
| Configuration | Linting/formatting | Set up code quality tools (ESLint, Prettier, etc.) |
| Dependencies | Package installation | Install required dependencies from plan.md |
| Dependencies | Dev dependencies | Install development and testing dependencies |
| Documentation | Initial docs | Create minimal README with setup instructions |

For each setup task, create an entry:
```
{
  id: "T001",  // Sequential task ID
  phase: 1,
  category: "setup",
  description: "Create project directory structure",
  filePath: "project root or specific path",
  parallel: true,  // Can run alongside other setup tasks
  blockedBy: [],   // No dependencies for setup tasks
  acceptanceCriteria: ["Directory structure matches plan.md specification"]
}
```

**4.2: Create Phase 2 - Foundational tasks**

Generate tasks for core utilities, foundation entities, and shared components that multiple user stories depend on.

**4.2.1: Core utilities and scripts**

Identify common utilities from plan.md Technical Context section:
- Helper functions (string manipulation, date formatting, etc.)
- Logging infrastructure
- Error handling utilities
- Configuration loading utilities

**4.2.2: Foundation entities (from Step 3.5)**

For each entity in the `foundationalEntities` list from Step 3.5, generate implementation tasks:

```
For each foundationalEntity:
  Generate tasks:
    - "Define {Entity} model/schema" (T0XX)
    - "Implement {Entity} validation rules" (T0XX) - blockedBy: model task
    - "Create {Entity} storage layer" (T0XX) - blockedBy: model task
```

Order foundation entity tasks by their `implementationOrder` from Step 3.5.

**4.2.3: Shared components used by multiple stories**

Analyze the storyToTasksMap from Step 2.4 to identify shared components:
- Components referenced by 2+ user stories
- Abstract base classes or interfaces
- Shared UI components (if applicable)
- Common API patterns or middleware

For each shared component:
```
{
  id: "T0XX",
  phase: 2,
  category: "foundation",
  description: "Implement {SharedComponent}",
  filePath: "path from plan.md structure",
  parallel: false,  // Usually sequential within foundation
  blockedBy: ["T001", ...],  // Depends on setup tasks
  acceptanceCriteria: ["Component is reusable by multiple features"]
}
```

**4.2.4: Base templates**

If plan.md defines template patterns, create tasks for:
- Base template files
- Template helpers or partials
- Template configuration

**4.3: Assign task IDs**

Assign sequential task IDs using the format `T###`:
- Phase 1 (Setup): T001 - T099
- Phase 2 (Foundational): T100 - T199
- Reserve T200+ for user story phases (Step 5)

Task ID assignment rules:
1. IDs are unique across all phases
2. IDs are assigned in execution order within each phase
3. Lower IDs indicate earlier execution (when no blocking dependencies)

**4.4: Mark parallel tasks with [P]**

Identify tasks that can execute in parallel and mark them with `[P]`:

Parallel criteria:
- No shared file modifications
- No dependency relationship
- No shared resource contention
- Can be completed independently

Examples of parallel tasks:
- Creating independent directory structures `[P]`
- Installing unrelated dependencies `[P]`
- Creating separate configuration files `[P]`

**4.5: Define blocking relationships**

Establish `blockedBy` relationships for each task:

| Task Type | Typically Blocked By |
|-----------|---------------------|
| Directory creation | None (can start immediately) |
| Configuration files | Directory creation |
| Dependency installation | Configuration files (package.json, etc.) |
| Foundation entities | Setup tasks completion |
| Entity validation | Entity model definition |
| Entity storage | Entity model definition |
| Shared components | Foundation entities they depend on |

Store the generated Phase 1 and Phase 2 tasks in a structured format:
```
setupAndFoundationTasks = {
  phase1: [
    { id: "T001", description: "...", parallel: true, blockedBy: [], ... },
    { id: "T002", description: "...", parallel: true, blockedBy: [], ... },
    ...
  ],
  phase2: [
    { id: "T100", description: "...", parallel: false, blockedBy: ["T001", "T002"], ... },
    ...
  ]
}
```

**Task format for output:**

Each task should be formatted as:
```
- [ ] T### [P?] Description (file path)
```

Where:
- `T###` is the task ID
- `[P]` is included only if the task can run in parallel
- `Description` is a clear, actionable task description
- `(file path)` is the primary file or directory affected

### Step 5: Generate User Story Phases

This step creates implementation phases for each user story extracted in Step 2, generating granular tasks with proper markers for story traceability and parallel execution.

**5.1: Create a phase for each user story**

For each user story in the sorted `storyToTasksMap` from Step 2.3, create a dedicated phase:

| Story Priority | Phase Number | Phase Title Format |
|----------------|--------------|-------------------|
| P1 stories | Starting at Phase 3 | `Phase 3: User Story 1 (US-001)` |
| P2 stories | Continuing sequence | `Phase 4: User Story 2 (US-002)` |
| P3 stories | Continuing sequence | `Phase N: User Story N (US-00N)` |

Phase numbering follows this pattern:
- Phase 1: Setup (from Step 4.1)
- Phase 2: Foundational (from Step 4.2)
- Phase 3+: User Stories (one phase per story, ordered by priority)

For each phase, create a header structure:
```
{
  phaseNumber: 3,
  phaseTitle: "User Story 1",
  storyId: "US-001",
  storyDescription: "As a user, I want to...",
  tasks: []  // Will be populated in 5.2
}
```

**5.2: Generate tasks for each story phase**

For each user story phase, generate the following task categories in order:

**5.2.1: Story-specific entities (from Step 3.3)**

Check the `storyPhaseEntities` list from Step 3.5 for entities assigned to this phase:

```
For each entity where entity.phase == currentPhaseNumber:
  Generate tasks:
    - "Define {Entity} model/schema" [US#]
    - "Implement {Entity} validation rules" [US#] - blockedBy: model task
    - "Create {Entity} storage layer" [US#] - blockedBy: model task
    - "Add {Entity} serialization/deserialization" [US#] - blockedBy: model task
```

These entity tasks are generated before implementation tasks because story logic depends on entity definitions.

**5.2.2: Implementation tasks**

Analyze the user story description and acceptance criteria to generate core implementation tasks:

| Task Category | Description | Example |
|---------------|-------------|---------|
| Core logic | Main business logic for the story | "Implement story validation logic" |
| Service layer | Service methods required by the story | "Create {Feature}Service with {operation} method" |
| API endpoints | REST/GraphQL endpoints (if applicable) | "Add POST /api/{resource} endpoint" |
| UI components | User interface elements (if applicable) | "Create {Component} React component" |
| State management | State updates and handlers | "Implement {feature} state management" |
| Error handling | Story-specific error cases | "Add error handling for {scenario}" |

For each implementation task:
```
{
  id: "T2XX",
  phase: currentPhaseNumber,
  category: "implementation",
  storyId: "US-001",
  description: "Implement {feature}",
  filePath: "path from plan.md structure",
  blockedBy: [entity task IDs from 5.2.1]
}
```

**5.2.3: Integration tasks**

Generate tasks that connect the story implementation to existing system components:

| Integration Type | Task Description |
|-----------------|------------------|
| Cross-component | "Integrate {StoryFeature} with {ExistingComponent}" |
| API integration | "Connect {StoryFeature} to {APIEndpoint}" |
| Event handling | "Wire {StoryEvent} to event bus/handlers" |
| Data flow | "Connect {StoryComponent} to data store" |

Integration tasks are blocked by their corresponding implementation tasks:
```
{
  id: "T2XX",
  phase: currentPhaseNumber,
  category: "integration",
  storyId: "US-001",
  description: "Integrate {feature} with {component}",
  blockedBy: [implementation task IDs from 5.2.2]
}
```

**5.2.4: Test tasks**

Generate testing tasks based on the story's acceptance criteria:

| Test Type | Task Description | Blocked By |
|-----------|------------------|------------|
| Unit tests | "Write unit tests for {Entity/Service}" | Entity/Implementation tasks |
| Integration tests | "Create integration tests for {Feature}" | Integration tasks |
| Acceptance tests | "Implement acceptance test for: {criterion}" | All story tasks |

For each acceptance criterion from the story, create a corresponding test task:
```
For each criterion in story.acceptanceCriteria:
  Generate task:
    - "Verify: {criterion}" [US#] - blockedBy: integration tasks
```

**5.3: Mark tasks with [US#] marker**

Every task generated for a user story phase MUST include the story marker:

Format: `[US#]` where `#` is the story number (e.g., `[US1]`, `[US2]`, `[US3]`)

The marker appears after the task ID and any parallel marker:
```
- [ ] T201 [US1] Implement user authentication logic (src/auth/service.ts)
- [ ] T202 [P] [US1] Create login form component (src/components/LoginForm.tsx)
```

This marker enables:
- Filtering tasks by user story
- Traceability from tasks to requirements
- Progress tracking per story
- Story-based sprint planning

**5.4: Mark parallel tasks with [P]**

Identify tasks within each story phase that can execute in parallel and mark them with `[P]`:

Parallel criteria within a story:
- Tasks modify different files
- No shared state dependencies
- No sequential data requirements
- Can be completed by different developers simultaneously

Common parallel patterns:
| Parallel Set | Example Tasks |
|--------------|---------------|
| Independent components | `[P] [US1] Create HeaderComponent`, `[P] [US1] Create FooterComponent` |
| Separate test files | `[P] [US1] Write unit tests for ServiceA`, `[P] [US1] Write unit tests for ServiceB` |
| Independent integrations | `[P] [US1] Integrate with LoggingService`, `[P] [US1] Integrate with MetricsService` |

The `[P]` marker appears immediately after the task ID:
```
- [ ] T203 [P] [US1] Task that can run in parallel (file/path)
- [ ] T204 [P] [US1] Another parallel task (different/file/path)
```

**5.5: Add checkpoint after each story phase**

After all tasks for a user story phase, add a checkpoint task:

```
- [ ] T2XX [US#] CHECKPOINT: Verify {Story Title} is complete and functional
```

The checkpoint task:
- Is blocked by ALL tasks in the current story phase
- Verifies all acceptance criteria are met
- Acts as a gate before the next story phase
- Provides a natural review/demo point

Checkpoint format:
```
{
  id: "T2XX",
  phase: currentPhaseNumber,
  category: "checkpoint",
  storyId: "US-001",
  description: "CHECKPOINT: Verify {Story Title} is complete and functional",
  blockedBy: [all task IDs in this phase],
  acceptanceCriteria: story.acceptanceCriteria  // Inherited from story
}
```

**Task format for story phase output:**

Each task in a story phase should be formatted as:
```
- [ ] T### [P?] [US#] Description (file path)
```

Where:
- `T###` is the task ID (T200+ for story phases)
- `[P]` is included only if the task can run in parallel
- `[US#]` is the user story marker (required for all story tasks)
- `Description` is a clear, actionable task description
- `(file path)` is the primary file or directory affected

**Example story phase output:**

```markdown
## Phase 3: User Authentication (US-001)

Story: As a user, I want to log in so that I can access my dashboard.

### Entity Tasks
- [ ] T200 [US1] Define User model schema (src/models/user.ts)
- [ ] T201 [US1] Implement User validation rules (src/models/user.ts)
- [ ] T202 [US1] Create User storage layer (src/repositories/userRepository.ts)

### Implementation Tasks
- [ ] T203 [US1] Implement authentication service (src/services/authService.ts)
- [ ] T204 [US1] Create login endpoint (src/api/auth/login.ts)
- [ ] T205 [P] [US1] Create login form component (src/components/LoginForm.tsx)
- [ ] T206 [P] [US1] Create auth state management (src/store/authSlice.ts)

### Integration Tasks
- [ ] T207 [US1] Connect login form to auth service (src/pages/Login.tsx)
- [ ] T208 [US1] Integrate auth state with router guards (src/router/guards.ts)

### Test Tasks
- [ ] T209 [P] [US1] Write unit tests for authService (tests/services/authService.test.ts)
- [ ] T210 [P] [US1] Write unit tests for User model (tests/models/user.test.ts)
- [ ] T211 [US1] Create integration tests for login flow (tests/integration/auth.test.ts)
- [ ] T212 [US1] Verify: User can log in with valid credentials (tests/e2e/login.test.ts)
- [ ] T213 [US1] Verify: Invalid credentials show error message (tests/e2e/login.test.ts)

### Checkpoint
- [ ] T214 [US1] CHECKPOINT: Verify User Authentication is complete and functional
```

### Step 6: Generate Dependency Graph

This step creates a comprehensive dependency structure that visualizes task relationships, enables parallel execution planning, and ensures correct execution ordering.

**6.1: Create Dependencies section in tasks.md**

Generate a Dependencies section that documents both phase-level and task-level dependencies.

**6.1.1: Phase dependencies**

Document how phases depend on each other:

```markdown
## Dependencies

### Phase Dependencies

| Phase | Depends On | Description |
|-------|------------|-------------|
| Phase 1: Setup | None | Initial project setup, no prerequisites |
| Phase 2: Foundational | Phase 1 | Requires project structure and configuration |
| Phase 3: {Story Title} | Phase 2 | Requires foundational entities and utilities |
| Phase 4: {Story Title} | Phase 2, Phase 3* | Requires foundation; *optional dependency on Phase 3 |
| ... | ... | ... |
```

Phase dependency rules:
- Phase 1 (Setup) has no dependencies
- Phase 2 (Foundational) depends on Phase 1 completion
- User story phases (3+) depend on Phase 2 completion
- User story phases MAY have optional dependencies on earlier story phases if they share entities or components

**6.1.2: Task dependencies within phases**

For each phase, document the internal task dependency structure:

```markdown
### Phase 2: Foundational - Internal Dependencies

| Task | Depends On | Parallel Group |
|------|------------|----------------|
| T100 | T001, T002 | - |
| T101 | T100 | A |
| T102 | T100 | A |
| T103 | T101, T102 | - |
```

Parallel Group indicates tasks that can execute simultaneously (same letter = same parallel group).

**6.2: Create dependency table**

Generate a comprehensive dependency table covering all tasks:

```markdown
### Complete Task Dependency Table

| Task ID | Description | Blocked By | Blocks | Parallel |
|---------|-------------|------------|--------|----------|
| T001 | Create project directory structure | - | T002, T003, T100 | Yes |
| T002 | Initialize package.json | T001 | T004, T005 | Yes |
| T003 | Create .env.example template | T001 | T100 | Yes |
| T004 | Install production dependencies | T002 | T100 | No |
| T005 | Install dev dependencies | T002 | T100 | No |
| T100 | Define User model schema | T001-T005 | T101, T102, T103 | No |
| T101 | Implement User validation | T100 | T104 | Yes |
| T102 | Create User repository | T100 | T104 | Yes |
| T103 | Add User serialization | T100 | T104 | Yes |
| T104 | Integrate User with auth service | T101, T102, T103 | T200 | No |
| ... | ... | ... | ... | ... |
```

Table columns:
- **Task ID**: Unique task identifier
- **Description**: Brief task description
- **Blocked By**: Task IDs that must complete before this task can start (use `-` for no blockers)
- **Blocks**: Task IDs that are waiting for this task to complete
- **Parallel**: Whether this task can run in parallel with other tasks in its group

**6.2.1: Dependency table generation rules**

1. Parse all tasks from Phases 1-N
2. For each task, identify:
   - Direct blockers (tasks explicitly referenced in `blockedBy`)
   - Implicit blockers (phase dependencies)
   - Tasks it blocks (reverse lookup of `blockedBy` references)
3. Mark parallel capability based on `[P]` marker

**6.3: Generate parallel execution examples**

Create practical examples showing how tasks can be executed in parallel to optimize development time.

**6.3.1: Identify parallel task groups**

Analyze all tasks marked with `[P]` and group them by execution window:

```markdown
### Parallel Execution Groups

#### Group A: Initial Setup (Phase 1)
Tasks that can run simultaneously at project start:
- T001: Create project directory structure
- T002: Create .gitignore
- T003: Create README.md

**Execution**: All 3 tasks can start immediately, no waiting required.

#### Group B: Configuration (Phase 1)
Tasks that can run after Group A completes:
- T004: Initialize package.json
- T005: Create tsconfig.json
- T006: Create .env.example

**Execution**: All 3 tasks can start once directory structure exists.

#### Group C: Foundation Entities (Phase 2)
Independent entity implementations:
- T101: Implement User validation
- T102: Create User repository
- T103: Add User serialization

**Execution**: All 3 can run in parallel after T100 (User model) completes.

#### Group D: Story Components (Phase 3)
Independent UI components:
- T205: Create LoginForm component
- T206: Create auth state management

**Execution**: Both can run in parallel after core implementation tasks.
```

**6.3.2: Example execution flow**

Provide a complete execution flow example showing optimal parallelization:

```markdown
### Example Execution Flow

This example shows how a 2-developer team could execute tasks optimally:

**Sprint 1, Day 1:**
```
Developer A                    Developer B
─────────────                  ─────────────
T001 Create directories        T002 Create .gitignore
     │                              │
     ├──────────┬──────────────────┘
     ▼          ▼
T004 package.json              T005 tsconfig.json
     │                              │
     └──────────┬──────────────────┘
                ▼
         (Both complete)
```

**Sprint 1, Day 2:**
```
Developer A                    Developer B
─────────────                  ─────────────
T100 Define User model         (waiting)
     │
     ├─────────────────────────────┐
     ▼                             ▼
T101 User validation           T102 User repository
     │                             │
     ├─────────────────────────────┘
     ▼
T104 Integrate with auth
```

**Sprint 1, Day 3:**
```
Developer A                    Developer B
─────────────                  ─────────────
T200 Implement auth service    T205 [P] LoginForm component
     │                              │
     │                         T206 [P] Auth state mgmt
     │                              │
     └─────────────────────────────┘
                ▼
         T207 Connect form to service
```

**Estimated time savings:**
- Sequential execution: 15 task-units
- Parallel execution: 9 task-units
- Time saved: 40%
```

**6.3.3: Parallel execution warnings**

Document situations where parallel execution should be avoided:

```markdown
### Parallel Execution Warnings

**Do NOT run in parallel:**

1. **Shared file modifications**
   - T104 and T105 both modify `src/services/index.ts`
   - Run sequentially to avoid merge conflicts

2. **Database migrations**
   - T110 and T111 both create database migrations
   - Run sequentially to maintain migration order

3. **Package installations with conflicts**
   - T004 and T007 install packages with peer dependency conflicts
   - Run T004 first, then T007

4. **Test execution during implementation**
   - T209 tests depend on T203 implementation
   - Wait for implementation before running tests
```

**6.4: Create ASCII dependency diagram**

Generate a visual dependency diagram for complex relationships.

**6.4.1: Simple linear dependencies**

```markdown
### Dependency Diagram: Phase 1 → Phase 2 Flow

┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: SETUP                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────┐     ┌───────┐     ┌───────┐                         │
│  │ T001  │────▶│ T002  │────▶│ T004  │                         │
│  │ dirs  │     │ pkg   │     │ deps  │                         │
│  └───────┘     └───────┘     └───────┘                         │
│       │                           │                             │
│       │        ┌───────┐          │                             │
│       └───────▶│ T003  │──────────┤                             │
│                │ env   │          │                             │
│                └───────┘          │                             │
│                                   ▼                             │
│                          ┌─────────────┐                        │
│                          │ PHASE 1     │                        │
│                          │ COMPLETE    │                        │
│                          └─────────────┘                        │
│                                   │                             │
└───────────────────────────────────│─────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────┐
│ PHASE 2: FOUNDATIONAL                                             │
└───────────────────────────────────────────────────────────────────┘
```

**6.4.2: Parallel branching diagram**

```markdown
### Dependency Diagram: Parallel Entity Implementation

                        ┌───────────────┐
                        │     T100      │
                        │  User Model   │
                        └───────┬───────┘
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
            ▼                   ▼                   ▼
    ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
    │     T101      │   │     T102      │   │     T103      │
    │  Validation   │   │  Repository   │   │ Serialization │
    │     [P]       │   │     [P]       │   │     [P]       │
    └───────┬───────┘   └───────┬───────┘   └───────┬───────┘
            │                   │                   │
            └───────────────────┼───────────────────┘
                                │
                                ▼
                        ┌───────────────┐
                        │     T104      │
                        │  Integration  │
                        └───────────────┘

[P] = Can execute in parallel
```

**6.4.3: Complex cross-phase dependencies**

```markdown
### Dependency Diagram: Cross-Phase Story Dependencies

PHASE 2                    PHASE 3 (US-001)              PHASE 4 (US-002)
─────────                  ───────────────               ───────────────

┌─────────┐
│  T100   │
│  User   │
│  Model  │
└────┬────┘
     │
     ├─────────────────────┐
     │                     │
     ▼                     ▼
┌─────────┐           ┌─────────┐
│  T104   │           │  T200   │
│  Auth   │──────────▶│  Login  │
│ Service │           │ Service │
└─────────┘           └────┬────┘
                           │
                           │                         ┌─────────┐
                           │                         │  T300   │
                           ├────────────────────────▶│ Profile │
                           │                         │ Service │
                           │                         └────┬────┘
                           ▼                              │
                      ┌─────────┐                         │
                      │  T214   │                         │
                      │  US-001 │                         │
                      │  CKPT   │                         │
                      └────┬────┘                         │
                           │                              │
                           └──────────────────────────────┤
                                                          ▼
                                                     ┌─────────┐
                                                     │  T314   │
                                                     │  US-002 │
                                                     │  CKPT   │
                                                     └─────────┘

LEGEND:
─────▶  Direct dependency (blockedBy)
─ ─ ─▶  Optional/soft dependency
CKPT    Checkpoint task
```

**6.4.4: Diagram generation guidelines**

When generating ASCII diagrams:

1. **Use consistent symbols**:
   - `┌─┐└─┘│─` for boxes
   - `───▶` for dependencies
   - `─ ─▶` for optional dependencies
   - `[P]` marker for parallel tasks

2. **Layout rules**:
   - Earlier phases on the left
   - Later phases on the right
   - Parallel tasks at the same vertical level
   - Dependencies flow left-to-right or top-to-bottom

3. **Include legend** for complex diagrams

4. **Limit width** to 80 characters for terminal compatibility

5. **Break large diagrams** into phase-specific sections

**6.4.5: Store dependency data for validation**

After generating the dependency graph, store the structured data for use in Step 7 (validation):

```
dependencyGraph = {
  phases: [
    {
      number: 1,
      name: "Setup",
      dependsOn: [],
      tasks: ["T001", "T002", ...]
    },
    ...
  ],
  tasks: {
    "T001": { blockedBy: [], blocks: ["T002", "T003", "T100"] },
    "T002": { blockedBy: ["T001"], blocks: ["T004", "T005"] },
    ...
  },
  parallelGroups: [
    { name: "A", tasks: ["T001", "T002", "T003"] },
    { name: "B", tasks: ["T101", "T102", "T103"] },
    ...
  ],
  criticalPath: ["T001", "T004", "T100", "T104", "T200", ...]
}
```

This data structure enables:
- Circular dependency detection in Step 7
- Execution order optimization
- Progress tracking and estimation
- Bottleneck identification

### Step 7: Validate Task Format

This step performs comprehensive validation of the generated tasks to ensure format consistency, dependency integrity, and priority correctness before writing the final output.

**7.1: Verify all tasks have correct format**

For each task in the generated task list, validate the following format requirements:

| Field | Format | Validation Rule |
|-------|--------|-----------------|
| Task ID | `T###` | Must be exactly T followed by three digits (e.g., T001, T042, T999) |
| Checkbox | `- [ ] T###` | Must start with unchecked checkbox format |
| Parallel marker | `[P]` | Optional; if present, must appear immediately after task ID |
| Story marker | `[US#]` | Optional; if present, must appear after [P] marker (if any) |
| Description | String | Must be present and non-empty |
| File path | `(path)` | Optional; if present, must be in parentheses at end |

**Format validation regex patterns:**

```
Task ID:       ^T\d{3}$
Full task:     ^- \[ \] T\d{3}(\s+\[P\])?(\s+\[US\d+\])?\s+.+(\s+\(.+\))?$
Parallel:      \[P\]
Story marker:  \[US\d+\]
```

**7.1.1: Task ID uniqueness check**

Build a set of all task IDs and verify:
- No duplicate task IDs exist
- Task IDs are sequential within each phase
- Task IDs follow the phase numbering convention:
  - Phase 1 (Setup): T001 - T099
  - Phase 2 (Foundational): T100 - T199
  - Phase 3+ (User Stories): T200+

**7.1.2: Format error collection**

For each format violation found:
```
formatErrors.push({
  taskId: "T###" or "UNKNOWN",
  line: lineNumber,
  error: "Description of format violation",
  severity: "error" | "warning"
})
```

**7.2: Check for circular dependencies**

Circular dependencies would create an infinite loop where tasks can never be completed. Use depth-first search (DFS) to detect cycles in the dependency graph.

**7.2.1: Build the dependency graph**

Using the `dependencyGraph.tasks` data from Step 6.4.5:

```
graph = {}
for each task in allTasks:
  graph[task.id] = {
    blockedBy: task.blockedBy,  // Tasks this task depends on
    blocks: task.blocks,        // Tasks that depend on this task
    visited: false,
    inStack: false
  }
```

**7.2.2: Detect cycles using DFS**

Implement cycle detection algorithm:

```
function detectCycles(graph):
  cycles = []

  function dfs(taskId, path):
    if graph[taskId].inStack:
      // Cycle detected - extract the cycle
      cycleStart = path.indexOf(taskId)
      cycle = path.slice(cycleStart).concat(taskId)
      cycles.push(cycle)
      return true

    if graph[taskId].visited:
      return false

    graph[taskId].visited = true
    graph[taskId].inStack = true
    path.push(taskId)

    for each dependency in graph[taskId].blockedBy:
      dfs(dependency, path)

    path.pop()
    graph[taskId].inStack = false
    return false

  for each taskId in graph:
    if not graph[taskId].visited:
      dfs(taskId, [])

  return cycles
```

**7.2.3: Error if cycles found**

If any cycles are detected:
```
for each cycle in cycles:
  cycleString = cycle.join(" → ")
  dependencyErrors.push({
    type: "circular_dependency",
    severity: "error",
    message: "Circular dependency detected: " + cycleString,
    tasks: cycle
  })
```

Display error message:
```
ERROR: Circular dependencies detected in task graph:
  - T101 → T102 → T103 → T101

Tasks in a cycle can never be completed. Please review and break the cycle
by removing one of the dependency relationships.
```

**7.3: Verify all dependency references are valid**

Ensure that every task ID referenced in `blockedBy` or `blocks` actually exists in the task list.

**7.3.1: Validate blockedBy references**

```
for each task in allTasks:
  for each dependencyId in task.blockedBy:
    if dependencyId not in graph:
      dependencyErrors.push({
        type: "invalid_blockedBy",
        severity: "error",
        taskId: task.id,
        invalidRef: dependencyId,
        message: "Task " + task.id + " references non-existent task " + dependencyId + " in blockedBy"
      })
```

**7.3.2: Validate blocks references**

```
for each task in allTasks:
  for each blockingId in task.blocks:
    if blockingId not in graph:
      dependencyErrors.push({
        type: "invalid_blocks",
        severity: "error",
        taskId: task.id,
        invalidRef: blockingId,
        message: "Task " + task.id + " references non-existent task " + blockingId + " in blocks"
      })
```

**7.3.3: Verify bidirectional consistency**

Ensure that dependency relationships are consistent in both directions:

```
for each task in allTasks:
  for each dependencyId in task.blockedBy:
    if task.id not in graph[dependencyId].blocks:
      dependencyErrors.push({
        type: "inconsistent_dependency",
        severity: "warning",
        taskId: task.id,
        relatedTask: dependencyId,
        message: "Task " + task.id + " is blockedBy " + dependencyId + " but " + dependencyId + " doesn't list " + task.id + " in blocks"
      })
```

**7.4: Check priority consistency**

Validate that task priorities follow logical dependency rules. P1 (highest priority) tasks should not be blocked by lower priority tasks.

**7.4.1: Extract task priorities**

Determine task priority based on:
1. Explicit priority markers in the task description
2. User story priority (P1 story tasks inherit P1 priority)
3. Phase (Phase 1-2 tasks are implicitly P1)

```
function getTaskPriority(task):
  if task.phase <= 2:
    return "P1"  // Setup and Foundation are critical

  if task.storyId:
    story = storyToTasksMap[task.storyId]
    return story.priority  // Inherit from user story

  return "P2"  // Default priority
```

**7.4.2: Validate P1 tasks are not blocked by P2/P3**

```
for each task in allTasks:
  taskPriority = getTaskPriority(task)

  if taskPriority == "P1":
    for each dependencyId in task.blockedBy:
      depPriority = getTaskPriority(graph[dependencyId])

      if depPriority in ["P2", "P3"]:
        priorityWarnings.push({
          type: "priority_inversion",
          severity: "warning",
          taskId: task.id,
          taskPriority: "P1",
          blockingTask: dependencyId,
          blockingPriority: depPriority,
          message: "P1 task " + task.id + " is blocked by " + depPriority + " task " + dependencyId
        })
```

**7.4.3: Warn if violations found**

Display priority warnings (non-blocking):
```
WARNING: Priority inconsistencies detected:

  - P1 task T200 (Login implementation) is blocked by P2 task T150 (Analytics setup)
    Recommendation: Consider elevating T150 to P1 or removing the dependency

  - P1 task T205 (Auth service) is blocked by P3 task T180 (Logging enhancement)
    Recommendation: P3 tasks should not block critical path items

These warnings do not prevent task generation but may indicate planning issues.
```

**7.5: Generate validation report**

Compile all validation results into a comprehensive report.

**7.5.1: Validation summary structure**

```
validationReport = {
  timestamp: currentDateTime,
  taskCount: totalTasks,
  phaseCount: totalPhases,

  formatValidation: {
    passed: formatErrors.filter(e => e.severity == "error").length == 0,
    errors: formatErrors.filter(e => e.severity == "error"),
    warnings: formatErrors.filter(e => e.severity == "warning")
  },

  dependencyValidation: {
    passed: dependencyErrors.filter(e => e.severity == "error").length == 0,
    circularDependencies: cycles,
    invalidReferences: dependencyErrors.filter(e => e.type.includes("invalid")),
    inconsistencies: dependencyErrors.filter(e => e.type == "inconsistent_dependency")
  },

  priorityValidation: {
    passed: true,  // Priority issues are warnings only
    warnings: priorityWarnings
  },

  overallStatus: "PASSED" | "FAILED",
  canProceed: true | false
}
```

**7.5.2: Display validation report**

```markdown
## Task Validation Report

### Summary
- Total Tasks: {taskCount}
- Total Phases: {phaseCount}
- Validation Status: {PASSED | FAILED}

### Format Validation
{✓ | ✗} All tasks have valid format
  - Errors: {count}
  - Warnings: {count}

{If errors exist, list each error with line number and description}

### Dependency Validation
{✓ | ✗} No circular dependencies
{✓ | ✗} All dependency references are valid
{✓ | ✗} Dependency relationships are consistent

{If errors exist, list each with details}

### Priority Validation
{✓ | ⚠} Priority consistency check
  - Warnings: {count}

{If warnings exist, list each with recommendation}

### Result
{If PASSED:}
✓ Validation passed. Ready to write tasks.md

{If FAILED:}
✗ Validation failed. Please fix the following errors before proceeding:
  {List all blocking errors}
```

**7.5.3: Handle validation failure**

If validation fails (any severity="error"):
1. Display the validation report
2. Do NOT write tasks.md
3. Provide specific guidance on fixing each error
4. Exit the command with error status

**7.6: Write tasks.md to FEATURE_DIR**

If validation passes, write the complete tasks.md file to the feature directory.

**7.6.1: Assemble final tasks.md content**

Combine all generated content into the final document structure:

```markdown
# Tasks: {Feature Name}

Generated: {timestamp}
Feature: {FEATURE_DIR}
Source: plan.md, spec.md{, data-model.md}{, research.md}

## Overview

- Total Tasks: {count}
- Phases: {count}
- Estimated Complexity: {Low | Medium | High}
- Parallel Execution Groups: {count}

## Task Legend

- `[ ]` - Incomplete task
- `[x]` - Completed task
- `[P]` - Can execute in parallel with other [P] tasks in same group
- `[US#]` - Linked to User Story # (e.g., [US1] = User Story 1)
- `CHECKPOINT` - Review point before proceeding to next phase

## Phase 1: Setup
{Setup tasks from Step 4.1}

## Phase 2: Foundational
{Foundational tasks from Step 4.2}

## Phase 3: {User Story Title} (US-001)
{Story tasks from Step 5}

{... additional phases ...}

## Dependencies
{Dependency documentation from Step 6}

## Validation
{Validation summary from Step 7.5}
```

**7.6.2: Write file to disk**

```bash
# Write tasks.md to the feature directory
echo "${tasksContent}" > "${FEATURE_DIR}/tasks.md"
```

Verify the file was written successfully:
```bash
if [ -f "${FEATURE_DIR}/tasks.md" ]; then
  echo "✓ tasks.md written successfully to ${FEATURE_DIR}"
else
  echo "✗ Failed to write tasks.md"
  exit 1
fi
```

### Step 8: Completion Summary

This step provides a final summary of the generated tasks and guides the user to the next step in the workflow.

**8.1: Report tasks.md created**

Display confirmation that tasks.md has been successfully generated:

```markdown
## Task Generation Complete

✓ Successfully generated tasks.md

  Location: {FEATURE_DIR}/tasks.md
  Generated: {timestamp}
```

**8.2: Show task counts by phase**

Provide a breakdown of tasks by phase for quick reference:

```markdown
### Task Summary by Phase

| Phase | Name | Tasks | Parallel | Checkpoints |
|-------|------|-------|----------|-------------|
| 1 | Setup | {count} | {parallel_count} | 0 |
| 2 | Foundational | {count} | {parallel_count} | 0 |
| 3 | {US-001 Title} | {count} | {parallel_count} | 1 |
| 4 | {US-002 Title} | {count} | {parallel_count} | 1 |
| ... | ... | ... | ... | ... |
| **Total** | | **{total}** | **{total_parallel}** | **{total_checkpoints}** |

### Priority Distribution

| Priority | Task Count | Percentage |
|----------|------------|------------|
| P1 (Critical) | {count} | {percent}% |
| P2 (Important) | {count} | {percent}% |
| P3 (Nice-to-have) | {count} | {percent}% |
```

**8.3: Display dependency statistics**

Show key dependency metrics:

```markdown
### Dependency Statistics

- Total Dependencies: {count}
- Average Dependencies per Task: {average}
- Maximum Dependency Chain Length: {max_chain} tasks
- Parallel Execution Groups: {group_count}
- Estimated Time Savings with Parallelization: {percent}%
```

**8.4: Suggest next step**

Guide the user to the next command in the workflow:

```markdown
### Next Steps

Your implementation tasks are ready. To begin executing tasks:

  /spectra:implement

This command will:
1. Parse the generated tasks.md
2. Execute tasks in dependency order
3. Track progress and update task status
4. Handle checkpoints between phases

**Optional commands before implementation:**

- `/spectra:analyze` - Run cross-artifact consistency analysis
- `/spectra:taskstoissues` - Convert tasks to GitHub issues
```

**8.5: Final output format**

Complete final output displayed to user:

```markdown
─────────────────────────────────────────────────────────────────
                    TASK GENERATION COMPLETE
─────────────────────────────────────────────────────────────────

✓ tasks.md generated successfully

  Feature: {feature_name}
  Location: {FEATURE_DIR}/tasks.md

  Tasks: {total_count} across {phase_count} phases
  User Stories: {story_count}
  Parallel Groups: {group_count}

  Priority Breakdown:
    P1: {p1_count} tasks ({p1_percent}%)
    P2: {p2_count} tasks ({p2_percent}%)
    P3: {p3_count} tasks ({p3_percent}%)

─────────────────────────────────────────────────────────────────

Ready to implement? Run:

  /spectra:implement

─────────────────────────────────────────────────────────────────
```

## Output

Upon successful completion, this command produces `tasks.md` in the current feature directory with:

- Phased task organization (Setup, Foundation, Feature phases)
- Unique task identifiers for tracking
- Dependency relationships between tasks
- Acceptance criteria for each task
- Estimated complexity indicators

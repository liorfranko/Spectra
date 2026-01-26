---
description: "Generate dependency-ordered tasks from an implementation plan"
user-invocable: true
---

# Tasks Command

Generate an actionable, dependency-ordered `tasks.md` file from the implementation plan and feature specification. This command analyzes the plan's architecture decisions, technical components, and integration points to produce granular development tasks organized into logical phases.

## Prerequisites

This command requires that `plan.md` exists in the current feature directory. The plan provides the architectural foundation and component breakdown needed to generate meaningful tasks.

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-plan
```

If the prerequisite check fails, run `/speckit.plan` first to generate the implementation plan.

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

If plan.md is not found in AVAILABLE_DOCS, display an error message instructing the user to run `/speckit.plan` first, then stop execution.

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

<!-- T035: Implement user story phase generation -->
- Create one phase per user story or logical grouping
- Break down each story into implementation tasks
- Include tasks for models, services, APIs, and UI as applicable
- Add integration and testing tasks for each phase

### Step 6: Generate Dependency Graph

<!-- T036: Implement dependency graph generation -->
- Analyze task relationships and prerequisites
- Assign unique task IDs (e.g., T001, T002, ...)
- Set blockedBy references based on logical dependencies
- Validate no circular dependencies exist
- Optimize task ordering for parallel execution where possible

### Step 7: Validate Task Format

<!-- T037: Implement task format validation -->
- Verify all tasks have required fields (ID, description, phase)
- Check dependency references are valid
- Ensure acceptance criteria are testable
- Validate task granularity (not too large, not too small)
- Write validated tasks.md to the feature directory

## Output

Upon successful completion, this command produces `tasks.md` in the current feature directory with:

- Phased task organization (Setup, Foundation, Feature phases)
- Unique task identifiers for tracking
- Dependency relationships between tasks
- Acceptance criteria for each task
- Estimated complexity indicators

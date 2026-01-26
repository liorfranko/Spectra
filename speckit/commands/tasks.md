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

### Step 3: Map Entities from data-model.md

<!-- T033: Implement entity mapping -->
- If data-model.md exists, parse entity definitions
- Extract entity names, attributes, and relationships
- Map entities to the components that will implement them
- Identify entity creation order based on relationships

### Step 4: Generate Setup and Foundational Phases

<!-- T034: Implement setup/foundation task generation -->
- Create Phase 0: Project Setup tasks (tooling, config, structure)
- Create Phase 1: Foundation tasks (core abstractions, base classes)
- Generate tasks for shared utilities and common infrastructure
- Establish the dependency baseline for subsequent phases

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

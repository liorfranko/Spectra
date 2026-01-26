---
description: "Generate an implementation plan from a feature specification"
user-invocable: true
---

# Plan Command

Execute the implementation planning workflow to generate design artifacts from a feature specification. This command transforms a validated spec.md into actionable technical documentation including research findings, data models, and implementation guidance.

## Prerequisites

This command requires a validated `spec.md` file to exist in the current feature directory.

Run the prerequisite check before proceeding:

```bash
$CLAUDE_PLUGIN_ROOT/scripts/check-prerequisites.sh --require-spec
```

If the check fails, use the `/speckit.specify` skill first to create the specification.

## Workflow

### Step 1: Check Prerequisites

Validate that spec.md exists and is properly formatted before proceeding with plan generation.

### Step 2: Phase 0 - Research

Generate research.md by identifying and resolving technical unknowns from the specification.

#### 2.1: Read the Specification

Read the spec.md file from the current feature directory to understand the feature requirements, scope, and technical implications.

#### 2.2: Identify Technical Unknowns

Analyze the specification to identify questions that need resolution:

- **Technology Options**: What technologies could implement this feature? Consider frameworks, libraries, and platforms.
- **Applicable Patterns**: What design patterns, architectural patterns, or best practices apply to this problem domain?
- **External Dependencies**: What external services, APIs, or third-party libraries might be needed?
- **Existing Solutions**: Are there existing implementations in the codebase or open-source projects to build upon?
- **Integration Points**: How will this feature integrate with existing systems and workflows?
- **Performance Considerations**: Are there scaling, latency, or resource constraints to address?

#### 2.3: Research Each Unknown

For each identified unknown, conduct research using available resources:

1. **Codebase Exploration**: Search for existing patterns, similar implementations, and established conventions in the current codebase
2. **Web Search**: Query for current best practices, tutorials, and community recommendations when needed
3. **Documentation Queries**: Use Context7 or similar tools to fetch up-to-date library and framework documentation
4. **Comparative Analysis**: Evaluate multiple options against the project's requirements and constraints

#### 2.4: Document Decisions

Structure the research findings with clear decision rationale:

For each significant unknown, document:
- **Question/Unknown**: What needed to be resolved
- **Options Considered**: List alternatives that were evaluated
- **Decision**: The chosen approach
- **Rationale**: Why this option was selected over alternatives
- **Trade-offs**: Known limitations or compromises
- **Sources**: References to documentation, examples, or discussions that informed the decision

#### 2.5: Write research.md

Create the research.md file in the feature directory with the following structure:

```markdown
# Research: [Feature Name]

## Overview
Brief summary of research scope and key decisions made.

## Technical Unknowns

### [Unknown 1: e.g., "State Management Approach"]

**Question**: [What needed to be determined]

**Options Considered**:
1. [Option A] - [Brief description]
2. [Option B] - [Brief description]
3. [Option C] - [Brief description]

**Decision**: [Chosen option]

**Rationale**: [Why this was selected]

**Trade-offs**: [Known limitations]

**Sources**:
- [Link or reference 1]
- [Link or reference 2]

### [Unknown 2: e.g., "API Integration Pattern"]
[Same structure as above]

## Key Findings

- [Important discovery 1]
- [Important discovery 2]
- [Constraint or requirement identified]

## Recommendations

Summary of recommended approach based on research findings.
```

Write the completed research.md to `FEATURE_DIR/research.md`.

### Step 3: Phase 1 - Data Model

<!-- Placeholder for T024: Data model phase implementation -->
Define the data structures, schemas, and state management approach based on the specification requirements.

### Step 4: Technical Context

<!-- Placeholder for T025: Technical context implementation -->
Establish the technical environment, dependencies, and integration points for the feature.

### Step 5: Quickstart Guide

<!-- Placeholder for T026: Quickstart guide implementation -->
Generate a quickstart guide with setup instructions and initial implementation steps.

### Step 6: Constitution Check

<!-- Placeholder for T027: Constitution check implementation -->
Validate the plan against project constitution principles and architectural guidelines.

### Step 7: Project Structure

<!-- Placeholder for T028: Project structure implementation -->
Define the file and directory structure for the feature implementation.

## Output

Upon successful completion, this command generates:

- `research.md` - Technology research and documentation findings
- `data-model.md` - Data structures and state schemas
- `plan.md` - Complete implementation plan with technical context
- `quickstart.md` - Setup and getting started guide

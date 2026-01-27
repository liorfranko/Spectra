---
description: "Generate an implementation plan from a feature specification"
user-invocable: true
---

# Plan Command

Execute the implementation planning workflow to generate design artifacts from a feature specification. This command transforms a validated spec.md into actionable technical documentation including research findings, data models, and implementation guidance.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Prerequisites

This command requires a validated `spec.md` file to exist in the current feature directory.

Run the prerequisite check before proceeding:

```bash
$CLAUDE_PLUGIN_ROOT/scripts/check-prerequisites.sh --require-spec
```

If the check fails, use the `/projspec:specify` skill first to create the specification.

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

Generate data-model.md by extracting and formalizing entities from the specification.

#### 3.1: Read Key Entities Section

Read the `Key Entities` section from spec.md. This section contains the domain entities that the feature operates on. Each entity is typically defined with:
- Entity name (bolded heading)
- Brief description of what the entity represents
- Related context from user scenarios and requirements

#### 3.2: Define Entity Attributes

For each identified entity, create a formal definition:

**Entity Structure**:
```markdown
### [Entity Name]

[Description from spec or expanded description based on requirements]

**Identifier Pattern**: [How instances are identified, if applicable]

**Storage Location**: [Where entity data is stored, if applicable]

**Attributes**:
| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| [name] | [type] | [Yes/No] | [Description] |
```

**Attribute Types**:
- Primitives: `string`, `integer`, `boolean`, `date`
- Enums: `enum` (list valid values in description)
- Collections: `string[]`, `[EntityName][]`
- References: `[EntityName]` (reference to another entity)

**Guidelines for Attributes**:
- Derive attributes from requirements (FR-###) that mention the entity
- Include attributes implied by user scenarios
- Add status/state attributes if the entity has lifecycle states
- Include timestamps if tracking is mentioned in requirements

#### 3.3: Define Validation Rules

For each entity, document validation rules based on requirements:

```markdown
**Validation Rules**:
- [Rule derived from requirement FR-###]
- [Constraint implied by success criteria SC-###]
- [Business rule from user scenarios]
```

Consider:
- Required fields and their constraints
- Format validations (patterns, ranges, lengths)
- Referential integrity (references to other entities)
- Business logic constraints

#### 3.4: Define Relationships

Document how entities relate to each other:

**Relationship Types**:
- **One-to-One (1:1)**: Entity A has exactly one Entity B
- **One-to-Many (1:n)**: Entity A has multiple Entity B instances
- **Many-to-Many (n:m)**: Multiple Entity A instances relate to multiple Entity B instances

**Relationship Diagram**:
If the feature has 3+ entities with relationships, include an ASCII relationship diagram:

```markdown
## Relationships

```
[EntityA] (1) ────────── [EntityB] (n)
     │
     │ [relationship verb]
     ▼
[EntityC] (1)
```
```

Document each relationship with:
- Cardinality (1:1, 1:n, n:m)
- Direction of ownership/containment
- Cascade behavior (what happens when parent is deleted)

#### 3.5: Define State Transitions

If any entity has status/state attributes, document the state machine:

```markdown
**Status Values**:
- `[state1]` - [Description of this state]
- `[state2]` - [Description of this state]

**State Transitions**:
```
[state1] → [state2] → [state3]
  ↓                        ↑
  └────────────────────────┘
         (alternate path)
```

**Transition Rules**:
- [state1] → [state2]: [Trigger/condition for transition]
- [state2] → [state3]: [Trigger/condition for transition]
```

Include:
- All valid states from the enum
- Valid transition paths
- Conditions/triggers for each transition
- Any terminal states (no outgoing transitions)

#### 3.6: Document File Formats

If the feature involves file-based storage or data exchange, document the formats:

```markdown
## File Format Specifications

### [Format Name]

**File Extension**: `.[ext]`
**Location**: `[path pattern]`

**Structure**:
```[format]
[Example showing structure]
```

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| [field] | [type] | [Yes/No] | [Description] |
```

Consider:
- YAML frontmatter for markdown files
- JSON/YAML for configuration files
- Line-based formats (JSONL) for logs/streams

#### 3.7: Write data-model.md

Create the data-model.md file in the feature directory with this structure:

```markdown
# Data Model: [Feature Name]

**Feature**: [Feature Name]
**Date**: [ISO 8601 date]

## Overview

[Brief description of the data model and its purpose]

---

## Core Entities

### 1. [Entity Name]

[Full entity definition per 3.2]

---

### 2. [Entity Name]

[Full entity definition per 3.2]

---

## Relationships

[Relationship diagram and descriptions per 3.4]

---

## File Format Specifications

[File formats per 3.6, if applicable]

---

## Validation Rules Summary

| Entity | Rule | Error Action |
|--------|------|--------------|
| [Entity] | [Rule] | [ERROR/WARN/Block action] |
```

Write the completed data-model.md to `FEATURE_DIR/data-model.md`.

### Step 4: Phase 1 - Technical Context

Fill the Technical Context section of plan.md by determining the language, dependencies, platform requirements, and constraints for the feature implementation.

#### 4.1: Determine Language and Runtime

Analyze the spec.md and research.md to identify the best technology stack:

1. **Check Research Decisions**: Review research.md for any technology decisions already made
2. **Analyze Codebase Patterns**: Search for existing files to determine:
   - Primary language used in the project (`*.ts`, `*.py`, `*.go`, `*.rs`, etc.)
   - Runtime version from configuration files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`)
   - Package manager in use (`npm`, `yarn`, `pnpm`, `pip`, `poetry`, `cargo`)
3. **Match Feature Requirements**: Ensure the chosen language/framework can meet the feature's functional requirements

**Populate Language & Runtime Table**:
```markdown
### Language & Runtime

| Aspect | Value |
|--------|-------|
| Primary Language | [e.g., TypeScript, Python, Bash] |
| Runtime/Version | [e.g., Node.js 18+, Python 3.10+] |
| Package Manager | [e.g., npm, yarn, pip, none] |
```

#### 4.2: Identify Primary Dependencies

List the key dependencies required for the feature:

1. **From Research**: Extract recommended libraries from research.md decision summaries
2. **From Existing Codebase**: Check `package.json`, `requirements.txt`, or equivalent for already-installed dependencies that can be reused
3. **From Spec Requirements**: Identify dependencies implied by functional requirements (e.g., "CLI interface" implies arg parsing library)

**Categorize Dependencies**:
- **Required**: Must be added to implement the feature
- **Existing**: Already in the project, will be used
- **Optional**: Nice-to-have, can implement without

**Populate Dependencies Table**:
```markdown
### Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| [lib-name] | [^x.y.z or existing] | [What it's used for] |
```

**Guidelines**:
- Prefer dependencies already in the project
- Minimize new external dependencies per constitution principles
- Document why each dependency is necessary

#### 4.3: Document Platform and Environment

Define the target platform and environment requirements:

1. **Target Platform**: Where will this feature run?
   - CLI tool (macOS, Linux, Windows)
   - Web application (browser, server)
   - Plugin/Extension (specific host environment)

2. **Minimum Requirements**: What must be present?
   - OS versions
   - Runtime versions
   - Required system tools

3. **Environment Variables**: What configuration is needed?
   - Required environment variables
   - Configuration file locations
   - Default values

**Populate Platform & Environment Table**:
```markdown
### Platform & Environment

| Aspect | Value |
|--------|-------|
| Target Platform | [e.g., Claude Code plugin, CLI tool, Node.js server] |
| Minimum Requirements | [e.g., Claude Code CLI, Bash 5.x, macOS/Linux] |
| Environment Variables | [e.g., CLAUDE_PLUGIN_ROOT, None required] |
```

#### 4.4: Identify Constraints

Document technical constraints that affect implementation:

1. **Constitution Principles**: Read the project constitution (if exists) and extract relevant constraints:
   ```bash
   # Check for constitution file
   ls -la $FEATURE_DIR/../constitution.md $PROJECT_ROOT/constitution.md $PROJECT_ROOT/.claude/constitution.md 2>/dev/null
   ```

2. **Existing Codebase Patterns**: Search for established conventions:
   - File naming patterns
   - Directory structure conventions
   - Code style guidelines
   - Testing patterns

3. **Spec Requirements**: Extract non-functional requirements (NFR-###) that impose constraints:
   - Performance requirements
   - Compatibility requirements
   - Security requirements

4. **Integration Constraints**: Identify limitations from integration points:
   - API compatibility requirements
   - Version constraints from dependencies
   - Platform-specific limitations

**Populate Constraints List**:
```markdown
### Constraints

- [Constraint 1: e.g., Must work with Claude Code plugin system]
- [Constraint 2: e.g., No external network requests during core operations]
- [Constraint 3: e.g., Must support both macOS and Linux]
- [Constraint 4: e.g., File operations must be atomic]
```

#### 4.5: Document Testing Approach

Define how the feature will be tested:

1. **Test Framework**: Identify testing tools from the project
   - Check for existing test directories (`tests/`, `__tests__/`, `spec/`)
   - Identify test runner configuration (`jest.config.js`, `pytest.ini`, etc.)

2. **Test Types**: Determine appropriate test types for this feature
   - Unit tests for isolated logic
   - Integration tests for component interaction
   - End-to-end tests for user workflows

3. **Coverage Requirements**: Note any coverage requirements from constitution or NFRs

**Add Testing Subsection**:
```markdown
### Testing Approach

| Aspect | Value |
|--------|-------|
| Test Framework | [e.g., Jest, pytest, bats-core, manual validation] |
| Test Location | [e.g., tests/, __tests__/, projspec/tests/] |
| Required Coverage | [e.g., Not specified, 80%, Critical paths only] |

**Test Types**:
- Unit: [Yes/No - what will be unit tested]
- Integration: [Yes/No - what will be integration tested]
- E2E: [Yes/No - what workflows will be tested end-to-end]
```

#### 4.6: Write Technical Context to plan.md

Create or update plan.md in the feature directory with the Technical Context section:

1. **Use Template**: Start from the plan-template.md structure
2. **Fill Placeholders**: Replace all `[PLACEHOLDER]` values with determined values
3. **Add Feature-Specific Details**: Expand tables if additional rows are needed
4. **Cross-Reference**: Link constraints to their sources (constitution principles, NFRs, etc.)

**Write Location**: `FEATURE_DIR/plan.md`

**Validation**: Ensure all tables are properly filled with no remaining placeholders in the Technical Context section.

### Step 5: Phase 1 - Quickstart Guide

Generate quickstart.md with a getting started guide for the feature implementation.

#### 5.1: Extract Prerequisites and Context

Gather information from existing artifacts to build the quickstart guide:

1. **From spec.md**:
   - Feature name and description
   - Key user scenarios (for workflow examples)
   - Core requirements that define primary operations

2. **From plan.md Technical Context**:
   - Language and runtime requirements
   - Required dependencies
   - Platform and environment requirements

3. **From data-model.md** (if exists):
   - Primary entities the user will work with
   - Key file formats or configurations

**Extract Key Information**:
```markdown
Prerequisites to extract:
- Runtime version (e.g., Node.js 18+, Python 3.10+)
- Required tools (e.g., Claude Code CLI, Git)
- Required dependencies (from Dependencies table)
- Environment setup (from Environment Variables)

User Scenarios to reference:
- Primary use case (first user scenario from spec)
- Core workflow steps
- Expected inputs and outputs
```

#### 5.2: Structure the Quickstart Guide

Organize the quickstart guide with the following sections:

**Section 1: Prerequisites**
List what must be installed or configured before using the feature:
- Runtime/language requirements
- Required tools and their minimum versions
- Required environment variables or configuration
- Any one-time setup steps

**Section 2: Installation**
Provide step-by-step installation instructions:
- Clone/download instructions (if applicable)
- Dependency installation commands
- Configuration file setup
- Verification steps to confirm successful installation

**Section 3: Quick Start Workflow**
Present the minimal steps to get started:
- The simplest path to using the feature
- Step-by-step commands with expected output
- Common first-time user workflow

**Section 4: Basic Examples**
Include 2-3 practical examples:
- Example 1: Simplest possible usage
- Example 2: Common use case with options
- Example 3: Real-world scenario from user stories

**Section 5: Next Steps**
Guide users to further documentation:
- Link to full specification (spec.md)
- Link to implementation plan (plan.md)
- Link to task list (tasks.md) for contributors
- Common customization options

#### 5.3: Write quickstart.md

Create the quickstart.md file in the feature directory with this structure:

```markdown
# Quickstart: [Feature Name]

Get started with [Feature Name] in under 5 minutes.

## Prerequisites

Before you begin, ensure you have:

- [ ] [Prerequisite 1: e.g., Node.js 18 or later installed]
- [ ] [Prerequisite 2: e.g., Claude Code CLI installed and authenticated]
- [ ] [Prerequisite 3: e.g., Git installed]

## Installation

### Step 1: [First installation step]

```bash
[Command to run]
```

### Step 2: [Second installation step]

```bash
[Command to run]
```

### Step 3: Verify Installation

```bash
[Verification command]
```

Expected output:
```
[Expected output showing successful installation]
```

## Quick Start

Follow these steps to [accomplish the primary use case]:

### 1. [First step name]

```bash
[Command]
```

### 2. [Second step name]

```bash
[Command]
```

### 3. [Third step name]

```bash
[Command]
```

## Basic Examples

### Example 1: [Simple usage title]

[Brief description of what this example demonstrates]

```bash
[Command(s)]
```

### Example 2: [Common use case title]

[Brief description of what this example demonstrates]

```bash
[Command(s)]
```

### Example 3: [Real-world scenario title]

[Brief description based on user story from spec]

```bash
[Command(s)]
```

## Next Steps

- **Full Specification**: See [spec.md](./spec.md) for complete requirements
- **Implementation Details**: See [plan.md](./plan.md) for technical design
- **Contributing**: See [tasks.md](./tasks.md) for implementation tasks
- **[Feature-specific link]**: [Description of additional resource]

## Troubleshooting

### Common Issues

**Issue: [Common problem]**
```
[Error message or symptom]
```
**Solution**: [How to resolve]

**Issue: [Another common problem]**
```
[Error message or symptom]
```
**Solution**: [How to resolve]
```

**Write Location**: `FEATURE_DIR/quickstart.md`

**Validation Checklist**:
- [ ] All prerequisites derived from Technical Context
- [ ] Installation steps are testable and complete
- [ ] Quick Start workflow matches primary user scenario from spec
- [ ] Examples are concrete and runnable
- [ ] Next steps link to actual artifact files
- [ ] No placeholder text remains in the output

### Step 6: Constitution Check

Validate the implementation plan against project constitution principles and track any violations.

#### 6.1: Read Constitution

Load the project constitution from the following locations (in priority order):

1. **Project-specific**: `.projspec/memory/constitution.md`
2. **Plugin default**: `$CLAUDE_PLUGIN_ROOT/memory/constitution.md`

```bash
# Check for constitution file
CONSTITUTION_PATH=""
if [ -f ".projspec/memory/constitution.md" ]; then
    CONSTITUTION_PATH=".projspec/memory/constitution.md"
elif [ -f "$CLAUDE_PLUGIN_ROOT/memory/constitution.md" ]; then
    CONSTITUTION_PATH="$CLAUDE_PLUGIN_ROOT/memory/constitution.md"
fi
```

If no constitution exists, skip the constitution check and note in the plan:
```markdown
## Constitution Check

**Status**: SKIPPED - No constitution file found
```

#### 6.2: Evaluate Each Principle

For each principle defined in the constitution, evaluate the planned implementation:

**Compliance Statuses**:
- **PASS**: Implementation fully complies with the principle
- **PARTIAL**: Implementation partially complies with justified trade-offs
- **VIOLATION**: Implementation does not comply with the principle

**Evaluation Process**:
1. Read each principle from the constitution (typically numbered P-001, P-002, etc.)
2. Cross-reference with:
   - Technical Context (dependencies, platform choices)
   - Data Model (entity design, storage approach)
   - Research decisions (technology choices)
3. Determine compliance status
4. Document justification for any non-PASS status

**Justification Requirements for Non-PASS**:
```markdown
| Principle | Status | Justification | Mitigation |
|-----------|--------|---------------|------------|
| P-001: [Name] | PARTIAL | [Why full compliance not possible] | [How impact is reduced] |
| P-002: [Name] | VIOLATION | [Why violation is necessary] | [What compensating controls exist] |
```

#### 6.3: Add Constitution Check Section to plan.md

Add the Constitution Check section to the plan.md file after the Technical Context section:

```markdown
## Constitution Check

**Constitution Source**: [path to constitution file]
**Check Date**: [ISO 8601 date]

### Principle Compliance

| Principle | Description | Status | Notes |
|-----------|-------------|--------|-------|
| P-001 | [Brief description] | PASS | - |
| P-002 | [Brief description] | PASS | Complies via [specific implementation choice] |
| P-003 | [Brief description] | PARTIAL | See justification below |

### Compliance Details

#### Principles with Full Compliance (PASS)

- **P-001**: [How the implementation satisfies this principle]
- **P-002**: [How the implementation satisfies this principle]

#### Principles with Partial Compliance (PARTIAL)

**P-003: [Principle Name]**
- **Requirement**: [What the principle requires]
- **Current Plan**: [What the plan does instead]
- **Justification**: [Why full compliance is not feasible]
- **Mitigation**: [How the impact is minimized]

#### Principles with Violations (VIOLATION)

**P-00X: [Principle Name]**
- **Requirement**: [What the principle requires]
- **Violation**: [How the plan violates this]
- **Justification**: [Why this violation is necessary]
- **Mitigation**: [Compensating controls or future remediation]
- **Governance**: [Required approval or override documentation]
```

#### 6.4: Track Violations in Complexity Section

If any VIOLATION status exists, it must be documented in the Complexity Tracking section of plan.md:

**Add to Complexity Tracking**:
```markdown
## Complexity Tracking

### Constitution Violations

| Violation | Principle | Impact | Justification | Approver |
|-----------|-----------|--------|---------------|----------|
| [Brief description] | P-00X | [High/Medium/Low] | [Why necessary] | [Who approved or TBD] |

### Violation Details

#### [Violation Title]

**Principle Violated**: P-00X: [Principle Name]

**Description**: [Detailed description of the violation]

**Business Justification**:
[Why this violation is necessary for the feature to succeed]

**Technical Justification**:
[Why alternative approaches that would comply are not feasible]

**Risk Assessment**:
- **Impact**: [What could go wrong]
- **Likelihood**: [How likely is the negative outcome]
- **Severity**: [How bad would it be]

**Mitigation Plan**:
1. [Immediate mitigation step]
2. [Ongoing monitoring or control]
3. [Future remediation plan if applicable]

**Required Governance**:
- [ ] Technical lead review
- [ ] Architecture review (if High impact)
- [ ] Documented exception approval
```

**Violation Handling Rules**:
- Violations CANNOT be ignored or hidden
- Each violation requires explicit justification
- High-impact violations require governance approval before implementation
- Violations should be flagged for future remediation when possible

#### 6.5: Determine Gate Status

The Constitution Check is a quality gate that determines if planning can proceed:

**Gate Criteria**:
```markdown
### Gate Status

**Constitution Check Result**: [PASS | FAIL]

**Criteria**:
- PASS: All principles are PASS or PARTIAL with documented justification
- FAIL: Any VIOLATION exists without proper governance approval

**Action Required**:
- [None - proceed to next phase | Obtain governance approval for violations]
```

**Gate Decision Matrix**:

| Highest Status | Gate Result | Action |
|----------------|-------------|--------|
| All PASS | PASS | Proceed to project structure |
| Any PARTIAL | PASS | Proceed with documented trade-offs |
| Any VIOLATION (justified + approved) | PASS | Proceed with governance documentation |
| Any VIOLATION (not approved) | FAIL | Halt - obtain approval or revise plan |

**On FAIL**:
1. Stop the planning workflow
2. Report the violations that need approval
3. Request governance review
4. Resume only after approvals are documented

**Output**: Add gate status to the plan.md Constitution Check section.

### Step 7: Project Structure

Generate the project structure section of plan.md by defining source code layout based on project type.

#### 7.1: Determine Directory Structure by Project Type

Based on the project type identified in Technical Context, determine the standard directory structure:

**Project Type Detection**:
1. Check Technical Context for Target Platform value
2. Identify project type from existing codebase patterns
3. Map to standard structure template

**Common Project Type Structures**:

**Claude Code Plugin**:
```
[plugin-name]/
├── plugin.json          # Plugin manifest
├── commands/            # User-invocable slash commands
│   └── *.md
├── skills/              # Reusable skill definitions
│   └── *.md
├── agents/              # Specialized agent definitions
│   └── *.md
├── hooks/               # Event hooks (PreToolUse, PostToolUse, etc.)
│   └── *.md
├── scripts/             # Bash helper scripts
│   └── *.sh
├── templates/           # Template files for generation
│   └── *.md
├── memory/              # Persistent knowledge and context
│   └── *.md
└── tests/               # Test files
    └── *.sh
```

**Node.js/TypeScript CLI**:
```
[project-name]/
├── src/                 # Source code
│   ├── index.ts         # Entry point
│   ├── commands/        # CLI commands
│   ├── lib/             # Core library code
│   └── utils/           # Utility functions
├── tests/               # Test files
│   ├── unit/
│   └── integration/
├── dist/                # Compiled output (gitignored)
├── package.json
├── tsconfig.json
└── README.md
```

**Python CLI**:
```
[project-name]/
├── src/
│   └── [package_name]/
│       ├── __init__.py
│       ├── cli.py       # Entry point
│       ├── commands/
│       └── utils/
├── tests/
│   ├── unit/
│   └── integration/
├── pyproject.toml
└── README.md
```

**Bash Scripts**:
```
[project-name]/
├── bin/                 # Executable scripts
│   └── *.sh
├── lib/                 # Shared functions
│   └── *.sh
├── tests/               # Test files (bats-core)
│   └── *.bats
└── README.md
```

#### 7.2: Create Documentation Structure

Define the feature documentation layout within the specs directory:

```markdown
### Documentation Structure

The feature documentation is organized under `specs/[feature-id]/`:

```
specs/[feature-id]/
├── spec.md              # Feature specification (requirements, scenarios)
├── research.md          # Technical research and decisions
├── data-model.md        # Entity definitions and schemas
├── plan.md              # Implementation plan (this document)
├── quickstart.md        # Getting started guide
├── tasks.md             # Implementation task list
└── checklists/          # Optional: validation checklists
    └── requirements.md
```

**File Purposes**:
| File | Purpose | Created By |
|------|---------|------------|
| spec.md | Requirements and acceptance criteria | /projspec:specify |
| research.md | Technology decisions and findings | /projspec:plan |
| data-model.md | Data structures and schemas | /projspec:plan |
| plan.md | Technical context and implementation guidance | /projspec:plan |
| quickstart.md | Setup and usage guide | /projspec:plan |
| tasks.md | Implementation task breakdown | /projspec:tasks |
```

#### 7.3: Create Source Code Structure

Define where source files should be created based on the project type:

```markdown
### Source Code Structure

Based on project type: [Project Type from 7.1]

**Main Source Directories**:
| Directory | Purpose | File Types |
|-----------|---------|------------|
| [dir1] | [Purpose] | [*.ext] |
| [dir2] | [Purpose] | [*.ext] |
| [dir3] | [Purpose] | [*.ext] |

**Test Directories**:
| Directory | Test Type | Framework |
|-----------|-----------|-----------|
| [test-dir1] | Unit tests | [framework] |
| [test-dir2] | Integration tests | [framework] |

**Configuration File Locations**:
| File | Location | Purpose |
|------|----------|---------|
| [config1] | [path] | [Purpose] |
| [config2] | [path] | [Purpose] |
```

**Source Structure Guidelines**:
1. Follow existing codebase conventions when present
2. Group related files by feature or domain
3. Keep test files adjacent to or mirroring source structure
4. Place shared utilities in dedicated directories

#### 7.4: Map Files to Requirements

Create a traceability matrix linking planned files to spec requirements:

```markdown
### File-to-Requirement Mapping

| Planned File | Primary Requirement(s) | Description |
|--------------|------------------------|-------------|
| [path/file1] | FR-001, FR-002 | [What this file implements] |
| [path/file2] | FR-003 | [What this file implements] |
| [path/file3] | FR-004, NFR-001 | [What this file implements] |
| [path/config] | NFR-002 | [Configuration for this requirement] |

**Unmapped Requirements**:
List any requirements that don't directly map to source files (e.g., documentation requirements, process requirements):
- [REQ-ID]: [Why no direct file mapping]
```

**Mapping Guidelines**:
1. Every functional requirement (FR-###) should map to at least one file
2. Non-functional requirements (NFR-###) may map to configuration or be constraints
3. If a requirement cannot be mapped, document why
4. Use this mapping during task generation to ensure complete coverage

#### 7.5: Add Project Structure Section to plan.md

Compile the project structure information into the plan.md document:

```markdown
## Project Structure

### Documentation Layout

```
specs/[feature-id]/
├── spec.md
├── research.md
├── data-model.md
├── plan.md
├── quickstart.md
├── tasks.md
└── checklists/
```

### Source Code Layout

Based on project type: [Type]

```
[Appropriate structure from 7.1]
```

### Directory Purposes

| Directory | Purpose |
|-----------|---------|
| [dir] | [purpose] |

### File-to-Requirement Mapping

| File | Requirements | Purpose |
|------|--------------|---------|
| [file] | [FR-###] | [purpose] |

### New Files to Create

| File Path | Type | Description |
|-----------|------|-------------|
| [path] | [source/config/test] | [What it will contain] |
```

#### 7.6: Finalize and Write plan.md

Complete the plan.md document and write to the feature directory:

1. **Verify All Sections Present**:
   - [ ] Header with feature metadata
   - [ ] Technical Context
   - [ ] Constitution Check
   - [ ] Project Structure
   - [ ] All placeholder text replaced

2. **Cross-Reference Check**:
   - [ ] File mapping covers all spec requirements
   - [ ] Directory structure matches Technical Context platform
   - [ ] Dependencies are reflected in configuration files

3. **Write Final plan.md**:
   Write the completed plan to `FEATURE_DIR/plan.md`

### Step 8: Plan Completion Summary

Report all created artifacts and provide next steps guidance.

#### 8.1: Report Created Artifacts

Generate a summary of all artifacts created during the planning phase:

```markdown
## Planning Complete

The following artifacts have been generated in `specs/[feature-id]/`:

### Generated Artifacts

| Artifact | Status | Description |
|----------|--------|-------------|
| research.md | Created | Technology research and decision documentation |
| data-model.md | Created | Entity definitions, relationships, and schemas |
| plan.md | Created | Technical context, constraints, and project structure |
| quickstart.md | Created | Prerequisites, installation, and usage guide |

### Artifact Summary

**research.md**:
- [X] Technical unknowns identified and resolved
- [X] Decision rationale documented
- [X] Sources and references included

**data-model.md**:
- [X] [N] entities defined
- [X] Relationships documented
- [X] Validation rules specified

**plan.md**:
- [X] Language and runtime specified
- [X] Dependencies cataloged
- [X] Platform requirements defined
- [X] Constitution compliance verified
- [X] Project structure defined

**quickstart.md**:
- [X] Prerequisites listed
- [X] Installation steps provided
- [X] Examples included
```

#### 8.2: Suggest Next Steps

Provide clear guidance on the recommended next action:

```markdown
### Next Steps

The implementation plan is complete. To continue:

**Recommended**: Generate implementation tasks
```
/projspec:tasks
```

This will:
1. Read the plan artifacts (spec.md, research.md, data-model.md, plan.md)
2. Generate a dependency-ordered task list
3. Create tasks.md with actionable implementation steps

**Alternative Actions**:
- `/projspec:analyze` - Perform cross-artifact consistency analysis
- `/projspec:checklist` - Generate a requirements validation checklist
- Manual review - Review generated artifacts before proceeding
```

#### 8.3: Output Planning Summary

Print the final planning summary to the user:

```
Planning phase complete for [Feature Name]

Artifacts created:
  - specs/[feature-id]/research.md
  - specs/[feature-id]/data-model.md
  - specs/[feature-id]/plan.md
  - specs/[feature-id]/quickstart.md

Constitution check: [PASS/FAIL]
Entities defined: [N]
Requirements mapped: [N]/[Total]

Next step: Run /projspec:tasks to generate implementation tasks
```

## Output

Upon successful completion, this command generates:

- `research.md` - Technology research and documentation findings
- `data-model.md` - Data structures and state schemas
- `plan.md` - Complete implementation plan with technical context
- `quickstart.md` - Setup and getting started guide

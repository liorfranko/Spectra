# Command: plan

## Purpose

Generate a comprehensive technical implementation plan from an existing feature specification. This command transforms a validated spec.md into actionable design artifacts that guide implementation, ensuring alignment with project constitution principles.

The planning process:
1. Reads and analyzes the existing spec.md to understand requirements
2. Verifies alignment with the project constitution
3. Creates plan.md with technical approach, file structure, and architecture
4. Generates supporting design artifacts (research.md, data-model.md, quickstart.md, contracts/)
5. Updates the feature state to the "plan" phase
6. Refreshes the agent context file (CLAUDE.md) with new technology information

---

## Prerequisites

Before running this command, verify the following:

1. **Existing spec.md**: The feature must have a spec.md file already created (via the `specify` command)
2. **Feature in spec phase**: The feature should be in the specification phase with status "Review" or "Approved"
3. **Constitution exists**: The project must have a constitution at `.specify/memory/constitution.md`
4. **Feature directory exists**: The feature's specification directory must exist (e.g., `specs/{ID}-{feature-slug}/` or `.specify/features/{ID}-{feature-slug}/`)
5. **Working in feature context**: You should be in the feature's worktree or have the feature context loaded

If prerequisites are not met, inform the user:
- If no spec.md exists, suggest running the `specify` command first
- If spec.md is still in "Draft" status, suggest running `clarify` to refine it first
- If no constitution exists, suggest creating one or proceeding with default principles

---

## Workflow

Follow these steps in order:

### Step 1: Locate and Read Required Documents

Find and read the following documents:

1. **Feature Specification**: Locate spec.md for the current feature
   - Check the current directory for spec.md
   - Check `specs/{feature-slug}/spec.md`
   - Check `.specify/features/{feature-slug}/spec.md`

2. **Project Constitution**: Read `.specify/memory/constitution.md`
   - If not found, check `constitution.md` in project root
   - If no constitution exists, document this as a gap and proceed with general best practices

3. **Plan Template**: Use the `plan-template.md` as the structure guide
   - Located at `templates/plan-template.md` or `.specify/templates/plan-template.md`

Read all documents thoroughly before proceeding.

### Step 2: Analyze the Specification

Review the spec.md to extract:

#### Core Requirements
- User stories and their priorities (P1, P2, P3)
- Functional requirements (FR-XXX)
- Non-functional requirements (NFR-XXX)
- Success criteria

#### Technical Implications
- Data entities and relationships mentioned
- API or interface requirements
- Integration points with external systems
- Performance, security, or scalability constraints

#### Scope Boundaries
- What is explicitly in scope
- What is explicitly out of scope
- Dependencies on other features or systems

Mark any unclear or underspecified technical areas as "NEEDS CLARIFICATION" for Phase 0 research.

### Step 3: Check Constitution Compliance

Before designing the solution, verify alignment with the project constitution:

#### For Each Core Principle
1. Read the principle statement and rationale
2. Evaluate how the feature design could apply this principle
3. Identify any potential conflicts or tensions
4. Document alignment status: YES, NO, or PARTIAL

#### Constitution Check Table
Create a table documenting each principle:

```markdown
## Constitution Check

| Principle | Alignment | Notes |
|-----------|-----------|-------|
| {Principle 1 Name} | YES/NO/PARTIAL | {How the design aligns or conflicts} |
| {Principle 2 Name} | YES/NO/PARTIAL | {How the design aligns or conflicts} |
```

#### Handling Violations
- If a principle cannot be followed, document why
- Check the constitution's Decision Framework for priority guidance
- Follow the Exception Process if needed
- **ERROR**: Stop and report if a violation cannot be justified

### Step 4: Create the Implementation Plan (plan.md)

Using the plan-template.md structure, create plan.md with all required sections:

#### Required Sections

1. **Header**: Feature name, branch, date, link to spec.md

2. **Summary**: 2-3 sentences describing the implementation approach

3. **Technical Context**:
   - Existing Codebase Analysis: Relevant files, patterns in use, integration points
   - Technology Stack: Required technologies and tools
   - Mark unknowns as "NEEDS CLARIFICATION"

4. **Constitution Check**: The compliance table from Step 3

5. **Project Structure**:
   - Visual tree of how files will be organized
   - New Files table: Path and purpose
   - Modified Files table: Path and what changes

6. **Complexity Tracking**:
   - Risk Assessment: Identify risks with likelihood, impact, and mitigation
   - Complexity Indicators: Effort, integration, and testing complexity

7. **Implementation Phases**: Logical phases with goals and steps

8. **API Design**: Define interfaces, contracts, or APIs (if applicable)

9. **Testing Strategy**: Unit tests, integration tests, manual testing

10. **Rollback Plan**: How to safely revert if issues arise

11. **Open Design Decisions**: Decisions to finalize during implementation

### Step 5: Generate Phase 0 - Research Artifacts

**Goal**: Resolve all "NEEDS CLARIFICATION" items and document technology decisions.

#### Create research.md

For each unknown or technology decision:

1. **Extract Research Tasks**:
   - Each "NEEDS CLARIFICATION" becomes a research task
   - Each technology choice needs best practices research
   - Each integration point needs patterns research

2. **Conduct Research**:
   - Investigate options and alternatives
   - Consider project constitution principles when choosing
   - Document findings with rationale

3. **Document in research.md**:

```markdown
# Research: {Feature Name}

## Decision: {Topic}

**Choice**: {What was chosen}

**Rationale**: {Why this choice was made}

**Alternatives Considered**:
- {Alternative 1}: {Why not chosen}
- {Alternative 2}: {Why not chosen}

**Constitution Alignment**: {How choice aligns with principles}
```

**Output**: `research.md` with all technical decisions documented

### Step 6: Generate Phase 1 - Design Artifacts

**Prerequisites**: research.md complete with all clarifications resolved

#### Create data-model.md (if applicable)

Extract entities from the feature spec:

```markdown
# Data Model: {Feature Name}

## Entity: {EntityName}

**Description**: {Purpose of this entity}

### Fields

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| {field} | {type} | Yes/No | {rules} | {description} |

### Relationships

- {Relationship description}

### State Transitions (if applicable)

| Current State | Event | Next State | Conditions |
|---------------|-------|------------|------------|
| {state} | {event} | {state} | {conditions} |
```

#### Create contracts/ Directory (if applicable)

Generate API contracts from functional requirements:

1. **Identify Endpoints**: For each user action in user stories, define an endpoint
2. **Design Contracts**: Use OpenAPI (REST) or GraphQL schema format
3. **Include**:
   - Request/response schemas
   - Error responses
   - Authentication requirements
   - Rate limiting (if applicable)

Create files like:
- `contracts/api.yaml` (OpenAPI specification)
- `contracts/graphql/schema.graphql` (GraphQL schema)

#### Create quickstart.md

Define validation scenarios for testing the implementation:

```markdown
# Quickstart: {Feature Name}

## Prerequisites

- {Required setup step}
- {Required configuration}

## Validation Scenarios

### Scenario 1: {Happy Path Scenario Name}

**Steps**:
1. {Step 1}
2. {Step 2}

**Expected Result**: {What should happen}

### Scenario 2: {Edge Case Scenario Name}

**Steps**:
1. {Step 1}

**Expected Result**: {What should happen}

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| {Issue} | {Cause} | {Solution} |
```

### Step 7: Re-evaluate Constitution Compliance

After generating all design artifacts:

1. **Review the Constitution Check table** from Step 3
2. **Update alignment status** if any decisions changed during design
3. **Verify no new violations** were introduced
4. **Document any exceptions** that were approved

If new violations are discovered:
- Return to the relevant design artifact
- Adjust the design to achieve compliance
- Or document a justified exception

### Step 8: Update Feature State

Update the feature to indicate the planning phase is complete:

1. **Update spec.md status**: Change from "Review" to "Planning Complete" or similar
2. **Create or update state metadata**: If the project uses state files (e.g., `.state.json`, `meta.json`)
3. **The feature is now in the "plan" phase** of the development lifecycle

### Step 9: Update Agent Context

Run the update-agent-context.sh script to refresh CLAUDE.md:

```bash
./scripts/update-agent-context.sh
```

Or if using the .specify scripts:

```bash
./.specify/scripts/bash/update-agent-context.sh claude
```

This will:
- Detect which AI agent is in use
- Update the appropriate agent-specific context file
- Add new technologies from the current plan
- Preserve manual additions between markers

### Step 10: Present the Plan

After creating all artifacts:

1. **Summarize what was created**:
```
## Planning Complete

### Artifacts Created:
- plan.md - Technical implementation plan
- research.md - Technology decisions and rationale
- data-model.md - Entity definitions (if applicable)
- quickstart.md - Validation scenarios
- contracts/ - API contracts (if applicable)

### Constitution Compliance:
- All principles verified: {YES/NO}
- Exceptions documented: {COUNT}

### Next Steps:
- Review the plan with stakeholders
- Proceed to task generation with `/tasks`
- Begin implementation
```

2. **Highlight any areas needing attention**:
   - Open design decisions
   - Risks requiring mitigation
   - Constitution exceptions

3. **Suggest next steps**:
   - Run `/tasks` to generate implementation tasks
   - Review with team for feedback
   - Begin Phase 1 implementation

---

## Output

Upon successful completion, the following will be created:

### Files Created

| File | Description |
|------|-------------|
| `plan.md` | Technical implementation plan with architecture and phases |
| `research.md` | Technology decisions with rationale and alternatives |
| `data-model.md` | Entity definitions with fields and relationships (if applicable) |
| `quickstart.md` | Validation scenarios for testing the implementation |
| `contracts/` | Directory containing API contracts (if applicable) |

### Plan Contents

The plan.md will contain:
- Summary of implementation approach
- Technical context and existing codebase analysis
- Constitution compliance verification
- Project structure with new and modified files
- Risk assessment and complexity tracking
- Implementation phases with specific steps
- API design and interface definitions
- Testing strategy
- Rollback plan
- Open design decisions

### Feature State

- Phase: `plan`
- Status: Planning Complete
- Ready for: Task generation and implementation

### Agent Context

- CLAUDE.md updated with new technologies
- Project structure documented
- Commands refreshed if applicable

---

## Examples

### Example 1: Standard Feature Planning

**Scenario**: User has a complete spec.md for a "user authentication" feature.

**Actions**:
1. Read spec.md and constitution.md
2. Identify authentication method, session management, security requirements
3. Check constitution principles (e.g., "Security First", "User Privacy")
4. Create plan.md with OAuth integration, JWT tokens, secure storage
5. Generate research.md documenting why OAuth was chosen over API keys
6. Create data-model.md with User, Session, Token entities
7. Create quickstart.md with login, logout, session expiry scenarios
8. Update agent context with new dependencies (OAuth library, JWT library)

### Example 2: API-Heavy Feature

**Scenario**: User has spec.md for "project export" with multiple export formats.

**Actions**:
1. Read spec.md identifying export to JSON, CSV, PDF
2. Constitution check reveals "Performance" principle requiring async exports
3. Research.md documents choice of background job processing
4. Create contracts/export-api.yaml with endpoints for:
   - POST /exports (initiate export)
   - GET /exports/{id} (check status)
   - GET /exports/{id}/download (get file)
5. data-model.md defines ExportJob entity with status transitions
6. quickstart.md includes scenarios for each format and large file handling

### Example 3: Constitution Conflict

**Scenario**: Spec requires storing sensitive data, but constitution has "Minimal Data Collection" principle.

**Actions**:
1. Identify conflict during Constitution Check
2. Review Decision Framework priority order
3. If security > minimal data, document justification
4. Follow Exception Process if needed
5. Document in plan.md Constitution Check table:
   | Minimal Data | PARTIAL | Storing encrypted tokens required for OAuth; minimal additional data |
6. Proceed with justified exception

---

## Error Handling

### Common Issues

1. **No spec.md found**: Guide user to run `specify` command first
2. **Spec still in Draft**: Suggest running `clarify` to refine before planning
3. **No constitution found**: Offer to proceed with general best practices, or guide to create constitution
4. **Constitution violation without justification**: ERROR - stop and require resolution
5. **Unable to resolve NEEDS CLARIFICATION**: ERROR - stop and ask user for input

### Recovery Steps

If the command fails partway through:
1. Check what artifacts were created (plan.md, research.md, etc.)
2. Report which steps completed successfully
3. Resume from the failed step rather than starting over
4. Keep partial artifacts for reference

### Validation Errors

Before completing, validate:
- [ ] All "NEEDS CLARIFICATION" items are resolved in research.md
- [ ] All constitution principles have alignment status
- [ ] plan.md has all required sections
- [ ] File structure is consistent with project conventions

---

## Notes

- **Constitution compliance is mandatory**: Do not skip the compliance check even under time pressure
- **Research thoroughly**: Hasty technology decisions create technical debt
- **Link to spec.md**: The plan should reference specific requirements by ID (FR-001, NFR-002)
- **Keep artifacts in sync**: If the spec changes, the plan may need updating
- **Phase appropriately**: Break complex implementations into smaller, verifiable phases
- **Design for testability**: Consider how each component will be tested
- **Document trade-offs**: Explain why alternatives were rejected, not just what was chosen
- **Update agent context last**: Ensure all other artifacts are complete first
- **Iterate if needed**: Complex features may require multiple planning sessions

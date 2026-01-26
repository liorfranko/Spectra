# Skill: PRD to Specification Translation

## When to Use
When translating a detailed Product Requirements Document (PRD) into a feature specification using the speckit workflow.

## Pattern

1. **Extract Core Concepts First**
   - Identify the main problem being solved
   - List the key actors and their goals
   - Note any explicit constraints or principles

2. **Map PRD Sections to User Stories**
   - Each major feature area becomes 1-2 user stories
   - Workflow phases often map to sequential user stories
   - Priority P1 = foundational/blocking, P2 = enhancement/optional

3. **Convert Technical Descriptions to Requirements**
   - PRD implementation details → Key Entities (without implementation)
   - PRD data models → Functional requirements about data capabilities
   - PRD error handling → Edge cases and acceptance scenarios

4. **Derive Measurable Success Criteria**
   - Look for any metrics mentioned in the PRD
   - Convert implementation metrics to user-facing outcomes
   - Add implicit quality attributes (reliability, usability)

5. **Document Assumptions**
   - Extract prerequisites from the PRD
   - Note any implicit dependencies (tools, environment)
   - Capture scope boundaries (what's Phase 2, out of scope)

## Example Transformation

**PRD says**: "State is stored in simple YAML files that Claude reads/writes directly"

**Spec says**:
- FR-005: System MUST store spec state in `state.yaml` files
- Key Entity: Spec has ID, name, phase, branch, worktree path, tasks
- (No mention of YAML format in spec - that's implementation)

## Key Insight
The spec should be readable by someone who hasn't seen the PRD. Focus on WHAT and WHY, never HOW.

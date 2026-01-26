---
description: Create a structured feature specification from a natural language description
user-invocable: true
argument-hint: feature description
---

# Specify Command

Create or update a feature specification from a natural language feature description. This command transforms informal requirements into a structured spec.md document.

## Arguments

The `$ARGUMENTS` variable contains the feature description provided by the user. This should be a natural language description of the feature to be specified.

## Workflow Steps

### Step 1: Validate Input

Check that the user provided a feature description:

1. If `$ARGUMENTS` is empty or contains only whitespace:
   - Prompt the user: "Please provide a feature description. What feature would you like to specify?"
   - Wait for user input before proceeding
   - Store the response as the feature description

2. If `$ARGUMENTS` contains a valid description:
   - Use it directly as the feature description
   - Proceed to Step 2

### Step 2: Create Feature Structure

Run the create-new-feature.sh script to set up the feature branch and directory:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/create-new-feature.sh "$ARGUMENTS" --json
```

**Parse the JSON output** to extract:
- `FEATURE_ID`: The unique identifier for the feature (e.g., "003-user-auth")
- `FEATURE_DIR`: The absolute path to the feature directory (e.g., "/path/to/specs/003-user-auth")
- `BRANCH`: The git branch name (same as FEATURE_ID)

**Error Handling:**
- If the script exits with a non-zero status, report the error message to the user and stop
- Common errors include:
  - Feature directory already exists
  - Branch already exists
  - Failed to create worktree
  - Invalid feature description

### Step 3: Navigate to Feature Directory

Use the `FEATURE_DIR` path from the script output:

1. Verify the directory exists and contains a `checklists/` subdirectory
2. The spec.md file will be created at: `${FEATURE_DIR}/spec.md`
3. Store the feature context for subsequent steps:
   - Feature ID: Used for cross-references
   - Feature Directory: Base path for all feature artifacts
   - Branch Name: For git operations

### Step 4: Generate Specification

Read the spec template and generate a structured specification document from the feature description.

#### 4.1: Load Template

Read the spec template from:
```
${CLAUDE_PLUGIN_ROOT}/templates/spec-template.md
```

This template contains placeholder markers that need to be replaced with generated content.

#### 4.2: Analyze Feature Description

Carefully analyze the feature description (`$ARGUMENTS`) to extract the following elements:

**Feature Identification:**
- Extract a clear, concise feature name from the description
- Identify the core purpose and value proposition
- Determine the primary user role(s) involved

**Key Concepts Extraction:**
- Identify nouns that represent domain entities (e.g., "user", "document", "notification")
- Identify verbs that represent actions (e.g., "create", "validate", "sync")
- Note any relationships between entities mentioned

**User Intent Analysis:**
- Infer who will use this feature (the user role)
- Determine what actions they want to perform
- Understand why they need this capability (the benefit)

**Requirements Inference:**
- Extract explicit requirements stated in the description
- Infer implicit requirements from the context
- Identify any constraints or limitations mentioned

#### 4.3: Fill Template Sections

Replace template placeholders with generated content:

**Metadata Section:**
| Placeholder | Replacement |
|-------------|-------------|
| `[FEATURE_NAME]` | Extracted feature name (title case, descriptive) |
| `[BRANCH]` | The `FEATURE_ID` from Step 2 output |
| `[DATE]` | Current date in YYYY-MM-DD format |
| `[STATUS]` | `Draft` |
| `[BRIEF_DESCRIPTION_OF_FEATURE_REQUEST]` | First sentence of `$ARGUMENTS` |

**User Scenarios Section (US-###):**
Generate at least 2 user scenarios:
- US-001: Primary/happy path scenario based on main feature intent
- US-002: Secondary scenario or alternative flow
- For each scenario:
  - `[ROLE]`: The user type performing the action
  - `[ACTION]`: The specific action they want to take
  - `[BENEFIT]`: The value they receive
  - `[CRITERION_N]`: 2-4 testable acceptance criteria
  - `[Priority]`: High for primary scenarios, Medium/Low for secondary

**Edge Cases Table:**
Generate 3 edge cases considering:
- Empty or missing input
- Maximum limits or boundaries
- Error conditions or failure modes

**Requirements Section (FR-###):**
Generate 3-5 functional requirements:
- FR-001 through FR-00N
- Each requirement must be:
  - **Testable**: Can be verified as pass/fail
  - **Specific**: No ambiguous terms
  - **Independent**: Understandable on its own
- Include a verification method for each requirement

**Constraints Table:**
If the description mentions any limitations, performance needs, or compatibility requirements, document them here. Otherwise, leave the table with placeholder rows to be filled during clarification.

**Key Entities Section:**
For each identified domain entity:
- Provide a clear description of what it represents
- List 2-4 key attributes with descriptions and constraints
- Document relationships between entities

**Success Criteria Section (SC-###):**
Generate 2-3 success criteria:
- SC-001 through SC-00N
- Each criterion must be:
  - **Measurable**: Has a quantifiable target
  - **Verifiable**: Has a clear verification method
- Examples: "Feature loads in under 2 seconds", "Error rate below 1%"

**Assumptions Section:**
Document 2-3 assumptions made while generating the spec:
- Technical assumptions (e.g., "User has network connectivity")
- Business assumptions (e.g., "Feature is for authenticated users only")
- Mark all as `Validated: No` initially

**Open Questions Section:**
Leave Q-001 and Q-002 as placeholders for clarification questions (handled in Step 5).

**Revision History:**
- Version: `0.1`
- Date: Current date in YYYY-MM-DD format
- Author: `Claude (speckit)`
- Changes: `Initial draft from feature description`

#### 4.4: Write Specification File

Write the completed specification to:
```
${FEATURE_DIR}/spec.md
```

**Validation before writing:**
1. Ensure all `[PLACEHOLDER]` markers have been replaced (except those intentionally left for clarification)
2. Verify at least 2 user scenarios are defined
3. Verify at least 3 functional requirements are defined
4. Verify at least 2 success criteria are defined
5. Confirm no implementation details (languages, frameworks, APIs) are included

**Quality Guidelines:**
- Use clear, professional language
- Avoid jargon unless domain-specific and necessary
- Keep requirements atomic (one requirement = one thing)
- Ensure traceability (scenarios map to requirements, requirements map to success criteria)

### Step 5: Identify Clarification Needs

After generating the initial specification, review it for ambiguous or underspecified areas that require user input.

#### 5.1: Scan for Ambiguities

Review the generated specification for these common ambiguity patterns:

**Vague Scope:**
- Features described without clear boundaries
- Missing user role definitions
- Unclear interaction between entities

**Missing Details:**
- Quantities without specified limits (e.g., "multiple items" - how many?)
- Timeframes without duration (e.g., "quickly" - how fast?)
- Conditions without thresholds (e.g., "large file" - what size?)

**Implicit Requirements:**
- Authentication/authorization not explicitly stated
- Error handling behavior not specified
- Edge cases not addressed in the original description

**Technical Gaps:**
- Data persistence needs unclear
- Integration points not defined
- Performance expectations unstated

#### 5.2: Prioritize and Limit Clarifications

**Maximum 3 Clarification Items:**
If more than 3 ambiguities are found, prioritize using these criteria (in order):
1. **Blockers**: Ambiguities that prevent implementation from starting
2. **Scope-defining**: Ambiguities that significantly affect feature scope
3. **Risk-bearing**: Ambiguities that could lead to rework if assumed incorrectly

Defer lower-priority ambiguities to the `/speckit.clarify` command for later resolution.

#### 5.3: Mark Clarification Items

For each prioritized ambiguity (up to 3), add a `[NEEDS CLARIFICATION]` marker in the appropriate section of the spec:

**Marker Format:**
```markdown
[NEEDS CLARIFICATION: Brief description of what's unclear]
```

**Placement Rules:**
- Place the marker immediately after the ambiguous content
- If the ambiguity affects an entire section, place it at the section header
- Do not place markers in the Open Questions section (those go there as full questions)

#### 5.4: Create Structured Questions

For each `[NEEDS CLARIFICATION]` marker, add a corresponding entry to the **Open Questions** section of the spec. Each question must include:

**Required Fields:**
| Field | Description |
|-------|-------------|
| Question ID | Sequential ID: Q-001, Q-002, Q-003 |
| Question | Clear, specific question that can be answered definitively |
| Why Needed | Brief explanation of why this information affects the implementation |
| Suggested Default | A reasonable default to use if the user doesn't provide clarification |
| Status | Set to `Open` |
| Impact | Which spec sections/IDs are affected (e.g., "FR-002, US-001") |

**Question Format in Open Questions Section:**
```markdown
### Q-001: [Concise question title]
- **Question**: [Full question text - specific and answerable]
- **Why Needed**: [Impact on implementation if not clarified]
- **Suggested Default**: [Reasonable default value or behavior]
- **Status**: Open
- **Impacts**: [List of affected spec item IDs]
```

#### 5.5: Update Spec File

After identifying clarification needs:

1. **Add markers to spec content**: Insert `[NEEDS CLARIFICATION]` markers at ambiguous points
2. **Populate Open Questions section**: Replace placeholder questions with structured clarification questions
3. **Write updated spec**: Save the modified specification to `${FEATURE_DIR}/spec.md`

**Example Clarification Entry:**
```markdown
### Q-001: Maximum file size limit
- **Question**: What is the maximum file size allowed for uploads?
- **Why Needed**: Affects storage architecture and upload timeout configuration
- **Suggested Default**: 10MB (standard web upload limit)
- **Status**: Open
- **Impacts**: FR-003, EC-002
```

#### 5.6: Report Clarification Status

After processing clarifications, prepare a summary for the user:

**If clarifications are needed (1-3 items):**
- List each question with its ID and brief description
- Indicate the suggested defaults that will be used if not clarified
- Inform user they can run `/speckit.clarify` to address these questions

**If no clarifications are needed:**
- Note that the specification is complete and ready for planning
- Proceed to finalization

**If more than 3 ambiguities were found:**
- Report the 3 prioritized questions
- Mention that additional clarifications can be addressed with `/speckit.clarify`

<!-- T020: Add finalization step -->
<!-- Finalize spec and report results -->

## Output

Upon completion, this command will:
1. Create a structured specification document at `specs/{feature-id}/spec.md`
2. Report any clarification questions or ambiguities found
3. Provide a summary of the generated specification

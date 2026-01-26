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

### Step 6: Validate Specification

Before finalizing, validate the specification against quality rules to ensure it meets requirements for a complete, implementation-agnostic specification.

#### 6.1: Check Mandatory Sections

Verify all required sections are present and non-empty:

**Mandatory Sections Checklist:**
| Section | Requirement | Validation |
|---------|-------------|------------|
| User Scenarios & Testing | At least 2 scenarios (US-001, US-002) | Count `### US-` headers |
| Requirements | At least 1 functional requirement (FR-001) | Count `### FR-` headers |
| Success Criteria | At least 1 success criterion (SC-001) | Count `### SC-` headers |
| Edge Cases | At least 1 entry in the table | Check table has data rows |

**Validation Logic:**
1. Parse the spec.md file content
2. Count occurrences of each section pattern
3. Flag any section that doesn't meet minimum count

**If validation fails:**
- Report which sections are incomplete
- Do not proceed to finalization
- Suggest user provide additional details or rerun with more context

#### 6.2: Verify No Implementation Details

Scan the entire specification for implementation-specific language that should not appear in a spec:

**Prohibited Content Categories:**

| Category | Examples | Detection Pattern |
|----------|----------|-------------------|
| Programming Languages | Python, JavaScript, TypeScript, Java, Go, Rust, Ruby, C++, C#, PHP, Swift, Kotlin | Case-insensitive word match |
| Frontend Frameworks | React, Vue, Angular, Svelte, Next.js, Nuxt, Remix, Astro | Case-insensitive word match |
| Backend Frameworks | Django, Flask, FastAPI, Express, NestJS, Spring, Rails, Laravel | Case-insensitive word match |
| Databases | PostgreSQL, MySQL, MongoDB, Redis, SQLite, DynamoDB, Cassandra | Case-insensitive word match |
| API Specifications | REST endpoint, GraphQL schema, gRPC, WebSocket protocol | Phrase match |
| Infrastructure | Docker, Kubernetes, AWS Lambda, Azure Functions, S3 bucket | Case-insensitive word match |

**Scanning Process:**
1. Read the full spec content (excluding code blocks in examples)
2. Check each prohibited term against the content
3. Collect all matches with their locations

**If implementation details are found:**
- List each occurrence with section and context
- Mark the spec as needing revision
- Suggest rephrasing to focus on "what" not "how":
  - Instead of "Use PostgreSQL database" → "Data must be persisted and queryable"
  - Instead of "React component" → "User interface element"
  - Instead of "REST API endpoint" → "System interface"

#### 6.3: Verify Requirements Format

Validate that all functional requirements follow the correct format and are testable.

**Format Requirements:**
- Each requirement uses the `FR-###` identifier format (e.g., FR-001, FR-002)
- Each requirement has a verification method defined
- Requirements are atomic (one testable behavior per requirement)

**Testability Criteria:**
A requirement is testable if it includes:
- **Clear action**: A specific behavior that can be observed
- **Defined conditions**: When/where the behavior occurs
- **Expected outcome**: What should happen (pass/fail determinable)

**Validation Steps:**
1. Extract all `### FR-###` sections
2. For each requirement:
   - Verify ID format matches `FR-\d{3}` pattern
   - Check for verification/testing subsection or method
   - Ensure no vague terms like "should be easy", "user-friendly", "fast enough"
3. Flag non-compliant requirements

**Vague Terms to Flag:**
- "easy to use", "user-friendly", "intuitive"
- "fast", "quick", "responsive" (without measurable threshold)
- "robust", "reliable", "stable" (without specific criteria)
- "as needed", "when appropriate", "sometimes"

#### 6.4: Verify Success Criteria Format

Validate that all success criteria are measurable and verifiable.

**Format Requirements:**
- Each criterion uses the `SC-###` identifier format (e.g., SC-001, SC-002)
- Each criterion has a measurable target value
- Each criterion has a verification method

**Measurability Criteria:**
A success criterion is measurable if it includes:
- **Quantifiable metric**: A number, percentage, duration, or count
- **Target value**: The threshold that defines success
- **Measurement method**: How the metric will be collected

**Validation Steps:**
1. Extract all `### SC-###` sections
2. For each criterion:
   - Verify ID format matches `SC-\d{3}` pattern
   - Check for numeric target (e.g., "< 2 seconds", "95%", "zero errors")
   - Verify measurement method is specified
3. Flag criteria without measurable targets

**Examples of Valid vs Invalid:**
| Invalid | Valid |
|---------|-------|
| "Feature should be fast" | "Page load time < 2 seconds (P95)" |
| "Users should be satisfied" | "User satisfaction score >= 4.0/5.0 in feedback survey" |
| "Low error rate" | "Error rate < 0.1% over 7-day window" |

#### 6.5: Count NEEDS CLARIFICATION Markers

Check that clarification needs are within acceptable limits.

**Maximum Allowed:** 3 `[NEEDS CLARIFICATION]` markers

**Counting Process:**
1. Search for all occurrences of `[NEEDS CLARIFICATION` in the spec
2. Count total occurrences
3. Compare against maximum threshold

**If count exceeds 3:**
- The spec is considered too ambiguous to proceed
- Report the count and recommend:
  - Obtain more details from the user before continuing
  - Run `/speckit.clarify` to resolve existing questions first
  - Consider breaking the feature into smaller, clearer features

**If count is 0-3:**
- Spec passes this validation
- Note the count in the validation report

#### 6.6: Generate Validation Report

Compile all validation results into a structured report.

**Report Format:**
```markdown
## Specification Validation Report

**Feature:** [FEATURE_ID]
**Validated:** [TIMESTAMP]

### Section Completeness
| Section | Required | Found | Status |
|---------|----------|-------|--------|
| User Scenarios | >= 2 | [count] | [PASS/FAIL] |
| Requirements | >= 1 | [count] | [PASS/FAIL] |
| Success Criteria | >= 1 | [count] | [PASS/FAIL] |
| Edge Cases | >= 1 | [count] | [PASS/FAIL] |

### Implementation Details Check
- **Status**: [PASS/FAIL]
- **Violations Found**: [count]
[If violations exist, list each with location]

### Requirements Format Check
- **Total Requirements**: [count]
- **Properly Formatted**: [count]
- **Testable**: [count]
- **Status**: [PASS/FAIL]
[If issues exist, list each requirement ID with issue description]

### Success Criteria Format Check
- **Total Criteria**: [count]
- **Properly Formatted**: [count]
- **Measurable**: [count]
- **Status**: [PASS/FAIL]
[If issues exist, list each criterion ID with issue description]

### Clarification Markers
- **Count**: [count] / 3 maximum
- **Status**: [PASS/FAIL]

### Overall Result
- **Status**: [VALID/INVALID]
- **Issues to Address**: [count]
```

#### 6.7: Handle Validation Results

Based on the validation report, take appropriate action:

**If ALL checks pass (Status: VALID):**
1. Proceed to finalization
2. Include validation summary in output to user
3. Note that spec is ready for `/speckit.plan` command

**If ANY check fails (Status: INVALID):**
1. Do not mark spec as complete
2. Display the full validation report to the user
3. For each failure, provide actionable guidance:
   - Missing sections: "Add at least [N] more [section type]"
   - Implementation details: "Remove or rephrase: [specific term] in [section]"
   - Format issues: "Update [ID] to include [missing element]"
   - Vague requirements: "Add measurable threshold to [ID]"
   - Too many clarifications: "Resolve open questions before proceeding"
4. Offer to help fix issues: "Would you like me to help address these validation issues?"

**Partial Pass Handling:**
If the spec passes critical checks (sections present, no implementation details) but has minor format issues:
- Warn the user but allow proceeding with caution
- Recommend running `/speckit.clarify` to improve quality
- Mark spec status as "Draft - Needs Review"

### Step 7: Generate Requirements Checklist

After validation passes, generate a requirements checklist to help validate specification quality before proceeding to planning.

#### 7.1: Create Checklists Directory

Ensure the checklists directory exists within the feature directory:

```
${FEATURE_DIR}/checklists/
```

If the directory doesn't exist, create it. The `create-new-feature.sh` script typically creates this directory, but verify it exists.

#### 7.2: Generate Requirements Checklist Content

Create a requirements checklist based on the checklist template format. The checklist should validate spec quality across these categories:

**Checklist Header:**
```markdown
# Requirements Checklist: [FEATURE_NAME]

**Purpose**: Validate specification quality before proceeding to implementation planning
**Created**: [DATE in YYYY-MM-DD format]
**Feature**: [Link to spec.md]

---

## Overview

This checklist validates that the feature specification is complete, well-formed,
and ready for implementation planning. All items should pass before running `/speckit.plan`.

---
```

**Completeness Section:**
Generate checklist items to verify all required sections are present:
- [ ] Overview section describes feature purpose and scope
- [ ] At least 2 user scenarios are defined (US-001, US-002)
- [ ] Edge cases table has at least 1 entry
- [ ] At least 1 functional requirement is defined (FR-001)
- [ ] At least 1 success criterion is defined (SC-001)
- [ ] Key entities are identified and described
- [ ] Assumptions are documented
- [ ] Open questions are tracked (if any)

**Requirement Quality Section:**
Generate checklist items to verify requirements meet quality standards:
- [ ] All requirements are testable (have pass/fail criteria)
- [ ] All requirements are specific (no vague terms like "fast", "easy", "user-friendly")
- [ ] All requirements are atomic (one behavior per requirement)
- [ ] All requirements have verification methods defined
- [ ] Requirements use consistent terminology

**Implementation Independence Section:**
Generate checklist items to verify no implementation leakage:
- [ ] No programming languages mentioned (Python, JavaScript, etc.)
- [ ] No frameworks mentioned (React, Django, Express, etc.)
- [ ] No database technologies mentioned (PostgreSQL, MongoDB, etc.)
- [ ] No infrastructure details mentioned (AWS, Docker, etc.)
- [ ] Focus is on "what" not "how"

**Success Criteria Section:**
Generate checklist items to verify success criteria quality:
- [ ] All success criteria have measurable targets
- [ ] Targets include specific values (numbers, percentages, durations)
- [ ] Verification methods are defined for each criterion
- [ ] Criteria are achievable and realistic

**Edge Case Coverage Section:**
Generate checklist items to verify edge cases are addressed:
- [ ] Empty/null input cases are considered
- [ ] Boundary conditions are identified
- [ ] Error scenarios are documented
- [ ] Recovery behaviors are specified

**Assumption Documentation Section:**
Generate checklist items to verify assumptions are properly tracked:
- [ ] All assumptions are explicitly listed
- [ ] Each assumption has validation status
- [ ] Impact of invalid assumptions is understood
- [ ] No hidden assumptions in requirements

**Notes Section:**
```markdown
---

## Notes

<!--
Document any issues, blockers, or observations here.
Format: - [ITEM_REF] Description of issue or note
-->

-

---
```

**Summary Table:**
```markdown
## Summary

| Category                   | Passed | Failed | Skipped |
|----------------------------|--------|--------|---------|
| Completeness               | 0      | 0      | 0       |
| Requirement Quality        | 0      | 0      | 0       |
| Implementation Independence| 0      | 0      | 0       |
| Success Criteria           | 0      | 0      | 0       |
| Edge Case Coverage         | 0      | 0      | 0       |
| Assumption Documentation   | 0      | 0      | 0       |
| **Total**                  | 0      | 0      | 0       |

**Status**: [ ] PASS / [ ] FAIL / [ ] BLOCKED

---

## Instructions

1. Check items as you validate them: `- [x]` for pass, leave unchecked for fail
2. Add notes for any failed or concerning items
3. Update the summary table when complete
4. Mark final status based on results
5. Address any failed items before running `/speckit.plan`
```

#### 7.3: Write Requirements Checklist

Write the generated checklist to:
```
${FEATURE_DIR}/checklists/requirements.md
```

**File Content:**
Combine all sections from 7.2 into a complete checklist document, replacing placeholders:
- `[FEATURE_NAME]`: The feature name from the spec
- `[DATE]`: Current date in YYYY-MM-DD format
- `[Link to spec.md]`: Relative path `../spec.md`

### Step 8: Final Summary

Present a comprehensive summary of all artifacts created and guide the user to next steps.

#### 8.1: Report Created Artifacts

Display a summary of what was created:

```markdown
## Specification Complete

**Feature ID**: [FEATURE_ID]
**Branch**: [BRANCH]
**Directory**: [FEATURE_DIR]

### Artifacts Created

| File | Description | Status |
|------|-------------|--------|
| `spec.md` | Feature specification document | Created |
| `checklists/requirements.md` | Spec quality validation checklist | Created |

### Specification Summary

- **User Scenarios**: [count] defined
- **Functional Requirements**: [count] defined
- **Success Criteria**: [count] defined
- **Edge Cases**: [count] documented
- **Open Questions**: [count] pending
```

#### 8.2: Determine Next Steps

Based on the specification state, recommend appropriate next steps:

**If Open Questions exist (clarifications needed):**
```markdown
### Recommended Next Steps

1. **Review Open Questions**: The specification has [count] open question(s) that should be addressed:
   [List Q-### IDs with brief descriptions]

2. **Run `/speckit.clarify`**: This command will help resolve open questions interactively

3. **Then proceed to `/speckit.plan`**: After clarifications are resolved, generate the implementation plan
```

**If No Open Questions (spec is complete):**
```markdown
### Recommended Next Steps

1. **Review the Specification**: Review `spec.md` to ensure it captures your requirements accurately

2. **Validate with Checklist**: Use `checklists/requirements.md` to verify spec quality

3. **Run `/speckit.plan`**: Generate the implementation plan with architecture and design decisions
```

#### 8.3: Display Feature Context

Provide context information for reference:

```markdown
### Feature Context

- **Feature ID**: [FEATURE_ID]
- **Git Branch**: [BRANCH]
- **Feature Directory**: [FEATURE_DIR]
- **Spec File**: [FEATURE_DIR]/spec.md
- **Checklist**: [FEATURE_DIR]/checklists/requirements.md
```

## Output

Upon completion, this command will:
1. Create a structured specification document at `${FEATURE_DIR}/spec.md`
2. Generate a requirements checklist at `${FEATURE_DIR}/checklists/requirements.md`
3. Report any clarification questions or ambiguities found
4. Provide a summary of the generated specification
5. Recommend next steps based on specification state

---
description: "Identify underspecified areas in the current feature spec by asking up to 5 highly targeted clarification questions and encoding answers back into the spec"
user-invocable: true
---

# Clarify Command

Identify underspecified areas in the current feature specification by scanning for existing clarification markers, analyzing the spec for additional ambiguities, presenting up to 5 targeted clarification questions with suggested answers, and integrating user responses back into the spec.md document.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Prerequisites

This command requires a `spec.md` file to exist in the current feature directory.

Run the prerequisite check before proceeding:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-spec
```

If the check fails, use the `/projspec:specify` command first to create the specification.

## Workflow

### Step 1: Check Prerequisites and Load Specification

Validate that spec.md exists and load its content for analysis.

#### 1.1: Run Prerequisite Check

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-spec --json
```

Parse the JSON output to extract:
- `FEATURE_DIR` - The path to the current feature directory
- `FEATURE_ID` - The unique identifier for the feature
- `SPEC_EXISTS` - Boolean indicating if spec.md is present

If `SPEC_EXISTS` is false, display an error message instructing the user to run `/projspec:specify` first, then stop execution.

#### 1.2: Load spec.md Content

Read the spec.md file from `${FEATURE_DIR}/spec.md` and store the full content for analysis in subsequent steps.

#### 1.3: Extract Feature Metadata

Parse the spec.md metadata section to extract:

| Field | Location | Purpose |
|-------|----------|---------|
| Feature Name | Heading or Metadata table | For display in questions |
| Branch | Metadata table | For reference |
| Status | Metadata table | To update after clarification |
| Date | Metadata table | To update with current date |

Store these values for use in updating the spec after clarification.

### Step 2: Scan for Existing NEEDS CLARIFICATION Markers

Search the spec.md content for existing `[NEEDS CLARIFICATION]` markers that were added during initial specification creation.

#### 2.1: Define Marker Pattern

The clarification marker pattern follows this format:
```
[NEEDS CLARIFICATION: Brief description of what's unclear]
```

**Regex pattern for detection:**
```
\[NEEDS CLARIFICATION:\s*([^\]]+)\]
```

#### 2.2: Scan Specification Content

Search the entire spec.md content for all occurrences of the clarification marker pattern.

For each match found, extract:

| Field | Description |
|-------|-------------|
| Location | Section name where the marker appears |
| Line Number | Approximate line number in the document |
| Description | The text after the colon describing what needs clarification |
| Context | 2-3 lines before and after the marker for context |

#### 2.3: Catalog Existing Markers

Create a structured list of all found markers:

```
existingMarkers = [
  {
    id: "M1",
    location: "Section Name",
    lineNumber: 42,
    description: "What size limit for uploads?",
    context: "...surrounding text...",
    relatedIds: ["FR-003", "EC-002"]  // Related spec item IDs if identifiable
  },
  ...
]
```

**Maximum existing markers:** The spec should have no more than 3 `[NEEDS CLARIFICATION]` markers. If more than 3 exist, note this as a spec quality issue.

#### 2.4: Map Markers to Open Questions

Cross-reference found markers with the Open Questions section of the spec:

1. Parse the Open Questions section for entries with format `Q-###`
2. For each existing marker, check if a corresponding question exists
3. If a marker lacks a corresponding question, flag it for question generation

```
markerQuestionMap = {
  "M1": {
    marker: {...},
    hasQuestion: true,
    questionId: "Q-001"
  },
  "M2": {
    marker: {...},
    hasQuestion: false,
    questionId: null  // Need to generate
  }
}
```

### Step 3: Analyze Spec for Additional Underspecified Areas

Beyond explicit markers, analyze the specification content to identify implicit ambiguities and underspecified areas that should be clarified.

#### 3.1: Define Ambiguity Detection Patterns

Scan the specification for these common ambiguity indicators:

**Vague Quantifiers:**
| Pattern | Example | Why Ambiguous |
|---------|---------|---------------|
| "several", "multiple", "many" | "supports multiple users" | No specific limit defined |
| "few", "some", "various" | "some configuration options" | Unclear scope |
| "large", "small", "significant" | "large file uploads" | No measurable threshold |

**Indefinite Timeframes:**
| Pattern | Example | Why Ambiguous |
|---------|---------|---------------|
| "quickly", "fast", "soon" | "responds quickly" | No performance target |
| "periodically", "regularly" | "regularly syncs data" | No frequency specified |
| "eventually", "later" | "eventually consistent" | No time bound |

**Unclear Conditions:**
| Pattern | Example | Why Ambiguous |
|---------|---------|---------------|
| "as needed", "when appropriate" | "validate as needed" | Trigger undefined |
| "if possible", "when available" | "cache if possible" | Fallback undefined |
| "typically", "usually", "normally" | "typically takes 5 seconds" | Deviation handling unclear |

**Missing Specifications:**
| Pattern | Example | Why Ambiguous |
|---------|---------|---------------|
| Entities without constraints | "User entity" with no field limits | Storage/validation unclear |
| Actions without error handling | "System saves file" | Failure behavior undefined |
| Features without scope limits | "Supports file uploads" | Size, type, count limits missing |

#### 3.2: Scan for Vague Language

Apply the ambiguity patterns to detect underspecified areas:

```
For each pattern category:
  Search spec content for matching patterns
  For each match:
    Extract context (section, surrounding text)
    Determine severity (High/Medium/Low)
    Identify affected spec items (FR-###, SC-###, etc.)
    Add to potentialClarifications list
```

**Severity Classification:**
- **High**: Affects core functionality or user-facing behavior
- **Medium**: Affects implementation details or edge cases
- **Low**: Affects documentation or nice-to-have features

#### 3.3: Check for Missing Essential Information

Analyze each major section for completeness:

**User Scenarios Section:**
- [ ] Each scenario has defined acceptance criteria
- [ ] User roles are clearly identified
- [ ] Benefits are specific and measurable
- [ ] Edge cases are addressed

**Requirements Section:**
- [ ] Each requirement has a verification method
- [ ] Requirements are atomic (single behavior)
- [ ] No "and" combining multiple requirements
- [ ] Constraints have specific values

**Key Entities Section:**
- [ ] Each entity has defined attributes
- [ ] Attribute constraints are specified (length, format, range)
- [ ] Relationships have cardinality defined
- [ ] Required vs optional fields are marked

**Success Criteria Section:**
- [ ] Each criterion has measurable targets
- [ ] Verification methods are defined
- [ ] Time bounds are specified where relevant

For each missing element found, add to `potentialClarifications`:

```
potentialClarifications.push({
  type: "missing_information",
  section: "Requirements",
  description: "FR-003 lacks verification method",
  severity: "Medium",
  affectedIds: ["FR-003"]
})
```

#### 3.4: Identify Assumption Dependencies

Scan the Assumptions section and cross-reference with requirements:

1. Read each assumption from the Assumptions table
2. Check if the assumption is marked as `Validated: No`
3. If unvalidated, determine if it blocks implementation
4. Add blocking assumptions to clarification candidates

```
For each unvalidated assumption:
  If assumption.impact == "High":
    potentialClarifications.push({
      type: "unvalidated_assumption",
      assumptionId: "A-001",
      description: assumption.description,
      impact: assumption.impactIfWrong,
      severity: "High"
    })
```

#### 3.5: Compile Clarification Candidates

Merge all sources into a unified candidate list:

```
allCandidates = [
  ...existingMarkers.map(m => ({...m, source: "explicit_marker"})),
  ...potentialClarifications.map(p => ({...p, source: "analysis"}))
]
```

Remove duplicates by comparing:
- Section location
- Affected spec item IDs
- Similar description text (fuzzy match)

Sort candidates by:
1. Severity (High first)
2. Source (explicit markers before analysis findings)
3. Affected spec item count (more affected items = higher priority)

### Step 4: Present Up to 5 Targeted Clarification Questions

Transform the prioritized clarification candidates into clear, actionable questions with suggested answers.

#### 4.1: Select Top 5 Candidates

From the sorted `allCandidates` list, select the top 5 candidates for clarification:

```
selectedCandidates = allCandidates.slice(0, 5)
```

**Selection criteria:**
1. Never exceed 5 questions per clarification session
2. Prioritize High severity candidates
3. Prefer explicit markers over analysis findings
4. Balance across different sections (avoid 5 questions from same section)

If fewer than 5 candidates exist, use all available candidates.

#### 4.2: Generate Question Format

For each selected candidate, generate a structured question:

**Question Structure:**
```markdown
### Question {N}: {Short Title}

**Context**: {Section or spec item where the ambiguity exists}

**Issue**: {Clear description of what is underspecified}

**Question**: {Specific, answerable question}

**Suggested Answer**: {Reasonable default or recommended value}

**Why This Matters**: {Impact on implementation if not clarified}

**Affected Items**: {List of FR-###, SC-###, US-### affected}
```

#### 4.3: Generate Suggested Answers

For each question, provide a reasonable default answer based on:

**Common Defaults by Type:**

| Ambiguity Type | Suggested Default | Rationale |
|----------------|-------------------|-----------|
| File size limit | 10MB | Standard web upload limit |
| Text field length | 255 characters | Common database field size |
| List/array limit | 100 items | Reasonable for most UIs |
| Timeout duration | 30 seconds | Typical API timeout |
| Retry attempts | 3 retries | Standard retry pattern |
| Session duration | 24 hours | Common session length |
| Password length | 8-128 characters | Security best practice |
| Batch size | 50 items | Performance/UX balance |

**Domain-Specific Suggestions:**
- Analyze similar requirements in the same spec for patterns
- Use industry standards when applicable
- Prefer conservative (stricter) limits for security-related items
- Prefer generous limits for user-facing features

#### 4.4: Present Questions to User

Display all questions in a clear, interactive format:

```markdown
## Clarification Questions for {Feature Name}

The following areas in your specification need clarification. Please provide answers
to help complete the specification.

---

### Question 1: Maximum Upload Size

**Context**: FR-003 (File Upload Requirement)

**Issue**: The requirement mentions "file uploads" but doesn't specify size limits.

**Question**: What is the maximum file size allowed for uploads?

**Suggested Answer**: 10MB (standard web upload limit)

**Why This Matters**: Affects storage architecture, upload timeout configuration,
and user experience for large file handling.

**Affected Items**: FR-003, EC-002, SC-001

---

### Question 2: {Next Question}
...

---

## How to Respond

For each question, you can:
1. **Accept the suggested answer**: Just reply "Accept Q1" or "Accept all"
2. **Provide a custom answer**: Reply with "Q1: Your custom answer here"
3. **Skip a question**: Reply "Skip Q1" (it will remain marked for later)
4. **Add context**: Include any additional context after your answer

Example response:
```
Q1: 25MB (we need to support video uploads)
Q2: Accept suggested
Q3: 500 characters, must support unicode
Skip Q4
Q5: Accept suggested
```
```

#### 4.5: Parse User Responses

After presenting questions, wait for user input and parse their responses:

**Response Patterns:**

| User Input | Interpretation |
|------------|----------------|
| "Accept Q1" | Use suggested answer for question 1 |
| "Accept all" | Use suggested answers for all questions |
| "Q1: custom value" | Use custom value for question 1 |
| "Skip Q1" | Leave question 1 unresolved |
| "1. custom value" | Alternative format for question 1 |

**Parsing Logic:**
```
For each line in user response:
  If matches "Accept Q{N}" or "Accept #{N}":
    answers[N] = suggestedAnswers[N]
    answers[N].source = "suggested"

  If matches "Accept all":
    For each question:
      answers[N] = suggestedAnswers[N]
      answers[N].source = "suggested"

  If matches "Q{N}: {value}" or "{N}. {value}" or "{N}: {value}":
    answers[N] = parseValue(value)
    answers[N].source = "user_provided"

  If matches "Skip Q{N}" or "Skip #{N}":
    answers[N] = null
    answers[N].status = "skipped"
```

#### 4.6: Validate User Answers

Perform basic validation on user-provided answers:

**Validation Checks:**
- Not empty (unless skipped)
- Reasonable length (not excessively long)
- Contains expected data type (number for limits, text for descriptions)
- No conflicting values with other answers

If validation fails, prompt user to clarify:
```
The answer for Q3 appears incomplete. You provided: "{partial answer}"
Could you please provide a more specific value?
For example: "Q3: 500 characters maximum"
```

### Step 5: Integrate Answers Back into Specification

Update the spec.md document with the clarification answers, removing resolved markers and updating the Open Questions section.

#### 5.1: Prepare Spec Updates

For each answered question, determine the necessary spec modifications:

**Update Types:**

| Answer Type | Update Action |
|-------------|---------------|
| Quantifier clarification | Add specific value to requirement text |
| Constraint definition | Add to entity attributes table or constraints section |
| Behavior specification | Expand requirement description or add edge case |
| Missing information | Add new content to appropriate section |

**Update Structure:**
```
specUpdates = [
  {
    questionId: "Q1",
    answer: "25MB",
    updateLocations: [
      {
        section: "Requirements",
        subsection: "FR-003",
        action: "replace",
        oldText: "[NEEDS CLARIFICATION: file size limit]",
        newText: "Maximum file size: 25MB"
      },
      {
        section: "Edge Cases",
        action: "add_row",
        content: "| File exceeds 25MB | Display error and reject upload |"
      }
    ]
  },
  ...
]
```

#### 5.2: Remove Resolved NEEDS CLARIFICATION Markers

For each answered question that had an explicit marker:

1. Locate the original `[NEEDS CLARIFICATION: ...]` marker
2. Replace it with the clarified content
3. Ensure surrounding text remains grammatically correct

**Replacement Strategy:**

If the marker was inline:
```
Before: "The system supports [NEEDS CLARIFICATION: how many?] concurrent users."
After:  "The system supports up to 100 concurrent users."
```

If the marker was standalone:
```
Before: "[NEEDS CLARIFICATION: What file types are allowed?]"
After:  "Allowed file types: .pdf, .doc, .docx, .txt, .csv"
```

#### 5.3: Update Open Questions Section

Modify the Open Questions section based on resolution status:

**For Resolved Questions:**
```markdown
Before:
| Q-001 | What is the max file size? | TBD | [NEEDS CLARIFICATION] |

After:
| Q-001 | What is the max file size? | User | Resolved: 25MB |
```

**For Skipped Questions:**
```markdown
| Q-001 | What is the max file size? | TBD | [NEEDS CLARIFICATION] |
(No change - remains open)
```

**For New Questions Generated During Analysis:**
If a question was generated from analysis (not an existing marker), add it to Open Questions:
```markdown
| Q-003 | How long should sessions last? | User | Resolved: 24 hours |
```

#### 5.4: Update Affected Spec Sections

Apply updates to each affected section based on the update plan from 5.1:

**Requirements Section Updates:**
- Add specific values to requirement descriptions
- Update verification methods if needed
- Add constraints to requirements that lacked them

**Edge Cases Section Updates:**
- Add new edge case rows for boundary conditions
- Update expected behaviors based on clarifications

**Key Entities Section Updates:**
- Add attribute constraints (length, format, range)
- Update relationship cardinalities
- Add validation rules based on answers

**Success Criteria Section Updates:**
- Add specific numeric targets
- Update measurement methods
- Add time bounds where clarified

**Assumptions Section Updates:**
- Mark validated assumptions as `Validated: Yes`
- Add new assumptions discovered during clarification

#### 5.5: Update Spec Metadata

Update the specification metadata to reflect the clarification:

```markdown
| Field | Value |
|-------|-------|
| Branch | `{unchanged}` |
| Date | {current date in YYYY-MM-DD format} |
| Status | {update if appropriate} |
| Input | {unchanged} |
```

**Status Update Rules:**
- If all clarifications resolved and no markers remain: Status can be "Ready for Review"
- If some clarifications remain: Status stays "Draft"
- If new clarifications added: Status stays "Draft"

#### 5.6: Add Revision History Entry

Append a new entry to the Revision History table:

```markdown
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| {previous entries...} |
| {increment version} | {current date} | Claude (projspec/clarify) | Resolved {N} clarification questions: {brief summary} |
```

**Version Increment Rules:**
- If all clarifications resolved: increment minor version (0.1 -> 0.2)
- If partial clarifications: increment patch version (0.1 -> 0.1.1)

#### 5.7: Write Updated Specification

Write the modified spec.md back to the feature directory:

```bash
# Write updated spec.md
echo "${updatedSpecContent}" > "${FEATURE_DIR}/spec.md"
```

**Pre-write Validation:**
1. Verify no duplicate sections were created
2. Verify table formatting is preserved
3. Verify all `[NEEDS CLARIFICATION]` markers for answered questions are removed
4. Verify new content is properly indented and formatted

#### 5.8: Generate Clarification Summary

Create a summary of all changes made during the clarification session:

```markdown
## Clarification Session Summary

**Feature**: {Feature Name}
**Date**: {Current Date}
**Questions Presented**: {N}

### Resolved Questions

| Question | Answer | Source | Affected Items |
|----------|--------|--------|----------------|
| Q1: Max file size | 25MB | User provided | FR-003, EC-002 |
| Q2: Session timeout | 24 hours | Suggested (accepted) | FR-007, SC-002 |
| Q3: Field length | 500 characters | User provided | FR-004 |

### Skipped Questions

| Question | Reason | Status |
|----------|--------|--------|
| Q4: Retry behavior | User skipped | Remains open |

### Spec Updates Applied

| Section | Update Type | Description |
|---------|-------------|-------------|
| Requirements | Modified | Updated FR-003 with 25MB limit |
| Edge Cases | Added | Added file size exceeded case |
| Key Entities | Modified | Added maxLength to description field |
| Open Questions | Updated | Marked Q1-Q3 as resolved |
| Revision History | Added | Version 0.2 entry |

### Remaining Clarifications

{If any questions remain open or new ones were discovered}

- Q-004: What retry behavior for failed uploads? [NEEDS CLARIFICATION]
- A-002: Assumption about network availability needs validation

### Next Steps

{Based on remaining work}

**If all clarifications resolved:**
The specification is now complete. Recommended next step:
  /projspec:plan

**If clarifications remain:**
Run `/projspec:clarify` again to address remaining questions, or proceed
with `/projspec:plan` using the suggested defaults for unresolved items.
```

### Step 6: Report Completion Status

Provide a final status report to the user and recommend next actions.

#### 6.1: Calculate Clarification Metrics

Compute summary statistics:

```
metrics = {
  questionsPresented: selectedCandidates.length,
  questionsResolved: answers.filter(a => a.status != "skipped").length,
  questionsSkipped: answers.filter(a => a.status == "skipped").length,
  suggestedAccepted: answers.filter(a => a.source == "suggested").length,
  customProvided: answers.filter(a => a.source == "user_provided").length,
  markersRemoved: resolvedMarkers.length,
  markersRemaining: remainingMarkers.length,
  sectionsUpdated: uniqueUpdatedSections.length
}
```

#### 6.2: Determine Spec Completeness

Assess whether the specification is now complete:

**Completeness Criteria:**
- [ ] No `[NEEDS CLARIFICATION]` markers remain
- [ ] All Open Questions are marked as Resolved
- [ ] All High-priority ambiguities have been addressed
- [ ] Unvalidated blocking assumptions have been resolved

**Completeness Status:**
```
If all criteria met:
  completeness = "COMPLETE"
  recommendation = "Run /projspec:plan to generate implementation plan"

If markers remain but < 3:
  completeness = "MOSTLY_COMPLETE"
  recommendation = "Proceed to /projspec:plan or run /projspec:clarify again"

If markers >= 3 or blocking issues exist:
  completeness = "INCOMPLETE"
  recommendation = "Run /projspec:clarify again to resolve remaining issues"
```

#### 6.3: Display Final Report

Present the completion report to the user:

```markdown
-------------------------------------------------------------------
                    CLARIFICATION COMPLETE
-------------------------------------------------------------------

Feature: {Feature Name}
Spec Location: {FEATURE_DIR}/spec.md

Summary:
  - Questions Presented: {N}
  - Questions Resolved: {N}
  - Questions Skipped: {N}
  - Sections Updated: {N}

Resolution Details:
  - Accepted Suggestions: {N}
  - Custom Answers: {N}
  - Markers Removed: {N}
  - Markers Remaining: {N}

Specification Status: {COMPLETE | MOSTLY_COMPLETE | INCOMPLETE}

-------------------------------------------------------------------

{If COMPLETE:}
Your specification is now complete and ready for planning.

Recommended next step:
  /projspec:plan

{If MOSTLY_COMPLETE:}
Your specification has {N} remaining clarification items.
You can proceed with planning (defaults will be used) or clarify further.

Options:
  /projspec:plan      - Proceed with implementation planning
  /projspec:clarify   - Resolve remaining questions

{If INCOMPLETE:}
Your specification still has {N} unresolved clarification items.
It's recommended to resolve these before proceeding.

Recommended next step:
  /projspec:clarify

-------------------------------------------------------------------
```

## Output

Upon successful completion, this command:

1. **Scans** the existing spec.md for `[NEEDS CLARIFICATION]` markers
2. **Analyzes** the specification for additional underspecified areas
3. **Presents** up to 5 targeted clarification questions with suggested answers
4. **Integrates** user answers back into the spec.md document
5. **Updates** the Open Questions section and Revision History
6. **Reports** clarification status and recommends next steps

The spec.md file is updated in place with all clarifications resolved.

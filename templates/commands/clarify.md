# Command: clarify

## Purpose

Identify underspecified areas in the current feature specification by asking targeted clarification questions (maximum of 5) and encoding the answers directly back into the spec.md document. This command refines an existing specification to make requirements more concrete and actionable.

The clarification process:
1. Analyzes the existing spec.md for ambiguities, gaps, and underspecified requirements
2. Formulates up to 5 highly targeted questions to resolve these issues
3. Incorporates user answers directly into the specification
4. Produces an updated spec.md with clarified, implementation-ready requirements

---

## Prerequisites

Before running this command, verify the following:

1. **Existing spec.md**: The feature must have a spec.md file already created (via the `specify` command or manually)
2. **Feature in spec phase**: The feature should be in the specification phase (status: Draft or Review)
3. **Feature directory exists**: The feature's specification directory must exist (e.g., `specs/{ID}-{feature-slug}/` or `.specify/features/{ID}-{feature-slug}/`)
4. **Working in feature context**: You should be in the feature's worktree or have the feature context loaded

If prerequisites are not met, inform the user:
- If no spec.md exists, suggest running the `specify` command first
- If the feature is already in implementation phase, warn that changes may impact ongoing work

---

## Workflow

Follow these steps in order:

### Step 1: Locate and Read the Specification

Find and read the spec.md for the current feature:

1. Check the current directory for spec.md
2. Check `specs/{feature-slug}/spec.md`
3. Check `.specify/features/{feature-slug}/spec.md`

Read the entire specification document carefully, paying attention to:
- User stories and their acceptance criteria
- Functional and non-functional requirements
- Assumptions that may need validation
- Open questions already documented
- Success criteria and their measurability

### Step 2: Analyze for Ambiguities

Systematically review the specification for common issues:

#### Scope Ambiguities
- Unclear boundaries between what's included and excluded
- User stories that could be interpreted multiple ways
- Features mentioned without clear definition of extent

#### Requirement Gaps
- Missing error handling scenarios
- Undefined edge cases in acceptance criteria
- Vague or unmeasurable success criteria
- Incomplete Given/When/Then statements

#### Technical Uncertainties
- Unspecified data formats or schemas
- Missing performance expectations
- Unclear integration points
- Undefined validation rules or constraints

#### User Experience Gaps
- Missing user roles or personas
- Unclear user flows or interactions
- Undefined feedback or notification requirements

#### Dependency Issues
- Assumed capabilities not documented
- External integrations without specifications
- Prerequisites that need validation

### Step 3: Formulate Clarification Questions

Based on your analysis, create **a maximum of 5 targeted questions**. These questions should:

**Question Criteria**:
- Be **specific** and answerable (avoid open-ended questions)
- Address issues that **block implementation** or create ambiguity
- Be **prioritized** by impact on the specification quality
- Have **clear options** when appropriate to guide the user
- Be **independent** - each question should stand alone

**Question Prioritization** (ask in this order):
1. Questions about core functionality scope
2. Questions about critical edge cases or error handling
3. Questions about user roles or permissions
4. Questions about technical constraints or requirements
5. Questions about integration or dependencies

**Question Format**:
```
I've reviewed the specification and identified some areas that need clarification:

1. **[Topic Area]**: [Specific question]
   - Option A: [First possibility]
   - Option B: [Second possibility]
   - Other: [Let user specify]

2. **[Topic Area]**: [Specific question with context]

3. **[Topic Area]**: [Question referencing specific part of spec]
   > Currently the spec says: "[quote from spec]"
   > This could mean: [interpretation A] or [interpretation B]. Which is intended?

[Continue up to 5 questions maximum]

Please answer these questions so I can update the specification.
```

**Important**: If the specification is already comprehensive and clear, inform the user:
```
I've reviewed the specification and it appears comprehensive. No clarification questions are needed at this time.

If you have concerns about specific areas, please point them out and I'll review them in more detail.
```

### Step 4: Collect and Process Answers

Wait for the user to respond to all questions. For each answer:

1. **Acknowledge** the answer to confirm understanding
2. **Identify** which section(s) of spec.md need updating
3. **Plan** the specific changes to incorporate the answer

If the user provides partial answers or skips questions:
- Proceed with the answers provided
- Note skipped questions in the "Open Questions" section of the spec

### Step 5: Update the Specification

Modify the spec.md to incorporate all clarifications:

#### For Scope Clarifications
- Update the Overview section if the feature scope changed
- Add items to "Out of Scope" section for explicitly excluded functionality
- Modify user stories to reflect refined scope

#### For Requirement Clarifications
- Add or update acceptance criteria with specific conditions
- Add new test scenarios for clarified edge cases
- Update FR/NFR requirements with concrete specifications
- Make success criteria more measurable

#### For Technical Clarifications
- Add specific constraints to requirements (e.g., "must complete in < 2 seconds")
- Document data formats, validation rules, or schemas
- Add integration specifications to Dependencies section

#### For User Experience Clarifications
- Add or clarify user roles in user stories
- Update acceptance criteria with specific user feedback requirements
- Document notification or messaging requirements

#### Updating Best Practices
- **Preserve** all existing content that doesn't need modification
- **Add** new information inline where it belongs contextually
- **Remove** items from "Open Questions" when they are resolved
- **Add** new questions to "Open Questions" if answers reveal new uncertainties
- **Update** the spec status if appropriate (e.g., Draft -> Review if significantly refined)

### Step 6: Present the Changes

After updating the specification:

1. **Summarize** the changes made:
```
I've updated the specification with your clarifications:

### Changes Made:
1. **[Section]**: [Brief description of change]
2. **[Section]**: [Brief description of change]
...

### Open Questions Resolved:
- [Question that was answered and removed from Open Questions]

### Remaining Open Questions:
- [Questions still pending, if any]
```

2. **Show** the updated sections (not the entire spec unless requested)
3. **Suggest** next steps:
   - Additional clarification if issues remain
   - Proceed to planning phase if specification is complete
   - Mark as "Review" if ready for stakeholder review

---

## Output

Upon successful completion, the following will be modified:

### Files Modified
- `spec.md` - Updated with clarified requirements and resolved ambiguities

### Specification Updates
The updated spec.md will include:
- Clarified user stories with refined scope
- More specific acceptance criteria
- Resolved ambiguities in requirements
- Concrete technical constraints where previously vague
- Updated Open Questions (resolved items removed, new items added if discovered)

### Feature State
- Phase: Remains in `spec` phase
- Status: May be updated to "Review" if significantly refined
- Ready for: Further clarification, planning phase, or stakeholder review

---

## Examples

### Example 1: Vague Acceptance Criteria

**Original Spec Content**:
```markdown
#### Acceptance Criteria
- [ ] Given a user submits the form, when processing completes, then the user receives feedback
```

**Clarification Question**:
```
1. **User Feedback**: The spec mentions users receive "feedback" after form submission. What specific feedback should be shown?
   - Option A: A simple success/error message banner
   - Option B: A detailed result summary with next steps
   - Option C: Email notification with confirmation details
   - Other: Please specify
```

**User Answer**: "Option B - show a summary of what was submitted and clear next action buttons"

**Updated Spec Content**:
```markdown
#### Acceptance Criteria
- [ ] Given a user submits the form, when processing completes successfully, then the user sees a summary panel displaying: submitted field values, submission timestamp, and "Continue" / "Submit Another" action buttons
- [ ] Given a user submits the form, when processing fails, then the user sees an error banner with the specific failure reason and a "Retry" button
```

### Example 2: Missing Edge Case

**Original Spec Content**:
```markdown
### Functional Requirements
- **FR-003**: System shall validate user input before processing
```

**Clarification Question**:
```
2. **Input Validation**: FR-003 mentions input validation but doesn't specify what happens when validation fails. What behavior is expected?
   - Should invalid fields be highlighted individually?
   - Should all errors be shown at once or one at a time?
   - Should the form prevent submission until all fields are valid?
```

**User Answer**: "Highlight all invalid fields with red borders, show error messages below each field, and disable the submit button until all validations pass"

**Updated Spec Content**:
```markdown
### Functional Requirements
- **FR-003**: System shall validate user input before processing
  - Invalid fields shall be highlighted with a red border
  - Each invalid field shall display an error message directly below the field
  - The submit button shall be disabled until all validation errors are resolved
  - Validation shall occur on field blur and on form submission attempt
```

### Example 3: No Clarification Needed

**Scenario**: The specification is comprehensive with clear acceptance criteria, defined edge cases, and measurable success criteria.

**Response**:
```
I've reviewed the specification and it appears comprehensive. The user stories have clear acceptance criteria, edge cases are documented, and success criteria are measurable.

No clarification questions are needed at this time. You can proceed to:
- Run `/plan` to generate the implementation plan
- Share with stakeholders for review
- Mark the status as "Review" if ready for formal approval
```

---

## Error Handling

### Common Issues

1. **No spec.md found**: Guide user to run `specify` command first or locate the correct feature directory
2. **Specification is empty or minimal**: Suggest completing the specification first rather than clarifying
3. **Feature already in implementation**: Warn that spec changes may impact ongoing work, ask for confirmation
4. **User skips questions**: Proceed with answered questions, note unanswered in Open Questions

### Recovery Steps

If the command fails partway through:
1. Inform user which updates were successfully applied
2. List remaining clarifications that need to be incorporated
3. Offer to continue from where the process stopped
4. Keep a backup of the original spec if making extensive changes

---

## Notes

- **Maximum 5 questions**: Keep clarification sessions focused. If more issues exist, prioritize and schedule follow-up sessions
- **Specific over open-ended**: Questions like "What else should we consider?" are not effective. Ask "Should the system support X?" instead
- **Reference the spec**: Quote specific passages when asking about ambiguities so the user has context
- **Incorporate immediately**: Answers should be directly woven into the spec, not added as separate notes
- **Preserve structure**: Maintain the spec template structure when adding clarifications
- **Iterative process**: Multiple clarification sessions may be needed for complex features - this is normal
- **Track changes**: If significant, note in the spec that clarifications were made (e.g., add a changelog or update the date)

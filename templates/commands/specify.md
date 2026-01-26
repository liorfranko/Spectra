# Command: specify

## Purpose

Create a comprehensive feature specification from a natural language feature description. This command guides you through transforming a user's feature idea into a structured, actionable specification document (spec.md) that serves as the foundation for planning and implementation.

The specification process:
1. Sets up the feature infrastructure (branch, worktree, directories)
2. Clarifies ambiguous requirements through targeted questions
3. Produces a complete spec.md with user stories, acceptance criteria, and requirements

---

## Prerequisites

Before running this command, verify the following:

1. **Initialized ProjSpec project**: The current directory must be a ProjSpec-enabled project (check for `.projspec/` or `.specify/` directory)
2. **Git repository**: The project must be a git repository with a clean working state
3. **Base branch exists**: The base branch (typically `main` or `master`) must exist and be up to date
4. **Feature description provided**: The user must provide a description of the feature they want to specify

If prerequisites are not met, inform the user and guide them to resolve the issue before proceeding.

---

## Workflow

Follow these steps in order:

### Step 1: Capture Feature Description

Read the user's feature description carefully. The description may be:
- A brief one-liner (e.g., "add user authentication")
- A detailed paragraph with requirements
- A bulleted list of capabilities

Store the original description for reference.

### Step 2: Create Feature Infrastructure

Run the `create-new-feature.sh` script to set up the feature environment:

```bash
./scripts/create-new-feature.sh "<feature-name>"
```

The script will:
- Generate a unique feature ID (e.g., `042`)
- Create a feature branch with naming convention: `{ID}-{feature-slug}`
- Set up a git worktree for isolated development
- Create the specification directory structure
- Initialize template files

**Note**: If the script is not available or fails, manually create:
- A new branch: `{ID}-{feature-slug}` from the base branch
- A spec directory: `specs/{ID}-{feature-slug}/` or `.specify/features/{ID}-{feature-slug}/`
- Copy the spec-template.md to the feature directory as `spec.md`

### Step 3: Ask Clarifying Questions (If Needed)

If the feature description is ambiguous, incomplete, or could be interpreted multiple ways, ask clarifying questions **before** writing the specification.

**Question Guidelines**:
- Ask a **maximum of 3 questions** per specification session
- Only ask if the answer significantly impacts the specification
- Prioritize questions about:
  - Core functionality scope (what's included vs. excluded)
  - User roles and permissions
  - Critical edge cases or error handling
  - Integration points with existing features

**Question Format**:
```
Before I create the specification, I have a few clarifying questions:

1. [Most critical question about scope or functionality]
2. [Question about user roles or permissions if relevant]
3. [Question about edge cases or constraints if relevant]

Please answer these so I can create an accurate specification.
```

**Skip questions if**:
- The description is comprehensive and unambiguous
- The feature is straightforward with obvious scope
- The user has already provided detailed requirements

### Step 4: Create the Specification Document

Using the `spec-template.md` as a guide, create the `spec.md` file with all required sections:

#### Required Sections (Mandatory)

1. **Header**: Feature name, branch, date, status (set to "Draft")

2. **Overview**: 2-3 sentence summary explaining:
   - What problem is being solved
   - What value the feature provides
   - Who benefits from this feature

3. **User Scenarios & Testing**: Define user stories with:
   - **User Story format**: As a [role], I want [capability], So that [benefit]
   - **Priority levels**: P1 (Must have), P2 (Should have), P3 (Nice to have)
   - **Acceptance Criteria**: Given/When/Then format, must be testable
   - **Test Scenarios**: Happy path, edge cases, error handling

4. **Requirements**:
   - **Functional Requirements (FR-XXX)**: Specific capabilities
   - **Non-Functional Requirements (NFR-XXX)**: Performance, security, usability

5. **Success Criteria**: Measurable outcomes that define completion

#### Optional Sections (Include If Relevant)

6. **Assumptions**: List assumptions that need validation
7. **Out of Scope**: Explicitly state what is NOT included
8. **Dependencies**: External dependencies or prerequisites
9. **Open Questions**: Unresolved questions for future discussion

### Step 5: Set Feature State

Update the feature state to indicate the specification phase:
- Set status in spec.md header to "Draft"
- Create or update a state file if the project uses one (e.g., `.state.json` or `meta.json`)
- The feature is now in the "spec" phase of the development lifecycle

### Step 6: Present the Specification

After creating the specification:
1. Display the full spec.md content to the user
2. Highlight any areas that may need refinement
3. List any open questions that were deferred
4. Suggest next steps (review, refinement, or proceed to planning)

---

## Output

Upon successful completion, the following will be created:

### Files Created
- `specs/{ID}-{feature-slug}/spec.md` - The feature specification document
- Feature branch: `{ID}-{feature-slug}`
- Git worktree (if enabled): `worktrees/{ID}-{feature-slug}/`

### Specification Contents
The spec.md will contain:
- Complete feature overview
- User stories with priorities (P1, P2, P3)
- Testable acceptance criteria in Given/When/Then format
- Functional and non-functional requirements
- Success criteria with measurable outcomes
- Documented assumptions and exclusions
- Open questions for future resolution

### Feature State
- Phase: `spec`
- Status: `Draft`
- Ready for: Review and refinement, then planning phase

---

## Examples

### Example 1: Simple Feature Request

**User Input**: "Add user authentication to the CLI"

**Clarifying Questions**:
1. Should authentication support multiple providers (e.g., OAuth, API keys) or just one method?
2. Should sessions persist across CLI invocations, or require re-authentication each time?
3. Are there specific security requirements (e.g., token expiration, MFA)?

### Example 2: Detailed Feature Request

**User Input**: "I need a feature to export project data. Users should be able to export to JSON and CSV formats. The export should include all project metadata, specifications, and task lists. It should work from the CLI with options to filter by date range and feature status."

**Action**: No clarifying questions needed - proceed directly to specification.

---

## Error Handling

### Common Issues

1. **Not a git repository**: Guide user to initialize git or navigate to correct directory
2. **Script not found**: Provide manual steps to create branch and directories
3. **Branch already exists**: Ask user if they want to continue with existing branch or choose new name
4. **No feature description**: Prompt user to provide a feature description before proceeding

### Recovery Steps

If the command fails partway through:
1. Check what was created (branch, directories, files)
2. Clean up partial artifacts if needed
3. Resume from the failed step rather than starting over

---

## Notes

- This command creates a **Draft** specification. The user should review and refine before marking as "Review" or "Approved"
- User stories should focus on **what** users need, not **how** it will be implemented
- Acceptance criteria must be specific enough to write tests against
- Keep the specification focused - use "Out of Scope" to defer related but separate features

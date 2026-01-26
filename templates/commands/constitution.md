# Command: constitution

## Purpose

Create or update the project constitution with interactive or provided principle inputs. The constitution defines core principles and values that guide all development decisions, ensuring consistency across features and team members.

The constitution process:
1. Checks if a constitution already exists in the project
2. If creating new: Gathers principles through interactive questions (3-7 principles recommended)
3. If updating: Reads existing constitution and asks what to modify
4. Creates or updates the constitution using the constitution-template.md
5. Ensures dependent templates remain aligned (plan template references constitution)

---

## Prerequisites

Before running this command, verify the following:

1. **Initialized Project**: The current directory must be a ProjSpec-enabled project (check for `.projspec/` or `.specify/` directory)
2. **Git repository**: The project should be a git repository for version tracking of constitution changes
3. **Write permissions**: You must have write access to `.specify/memory/` directory

If prerequisites are not met, inform the user:
- If no project is initialized, suggest running the initialization command first
- If `.specify/memory/` directory does not exist, offer to create it

---

## Workflow

Follow these steps in order:

### Step 1: Check for Existing Constitution

Look for an existing constitution in the following locations (in order):

1. `.specify/memory/constitution.md` (primary location)
2. `constitution.md` in project root (fallback location)
3. `.projspec/constitution.md` (legacy location)

**If constitution exists**:
- Inform the user: "An existing constitution was found at {path}"
- Read and display a summary (mission statement and principle names)
- Proceed to Step 3 (Update Mode)

**If no constitution exists**:
- Inform the user: "No existing constitution found. I'll help you create one."
- Proceed to Step 2 (Creation Mode)

### Step 2: Create New Constitution (Creation Mode)

Guide the user through creating a new constitution with interactive questions.

#### 2.1: Gather Project Context

Ask the user:
```
Before we define your project principles, I need some context:

1. **Project Name**: What is the name of this project?
2. **Mission Statement**: In 1-2 sentences, what is the core purpose of this project? What problem does it solve?
```

Wait for the user's response before continuing.

#### 2.2: Gather Core Principles

Ask the user to define 3-7 core principles. Present the question in a structured format:

```
Now let's define your core principles. These are fundamental values that guide all development decisions.

Good principles are:
- Actionable (can be applied to real decisions)
- Verifiable (you can tell if you're following them)
- Stable (rarely need to change)
- Prioritizable (you know which matters most when they conflict)

**Example Principles**:
- "Security First": Security considerations take precedence over convenience
- "User Experience Over Technical Elegance": When in conflict, favor user experience
- "Explicit Over Implicit": Prefer explicit configuration over magic behaviors
- "Test Everything": No feature ships without automated tests
- "Documentation as Code": Documentation is treated with the same rigor as code

Please provide your core principles (3-7 recommended). For each principle, include:
1. **Name**: A short, memorable name
2. **Statement**: What this principle means (1-2 sentences)
3. **Rationale**: Why this principle matters for your project (1-2 sentences)

You can list them all at once, or I can ask for one at a time. Which do you prefer?
```

**If user chooses one at a time**:
Ask for each principle individually:
```
Principle {N} of up to 7:
- **Name**:
- **Statement**:
- **Rationale**:

(Enter "done" when you've added enough principles, or provide the next one)
```

Continue until the user indicates they are done or reaches 7 principles.

**If fewer than 3 principles**:
Warn the user:
```
You've provided only {N} principle(s). While this is acceptable, having 3-7 principles is recommended for comprehensive guidance. Would you like to add more, or proceed with what you have?
```

#### 2.3: Define Priority Order

Once principles are collected, ask about priority:

```
When principles conflict, which order should they be prioritized? Please rank your principles from highest to lowest priority:

Your principles:
{List of principle names}

Provide the ranking (e.g., "1, 3, 2, 4" or list them in order):
```

#### 2.4: Gather Technical Standards (Optional)

Ask about technical standards:

```
Would you like to define technical standards? These are non-negotiable requirements for:
- Code Quality (e.g., linting, formatting rules)
- Testing Requirements (e.g., coverage thresholds)
- Security Requirements (e.g., no secrets in code)
- Performance Requirements (e.g., response time limits)

Options:
1. Yes, let's define standards now
2. Skip for now (can be added later)
3. Use sensible defaults

Which would you prefer?
```

**If user chooses to define standards**:
Ask follow-up questions for each category they want to define.

**If user chooses defaults**:
Use reasonable defaults like:
- All code must pass linting before merge
- Unit test coverage must be at least 80%
- No secrets or credentials in source code
- Critical paths must respond within 2 seconds

#### 2.5: Gather Architectural Boundaries (Optional)

Ask about architectural commitments:

```
Would you like to define architectural boundaries? These clarify:
- What you WILL do architecturally (commitments)
- What you WON'T do architecturally (anti-commitments)

Examples:
- "We WILL use dependency injection for all services"
- "We WON'T use global state"
- "We WILL support offline-first design"
- "We WON'T add external dependencies without team review"

Options:
1. Yes, let's define boundaries now
2. Skip for now (can be added later)

Which would you prefer?
```

Proceed to Step 4 after gathering all inputs.

### Step 3: Update Existing Constitution (Update Mode)

If a constitution already exists, guide the user through updates.

#### 3.1: Display Current Constitution Summary

Present a summary of the existing constitution:

```
## Current Constitution Summary

**Project**: {PROJECT_NAME}
**Version**: {VERSION}
**Last Updated**: {DATE}

### Mission Statement
{MISSION_STATEMENT}

### Core Principles
1. {PRINCIPLE_1_NAME}: {BRIEF_STATEMENT}
2. {PRINCIPLE_2_NAME}: {BRIEF_STATEMENT}
...

### Priority Order
1. {HIGHEST_PRIORITY}
2. {SECOND_PRIORITY}
...

What would you like to modify?
```

#### 3.2: Determine Update Scope

Ask what the user wants to update:

```
What would you like to update?

1. **Mission Statement**: Change the project's core purpose
2. **Add Principle**: Add a new core principle
3. **Modify Principle**: Change an existing principle's statement, rationale, or examples
4. **Remove Principle**: Remove a core principle
5. **Reorder Priorities**: Change the priority order of principles
6. **Technical Standards**: Update code, testing, security, or performance standards
7. **Architectural Boundaries**: Update what you will/won't do architecturally
8. **Full Review**: Review and update the entire constitution

Which option? (Enter number or describe what you want to change)
```

#### 3.3: Execute the Update

Based on the user's choice:

**For Adding a Principle**:
- Ask for name, statement, rationale
- Ask where it falls in the priority order
- Ask for examples and anti-patterns

**For Modifying a Principle**:
- Show the current principle in full
- Ask what specifically to change
- Confirm the changes before applying

**For Removing a Principle**:
- Show the principle to be removed
- Warn about potential impact on existing plans/features
- Ask for confirmation

**For Reordering Priorities**:
- Show current order
- Ask for new order
- Confirm the changes

**For Full Review**:
- Go through each section, asking if changes are needed
- Only modify sections the user wants to change

### Step 4: Generate the Constitution Document

Using the `constitution-template.md`, create or update the constitution.

#### 4.1: Prepare the Document

Fill in the template with collected information:

```markdown
# Project Constitution: {PROJECT_NAME}

**Version**: {VERSION (1.0 for new, increment for updates)}
**Created**: {ORIGINAL_CREATION_DATE}
**Last Updated**: {TODAY'S_DATE}

---

## Mission Statement

{MISSION_STATEMENT}

---

## Core Principles

### 1. {PRINCIPLE_NAME}

**Statement**: {PRINCIPLE_STATEMENT}

**Rationale**: {WHY_THIS_MATTERS}

**Examples**:
- {EXAMPLE_1}
- {EXAMPLE_2}

**Anti-patterns**:
- {ANTI_PATTERN_1}
- {ANTI_PATTERN_2}

{... repeat for each principle ...}
```

#### 4.2: Generate Examples and Anti-patterns

For each principle, if the user did not provide examples, generate reasonable ones:

**For each principle**:
1. Based on the statement and rationale, suggest 2 examples of applying the principle
2. Suggest 2 anti-patterns that would violate the principle
3. Present to user for confirmation or modification

```
For the principle "{PRINCIPLE_NAME}":

**Suggested Examples**:
- {EXAMPLE_1}
- {EXAMPLE_2}

**Suggested Anti-patterns**:
- {ANTI_PATTERN_1}
- {ANTI_PATTERN_2}

Are these appropriate, or would you like to modify them?
```

#### 4.3: Add Decision Framework

Include the decision framework section:

```markdown
## Decision Framework

### Priority Order

When principles conflict, prioritize in this order:

1. {HIGHEST_PRIORITY_PRINCIPLE}
2. {SECOND_PRIORITY_PRINCIPLE}
3. {THIRD_PRIORITY_PRINCIPLE}
{... etc ...}

### Exception Process

When an exception to a principle is needed:

1. Document the specific principle being excepted
2. Explain why the exception is necessary
3. Define the scope and duration of the exception
4. Get approval from the appropriate stakeholder
5. Track in the relevant feature's plan.md
```

### Step 5: Write the Constitution File

Save the constitution to the designated location:

1. **Primary location**: `.specify/memory/constitution.md`
2. Create the `.specify/memory/` directory if it does not exist
3. If updating, create a backup of the previous version (optional, based on project preferences)

```bash
# Create directory if needed
mkdir -p .specify/memory

# Write the constitution
# (The file content is written by the AI)
```

### Step 6: Verify Dependent Template Alignment

Check that dependent templates reference the constitution correctly:

1. **Plan template**: Verify `templates/plan-template.md` includes the Constitution Check section
2. **Inform user** if any templates need updating:

```
The constitution has been created/updated. The following templates depend on it:

- plan-template.md: Includes Constitution Check section (already aligned)

No additional template updates are needed.
```

**If templates need updating**:
```
The constitution has been created/updated. The following templates may need alignment:

- {TEMPLATE_NAME}: {WHAT_NEEDS_UPDATING}

Would you like me to update these templates now?
```

### Step 7: Present the Result

After creating or updating the constitution:

1. **Display a summary** of what was created or changed:

```
## Constitution Created/Updated

**Location**: .specify/memory/constitution.md
**Version**: {VERSION}

### Summary:
- **Project**: {PROJECT_NAME}
- **Mission**: {MISSION_STATEMENT_PREVIEW}
- **Principles**: {N} core principles defined
- **Priority Order**: {FIRST_PRIORITY} > {SECOND_PRIORITY} > ...
- **Technical Standards**: {Defined/Not defined}
- **Architectural Boundaries**: {Defined/Not defined}

### What's Next:
1. Review the full constitution to ensure accuracy
2. Share with team members for alignment
3. Reference during planning with the `/plan` command
4. Update as the project evolves

The constitution is now active and will be checked during feature planning.
```

2. **Offer to display the full document** if the user wants to review it:

```
Would you like to see the full constitution document?
```

---

## Output

Upon successful completion, the following will be created or modified:

### Files Created/Modified

| File | Description |
|------|-------------|
| `.specify/memory/constitution.md` | The project constitution document |

### Constitution Contents

The constitution will contain:
- Project name and mission statement
- 3-7 core principles with statements, rationale, examples, and anti-patterns
- Technical standards (code quality, testing, security, performance)
- Architectural boundaries (what you will/won't do)
- Decision framework with priority order
- Exception process for handling principle violations
- Review process guidelines
- Revision history

### Feature State

- The project now has a constitution for guiding decisions
- The `/plan` command will verify alignment with these principles
- All future features should be developed in accordance with the constitution

---

## Examples

### Example 1: Creating a New Constitution

**User Input**: `/constitution`

**AI Response**:
```
No existing constitution found. I'll help you create one.

Before we define your project principles, I need some context:

1. **Project Name**: What is the name of this project?
2. **Mission Statement**: In 1-2 sentences, what is the core purpose of this project?
```

**User Response**: "The project is ProjSpec. Its mission is to provide a structured methodology for AI-assisted software development that ensures consistent, high-quality specifications and implementations."

**AI Response**:
```
Great! Now let's define your core principles...

[Continues with principle gathering]
```

### Example 2: Adding a New Principle

**User Input**: `/constitution` (constitution already exists)

**AI Response**:
```
An existing constitution was found at .specify/memory/constitution.md

## Current Constitution Summary

**Project**: ProjSpec
**Version**: 1.0

### Core Principles
1. Clarity Over Brevity: ...
2. Iterative Refinement: ...
3. Tool Agnosticism: ...

What would you like to modify?
```

**User Response**: "Add a new principle about documentation"

**AI Response**:
```
Let's add a new principle. Please provide:

1. **Name**: A short, memorable name (e.g., "Documentation First")
2. **Statement**: What this principle means
3. **Rationale**: Why this principle matters

Where should this principle fall in the priority order? (Currently: Clarity Over Brevity > Iterative Refinement > Tool Agnosticism)
```

### Example 3: Quick Constitution with Defaults

**User Input**: "Create a constitution quickly with sensible defaults"

**AI Response**:
```
I'll create a constitution with common defaults. I still need a few key inputs:

1. **Project Name**: What is this project called?
2. **Mission Statement**: What is the core purpose? (1-2 sentences)
3. **Primary Principle**: What is the single most important value for this project?

For everything else, I'll use sensible defaults that you can modify later.
```

---

## Error Handling

### Common Issues

1. **No project initialized**: Guide user to initialize ProjSpec first
2. **Cannot create directory**: Check permissions, suggest running with appropriate access
3. **Constitution exists but is malformed**: Offer to recreate from scratch or attempt repair
4. **User provides too few principles**: Warn but allow proceeding with minimum of 1
5. **Conflicting principles identified**: Ask user to clarify or prioritize

### Recovery Steps

If the command fails partway through:
1. Check what information was already gathered
2. Save partial inputs to a temporary file if possible
3. Offer to resume from where the process stopped
4. Keep backup of any existing constitution before modifying

### Validation Checks

Before finalizing the constitution:
- [ ] At least 1 core principle is defined (3-7 recommended)
- [ ] Mission statement is provided
- [ ] Project name is provided
- [ ] Priority order is defined for all principles
- [ ] No duplicate principle names exist

---

## Notes

- **Start with 3-5 principles**: Too many principles dilute focus and make compliance harder to verify
- **Be specific**: Vague principles like "Be good" are not actionable. "Security takes precedence over convenience" is actionable
- **Principles should conflict occasionally**: If they never conflict, they may not be specific enough
- **Review regularly**: Constitutions should evolve with the project, but changes should be deliberate
- **Share with the team**: A constitution only works if everyone knows and follows it
- **Reference during planning**: The `/plan` command will verify alignment with these principles
- **Document exceptions**: When you must violate a principle, document why in the feature's plan.md
- **Version carefully**: Increment version numbers for significant changes to track evolution
- **Keep mission statement stable**: The mission should rarely change; if it does, consider if you're building a new product

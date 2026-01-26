---
description: "Create or update project constitution with foundational principles and constraints"
user-invocable: true
argument-hint: principle to add or 'interactive' for guided creation
---

# Constitution Command

Interactively create or update the project constitution from user inputs. The constitution defines foundational principles and constraints that govern all development decisions, ensuring consistency across feature implementations.

## Arguments

The `$ARGUMENTS` variable contains optional input:
- `interactive` - Start an interactive guided creation/update flow
- `add "<principle>"` - Add a specific principle to the constitution
- `update` - Update existing constitution with new inputs
- (empty) - Display current constitution or start creation if none exists

## Overview

The project constitution serves as the foundational document that:
- Defines core principles guiding development decisions
- Establishes constraints and quality gates
- Documents the development workflow and governance
- Provides override rules for exceptional cases

Changes to the constitution affect all subsequent planning and implementation phases.

## Workflow

### Step 1: Check for Existing Constitution

**1.1: Search for constitution file**

Check for an existing constitution in the following locations (in priority order):

```bash
# Check project-specific location first
if [ -f ".projspec/memory/constitution.md" ]; then
    CONSTITUTION_PATH=".projspec/memory/constitution.md"
    CONSTITUTION_EXISTS=true
elif [ -f ".claude/memory/constitution.md" ]; then
    CONSTITUTION_PATH=".claude/memory/constitution.md"
    CONSTITUTION_EXISTS=true
else
    CONSTITUTION_EXISTS=false
fi
```

**1.2: If constitution exists, read and parse current content**

Parse the existing constitution to extract:
- Core Principles (numbered P-001, P-002, etc.)
- Constraints (technology, compliance, policy)
- Development Workflow requirements
- Quality Gates
- Governance rules
- Version history

Store the parsed content:
```
currentConstitution = {
  version: "1.0.0",
  effectiveDate: "YYYY-MM-DD",
  lastAmended: "YYYY-MM-DD",
  principles: [
    { id: "P-001", title: "...", description: "..." },
    ...
  ],
  constraints: {
    technology: [...],
    compliance: [...],
    policy: [...]
  },
  workflow: [...],
  qualityGates: [...],
  governance: {
    amendmentProcess: [...],
    overrideRules: [...],
    hierarchy: [...]
  }
}
```

**1.3: Determine operation mode based on arguments and state**

| Condition | Mode |
|-----------|------|
| No constitution + no arguments | Create new (interactive) |
| No constitution + `add "<principle>"` | Create new with initial principle |
| Existing constitution + no arguments | Display current constitution |
| Existing constitution + `interactive` | Update existing (interactive) |
| Existing constitution + `add "<principle>"` | Add principle to existing |
| Any + `update` | Update/amend existing |

### Step 2: Interactive Constitution Creation

When creating a new constitution or in interactive mode.

**2.1: Display introduction and gather project context**

```markdown
## Creating Project Constitution

The constitution defines the foundational principles and constraints for this project.
These principles guide all development decisions and are checked during planning.

### Step 1 of 5: Project Context

First, let's understand your project:

1. **Project Name**: What is this project called?
2. **Project Type**: What type of project is this?
   - CLI Tool
   - Web Application
   - API Service
   - Library/SDK
   - Plugin/Extension
   - Other (specify)
3. **Primary Language**: What is the primary programming language?
4. **Team Size**: Solo developer, small team (2-5), or larger team?
```

Wait for user response and store:
```
projectContext = {
  name: user_response.name,
  type: user_response.type,
  language: user_response.language,
  teamSize: user_response.teamSize
}
```

**2.2: Gather core principles**

```markdown
### Step 2 of 5: Core Principles

Core principles are the fundamental values that guide development decisions.

I'll suggest some common principles based on your project type. You can accept,
modify, or add your own.

**Suggested Principles for {projectContext.type}:**

1. **User-Centric Design** (Recommended)
   All features must prioritize user experience and accessibility.
   _Accept? (y/n/modify)_

2. **Maintainability First** (Recommended)
   Code should be written for humans to read and maintain.
   _Accept? (y/n/modify)_

3. **Incremental Delivery** (Recommended)
   Deliver working software in small, testable increments.
   _Accept? (y/n/modify)_

4. **Documentation as Code** (Recommended)
   Documentation is a first-class deliverable.
   _Accept? (y/n/modify)_

5. **Test-Driven Confidence** (Recommended)
   New functionality requires accompanying tests.
   _Accept? (y/n/modify)_

Would you like to:
- Accept all suggested principles? (type 'accept all')
- Review each individually? (type 'review')
- Add custom principles? (type 'custom')
- Skip to constraints? (type 'skip')
```

Process user responses:
- For 'accept all': Add all suggested principles
- For 'review': Ask about each principle individually
- For 'custom': Prompt for custom principle input
- For 'modify': Allow user to edit principle text

**2.3: Gather constraints**

```markdown
### Step 3 of 5: Constraints

Constraints define the boundaries within which development must occur.

**Technology Constraints:**
What technology requirements or limitations apply?
- Runtime requirements (e.g., "Node.js 18+", "Python 3.10+")
- Dependency policies (e.g., "Minimize external dependencies", "Only MIT-licensed packages")
- Compatibility requirements (e.g., "Must support macOS and Linux")

Please list your technology constraints (one per line, or 'none'):

**Compliance Constraints:**
What security, privacy, or regulatory requirements apply?
- Security requirements (e.g., "No hardcoded credentials", "Input validation required")
- Privacy requirements (e.g., "GDPR compliant", "No PII logging")
- Licensing requirements (e.g., "GPL-compatible only")

Please list your compliance constraints (one per line, or 'none'):

**Policy Constraints:**
What team or organizational policies apply?
- Code review requirements
- Breaking change policies
- Performance requirements

Please list your policy constraints (one per line, or 'none'):
```

Store the constraints:
```
constraints = {
  technology: [...user provided constraints...],
  compliance: [...user provided constraints...],
  policy: [...user provided constraints...]
}
```

**2.4: Define quality gates**

```markdown
### Step 4 of 5: Quality Gates

Quality gates are checkpoints that must pass before code is merged.

**Suggested Quality Gates for {projectContext.type}:**

1. [ ] Lint checks pass
2. [ ] Unit tests pass
3. [ ] Integration tests pass
4. [ ] Documentation updated
5. [ ] Constitution compliance verified

Would you like to:
- Accept these gates? (type 'accept')
- Add custom gates? (type 'add')
- Modify gates? (type 'modify')
```

**2.5: Define governance rules**

```markdown
### Step 5 of 5: Governance

Governance defines how the constitution can be changed and how exceptions are handled.

**Amendment Process:**
How should constitution changes be proposed and approved?

Options:
1. **Solo Developer**: Author can amend freely with documentation
2. **Team Review**: Amendments require team discussion (48-hour review period)
3. **Formal Process**: Proposals require written rationale and approval vote

Select your amendment process (1/2/3):

**Override Rules:**
How should constitution violations be handled?

Default rules:
- Violations require explicit justification in the plan
- Emergency overrides must be documented and reviewed post-implementation
- No override is permanent; violations must be remediated or constitution amended

Accept default override rules? (y/n/modify)

**Principle Hierarchy:**
When principles conflict, which takes precedence?

Default hierarchy:
1. Security and compliance constraints take precedence
2. User-centric design overrides technical preferences
3. Maintainability overrides performance unless SLA-bound

Accept default hierarchy? (y/n/modify)
```

### Step 3: Generate Constitution Document

**3.1: Compile all inputs into the constitution structure**

```markdown
# Project Constitution

> Foundational principles and constraints governing all development decisions.

**Version:** 1.0.0
**Effective Date:** {TODAY in YYYY-MM-DD format}
**Last Amended:** {TODAY in YYYY-MM-DD format}

---

## Core Principles

{For each principle in principles:}
### {Roman numeral}. {Principle Title}

{Principle description}

{End for}

---

## Constraints

### Technology Constraints

{For each constraint in constraints.technology:}
- **{Category}:** {Constraint description}
{End for}

### Compliance Constraints

{For each constraint in constraints.compliance:}
- **{Category}:** {Constraint description}
{End for}

### Policy Constraints

{For each constraint in constraints.policy:}
- **{Category}:** {Constraint description}
{End for}

---

## Development Workflow

### Required Processes

1. **Specification:** Features must be specified before implementation
2. **Planning:** Implementation plans must be reviewed for constitution compliance
3. **Review:** Code changes require approval from designated reviewers
4. **Testing:** Automated tests must pass before merge
5. **Documentation:** User-facing changes require documentation updates

### Quality Gates

{For each gate in qualityGates:}
- [ ] {Gate description}
{End for}

---

## Governance

### Amendment Process

{Amendment process description based on user selection}

### Override Rules

{Override rules description}

### Principle Hierarchy

In case of conflict between principles:
{For each hierarchy rule:}
{Index}. {Rule description}
{End for}

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | {TODAY} | Initial constitution established | {User or "Claude (projspec)"} |

---

*This constitution is checked during `/projspec.plan` execution. Violations must be justified in the Complexity Tracking section of the plan.*
```

**3.2: Write the constitution file**

Determine the output location:
```bash
# Create .projspec/memory directory if it doesn't exist
mkdir -p ".projspec/memory"

# Write constitution
CONSTITUTION_PATH=".projspec/memory/constitution.md"
```

Write the compiled constitution to the file.

### Step 4: Add Principle (Non-Interactive Mode)

When `$ARGUMENTS` contains `add "<principle>"`.

**4.1: Parse the principle from arguments**

Extract the principle text from the add command:
```
principle_text = extract text between quotes from $ARGUMENTS
```

**4.2: Determine principle number**

If constitution exists:
```
next_principle_number = max(existing principle numbers) + 1
```

If new constitution:
```
next_principle_number = 1
```

**4.3: Add the principle**

Create a new principle entry:
```markdown
### {Next Roman numeral}. {Extracted or Auto-generated Title}

{principle_text}
```

**4.4: Update constitution and version**

- Increment minor version (e.g., 1.0.0 -> 1.1.0)
- Update "Last Amended" date
- Add entry to Version History

```markdown
| 1.1.0 | {TODAY} | Added principle: {principle_title} | Claude (projspec) |
```

### Step 5: Update Dependent Templates

After any constitution change, check if dependent templates need synchronization.

**5.1: Identify dependent templates**

Templates that reference constitution principles:
- `plan-template.md` - Constitution Check section
- `checklist-template.md` - Quality gates section
- Any custom templates in the project

**5.2: Notify about potential sync needs**

```markdown
## Constitution Updated

The constitution has been updated. The following templates may need review:

| Template | Dependency | Action Needed |
|----------|------------|---------------|
| plan-template.md | Constitution Check section | Verify principle references |
| checklist-template.md | Quality Gates | Verify gate alignment |

**Note:** These templates will automatically use the updated constitution
during their respective command executions.
```

### Step 6: Report Completion

**6.1: Display summary of constitution**

```markdown
## Constitution {Created/Updated}

**Location:** {CONSTITUTION_PATH}
**Version:** {version}

### Core Principles

| # | Principle | Description |
|---|-----------|-------------|
{For each principle:}
| {Roman numeral} | {Title} | {Brief description} |
{End for}

### Constraint Summary

| Category | Count |
|----------|-------|
| Technology | {count} |
| Compliance | {count} |
| Policy | {count} |

### Quality Gates: {gate_count}

### Next Steps

The constitution is now active. It will be checked during:
- `/projspec.plan` - Technical planning will verify compliance
- `/projspec.implement` - Implementation will follow constraints
- `/projspec.review-pr` - Reviews will verify adherence

To view the full constitution:
```bash
cat {CONSTITUTION_PATH}
```

To add a new principle:
```
/projspec.constitution add "Your new principle text here"
```

To update interactively:
```
/projspec.constitution interactive
```
```

## Output

Upon completion, this command produces:

### Files Created/Modified

| File | Description |
|------|-------------|
| `.projspec/memory/constitution.md` | Project constitution document |

### Console Output

| Output | When Displayed |
|--------|----------------|
| Current constitution | When viewing existing constitution |
| Interactive prompts | During creation/update workflow |
| Principle confirmation | When adding a principle |
| Completion summary | After any constitution change |

## Usage

```
/projspec.constitution [action] [arguments]
```

### Actions

| Action | Description |
|--------|-------------|
| (none) | Display current constitution or start creation |
| `interactive` | Start interactive creation/update workflow |
| `add "<principle>"` | Add a specific principle |
| `update` | Update existing constitution |
| `view` | View current constitution |

### Examples

```bash
# View current constitution
/projspec.constitution

# Start interactive creation
/projspec.constitution interactive

# Add a specific principle
/projspec.constitution add "All API endpoints must have rate limiting"

# Update existing constitution
/projspec.constitution update
```

## Notes

- Constitution changes are versioned with date and author
- The constitution is checked during planning and implementation
- Violations require explicit justification and governance approval
- Override rules ensure flexibility while maintaining accountability
- Template synchronization is handled automatically during command execution

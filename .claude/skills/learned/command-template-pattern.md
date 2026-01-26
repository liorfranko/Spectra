# Skill: Command Template Pattern for Claude Code

## Purpose

Command templates are markdown files that guide Claude Code through specific workflows. They serve as instructions that Claude reads and follows.

## Standard Template Structure

```markdown
# Command: [name]

## Purpose

[1-2 paragraphs explaining what this command does and when to use it]

---

## Prerequisites

Before running this command, ensure:

1. [Prerequisite 1]
2. [Prerequisite 2]
3. [Prerequisite 3]

**If prerequisites are not met:**
- [What to do if missing]

---

## Workflow

### Step 1: [Action Name]

[Detailed instructions for this step]

**Input**: [What Claude should read/gather]
**Output**: [What Claude should produce]

### Step 2: [Action Name]

[Detailed instructions...]

[Continue for all steps...]

---

## Output

**Files Created/Modified:**
- `path/to/file.md` - Description

**State Changes:**
- [Phase updates, status changes, etc.]

---

## Examples

### Example 1: [Scenario Name]

**Context**: [When this example applies]

**User Input**: [What user provides]

**Expected Flow**:
1. [Step 1]
2. [Step 2]
3. [Result]

### Example 2: [Scenario Name]
...

---

## Error Handling

| Issue | Recovery |
|-------|----------|
| [Problem 1] | [Solution 1] |
| [Problem 2] | [Solution 2] |

---

## Notes

- [Important principle 1]
- [Important principle 2]
- [Best practices]
```

## Key Design Principles

1. **Clear Prerequisites**: Always list what must exist before the command runs
2. **Numbered Steps**: Each step in workflow should be actionable and specific
3. **Examples**: Include 2-4 practical examples showing different scenarios
4. **Error Handling**: Anticipate common issues and provide recovery steps
5. **Output Clarity**: Explicitly state what files/state changes result

## Template Location

Command templates live in `templates/commands/` and are referenced by:
- Claude Code directly reading them
- The speckit plugin loading them as skills

## Examples in This Project

- `specify.md` - Create feature specifications
- `plan.md` - Generate implementation plans
- `tasks.md` - Create task breakdowns
- `implement.md` - Execute task implementation
- `clarify.md` - Resolve specification ambiguities
- `constitution.md` - Create project principles
- `analyze.md` - Cross-artifact analysis
- `checklist.md` - Generate quality checklists
- `taskstoissues.md` - Convert tasks to GitHub issues

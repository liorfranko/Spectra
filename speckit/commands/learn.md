---
description: "Review and manage auto-learned patterns and insights from development sessions"
user-invocable: true
argument-hint: action (list, review, apply, clear)
---

# Learn Command

Review and manage auto-learned instincts, patterns, and skills discovered during development sessions. This command provides visibility into patterns that have been captured and allows you to promote useful patterns to permanent knowledge.

## Arguments

The `$ARGUMENTS` variable contains the action to perform:
- `list` - List all captured patterns and observations
- `review` - Interactively review and categorize patterns
- `apply` - Apply selected patterns to project configuration
- `clear` - Clear temporary pattern observations
- `export` - Export patterns to shareable format
- (empty) - Default to `list` action

## Overview

The learning system captures patterns during development sessions:
- **Instincts** - Implicit preferences and decision patterns
- **Observations** - Recurring behaviors or issues noted
- **Skills** - Reusable approaches that worked well
- **Anti-patterns** - Things to avoid based on experience

These patterns can be:
- Reviewed and validated
- Promoted to permanent project memory
- Shared with team members
- Used to improve future sessions

## Workflow

### Step 1: Load Learning Data

**1.1: Identify learning storage locations**

Learning data is stored in the `.specify/learning/` directory:

```bash
LEARNING_DIR=".specify/learning"

# Check if learning directory exists
if [ ! -d "$LEARNING_DIR" ]; then
    echo "No learning data found."
    exit 0
fi
```

**1.2: Discover learning artifacts**

```bash
# List learning categories
ls -la "$LEARNING_DIR/"
```

Expected structure:
```
.specify/learning/
├── observations/           # Session observations
│   └── {session-id}/
│       ├── patterns.md
│       └── issues.md
├── instincts/              # Captured instincts
│   └── instinct-{id}.md
├── skills/                 # Learned skills
│   └── skill-{id}.md
├── anti-patterns/          # Things to avoid
│   └── antipattern-{id}.md
└── session-log.json        # Session history
```

**1.3: Parse learning data**

For each category, read and parse the learning files:

```
learningData = {
  observations: [
    {
      sessionId: "abc123",
      timestamp: "2024-01-15T10:00:00Z",
      patterns: [...],
      issues: [...]
    },
    ...
  ],
  instincts: [
    {
      id: "instinct-001",
      description: "...",
      frequency: 5,
      confidence: "high",
      status: "pending" | "validated" | "rejected"
    },
    ...
  ],
  skills: [
    {
      id: "skill-001",
      name: "...",
      description: "...",
      examples: [...],
      status: "pending" | "validated" | "rejected"
    },
    ...
  ],
  antiPatterns: [
    {
      id: "antipattern-001",
      description: "...",
      consequence: "...",
      alternative: "...",
      status: "pending" | "validated" | "rejected"
    },
    ...
  ]
}
```

### Step 2: List Action (Default)

When `$ARGUMENTS` is empty or `list`.

**2.1: Display learning summary**

```markdown
## Learning Summary

**Learning Directory:** {LEARNING_DIR}
**Sessions Tracked:** {session_count}
**Last Session:** {last_session_date}

### Pattern Categories

| Category | Total | Pending | Validated | Rejected |
|----------|-------|---------|-----------|----------|
| Observations | {count} | {pending} | {validated} | {rejected} |
| Instincts | {count} | {pending} | {validated} | {rejected} |
| Skills | {count} | {pending} | {validated} | {rejected} |
| Anti-patterns | {count} | {pending} | {validated} | {rejected} |
```

**2.2: Display pending items summary**

```markdown
### Pending Review

The following patterns are awaiting review:

#### Instincts ({pending_count})
{For each pending instinct (max 5):}
- **{id}**: {brief_description}
  - Observed: {frequency} times
  - Confidence: {confidence}
{End for}
{If more than 5:}
... and {remaining} more. Run `/speckit.learn review` to see all.
{End if}

#### Skills ({pending_count})
{For each pending skill (max 5):}
- **{id}**: {name}
  - Description: {brief_description}
{End for}

#### Anti-patterns ({pending_count})
{For each pending anti-pattern (max 5):}
- **{id}**: {brief_description}
  - Avoid: {consequence}
{End for}
```

**2.3: Display recent observations**

```markdown
### Recent Observations

{For each recent session (max 3):}
#### Session: {session_date}

**Patterns Observed:**
{For each pattern:}
- {pattern_description}
{End for}

**Issues Noted:**
{For each issue:}
- {issue_description}
{End for}

{End for}
```

**2.4: Suggest next action**

```markdown
### Actions Available

- `/speckit.learn review` - Interactively review pending patterns
- `/speckit.learn apply` - Apply validated patterns to project
- `/speckit.learn clear` - Clear rejected/old patterns
- `/speckit.learn export` - Export patterns for sharing
```

### Step 3: Review Action

When `$ARGUMENTS` is `review`.

**3.1: Start interactive review**

```markdown
## Pattern Review

You have {pending_count} patterns pending review.

Review each pattern and decide whether to:
- **validate** - Confirm pattern is useful and should be kept
- **reject** - Pattern is not useful or incorrect
- **skip** - Defer decision to later

Starting review...

---
```

**3.2: Review instincts**

For each pending instinct:

```markdown
### Instinct Review: {id}

**Pattern Observed:**
{description}

**Context:**
- Observed {frequency} times across sessions
- Confidence level: {confidence}
- First observed: {first_seen}
- Last observed: {last_seen}

**Examples:**
{For each example (max 3):}
- {example_context}
{End for}

**Decision Options:**
1. `validate` - This is a useful pattern to remember
2. `reject` - This pattern is not useful or is incorrect
3. `skip` - Decide later
4. `modify` - Edit the pattern description

Your decision (1/2/3/4):
```

Wait for user input and update instinct status accordingly.

**3.3: Review skills**

For each pending skill:

```markdown
### Skill Review: {id}

**Skill:** {name}

**Description:**
{description}

**When to Use:**
{usage_context}

**Examples:**
{For each example:}
```
{example_code_or_command}
```
{End for}

**Decision Options:**
1. `validate` - Add to permanent skill library
2. `reject` - This skill is not useful
3. `skip` - Decide later
4. `modify` - Edit the skill definition

Your decision (1/2/3/4):
```

**3.4: Review anti-patterns**

For each pending anti-pattern:

```markdown
### Anti-pattern Review: {id}

**Pattern to Avoid:**
{description}

**Why It's Problematic:**
{consequence}

**Better Alternative:**
{alternative}

**Observed In:**
{For each occurrence:}
- {occurrence_context}
{End for}

**Decision Options:**
1. `validate` - Add to anti-pattern list
2. `reject` - This is not actually an anti-pattern
3. `skip` - Decide later
4. `modify` - Edit the anti-pattern definition

Your decision (1/2/3/4):
```

**3.5: Report review summary**

```markdown
## Review Complete

### Decisions Made

| Category | Validated | Rejected | Skipped | Modified |
|----------|-----------|----------|---------|----------|
| Instincts | {count} | {count} | {count} | {count} |
| Skills | {count} | {count} | {count} | {count} |
| Anti-patterns | {count} | {count} | {count} | {count} |

### Next Steps

{If validated patterns exist:}
Run `/speckit.learn apply` to add validated patterns to your project configuration.
{End if}

{If skipped patterns exist:}
{skipped_count} patterns were skipped and remain pending.
{End if}
```

### Step 4: Apply Action

When `$ARGUMENTS` is `apply`.

**4.1: Gather validated patterns**

```
validatedPatterns = {
  instincts: learningData.instincts.filter(i => i.status === "validated"),
  skills: learningData.skills.filter(s => s.status === "validated"),
  antiPatterns: learningData.antiPatterns.filter(a => a.status === "validated")
}
```

**4.2: Determine application targets**

```markdown
## Apply Validated Patterns

You have {total_validated} validated patterns to apply.

### Application Options

Patterns can be applied to:

1. **CLAUDE.md** - Add as project instructions
   - Instincts become guidelines
   - Skills become documented approaches
   - Anti-patterns become warnings

2. **Constitution** - Add as formal principles
   - High-confidence patterns become constraints
   - Anti-patterns become prohibited practices

3. **Custom Configuration** - Add to .specify/memory/
   - Patterns stored for session context
   - Available to future Claude Code sessions

Which target(s)? (1/2/3/all):
```

**4.3: Apply to CLAUDE.md**

If user selects option 1:

```markdown
### Updating CLAUDE.md

The following will be added to your CLAUDE.md file:

#### Learned Patterns Section

```markdown
## Learned Patterns

The following patterns have been learned from development sessions:

### Instincts
{For each validated instinct:}
- {description}
{End for}

### Preferred Approaches
{For each validated skill:}
- **{name}**: {description}
{End for}

### Avoid
{For each validated anti-pattern:}
- {description} - {consequence}
{End for}
```

Add this to CLAUDE.md? (y/n):
```

If confirmed, append the section to CLAUDE.md.

**4.4: Apply to constitution**

If user selects option 2:

```markdown
### Updating Constitution

The following will be proposed as new constitution entries:

**New Constraints:**
{For each high-confidence pattern:}
- {pattern as constraint}
{End for}

**New Policy Rules:**
{For each validated anti-pattern:}
- Avoid: {anti-pattern description}
{End for}

This will run `/speckit.constitution update` with these additions.

Proceed? (y/n):
```

If confirmed, invoke the constitution command with the updates.

**4.5: Report application results**

```markdown
## Patterns Applied

### Summary

| Target | Patterns Applied | Status |
|--------|------------------|--------|
| CLAUDE.md | {count} | {Updated/Skipped} |
| Constitution | {count} | {Updated/Skipped} |
| Custom Config | {count} | {Updated/Skipped} |

### Applied Patterns

{For each applied pattern:}
- [{category}] {description} -> {target}
{End for}

These patterns will now inform future development sessions.
```

### Step 5: Clear Action

When `$ARGUMENTS` is `clear`.

**5.1: Identify clearable data**

```markdown
## Clear Learning Data

The following data can be cleared:

| Category | Count | Age | Status |
|----------|-------|-----|--------|
| Rejected patterns | {count} | Various | Can clear |
| Old observations (> 30 days) | {count} | > 30 days | Can clear |
| Session logs (> 90 days) | {count} | > 90 days | Can clear |
| Temporary files | {count} | Various | Can clear |

**Warning:** Cleared data cannot be recovered.

What would you like to clear?
1. Rejected patterns only
2. Old data (> 30 days)
3. All temporary data
4. Everything (fresh start)
5. Cancel

Your choice (1/2/3/4/5):
```

**5.2: Execute clear based on selection**

For each selection:
- **Option 1**: Remove patterns with status "rejected"
- **Option 2**: Remove observations and logs older than 30 days
- **Option 3**: Remove all temporary data, keep validated patterns
- **Option 4**: Remove everything in learning directory
- **Option 5**: Cancel and return

**5.3: Report clear results**

```markdown
## Clear Complete

### Removed

| Category | Files Removed | Space Freed |
|----------|---------------|-------------|
| {category} | {count} | {size} |

### Retained

| Category | Files Kept | Reason |
|----------|------------|--------|
| Validated patterns | {count} | User validated |
| Recent observations | {count} | < 30 days old |

The learning directory has been cleaned up.
```

### Step 6: Export Action

When `$ARGUMENTS` is `export`.

**6.1: Gather exportable patterns**

Only validated patterns are exportable:

```
exportablePatterns = {
  instincts: learningData.instincts.filter(i => i.status === "validated"),
  skills: learningData.skills.filter(s => s.status === "validated"),
  antiPatterns: learningData.antiPatterns.filter(a => a.status === "validated")
}
```

**6.2: Select export format**

```markdown
## Export Patterns

You have {total_validated} validated patterns to export.

### Export Formats

1. **Markdown** - Human-readable document
2. **JSON** - Machine-readable, importable
3. **YAML** - Configuration-friendly
4. **CLAUDE.md Fragment** - Ready to paste into CLAUDE.md

Select format (1/2/3/4):
```

**6.3: Generate export content**

For each format:

**Markdown format:**
```markdown
# Learned Patterns Export

**Exported:** {timestamp}
**Source:** {project_name}
**Patterns:** {total_count}

## Instincts

{For each instinct:}
### {id}

{description}

- **Confidence:** {confidence}
- **Frequency:** {frequency} observations

{End for}

## Skills

{For each skill:}
### {name}

{description}

**Usage:**
{usage_context}

**Example:**
```
{example}
```

{End for}

## Anti-patterns

{For each anti-pattern:}
### {description}

**Avoid because:** {consequence}

**Instead:** {alternative}

{End for}
```

**JSON format:**
```json
{
  "exportedAt": "{timestamp}",
  "source": "{project_name}",
  "version": "1.0",
  "patterns": {
    "instincts": [...],
    "skills": [...],
    "antiPatterns": [...]
  }
}
```

**6.4: Save or display export**

```markdown
### Export Options

1. Save to file: `.specify/exports/patterns-{timestamp}.{ext}`
2. Display in terminal (copy-paste)
3. Copy to clipboard (if supported)

Your choice (1/2/3):
```

Handle selection and complete export.

**6.5: Report export completion**

```markdown
## Export Complete

**Format:** {selected_format}
**Patterns Exported:** {total_count}
{If saved to file:}
**File:** {export_path}
{End if}

### To Import in Another Project

{If JSON:}
Copy the JSON file to `.specify/learning/imports/` in the target project,
then run `/speckit.learn import`.
{End if}

{If Markdown:}
Share the markdown file with team members for reference.
{End if}
```

## Output

Upon completion, this command produces:

### Console Output

| Output | When Displayed |
|--------|----------------|
| Pattern summary | For `list` action |
| Interactive prompts | For `review` action |
| Application results | For `apply` action |
| Clear confirmation | For `clear` action |
| Export content/file | For `export` action |

### Files Modified

| File | Description |
|------|-------------|
| `.specify/learning/instincts/*.md` | Updated instinct status |
| `.specify/learning/skills/*.md` | Updated skill status |
| `.specify/learning/anti-patterns/*.md` | Updated anti-pattern status |
| `CLAUDE.md` | If patterns applied (optional) |
| `.specify/exports/*.{ext}` | Export files (optional) |

## Usage

```
/speckit.learn [action]
```

### Actions

| Action | Description |
|--------|-------------|
| `list` | List all captured patterns (default) |
| `review` | Interactively review pending patterns |
| `apply` | Apply validated patterns to configuration |
| `clear` | Clear old or rejected patterns |
| `export` | Export patterns to shareable format |

### Examples

```bash
# List all learning data
/speckit.learn

# List patterns (explicit)
/speckit.learn list

# Review pending patterns interactively
/speckit.learn review

# Apply validated patterns to project
/speckit.learn apply

# Clear rejected patterns
/speckit.learn clear

# Export patterns to share
/speckit.learn export
```

## Notes

- Learning data is captured automatically during development sessions
- Patterns start as "pending" and must be reviewed to be applied
- Validated patterns can be promoted to permanent project configuration
- Rejected patterns are cleared during cleanup
- Export allows sharing learned patterns across projects or team members
- The learning system improves over time as more patterns are validated

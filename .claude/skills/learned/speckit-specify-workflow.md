# Skill: SpecKit Specify Workflow

**Learned**: 2026-01-26
**Context**: Feature specification generation using speckit plugin

---

## Pattern: Feature Specification from Vague Input

When a user provides a vague or minimal feature description to `/speckit:specify`, follow this workflow:

### 1. Validate Input Quality

If the input is too vague (e.g., single words like "test", "feature"):
- Use `AskUserQuestion` to clarify the feature type
- Provide common feature options (Authentication, File Upload, Notifications, Search)
- Allow custom input via "Other" option

### 2. Feature Structure Creation

```bash
/path/to/scripts/create-new-feature.sh "feature-name" --json
```

Parse JSON output for:
- `FEATURE_ID`: Unique identifier (e.g., "004-test")
- `FEATURE_DIR`: Absolute path to feature directory
- `BRANCH`: Git branch name (same as FEATURE_ID)

### 3. Template-Based Generation

Read the spec template and systematically replace placeholders:
- Metadata section with feature ID, date, status
- User scenarios (minimum 2 required)
- Functional requirements with verification methods
- Success criteria with measurable targets
- Key entities with attributes and relationships
- Edge cases table

### 4. Clarification Identification

Limit to maximum 3 open questions. Prioritize:
1. Blockers that prevent implementation
2. Scope-defining decisions
3. Risk-bearing assumptions

Format questions with:
- Why Needed
- Suggested Default
- Impacted spec items (FR-###, US-###, etc.)

### 5. Validation Checks

Before finalizing, verify:
- No implementation details (languages, frameworks, databases)
- All requirements are testable and specific
- Success criteria have measurable targets
- All placeholders are filled

---

## Key Learnings

1. **Always clarify vague inputs** - Don't assume; ask the user
2. **Use suggested defaults** - Provide reasonable defaults for open questions
3. **Keep spec implementation-agnostic** - Focus on "what" not "how"
4. **Track open questions** - Maximum 3, with clear impact documentation
5. **Create checklist alongside spec** - Helps validate quality before planning

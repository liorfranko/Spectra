# Feature Specification: Prefer Interactive Questions in Skill Prompts

## Metadata

| Field | Value |
|-------|-------|
| Branch | `010-add-to-all-the` |
| Date | 2026-01-27 |
| Status | Draft |
| Input | Update all skill prompts to prefer using the AskUserQuestion tool with structured options at clarification points |
| Scope | Both commands (11 files) and agents (6 files) - 17 total prompt files |

---

## User Scenarios & Testing

### Primary Scenarios

#### US-001: Skill Author Updates Existing Skill Prompts

**As a** plugin maintainer
**I want to** update all skill prompts to use the AskUserQuestion tool
**So that** users receive structured, selectable options instead of plain text questions when clarification is needed

**Acceptance Criteria:**
- [ ] All skill prompts include instructions to use AskUserQuestion tool at clarification points
- [ ] Instructions specify when to use structured options vs plain text
- [ ] Skills provide consistent user experience across the plugin
- [ ] Existing skill functionality is preserved after the update

**Priority:** High

#### US-002: User Interacts with Updated Skill

**As a** projspec user
**I want to** receive interactive question prompts with selectable options
**So that** I can quickly provide input without typing long responses

**Acceptance Criteria:**
- [ ] When a skill needs clarification, user sees a list of options to select from
- [ ] Options include descriptions explaining each choice
- [ ] User can still provide custom input when predefined options don't fit
- [ ] Questions are clear and context-appropriate

**Priority:** High

#### US-003: Skill Handles Edge Cases Gracefully

**As a** projspec user
**I want to** the skill to handle unexpected or missing input gracefully
**So that** I'm not blocked by unclear prompts or missing options

**Acceptance Criteria:**
- [ ] Skills provide an "Other" option for custom input when appropriate
- [ ] Skills handle cases where no options are applicable
- [ ] Error messages guide the user to provide needed information

**Priority:** Medium

### Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| No clarification needed | Skill proceeds without prompting user |
| Single valid option exists | Still present as selectable option with ability to choose "Other" |
| User's context already provides answer | Skill uses existing context, skips redundant question |
| More than 4 options possible | Prioritize most common options (up to 4), offer "Other" for alternatives |

---

## Requirements

### Functional Requirements

#### FR-001: Update All Skill Prompts with AskUserQuestion Instructions

All skill prompts in the projspec plugin must include explicit instructions for when and how to use the AskUserQuestion tool at clarification points. This includes both command prompts (11 files: constitution, implement, validate, review-pr, analyze, tasks, clarify, checklist, issues, plan, specify) and agent prompts (6 files: code-reviewer, silent-failure-hunter, code-simplifier, comment-analyzer, pr-test-analyzer, type-design-analyzer). All 17 files will be updated in a single batch for consistency.

**Verification:** Review each of the 17 skill files and confirm it contains AskUserQuestion usage instructions in appropriate sections.

#### FR-002: Define Standard Question Format Guidelines

Establish a consistent format for interactive questions across all skills, including question structure, option limits, and description requirements. Guidelines will be embedded directly in each skill file (self-contained prompts) rather than in a shared reference document.

**Verification:** Review each skill file and verify it contains embedded AskUserQuestion guidelines that adhere to the standard format.

#### FR-003: Identify Clarification Points in Each Skill

Each skill must identify specific points where user input is needed to proceed, and mark these as interactive question opportunities.

**Verification:** Review each skill workflow and confirm clarification points are documented and implemented.

#### FR-004: Preserve Skill Backward Compatibility

Updated skills must continue to function correctly when users provide information upfront (via command arguments or context), bypassing unnecessary questions.

**Verification:** Test each skill with full context provided upfront and verify it completes without unnecessary prompts.

#### FR-005: Support Custom Input Fallback

All interactive questions must allow users to provide custom input when predefined options don't match their needs.

**Verification:** Test each interactive question and verify "Other" option is available and functional.

### Constraints

| Constraint | Description |
|------------|-------------|
| Maximum 4 options per question | AskUserQuestion tool limits options to 4 per question |
| Maximum 4 questions per prompt | Tool limits concurrent questions to 4 |
| Option labels max 80 characters | Keep labels concise for readability |
| Question text max 200 characters | Keeps questions concise and scannable |
| Header max 12 characters | Short label displayed as chip/tag |

---

## Key Entities

### Skill Prompt

**Description:** A markdown file that defines instructions for Claude to execute a specific workflow

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| Name | Unique identifier for the skill | Must match filename pattern |
| Workflow Steps | Ordered list of steps to execute | Must be sequential |
| Clarification Points | Locations where user input may be needed | Must use AskUserQuestion format |

### Interactive Question

**Description:** A structured question presented to the user with selectable options

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| Question Text | The question being asked | Max 200 characters, clear, specific, ends with ? |
| Header | Short label for the question | Max 12 characters |
| Options | List of selectable choices | 2-4 options required |
| Multi-select | Whether multiple options can be selected | Boolean, default false |

### Option

**Description:** A single selectable choice within an interactive question

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| Label | Display text for the option | Max 80 characters |
| Description | Explanation of what this option means | Should clarify implications |

### Entity Relationships

- Skill Prompt contains zero or more Clarification Points
- Clarification Point triggers one Interactive Question
- Interactive Question contains 2-4 Options

---

## Success Criteria

### SC-001: Complete Skill Coverage

**Measure:** Percentage of skills updated with AskUserQuestion instructions
**Target:** 100% of skill prompts include interactive question guidelines
**Verification Method:** Audit all skill files in the plugin and confirm each contains the required instructions

### SC-002: Consistent Question Format

**Measure:** Adherence to standard question format across skills
**Target:** 100% of interactive questions follow documented format guidelines
**Verification Method:** Review a sample of each skill's clarification points against the standard

### SC-003: User Experience Improvement

**Measure:** Reduction in free-form text input requirements at clarification points
**Target:** At least 80% of clarification points use structured options
**Verification Method:** Count clarification points before and after update, compare structured vs free-form

---

## Assumptions

| ID | Assumption | Impact if Wrong | Validated |
|----|------------|-----------------|-----------|
| A-001 | All skills have identifiable clarification points | Some skills may not benefit from interactive questions | No |
| A-002 | Users prefer selecting options over typing responses | Feature may not improve UX for all users | No |
| A-003 | AskUserQuestion tool is available in all contexts where skills run | N/A - core Claude Code tool, no fallback needed | Yes |

---

## Open Questions

### Q-001: Which skills should be prioritized for the update?

- **Question**: Should all skills be updated in a single batch, or should they be prioritized based on usage frequency?
- **Why Needed**: Determines implementation order and helps manage scope
- **Resolution**: Update all 17 skills in a single batch for consistency
- **Status**: Resolved
- **Impacts**: FR-001, SC-001

### Q-002: Should interactive question guidelines be centralized or embedded in each skill?

- **Question**: Should there be a shared template/include for interactive question instructions, or should each skill contain its own copy?
- **Why Needed**: Affects maintainability and consistency of updates
- **Resolution**: Embed guidelines directly in each skill file (self-contained prompts)
- **Status**: Resolved
- **Impacts**: FR-002, SC-002

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-01-27 | Claude (projspec) | Initial draft from feature description |
| 0.2 | 2026-01-27 | Claude (projspec/clarify) | Resolved 5 clarifications: scope (both commands+agents), implementation order (single batch), guideline location (embedded), fallback (not needed), question text limit (200 chars). Updated FR-001, FR-002, constraints, entities. Resolved Q-001, Q-002. Validated A-003. |

# Skill: SpecKit Validation Checklist

## When to Use
When running `/speckit.validate` or manually validating feature specifications for completeness and consistency.

## Validation Categories

### 1. Specification Completeness
- All mandatory sections present (User Scenarios, Requirements, Success Criteria)
- No placeholder text remaining (`[FEATURE NAME]`, `[TODO]`)
- No unresolved `[NEEDS CLARIFICATION]` markers
- All user stories have acceptance scenarios (Given/When/Then)
- All functional requirements have MUST/SHOULD language
- Success criteria are measurable with specific numbers/percentages

### 2. Constitution Alignment
- Constitution exists and is customized (not template placeholders)
- All principles addressed in plan's Constitution Check
- No violations without documented justification

### 3. Cross-Artifact Consistency
Check these pairings:
- **Spec <-> Plan**: User stories in scope, technical context addresses requirements
- **Spec <-> Data Model**: All Key Entities defined with attributes
- **Spec <-> Contracts**: User stories have corresponding CLI commands/endpoints
- **Spec <-> Quickstart**: P1 user stories covered, commands match contracts
- **Research <-> Plan**: Technologies reflected, no outdated conclusions

### 4. Terminology Consistency
- Same entity names across all artifacts
- No confusing synonyms (e.g., "repo" vs "repository")
- Technical terms match constitution glossary

### 5. Testability
- Each functional requirement can be verified with a specific test
- Success criteria have clear pass/fail conditions
- Acceptance scenarios follow Given/When/Then format correctly

### 6. Clarity & Ambiguity
- No vague adjectives without quantification ("fast", "robust")
- No assumptions that should be explicit
- No contradicting requirements

### 7. Leftover Detection
- No orphaned references to removed features
- No stale TODOs or FIXMEs
- No commented-out sections
- No references using old entity names

## Status Definitions
- **PASS**: All checks pass
- **WARNING**: Minor issues, non-blocking
- **FAIL**: Critical issues that must be resolved

## Auto-Fail Conditions
1. Spec file missing or unreadable
2. Any `[NEEDS CLARIFICATION]` markers remain
3. Missing mandatory sections
4. Functional requirements without testable criteria
5. Constitution violations without justification

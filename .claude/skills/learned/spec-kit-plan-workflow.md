# Skill: Spec-Kit Plan Workflow

**Learned**: 2026-01-26
**Context**: Executing `/speckit.plan` command

## Pattern

The `/speckit.plan` command follows a structured workflow to generate implementation artifacts from a feature specification.

### Phases

1. **Setup**: Run `setup-plan.sh --json` to get paths and copy plan template
2. **Load Context**: Read spec.md, constitution.md, and plan template
3. **Fill Plan**: Complete Technical Context, Constitution Check, Project Structure
4. **Phase 0 - Research**: Generate research.md with technology decisions
5. **Phase 1 - Design**: Generate data-model.md, contracts/, quickstart.md
6. **Update Context**: Run `update-agent-context.sh` to refresh CLAUDE.md

### Key Artifacts

| File | Purpose |
|------|---------|
| plan.md | Technical implementation plan |
| research.md | Technology decisions with rationale |
| data-model.md | Entity definitions and state schemas |
| contracts/*.md | API/CLI interface contracts |
| quickstart.md | Validation scenarios for testing |

### Technical Context Template

Fill these fields (mark unknowns as "NEEDS CLARIFICATION"):
- Language/Version
- Primary Dependencies
- Storage
- Testing
- Target Platform
- Project Type
- Performance Goals
- Constraints
- Scale/Scope

### Constitution Check

Evaluate gates from constitution.md before proceeding. Document:
- Gate name
- PASS/FAIL status
- Notes explaining decision

### Research Document Structure

For each technology decision:
1. **Decision**: What was chosen
2. **Rationale**: Why chosen
3. **Alternatives Considered**: Table with rejected alternatives and reasons
4. **Best Practices**: Key patterns to follow
5. **Source Files**: Reference implementations if available

### Data Model Structure

1. Entity diagram (ASCII art)
2. For each entity:
   - YAML schema with all fields
   - Validation rules
   - State transitions (if applicable)
3. File organization summary

### Contract Structure

1. Command/endpoint name
2. Arguments/parameters table
3. Options table
4. Exit codes or response codes
5. Output examples
6. Validation checklist

## When to Apply

- When executing `/speckit.plan` command
- When creating implementation plans from specifications
- When documenting technology decisions for a feature

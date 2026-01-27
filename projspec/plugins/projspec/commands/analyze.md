---
description: "Perform cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md"
user-invocable: true
---

# Analyze Command

Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation. This command identifies gaps, conflicts, and drift between artifacts without modifying any files.

## Clarification Approach

When you need user input that isn't already provided in context or arguments, use the AskUserQuestion tool with 2-4 selectable options instead of plain text questions. Put the recommended option first.

## Prerequisites

This command requires that at least spec.md exists in the current feature directory. For comprehensive analysis, plan.md and tasks.md should also be present.

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-spec
```

If the prerequisite check fails, run `/projspec.specify` first to create the specification.

## Workflow

### Step 1: Check Prerequisites and Load Artifacts

Validate that the required artifacts exist and load them for analysis.

#### 1.1: Run Prerequisite Check

Execute the prerequisite check script to identify the feature directory and available documents:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh --require-spec --json
```

**Parse the JSON output** to extract:
- `FEATURE_DIR`: The path to the current feature directory
- `AVAILABLE_DOCS`: List of documents that exist in the feature directory
- `FEATURE_ID`: The unique identifier for the feature

#### 1.2: Check for Required Artifacts

Verify that the minimum required artifacts exist:

| Artifact | Required | Purpose |
|----------|----------|---------|
| `spec.md` | Yes | Source of truth for requirements and user scenarios |
| `plan.md` | No | Technical implementation decisions and architecture |
| `tasks.md` | No | Implementation task breakdown |

**Analysis Scope Determination:**

Based on available artifacts, determine the analysis scope:

| Available Artifacts | Analysis Scope |
|---------------------|----------------|
| spec.md only | Spec self-validation only |
| spec.md + plan.md | Spec-to-Plan coverage analysis |
| spec.md + plan.md + tasks.md | Full cross-artifact analysis |
| All + data-model.md | Extended analysis with entity validation |

If only spec.md exists, warn the user:
```
Note: Only spec.md found. Run /projspec.plan and /projspec.tasks for full cross-artifact analysis.
```

#### 1.3: Load All Available Artifacts

Read each available artifact and parse its contents:

**For spec.md, extract:**
- User Scenarios (US-###) with acceptance criteria
- Functional Requirements (FR-###) with verification methods
- Success Criteria (SC-###) with targets
- Key Entities and their attributes
- Constraints
- Assumptions
- Open Questions

**For plan.md, extract:**
- Technical Context (language, dependencies, platform)
- Project Structure (directories, file mapping)
- Constitution Check results
- Component breakdown
- Architecture decisions

**For tasks.md, extract:**
- All task IDs (T###) with descriptions
- Phase organization
- Dependency relationships
- User story markers [US#]
- Checkpoint tasks

**For data-model.md (if exists), extract:**
- Entity definitions with attributes
- Validation rules
- Relationships between entities
- State transitions

#### 1.4: Create Analysis Context

Build a structured analysis context containing all extracted data:

```
analysisContext = {
  featureId: FEATURE_ID,
  featureDir: FEATURE_DIR,
  artifacts: {
    spec: { exists: true, content: {...} },
    plan: { exists: true/false, content: {...} },
    tasks: { exists: true/false, content: {...} },
    dataModel: { exists: true/false, content: {...} }
  },
  scope: "full" | "spec-plan" | "spec-only"
}
```

### Step 2: Validate Spec-to-Plan Coverage

Compare requirements in spec.md against plan.md to identify coverage gaps.

#### 2.1: Extract Requirement IDs from Spec

Parse spec.md to build a complete list of all defined requirements:

| Requirement Type | ID Pattern | Example |
|------------------|------------|---------|
| User Scenarios | `US-###` | US-001, US-002 |
| Functional Requirements | `FR-###` | FR-001, FR-002 |
| Success Criteria | `SC-###` | SC-001, SC-002 |
| Non-Functional Requirements | `NFR-###` | NFR-001 |

For each requirement, capture:
```
{
  id: "FR-001",
  type: "functional",
  title: "Requirement title",
  description: "Full description text",
  verificationMethod: "How to verify",
  priority: "High" | "Medium" | "Low" (if specified)
}
```

Store all requirements in a lookup structure:
```
specRequirements = {
  "US-001": { ... },
  "US-002": { ... },
  "FR-001": { ... },
  "FR-002": { ... },
  "SC-001": { ... },
  ...
}
```

#### 2.2: Extract Plan Coverage References

If plan.md exists, search for references to spec requirements:

**Coverage locations in plan.md:**
- File-to-Requirement Mapping table
- Technical Context constraints
- Component descriptions
- Architecture decision rationale

For each requirement reference found:
```
planCoverage = {
  "FR-001": {
    referenced: true,
    locations: ["File-to-Requirement Mapping", "Technical Context"],
    mappedFiles: ["src/services/auth.ts", "src/utils/validation.ts"],
    notes: "Covered by authentication service design"
  },
  ...
}
```

#### 2.3: Identify Spec-to-Plan Gaps

Compare specRequirements against planCoverage to find gaps:

**Gap Categories:**

| Gap Type | Description | Severity |
|----------|-------------|----------|
| Uncovered Requirement | Requirement in spec not mentioned in plan | High |
| Partial Coverage | Requirement mentioned but not mapped to files | Medium |
| Missing File Mapping | Requirement mapped but file path not specified | Low |
| Orphaned Reference | Plan references requirement not in spec | High |

For each gap found:
```
specToPlanGaps.push({
  type: "uncovered_requirement",
  requirementId: "FR-003",
  requirementType: "functional",
  description: "FR-003: User session management not addressed in plan",
  severity: "high",
  recommendation: "Add FR-003 to File-to-Requirement Mapping in plan.md"
})
```

#### 2.4: Check Entity Coverage

If data-model.md exists, verify all spec entities are defined:

**Entity Coverage Checks:**
1. Every entity mentioned in spec Key Entities section exists in data-model.md
2. Every entity attribute in spec is present in data-model.md definition
3. Entity relationships in spec match data-model.md relationships

For each entity gap:
```
entityGaps.push({
  type: "missing_entity" | "missing_attribute" | "relationship_mismatch",
  entityName: "UserSession",
  specLocation: "Key Entities > UserSession",
  issue: "Entity defined in spec but not in data-model.md",
  severity: "high"
})
```

### Step 3: Validate Plan-to-Tasks Coverage

Compare plan components against tasks.md to ensure all planned work has corresponding tasks.

#### 3.1: Extract Planned Components from Plan

Parse plan.md to identify all components that require implementation:

**Component Sources in plan.md:**

| Section | Component Type | Example |
|---------|----------------|---------|
| Project Structure | Source files | `src/services/auth.ts` |
| File-to-Requirement Mapping | Mapped files | Files listed in the table |
| Dependencies | Library integrations | External package setup |
| Technical Context | Configuration | Config file creation |

For each planned component:
```
plannedComponents = {
  "src/services/auth.ts": {
    type: "source_file",
    requirements: ["FR-001", "FR-002"],
    section: "File-to-Requirement Mapping"
  },
  "package.json": {
    type: "config",
    requirements: [],
    section: "Project Structure"
  },
  ...
}
```

#### 3.2: Extract Task Coverage from tasks.md

If tasks.md exists, parse all tasks to determine what they implement:

For each task, extract:
```
{
  id: "T201",
  phase: 3,
  description: "Implement authentication service (src/services/auth.ts)",
  filePath: "src/services/auth.ts",
  storyMarker: "US1",
  parallel: false,
  blockedBy: ["T200"]
}
```

Build a mapping of file paths to tasks:
```
taskCoverage = {
  "src/services/auth.ts": {
    tasks: ["T201", "T205"],
    covered: true
  },
  "src/utils/validation.ts": {
    tasks: ["T202"],
    covered: true
  },
  ...
}
```

#### 3.3: Identify Plan-to-Tasks Gaps

Compare plannedComponents against taskCoverage:

**Gap Categories:**

| Gap Type | Description | Severity |
|----------|-------------|----------|
| Uncovered File | File in plan has no tasks | High |
| Partial Coverage | File mentioned but only some operations covered | Medium |
| Missing Dependency Setup | Dependency in plan has no installation task | Medium |
| Configuration Gap | Config file in plan has no creation task | Low |

For each gap found:
```
planToTasksGaps.push({
  type: "uncovered_file",
  filePath: "src/middleware/rateLimit.ts",
  planSection: "File-to-Requirement Mapping",
  relatedRequirements: ["NFR-001"],
  description: "Rate limiting middleware has no implementation tasks",
  severity: "high",
  recommendation: "Add task(s) to implement src/middleware/rateLimit.ts"
})
```

#### 3.4: Validate User Story Coverage

Ensure all user stories from spec have corresponding tasks:

**User Story Task Validation:**
1. Every US-### in spec should have tasks marked with [US#]
2. Acceptance criteria should map to test tasks
3. Each user story should have a CHECKPOINT task

For each user story:
```
storyCoverage = {
  "US-001": {
    storyId: "US-001",
    specTitle: "User can log in",
    tasksFound: ["T200", "T201", "T202", ...],
    checkpointTask: "T214",
    acceptanceCriteria: 3,
    testTasks: 2,
    coveragePercent: 67,
    gaps: ["Missing test task for criterion 3"]
  },
  ...
}
```

Flag stories with low coverage:
```
if storyCoverage[storyId].coveragePercent < 100:
  storyGaps.push({
    type: "incomplete_story_coverage",
    storyId: storyId,
    coveragePercent: storyCoverage[storyId].coveragePercent,
    missingItems: storyCoverage[storyId].gaps,
    severity: "medium"
  })
```

### Step 4: Identify Gaps, Conflicts, and Drift

Perform comprehensive analysis to detect inconsistencies across all artifacts.

#### 4.1: Detect Terminology Drift

Identify cases where the same concept uses different terms across artifacts:

**Terminology Consistency Checks:**

1. **Entity Name Consistency**: Same entity should use same name
   - spec.md: "UserSession"
   - data-model.md: "Session"
   - tasks.md: "user session"

2. **Requirement ID Consistency**: IDs should match exactly
   - spec.md: "FR-001"
   - plan.md: "FR-1" (incorrect)

3. **File Path Consistency**: Paths should be identical
   - plan.md: "src/services/authService.ts"
   - tasks.md: "src/services/auth-service.ts" (inconsistent)

For each terminology drift:
```
terminologyDrift.push({
  type: "terminology_drift",
  concept: "User Session entity",
  variants: [
    { artifact: "spec.md", term: "UserSession" },
    { artifact: "data-model.md", term: "Session" },
    { artifact: "tasks.md", term: "user session" }
  ],
  severity: "medium",
  recommendation: "Standardize on 'UserSession' across all artifacts"
})
```

#### 4.2: Detect Requirement Conflicts

Identify requirements or constraints that conflict with each other:

**Conflict Detection Rules:**

| Conflict Type | Example | Detection Method |
|---------------|---------|------------------|
| Contradicting Requirements | FR-001 says "must" while FR-005 says "must not" | Semantic analysis of negations |
| Incompatible Constraints | Platform: macOS-only + Requirement: Windows support | Cross-reference platform and requirements |
| Priority Conflicts | P1 task blocked by P3 task | Analyze dependency graph vs priority |
| Capacity Conflicts | Success criteria exceeds constraint limits | Compare SC targets against constraints |

For each conflict found:
```
conflicts.push({
  type: "requirement_conflict",
  items: [
    { id: "FR-001", text: "System must log all user actions" },
    { id: "NFR-002", text: "System must not store any user data" }
  ],
  description: "Cannot log user actions without storing user data",
  severity: "high",
  resolution: "Clarify scope of logging vs data storage requirements"
})
```

#### 4.3: Detect Scope Drift

Identify features or components that appear in later artifacts but not in spec:

**Scope Drift Detection:**

1. **Plan Additions**: Components in plan not traceable to spec requirements
2. **Task Additions**: Tasks not linked to any spec requirement or user story
3. **Entity Additions**: Entities in data-model not mentioned in spec

For each scope drift:
```
scopeDrift.push({
  type: "scope_drift",
  artifact: "plan.md",
  item: "Redis caching layer",
  location: "Project Structure > Cache directory",
  description: "Caching infrastructure not mentioned in spec requirements",
  severity: "medium",
  recommendation: "Either add caching requirement to spec or remove from plan"
})
```

#### 4.4: Detect Orphaned References

Find references to items that no longer exist or never existed:

**Orphan Detection:**

| Orphan Type | Example | Severity |
|-------------|---------|----------|
| Orphaned Requirement | Plan references FR-010 but spec only has FR-001 to FR-005 | High |
| Orphaned Task | Task references T100 in blockedBy but T100 doesn't exist | High |
| Orphaned Entity | Task mentions "SessionToken" entity not in data-model | Medium |
| Orphaned File | Task targets file not in Project Structure | Low |

For each orphan:
```
orphans.push({
  type: "orphaned_reference",
  referenceType: "requirement",
  invalidReference: "FR-010",
  foundIn: "plan.md",
  location: "File-to-Requirement Mapping",
  severity: "high",
  recommendation: "Remove reference to FR-010 or add FR-010 to spec"
})
```

#### 4.5: Detect Missing Traceability

Identify items that should be linked but are not:

**Traceability Requirements:**

| Source | Should Link To | Validation |
|--------|----------------|------------|
| User Scenario (US-###) | Tasks with [US#] marker | Every US should have tasks |
| Functional Requirement (FR-###) | File in plan mapping | Every FR should have file(s) |
| Success Criteria (SC-###) | Test task or verification | Every SC should have verification |
| Entity in spec | Definition in data-model | Every entity should be defined |

For each missing link:
```
missingTraceability.push({
  type: "missing_traceability",
  source: "SC-003",
  sourceArtifact: "spec.md",
  expectedTarget: "Test task or verification in tasks.md",
  description: "SC-003 (Response time < 2s) has no verification task",
  severity: "medium",
  recommendation: "Add performance test task for SC-003"
})
```

#### 4.6: Compile All Issues

Aggregate all detected issues into a unified findings structure:

```
allIssues = {
  gaps: [...specToPlanGaps, ...planToTasksGaps, ...entityGaps, ...storyGaps],
  conflicts: [...conflicts],
  drift: [...terminologyDrift, ...scopeDrift],
  orphans: [...orphans],
  traceability: [...missingTraceability]
}
```

Calculate severity distribution:
```
severityCounts = {
  high: allIssues.filter(i => i.severity == "high").count,
  medium: allIssues.filter(i => i.severity == "medium").count,
  low: allIssues.filter(i => i.severity == "low").count
}
```

### Step 5: Generate Consistency Report

Compile all findings into a comprehensive, structured report.

#### 5.1: Create Report Header

Generate the report header with analysis metadata:

```markdown
# Cross-Artifact Consistency Analysis Report

**Feature**: [FEATURE_ID]
**Directory**: [FEATURE_DIR]
**Generated**: [TIMESTAMP in ISO 8601 format]
**Analysis Scope**: [full | spec-plan | spec-only]

## Executive Summary

| Metric | Count |
|--------|-------|
| Artifacts Analyzed | [count] |
| Total Issues Found | [count] |
| High Severity | [count] |
| Medium Severity | [count] |
| Low Severity | [count] |

**Overall Status**: [PASS | WARN | FAIL]

Criteria:
- PASS: No high severity issues
- WARN: 1-2 high severity issues or 5+ medium severity issues
- FAIL: 3+ high severity issues

---
```

#### 5.2: Generate Spec-to-Plan Coverage Section

Document the coverage analysis between specification and plan:

```markdown
## Spec-to-Plan Coverage

### Requirement Coverage Summary

| Requirement Type | Total | Covered | Coverage % |
|------------------|-------|---------|------------|
| User Scenarios (US-###) | [count] | [count] | [percent]% |
| Functional Requirements (FR-###) | [count] | [count] | [percent]% |
| Success Criteria (SC-###) | [count] | [count] | [percent]% |
| Non-Functional Requirements (NFR-###) | [count] | [count] | [percent]% |
| **Total** | [total] | [covered] | [percent]% |

### Uncovered Requirements

{For each uncovered requirement:}

#### [REQUIREMENT_ID]: [REQUIREMENT_TITLE]

- **Type**: [Functional | Non-Functional | User Scenario | Success Criteria]
- **Description**: [Brief description from spec]
- **Severity**: [High | Medium | Low]
- **Recommendation**: Add coverage for this requirement in plan.md

{End for each}

### Entity Coverage

| Entity | In Spec | In Data Model | In Plan | Status |
|--------|---------|---------------|---------|--------|
| [EntityName] | Yes | Yes | Yes | Covered |
| [EntityName] | Yes | No | Yes | Missing data-model |
| [EntityName] | Yes | Yes | No | Missing plan mapping |

---
```

#### 5.3: Generate Plan-to-Tasks Coverage Section

Document the coverage analysis between plan and tasks:

```markdown
## Plan-to-Tasks Coverage

### File Coverage Summary

| Category | Planned | With Tasks | Coverage % |
|----------|---------|------------|------------|
| Source Files | [count] | [count] | [percent]% |
| Configuration Files | [count] | [count] | [percent]% |
| Test Files | [count] | [count] | [percent]% |
| **Total** | [total] | [covered] | [percent]% |

### Uncovered Files

{For each uncovered file:}

- **File**: `[file_path]`
- **Plan Section**: [section where file is defined]
- **Related Requirements**: [FR-###, FR-###]
- **Recommendation**: Add implementation task(s) for this file

{End for each}

### User Story Task Coverage

| Story | Title | Tasks | Checkpoint | Test Tasks | Coverage |
|-------|-------|-------|------------|------------|----------|
| US-001 | [title] | [count] | Yes/No | [count] | [percent]% |
| US-002 | [title] | [count] | Yes/No | [count] | [percent]% |

### Stories with Incomplete Coverage

{For each story with < 100% coverage:}

#### [STORY_ID]: [STORY_TITLE]

- **Coverage**: [percent]%
- **Missing Items**:
  - [Missing item 1]
  - [Missing item 2]
- **Recommendation**: [Specific action to improve coverage]

{End for each}

---
```

#### 5.4: Generate Conflicts and Drift Section

Document all detected conflicts and drift:

```markdown
## Conflicts and Drift

### Terminology Drift

{If terminology drift issues exist:}

| Concept | Spec Term | Plan Term | Tasks Term | Recommendation |
|---------|-----------|-----------|------------|----------------|
| [concept] | [term] | [term] | [term] | Standardize on "[preferred]" |

{Else:}
No terminology drift detected.

### Requirement Conflicts

{For each conflict:}

#### Conflict: [CONFLICT_TITLE]

**Items in Conflict:**
- [ID1]: [Description of first item]
- [ID2]: [Description of second item]

**Issue**: [Description of the conflict]

**Severity**: [High | Medium]

**Resolution**: [Suggested resolution]

{End for each}

{If no conflicts:}
No requirement conflicts detected.

### Scope Drift

{For each scope drift:}

- **Item**: [Item that drifted]
- **Found In**: [artifact]
- **Issue**: [Description of scope drift]
- **Severity**: [Medium | Low]
- **Recommendation**: [Add to spec OR remove from artifact]

{End for each}

{If no scope drift:}
No scope drift detected.

---
```

#### 5.5: Generate Orphaned References Section

Document all orphaned references:

```markdown
## Orphaned References

### Invalid References

{For each orphan:}

| Reference | Type | Found In | Issue | Recommendation |
|-----------|------|----------|-------|----------------|
| [ref] | [type] | [artifact:location] | [issue] | [fix] |

{End for each}

{If no orphans:}
No orphaned references detected.

### Broken Dependencies

{For each broken task dependency:}

- **Task**: [task_id]
- **References**: [invalid_task_id] in blockedBy
- **Issue**: Referenced task does not exist
- **Impact**: Task dependency chain is broken

{End for each}

---
```

#### 5.6: Generate Traceability Matrix

Create a comprehensive traceability view:

```markdown
## Traceability Matrix

### Requirements to Artifacts

| Requirement | Spec | Plan | Tasks | Data Model | Status |
|-------------|------|------|-------|------------|--------|
| US-001 | Def | Ref | Impl | N/A | Complete |
| US-002 | Def | Ref | Impl | N/A | Complete |
| FR-001 | Def | Map | Impl | N/A | Complete |
| FR-002 | Def | Map | - | N/A | Missing Tasks |
| SC-001 | Def | - | Test | N/A | Missing Plan |
| Entity: User | Def | Map | Impl | Def | Complete |

**Legend:**
- Def: Defined in artifact
- Ref: Referenced in artifact
- Map: Mapped to files in artifact
- Impl: Implementation task exists
- Test: Test task exists
- `-`: Not present (gap)
- N/A: Not applicable

### Missing Traceability Links

{For each missing link:}

- **Source**: [source_id] in [artifact]
- **Expected**: [what should be linked]
- **Issue**: [description of missing link]
- **Recommendation**: [how to fix]

{End for each}

---
```

#### 5.7: Generate Recommendations Section

Compile prioritized recommendations:

```markdown
## Recommendations

### High Priority (Blocking Issues)

{For each high severity issue:}

1. **[Issue Title]**
   - Issue: [Brief description]
   - Location: [artifact:section]
   - Action: [Specific remediation step]
   - Estimated Effort: [Low | Medium | High]

{End for each}

### Medium Priority (Quality Issues)

{For each medium severity issue:}

1. **[Issue Title]**
   - Issue: [Brief description]
   - Action: [Specific remediation step]

{End for each}

### Low Priority (Improvements)

{For each low severity issue:}

1. **[Issue Title]**: [Action to take]

{End for each}

---
```

#### 5.8: Generate Report Footer

Add summary statistics and next steps:

```markdown
## Analysis Statistics

| Metric | Value |
|--------|-------|
| Analysis Duration | [duration] |
| Artifacts Analyzed | [count] |
| Requirements Checked | [count] |
| Files Validated | [count] |
| Dependencies Verified | [count] |
| Issues Found | [count] |

## Next Steps

{Based on analysis results:}

**If PASS:**
All artifacts are consistent. You may proceed with:
- `/projspec.implement` - Begin implementation
- `/projspec.taskstoissues` - Convert tasks to GitHub issues

**If WARN:**
Minor issues detected. Consider addressing before proceeding:
- Review medium severity issues above
- Run `/projspec.clarify` to resolve open questions
- Then `/projspec.analyze` again to verify fixes

**If FAIL:**
Critical issues must be resolved before proceeding:
- Address all high severity issues listed above
- Run `/projspec.analyze` again after fixes
- Do not proceed to implementation until PASS status achieved

---

*Report generated by projspec analyze command*
*Run `/projspec.analyze` again after making changes to verify fixes*
```

### Step 6: Output Report

Display the analysis report to the user.

#### 6.1: Write Report to Console

Output the complete report to the console for immediate review.

The report should be displayed in full, formatted as Markdown for readability.

#### 6.2: Optionally Save Report

If the analysis found issues, offer to save the report:

```markdown
---

**Analysis Complete**

Would you like to save this report to the feature directory?
- Save location: ${FEATURE_DIR}/analysis-report.md
- Note: This is optional - the report has already been displayed above

To save: Confirm and I will write the report to a file.
To skip: No action needed, the analysis is complete.
```

**Important**: This command is non-destructive. It does NOT modify any existing artifacts (spec.md, plan.md, tasks.md, or data-model.md). It only reads and analyzes them.

#### 6.3: Display Summary Banner

After the full report, display a quick summary banner:

```
================================================================================
                         ANALYSIS COMPLETE
================================================================================

Feature: [FEATURE_ID]
Status:  [PASS | WARN | FAIL]

Issues:  [high_count] High  |  [medium_count] Medium  |  [low_count] Low

{If PASS:}
All artifacts are consistent. Ready for implementation.

{If WARN:}
Minor issues found. Review recommendations above.

{If FAIL:}
Critical issues found. Must resolve before proceeding.

================================================================================
```

## Output

Upon successful completion, this command produces:

- A detailed consistency analysis report displayed in the console
- Identification of all gaps, conflicts, and drift between artifacts
- Prioritized recommendations for resolving issues
- Traceability matrix showing requirement coverage
- Overall PASS/WARN/FAIL status for the feature artifacts

**Note**: This command is read-only and does not modify any files. To fix identified issues, manually update the appropriate artifacts and run `/projspec.analyze` again to verify.

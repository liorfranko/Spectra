---
description: "Generate an implementation plan from a feature specification"
user-invocable: true
---

# Plan Command

Execute the implementation planning workflow to generate design artifacts from a feature specification. This command transforms a validated spec.md into actionable technical documentation including research findings, data models, and implementation guidance.

## Prerequisites

This command requires a validated `spec.md` file to exist in the current feature directory.

Run the prerequisite check before proceeding:

```bash
$CLAUDE_PLUGIN_ROOT/scripts/check-prerequisites.sh --require-spec
```

If the check fails, use the `/speckit.specify` skill first to create the specification.

## Workflow

### Step 1: Check Prerequisites

Validate that spec.md exists and is properly formatted before proceeding with plan generation.

### Step 2: Phase 0 - Research

<!-- Placeholder for T023: Research phase implementation -->
Conduct technology research and gather relevant documentation to inform the implementation approach.

### Step 3: Phase 1 - Data Model

<!-- Placeholder for T024: Data model phase implementation -->
Define the data structures, schemas, and state management approach based on the specification requirements.

### Step 4: Technical Context

<!-- Placeholder for T025: Technical context implementation -->
Establish the technical environment, dependencies, and integration points for the feature.

### Step 5: Quickstart Guide

<!-- Placeholder for T026: Quickstart guide implementation -->
Generate a quickstart guide with setup instructions and initial implementation steps.

### Step 6: Constitution Check

<!-- Placeholder for T027: Constitution check implementation -->
Validate the plan against project constitution principles and architectural guidelines.

### Step 7: Project Structure

<!-- Placeholder for T028: Project structure implementation -->
Define the file and directory structure for the feature implementation.

## Output

Upon successful completion, this command generates:

- `research.md` - Technology research and documentation findings
- `data-model.md` - Data structures and state schemas
- `plan.md` - Complete implementation plan with technical context
- `quickstart.md` - Setup and getting started guide

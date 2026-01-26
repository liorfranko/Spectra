---
description: Create a structured feature specification from a natural language description
user-invocable: true
argument-hint: feature description
---

# Specify Command

Create or update a feature specification from a natural language feature description. This command transforms informal requirements into a structured spec.md document.

## Arguments

The `$ARGUMENTS` variable contains the feature description provided by the user. This should be a natural language description of the feature to be specified.

## Workflow Steps

<!-- T017: Add input validation step -->
<!-- Validate that $ARGUMENTS contains a feature description -->

<!-- T018: Add directory structure creation step -->
<!-- Create specs/{feature-id}/ directory if needed -->

<!-- T019: Add spec generation step -->
<!-- Generate structured spec.md from feature description -->

<!-- T020: Add clarification questions step -->
<!-- Identify ambiguities and prompt for clarification -->

<!-- T021: Add finalization step -->
<!-- Finalize spec and report results -->

## Output

Upon completion, this command will:
1. Create a structured specification document at `specs/{feature-id}/spec.md`
2. Report any clarification questions or ambiguities found
3. Provide a summary of the generated specification

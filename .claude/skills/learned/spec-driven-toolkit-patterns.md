# Spec-Driven Toolkit Patterns

## Context
Learned while creating the ProjSpec specification - a streamlined version of GitHub's spec-kit.

## Pattern: Prioritized User Stories as MVP Slices

When creating specifications for development toolkits:

1. **Each user story should be independently testable** - meaning implementing just that one story delivers value
2. **Priority ordering (P1, P2, P3) reflects dependency chain**:
   - P1: Foundation capabilities (init, specify) - must exist for anything else to work
   - P2: Value amplifiers (plan, tasks) - enhance P1 but not strictly required
   - P3: Polish features (implement guidance, constitution) - nice-to-have optimizations

## Pattern: Scope Simplification for Toolkit Forks

When creating a simplified version of an existing toolkit:

1. **Platform reduction** - Pick specific platforms (Mac/Linux only) rather than universal support
2. **Integration focus** - Pick one primary integration (Claude Code only) instead of multi-tool support
3. **Shell standardization** - Require bash-compatible shells to avoid cross-shell complexity

## Pattern: Measurable Success Criteria Without Implementation Details

Good success criteria for developer tools:
- "Developers can initialize in under 1 minute" (time-based)
- "90% of specs require 2 or fewer clarification rounds" (completion rate)
- "Tasks specific enough to complete without additional context 80% of time" (self-sufficiency)

Avoid:
- "API responds in 200ms" (too technical)
- "Uses efficient caching" (implementation detail)

## Pattern: Clean Reimplementation Specifications

When specifying a reimplementation of an existing tool (not a new product):

1. **Add Compatibility Requirements section** - Explicitly require same commands, prompts, and outputs
2. **Add Code Quality Requirements section** - Define the structural improvements that justify the rewrite
3. **Add Extensibility Criteria** - Measure how easy it is to add new features (e.g., "adding a step requires only new module + registration")
4. **Add explicit "Out of Scope" section** - Prevent scope creep by listing what's NOT being built
5. **Frame as foundation** - Clarify that future innovation comes AFTER achieving compatibility

Key distinction: The spec describes behavior compatibility, not feature innovation.

## When to Apply

- Creating specifications for CLI tools
- Designing developer workflow automation
- Simplifying complex multi-platform projects
- Reimplementing existing tools with cleaner architecture

# Data Model: Claude Code Spec Plugin

**Feature**: Claude Code Spec Plugin (speckit)
**Date**: 2026-01-26

## Overview

The speckit plugin operates on markdown files as its primary data format. This document defines the entities, their structure, relationships, and state transitions.

---

## Core Entities

### 1. Feature

A unit of work identified by number and short name, containing all related specification artifacts.

**Identifier Pattern**: `[###]-[short-name]` (e.g., `003-user-auth`)

**Storage Location**: `specs/[###]-[short-name]/`

**Attributes**:
| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| number | integer | Yes | Sequential, unique across all branches |
| shortName | string | Yes | 2-4 word kebab-case identifier |
| status | enum | Yes | Current workflow state |
| branch | string | Yes | Git branch name (matches identifier) |
| createdAt | date | Yes | ISO 8601 date |

**Status Values**:
- `draft` - Initial state after specification created
- `planned` - Implementation plan completed
- `tasked` - Tasks generated from plan
- `in-progress` - Implementation started
- `completed` - All tasks completed
- `archived` - Feature closed (completed or abandoned)

**State Transitions**:
```
draft → planned → tasked → in-progress → completed → archived
  ↓                                              ↑
  └─────────────────────────────────────────────┘
                   (archive without completing)
```

---

### 2. Specification (spec.md)

The "what" and "why" document capturing user scenarios, requirements, and success criteria.

**Storage Location**: `specs/[feature-id]/spec.md`

**Required Sections**:
| Section | Purpose |
|---------|---------|
| Feature Header | Branch, date, status, input description |
| User Scenarios & Testing | Prioritized user stories with acceptance criteria |
| Requirements | Functional requirements (FR-###) |
| Key Entities | Domain entities if data is involved |
| Success Criteria | Measurable outcomes (SC-###) |
| Assumptions | Documented assumptions made |

**Validation Rules**:
- All mandatory sections must be present
- No implementation details (languages, frameworks, APIs)
- Requirements must be testable (FR-### format)
- Success criteria must be measurable (SC-### format)
- Maximum 3 `[NEEDS CLARIFICATION]` markers allowed
- Edge cases section must be populated

---

### 3. Implementation Plan (plan.md)

The "how" document containing implementation phases, affected files, and technical approach.

**Storage Location**: `specs/[feature-id]/plan.md`

**Required Sections**:
| Section | Purpose |
|---------|---------|
| Summary | Primary requirement + technical approach |
| Technical Context | Language, dependencies, platform, constraints |
| Constitution Check | Validation against project principles |
| Project Structure | Documentation and source code layout |
| Complexity Tracking | Justification for any violations |

**Dependencies**:
- Requires: `spec.md` exists and passes validation
- Generates: `research.md` (Phase 0), `data-model.md`, `quickstart.md` (Phase 1)

---

### 4. Tasks (tasks.md)

Ordered list of actionable work items with dependencies and status tracking.

**Storage Location**: `specs/[feature-id]/tasks.md`

**Task Entity**:
| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Task identifier (e.g., T-001) |
| title | string | Yes | Imperative-form task description |
| description | string | No | Detailed task requirements |
| status | enum | Yes | pending, in-progress, completed |
| priority | enum | Yes | P1, P2, P3 |
| blockedBy | string[] | No | Task IDs this depends on |
| blocks | string[] | No | Task IDs that depend on this |

**Status Values**:
- `pending` - Not started
- `in-progress` - Currently being worked on
- `completed` - Finished
- `blocked` - Waiting on dependencies

**Validation Rules**:
- No circular dependencies allowed
- All dependencies must reference existing tasks
- P1 tasks should have no blockedBy (or only P1 tasks)

---

### 5. Checklist

Validation document for quality gates.

**Storage Location**: `specs/[feature-id]/checklists/[type].md`

**Types**:
- `requirements.md` - Specification quality validation
- `implementation.md` - Implementation readiness validation
- `pr-review.md` - Pull request review checklist

**Item Entity**:
| Attribute | Type | Description |
|-----------|------|-------------|
| item | string | Checklist item description |
| status | boolean | Checked (true) or unchecked (false) |
| notes | string | Optional notes for failed items |

---

### 6. Constitution

Project-level principles and constraints that all features must follow.

**Storage Location**: `.specify/memory/constitution.md`

**Sections**:
| Section | Purpose |
|---------|---------|
| Core Principles | Numbered principles (I, II, III, etc.) |
| Constraints | Technology, compliance, or policy limits |
| Development Workflow | Required processes |
| Governance | Amendment and override rules |

**Usage**:
- Checked during `/plan` (Constitution Check section)
- Violations must be justified in Complexity Tracking
- Cannot be overridden without explicit governance process

---

### 7. Session Context

Persistent context that carries across Claude Code sessions.

**Storage Location**: `.specify/memory/context.md`

**Sections**:
| Section | Purpose |
|---------|---------|
| Project Overview | What the project does |
| Architecture | Entry points, directories, data flow |
| Key Conventions | Naming, code style, testing patterns |
| Common Gotchas | Easy mistakes to avoid |
| Useful Commands | Frequently used commands |

---

### 8. Learning Observations

Auto-captured patterns from sessions for later analysis.

**Storage Location**: `.specify/learning/observations/[session-id]/`

**Files**:
| File | Purpose |
|------|---------|
| session-meta.json | Session metadata (start time, feature, etc.) |
| tools.jsonl | Tool usage patterns (JSON Lines format) |
| corrections.jsonl | User corrections to Claude's actions |

---

## Relationships

```
Constitution (1) ←──────────────────── Project
     │
     │ validates
     ▼
Feature (n)
     │
     ├── Specification (1) ─────────── spec.md
     │        │
     │        │ generates
     │        ▼
     ├── Plan (1) ──────────────────── plan.md
     │        │
     │        ├── research.md
     │        ├── data-model.md
     │        └── quickstart.md
     │        │
     │        │ generates
     │        ▼
     ├── Tasks (1) ─────────────────── tasks.md
     │        │
     │        │ converts to
     │        ▼
     │   GitHub Issues (n)
     │
     └── Checklists (n) ────────────── checklists/
```

---

## File Format Specifications

### YAML Frontmatter (Commands/Agents)

```yaml
---
description: Brief description
user-invocable: true
argument-hint: [optional-hint]
---
```

### JSON Hooks Configuration

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "script.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Session Metadata (JSON)

```json
{
  "sessionId": "uuid",
  "startTime": "2026-01-26T10:00:00Z",
  "feature": "003-feature-name",
  "branch": "003-feature-name"
}
```

---

## Validation Rules Summary

| Entity | Rule | Error Action |
|--------|------|--------------|
| Specification | No implementation details | Block plan generation |
| Specification | Max 3 NEEDS CLARIFICATION | Require clarify step |
| Plan | Constitution check passes | Block or require justification |
| Plan | Technical context complete | ERROR if missing |
| Tasks | No circular dependencies | ERROR on generation |
| Tasks | Valid priority ordering | WARN if P2 blocks P1 |
| Checklist | All items checked | Block next phase |

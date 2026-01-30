# Data Model: Rename Project to Spectra

**Feature**: Rename Project from ProjSpec to Spectra
**Date**: 2026-01-30

## Overview

This data model documents the entities affected by the rename operation. The rename is primarily a refactoring operation affecting naming conventions rather than data structures.

---

## Core Entities

### 1. Plugin

The Claude Code plugin package that provides spec-driven development capabilities.

**Identifier Pattern**: Plugin name in `plugin.json`

**Storage Location**: `spectra/plugins/spectra/.claude-plugin/plugin.json`

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | Plugin identifier, must be "spectra" |
| version | string | Yes | Semantic version, bump to 2.0.0 |
| description | string | Yes | Plugin description |
| author | object | Yes | Author information |

**Before → After**:
```json
// Before
{ "name": "projspec", "version": "1.0.12" }

// After
{ "name": "spectra", "version": "2.0.0" }
```

---

### 2. Command

A slash command provided by the plugin.

**Identifier Pattern**: `/spectra.<command-name>`

**Storage Location**: `spectra/plugins/spectra/commands/<command-name>.md`

**Attributes**:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| prefix | string | Yes | Must be "spectra" |
| name | string | Yes | Command name (specify, plan, tasks, etc.) |
| file | string | Yes | Markdown file defining the command |

**Commands to Update**:

| Command | Old Prefix | New Prefix |
|---------|------------|------------|
| specify | /projspec:specify | /spectra:specify |
| clarify | /projspec:clarify | /spectra:clarify |
| plan | /projspec:plan | /spectra:plan |
| tasks | /projspec:tasks | /spectra:tasks |
| implement | /projspec:implement | /spectra:implement |
| review-pr | /projspec:review-pr | /spectra:review-pr |
| accept | /projspec:accept | /spectra:accept |
| merge | /projspec:merge | /spectra:merge |
| cancel | /projspec:cancel | /spectra:cancel |
| analyze | /projspec:analyze | /spectra:analyze |
| constitution | /projspec:constitution | /spectra:constitution |
| issues | /projspec:issues | /spectra:issues |

---

### 3. Directory Structure

The file system layout of the plugin.

**Before**:
```
projspec/
├── plugins/
│   └── projspec/
│       ├── .claude-plugin/
│       ├── commands/
│       ├── agents/
│       ├── scripts/
│       ├── templates/
│       ├── memory/
│       └── hooks/
└── README.md
```

**After**:
```
spectra/
├── plugins/
│   └── spectra/
│       ├── .claude-plugin/
│       ├── commands/
│       ├── agents/
│       ├── scripts/
│       ├── templates/
│       ├── memory/
│       └── hooks/
└── README.md
```

---

## Relationships

```
Plugin (1) ─────────────────── Commands (n)
   │                               │
   │ contains                      │ uses prefix from
   │                               │
   ▼                               ▼
Directory Structure          Plugin.name
```

- **Plugin** contains multiple **Commands**
- **Commands** derive their prefix from **Plugin.name**
- **Directory Structure** must match **Plugin.name**

---

## File Mapping

Files requiring name changes:

| File Type | Location Pattern | Change Required |
|-----------|------------------|-----------------|
| plugin.json | `.claude-plugin/plugin.json` | Update `name` field |
| Commands | `commands/*.md` | Update `/projspec:` → `/spectra:` |
| Scripts | `scripts/*.sh` | Update path references |
| Templates | `templates/*.md` | Update example references |
| Agents | `agents/*.md` | Update description references |
| READMEs | `*.md` (root) | Update all branding |
| CLAUDE.md | `CLAUDE.md` | Update project description |

---

## Validation Rules Summary

| Entity | Rule | Error Action |
|--------|------|--------------|
| Plugin.name | Must equal "spectra" | Block release |
| Command.prefix | Must equal "spectra" | Block release |
| Directory | Must be named "spectra" | Block release |
| Documentation | No "projspec" references | Warn |

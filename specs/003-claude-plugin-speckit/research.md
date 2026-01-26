# Research: Claude Code Plugin Architecture

**Feature**: Claude Code Spec Plugin (speckit)
**Date**: 2026-01-26
**Purpose**: Document technical decisions and patterns for building a Claude Code plugin

## Research Summary

This document captures the research findings for building the "speckit" plugin that automates specification-driven development workflows within Claude Code.

---

## 1. Plugin Directory Structure

**Decision**: Use standard Claude Code plugin structure with `.claude-plugin/plugin.json` manifest

**Rationale**: This is the official documented pattern for Claude Code plugins. The plugin manifest lives in `.claude-plugin/` while all other components (commands, agents, hooks, scripts) live at the plugin root level.

**Alternatives Considered**:
- Monolithic single-file plugin: Rejected because it doesn't support multiple commands, agents, and hooks
- Custom directory structure: Rejected because it would require custom loading logic

**Key Pattern**:
```
speckit/
├── .claude-plugin/
│   └── plugin.json          # Only manifest goes here
├── commands/                 # Slash commands
├── agents/                   # Subagents
├── hooks/                    # Hook configurations
├── scripts/                  # Utility scripts
├── templates/                # Document templates
└── memory/                   # Persistent context
```

---

## 2. Plugin Manifest (plugin.json)

**Decision**: Minimal manifest with explicit paths to components

**Rationale**: Claude Code auto-discovers components in standard directories. Explicit paths provide clarity and allow custom locations if needed.

**Schema**:
```json
{
  "name": "speckit",
  "version": "1.0.0",
  "description": "Specification-driven development workflow automation",
  "commands": "./commands/",
  "agents": "./agents/",
  "hooks": "./hooks/hooks.json"
}
```

**Key Fields**:
- `name`: Kebab-case identifier, becomes command namespace (`/speckit:command`)
- `version`: Semantic versioning for updates
- `commands`: Path to commands directory
- `agents`: Path to agents directory
- `hooks`: Path to hooks configuration

---

## 3. Command Structure

**Decision**: Use markdown files with YAML frontmatter for command definitions

**Rationale**: This is the Claude Code standard for defining slash commands. Markdown content becomes the system prompt for the command.

**Pattern**:
```markdown
---
description: Brief description for autocomplete/help
user-invocable: true
argument-hint: [optional-arg-hint]
---

# Command Name

Command instructions and workflow steps...

Use $ARGUMENTS to reference user input.
```

**Key Frontmatter Fields**:
| Field | Purpose |
|-------|---------|
| `description` | Shown in autocomplete, used by Claude to decide when to invoke |
| `user-invocable` | If false, hidden from `/` menu |
| `argument-hint` | Placeholder text in command autocomplete |
| `disable-model-invocation` | If true, prevents auto-invocation by Claude |

---

## 4. Agent Structure

**Decision**: Use markdown files with YAML frontmatter for agent definitions

**Rationale**: Agents are isolated subagents that can be invoked by Claude for specific tasks. They run in separate context from the main conversation.

**Pattern**:
```markdown
---
name: agent-name
description: When to use this agent
tools: Read, Write, Edit, Bash
model: sonnet
---

# Agent Name

System prompt for the agent...

## Capabilities
- What this agent does

## Approach
- How it accomplishes tasks
```

**Key Frontmatter Fields**:
| Field | Purpose |
|-------|---------|
| `name` | Agent identifier |
| `description` | When Claude should delegate to this agent |
| `tools` | Allowed tools (inherits all if omitted) |
| `model` | sonnet, opus, haiku, or inherit |

---

## 5. Hook System

**Decision**: Use JSON configuration for hooks with bash scripts for complex logic

**Rationale**: Hooks enable automation around tool events. JSON config is simpler; bash scripts handle complex validation.

**Available Hook Events**:
| Event | When Fired | Use Case |
|-------|------------|----------|
| `SessionStart` | Session begins | Load context |
| `PreToolUse` | Before tool execution | Validate/block actions |
| `PostToolUse` | After tool succeeds | Post-processing |
| `Stop` | Claude finishes | Check completion |
| `SessionEnd` | Session terminates | Save state |

**Pattern** (hooks/hooks.json):
```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/session-start.sh"
      }]
    }],
    "PreToolUse": [{
      "matcher": "Write",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-write.sh"
      }]
    }]
  }
}
```

**Exit Codes**:
- `0`: Success
- `2`: Block action (PreToolUse, Stop only)
- Other: Non-blocking error

---

## 6. Script Patterns

**Decision**: Use bash scripts for all utility operations (macOS/Linux only as per requirements)

**Rationale**: Bash is universally available on macOS/Linux, requires no additional runtime, and integrates well with git operations.

**Key Scripts**:
| Script | Purpose |
|--------|---------|
| `create-new-feature.sh` | Create feature branch and spec directory |
| `setup-plan.sh` | Initialize plan workflow |
| `check-prerequisites.sh` | Validate git, gh CLI, etc. |
| `update-agent-context.sh` | Update agent context files |

**Pattern**:
- Scripts receive JSON via stdin from hooks
- Use `jq` for JSON parsing
- Use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths
- Return JSON output when needed (parse via `--json` flag)

---

## 7. Template System

**Decision**: Store templates as markdown files in `templates/` directory

**Rationale**: Templates define the structure of generated artifacts. Markdown format allows easy editing and Claude can fill placeholders intelligently.

**Templates Needed**:
| Template | Purpose |
|----------|---------|
| `spec-template.md` | Feature specification structure |
| `plan-template.md` | Implementation plan structure |
| `tasks-template.md` | Tasks list structure |
| `checklist-template.md` | Validation checklist structure |

**Placeholder Pattern**:
- Use `[PLACEHOLDER_NAME]` for required values
- Use `$ARGUMENTS` for user input in commands
- Use markdown comments for instructions to Claude

---

## 8. File Organization Strategy

**Decision**: Separate runtime files (`.specify/`) from plugin distribution (`speckit/`)

**Rationale**: The plugin package should be distributable without project-specific files. Runtime files are created when the plugin is used.

**Plugin Package** (distributable):
```
speckit/
├── .claude-plugin/plugin.json
├── commands/
├── agents/
├── hooks/
├── scripts/
└── templates/
```

**Runtime Files** (project-specific, created by plugin):
```
.specify/                    # Created in user's project
├── memory/
│   ├── constitution.md
│   └── context.md
├── sessions/
├── learning/
├── hooks/                   # Copied from templates
└── scripts/                 # Copied from templates

specs/                       # Created in user's project
└── [feature-number]-[feature-name]/
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    └── checklists/
```

---

## 9. Git Integration

**Decision**: Use git worktrees for feature isolation

**Rationale**: Worktrees allow multiple feature branches to be worked on simultaneously without switching branches.

**Workflow**:
1. User invokes `/speckit:specify "feature description"`
2. Script determines next feature number (highest across all branches + 1)
3. Create worktree: `git worktree add ../worktrees/[###]-[short-name] -b [###]-[short-name]`
4. Create spec directory: `specs/[###]-[short-name]/`
5. Initialize spec.md from template

---

## 10. Command Workflow Dependencies

**Decision**: Commands validate prerequisites before execution

**Rationale**: Prevents errors and guides users through the correct workflow sequence.

**Dependency Chain**:
```
specify → plan → tasks → implement
    ↓         ↓       ↓
 clarify   analyze  issues
    ↓
checklist
```

**Validation Pattern**:
- `/plan` requires `spec.md` exists
- `/tasks` requires `plan.md` exists
- `/implement` requires `tasks.md` exists
- `/issues` requires `tasks.md` exists
- `/analyze` requires all three artifacts

---

## 11. Testing Strategy

**Decision**: Manual testing via Claude Code CLI with `--plugin-dir` flag

**Rationale**: Plugins run within Claude Code's runtime; automated testing of LLM interactions is not practical.

**Testing Approach**:
```bash
# Test during development
claude --plugin-dir ./speckit

# Verify commands appear in help
/help

# Test each command in sequence
/speckit:specify "Test feature"
/speckit:plan
/speckit:tasks
```

---

## 12. Distribution Strategy

**Decision**: Distribute as Git repository, install via Claude Code plugin marketplace or local path

**Rationale**: Git provides versioning; local installation allows easy development iteration.

**Installation Methods**:
1. **Local development**: `claude --plugin-dir /path/to/speckit`
2. **Git install**: Configure in `.claude/settings.json`:
   ```json
   {
     "plugins": [
       { "source": "github:user/speckit", "version": "v1.0.0" }
     ]
   }
   ```

---

## Resolved Clarifications

| Unknown | Resolution | Source |
|---------|------------|--------|
| Plugin structure | `.claude-plugin/plugin.json` + root-level components | Claude Code documentation |
| Command format | Markdown with YAML frontmatter | Claude Code plugin guide |
| Hook system | JSON config with bash scripts | Claude Code documentation |
| Agent format | Markdown with YAML frontmatter | Claude Code plugin guide |
| Testing approach | Manual via `--plugin-dir` flag | Claude Code CLI documentation |

---

## References

- Claude Code Plugin Architecture Guide (researched via claude-code-guide agent)
- Existing speckit implementation in current worktree (.claude/commands/*.md)
- Claude Code CLI documentation

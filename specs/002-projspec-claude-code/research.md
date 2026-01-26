# Research: ProjSpec Technology Decisions

**Feature**: 002-projspec-claude-code
**Date**: 2026-01-26
**Purpose**: Resolve all technical decisions before implementation

## 1. Python CLI Framework

### Decision: Typer + Rich + Pydantic

**Rationale**: This is the exact stack used by spec-kit, ensuring compatibility and leveraging proven patterns.

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|------------------|
| Click | Typer is built on Click with type hints, more modern |
| Argparse | More verbose, less readable output |
| Fire | Less control over help text and validation |

**Best Practices**:
- Use Typer's callback pattern for subcommands
- Leverage Rich for all terminal output (tables, panels, progress)
- Use Pydantic models for configuration validation
- Keep CLI layer thin - delegate to services

**Source Files from spec-kit**:
- `src/specify_cli/__main__.py` - Entry point pattern
- `src/specify_cli/cli.py` - Command structure

## 2. Command Prompt Templates (No Plugin)

### Decision: Markdown prompt templates instead of Claude Code plugin

**Rationale**: Simpler distribution, no plugin installation required, works with any Claude Code version.

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|------------------|
| Claude Code Plugin | Adds complexity, requires plugin installation, version compatibility concerns |
| Bash wrapper scripts | Less flexible, can't leverage Claude's context understanding |
| External CLI tool | Requires separate process, loses Claude session context |

**Template Location**:
```
.specify/templates/commands/
├── analyze.md           # Cross-artifact consistency check
├── checklist.md         # Generate quality checklist
├── clarify.md           # Resolve spec ambiguities
├── constitution.md      # Create/update constitution
├── implement.md         # Execute tasks sequentially
├── plan.md              # Generate implementation plan
├── specify.md           # Create feature specification
├── tasks.md             # Generate task breakdown
└── taskstoissues.md     # Convert tasks to GitHub issues
```

**Usage Pattern**:
```bash
# User asks Claude to read the command template
"Read .specify/templates/commands/specify.md and follow those instructions"

# Or user copies template content directly into Claude session
```

**Template Structure**:
```markdown
# Command: [name]

## Purpose
[What this command does]

## Prerequisites
[Required state before running]

## Workflow
1. [Step 1]
2. [Step 2]
...

## Output
[What gets created/modified]
```

## 3. Directory Structure Conventions

### Decision: Use `.specify/` as the runtime directory name

**Rationale**: Maintains compatibility with spec-kit's established structure while allowing future differentiation.

**Directory Layout**:
```
project-root/
├── .specify/                    # Runtime configuration
│   ├── memory/
│   │   └── constitution.md      # Project governance
│   ├── scripts/
│   │   └── bash/                # Shell utilities
│   └── templates/               # Document templates
└── specs/                       # Feature specifications
    ├── 001-feature-a/
    │   ├── spec.md
    │   ├── plan.md
    │   ├── research.md
    │   ├── data-model.md
    │   ├── quickstart.md
    │   ├── contracts/
    │   └── tasks.md
    └── 002-feature-b/
        └── ...
```

## 4. Feature Numbering and Branch Naming

### Decision: 3-digit sequential numbering with slugified names

**Rationale**: Matches spec-kit's system for consistency.

**Pattern**: `NNN-feature-name`
- NNN: Zero-padded 3-digit number (001, 002, ..., 999)
- feature-name: Slugified from description (lowercase, hyphens, no stop words)

**Implementation**:
- Scan existing `specs/` directories to find next number
- Convert feature description to slug:
  - Lowercase
  - Replace spaces with hyphens
  - Remove stop words (the, a, an, in, on, for, to, of, and, with)
  - Truncate to fit GitHub's 244-byte branch limit

## 5. Git Worktrees (Feature Isolation)

### Decision: Use git worktrees by default for each feature

**Rationale**: Worktrees provide complete filesystem isolation, enabling parallel work on multiple features without stashing or switching branches.

**Alternatives Considered**:
| Alternative | Rejected Because |
|-------------|------------------|
| Branch switching | Requires stashing, loses context, can't work on multiple features |
| Separate clones | Heavy on disk, no shared git history, harder to merge |
| Stash-based workflow | Easy to lose work, confusing with multiple stashes |

**Worktree Layout**:
```
project-root/              # Main repository (typically on main branch)
├── .git/                  # Shared git database
├── .specify/              # Shared configuration
├── specs/                 # Shared specs directory
└── worktrees/             # Feature worktrees
    ├── 001-user-auth/     # Worktree for feature 001
    │   ├── .git           # Worktree git link (file, not directory)
    │   ├── specs -> ../../specs  # Symlink to shared specs
    │   └── [source files] # Feature-specific code
    └── 002-api-redesign/  # Worktree for feature 002
        └── ...
```

**Key Commands**:
```bash
# Create worktree for new feature
git worktree add worktrees/001-user-auth -b 001-user-auth

# List all worktrees
git worktree list

# Remove worktree (after merge)
git worktree remove worktrees/001-user-auth

# Prune stale worktrees
git worktree prune
```

**Specs Directory Strategy**:
- `specs/` is shared across all worktrees via symlink
- Each feature's spec is in `specs/NNN-feature-name/`
- This ensures spec artifacts are always accessible from main repo
- Worktrees contain only source code changes

**Benefits**:
1. **Complete isolation**: Each feature has its own working directory
2. **Parallel work**: Work on multiple features simultaneously
3. **No stash juggling**: Never lose uncommitted work
4. **Clean context**: Claude Code sees only one feature's changes
5. **Easy cleanup**: Remove worktree after merge, branch cleanup automatic

**Implementation in Scripts**:
- `create-new-feature.sh` creates worktree + branch + spec directory
- `archive-feature.sh` merges branch, removes worktree, cleans up
- Worktree detection in `common.sh` for context-aware operations

## 6. State Management

### Decision: YAML files for state, Markdown for content

**Rationale**: Human-readable, git-friendly, spec-kit compatible.

**State Files**:
- `state.yaml` - Feature phase and task status (per feature)
- `config.yaml` - Project configuration (in `.specify/`)

**Content Files**:
- `spec.md` - Feature specification
- `plan.md` - Implementation plan
- `tasks.md` - Task breakdown
- `research.md`, `data-model.md`, `quickstart.md` - Supporting docs

## 7. Bash Script Utilities

### Decision: Bourne Again Shell (Bash 4.0+)

**Rationale**: Mac/Linux only, no PowerShell needed.

**Key Scripts**:
| Script | Purpose |
|--------|---------|
| `common.sh` | Shared functions (get_repo_root, get_current_branch, etc.) |
| `check-prerequisites.sh` | Validate feature state before operations |
| `create-new-feature.sh` | Create branch, directory, initialize spec |
| `setup-plan.sh` | Initialize plan.md from template |
| `update-agent-context.sh` | Refresh CLAUDE.md with technology context |

**Best Practices**:
- Source `common.sh` in all scripts
- Support `--json` output for programmatic use
- Use `set -euo pipefail` for strict error handling
- Quote all variables to prevent word splitting

## 8. Testing Strategy

### Decision: pytest for Python, manual workflow testing for scripts

**Rationale**: Python code is testable; bash scripts are validated through integration tests.

**Test Structure**:
```
tests/
├── unit/
│   ├── test_cli.py          # CLI command tests (mocked)
│   ├── test_models.py       # Pydantic model validation
│   └── test_services.py     # Service logic tests
├── integration/
│   ├── test_init.py         # Full init workflow
│   └── test_workflow.py     # E2E workflow tests
└── conftest.py              # Fixtures and helpers
```

**Coverage Goals**:
- Python CLI: 80%+ coverage
- Integration tests cover all user stories

## 9. Dependency Management

### Decision: pyproject.toml with hatchling build backend

**Rationale**: Modern Python packaging, matches spec-kit.

**Dependencies**:
```toml
[project]
dependencies = [
    "typer>=0.9.0",
    "rich>=13.0.0",
    "pydantic>=2.0.0",
    "platformdirs>=3.0.0",
    "pyyaml>=6.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
]
```

## 10. Installation Methods

### Decision: uv tool install (primary), pip (fallback)

**Rationale**: uv is fast and recommended; pip as universal fallback.

**Installation Commands**:
```bash
# Recommended
uv tool install projspec-cli

# Alternative
pip install projspec-cli

# Development
uv pip install -e ".[dev]"
```

## 11. Error Handling Strategy

### Decision: Fail fast with actionable messages

**Rationale**: SC-009 requires clear, actionable error messages.

**Patterns**:
- Use Rich panels for error display
- Include "What happened", "What to do", and optional context
- Exit with non-zero codes for CI/script integration
- Log verbose details only in debug mode

**Example**:
```python
console.print(Panel(
    "[red]Error: Feature branch not found[/red]\n\n"
    "The branch '003-user-auth' does not exist.\n\n"
    "[dim]Try: projspec new user-auth[/dim]",
    title="Branch Error",
    border_style="red"
))
raise typer.Exit(1)
```

---

## Summary of Technology Choices

| Aspect | Decision | Spec-Kit Alignment |
|--------|----------|-------------------|
| CLI Framework | Typer + Rich + Pydantic | ✅ Identical |
| Command Delivery | Prompt templates (no plugin) | ⚡ Simplified (spec-kit uses plugin) |
| Directory Structure | `.specify/` and `specs/` | ✅ Identical |
| Feature Numbering | 3-digit sequential | ✅ Identical |
| Git Isolation | Worktrees by default | ⚡ Enhanced (spec-kit uses optional worktrees) |
| State Storage | YAML + Markdown | ✅ Identical |
| Shell Scripts | Bash 4.0+ | ⚡ Simplified (no PowerShell) |
| Testing | pytest | ✅ Identical |
| Packaging | pyproject.toml + hatchling | ✅ Identical |
| Installation | uv tool install | ✅ Identical |

All NEEDS CLARIFICATION items have been resolved through analysis of spec-kit's implementation.

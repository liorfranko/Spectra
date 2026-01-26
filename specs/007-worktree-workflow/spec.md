# Feature Specification: Worktree-Based Feature Workflow

**Feature Branch**: `007-worktree-workflow`
**Created**: 2026-01-26
**Status**: Draft
**Input**: User description: "change the behavior from working with branches to work with worktree"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start New Feature in Dedicated Worktree (Priority: P1)

A developer invokes the `/projspec.specify` command to create a new feature. The system creates a git worktree with the feature branch checked out, placing all feature-specific work in an isolated directory while keeping specs in the shared main repository.

**Why this priority**: This is the entry point to the entire workflow. Without a clear worktree creation process, developers cannot work on features in isolation.

**Independent Test**: Can be fully tested by running `/projspec.specify` and verifying a new worktree is created at `worktrees/<feature-name>/` with the feature branch checked out and spec files in the worktree's specs directory.

**Acceptance Scenarios**:

1. **Given** a developer invokes `/projspec.specify` with a feature description, **When** the feature is created, **Then** a new worktree is created at `worktrees/<NNN-feature-name>/` with the feature branch checked out.

2. **Given** a worktree is created, **When** the developer examines the worktree directory, **Then** they find the feature spec at `specs/<NNN-feature-name>/spec.md` ready to be committed to the feature branch.

3. **Given** a worktree exists, **When** the developer navigates to it and runs `git branch`, **Then** the feature branch `NNN-feature-name` is shown as the current branch.

---

### User Story 2 - Execute Commands from Worktree Context (Priority: P1)

A developer working in a worktree invokes projspec commands (e.g., `/projspec.plan`, `/projspec.implement`). The system correctly identifies the worktree context and executes scripts from the main repository while operating on files in the appropriate locations.

**Why this priority**: Commands must work seamlessly from worktrees for developers to adopt the worktree workflow. This is critical for day-to-day development.

**Independent Test**: Can be tested by navigating to a worktree and running `/projspec.plan`, verifying it correctly reads specs from the symlinked directory and creates plan artifacts.

**Acceptance Scenarios**:

1. **Given** a developer is working in a worktree, **When** they run `/projspec.plan`, **Then** the script correctly locates and reads the feature spec from the symlinked specs directory.

2. **Given** a developer runs a command from a worktree, **When** the script needs to access `.specify/` resources (templates, scripts), **Then** it correctly resolves paths to the main repository.

3. **Given** a developer runs `/projspec.implement` from a worktree, **When** tasks create/modify source files, **Then** changes are made in the worktree directory (not the main repo).

---

### User Story 3 - Navigate Between Worktrees (Priority: P2)

A developer wants to switch between different features or return to the main repository. The system provides clear guidance on worktree locations and navigation without losing work.

**Why this priority**: Multi-feature workflows require easy navigation. This improves developer experience but is not blocking for basic single-feature work.

**Independent Test**: Can be tested by creating two features, verifying both worktrees exist independently, and confirming changes in one don't affect the other.

**Acceptance Scenarios**:

1. **Given** multiple worktrees exist, **When** the developer lists worktrees (`git worktree list`), **Then** all feature worktrees are displayed with their paths and branches.

2. **Given** a developer is in worktree A, **When** they navigate to worktree B (via `cd`), **Then** they are now in a different branch context with isolated changes.

3. **Given** a developer has uncommitted changes in a worktree, **When** they navigate to another worktree, **Then** changes in the first worktree are preserved (not lost or mixed).

---

### User Story 4 - Clean Up Completed Feature Worktrees (Priority: P3)

After a feature is merged, a developer wants to clean up the associated worktree. The system provides guidance or automation for removing worktrees while preserving specs (if needed) and branches.

**Why this priority**: Cleanup prevents disk clutter but is a post-feature operation that doesn't block development.

**Independent Test**: Can be tested by creating a worktree, then removing it with `git worktree remove`, and verifying specs remain in the shared directory.

**Acceptance Scenarios**:

1. **Given** a completed feature worktree exists, **When** the developer removes it with `git worktree remove worktrees/<feature>`, **Then** the worktree directory is deleted but specs remain in `specs/<feature>/`.

2. **Given** a worktree is removed, **When** the developer checks `git worktree list`, **Then** the removed worktree no longer appears.

3. **Given** a worktree has uncommitted changes, **When** the developer attempts to remove it, **Then** the system warns about uncommitted work and requires confirmation.

---

### Edge Cases

- What happens when a developer tries to checkout a feature branch in the main repo that's already checked out in a worktree? Git returns `fatal: 'branch' is already checked out` error - this is expected behavior and the user should be directed to use the worktree.
- How does the system handle running commands from the main repository instead of a worktree? Commands should detect context and provide helpful guidance to navigate to the appropriate worktree.
- How does the system handle worktree paths with special characters or spaces? Worktree paths should be sanitized to use only alphanumeric characters and hyphens.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create git worktrees in `worktrees/<NNN-feature-name>/` directory when starting a new feature
- **FR-002**: System MUST create the feature spec directory at `worktrees/<NNN-feature-name>/specs/<NNN-feature-name>/` for commits to the feature branch
- **FR-003**: System MUST display worktree path and navigation instructions after feature creation
- **FR-004**: All projspec scripts MUST correctly resolve paths when executed from a worktree context
- **FR-005**: Scripts MUST access `.specify/` resources (templates, scripts, memory) from the repository root
- **FR-006**: Source code modifications during `/projspec.implement` MUST occur in the worktree directory, not the main repository
- **FR-007**: Documentation and command help MUST use "worktree" terminology instead of "branch" where appropriate
- **FR-008**: Specs MUST be committed to the feature branch and merged via PR to main
- **FR-009**: The `.specify/scripts/bash/common.sh` MUST provide reliable worktree detection and path resolution functions
- **FR-010**: Commands executed from main repository context MUST detect if they should be run from a worktree and provide guidance

### Key Entities

- **Worktree**: An isolated working directory containing a checkout of a feature branch, located at `worktrees/<feature-name>/`
- **Main Repository**: The primary git repository containing configuration (`.specify/`) and shared scripts
- **Feature Specs**: Specification files located at `worktree/specs/<feature-name>/`, committed to the feature branch
- **Feature Context**: The combination of worktree path, branch name, and spec directory that defines where a feature's work happens

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can create a new feature and be working in an isolated worktree in under 1 minute
- **SC-002**: 100% of projspec commands work correctly when executed from a worktree context
- **SC-003**: Developers can work on multiple features simultaneously without any cross-contamination of changes
- **SC-004**: No data loss occurs when navigating between worktrees with uncommitted changes
- **SC-005**: Documentation accurately describes worktree workflow with zero references to "checkout branch" for feature work
- **SC-006**: Specs are properly merged to main via PR when feature is complete

## Assumptions

- Git version 2.5+ is available (worktrees were introduced in 2.5)
- Developers have sufficient disk space for multiple worktrees
- The project structure follows the standard layout with `worktrees/` and `specs/` at repository root
- The `.specify/` directory is shared across worktrees (part of the git checkout)
- Specs are committed to feature branches and merged to main via PRs

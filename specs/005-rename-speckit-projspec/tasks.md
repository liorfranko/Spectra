# Tasks: Rename SpecKit to ProjSpec

**Input**: Design documents from `/specs/005-rename-speckit-projspec/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/rename-mapping.md

**Tests**: Not requested for this refactoring task. Validation is via grep commands and command execution.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a plugin/configuration refactoring task. Paths reference:
- `speckit/` → `projspec/` (plugin root)
- `.claude/commands/` (command shortcuts)
- `CLAUDE.md` (project metadata)

---

## Phase 1: Setup (Directory Renames)

**Purpose**: Rename directory structure before file-level changes

- [x] T001 Rename outer plugin directory using `git mv speckit projspec`
- [x] T002 Rename inner plugin directory using `git mv projspec/plugins/speckit projspec/plugins/projspec`

---

## Phase 2: Foundational (Command File Renames)

**Purpose**: Rename all command files to establish new command entry points

**CRITICAL**: Must complete before content updates to avoid broken references

- [x] T003 [P] Rename `.claude/commands/speckit.analyze.md` to `.claude/commands/projspec.analyze.md`
- [x] T004 [P] Rename `.claude/commands/speckit.checklist.md` to `.claude/commands/projspec.checklist.md`
- [x] T005 [P] Rename `.claude/commands/speckit.clarify.md` to `.claude/commands/projspec.clarify.md`
- [x] T006 [P] Rename `.claude/commands/speckit.constitution.md` to `.claude/commands/projspec.constitution.md`
- [x] T007 [P] Rename `.claude/commands/speckit.implement.md` to `.claude/commands/projspec.implement.md`
- [x] T008 [P] Rename `.claude/commands/speckit.learn.md` to `.claude/commands/projspec.learn.md`
- [x] T009 [P] Rename `.claude/commands/speckit.plan.md` to `.claude/commands/projspec.plan.md`
- [x] T010 [P] Rename `.claude/commands/speckit.review-pr.md` to `.claude/commands/projspec.review-pr.md`
- [x] T011 [P] Rename `.claude/commands/speckit.specify.md` to `.claude/commands/projspec.specify.md`
- [x] T012 [P] Rename `.claude/commands/speckit.tasks.md` to `.claude/commands/projspec.tasks.md`
- [x] T013 [P] Rename `.claude/commands/speckit.taskstoissues.md` to `.claude/commands/projspec.taskstoissues.md`
- [x] T014 [P] Rename `.claude/commands/speckit.checkpoint.md` to `.claude/commands/projspec.checkpoint.md`

**Checkpoint**: All command files renamed. Directory structure complete.

---

## Phase 3: User Story 1 - Use ProjSpec Commands (Priority: P1)

**Goal**: All slash commands work with `/projspec.*` prefix and contain correct internal references

**Independent Test**: Run `/projspec.specify "test"`, `/projspec.plan`, `/projspec.tasks` and verify all execute correctly

### Update Plugin Configuration

- [x] T016 [US1] Update `projspec/.claude-plugin/marketplace.json`: change `"name": "speckit"` to `"name": "projspec"`
- [x] T017 [US1] Update `projspec/.claude-plugin/marketplace.json`: change `"source": "./plugins/speckit"` to `"source": "./plugins/projspec"`
- [x] T018 [US1] Update `projspec/plugins/projspec/.claude-plugin/plugin.json`: change `"name": "speckit"` to `"name": "projspec"`

### Update Command Content - Root Commands (13 files)

- [x] T019 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.analyze.md`
- [x] T020 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.checklist.md`
- [x] T021 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.clarify.md`
- [x] T022 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.constitution.md`
- [x] T023 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.implement.md`
- [x] T024 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.learn.md`
- [x] T025 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.plan.md`
- [x] T026 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.review-pr.md`
- [x] T027 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.specify.md`
- [x] T028 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.tasks.md`
- [x] T029 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.taskstoissues.md`
- [x] T030 [P] [US1] Update `/speckit.` → `/projspec.` references in `.claude/commands/projspec.checkpoint.md`

### Update Command Content - Plugin Commands (14 files)

- [x] T032 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/analyze.md`
- [x] T033 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/checklist.md`
- [x] T034 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/clarify.md`
- [x] T035 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/constitution.md`
- [x] T036 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/implement.md`
- [x] T037 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/plan.md`
- [x] T038 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/review-pr.md`
- [x] T039 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/specify.md`
- [x] T040 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/tasks.md`
- [x] T041 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/issues.md`
- [x] T043 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/checkpoint.md` (if exists)
- [x] T044 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/commands/learn.md` (if exists)

### Update Template Files

- [x] T045 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/templates/plan-template.md`
- [x] T046 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/templates/tasks-template.md`
- [x] T047 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/templates/spec-template.md`
- [x] T048 [P] [US1] Update `/speckit.` → `/projspec.` references in `projspec/plugins/projspec/templates/checklist-template.md`
- [x] T049 [P] [US1] Review and update `projspec/plugins/projspec/templates/agent-file-template.md` for speckit references

**Checkpoint**: User Story 1 complete. All commands should execute with `/projspec.*` prefix.

---

## Phase 4: User Story 2 - Install and Configure Plugin (Priority: P2)

**Goal**: Plugin appears as "projspec" in all configuration and discovery systems

**Independent Test**: Verify plugin.json and marketplace.json show "projspec" via `jq` commands

### Verification Tasks

- [x] T050 [US2] Verify `jq '.name' projspec/.claude-plugin/marketplace.json` returns "projspec"
- [x] T051 [US2] Verify `jq '.source' projspec/.claude-plugin/marketplace.json` returns "./plugins/projspec"
- [x] T052 [US2] Verify `jq '.name' projspec/plugins/projspec/.claude-plugin/plugin.json` returns "projspec"

**Checkpoint**: User Story 2 complete. Plugin configuration verified.

---

## Phase 5: User Story 3 - Reference Documentation and Files (Priority: P3)

**Goal**: All user-facing documentation references "projspec" or "ProjSpec"

**Independent Test**: `grep -r "speckit" projspec/` returns zero matches (excluding historical specs)

### Update Script Comments

- [x] T053 [P] [US3] Update `# speckit/` → `# projspec/` in `projspec/plugins/projspec/scripts/common.sh`
- [x] T054 [P] [US3] Update `# speckit/` → `# projspec/` in `projspec/plugins/projspec/scripts/setup-hooks.sh`
- [x] T055 [P] [US3] Update `# speckit/` → `# projspec/` in `projspec/plugins/projspec/scripts/setup-plan.sh`
- [x] T056 [P] [US3] Update `# speckit/` → `# projspec/` in `projspec/plugins/projspec/scripts/check-prerequisites.sh`
- [x] T057 [P] [US3] Update `# speckit/` → `# projspec/` in `projspec/plugins/projspec/scripts/update-agent-context.sh`
- [x] T058 [P] [US3] Update `# speckit/` → `# projspec/` in `projspec/plugins/projspec/scripts/create-new-feature.sh`

### Update Documentation Files

- [x] T059 [US3] Update `projspec/README.md`: change title `# speckit` → `# projspec` and all `/speckit.*` → `/projspec.*`
- [x] T060 [US3] Update `projspec/README.md`: change all `SpecKit` → `ProjSpec` product name references
- [x] T061 [P] [US3] Update `projspec/TESTING.md`: change all speckit references to projspec
- [x] T062 [P] [US3] Update `projspec/VERIFICATION.md`: change all speckit references to projspec

### Update Project Metadata

- [x] T063 [US3] Update `CLAUDE.md`: change `speckit/` → `projspec/` in project structure section

**Checkpoint**: User Story 3 complete. All documentation references projspec.

---

## Phase 6: Polish & Validation

**Purpose**: Final validation and cleanup

### Validation

- [x] T064 Run validation: `find .claude/commands -name "speckit*"` returns empty
- [x] T065 Run validation: `grep -rc "speckit" .claude/commands/ | grep -v ":0$"` returns empty
- [x] T066 Run validation: `grep -rc "speckit" projspec/ | grep -v ":0$"` returns empty
- [x] T067 Run validation: `grep -r '"speckit"' projspec/.claude-plugin/ projspec/plugins/projspec/.claude-plugin/` returns empty

### Functional Testing

- [ ] T068 Execute `/projspec.specify "validation test"` and verify workflow starts (manual)
- [ ] T069 Execute `/projspec.plan` and verify planning workflow runs (manual)
- [ ] T070 Execute `/projspec.tasks` and verify task generation works (manual)

### Cleanup

- [x] T071 Commit all changes with descriptive message
- [x] T072 Update session file with completion status

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - all file renames must complete before content updates
- **User Story 1 (Phase 3)**: Depends on Foundational - command files must exist before updating content
- **User Story 2 (Phase 4)**: Depends on Phase 3 T016-T018 (config updates)
- **User Story 3 (Phase 5)**: Can run in parallel with Phase 4 after Phase 3 completes
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 completion only
- **User Story 2 (P2)**: Subset of US1 - config verification only
- **User Story 3 (P3)**: Independent of US1/US2 - can run in parallel after Phase 2

### Within Each User Story

- Config updates (T016-T018) before content updates
- All [P] tasks within a story can run in parallel
- Validation at each checkpoint

### Parallel Opportunities

- **Phase 2**: All 13 file renames (T003-T015) can run in parallel
- **Phase 3**: All root command updates (T019-T031) can run in parallel
- **Phase 3**: All plugin command updates (T032-T044) can run in parallel
- **Phase 3**: All template updates (T045-T049) can run in parallel
- **Phase 5**: All script updates (T053-T058) can run in parallel
- **Phase 5**: Doc updates T061-T062 can run in parallel

---

## Parallel Example: Phase 2 (File Renames)

```bash
# All file renames can execute in parallel:
git mv .claude/commands/speckit.analyze.md .claude/commands/projspec.analyze.md
git mv .claude/commands/speckit.checklist.md .claude/commands/projspec.checklist.md
git mv .claude/commands/speckit.clarify.md .claude/commands/projspec.clarify.md
# ... (all 13 files)
```

## Parallel Example: Phase 3 (Content Updates)

```bash
# All command content updates can execute in parallel:
sed -i '' 's|/speckit\.|/projspec.|g' .claude/commands/projspec.analyze.md
sed -i '' 's|/speckit\.|/projspec.|g' .claude/commands/projspec.checklist.md
# ... (all 13 files)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Directory renames
2. Complete Phase 2: File renames
3. Complete Phase 3: Command content updates
4. **STOP and VALIDATE**: Test `/projspec.specify`, `/projspec.plan`, `/projspec.tasks`
5. If working → MVP complete

### Full Implementation

1. Complete Phases 1-3 → Commands work
2. Complete Phase 4 → Config verified
3. Complete Phase 5 → Docs updated
4. Complete Phase 6 → All validated
5. Commit and push

---

## Notes

- Use `git mv` for all file/directory renames to preserve history
- All [P] tasks operate on different files with no dependencies
- Exclude `specs/003-claude-plugin-speckit/` from updates (historical)
- Exclude `.specify/sessions/` from updates (historical logs)
- Case convention: `projspec` (lowercase) for files/commands, `ProjSpec` for docs

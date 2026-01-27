# Feature Specification: Token Count Visibility

## Metadata

| Field | Value |
|-------|-------|
| Branch | `011-token-count-visibility-for` |
| Date | 2026-01-27 |
| Status | Draft (Clarified) |
| Input | Add visibility to specs by saving token counts, split by stage |

---

## User Scenarios & Testing

### Primary Scenarios

#### US-001: View Token Usage Per Spec

**As a** projspec user
**I want to** see actual LLM API token usage for my feature specification work
**So that** I can understand the real token consumption when developing a feature

**Acceptance Criteria:**
- [ ] Actual API token usage (input + output) is automatically recorded when a Claude Code session ends
- [ ] Token usage is aggregated from Claude's session files in `~/.claude/projects/`
- [ ] Counting happens deterministically via Stop hook (no LLM involvement)

**Priority:** High

#### US-002: Access Historical Token Counts

**As a** projspec user
**I want to** access saved token counts for a feature at any time
**So that** I can review and analyze token usage across features

**Acceptance Criteria:**
- [ ] Token counts are saved in a predictable location within the feature directory
- [ ] Saved token data includes timestamp of when counts were recorded
- [ ] Token data is human-readable and machine-parseable

**Priority:** High

#### US-003: Track Cumulative Token Usage

**As a** projspec user
**I want to** see cumulative token usage across all sessions for a feature
**So that** I can understand the total API consumption for developing a feature specification

**Acceptance Criteria:**
- [ ] Cumulative total is calculated across all sessions
- [ ] Individual session usage is preserved in history
- [ ] Each session end adds to the cumulative total

**Priority:** Medium

### Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| No session files found | Record 0 tokens, note "no sessions detected" |
| Session file corrupted | Skip corrupted entries, count what's parseable |
| Very large session (>1M tokens) | Record count normally with warning indicator |
| Multiple concurrent sessions | Aggregate all session files in project directory |
| Subagent sessions (agent-*.jsonl) | Include in aggregation alongside main sessions |

---

## Requirements

### Functional Requirements

#### FR-001: Token Count Persistence

The system shall save actual API token usage to a dedicated file within the feature directory structure. The file shall contain cumulative usage with session history and timestamps.

**Verification:** Work on a feature, end session, verify token count file exists with actual API usage recorded.

#### FR-002: Session-Based Token Aggregation

The system shall read token usage from Claude Code session files:
- Location: `~/.claude/projects/[project-path]/[session-id].jsonl`
- Metrics: `input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`
- Include both main sessions and subagent sessions (agent-*.jsonl)

**Verification:** Run projspec commands, end session, verify all session metrics are aggregated correctly.

#### FR-003: Token Count File Format

The token count file shall be named `tokens.json` and use JSON format. The file shall include:
- Session ID
- Input tokens (direct + cache creation)
- Output tokens
- Cache read tokens (for context)
- Timestamp of session end

Each session end appends a new entry to the history array. Cumulative totals are maintained at the file level.

**Verification:** Parse `tokens.json` programmatically and verify all required fields are present and JSON is valid.

#### FR-004: Automatic Token Counting via Stop Hook

Token counts shall be automatically calculated and saved via a Stop hook when any projspec session ends. The hook executes deterministically without LLM involvement.

**Verification:** Run any projspec command, verify tokens.json is updated after session ends.

#### FR-005: Cumulative Total Calculation

The system shall calculate and display a cumulative total of all artifact token counts for a feature.

**Verification:** Generate multiple artifacts, verify cumulative total equals sum of individual counts.

### Constraints

| Constraint | Description |
|------------|-------------|
| Token data source | Read from `~/.claude/projects/[project-path]/*.jsonl` session files |
| Project path mapping | Convert cwd path to dash-separated format (e.g., `/Users/x/proj` → `-Users-x-proj`) |
| File location | `tokens.json` must reside within the feature directory root |
| File format | JSON format for universal tooling compatibility |
| Update behavior | Stop hook reads all session files and aggregates total usage |
| Execution model | Deterministic bash/python script via Stop hook (no LLM involvement) |

---

## Key Entities

### SessionUsage

**Description:** A record of API token usage for a single Claude Code session.

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| session_id | Claude session identifier | UUID or agent-xxx format |
| input_tokens | Direct input tokens | Non-negative integer |
| cache_creation_tokens | Tokens used for cache creation | Non-negative integer |
| cache_read_tokens | Tokens read from cache | Non-negative integer |
| output_tokens | Output tokens generated | Non-negative integer |
| timestamp | When the session ended | ISO 8601 format |

### TokenSummary

**Description:** Aggregate view of all API token usage for a feature.

| Attribute | Description | Constraints |
|-----------|-------------|-------------|
| feature_id | Identifier of the feature | Matches feature directory name |
| total_input_tokens | Sum of input + cache_creation tokens | Non-negative integer |
| total_output_tokens | Sum of all output tokens | Non-negative integer |
| total_cache_read_tokens | Sum of cache read tokens | Non-negative integer |
| last_updated | Most recent session timestamp | ISO 8601 format |
| sessions | Collection of SessionUsage entries | Array of SessionUsage |

### Entity Relationships

- TokenSummary contains one or more SessionUsage entries
- SessionUsage maps to Claude session files in ~/.claude/projects/
- TokenSummary belongs to one feature directory

---

## Success Criteria

### SC-001: Token Count File Created

**Measure:** Presence of token count file after command execution
**Target:** 100% of successful command runs create/update the token count file
**Verification Method:** Run each projspec command and check for token count file existence

### SC-002: Count Accuracy

**Measure:** Accuracy of token counts from API usage data
**Target:** 100% accuracy (reading actual usage from session files)
**Verification Method:** Compare aggregated counts against manual sum of usage fields in session JSONL files

### SC-003: File Format Validity

**Measure:** Parseability of token count file
**Target:** 100% of token count files parse successfully with standard tools
**Verification Method:** Programmatically parse token count files from 10 different features

---

## Assumptions

| ID | Assumption | Impact if Wrong | Validated |
|----|------------|-----------------|-----------|
| A-001 | Claude Code session files persist in ~/.claude/projects/ and are readable | Would need alternative token tracking method | Yes (verified) |
| A-002 | Session JSONL files contain usage field with token metrics | Would need to find alternative data source | Yes (verified) |
| A-003 | Project directory name is cwd path with slashes replaced by dashes | Would need to find correct mapping | Yes (verified) |
| A-004 | Users want persistent token counts, not just ephemeral display | Would simplify to console-only output | No |

---

## Open Questions

### Q-001: Token Count File Format
- **Question**: Should the token count file use YAML, JSON, or Markdown format?
- **Why Needed**: Affects how easily the data can be consumed by other tools
- **Resolution**: JSON format for universal tooling compatibility
- **Status**: Resolved
- **Impacts**: FR-003

### Q-002: Token Counting Algorithm
- **Question**: Should we use character-based estimation, word-based, or integrate a proper tokenizer?
- **Why Needed**: Affects accuracy of counts and implementation complexity
- **Resolution**: Read actual API usage from Claude Code session files - 100% accurate, no estimation needed
- **Status**: Resolved
- **Impacts**: SC-002, FR-001, FR-002

### Q-003: Display Behavior
- **Question**: Where should token counts be displayed after each stage?
- **Resolution**: File-only persistence (no console output during command execution)
- **Status**: Resolved
- **Impacts**: US-001, FR-004

### Q-004: History Management
- **Question**: How should token count history be managed?
- **Resolution**: Full history per spec lifecycle - file resets when new specification starts
- **Status**: Resolved
- **Impacts**: FR-003, TokenSummary entity

### Q-005: File Naming
- **Question**: What should the token count file be named?
- **Resolution**: `tokens.json` in the feature directory root
- **Status**: Resolved
- **Impacts**: FR-001, FR-003, US-002

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-01-27 | Claude (projspec) | Initial draft from feature description |
| 0.2 | 2026-01-27 | Claude (projspec/clarify) | Resolved 5 clarification questions: JSON format, word-based counting, file-only display, full history per spec, tokens.json filename |
| 0.3 | 2026-01-27 | Claude (projspec) | Changed to Stop hook approach for deterministic execution (no LLM involvement) |
| 0.4 | 2026-01-27 | Claude (projspec) | Major pivot: Track actual LLM API token usage from Claude session files instead of word-count estimation. Updated entities from TokenCount/artifact to SessionUsage/API metrics. Verified assumptions about ~/.claude/projects/ structure. |

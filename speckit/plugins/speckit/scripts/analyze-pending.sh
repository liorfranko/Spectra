#!/usr/bin/env bash
# speckit/scripts/analyze-pending.sh - Analyze pending learning observations
# Processes pending sessions and creates atomic instincts from detected corrections
# Run this manually or via automation to analyze sessions queued by session-end hooks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Confidence thresholds
CONFIDENCE_LOW=0.3
CONFIDENCE_MEDIUM=0.5
CONFIDENCE_HIGH=0.7
CONFIDENCE_MAX=0.9
DECAY_PER_WEEK=0.05
PROMOTION_THRESHOLD=0.9

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Analyze pending learning observations and manage instincts.

OPTIONS:
    --list, -l      List pending sessions without processing
    --decay, -d     Apply confidence decay to stale instincts
    --promote, -p   Promote high-confidence instincts to skills
    --all, -a       Process pending, apply decay, and promote
    --json          Output in JSON format
    -h, --help      Show this help message

EXAMPLES:
    $(basename "$0")              # Process all pending sessions
    $(basename "$0") --list       # List pending sessions
    $(basename "$0") --decay      # Apply confidence decay
    $(basename "$0") --promote    # Promote high-confidence instincts
    $(basename "$0") --all        # Full analysis cycle
EOF
}

# =============================================================================
# Path Configuration
# =============================================================================

# Get project root - prefer CLAUDE_PROJECT_DIR env var, fallback to search
get_project_root() {
    # Use Claude Code's project dir if available
    if [[ -n "${CLAUDE_PROJECT_DIR:-}" && -d "$CLAUDE_PROJECT_DIR/.specify" ]]; then
        echo "$CLAUDE_PROJECT_DIR"
        return 0
    fi
    # Fallback: search up from current directory
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.specify" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    # Final fallback: use git root
    get_repo_root
}

PROJECT_ROOT=$(get_project_root)
LEARNING_DIR="$PROJECT_ROOT/.specify/learning"
PENDING_DIR="$LEARNING_DIR/pending-analysis"
INSTINCTS_DIR="$LEARNING_DIR/instincts"
SKILLS_DIR="$PROJECT_ROOT/.specify/skills/learned"

# =============================================================================
# Logging
# =============================================================================

log_info() { echo "[analyze] $1"; }
log_warn() { echo "[analyze] WARNING: $1" >&2; }
log_error() { echo "[analyze] ERROR: $1" >&2; }

# =============================================================================
# Instinct Management
# =============================================================================

# Generate unique instinct ID
generate_instinct_id() {
    echo "instinct-$(date +%s)-$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"
}

# Find existing instinct by pattern match
find_similar_instinct() {
    local correction_type="$1"
    local tool="$2"
    local message_pattern="$3"

    if [[ ! -d "$INSTINCTS_DIR" ]]; then
        return 1
    fi

    # Look for instincts with matching type and tool
    while IFS= read -r instinct_file; do
        [[ -z "$instinct_file" ]] && continue

        local inst_type
        inst_type=$(grep -o '"type"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
        local inst_tool
        inst_tool=$(grep -o '"tool"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/' || echo "")

        if [[ "$inst_type" == "$correction_type" && "$inst_tool" == "$tool" ]]; then
            echo "$instinct_file"
            return 0
        fi
    done < <(find "$INSTINCTS_DIR" -name "instinct-*.json" -type f 2>/dev/null)

    return 1
}

# Reinforce existing instinct (increase confidence)
reinforce_instinct() {
    local instinct_file="$1"
    local new_evidence="$2"

    # Read current confidence
    local current_conf
    current_conf=$(grep -o '"confidence"[[:space:]]*:[[:space:]]*[0-9.]*' "$instinct_file" | sed 's/.*:[[:space:]]*//' || echo "0.3")

    # Increase confidence by 0.1, cap at CONFIDENCE_MAX
    local new_conf
    new_conf=$(echo "$current_conf + 0.1" | bc -l 2>/dev/null || echo "$current_conf")
    new_conf=$(printf "%.2f" "$new_conf")
    if (( $(echo "$new_conf > $CONFIDENCE_MAX" | bc -l 2>/dev/null || echo 0) )); then
        new_conf=$CONFIDENCE_MAX
    fi

    # Read current reinforcement count
    local current_count
    current_count=$(grep -o '"reinforcement_count"[[:space:]]*:[[:space:]]*[0-9]*' "$instinct_file" | sed 's/.*:[[:space:]]*//' || echo "0")
    local new_count=$((current_count + 1))

    # Update the instinct file
    local temp_file="${instinct_file}.tmp"

    # Update confidence
    sed "s/\"confidence\"[[:space:]]*:[[:space:]]*[0-9.]*/\"confidence\": $new_conf/" "$instinct_file" > "$temp_file"
    mv "$temp_file" "$instinct_file"

    # Update reinforcement count
    sed "s/\"reinforcement_count\"[[:space:]]*:[[:space:]]*[0-9]*/\"reinforcement_count\": $new_count/" "$instinct_file" > "$temp_file"
    mv "$temp_file" "$instinct_file"

    # Update last_reinforced timestamp
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    sed "s/\"last_reinforced\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"last_reinforced\": \"$timestamp\"/" "$instinct_file" > "$temp_file"
    mv "$temp_file" "$instinct_file"

    log_info "Reinforced instinct: $(basename "$instinct_file") -> confidence $new_conf (x$new_count)"
}

# Create new instinct from correction
create_instinct() {
    local correction_type="$1"
    local tool="$2"
    local message="$3"
    local confidence="$4"
    local timestamp="$5"
    local session_id="$6"

    mkdir -p "$INSTINCTS_DIR"

    local instinct_id
    instinct_id=$(generate_instinct_id)
    local instinct_file="$INSTINCTS_DIR/${instinct_id}.json"

    # Parse action from message
    local dont_action=""
    local do_action=""

    case "$correction_type" in
        "NEGATIVE_PREFERENCE")
            dont_action=$(echo "$message" | head -c 200)
            ;;
        "POSITIVE_PREFERENCE")
            do_action=$(echo "$message" | head -c 200)
            ;;
        "ERROR_CORRECTION")
            dont_action="Avoid the pattern that caused this error"
            do_action=$(echo "$message" | head -c 200)
            ;;
        "PROJECT_CONVENTION")
            do_action=$(echo "$message" | head -c 200)
            ;;
    esac

    cat > "$instinct_file" << EOF
{
    "id": "$instinct_id",
    "created_at": "$timestamp",
    "type": "$correction_type",
    "confidence": $confidence,
    "trigger": {
        "context": "Detected from user correction",
        "tool": "$tool",
        "pattern": ""
    },
    "action": {
        "dont": "$(echo "$dont_action" | sed 's/"/\\"/g')",
        "do": "$(echo "$do_action" | sed 's/"/\\"/g')"
    },
    "evidence": [
        {
            "session_id": "$session_id",
            "timestamp": "$timestamp",
            "message": "$(echo "$message" | sed 's/"/\\"/g' | head -c 500)"
        }
    ],
    "reinforcement_count": 0,
    "last_reinforced": "$timestamp",
    "status": "active"
}
EOF

    log_info "Created instinct: $instinct_id (type: $correction_type, confidence: $confidence)"
}

# =============================================================================
# Session Processing
# =============================================================================

# Process a single pending session
process_session() {
    local queue_file="$1"
    local session_dir
    session_dir=$(cat "$queue_file")

    if [[ ! -d "$session_dir" ]]; then
        log_warn "Session directory not found: $session_dir"
        rm -f "$queue_file"
        return
    fi

    local corrections_file="$session_dir/corrections.jsonl"
    if [[ ! -f "$corrections_file" ]]; then
        log_info "No corrections file found in session"
        rm -f "$queue_file"
        return
    fi

    local meta_file="$session_dir/session-meta.json"
    local session_id="unknown"
    if [[ -f "$meta_file" ]]; then
        session_id=$(grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$meta_file" | sed 's/.*"\([^"]*\)"$/\1/' || echo "unknown")
    fi

    log_info "Processing session: $session_id"

    local created=0
    local reinforced=0

    # Process each correction
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        local correction_type
        correction_type=$(echo "$line" | grep -o '"type"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
        local tool
        tool=$(echo "$line" | grep -o '"tool"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
        local message
        message=$(echo "$line" | grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
        local confidence
        confidence=$(echo "$line" | grep -o '"confidence"[[:space:]]*:[[:space:]]*[0-9.]*' | sed 's/.*:[[:space:]]*//' || echo "0.3")
        local timestamp
        timestamp=$(echo "$line" | grep -o '"timestamp"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || echo "")

        if [[ -z "$correction_type" ]]; then
            continue
        fi

        # Check if similar instinct already exists
        local existing_instinct
        if existing_instinct=$(find_similar_instinct "$correction_type" "$tool" "$message"); then
            reinforce_instinct "$existing_instinct" "$line"
            ((reinforced++))
        else
            create_instinct "$correction_type" "$tool" "$message" "$confidence" "$timestamp" "$session_id"
            ((created++))
        fi

    done < "$corrections_file"

    log_info "Session $session_id: created $created instinct(s), reinforced $reinforced"

    # Mark session as processed
    rm -f "$queue_file"
}

# =============================================================================
# Confidence Decay
# =============================================================================

# Apply confidence decay to stale instincts
apply_decay() {
    if [[ ! -d "$INSTINCTS_DIR" ]]; then
        log_info "No instincts directory found"
        return
    fi

    local now_epoch
    now_epoch=$(date +%s)
    local week_seconds=$((7 * 24 * 60 * 60))
    local decayed=0
    local archived=0

    while IFS= read -r instinct_file; do
        [[ -z "$instinct_file" ]] && continue

        # Get last reinforced timestamp
        local last_reinforced
        last_reinforced=$(grep -o '"last_reinforced"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" | sed 's/.*"\([^"]*\)"$/\1/' || echo "")

        if [[ -z "$last_reinforced" ]]; then
            continue
        fi

        # Convert to epoch (macOS compatible)
        local last_epoch
        if [[ "$(uname)" == "Darwin" ]]; then
            last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_reinforced" +%s 2>/dev/null || echo "0")
        else
            last_epoch=$(date -d "$last_reinforced" +%s 2>/dev/null || echo "0")
        fi

        local age_seconds=$((now_epoch - last_epoch))
        local weeks_stale=$((age_seconds / week_seconds))

        if [[ "$weeks_stale" -gt 0 ]]; then
            local current_conf
            current_conf=$(grep -o '"confidence"[[:space:]]*:[[:space:]]*[0-9.]*' "$instinct_file" | sed 's/.*:[[:space:]]*//' || echo "0")

            local decay_amount
            decay_amount=$(echo "$weeks_stale * $DECAY_PER_WEEK" | bc -l 2>/dev/null || echo "0")
            local new_conf
            new_conf=$(echo "$current_conf - $decay_amount" | bc -l 2>/dev/null || echo "$current_conf")
            new_conf=$(printf "%.2f" "$new_conf")

            # Archive if confidence drops below threshold
            if (( $(echo "$new_conf < 0.1" | bc -l 2>/dev/null || echo 0) )); then
                # Move to archived status
                local temp_file="${instinct_file}.tmp"
                sed 's/"status"[[:space:]]*:[[:space:]]*"active"/"status": "archived"/' "$instinct_file" > "$temp_file"
                mv "$temp_file" "$instinct_file"
                ((archived++))
                log_info "Archived stale instinct: $(basename "$instinct_file")"
            elif (( $(echo "$new_conf < $current_conf" | bc -l 2>/dev/null || echo 0) )); then
                # Apply decay
                local temp_file="${instinct_file}.tmp"
                sed "s/\"confidence\"[[:space:]]*:[[:space:]]*[0-9.]*/\"confidence\": $new_conf/" "$instinct_file" > "$temp_file"
                mv "$temp_file" "$instinct_file"
                ((decayed++))
            fi
        fi
    done < <(find "$INSTINCTS_DIR" -name "instinct-*.json" -type f 2>/dev/null)

    log_info "Decay applied: $decayed instinct(s) decayed, $archived archived"
}

# =============================================================================
# Instinct Promotion
# =============================================================================

# Promote high-confidence instincts to skills
promote_instincts() {
    if [[ ! -d "$INSTINCTS_DIR" ]]; then
        log_info "No instincts directory found"
        return
    fi

    mkdir -p "$SKILLS_DIR"
    local promoted=0

    while IFS= read -r instinct_file; do
        [[ -z "$instinct_file" ]] && continue

        local confidence
        confidence=$(grep -o '"confidence"[[:space:]]*:[[:space:]]*[0-9.]*' "$instinct_file" | sed 's/.*:[[:space:]]*//' || echo "0")

        local status
        status=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" | sed 's/.*"\([^"]*\)"$/\1/' || echo "active")

        if [[ "$status" != "active" ]]; then
            continue
        fi

        if (( $(echo "$confidence >= $PROMOTION_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
            local instinct_id
            instinct_id=$(grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" | sed 's/.*"\([^"]*\)"$/\1/' || echo "unknown")

            local instinct_type
            instinct_type=$(grep -o '"type"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" | sed 's/.*"\([^"]*\)"$/\1/' || echo "")

            local do_action
            do_action=$(grep -o '"do"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" | sed 's/.*"\([^"]*\)"$/\1/' || echo "")

            local dont_action
            dont_action=$(grep -o '"dont"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" | sed 's/.*"\([^"]*\)"$/\1/' || echo "")

            local tool
            tool=$(grep -o '"tool"[[:space:]]*:[[:space:]]*"[^"]*"' "$instinct_file" | sed 's/.*"\([^"]*\)"$/\1/' || echo "")

            local reinforcement_count
            reinforcement_count=$(grep -o '"reinforcement_count"[[:space:]]*:[[:space:]]*[0-9]*' "$instinct_file" | sed 's/.*:[[:space:]]*//' || echo "0")

            # Create skill file
            local skill_file="$SKILLS_DIR/skill-${instinct_id#instinct-}.md"
            cat > "$skill_file" << EOF
# Learned Skill: ${instinct_type}

**Source:** Auto-promoted from instinct
**Confidence:** ${confidence}
**Reinforcements:** ${reinforcement_count}
**Tool Context:** ${tool}

## What This Skill Does

${do_action}

## What to Avoid

${dont_action}

## When to Apply

Apply this skill when working with ${tool:-"similar contexts"}.

---
*Auto-promoted from ${instinct_id} on $(date +%Y-%m-%d)*
EOF

            # Mark instinct as promoted
            local temp_file="${instinct_file}.tmp"
            sed 's/"status"[[:space:]]*:[[:space:]]*"active"/"status": "promoted"/' "$instinct_file" > "$temp_file"
            mv "$temp_file" "$instinct_file"

            ((promoted++))
            log_info "Promoted to skill: $skill_file"
        fi
    done < <(find "$INSTINCTS_DIR" -name "instinct-*.json" -type f 2>/dev/null)

    log_info "Promotion complete: $promoted instinct(s) promoted to skills"
}

# =============================================================================
# List Pending
# =============================================================================

# List pending sessions
list_pending() {
    if [[ ! -d "$PENDING_DIR" ]]; then
        log_info "No pending sessions"
        return
    fi

    local count
    count=$(find "$PENDING_DIR" -name "*.pending" -type f 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$count" -eq 0 ]]; then
        log_info "No pending sessions"
        return
    fi

    log_info "Pending sessions ($count):"
    while IFS= read -r queue_file; do
        local session_dir
        session_dir=$(cat "$queue_file")
        echo "  - $(basename "$queue_file" .pending): $session_dir"
    done < <(find "$PENDING_DIR" -name "*.pending" -type f 2>/dev/null)
}

# =============================================================================
# Main
# =============================================================================

main() {
    mkdir -p "$INSTINCTS_DIR"
    mkdir -p "$PENDING_DIR"
    mkdir -p "$SKILLS_DIR"

    local mode="${1:-analyze}"

    case "$mode" in
        -h|--help)
            usage
            exit 0
            ;;
        --list|-l)
            list_pending
            ;;
        --decay|-d)
            apply_decay
            ;;
        --promote|-p)
            promote_instincts
            ;;
        --all|-a)
            # Process pending, apply decay, and promote
            while IFS= read -r queue_file; do
                [[ -z "$queue_file" ]] && continue
                process_session "$queue_file"
            done < <(find "$PENDING_DIR" -name "*.pending" -type f 2>/dev/null)
            apply_decay
            promote_instincts
            ;;
        analyze|*)
            # Default: just process pending sessions
            local count
            count=$(find "$PENDING_DIR" -name "*.pending" -type f 2>/dev/null | wc -l | tr -d ' ')

            if [[ "$count" -eq 0 ]]; then
                log_info "No pending sessions to analyze"
                return
            fi

            log_info "Processing $count pending session(s)..."
            while IFS= read -r queue_file; do
                [[ -z "$queue_file" ]] && continue
                process_session "$queue_file"
            done < <(find "$PENDING_DIR" -name "*.pending" -type f 2>/dev/null)
            ;;
    esac
}

main "$@"

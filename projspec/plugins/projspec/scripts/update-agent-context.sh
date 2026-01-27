#!/usr/bin/env bash
# projspec/scripts/update-agent-context.sh - Update CLAUDE.md with feature context
# Reads plan.md and updates CLAUDE.md with technologies, structure, and changes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Script Configuration
# =============================================================================

OUTPUT_JSON=false
DRY_RUN=false
FEATURE_DIR=""

# =============================================================================
# Usage and Help
# =============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Update CLAUDE.md with information from the current feature's plan.md.

This script extracts:
- Active technologies from Technical Context
- Project structure from plan.md
- Recent changes entry for the feature

OPTIONS:
    --feature-dir DIR   Feature directory path (auto-detect from branch if not provided)
    --dry-run           Show what would be changed without modifying CLAUDE.md
    --json              Output in JSON format
    -h, --help          Show this help message

EXAMPLES:
    $(basename "$0")
    $(basename "$0") --feature-dir /path/to/specs/003-my-feature
    $(basename "$0") --dry-run
    $(basename "$0") --json
EOF
}

# =============================================================================
# Argument Parsing
# =============================================================================

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --feature-dir)
                if [[ -z "${2:-}" ]]; then
                    error "--feature-dir requires a value"
                fi
                FEATURE_DIR="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --json)
                OUTPUT_JSON=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# =============================================================================
# Plan.md Parsing Functions
# =============================================================================

# Extract the Primary Language value from Technical Context
extract_language() {
    local plan_file="$1"

    # Look for the Language & Runtime table and extract Primary Language value
    local language=""
    language=$(grep -A 10 "### Language & Runtime" "$plan_file" 2>/dev/null | \
               grep "Primary Language" | \
               sed 's/.*|[^|]*|[[:space:]]*\([^|]*\)[[:space:]]*|.*/\1/' | \
               sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
               head -n1)

    # Clean up placeholder text
    if [[ "$language" == "[LANGUAGE]" ]] || [[ -z "$language" ]]; then
        echo ""
    else
        echo "$language"
    fi
}

# Extract dependencies from the Dependencies table
extract_dependencies() {
    local plan_file="$1"

    # Look for dependencies table and extract dependency names
    local deps=""
    deps=$(awk '/### Dependencies/,/### Platform/' "$plan_file" 2>/dev/null | \
           grep "^|" | \
           grep -v "Dependency\|Version\|Purpose\|---" | \
           awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); if ($2 != "" && $2 !~ /\[DEPENDENCY/) print $2}' | \
           tr '\n' ', ' | \
           sed 's/, $//')

    echo "$deps"
}

# Extract Target Platform from Technical Context
extract_platform() {
    local plan_file="$1"

    local platform=""
    platform=$(grep -A 10 "### Platform & Environment" "$plan_file" 2>/dev/null | \
               grep "Target Platform" | \
               sed 's/.*|[^|]*|[[:space:]]*\([^|]*\)[[:space:]]*|.*/\1/' | \
               sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
               head -n1)

    if [[ "$platform" == "[PLATFORM]" ]] || [[ -z "$platform" ]]; then
        echo ""
    else
        echo "$platform"
    fi
}

# Extract project structure directories
extract_structure() {
    local plan_file="$1"

    # Look for Source Code Layout section and extract directory structure
    local structure=""
    structure=$(awk '/### Source Code Layout/,/### File Mapping/' "$plan_file" 2>/dev/null | \
                grep "^├──\|^└──\|^│" | \
                grep -v "│   " | \
                sed 's/[├└]──[[:space:]]*//' | \
                sed 's/[[:space:]]*#.*//' | \
                sed 's/\/$//g' | \
                tr '\n' '\n' | \
                head -10)

    # If not found, try looking at the Documentation Layout
    if [[ -z "$structure" ]]; then
        structure=$(awk '/### Documentation Layout/,/### Source Code Layout/' "$plan_file" 2>/dev/null | \
                    grep "specs/\|src/\|tests/\|projspec/" | \
                    head -5)
    fi

    echo "$structure"
}

# Build tech stack summary string
build_tech_summary() {
    local plan_file="$1"
    local feature_id="$2"

    local language
    language=$(extract_language "$plan_file")

    local platform
    platform=$(extract_platform "$plan_file")

    local deps
    deps=$(extract_dependencies "$plan_file")

    local summary=""

    if [[ -n "$language" ]]; then
        summary="$language"
    fi

    if [[ -n "$platform" ]]; then
        if [[ -n "$summary" ]]; then
            summary="$summary + $platform"
        else
            summary="$platform"
        fi
    fi

    if [[ -n "$deps" ]]; then
        if [[ -n "$summary" ]]; then
            summary="$summary, $deps"
        else
            summary="$deps"
        fi
    fi

    if [[ -z "$summary" ]]; then
        summary="Not specified"
    fi

    echo "$summary ($feature_id)"
}

# =============================================================================
# CLAUDE.md Update Functions
# =============================================================================

# Check if CLAUDE.md exists and has the expected sections
validate_claude_md() {
    local claude_file="$1"

    if [[ ! -f "$claude_file" ]]; then
        return 1
    fi

    # Check for required sections
    if ! grep -q "## Active Technologies" "$claude_file"; then
        return 1
    fi

    return 0
}

# Create initial CLAUDE.md if it doesn't exist
create_claude_md() {
    local claude_file="$1"
    local feature_id="$2"
    local today
    today=$(date +%Y-%m-%d)

    cat > "$claude_file" <<EOF
# ${feature_id} Development Guidelines

Auto-generated from all feature plans. Last updated: ${today}

## Active Technologies

<!-- Add technology stacks per feature -->

## Project Structure

\`\`\`text
src/
tests/
\`\`\`

## Commands

# Add commands for your tech stack

## Code Style

Follow standard conventions

## Recent Changes

<!-- Add recent changes here -->

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
EOF
}

# Update Active Technologies section
update_technologies_section() {
    local claude_file="$1"
    local tech_summary="$2"
    local feature_id="$3"
    local temp_file
    temp_file=$(mktemp)

    # Check if this feature already has an entry
    if grep -q "($feature_id)" "$claude_file"; then
        # Update existing entry
        sed "s/^- .*(${feature_id})\$/- ${tech_summary}/" "$claude_file" > "$temp_file"
    else
        # Add new entry after "## Active Technologies" heading
        awk -v tech="- ${tech_summary}" '
        /^## Active Technologies/ {
            print
            getline
            if (/^$/ || /^<!--/) {
                print
                print tech
            } else {
                print tech
                print
            }
            next
        }
        { print }
        ' "$claude_file" > "$temp_file"
    fi

    cat "$temp_file"
    rm -f "$temp_file"
}

# Update Project Structure section
update_structure_section() {
    local claude_content="$1"
    local structure="$2"

    # If structure is empty, return original content
    if [[ -z "$structure" ]]; then
        echo "$claude_content"
        return
    fi

    # Build the structure block
    local structure_block
    structure_block=$(echo "$structure" | grep -v "^$" | sed 's/^//')

    # Replace the structure section
    echo "$claude_content" | awk -v struct="$structure_block" '
    /^## Project Structure/ {
        print
        print ""
        print "```text"
        print struct
        print "```"
        # Skip until next section
        while ((getline line) > 0) {
            if (line ~ /^## /) {
                print line
                break
            }
        }
        next
    }
    { print }
    '
}

# Update Recent Changes section
update_recent_changes() {
    local claude_content="$1"
    local feature_id="$2"
    local tech_summary="$3"
    local temp_file
    temp_file=$(mktemp)

    # Remove the feature_id suffix from tech_summary for the change message
    local change_msg
    change_msg=$(echo "$tech_summary" | sed "s/ ($feature_id)//")

    # Check if this feature already has a recent change entry
    if echo "$claude_content" | grep -q "^- ${feature_id}:"; then
        # Update existing entry
        echo "$claude_content" | sed "s/^- ${feature_id}:.*\$/- ${feature_id}: Added ${change_msg}/" > "$temp_file"
    else
        # Add new entry after "## Recent Changes" heading
        echo "$claude_content" | awk -v change="- ${feature_id}: Added ${change_msg}" '
        /^## Recent Changes/ {
            print
            getline
            if (/^$/ || /^<!--/) {
                print
                print change
            } else {
                print change
                print
            }
            next
        }
        { print }
        ' > "$temp_file"
    fi

    cat "$temp_file"
    rm -f "$temp_file"
}

# Update Code Style section
update_code_style() {
    local claude_content="$1"
    local language="$2"

    if [[ -z "$language" ]]; then
        echo "$claude_content"
        return
    fi

    # Replace the Code Style section content
    echo "$claude_content" | awk -v lang="$language" '
    /^## Code Style/ {
        print
        print ""
        print lang ": Follow standard conventions"
        # Skip until next section or MANUAL ADDITIONS
        while ((getline line) > 0) {
            if (line ~ /^## / || line ~ /<!-- MANUAL ADDITIONS/) {
                print line
                break
            }
        }
        next
    }
    { print }
    '
}

# Update the last updated date in CLAUDE.md
update_last_updated() {
    local claude_content="$1"
    local today
    today=$(date +%Y-%m-%d)

    echo "$claude_content" | sed "s/Last updated: [0-9-]*/Last updated: ${today}/"
}

# =============================================================================
# Main Logic
# =============================================================================

main() {
    parse_args "$@"

    local repo_root
    repo_root=$(get_repo_root)

    # Auto-detect feature directory if not provided
    if [[ -z "$FEATURE_DIR" ]]; then
        FEATURE_DIR=$(get_feature_dir) || {
            if [[ "$OUTPUT_JSON" == "true" ]]; then
                json_error "Failed to auto-detect feature directory from branch name"
                exit 1
            else
                error "Failed to auto-detect feature directory from branch name"
            fi
        }
    fi

    # Validate feature directory exists
    if [[ ! -d "$FEATURE_DIR" ]]; then
        if [[ "$OUTPUT_JSON" == "true" ]]; then
            json_output "error" "true" "message" "Feature directory does not exist: $FEATURE_DIR"
            exit 1
        else
            error "Feature directory does not exist: $FEATURE_DIR"
        fi
    fi

    # Extract feature ID from directory name
    local feature_id
    feature_id=$(basename "$FEATURE_DIR")

    # Check for plan.md
    local plan_file="${FEATURE_DIR}/plan.md"
    if [[ ! -f "$plan_file" ]]; then
        if [[ "$OUTPUT_JSON" == "true" ]]; then
            json_output "error" "true" "message" "plan.md not found in $FEATURE_DIR - run /projspec:plan first"
            exit 1
        else
            error "plan.md not found in $FEATURE_DIR - run /projspec:plan first"
        fi
    fi

    # CLAUDE.md location
    local claude_file="${repo_root}/CLAUDE.md"

    # Create CLAUDE.md if it doesn't exist or is malformed
    if ! validate_claude_md "$claude_file"; then
        if [[ "$DRY_RUN" == "true" ]]; then
            if [[ "$OUTPUT_JSON" == "true" ]]; then
                json_output "action" "would_create" "file" "$claude_file" "reason" "CLAUDE.md does not exist or is missing required sections"
            else
                echo "[DRY RUN] Would create CLAUDE.md at: $claude_file"
            fi
        else
            create_claude_md "$claude_file" "$feature_id"
            if [[ "$OUTPUT_JSON" != "true" ]]; then
                info "Created CLAUDE.md at: $claude_file"
            fi
        fi
    fi

    # Read current CLAUDE.md content
    local original_content=""
    if [[ -f "$claude_file" ]]; then
        original_content=$(cat "$claude_file")
    fi

    # Extract information from plan.md
    local tech_summary
    tech_summary=$(build_tech_summary "$plan_file" "$feature_id")

    local language
    language=$(extract_language "$plan_file")

    local structure
    structure=$(extract_structure "$plan_file")

    # Build updated CLAUDE.md content
    local updated_content
    updated_content=$(update_technologies_section "$claude_file" "$tech_summary" "$feature_id")
    updated_content=$(update_recent_changes "$updated_content" "$feature_id" "$tech_summary")
    updated_content=$(update_code_style "$updated_content" "$language")
    updated_content=$(update_last_updated "$updated_content")

    # Handle dry-run or actual update
    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ "$OUTPUT_JSON" == "true" ]]; then
            # Create a simple diff summary
            local changes_made=""
            if [[ "$original_content" != "$updated_content" ]]; then
                changes_made="technologies,recent_changes,code_style,last_updated"
            fi
            json_output \
                "action" "dry_run" \
                "file" "$claude_file" \
                "feature_id" "$feature_id" \
                "tech_summary" "$tech_summary" \
                "changes" "$changes_made"
        else
            echo "[DRY RUN] Would update CLAUDE.md with:"
            echo ""
            echo "Feature ID: $feature_id"
            echo "Tech Summary: $tech_summary"
            echo ""
            echo "=== Diff ==="
            if command -v diff &>/dev/null; then
                diff -u <(echo "$original_content") <(echo "$updated_content") || true
            else
                echo "--- Original ---"
                echo "$original_content"
                echo ""
                echo "--- Updated ---"
                echo "$updated_content"
            fi
        fi
    else
        # Write updated content
        echo "$updated_content" > "$claude_file"

        if [[ "$OUTPUT_JSON" == "true" ]]; then
            json_output \
                "success" "true" \
                "file" "$claude_file" \
                "feature_id" "$feature_id" \
                "tech_summary" "$tech_summary" \
                "updated_sections" "technologies,recent_changes,code_style,last_updated"
        else
            echo "CLAUDE.md updated successfully!"
            echo ""
            echo "Updated sections:"
            echo "  - Active Technologies: $tech_summary"
            echo "  - Recent Changes: Added entry for $feature_id"
            if [[ -n "$language" ]]; then
                echo "  - Code Style: Updated for $language"
            fi
            echo "  - Last Updated: $(date +%Y-%m-%d)"
            echo ""
            echo "File: $claude_file"
        fi
    fi
}

main "$@"

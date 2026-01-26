#!/usr/bin/env bash
# =============================================================================
# update-agent-context.sh - Refresh agent context files (CLAUDE.md, etc.)
# =============================================================================
# This script updates agent context files to reflect the current state of
# the project, including:
# - Regenerating CLAUDE.md from templates and current feature state
# - Updating technology and dependency information
# - Refreshing command references
# - Syncing with active feature plans
#
# Usage:
#   ./update-agent-context.sh [options]
#
# Options:
#   --feature <id>    Update context for specific feature
#   --all             Update all agent context files
#   --check           Check if context is up-to-date (no changes made)
#   --json            Output results in JSON format
#
# Examples:
#   ./update-agent-context.sh                    # Update current feature
#   ./update-agent-context.sh --all              # Update everything
#   ./update-agent-context.sh --feature 042      # Specific feature
#   ./update-agent-context.sh --check            # Validate only
#
# Exit codes:
#   0 - Context updated successfully (or up-to-date in --check mode)
#   1 - Error during update
#   2 - Context is out-of-date (--check mode only)
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Agent context file
CLAUDE_MD="CLAUDE.md"

# Template for CLAUDE.md
AGENT_TEMPLATE_NAME="agent-file-template.md"

# Section markers
MANUAL_START="<!-- MANUAL ADDITIONS START -->"
MANUAL_END="<!-- MANUAL ADDITIONS END -->"

# Spec directory pattern
SPEC_DIR_PATTERN="specs"

# =============================================================================
# Help
# =============================================================================

show_help() {
    cat << 'EOF'
Usage: update-agent-context.sh [options]

Refresh agent context files (CLAUDE.md) to reflect current project state.

Options:
  --feature <id>    Update context for specific feature (e.g., 001)
  --all             Update all agent context files (main and worktrees)
  --check           Check if context is up-to-date (no changes made)
  --json            Output results in JSON format
  --help            Show this help message
  --version         Show version information

Examples:
  ./update-agent-context.sh                    # Update current feature
  ./update-agent-context.sh --all              # Update everything
  ./update-agent-context.sh --feature 042      # Specific feature
  ./update-agent-context.sh --check            # Validate only (exit 2 if outdated)
EOF
}

# =============================================================================
# Helper Functions
# =============================================================================

get_active_features() {
    # Get list of active features from specs/ directory
    # Returns: newline-separated list of feature branch names (e.g., "001-feature-name")
    local main_root="${1:-}"
    local specs_dir="$main_root/$SPEC_DIR_PATTERN"

    if [[ ! -d "$specs_dir" ]]; then
        return 0
    fi

    # Find all feature directories that match the pattern NNN-*
    for dir in "$specs_dir"/[0-9][0-9][0-9]-*/; do
        if [[ -d "$dir" ]]; then
            local dirname
            dirname=$(basename "$dir")
            # Verify it's a valid feature directory (has spec.md or plan.md)
            if [[ -f "$dir/spec.md" ]] || [[ -f "$dir/plan.md" ]]; then
                echo "$dirname"
            fi
        fi
    done
}

extract_manual_sections() {
    # Extract manually-added content from existing CLAUDE.md
    # Args: $1 - path to CLAUDE.md
    # Returns: content between MANUAL_START and MANUAL_END markers
    local claude_md="${1:-$CLAUDE_MD}"

    if [[ ! -f "$claude_md" ]]; then
        echo ""
        return 0
    fi

    # Use sed to extract content between markers
    local content
    content=$(sed -n "/${MANUAL_START//\//\\/}/,/${MANUAL_END//\//\\/}/p" "$claude_md" 2>/dev/null || echo "")

    # Remove the marker lines themselves to get just the content
    if [[ -n "$content" ]]; then
        content=$(echo "$content" | sed "1d;\$d")
    fi

    echo "$content"
}

gather_technology_info() {
    # Gather technology information from active feature plan.md files
    # Args: $1 - main repo root, $2 - specific feature (optional)
    # Returns: technology summary for CLAUDE.md
    local main_root="${1:-}"
    local specific_feature="${2:-}"

    log_info "Gathering technology information" >&2

    local specs_dir="$main_root/$SPEC_DIR_PATTERN"
    local tech_entries=()

    # Get list of features to process
    local features
    if [[ -n "$specific_feature" ]]; then
        # Find the feature directory matching the ID
        for dir in "$specs_dir"/"$specific_feature"-*/; do
            if [[ -d "$dir" ]]; then
                features=$(basename "$dir")
                break
            fi
        done
        if [[ -z "${features:-}" ]]; then
            features="$specific_feature"
        fi
    else
        features=$(get_active_features "$main_root")
    fi

    while IFS= read -r feature; do
        [[ -z "$feature" ]] && continue

        local plan_file="$specs_dir/$feature/plan.md"
        if [[ -f "$plan_file" ]]; then
            # Extract Language/Version line from Technical Context section
            local lang_version
            lang_version=$(grep -E '^\*\*Language/Version\*\*:' "$plan_file" 2>/dev/null | head -1 | sed 's/\*\*Language\/Version\*\*:[[:space:]]*//')

            # Extract Primary Dependencies
            local deps
            deps=$(grep -E '^\*\*Primary Dependencies\*\*:' "$plan_file" 2>/dev/null | head -1 | sed 's/\*\*Primary Dependencies\*\*:[[:space:]]*//')

            if [[ -n "$lang_version" ]]; then
                local entry="$lang_version"
                if [[ -n "$deps" ]]; then
                    entry="$entry + $deps"
                fi
                entry="$entry ($feature)"
                tech_entries+=("$entry")
            fi
        fi
    done <<< "$features"

    # Return unique entries
    if [[ ${#tech_entries[@]} -gt 0 ]]; then
        printf '%s\n' "${tech_entries[@]}" | sort -u
    fi
}

gather_command_info() {
    # Gather command information from active feature plan.md files
    # Args: $1 - main repo root, $2 - specific feature (optional)
    # Returns: command summary for CLAUDE.md
    local main_root="${1:-}"
    local specific_feature="${2:-}"

    log_info "Gathering command information" >&2

    local specs_dir="$main_root/$SPEC_DIR_PATTERN"
    local commands=()

    # Get list of features to process
    local features
    if [[ -n "$specific_feature" ]]; then
        for dir in "$specs_dir"/"$specific_feature"-*/; do
            if [[ -d "$dir" ]]; then
                features=$(basename "$dir")
                break
            fi
        done
        if [[ -z "${features:-}" ]]; then
            features="$specific_feature"
        fi
    else
        features=$(get_active_features "$main_root")
    fi

    while IFS= read -r feature; do
        [[ -z "$feature" ]] && continue

        local plan_file="$specs_dir/$feature/plan.md"
        if [[ -f "$plan_file" ]]; then
            # Look for common command patterns in plan.md
            # Extract commands from code blocks after "# " comments
            local in_commands_section=false
            local collecting_commands=false

            while IFS= read -r line; do
                # Look for Commands section or Development/Testing/Build subsections
                if [[ "$line" =~ ^#+[[:space:]]*Commands ]] || \
                   [[ "$line" =~ ^#+[[:space:]]*Development ]] || \
                   [[ "$line" =~ ^#+[[:space:]]*Testing ]]; then
                    in_commands_section=true
                    continue
                fi

                # Stop at next major section
                if [[ "$in_commands_section" == "true" ]] && [[ "$line" =~ ^##[[:space:]] ]] && \
                   [[ ! "$line" =~ Development ]] && [[ ! "$line" =~ Testing ]] && [[ ! "$line" =~ Build ]]; then
                    in_commands_section=false
                fi

                # Collect commands from code blocks
                if [[ "$line" == '```bash' ]] || [[ "$line" == '```shell' ]] || [[ "$line" == '```' && "$collecting_commands" == "true" ]]; then
                    if [[ "$line" == '```' ]]; then
                        collecting_commands=false
                    else
                        collecting_commands=true
                    fi
                    continue
                fi

                if [[ "$collecting_commands" == "true" ]] && [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
                    # Skip placeholder commands
                    if [[ ! "$line" =~ \{.*\} ]]; then
                        commands+=("$line")
                    fi
                fi
            done < "$plan_file"
        fi
    done <<< "$features"

    # If no commands found in plans, provide defaults based on project type
    if [[ ${#commands[@]} -eq 0 ]]; then
        # Check for common project indicators
        if [[ -f "$main_root/pyproject.toml" ]] || [[ -f "$main_root/setup.py" ]]; then
            commands+=("pytest")
            commands+=("ruff check .")
        fi
        if [[ -f "$main_root/package.json" ]]; then
            commands+=("npm test")
            commands+=("npm run lint")
        fi
    fi

    # Return unique commands
    if [[ ${#commands[@]} -gt 0 ]]; then
        printf '%s\n' "${commands[@]}" | sort -u | head -20
    fi
}

gather_structure_info() {
    # Gather project structure information
    # Args: $1 - directory to analyze
    # Returns: structure summary for CLAUDE.md
    local target_dir="${1:-}"

    log_info "Gathering project structure" >&2

    if [[ ! -d "$target_dir" ]]; then
        echo "src/"
        echo "tests/"
        return 0
    fi

    # Get top-level directories, excluding common non-source dirs
    local structure=()
    local exclude_dirs=(".git" ".specify" "node_modules" "__pycache__" ".pytest_cache"
                        ".mypy_cache" ".ruff_cache" "venv" ".venv" "env" ".env"
                        "dist" "build" ".eggs" "*.egg-info" "worktrees" ".DS_Store")

    for item in "$target_dir"/*/; do
        if [[ -d "$item" ]]; then
            local dirname
            dirname=$(basename "$item")

            # Skip excluded directories
            local skip=false
            for exclude in "${exclude_dirs[@]}"; do
                if [[ "$dirname" == $exclude ]] || [[ "$dirname" == .* && "$exclude" == .* ]]; then
                    skip=true
                    break
                fi
            done

            if [[ "$skip" == "false" ]]; then
                structure+=("$dirname/")
            fi
        fi
    done

    # Return structure
    if [[ ${#structure[@]} -gt 0 ]]; then
        printf '%s\n' "${structure[@]}" | sort
    else
        echo "src/"
        echo "tests/"
    fi
}

gather_code_style_info() {
    # Gather code style information from plan.md files
    # Args: $1 - main repo root, $2 - specific feature (optional)
    # Returns: code style summary
    local main_root="${1:-}"
    local specific_feature="${2:-}"

    local specs_dir="$main_root/$SPEC_DIR_PATTERN"
    local styles=()

    # Get list of features to process
    local features
    if [[ -n "$specific_feature" ]]; then
        for dir in "$specs_dir"/"$specific_feature"-*/; do
            if [[ -d "$dir" ]]; then
                features=$(basename "$dir")
                break
            fi
        done
    else
        features=$(get_active_features "$main_root")
    fi

    while IFS= read -r feature; do
        [[ -z "$feature" ]] && continue

        local plan_file="$specs_dir/$feature/plan.md"
        if [[ -f "$plan_file" ]]; then
            # Extract Language/Version for style reference
            local lang_version
            lang_version=$(grep -E '^\*\*Language/Version\*\*:' "$plan_file" 2>/dev/null | head -1 | sed 's/\*\*Language\/Version\*\*:[[:space:]]*//')

            if [[ -n "$lang_version" ]]; then
                styles+=("$lang_version: Follow standard conventions")
            fi
        fi
    done <<< "$features"

    # Return unique styles
    if [[ ${#styles[@]} -gt 0 ]]; then
        printf '%s\n' "${styles[@]}" | sort -u
    fi
}

gather_recent_changes() {
    # Gather recent changes from active features
    # Args: $1 - main repo root, $2 - specific feature (optional)
    # Returns: recent changes summary
    local main_root="${1:-}"
    local specific_feature="${2:-}"

    local specs_dir="$main_root/$SPEC_DIR_PATTERN"
    local changes=()

    # Get list of features to process
    local features
    if [[ -n "$specific_feature" ]]; then
        for dir in "$specs_dir"/"$specific_feature"-*/; do
            if [[ -d "$dir" ]]; then
                features=$(basename "$dir")
                break
            fi
        done
    else
        features=$(get_active_features "$main_root")
    fi

    while IFS= read -r feature; do
        [[ -z "$feature" ]] && continue

        local plan_file="$specs_dir/$feature/plan.md"
        if [[ -f "$plan_file" ]]; then
            # Get a summary from the plan
            local lang_version
            lang_version=$(grep -E '^\*\*Language/Version\*\*:' "$plan_file" 2>/dev/null | head -1 | sed 's/\*\*Language\/Version\*\*:[[:space:]]*//')

            local deps
            deps=$(grep -E '^\*\*Primary Dependencies\*\*:' "$plan_file" 2>/dev/null | head -1 | sed 's/\*\*Primary Dependencies\*\*:[[:space:]]*//')

            if [[ -n "$lang_version" ]]; then
                local change="$feature: Added $lang_version"
                if [[ -n "$deps" ]]; then
                    change="$change + $deps"
                fi
                changes+=("$change")
            fi
        fi
    done <<< "$features"

    # Return changes
    if [[ ${#changes[@]} -gt 0 ]]; then
        printf '%s\n' "${changes[@]}"
    fi
}

get_project_name() {
    # Get project name from various sources
    # Args: $1 - target directory
    local target_dir="${1:-}"

    # Try pyproject.toml
    if [[ -f "$target_dir/pyproject.toml" ]]; then
        local name
        name=$(grep -E '^name\s*=' "$target_dir/pyproject.toml" 2>/dev/null | head -1 | sed 's/.*=\s*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/')
        if [[ -n "$name" ]]; then
            echo "$name"
            return 0
        fi
    fi

    # Try package.json
    if [[ -f "$target_dir/package.json" ]]; then
        local name
        name=$(grep -E '"name"' "$target_dir/package.json" 2>/dev/null | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [[ -n "$name" ]]; then
            echo "$name"
            return 0
        fi
    fi

    # Fall back to directory name
    basename "$target_dir"
}

generate_claude_md() {
    # Generate new CLAUDE.md content
    # Args: $1 - main repo root, $2 - target directory, $3 - feature ID (optional)
    # Output: Generated CLAUDE.md content to stdout
    local main_root="${1:-}"
    local target_dir="${2:-$main_root}"
    local feature_id="${3:-}"

    log_info "Generating CLAUDE.md content" >&2

    local current_date
    current_date=$(date +%Y-%m-%d)

    # Get project name
    local project_name
    if [[ -n "$feature_id" ]]; then
        # For feature-specific context, use feature branch name
        for dir in "$main_root/$SPEC_DIR_PATTERN"/"$feature_id"-*/; do
            if [[ -d "$dir" ]]; then
                project_name=$(basename "$dir")
                break
            fi
        done
        project_name="${project_name:-$feature_id}"
    else
        project_name=$(get_project_name "$target_dir")
    fi

    # Gather information
    local technologies
    technologies=$(gather_technology_info "$main_root" "$feature_id")

    local structure
    structure=$(gather_structure_info "$target_dir")

    local commands
    commands=$(gather_command_info "$main_root" "$feature_id")

    local code_styles
    code_styles=$(gather_code_style_info "$main_root" "$feature_id")

    local recent_changes
    recent_changes=$(gather_recent_changes "$main_root" "$feature_id")

    # Extract existing manual sections
    local manual_content
    manual_content=$(extract_manual_sections "$target_dir/$CLAUDE_MD")

    # Generate the content
    cat << EOF
# $project_name Development Guidelines

Auto-generated from all feature plans. Last updated: $current_date

## Active Technologies

EOF

    # Add technologies
    if [[ -n "$technologies" ]]; then
        while IFS= read -r tech; do
            [[ -n "$tech" ]] && echo "- $tech"
        done <<< "$technologies"
    else
        echo "- No technologies defined yet"
    fi

    cat << 'EOF'

## Project Structure

```text
EOF

    # Add structure
    if [[ -n "$structure" ]]; then
        while IFS= read -r item; do
            [[ -n "$item" ]] && echo "$item"
        done <<< "$structure"
    else
        echo "src/"
        echo "tests/"
    fi

    cat << 'EOF'
```

## Commands

EOF

    # Add commands
    if [[ -n "$commands" ]]; then
        while IFS= read -r cmd; do
            [[ -n "$cmd" ]] && echo "$cmd"
        done <<< "$commands"
    else
        echo "# No commands defined yet"
    fi

    cat << 'EOF'

## Code Style

EOF

    # Add code styles
    if [[ -n "$code_styles" ]]; then
        while IFS= read -r style; do
            [[ -n "$style" ]] && echo "$style"
        done <<< "$code_styles"
    else
        echo "Follow standard conventions for the project's primary language"
    fi

    cat << 'EOF'

## Recent Changes

EOF

    # Add recent changes
    if [[ -n "$recent_changes" ]]; then
        while IFS= read -r change; do
            [[ -n "$change" ]] && echo "- $change"
        done <<< "$recent_changes"
    else
        echo "- No recent changes tracked"
    fi

    cat << EOF

$MANUAL_START
EOF

    # Preserve manual content
    if [[ -n "$manual_content" ]]; then
        echo "$manual_content"
    fi

    cat << EOF
$MANUAL_END
EOF
}

compare_context() {
    # Compare generated context with existing
    # Args: $1 - new content, $2 - existing file path
    # Returns: 0 if same, 1 if different
    local new_content="${1:-}"
    local existing_file="${2:-}"

    if [[ ! -f "$existing_file" ]]; then
        # No existing file means different
        return 1
    fi

    local existing_content
    existing_content=$(cat "$existing_file")

    # Normalize whitespace for comparison
    local new_normalized
    local existing_normalized
    new_normalized=$(echo "$new_content" | sed 's/[[:space:]]*$//' | sed '/^$/d')
    existing_normalized=$(echo "$existing_content" | sed 's/[[:space:]]*$//' | sed '/^$/d')

    if [[ "$new_normalized" == "$existing_normalized" ]]; then
        return 0
    else
        return 1
    fi
}

write_claude_md() {
    # Write updated CLAUDE.md
    # Args: $1 - content, $2 - output path
    local content="${1:-}"
    local output_path="${2:-$CLAUDE_MD}"

    log_info "Writing $output_path"

    # Ensure parent directory exists
    local parent_dir
    parent_dir=$(dirname "$output_path")
    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir" || {
            log_error "Failed to create directory: $parent_dir"
            return 1
        }
    fi

    # Write the file
    echo "$content" > "$output_path" || {
        log_error "Failed to write to $output_path"
        return 1
    }

    return 0
}

update_worktree_context() {
    # Update context in a specific worktree
    # Args: $1 - worktree path, $2 - main repo root, $3 - feature ID, $4 - check only flag
    local worktree_path="${1:-}"
    local main_root="${2:-}"
    local feature_id="${3:-}"
    local check_only="${4:-false}"

    log_info "Updating context in worktree: $worktree_path"

    if [[ ! -d "$worktree_path" ]]; then
        log_warning "Worktree not found: $worktree_path"
        return 1
    fi

    # Generate content for this worktree
    local content
    content=$(generate_claude_md "$main_root" "$worktree_path" "$feature_id")

    local claude_md_path="$worktree_path/$CLAUDE_MD"

    if [[ "$check_only" == "true" ]]; then
        if compare_context "$content" "$claude_md_path"; then
            log_info "Context is up-to-date in $worktree_path"
            return 0
        else
            log_warning "Context is out-of-date in $worktree_path"
            return 2
        fi
    else
        write_claude_md "$content" "$claude_md_path"
        return $?
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local feature_id=""
    local update_all=false
    local check_only=false
    local updated_count=0
    local outdated_count=0
    local error_count=0
    local updated_files=()

    # Parse command line arguments
    parse_common_args "$@"
    set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --feature)
                if [[ -n "${2:-}" ]]; then
                    feature_id="$2"
                    shift 2
                else
                    log_error "--feature requires a value"
                    exit 1
                fi
                ;;
            --all)
                update_all=true
                shift
                ;;
            --check)
                check_only=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                exit 1
                ;;
        esac
    done

    require_git

    log_info "Updating agent context"

    # Get main repository root
    local main_root
    main_root=$(get_main_repo_root) || {
        log_error "Could not determine main repository root"
        exit 1
    }

    # Get current repo root (may be worktree)
    local repo_root
    repo_root=$(get_repo_root) || {
        log_error "Could not determine repository root"
        exit 1
    }

    # Get current feature if not specified and not updating all
    if [[ -z "$feature_id" ]] && [[ "$update_all" != "true" ]]; then
        local current_branch
        current_branch=$(get_current_branch)

        if check_feature_branch "$current_branch"; then
            feature_id=$(extract_feature_id "$current_branch")
            log_info "Using feature ID from current branch: $feature_id"
        fi
    fi

    # Determine what to update
    if [[ "$update_all" == "true" ]]; then
        # Update main repo CLAUDE.md
        log_info "Updating main repository context"
        local main_content
        main_content=$(generate_claude_md "$main_root" "$main_root" "")

        if [[ "$check_only" == "true" ]]; then
            if compare_context "$main_content" "$main_root/$CLAUDE_MD"; then
                log_info "Main repository context is up-to-date"
            else
                log_warning "Main repository context is out-of-date"
                ((outdated_count++))
            fi
        else
            if write_claude_md "$main_content" "$main_root/$CLAUDE_MD"; then
                ((updated_count++))
                updated_files+=("$main_root/$CLAUDE_MD")
            else
                ((error_count++))
            fi
        fi

        # Update all worktrees
        while IFS=: read -r wt_path wt_branch; do
            [[ -z "$wt_path" ]] && continue

            # Skip main repo
            if [[ "$wt_path" == "$main_root" ]]; then
                continue
            fi

            # Extract feature ID from branch
            local wt_feature_id=""
            if check_feature_branch "$wt_branch"; then
                wt_feature_id=$(extract_feature_id "$wt_branch")
            fi

            local result
            if update_worktree_context "$wt_path" "$main_root" "$wt_feature_id" "$check_only"; then
                if [[ "$check_only" != "true" ]]; then
                    ((updated_count++))
                    updated_files+=("$wt_path/$CLAUDE_MD")
                fi
            else
                result=$?
                if [[ "$result" == "2" ]]; then
                    ((outdated_count++))
                else
                    ((error_count++))
                fi
            fi
        done < <(list_worktrees)

    elif [[ -n "$feature_id" ]]; then
        # Update specific feature's worktree
        local wt_path=""

        # Find worktree for this feature
        while IFS=: read -r path branch; do
            if [[ "$branch" =~ ^${feature_id}- ]]; then
                wt_path="$path"
                break
            fi
        done < <(list_worktrees)

        if [[ -z "$wt_path" ]]; then
            # No worktree, update current directory if it matches
            if [[ "$repo_root" != "$main_root" ]]; then
                wt_path="$repo_root"
            else
                log_warning "No worktree found for feature $feature_id"
                wt_path="$main_root"
            fi
        fi

        local content
        content=$(generate_claude_md "$main_root" "$wt_path" "$feature_id")

        if [[ "$check_only" == "true" ]]; then
            if compare_context "$content" "$wt_path/$CLAUDE_MD"; then
                log_info "Context is up-to-date"
            else
                log_warning "Context is out-of-date"
                ((outdated_count++))
            fi
        else
            if write_claude_md "$content" "$wt_path/$CLAUDE_MD"; then
                ((updated_count++))
                updated_files+=("$wt_path/$CLAUDE_MD")
            else
                ((error_count++))
            fi
        fi
    else
        # Update current directory
        local content
        content=$(generate_claude_md "$main_root" "$repo_root" "$feature_id")

        if [[ "$check_only" == "true" ]]; then
            if compare_context "$content" "$repo_root/$CLAUDE_MD"; then
                log_info "Context is up-to-date"
            else
                log_warning "Context is out-of-date"
                ((outdated_count++))
            fi
        else
            if write_claude_md "$content" "$repo_root/$CLAUDE_MD"; then
                ((updated_count++))
                updated_files+=("$repo_root/$CLAUDE_MD")
            else
                ((error_count++))
            fi
        fi
    fi

    # Output results
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        local files_json="[]"
        if [[ ${#updated_files[@]} -gt 0 ]]; then
            files_json=$(json_array "${updated_files[@]}")
        fi

        cat << EOF
{
  "success": $(json_bool "$([[ $error_count -eq 0 ]] && echo true || echo false)"),
  "check_mode": $(json_bool "$check_only"),
  "updated_count": $updated_count,
  "outdated_count": $outdated_count,
  "error_count": $error_count,
  "files": $files_json
}
EOF
    else
        if [[ "$check_only" == "true" ]]; then
            if [[ $outdated_count -gt 0 ]]; then
                log_warning "Context is out-of-date ($outdated_count file(s) need updating)"
                exit 2
            else
                log_success "Context is up-to-date"
            fi
        else
            if [[ $error_count -gt 0 ]]; then
                log_error "Completed with $error_count error(s)"
                exit 1
            elif [[ $updated_count -gt 0 ]]; then
                log_success "Agent context updated ($updated_count file(s))"
                for f in "${updated_files[@]}"; do
                    echo "  - $f"
                done
            else
                log_info "No files needed updating"
            fi
        fi
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

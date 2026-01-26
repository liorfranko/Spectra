#!/usr/bin/env bash
# =============================================================================
# archive-feature.sh - Archive completed feature (merge and cleanup)
# =============================================================================
# This script handles the archival of a completed feature including:
# - Merging the feature branch to main (or specified target)
# - Cleaning up the git worktree
# - Archiving or removing the feature specification
# - Updating project status
#
# Usage:
#   ./archive-feature.sh [feature-id] [options]
#
# Arguments:
#   feature-id    Feature ID to archive (uses current branch if not provided)
#
# Options:
#   --target <branch>    Target branch for merge (default: main)
#   --no-merge           Skip merge, just cleanup worktree
#   --keep-spec          Don't archive the spec directory
#   --delete-branch      Delete the feature branch after merge
#   --force              Force cleanup even with uncommitted changes or incomplete tasks
#   --dry-run            Show what would be done without doing it
#   --json               Output results in JSON format
#
# Examples:
#   ./archive-feature.sh 042
#   ./archive-feature.sh --target develop
#   ./archive-feature.sh 042 --no-merge --force
#   ./archive-feature.sh --delete-branch
#
# Exit codes:
#   0 - Feature archived successfully
#   1 - Error during archival
#   2 - Aborted by user
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

# Default target branch for merging
DEFAULT_TARGET_BRANCH="main"

# Archive directory for completed features
ARCHIVE_DIR="specs/.archive"

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << 'EOF'
Usage: archive-feature.sh [feature-id] [options]

Archive a completed feature by merging and cleaning up.

Arguments:
  feature-id    Feature ID or branch name to archive (uses current branch if not provided)

Options:
  --target <branch>    Target branch for merge (default: main)
  --no-merge           Skip merge, just cleanup worktree
  --keep-spec          Don't archive the spec directory
  --delete-branch      Delete the feature branch after merge
  --force              Force cleanup even with uncommitted changes or incomplete tasks
  --dry-run            Show what would be done without doing it
  --json               Output results in JSON format
  --help               Show this help message
  --version            Show version information

Examples:
  ./archive-feature.sh 042
  ./archive-feature.sh --target develop
  ./archive-feature.sh 042 --no-merge --force
  ./archive-feature.sh --delete-branch
EOF
}

get_feature_branch() {
    # Get full branch name for feature ID
    # Args: $1 - feature ID (e.g., "042" or "042-feature-name")
    local feature_id="${1:-}"

    if [[ -z "$feature_id" ]]; then
        echo ""
        return 1
    fi

    # If it already matches the full pattern, return it
    if check_feature_branch "$feature_id"; then
        echo "$feature_id"
        return 0
    fi

    # If it's just a 3-digit ID, find matching branch
    if [[ "$feature_id" =~ ^[0-9]{3}$ ]]; then
        # Search for matching branches
        local matching_branch
        matching_branch=$(git branch --list "${feature_id}-*" --format='%(refname:short)' 2>/dev/null | head -n 1)

        if [[ -n "$matching_branch" ]]; then
            echo "$matching_branch"
            return 0
        fi

        # Also check worktrees
        while IFS=: read -r path branch; do
            if [[ "$branch" == "${feature_id}-"* ]]; then
                echo "$branch"
                return 0
            fi
        done < <(list_worktrees)
    fi

    echo ""
    return 1
}

check_feature_complete() {
    # Check if the feature is in 'complete' phase
    # Args: $1 - feature branch name
    local feature_branch="${1:-}"

    if [[ -z "$feature_branch" ]]; then
        return 1
    fi

    local main_root
    main_root=$(get_main_repo_root) || return 1

    local spec_dir="$main_root/specs/$feature_branch"
    local state_file="$spec_dir/state.yaml"

    if [[ ! -f "$state_file" ]]; then
        log_warning "State file not found: $state_file"
        return 1
    fi

    local phase
    phase=$(grep "^phase:" "$state_file" 2>/dev/null | sed 's/^phase:[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [[ "$phase" == "complete" ]]; then
        return 0
    else
        log_warning "Feature phase is '$phase', expected 'complete'"
        return 1
    fi
}

check_merge_status() {
    # Check if feature branch can be cleanly merged
    # Args: $1 - feature branch, $2 - target branch
    local feature_branch="${1:-}"
    local target_branch="${2:-}"

    if [[ -z "$feature_branch" ]] || [[ -z "$target_branch" ]]; then
        return 1
    fi

    log_info "Checking merge status: $feature_branch -> $target_branch"

    # Fetch latest from remote if available
    git fetch origin "$target_branch" 2>/dev/null || true

    # Try a dry-run merge
    local merge_base
    merge_base=$(git merge-base "$target_branch" "$feature_branch" 2>/dev/null) || {
        log_error "Cannot determine merge base between $target_branch and $feature_branch"
        return 1
    }

    # Check if there are any conflicts
    local result
    result=$(git merge-tree "$merge_base" "$target_branch" "$feature_branch" 2>/dev/null) || true

    if echo "$result" | grep -q "^<<<<<<<"; then
        log_error "Merge would result in conflicts"
        return 1
    fi

    log_info "Merge check passed - no conflicts detected"
    return 0
}

perform_merge() {
    # Merge feature branch to target
    # Args: $1 - feature branch, $2 - target branch, $3 - dry_run flag
    local feature_branch="${1:-}"
    local target_branch="${2:-}"
    local dry_run="${3:-false}"

    if [[ -z "$feature_branch" ]] || [[ -z "$target_branch" ]]; then
        log_error "Feature branch and target branch are required"
        return 1
    fi

    log_info "Merging $feature_branch to $target_branch"

    # Get current branch to restore later
    local original_branch
    original_branch=$(get_current_branch)

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would merge $feature_branch into $target_branch"
        return 0
    fi

    # Stash any uncommitted changes
    local stash_result
    stash_result=$(git stash push -m "archive-feature: temporary stash" 2>&1) || true

    # Switch to target branch
    git checkout "$target_branch" || {
        log_error "Failed to checkout $target_branch"
        return 1
    }

    # Pull latest changes
    git pull origin "$target_branch" 2>/dev/null || true

    # Perform the merge
    local feature_id
    feature_id=$(extract_feature_id "$feature_branch")
    local merge_message="Merge feature $feature_branch

Feature ID: $feature_id
Merged by: archive-feature.sh"

    git merge --no-ff "$feature_branch" -m "$merge_message" || {
        log_error "Merge failed. Aborting merge."
        git merge --abort 2>/dev/null || true
        git checkout "$original_branch" 2>/dev/null || true
        return 1
    }

    log_success "Merge completed successfully"

    # Push to remote if available
    if git remote | grep -q "^origin$"; then
        log_info "Pushing to origin/$target_branch"
        git push origin "$target_branch" || {
            log_warning "Failed to push to origin. You may need to push manually."
        }
    fi

    # Restore original branch if different from target
    if [[ "$original_branch" != "$target_branch" ]] && [[ -n "$original_branch" ]]; then
        git checkout "$original_branch" 2>/dev/null || true
    fi

    # Restore stashed changes if any
    if [[ "$stash_result" != *"No local changes"* ]]; then
        git stash pop 2>/dev/null || true
    fi

    return 0
}

cleanup_worktree() {
    # Remove git worktree for the feature
    # Args: $1 - feature branch, $2 - force flag, $3 - dry_run flag
    local feature_branch="${1:-}"
    local force="${2:-false}"
    local dry_run="${3:-false}"

    if [[ -z "$feature_branch" ]]; then
        log_error "Feature branch is required"
        return 1
    fi

    # Find the worktree path
    local worktree_path
    worktree_path=$(get_worktree_path "$feature_branch")

    if [[ -z "$worktree_path" ]]; then
        log_info "No worktree found for $feature_branch"
        return 0
    fi

    log_info "Cleaning up worktree: $worktree_path"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would remove worktree: $worktree_path"
        return 0
    fi

    # Check for uncommitted changes if not forcing
    if [[ "$force" != "true" ]]; then
        if [[ -d "$worktree_path" ]]; then
            pushd "$worktree_path" > /dev/null || return 1
            if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                log_error "Worktree has uncommitted changes. Use --force to override."
                popd > /dev/null
                return 1
            fi
            popd > /dev/null
        fi
    fi

    # Remove the worktree
    local remove_args=("--force")
    if [[ "$force" == "true" ]]; then
        remove_args+=("--force")
    fi

    git worktree remove "${remove_args[@]}" "$worktree_path" 2>/dev/null || {
        # If standard removal fails, try prune
        log_warning "Standard worktree removal failed, attempting prune"
        git worktree prune
        if [[ -d "$worktree_path" ]]; then
            if [[ "$force" == "true" ]]; then
                rm -rf "$worktree_path"
                log_info "Force removed worktree directory"
            else
                log_error "Failed to remove worktree directory"
                return 1
            fi
        fi
    }

    log_success "Worktree removed: $worktree_path"
    return 0
}

delete_feature_branch() {
    # Delete the feature branch after merge
    # Args: $1 - branch name, $2 - dry_run flag
    local branch_name="${1:-}"
    local dry_run="${2:-false}"

    if [[ -z "$branch_name" ]]; then
        log_error "Branch name is required"
        return 1
    fi

    log_info "Deleting branch: $branch_name"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would delete branch: $branch_name"
        return 0
    fi

    # Make sure we're not on the branch we're trying to delete
    local current_branch
    current_branch=$(get_current_branch)

    if [[ "$current_branch" == "$branch_name" ]]; then
        git checkout main 2>/dev/null || git checkout master 2>/dev/null || {
            log_error "Cannot delete current branch. Please switch to another branch first."
            return 1
        }
    fi

    # Delete local branch (use -d for safety, -D if merged)
    git branch -d "$branch_name" 2>/dev/null || {
        log_warning "Branch not fully merged, using force delete"
        git branch -D "$branch_name" || {
            log_error "Failed to delete local branch: $branch_name"
            return 1
        }
    }

    # Delete remote branch if it exists
    if git ls-remote --exit-code --heads origin "$branch_name" >/dev/null 2>&1; then
        log_info "Deleting remote branch: origin/$branch_name"
        git push origin --delete "$branch_name" 2>/dev/null || {
            log_warning "Failed to delete remote branch. You may need to delete it manually."
        }
    fi

    log_success "Branch deleted: $branch_name"
    return 0
}

archive_spec_directory() {
    # Move spec directory to archive
    # Args: $1 - feature branch, $2 - dry_run flag
    local feature_branch="${1:-}"
    local dry_run="${2:-false}"

    if [[ -z "$feature_branch" ]]; then
        log_error "Feature branch is required"
        return 1
    fi

    local main_root
    main_root=$(get_main_repo_root) || {
        log_error "Could not determine main repository root"
        return 1
    }

    local spec_dir="$main_root/specs/$feature_branch"
    local archive_dir="$main_root/$ARCHIVE_DIR"

    if [[ ! -d "$spec_dir" ]]; then
        log_info "Spec directory not found: $spec_dir"
        return 0
    fi

    log_info "Archiving spec directory: $spec_dir"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would move $spec_dir to $archive_dir/"
        return 0
    fi

    # Create archive directory if it doesn't exist
    mkdir -p "$archive_dir"

    # Add archive timestamp to state.yaml
    local state_file="$spec_dir/state.yaml"
    if [[ -f "$state_file" ]]; then
        local archive_date
        archive_date=$(date +%Y-%m-%d)
        echo "archived_at: $archive_date" >> "$state_file"
    fi

    # Move to archive
    mv "$spec_dir" "$archive_dir/" || {
        log_error "Failed to move spec directory to archive"
        return 1
    }

    log_success "Spec directory archived to: $archive_dir/$feature_branch"
    return 0
}

update_project_status() {
    # Update project tracking to reflect archived feature
    # Args: $1 - feature branch, $2 - dry_run flag
    local feature_branch="${1:-}"
    local dry_run="${2:-false}"

    if [[ -z "$feature_branch" ]]; then
        return 0
    fi

    log_info "Updating project status"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would update project status for $feature_branch"
        return 0
    fi

    local main_root
    main_root=$(get_main_repo_root) || return 1

    # Update CLAUDE.md if it exists (remove references to archived feature)
    local claude_md="$main_root/CLAUDE.md"
    if [[ -f "$claude_md" ]]; then
        # Note: We don't automatically modify CLAUDE.md as it might have important context
        log_info "CLAUDE.md exists - manual review recommended"
    fi

    # If there's a project status file, update it
    local status_file="$main_root/.specify/status.yaml"
    if [[ -f "$status_file" ]]; then
        # Add archived feature to completed list
        local feature_id
        feature_id=$(extract_feature_id "$feature_branch")
        local archive_date
        archive_date=$(date +%Y-%m-%d)

        # Check if there's an archived_features section
        if grep -q "^archived_features:" "$status_file" 2>/dev/null; then
            # Append to existing section
            sed -i.bak "/^archived_features:/a\\
  - feature: $feature_branch\\
    archived_at: $archive_date" "$status_file"
            rm -f "${status_file}.bak"
        fi
    fi

    return 0
}

confirm_action() {
    # Prompt user for confirmation
    # Args: $1 - action description
    local action="${1:-perform this action}"

    # Skip confirmation if not interactive
    if [[ ! -t 0 ]]; then
        return 0
    fi

    read -p "Are you sure you want to $action? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# =============================================================================
# Main
# =============================================================================

main() {
    local feature_id=""
    local target_branch="$DEFAULT_TARGET_BRANCH"
    local do_merge=true
    local keep_spec=false
    local delete_branch_flag=false
    local force=false
    local dry_run=false

    # Parse command line arguments
    parse_common_args "$@"
    set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                if [[ -n "${2:-}" ]]; then
                    target_branch="$2"
                    shift 2
                else
                    log_error "--target requires a branch name"
                    exit 1
                fi
                ;;
            --no-merge)
                do_merge=false
                shift
                ;;
            --keep-spec)
                keep_spec=true
                shift
                ;;
            --delete-branch)
                delete_branch_flag=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$feature_id" ]]; then
                    feature_id="$1"
                    shift
                else
                    log_error "Unexpected argument: $1"
                    exit 1
                fi
                ;;
        esac
    done

    require_git

    # Get main repository root
    local main_root
    main_root=$(get_main_repo_root) || {
        log_error "Could not determine main repository root"
        exit 1
    }

    # If no feature ID provided, try to get from current branch
    if [[ -z "$feature_id" ]]; then
        local current_branch
        current_branch=$(get_current_branch)

        if check_feature_branch "$current_branch"; then
            feature_id="$current_branch"
            log_info "Using feature from current branch: $feature_id"
        else
            log_error "Could not determine feature ID. Please provide one."
            exit 1
        fi
    fi

    # Resolve feature branch from ID
    local feature_branch
    feature_branch=$(get_feature_branch "$feature_id") || {
        log_error "Could not find feature branch for: $feature_id"
        exit 1
    }

    log_info "Archiving feature: $feature_branch"

    # Validate feature is complete (unless --force)
    if [[ "$force" != "true" ]]; then
        if ! check_feature_complete "$feature_branch"; then
            log_error "Feature is not marked as complete. Use --force to override."
            exit 1
        fi
    fi

    # Show what will be done
    if [[ "$OUTPUT_FORMAT" != "json" ]]; then
        echo ""
        echo "Archive plan for: $feature_branch"
        echo "  Target branch:     $target_branch"
        echo "  Perform merge:     $do_merge"
        echo "  Archive spec:      $(if [[ "$keep_spec" == "true" ]]; then echo "no"; else echo "yes"; fi)"
        echo "  Delete branch:     $delete_branch_flag"
        echo "  Force mode:        $force"
        echo "  Dry run:           $dry_run"
        echo ""
    fi

    # Confirm unless force or dry-run
    if [[ "$force" != "true" ]] && [[ "$dry_run" != "true" ]]; then
        if ! confirm_action "archive feature '$feature_branch'"; then
            log_info "Aborted by user"
            exit 2
        fi
    fi

    # Track results for JSON output
    local merge_result="skipped"
    local worktree_result="skipped"
    local archive_result="skipped"
    local branch_delete_result="skipped"

    # Step 1: Perform merge (unless --no-merge)
    if [[ "$do_merge" == "true" ]]; then
        if check_merge_status "$feature_branch" "$target_branch" || [[ "$force" == "true" ]]; then
            if perform_merge "$feature_branch" "$target_branch" "$dry_run"; then
                merge_result="success"
            else
                merge_result="failed"
                if [[ "$force" != "true" ]]; then
                    log_error "Merge failed. Use --force to continue with cleanup."
                    exit 1
                fi
            fi
        else
            merge_result="conflict"
            if [[ "$force" != "true" ]]; then
                log_error "Merge would have conflicts. Resolve conflicts first or use --force."
                exit 1
            fi
        fi
    fi

    # Step 2: Cleanup worktree
    if cleanup_worktree "$feature_branch" "$force" "$dry_run"; then
        worktree_result="success"
    else
        worktree_result="failed"
        log_warning "Worktree cleanup failed"
    fi

    # Step 3: Archive spec (unless --keep-spec)
    if [[ "$keep_spec" != "true" ]]; then
        if archive_spec_directory "$feature_branch" "$dry_run"; then
            archive_result="success"
        else
            archive_result="failed"
            log_warning "Spec archival failed"
        fi
    fi

    # Step 4: Delete feature branch (if --delete-branch)
    if [[ "$delete_branch_flag" == "true" ]]; then
        if delete_feature_branch "$feature_branch" "$dry_run"; then
            branch_delete_result="success"
        else
            branch_delete_result="failed"
            log_warning "Branch deletion failed"
        fi
    fi

    # Step 5: Update project status
    update_project_status "$feature_branch" "$dry_run"

    # Output results
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        cat << EOF
{
  "success": true,
  "feature": {
    "branch": "$feature_branch",
    "id": "$(extract_feature_id "$feature_branch")"
  },
  "target_branch": "$target_branch",
  "dry_run": $dry_run,
  "results": {
    "merge": "$merge_result",
    "worktree_cleanup": "$worktree_result",
    "spec_archive": "$archive_result",
    "branch_delete": "$branch_delete_result"
  }
}
EOF
    else
        if [[ "$dry_run" == "true" ]]; then
            log_success "[DRY RUN] Archive plan completed for: $feature_branch"
        else
            log_success "Feature archived: $feature_branch"
            echo ""
            echo "Results:"
            echo "  Merge:             $merge_result"
            echo "  Worktree cleanup:  $worktree_result"
            echo "  Spec archive:      $archive_result"
            echo "  Branch delete:     $branch_delete_result"
        fi
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

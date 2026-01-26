#!/usr/bin/env bash
# speckit/scripts/common.sh - Common utilities for SpecKit scripts
# Provides path helpers, JSON output, error handling, and utility functions
set -euo pipefail

# =============================================================================
# Path Helper Functions
# =============================================================================

# Get the git repository root directory
# Usage: repo_root=$(get_repo_root)
get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || {
        error "Not in a git repository"
    }
}

# Get the specs/ directory path
# Usage: specs_dir=$(get_specs_dir)
get_specs_dir() {
    local repo_root
    repo_root=$(get_repo_root)
    echo "${repo_root}/specs"
}

# Get the current feature directory
# Uses branch name pattern [###]-[short-name] or accepts feature identifier as argument
# Usage: feature_dir=$(get_feature_dir) or feature_dir=$(get_feature_dir "003-user-auth")
get_feature_dir() {
    local feature_id="${1:-}"
    local specs_dir
    specs_dir=$(get_specs_dir)

    if [[ -z "$feature_id" ]]; then
        # Extract from current branch name
        local branch_name
        branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
            error "Failed to get current branch name"
        }

        # Match pattern: [###]-[short-name] (e.g., 003-user-auth)
        if [[ "$branch_name" =~ ^([0-9]{3}-[a-z0-9-]+) ]]; then
            feature_id="${BASH_REMATCH[1]}"
        else
            error "Branch name '${branch_name}' does not match feature pattern [###]-[short-name]"
        fi
    fi

    echo "${specs_dir}/${feature_id}"
}

# Calculate the next feature number (highest across all branches + 1)
# Returns zero-padded 3-digit number (e.g., "004")
# Usage: next_num=$(get_next_feature_number)
get_next_feature_number() {
    local specs_dir
    specs_dir=$(get_specs_dir)

    local max_num=0

    # Check existing feature directories in specs/
    if [[ -d "$specs_dir" ]]; then
        while IFS= read -r dir; do
            local basename
            basename=$(basename "$dir")
            # Extract number from pattern [###]-[short-name]
            if [[ "$basename" =~ ^([0-9]{3})- ]]; then
                local num="${BASH_REMATCH[1]}"
                # Remove leading zeros for numeric comparison
                num=$((10#$num))
                if (( num > max_num )); then
                    max_num=$num
                fi
            fi
        done < <(find "$specs_dir" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null)
    fi

    # Also check git branches for feature patterns
    while IFS= read -r branch; do
        # Extract number from pattern [###]-[short-name]
        if [[ "$branch" =~ ^([0-9]{3})- ]]; then
            local num="${BASH_REMATCH[1]}"
            # Remove leading zeros for numeric comparison
            num=$((10#$num))
            if (( num > max_num )); then
                max_num=$num
            fi
        fi
    done < <(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)

    # Return next number, zero-padded to 3 digits
    printf "%03d\n" $((max_num + 1))
}

# =============================================================================
# JSON Output Functions
# =============================================================================

# Output a JSON object with key-value pairs
# Usage: json_output "key1" "value1" "key2" "value2" ...
# Keys and values are automatically escaped
json_output() {
    local first=true
    echo -n "{"

    while (( $# >= 2 )); do
        local key="$1"
        local value="$2"
        shift 2

        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo -n ","
        fi

        # Escape special JSON characters in key and value
        key=$(echo -n "$key" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\n/\\n/g')
        value=$(echo -n "$value" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\n/\\n/g')

        echo -n "\"${key}\":\"${value}\""
    done

    echo "}"
}

# Output a JSON error object
# Usage: json_error "Error message" [exit_code]
json_error() {
    local message="$1"
    local exit_code="${2:-1}"

    json_output "error" "true" "message" "$message" "exit_code" "$exit_code"
    return "$exit_code"
}

# =============================================================================
# Error Handling Functions
# =============================================================================

# Print error message to stderr and exit
# Usage: error "Something went wrong"
error() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: ${message}" >&2
    exit "$exit_code"
}

# Print warning message to stderr (does not exit)
# Usage: warn "This might be a problem"
warn() {
    local message="$1"
    echo "WARNING: ${message}" >&2
}

# Print info message to stderr (for --verbose mode)
# Usage: info "Processing file..."
info() {
    local message="$1"
    echo "INFO: ${message}" >&2
}

# =============================================================================
# Utility Functions
# =============================================================================

# Check if a command exists, error if not
# Usage: require_command "jq" "jq is required for JSON parsing"
require_command() {
    local cmd="$1"
    local message="${2:-Command '${cmd}' is required but not found}"

    if ! command -v "$cmd" &>/dev/null; then
        error "$message"
    fi
}

# Check if a file exists, error if not
# Usage: require_file "/path/to/file" "Configuration file not found"
require_file() {
    local filepath="$1"
    local message="${2:-File '${filepath}' not found}"

    if [[ ! -f "$filepath" ]]; then
        error "$message"
    fi
}

# Convert text to kebab-case slug (lowercase, hyphens, 2-4 words)
# Usage: slug=$(slugify "My Feature Name")
# Output: my-feature-name
slugify() {
    local text="$1"
    local max_words="${2:-4}"

    # Convert to lowercase, replace non-alphanumeric with hyphens, collapse multiple hyphens
    local slug
    slug=$(echo "$text" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')

    # Limit to max_words (count by hyphens)
    local word_count
    word_count=$(echo "$slug" | tr '-' '\n' | wc -l | tr -d ' ')

    if (( word_count > max_words )); then
        slug=$(echo "$slug" | cut -d'-' -f1-"${max_words}")
    fi

    # Ensure at least 2 words worth of content (or return as-is if single word)
    echo "$slug"
}

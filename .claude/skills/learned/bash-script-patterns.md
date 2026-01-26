# Skill: Bash Script Patterns for ProjSpec

## Standard Script Structure

```bash
#!/usr/bin/env bash
# =============================================================================
# script-name.sh - Brief description
# =============================================================================
# Detailed description of what this script does
#
# Usage:
#   ./script-name.sh [options]
#
# Options:
#   --json          Output results in JSON format
#   --help          Show this help message
#   --version       Show version information
#
# Exit codes:
#   0 - Success
#   1 - Error
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
# ...

# Helper Functions
# ...

# Main
main() {
    parse_common_args "$@"
    set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

    # Parse script-specific arguments
    # ...

    require_git

    # Script logic
    # ...

    # Output results
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        cat << EOF
{
  "success": true,
  "data": {...}
}
EOF
    else
        log_success "Operation completed"
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Key Patterns from common.sh

### Logging Functions
- `log_info "message"` - Blue info message
- `log_success "message"` - Green success message
- `log_warning "message"` - Yellow warning
- `log_error "message"` - Red error

### Git Utilities
- `require_git` - Exit if not in git repo
- `get_repo_root` - Get repository root path
- `get_main_repo_root` - Get main repo (not worktree)
- `get_current_branch` - Current branch name
- `check_feature_branch` - Validate branch matches NNN-* pattern

### JSON Utilities
- `json_bool "true/false"` - Output JSON boolean
- `json_string "value"` - Escape and quote string
- `json_array "item1" "item2"` - Create JSON array

### Common Args Parsing
- `parse_common_args "$@"` - Parse --json, --help, --version
- `OUTPUT_FORMAT` - "json" or "text"
- `REMAINING_ARGS` - Unparsed arguments

## File Sync Pattern

When scripts exist in both locations, keep them in sync:
1. `scripts/script-name.sh` - Development version
2. `src/projspec_cli/resources/scripts/bash/script-name.sh` - Bundled version

Always update both files and verify they're identical.

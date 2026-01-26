"""Default configuration templates for ProjSpec.

This module contains default YAML templates used when initializing
new ProjSpec projects. These templates provide sensible defaults
while including comments to guide users in customization.
"""

DEFAULT_CONFIG = """\
# ProjSpec configuration
version: "1.0"

project:
  # name: my-project  # Defaults to directory name
  description: ""

worktrees:
  base_path: "./worktrees"

context:
  always_include:
    - "CLAUDE.md"
"""

DEFAULT_WORKFLOW = """\
# ProjSpec workflow definition
workflow:
  name: default
  phases:
    - spec      # Define feature specification
    - plan      # Create implementation plan
    - tasks     # Generate task breakdown
    - implement # Execute tasks
    - review    # Review implementation
"""

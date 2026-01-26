"""
ProjSpec CLI entry point.

Provides the command-line interface for ProjSpec with subcommands:
- init: Initialize a new .projspec/ structure in the current directory
- status: Display active specs with progress information
"""

import argparse
from importlib import resources
from pathlib import Path

from projspec.defaults import DEFAULT_CONFIG, DEFAULT_WORKFLOW

# Phase template filenames bundled with the package
PHASE_TEMPLATES = ["spec.md", "plan.md", "tasks.md", "implement.md", "review.md"]


def create_parser() -> argparse.ArgumentParser:
    """Create and configure the argument parser with subcommands."""
    parser = argparse.ArgumentParser(
        prog="projspec",
        description="ProjSpec - Project specification and task management tool",
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # init subcommand
    subparsers.add_parser(
        "init",
        help="Initialize a new .projspec/ structure in the current directory",
    )

    # status subcommand
    subparsers.add_parser(
        "status",
        help="Display active specs with progress information",
    )

    return parser


def _copy_default_phases(target_dir: Path) -> None:
    """Copy bundled phase templates to the target directory.

    Uses importlib.resources to read phase template files from the package's
    assets/phases/ directory and writes them to the specified target directory.

    Args:
        target_dir: The directory where phase templates should be copied to.
                   Typically .projspec/phases/ in the project root.
    """
    # Access the bundled assets package (Python 3.9+)
    assets_phases = resources.files("projspec.assets.phases")

    for template_name in PHASE_TEMPLATES:
        template_file = assets_phases.joinpath(template_name)
        content = template_file.read_text(encoding="utf-8")
        (target_dir / template_name).write_text(content, encoding="utf-8")


def _run_init() -> None:
    """Initialize a new .projspec/ structure in the current directory."""
    cwd = Path.cwd()
    projspec_dir = cwd / ".projspec"

    # Create directories
    phases_dir = projspec_dir / "phases"
    phases_dir.mkdir(parents=True, exist_ok=True)
    (projspec_dir / "specs" / "active").mkdir(parents=True, exist_ok=True)
    (projspec_dir / "specs" / "completed").mkdir(parents=True, exist_ok=True)
    (cwd / "worktrees").mkdir(exist_ok=True)

    # Copy bundled phase templates
    _copy_default_phases(phases_dir)

    # Write config files
    (projspec_dir / "config.yaml").write_text(DEFAULT_CONFIG)
    (projspec_dir / "workflow.yaml").write_text(DEFAULT_WORKFLOW)

    print("Initialized ProjSpec in current directory.")


def main() -> None:
    """Main entry point for the ProjSpec CLI."""
    parser = create_parser()
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return

    # Command dispatch
    if args.command == "init":
        _run_init()
    elif args.command == "status":
        # Handler will be implemented in T025
        pass


if __name__ == "__main__":
    main()

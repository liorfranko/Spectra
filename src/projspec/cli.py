"""
ProjSpec CLI entry point.

Provides the command-line interface for ProjSpec with subcommands:
- init: Initialize a new .projspec/ structure in the current directory
- status: Display active specs with progress information
"""

import argparse
import sys
from importlib import resources
from pathlib import Path

from rich.console import Console
from rich.table import Table

from projspec.defaults import DEFAULT_CONFIG, DEFAULT_WORKFLOW
from projspec.state import load_active_specs

# Module-level console instance for Rich output
console = Console()


def _is_git_repo(path: Path) -> bool:
    """Check if the given path is inside a git repository.

    Checks for the presence of a .git directory or file (worktrees use a file)
    in the given path or any of its parent directories.

    Args:
        path: The directory path to check.

    Returns:
        True if the path is inside a git repository, False otherwise.
    """
    current = path.resolve()
    while current != current.parent:
        git_path = current / ".git"
        if git_path.exists():
            return True
        current = current.parent
    # Check root directory as well
    if (current / ".git").exists():
        return True
    return False

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

    # Check if we're in a git repository
    if not _is_git_repo(cwd):
        console.print(
            "[bold red]Error:[/bold red] Not a git repository. "
            "Please run 'git init' first."
        )
        sys.exit(1)

    projspec_dir = cwd / ".projspec"

    # Check if already initialized
    if projspec_dir.exists():
        console.print("[yellow]ProjSpec is already initialized in this directory.[/yellow]")
        return

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

    # Display success message with details
    console.print("[bold green]✓[/bold green] Initialized ProjSpec in current directory.")
    console.print("  Created .projspec/config.yaml")
    console.print("  Created .projspec/workflow.yaml")
    console.print(f"  Created .projspec/phases/ ({len(PHASE_TEMPLATES)} templates)")


def _get_phase_color(phase: str) -> str:
    """Return the Rich color for a given phase.

    Args:
        phase: The phase name (new, spec, plan, tasks, implement, review).

    Returns:
        Rich color name based on phase category:
        - yellow: early phases (new, spec, plan)
        - cyan: active development (tasks, implement)
        - green: near completion (review)
    """
    if phase in ("new", "spec", "plan"):
        return "yellow"
    elif phase in ("tasks", "implement"):
        return "cyan"
    elif phase == "review":
        return "green"
    return "white"


def _print_spec_status(specs: list) -> None:
    """Display specs in a formatted Rich table.

    Creates a table with columns for ID, Name, Phase (with color coding),
    and Branch. The phase column is color-coded based on the workflow stage.

    Args:
        specs: List of SpecState objects to display.
    """
    table = Table(title=f"Active Specs ({len(specs)})")

    table.add_column("ID", style="bold")
    table.add_column("Name")
    table.add_column("Phase")
    table.add_column("Branch", style="dim")

    for spec in specs:
        # Handle both enum and string phase values
        phase_value = spec.phase.value if hasattr(spec.phase, "value") else spec.phase
        phase_color = _get_phase_color(phase_value)
        phase_styled = f"[{phase_color}]{phase_value}[/{phase_color}]"
        table.add_row(spec.spec_id, spec.name, phase_styled, spec.branch)

    console.print(table)


def _run_status() -> None:
    """Display status of all active specs.

    Reads specs from .projspec/specs/active/ and displays basic information
    about each spec. Handles the case when ProjSpec is not initialized.
    """
    cwd = Path.cwd()
    projspec_dir = cwd / ".projspec"

    # Check if ProjSpec is initialized
    if not projspec_dir.exists():
        console.print(
            "[bold red]Error:[/bold red] ProjSpec is not initialized. "
            "Run 'projspec init' first."
        )
        sys.exit(1)

    # Load active specs
    specs = load_active_specs(cwd)

    if not specs:
        console.print("[yellow]No active specs found.[/yellow]")
        return

    # Display specs in a formatted table
    _print_spec_status(specs)


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
        _run_status()


if __name__ == "__main__":
    main()

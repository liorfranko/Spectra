"""
Main CLI commands for ProjSpec.

This module defines the primary CLI interface using Typer, including:
- init: Initialize a new ProjSpec project
- status: Display current project and feature status
- version: Show version information
- check: Validate project configuration and prerequisites
"""

from __future__ import annotations

import platform
import subprocess
import sys
from pathlib import Path
from typing import Annotated

import typer
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from projspec_cli import __version__
from projspec_cli.utils.git import has_git, is_git_repo

# Note: These imports will be used once services are implemented
# from projspec_cli.services.init import init_project
# from projspec_cli.services.status import display_status

# Rich console for formatted output
console = Console()
err_console = Console(stderr=True)

# Main Typer application
app = typer.Typer(
    name="projspec",
    help="Project specification management for Claude Code.\n\nA CLI tool for managing project specifications, features, and worktrees in multi-feature development workflows.",
    no_args_is_help=True,
    rich_markup_mode="rich",
    add_completion=False,
)


@app.command()
def version() -> None:
    """Display version information including Python and platform details."""
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    platform_info = f"{platform.system()} {platform.release()}"

    console.print(
        Panel(
            f"[bold blue]ProjSpec[/bold blue] version [green]{__version__}[/green]\n"
            f"Python [cyan]{python_version}[/cyan]\n"
            f"Platform [dim]{platform_info}[/dim]",
            title="Version Info",
            border_style="blue",
        )
    )


@app.command()
def check() -> None:
    """Verify installed tools and prerequisites for ProjSpec.

    Checks for:
    - Git installation and version
    - Python version compatibility
    - Whether current directory is a git repository
    """
    table = Table(title="Prerequisites Check", show_header=True, header_style="bold")
    table.add_column("Check", style="cyan", no_wrap=True)
    table.add_column("Status", justify="center")
    table.add_column("Details", style="dim")

    all_passed = True

    # Check Python version
    python_version = sys.version_info
    python_ok = python_version >= (3, 11)
    python_version_str = f"{python_version.major}.{python_version.minor}.{python_version.micro}"

    if python_ok:
        table.add_row(
            "Python version",
            "[green]PASS[/green]",
            f"v{python_version_str} (>= 3.11 required)",
        )
    else:
        all_passed = False
        table.add_row(
            "Python version",
            "[red]FAIL[/red]",
            f"v{python_version_str} (>= 3.11 required)",
        )

    # Check Git availability and version
    git_available = has_git()
    git_version_str = "Not installed"

    if git_available:
        try:
            result = subprocess.run(
                ["git", "--version"],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode == 0:
                # Parse "git version X.Y.Z"
                git_version_str = result.stdout.strip().replace("git version ", "v")
        except (FileNotFoundError, OSError):
            pass

        table.add_row(
            "Git installed",
            "[green]PASS[/green]",
            git_version_str,
        )
    else:
        all_passed = False
        table.add_row(
            "Git installed",
            "[red]FAIL[/red]",
            "Git is required for ProjSpec",
        )

    # Check if current directory is a git repository
    cwd = Path.cwd()
    in_repo = is_git_repo(cwd)

    if in_repo:
        table.add_row(
            "Git repository",
            "[green]PASS[/green]",
            f"In repository at {cwd}",
        )
    else:
        # This is not a hard failure, just informational
        table.add_row(
            "Git repository",
            "[yellow]INFO[/yellow]",
            "Not in a git repository (optional for some commands)",
        )

    # Check for worktree support (git >= 2.5.0)
    worktree_supported = False
    if git_available:
        try:
            result = subprocess.run(
                ["git", "worktree", "list"],
                capture_output=True,
                text=True,
                check=False,
                cwd=cwd if in_repo else None,
            )
            worktree_supported = result.returncode == 0 or "worktree" not in result.stderr.lower()
        except (FileNotFoundError, OSError):
            pass

        if worktree_supported:
            table.add_row(
                "Git worktree support",
                "[green]PASS[/green]",
                "Worktree commands available",
            )
        else:
            table.add_row(
                "Git worktree support",
                "[yellow]WARN[/yellow]",
                "Git worktree not available (git >= 2.5.0 required)",
            )

    console.print()
    console.print(table)
    console.print()

    if all_passed:
        console.print("[bold green]All prerequisites satisfied.[/bold green]")
    else:
        console.print("[bold red]Some prerequisites are missing.[/bold red]")
        raise typer.Exit(code=1)


@app.command()
def init(
    project_name: Annotated[
        str | None,
        typer.Argument(
            help="Name for the project (defaults to current directory name)",
        ),
    ] = None,
    here: Annotated[
        bool,
        typer.Option(
            "--here",
            help="Initialize in the current directory without creating a subdirectory",
        ),
    ] = False,
    force: Annotated[
        bool,
        typer.Option(
            "--force",
            "-f",
            help="Overwrite existing configuration if present",
        ),
    ] = False,
    no_git: Annotated[
        bool,
        typer.Option(
            "--no-git",
            help="Skip git repository initialization",
        ),
    ] = False,
) -> None:
    """Initialize ProjSpec in a directory.

    Creates the projspec.yaml configuration file and sets up the specs/ directory
    structure for managing feature specifications.

    Examples:
        projspec init my-project    # Create new project directory
        projspec init --here        # Initialize in current directory
        projspec init --force       # Reinitialize, overwriting existing config
    """
    # Delegate to the init service
    # The service will be implemented in a later task
    console.print("[bold]Initializing ProjSpec project...[/bold]")

    if project_name:
        console.print(f"Project name: [cyan]{project_name}[/cyan]")
    else:
        cwd = Path.cwd()
        console.print(f"Project name: [cyan]{cwd.name}[/cyan] (from current directory)")

    if here:
        console.print("Mode: Initialize in current directory")
    if force:
        console.print("Mode: Force overwrite existing configuration")
    if no_git:
        console.print("Mode: Skip git initialization")

    # TODO: Call init_project service once implemented
    # init_project(project_name=project_name, here=here, force=force, no_git=no_git)
    console.print()
    console.print("[yellow]Note: Full initialization will be implemented in a later task.[/yellow]")


@app.command()
def status(
    json_output: Annotated[
        bool,
        typer.Option(
            "--json",
            help="Output status in JSON format",
        ),
    ] = False,
) -> None:
    """Display status of all active features.

    Shows the current state of feature specifications, worktrees, and branches
    in the project.

    Examples:
        projspec status         # Show formatted status
        projspec status --json  # Output as JSON for scripting
    """
    # Delegate to the status service
    # The service will be implemented in a later task
    if json_output:
        console.print('{"status": "not_implemented", "message": "Status service pending implementation"}')
    else:
        console.print("[bold]ProjSpec Status[/bold]")
        console.print()

        # Check if we're in a git repo
        cwd = Path.cwd()
        if is_git_repo(cwd):
            console.print(f"[dim]Current directory:[/dim] {cwd}")

            # Try to get current branch
            try:
                result = subprocess.run(
                    ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                    capture_output=True,
                    text=True,
                    check=False,
                    cwd=cwd,
                )
                if result.returncode == 0:
                    branch = result.stdout.strip()
                    console.print(f"[dim]Current branch:[/dim] {branch}")
            except (FileNotFoundError, OSError):
                pass
        else:
            console.print("[yellow]Not in a git repository.[/yellow]")

        console.print()
        # TODO: Call display_status service once implemented
        # display_status(json_output=json_output)
        console.print("[yellow]Note: Full status display will be implemented in a later task.[/yellow]")


# Entry point for the CLI
def main() -> None:
    """Entry point for the ProjSpec CLI."""
    app()


if __name__ == "__main__":
    main()

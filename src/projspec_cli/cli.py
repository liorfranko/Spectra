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
from projspec_cli.services.init import initialize_project
from projspec_cli.services.status import (
    format_status_json,
    format_status_table,
    format_feature_status_json,
    get_feature_status,
    get_project_status,
    get_status_summary,
)
from projspec_cli.utils.git import has_git, is_git_repo

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

    Creates the .specify/ directory structure and sets up the project
    for managing feature specifications with worktrees.

    Examples:
        projspec init my-project    # Create new project directory
        projspec init --here        # Initialize in current directory
        projspec init --force       # Reinitialize, overwriting existing config
    """
    # Determine the target path
    cwd = Path.cwd()

    if here or project_name is None:
        # Initialize in current directory
        target_path = cwd
        effective_name = project_name if project_name else cwd.name
    else:
        # Create a new subdirectory
        target_path = cwd / project_name
        effective_name = project_name
        # Create the directory if it doesn't exist
        if not target_path.exists():
            target_path.mkdir(parents=True)

    # Call the init service
    result = initialize_project(
        path=target_path,
        project_name=effective_name,
        force=force,
        no_git=no_git,
    )

    if result.success:
        # Display created items with checkmarks
        console.print()
        for item in result.created_files:
            console.print(f"[green]\u2713[/green] Created {item}")

        console.print()
        console.print(
            Panel(
                f"[bold green]ProjSpec initialized in[/bold green] {target_path}\n\n"
                f"Features will be created in [cyan]worktrees/[/cyan] with isolated working directories.\n"
                f"Run [bold]/speckit.specify[/bold] in Claude Code to create your first feature.",
                title="Initialization Complete",
                border_style="green",
            )
        )
    else:
        # Display error message
        err_console.print()
        err_console.print(
            Panel(
                f"[bold red]Initialization failed[/bold red]\n\n{result.message}",
                title="Error",
                border_style="red",
            )
        )
        raise typer.Exit(code=result.exit_code)


@app.command()
def status(
    feature: Annotated[
        str | None,
        typer.Option(
            "--feature",
            "-f",
            help="Show status for a specific feature (by ID or name)",
        ),
    ] = None,
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
        projspec status              # Show all features status
        projspec status --feature 001  # Show specific feature status
        projspec status --json       # Output as JSON for scripting
    """
    cwd = Path.cwd()

    # If a specific feature is requested
    if feature:
        feature_status = get_feature_status(feature, cwd)
        if feature_status is None:
            err_console.print(
                Panel(
                    f"[bold red]Feature not found:[/bold red] {feature}\n\n"
                    "Make sure the feature exists in specs/ directory.",
                    title="Error",
                    border_style="red",
                )
            )
            raise typer.Exit(code=1)

        if json_output:
            console.print(format_feature_status_json(feature_status))
        else:
            _display_feature_status(feature_status)
        return

    # Get full project status
    result = get_project_status(cwd)

    if not result.success:
        if json_output:
            console.print('{"success": false, "error": "' + result.message + '"}')
        else:
            err_console.print(
                Panel(
                    f"[bold red]Error:[/bold red] {result.message}",
                    title="Status Error",
                    border_style="red",
                )
            )
        raise typer.Exit(code=1)

    if result.project_status is None:
        if json_output:
            console.print('{"success": false, "error": "No project status available"}')
        else:
            console.print("[yellow]No project status available.[/yellow]")
        raise typer.Exit(code=1)

    project_status = result.project_status

    if json_output:
        console.print(format_status_json(project_status))
    else:
        _display_project_status(project_status)


def _display_feature_status(feature_status) -> None:
    """Display detailed status for a single feature using Rich formatting."""
    # Feature header panel
    phase_color = _get_phase_color(feature_status.phase.value)
    header_content = (
        f"[bold]{feature_status.full_name}[/bold]\n"
        f"Phase: [{phase_color}]{feature_status.phase.value}[/{phase_color}]\n"
        f"Branch: [cyan]{feature_status.branch}[/cyan]"
    )
    if feature_status.description:
        header_content += f"\n\n{feature_status.description}"

    console.print()
    console.print(
        Panel(
            header_content,
            title=f"Feature {feature_status.id}",
            border_style=phase_color,
        )
    )

    # Artifacts table
    console.print()
    artifacts_table = Table(title="Artifacts", show_header=True, header_style="bold")
    artifacts_table.add_column("File", style="cyan")
    artifacts_table.add_column("Status", justify="center")

    artifacts_table.add_row(
        "spec.md",
        "[green]Present[/green]" if feature_status.has_spec else "[dim]Missing[/dim]",
    )
    artifacts_table.add_row(
        "plan.md",
        "[green]Present[/green]" if feature_status.has_plan else "[dim]Missing[/dim]",
    )
    artifacts_table.add_row(
        "tasks.md",
        "[green]Present[/green]" if feature_status.has_tasks else "[dim]Missing[/dim]",
    )
    artifacts_table.add_row(
        "state.yaml",
        "[green]Present[/green]" if feature_status.has_state else "[dim]Missing[/dim]",
    )

    console.print(artifacts_table)

    # Task progress
    if feature_status.task_progress.total > 0:
        console.print()
        progress = feature_status.task_progress
        task_table = Table(title="Task Progress", show_header=True, header_style="bold")
        task_table.add_column("Status", style="cyan")
        task_table.add_column("Count", justify="right")

        task_table.add_row("Pending", str(progress.pending))
        task_table.add_row("In Progress", f"[yellow]{progress.in_progress}[/yellow]")
        task_table.add_row("Completed", f"[green]{progress.completed}[/green]")
        task_table.add_row("Skipped", f"[dim]{progress.skipped}[/dim]")
        task_table.add_row(
            "[bold]Total[/bold]",
            f"[bold]{progress.total}[/bold] ({progress.percentage:.0f}% complete)",
        )

        console.print(task_table)

        if feature_status.next_available_task:
            console.print()
            console.print(
                f"[bold]Next available task:[/bold] [cyan]{feature_status.next_available_task}[/cyan]"
            )

    console.print()


def _display_project_status(project_status) -> None:
    """Display full project status using Rich formatting."""
    summary = get_status_summary(project_status)

    # Project header
    console.print()

    # Calculate task completion bar
    task_completion_bar = ""
    if summary["total_tasks"] > 0:
        completed_pct = summary["task_completion"]
        bar_width = 20
        filled = int(bar_width * completed_pct / 100)
        task_completion_bar = (
            f"\n\nTask Progress: [green]{'=' * filled}[/green]"
            f"[dim]{'=' * (bar_width - filled)}[/dim] "
            f"{completed_pct:.0f}%"
        )

    header_content = (
        f"[bold blue]{project_status.project_name}[/bold blue]\n"
        f"[dim]Root:[/dim] {project_status.project_root}\n"
        f"[dim]Features:[/dim] {project_status.total_features}"
        f"{task_completion_bar}"
    )

    # Add current context info
    if project_status.current_branch:
        header_content += f"\n\n[dim]Current branch:[/dim] {project_status.current_branch}"
    if project_status.is_worktree:
        header_content += " [cyan](worktree)[/cyan]"

    console.print(
        Panel(
            header_content,
            title="ProjSpec Status",
            border_style="blue",
        )
    )

    # Phase summary
    if project_status.features_by_phase:
        console.print()
        phase_table = Table(title="Features by Phase", show_header=True, header_style="bold")
        phase_table.add_column("Phase", style="cyan")
        phase_table.add_column("Count", justify="right")

        for phase, count in project_status.features_by_phase.items():
            phase_color = _get_phase_color(phase)
            phase_table.add_row(f"[{phase_color}]{phase}[/{phase_color}]", str(count))

        console.print(phase_table)

    # Features table
    if project_status.features:
        console.print()
        features_table = Table(title="Features", show_header=True, header_style="bold")
        features_table.add_column("ID", style="cyan", no_wrap=True)
        features_table.add_column("Name")
        features_table.add_column("Phase", justify="center")
        features_table.add_column("Tasks", justify="center")
        features_table.add_column("Branch", style="dim")
        features_table.add_column("Next Task", style="yellow")

        rows = format_status_table(project_status)
        for row in rows:
            features_table.add_row(*row)

        console.print(features_table)
    else:
        console.print()
        console.print("[dim]No features found. Create your first feature with /speckit.specify[/dim]")

    console.print()


def _get_phase_color(phase: str) -> str:
    """Get the display color for a phase."""
    phase_colors = {
        "new": "dim",
        "spec": "blue",
        "plan": "cyan",
        "tasks": "magenta",
        "implement": "yellow",
        "complete": "green",
    }
    return phase_colors.get(phase.lower(), "white")


# Entry point for the CLI
def main() -> None:
    """Entry point for the ProjSpec CLI."""
    app()


if __name__ == "__main__":
    main()

"""
Main CLI commands for ProjSpec.

This module defines the primary CLI interface using Typer, including:
- init: Initialize a new ProjSpec project
- status: Display current project and feature status
- version: Show version information
- check: Validate project configuration and prerequisites
"""

from __future__ import annotations

import json
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
from projspec_cli.utils.paths import get_project_root, get_specify_dir, get_specs_dir

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


def _get_git_version() -> str | None:
    """Get the git version string, or None if git is not available."""
    try:
        result = subprocess.run(
            ["git", "--version"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 0:
            # Parse "git version X.Y.Z" or "git version X.Y.Z (platform)"
            version_str = result.stdout.strip()
            # Extract version number
            parts = version_str.split()
            if len(parts) >= 3:
                return parts[2]  # Return just the version number
            return version_str
    except (FileNotFoundError, OSError):
        pass
    return None


def _get_gh_version() -> str | None:
    """Get the GitHub CLI version string, or None if gh is not available."""
    try:
        result = subprocess.run(
            ["gh", "--version"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 0:
            # Parse "gh version X.Y.Z (date)"
            first_line = result.stdout.strip().split("\n")[0]
            parts = first_line.split()
            if len(parts) >= 3:
                return parts[2]  # Return just the version number
            return first_line
    except (FileNotFoundError, OSError):
        pass
    return None


@app.command()
def version(
    json_output: Annotated[
        bool,
        typer.Option(
            "--json",
            help="Output version information in JSON format",
        ),
    ] = False,
) -> None:
    """Display version information including Python, Git, and platform details.

    Examples:
        projspec version           # Show version info with formatting
        projspec version --json    # Output as JSON for scripting
    """
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    platform_info = f"{platform.system()} {platform.release()}"
    git_version = _get_git_version()
    gh_version = _get_gh_version()

    if json_output:
        version_data = {
            "projspec": __version__,
            "python": python_version,
            "platform": platform_info,
            "git": git_version,
            "gh": gh_version,
        }
        console.print(json.dumps(version_data, indent=2))
    else:
        git_line = (
            f"Git [cyan]{git_version}[/cyan]"
            if git_version
            else "Git [dim]not installed[/dim]"
        )
        gh_line = (
            f"GitHub CLI [cyan]{gh_version}[/cyan]"
            if gh_version
            else "GitHub CLI [dim]not installed[/dim]"
        )

        console.print(
            Panel(
                f"[bold blue]ProjSpec[/bold blue] version [green]{__version__}[/green]\n"
                f"Python [cyan]{python_version}[/cyan]\n"
                f"{git_line}\n"
                f"{gh_line}\n"
                f"Platform [dim]{platform_info}[/dim]",
                title="Version Info",
                border_style="blue",
            )
        )


@app.command()
def check(
    json_output: Annotated[
        bool,
        typer.Option(
            "--json",
            help="Output check results in JSON format",
        ),
    ] = False,
) -> None:
    """Verify installed tools, prerequisites, and project structure for ProjSpec.

    Checks for:
    - Python version compatibility (>= 3.11)
    - Git installation and version
    - GitHub CLI (gh) availability (optional)
    - Whether current directory is a git repository
    - Git worktree support
    - ProjSpec project structure (.specify/, specs/, templates/)

    Examples:
        projspec check           # Run all checks with formatting
        projspec check --json    # Output as JSON for scripting
    """
    cwd = Path.cwd()
    checks: list[dict] = []
    all_passed = True

    # Check Python version
    python_version = sys.version_info
    python_ok = python_version >= (3, 11)
    python_version_str = f"{python_version.major}.{python_version.minor}.{python_version.micro}"

    checks.append({
        "name": "Python version",
        "status": "pass" if python_ok else "fail",
        "details": f"v{python_version_str} (>= 3.11 required)",
        "required": True,
    })
    if not python_ok:
        all_passed = False

    # Check Git availability and version
    git_available = has_git()
    git_version_str = _get_git_version()

    if git_available and git_version_str:
        checks.append({
            "name": "Git installed",
            "status": "pass",
            "details": f"v{git_version_str}",
            "required": True,
        })
    else:
        all_passed = False
        checks.append({
            "name": "Git installed",
            "status": "fail",
            "details": "Git is required for ProjSpec",
            "required": True,
        })

    # Check GitHub CLI availability
    gh_version = _get_gh_version()
    if gh_version:
        checks.append({
            "name": "GitHub CLI (gh)",
            "status": "pass",
            "details": f"v{gh_version}",
            "required": False,
        })
    else:
        checks.append({
            "name": "GitHub CLI (gh)",
            "status": "info",
            "details": "Not installed (optional, needed for GitHub integration)",
            "required": False,
        })

    # Check if current directory is a git repository
    in_repo = is_git_repo(cwd)

    if in_repo:
        checks.append({
            "name": "Git repository",
            "status": "pass",
            "details": f"In repository at {cwd}",
            "required": True,
        })
    else:
        checks.append({
            "name": "Git repository",
            "status": "info",
            "details": "Not in a git repository (optional for some commands)",
            "required": False,
        })

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
            checks.append({
                "name": "Git worktree support",
                "status": "pass",
                "details": "Worktree commands available",
                "required": False,
            })
        else:
            checks.append({
                "name": "Git worktree support",
                "status": "warn",
                "details": "Git worktree not available (git >= 2.5.0 required)",
                "required": False,
            })

    # Check project structure
    project_root = get_project_root(cwd)

    if project_root:
        checks.append({
            "name": "ProjSpec project",
            "status": "pass",
            "details": f"Project root at {project_root}",
            "required": False,
        })

        # Check .specify/ directory
        specify_dir = get_specify_dir(cwd)
        if specify_dir and specify_dir.exists():
            checks.append({
                "name": ".specify/ directory",
                "status": "pass",
                "details": str(specify_dir),
                "required": False,
            })
        else:
            checks.append({
                "name": ".specify/ directory",
                "status": "warn",
                "details": "Not found - run 'projspec init' to create",
                "required": False,
            })

        # Check specs/ directory
        specs_dir = get_specs_dir(cwd)
        if specs_dir and specs_dir.exists():
            checks.append({
                "name": "specs/ directory",
                "status": "pass",
                "details": str(specs_dir),
                "required": False,
            })
        else:
            checks.append({
                "name": "specs/ directory",
                "status": "warn",
                "details": "Not found - run 'projspec init' to create",
                "required": False,
            })

        # Check templates/ directory
        templates_dir = project_root / "templates"
        if templates_dir.exists():
            checks.append({
                "name": "templates/ directory",
                "status": "pass",
                "details": str(templates_dir),
                "required": False,
            })
        else:
            checks.append({
                "name": "templates/ directory",
                "status": "info",
                "details": "Not found (optional)",
                "required": False,
            })
    else:
        checks.append({
            "name": "ProjSpec project",
            "status": "info",
            "details": "Not in a ProjSpec project - run 'projspec init' to initialize",
            "required": False,
        })

    # JSON output
    if json_output:
        output = {
            "success": all_passed,
            "checks": checks,
        }
        console.print(json.dumps(output, indent=2))
        if not all_passed:
            raise typer.Exit(code=1)
        return

    # Rich table output
    table = Table(title="Prerequisites Check", show_header=True, header_style="bold")
    table.add_column("Check", style="cyan", no_wrap=True)
    table.add_column("Status", justify="center")
    table.add_column("Details", style="dim")

    status_styles = {
        "pass": "[green]PASS[/green]",
        "fail": "[red]FAIL[/red]",
        "warn": "[yellow]WARN[/yellow]",
        "info": "[blue]INFO[/blue]",
    }

    for check_item in checks:
        status_display = status_styles.get(check_item["status"], check_item["status"])
        table.add_row(
            check_item["name"],
            status_display,
            check_item["details"],
        )

    console.print()
    console.print(table)
    console.print()

    if all_passed:
        console.print("[bold green]All required prerequisites satisfied.[/bold green]")
    else:
        console.print("[bold red]Some required prerequisites are missing.[/bold red]")
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

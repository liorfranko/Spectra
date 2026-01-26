"""
Main CLI commands for ProjSpec.

This module defines the primary CLI interface using Typer, including:
- init: Initialize a new ProjSpec project
- status: Display current project and feature status
- version: Show version information
- check: Validate project configuration
"""

import typer

app = typer.Typer(
    name="projspec",
    help="Project specification management for Claude Code",
    no_args_is_help=True,
)


@app.command()
def version() -> None:
    """Show version information."""
    typer.echo("projspec version 0.1.0")


@app.command()
def init() -> None:
    """Initialize a new ProjSpec project."""
    typer.echo("Initializing ProjSpec project...")
    # TODO: Implement project initialization


@app.command()
def status() -> None:
    """Display current project and feature status."""
    typer.echo("ProjSpec status...")
    # TODO: Implement status display


@app.command()
def check() -> None:
    """Validate project configuration."""
    typer.echo("Checking project configuration...")
    # TODO: Implement configuration validation

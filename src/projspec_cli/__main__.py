"""
Entry point for running projspec_cli as a module.

Usage:
    python -m projspec_cli [COMMAND] [OPTIONS]
"""

from projspec_cli.cli import app

if __name__ == "__main__":
    app()

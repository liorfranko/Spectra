"""
ProjSpec CLI entry point.

Provides the command-line interface for ProjSpec with subcommands:
- init: Initialize a new .projspec/ structure in the current directory
- status: Display active specs with progress information
"""

import argparse


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


def main() -> None:
    """Main entry point for the ProjSpec CLI."""
    parser = create_parser()
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return

    # Command dispatch will be added in subsequent tasks
    if args.command == "init":
        # Handler will be implemented in T014
        pass
    elif args.command == "status":
        # Handler will be implemented in T025
        pass


if __name__ == "__main__":
    main()

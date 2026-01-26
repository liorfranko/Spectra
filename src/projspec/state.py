"""State management for ProjSpec specifications.

This module provides functions for loading and managing spec state from
the .projspec directory structure.
"""

from pathlib import Path

import yaml

from projspec.models import SpecState


def load_active_specs(base_path: Path | None = None) -> list[SpecState]:
    """Load all active specs from the .projspec/specs/active/ directory.

    Args:
        base_path: Optional base path to search from. Defaults to current directory.

    Returns:
        List of SpecState objects for all active specs.
        Returns empty list if no active specs found or directory doesn't exist.
    """
    if base_path is None:
        base_path = Path.cwd()

    active_dir = base_path / ".projspec" / "specs" / "active"

    if not active_dir.exists() or not active_dir.is_dir():
        return []

    specs: list[SpecState] = []

    for spec_dir in active_dir.iterdir():
        if not spec_dir.is_dir():
            continue

        state_file = spec_dir / "state.yaml"
        if not state_file.exists():
            continue

        try:
            with open(state_file) as f:
                data = yaml.safe_load(f)

            if data is not None:
                spec = SpecState(**data)
                specs.append(spec)
        except (yaml.YAMLError, TypeError, ValueError):
            # Skip specs with invalid YAML or data
            continue

    return specs


def get_current_spec(base_path: Path | None = None) -> SpecState | None:
    """Find the most recently modified active spec.

    Searches through all active specs and returns the one whose state.yaml
    file has the most recent modification time.

    Args:
        base_path: Optional base path to search from. Defaults to current directory.

    Returns:
        The SpecState of the most recently modified spec, or None if no specs exist.
    """
    specs = load_active_specs(base_path)

    if not specs:
        return None

    if base_path is None:
        base_path = Path.cwd()

    active_dir = base_path / ".projspec" / "specs" / "active"

    most_recent_spec: SpecState | None = None
    most_recent_mtime: float = 0.0

    for spec in specs:
        state_file = active_dir / spec.spec_id / "state.yaml"
        if state_file.exists():
            mtime = state_file.stat().st_mtime
            if mtime > most_recent_mtime:
                most_recent_mtime = mtime
                most_recent_spec = spec

    return most_recent_spec

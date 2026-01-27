#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

"""
Constants for Claude Code Hooks.
"""

import os
from pathlib import Path

# Base directory for all logs
# Default is 'logs' in the current working directory
LOG_BASE_DIR = os.environ.get("CLAUDE_HOOKS_LOG_DIR", "logs")

def get_session_log_dir(session_id: str) -> Path:
    """
    Get the log directory for a specific session.
    
    Args:
        session_id: The Claude session ID
        
    Returns:
        Path object for the session's log directory
    """
    return Path(LOG_BASE_DIR) / session_id

def ensure_session_log_dir(session_id: str) -> Path:
    """
    Ensure the log directory for a session exists.

    Args:
        session_id: The Claude session ID

    Returns:
        Path object for the session's log directory
    """
    log_dir = get_session_log_dir(session_id)
    log_dir.mkdir(parents=True, exist_ok=True)
    return log_dir


def append_to_json_log(log_path: Path, data: dict) -> None:
    """
    Append data to a JSON log file, creating if needed.

    Handles reading existing JSON array, appending new data, and writing back.
    Gracefully handles corrupted or empty files.

    Args:
        log_path: Path to the JSON log file
        data: Dictionary to append to the log
    """
    import json

    log_data = []
    if log_path.exists():
        try:
            with open(log_path, 'r') as f:
                log_data = json.load(f)
        except (json.JSONDecodeError, ValueError):
            log_data = []

    log_data.append(data)

    with open(log_path, 'w') as f:
        json.dump(log_data, f, indent=2)
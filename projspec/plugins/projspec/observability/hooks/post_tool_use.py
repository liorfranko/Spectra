#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

import json
import sys
from utils.constants import ensure_session_log_dir, append_to_json_log

def main():
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)

        # Extract session_id
        session_id = input_data.get('session_id', 'unknown')

        # Ensure session log directory exists and append to log
        log_dir = ensure_session_log_dir(session_id)
        log_path = log_dir / 'post_tool_use.json'
        append_to_json_log(log_path, input_data)

        sys.exit(0)

    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Exit cleanly on any other error
        sys.exit(0)

if __name__ == '__main__':
    main()
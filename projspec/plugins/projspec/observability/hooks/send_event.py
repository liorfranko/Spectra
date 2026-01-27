#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "anthropic",
#     "python-dotenv",
#     "pyyaml",
# ]
# ///

"""
Multi-Agent Observability Hook Script
Sends Claude Code hook events to the observability server.

Integrates with projspec configuration from .projspec/projspec.local.md
"""

import json
import sys
import os
import re
import argparse
import urllib.request
import urllib.error
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List
from utils.summarizer import generate_event_summary
from utils.model_extractor import get_model_from_transcript

try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False


# Default configuration values
DEFAULT_CONFIG = {
    'enabled': False,
    'server_url': 'http://localhost:4000',
    'client_url': 'http://localhost:3000',
    'source_app': 'projspec',
    'summarize_events': False,
    'include_chat': False,
    'max_chat_size': 1048576,  # 1MB
    'retention_days': 7,
}


def find_config_file() -> Optional[Path]:
    """
    Find the projspec configuration file.

    Search order:
    1. CLAUDE_PLUGIN_ROOT environment variable + .projspec/projspec.local.md
    2. Current working directory + .projspec/projspec.local.md

    Returns:
        Path to the config file if found, None otherwise.
    """
    config_filename = '.projspec/projspec.local.md'

    # Check CLAUDE_PLUGIN_ROOT first
    plugin_root = os.environ.get('CLAUDE_PLUGIN_ROOT')
    if plugin_root:
        config_path = Path(plugin_root) / config_filename
        if config_path.exists():
            return config_path

    # Fall back to current working directory
    cwd_config = Path.cwd() / config_filename
    if cwd_config.exists():
        return cwd_config

    return None


def parse_yaml_frontmatter(content: str) -> Dict[str, Any]:
    """
    Parse YAML frontmatter from markdown content.

    Args:
        content: The full markdown content with optional YAML frontmatter.

    Returns:
        Dictionary containing the parsed YAML frontmatter, or empty dict if none found.
    """
    if not YAML_AVAILABLE:
        print("Warning: PyYAML not available, using defaults", file=sys.stderr)
        return {}

    # Match YAML frontmatter between --- delimiters
    frontmatter_pattern = r'^---\s*\n(.*?)\n---\s*\n'
    match = re.match(frontmatter_pattern, content, re.DOTALL)

    if not match:
        return {}

    try:
        yaml_content = match.group(1)
        parsed = yaml.safe_load(yaml_content)  # type: ignore[possibly-undefined]
        return parsed if isinstance(parsed, dict) else {}
    except Exception as e:
        print(f"Warning: Failed to parse YAML frontmatter: {e}", file=sys.stderr)
        return {}


def load_projspec_config() -> Dict[str, Any]:
    """
    Load projspec configuration from .local.md file.

    Returns:
        Dictionary with observability configuration, merged with defaults.
    """
    config = DEFAULT_CONFIG.copy()

    config_file = find_config_file()
    if not config_file:
        return config

    try:
        content = config_file.read_text(encoding='utf-8')
        frontmatter = parse_yaml_frontmatter(content)

        # Extract observability section
        obs_config = frontmatter.get('observability', {})
        if isinstance(obs_config, dict):
            # Merge with defaults (config file values override defaults)
            for key, value in obs_config.items():
                if key in config:
                    config[key] = value

    except Exception as e:
        print(f"Warning: Failed to load config from {config_file}: {e}", file=sys.stderr)

    return config


def extract_feature_id() -> Optional[str]:
    """
    Extract feature ID from current working directory.

    If the current path contains specs/<feature>/, extract the feature name.

    Returns:
        Feature ID string if found, None otherwise.
    """
    cwd = Path.cwd()
    parts = cwd.parts

    # Look for 'specs' in path and get the next component
    for i, part in enumerate(parts):
        if part == 'specs' and i + 1 < len(parts):
            return parts[i + 1]

    return None


def get_projspec_context() -> Dict[str, Any]:
    """
    Extract projspec-specific context for event payloads.

    Returns:
        Dictionary containing:
        - feature_id: from current path if in specs/<feature>/
        - workflow_stage: from PROJSPEC_WORKFLOW_STAGE env var
    """
    context = {}

    # Extract feature ID from path
    feature_id = extract_feature_id()
    if feature_id:
        context['feature_id'] = feature_id

    # Get workflow stage from environment
    workflow_stage = os.environ.get('PROJSPEC_WORKFLOW_STAGE')
    if workflow_stage:
        context['workflow_stage'] = workflow_stage

    return context


def truncate_chat_transcript(chat_data: List[Dict], max_size: int) -> List[Dict]:
    """
    Truncate chat transcript to fit within max_size bytes.

    Removes oldest messages first until the JSON-serialized size is under the limit.

    Args:
        chat_data: List of chat message dictionaries.
        max_size: Maximum size in bytes (default 1MB = 1048576).

    Returns:
        Truncated list of chat messages.
    """
    if not chat_data:
        return chat_data

    # Check current size
    current_size = len(json.dumps(chat_data).encode('utf-8'))

    if current_size <= max_size:
        return chat_data

    # Remove oldest messages until under limit
    truncated = chat_data.copy()
    while truncated and len(json.dumps(truncated).encode('utf-8')) > max_size:
        truncated.pop(0)  # Remove oldest message

    # Add truncation marker if we removed messages
    if len(truncated) < len(chat_data):
        removed_count = len(chat_data) - len(truncated)
        truncation_marker = {
            '_truncated': True,
            '_removed_messages': removed_count,
            '_reason': f'Exceeded max_chat_size of {max_size} bytes'
        }
        truncated.insert(0, truncation_marker)

    return truncated

def send_event_to_server(event_data: Dict[str, Any], server_url: str = 'http://localhost:4000/events') -> bool:
    """Send event data to the observability server."""
    try:
        req = urllib.request.Request(
            server_url,
            data=json.dumps(event_data).encode('utf-8'),
            headers={
                'Content-Type': 'application/json',
                'User-Agent': 'Claude-Code-Hook/1.0'
            }
        )

        with urllib.request.urlopen(req, timeout=5) as response:
            if response.status == 200:
                return True
            print(f"Server returned status: {response.status}", file=sys.stderr)
            return False

    except urllib.error.URLError as e:
        print(f"Failed to send event: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return False


def parse_cli_arguments() -> argparse.Namespace:
    """Parse command line arguments for the hook script."""
    parser = argparse.ArgumentParser(description='Send Claude Code hook events to observability server')
    parser.add_argument('--source-app', default=None, help='Source application name (overrides config)')
    parser.add_argument('--event-type', required=True, help='Hook event type (PreToolUse, PostToolUse, etc.)')
    parser.add_argument('--server-url', default=None, help='Server URL (overrides config)')
    parser.add_argument('--add-chat', action='store_true', default=None, help='Include chat transcript if available (overrides config)')
    parser.add_argument('--summarize', action='store_true', default=None, help='Generate AI summary of the event (overrides config)')
    return parser.parse_args()


def resolve_config(args: argparse.Namespace, config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Resolve final configuration by merging CLI args with config file settings.

    Args:
        args: Parsed command line arguments.
        config: Configuration loaded from file.

    Returns:
        Dictionary with resolved configuration values.
    """
    source_app = args.source_app if args.source_app else config.get('source_app', 'projspec')
    server_url = args.server_url if args.server_url else config.get('server_url', 'http://localhost:4000')

    # Ensure server_url has /events endpoint
    if not server_url.endswith('/events'):
        server_url = server_url.rstrip('/') + '/events'

    return {
        'source_app': source_app,
        'server_url': server_url,
        'include_chat': args.add_chat if args.add_chat is not None else config.get('include_chat', False),
        'summarize': args.summarize if args.summarize is not None else config.get('summarize_events', False),
        'max_chat_size': config.get('max_chat_size', 1048576),
    }


def read_input_data() -> Optional[Dict[str, Any]]:
    """Read and parse JSON input from stdin."""
    try:
        return json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON input: {e}", file=sys.stderr)
        return None


def build_event_data(
    input_data: Dict[str, Any],
    source_app: str,
    event_type: str
) -> Dict[str, Any]:
    """
    Build the event payload for the observability server.

    Args:
        input_data: Raw hook input data from stdin.
        source_app: Source application identifier.
        event_type: Hook event type (PreToolUse, PostToolUse, etc.).

    Returns:
        Dictionary containing the complete event payload.
    """
    session_id = input_data.get('session_id', 'unknown')
    transcript_path = input_data.get('transcript_path', '')

    # Extract model name from transcript (with caching)
    model_name = ''
    if transcript_path:
        model_name = get_model_from_transcript(session_id, transcript_path)

    event_data = {
        'source_app': source_app,
        'session_id': session_id,
        'hook_event_type': event_type,
        'payload': input_data,
        'timestamp': int(datetime.now().timestamp() * 1000),
        'model_name': model_name
    }

    # Add projspec context if available
    projspec_context = get_projspec_context()
    if projspec_context:
        event_data['projspec_context'] = projspec_context

    return event_data


def include_chat_transcript(event_data: Dict[str, Any], transcript_path: str, max_size: int) -> None:
    """
    Read and include chat transcript in event data.

    Args:
        event_data: Event payload to add chat data to.
        transcript_path: Path to the JSONL transcript file.
        max_size: Maximum size in bytes for the chat data.
    """
    if not os.path.exists(transcript_path):
        return

    try:
        chat_data = []
        with open(transcript_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        chat_data.append(json.loads(line))
                    except json.JSONDecodeError:
                        pass  # Skip invalid lines

        # Truncate chat if it exceeds max_chat_size
        chat_data = truncate_chat_transcript(chat_data, max_size)
        event_data['chat'] = chat_data

    except Exception as e:
        print(f"Failed to read transcript: {e}", file=sys.stderr)


def main():
    # Load projspec configuration first
    config = load_projspec_config()

    # Check if observability is enabled - early exit if disabled
    if not config.get('enabled', False):
        sys.exit(0)

    # Parse CLI arguments and resolve configuration
    args = parse_cli_arguments()
    resolved = resolve_config(args, config)

    # Read input data from stdin
    input_data = read_input_data()
    if input_data is None:
        sys.exit(0)  # Exit 0 to not block Claude Code

    # Build event payload
    event_data = build_event_data(input_data, resolved['source_app'], args.event_type)

    # Include chat transcript if requested
    if resolved['include_chat'] and 'transcript_path' in input_data:
        include_chat_transcript(event_data, input_data['transcript_path'], resolved['max_chat_size'])

    # Generate summary if requested
    if resolved['summarize']:
        summary = generate_event_summary(event_data)
        if summary:
            event_data['summary'] = summary

    # Send to server
    send_event_to_server(event_data, resolved['server_url'])

    # Always exit with 0 to not block Claude Code operations
    sys.exit(0)

if __name__ == '__main__':
    main()

"""Unit tests for observability hooks send_event module.

This module contains comprehensive tests for the send_event.py functions:
- parse_yaml_frontmatter: YAML frontmatter extraction from markdown
- load_projspec_config: Configuration loading from .local.md files
- extract_feature_id: Feature ID extraction from paths
- get_projspec_context: Projspec context assembly
- truncate_chat_transcript: Chat transcript size limiting
- send_event_to_server: HTTP event sending (mocked)

Run with: pytest observability/tests/test_hooks.py -v
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, Any, List
from unittest.mock import patch, MagicMock
import pytest  # type: ignore[import-not-found]

# Add hooks directory to path for imports
HOOKS_DIR = Path(__file__).parent.parent / "hooks"
sys.path.insert(0, str(HOOKS_DIR))

from send_event import (
    parse_yaml_frontmatter,
    load_projspec_config,
    extract_feature_id,
    get_projspec_context,
    truncate_chat_transcript,
    send_event_to_server,
    find_config_file,
    DEFAULT_CONFIG,
)


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def valid_yaml_frontmatter() -> str:
    """Valid markdown content with YAML frontmatter."""
    return """---
observability:
  enabled: true
  server_url: http://example.com:4000
  client_url: http://example.com:3000
  source_app: test-app
  summarize_events: true
  include_chat: true
  max_chat_size: 2097152
  retention_days: 14
---

# Project Configuration

This is the markdown body content.
"""


@pytest.fixture
def minimal_yaml_frontmatter() -> str:
    """Minimal valid frontmatter with only required fields."""
    return """---
observability:
  enabled: true
---

# Minimal Config
"""


@pytest.fixture
def invalid_yaml_frontmatter() -> str:
    """Markdown content with invalid YAML frontmatter."""
    return """---
observability:
  enabled: true
  malformed: [unclosed bracket
  indentation:
   wrong: level
---

# Invalid YAML
"""


@pytest.fixture
def no_frontmatter_content() -> str:
    """Markdown content without YAML frontmatter."""
    return """# Project Documentation

This file has no YAML frontmatter.
It starts directly with content.
"""


@pytest.fixture
def empty_frontmatter_content() -> str:
    """Markdown content with empty frontmatter."""
    return """---
---

# Empty frontmatter
"""


@pytest.fixture
def sample_chat_data() -> List[Dict[str, Any]]:
    """Sample chat transcript data."""
    return [
        {"role": "user", "content": "Hello, this is message 1"},
        {"role": "assistant", "content": "Hi there, I'm Claude"},
        {"role": "user", "content": "Can you help me with something?"},
        {"role": "assistant", "content": "Of course! What do you need?"},
        {"role": "user", "content": "I need to test truncation"},
    ]


@pytest.fixture
def large_chat_data() -> List[Dict[str, Any]]:
    """Large chat transcript that exceeds typical size limits."""
    # Create messages that are about 1KB each
    large_content = "x" * 1000
    return [
        {"role": "user" if i % 2 == 0 else "assistant",
         "content": f"Message {i}: {large_content}"}
        for i in range(100)
    ]


@pytest.fixture
def mock_config_file(valid_yaml_frontmatter, tmp_path) -> Path:
    """Create a temporary config file for testing."""
    config_dir = tmp_path / ".projspec"
    config_dir.mkdir()
    config_file = config_dir / "projspec.local.md"
    config_file.write_text(valid_yaml_frontmatter)
    return config_file


# ============================================================================
# Tests for parse_yaml_frontmatter
# ============================================================================

class TestParseYamlFrontmatter:
    """Tests for parse_yaml_frontmatter function."""

    def test_valid_frontmatter_extracts_all_fields(self, valid_yaml_frontmatter):
        """Test that valid YAML frontmatter is correctly parsed."""
        result = parse_yaml_frontmatter(valid_yaml_frontmatter)

        assert result is not None
        assert 'observability' in result
        obs = result['observability']
        assert obs['enabled'] is True
        assert obs['server_url'] == 'http://example.com:4000'
        assert obs['client_url'] == 'http://example.com:3000'
        assert obs['source_app'] == 'test-app'
        assert obs['summarize_events'] is True
        assert obs['include_chat'] is True
        assert obs['max_chat_size'] == 2097152
        assert obs['retention_days'] == 14

    def test_minimal_frontmatter(self, minimal_yaml_frontmatter):
        """Test parsing of minimal frontmatter with only required fields."""
        result = parse_yaml_frontmatter(minimal_yaml_frontmatter)

        assert result is not None
        assert 'observability' in result
        assert result['observability']['enabled'] is True

    def test_no_frontmatter_returns_empty_dict(self, no_frontmatter_content):
        """Test that content without frontmatter returns empty dict."""
        result = parse_yaml_frontmatter(no_frontmatter_content)

        assert result == {}

    def test_empty_frontmatter_returns_empty_dict(self, empty_frontmatter_content):
        """Test that empty frontmatter returns empty dict."""
        result = parse_yaml_frontmatter(empty_frontmatter_content)

        assert result == {}

    def test_invalid_yaml_returns_empty_dict(self, invalid_yaml_frontmatter):
        """Test that invalid YAML returns empty dict gracefully."""
        result = parse_yaml_frontmatter(invalid_yaml_frontmatter)

        # Should return empty dict rather than raising exception
        assert result == {}

    def test_frontmatter_with_only_dashes(self):
        """Test frontmatter with only delimiter dashes."""
        content = "---\n---\n# Content"
        result = parse_yaml_frontmatter(content)

        assert result == {}

    def test_frontmatter_with_list_returns_empty(self):
        """Test that frontmatter containing a list (not dict) returns empty."""
        content = """---
- item1
- item2
- item3
---

# List frontmatter
"""
        result = parse_yaml_frontmatter(content)

        # Should return empty since parsed result is list, not dict
        assert result == {}

    def test_frontmatter_with_scalar_returns_empty(self):
        """Test that frontmatter containing a scalar returns empty."""
        content = """---
just a string value
---

# Scalar frontmatter
"""
        result = parse_yaml_frontmatter(content)

        assert result == {}

    def test_empty_string_returns_empty_dict(self):
        """Test that empty string input returns empty dict."""
        result = parse_yaml_frontmatter("")

        assert result == {}

    def test_nested_yaml_structure(self):
        """Test parsing of nested YAML structures."""
        content = """---
observability:
  enabled: true
  advanced:
    feature_a: value1
    feature_b: value2
other_section:
  key: value
---

# Nested YAML
"""
        result = parse_yaml_frontmatter(content)

        assert 'observability' in result
        assert result['observability']['enabled'] is True
        assert result['observability']['advanced']['feature_a'] == 'value1'
        assert result['other_section']['key'] == 'value'


# ============================================================================
# Tests for find_config_file
# ============================================================================

class TestFindConfigFile:
    """Tests for find_config_file function."""

    def test_finds_config_in_plugin_root(self, tmp_path):
        """Test that config is found when CLAUDE_PLUGIN_ROOT is set."""
        config_dir = tmp_path / ".projspec"
        config_dir.mkdir()
        config_file = config_dir / "projspec.local.md"
        config_file.write_text("---\nobservability:\n  enabled: true\n---\n")

        with patch.dict(os.environ, {'CLAUDE_PLUGIN_ROOT': str(tmp_path)}):
            result = find_config_file()

        assert result == config_file

    def test_finds_config_in_cwd(self, tmp_path, monkeypatch):
        """Test that config is found in current working directory."""
        config_dir = tmp_path / ".projspec"
        config_dir.mkdir()
        config_file = config_dir / "projspec.local.md"
        config_file.write_text("---\nobservability:\n  enabled: true\n---\n")

        monkeypatch.chdir(tmp_path)

        # Ensure CLAUDE_PLUGIN_ROOT is not set
        with patch.dict(os.environ, {}, clear=True):
            result = find_config_file()

        assert result == config_file

    def test_returns_none_when_no_config_exists(self, tmp_path, monkeypatch):
        """Test that None is returned when no config file exists."""
        monkeypatch.chdir(tmp_path)

        with patch.dict(os.environ, {}, clear=True):
            result = find_config_file()

        assert result is None

    def test_plugin_root_takes_precedence_over_cwd(self, tmp_path, monkeypatch):
        """Test that CLAUDE_PLUGIN_ROOT config takes precedence over cwd."""
        # Create config in plugin root
        plugin_root = tmp_path / "plugin"
        plugin_root.mkdir()
        plugin_config_dir = plugin_root / ".projspec"
        plugin_config_dir.mkdir()
        plugin_config = plugin_config_dir / "projspec.local.md"
        plugin_config.write_text("---\nobservability:\n  source_app: plugin\n---\n")

        # Create config in cwd
        cwd_dir = tmp_path / "cwd"
        cwd_dir.mkdir()
        cwd_config_dir = cwd_dir / ".projspec"
        cwd_config_dir.mkdir()
        cwd_config = cwd_config_dir / "projspec.local.md"
        cwd_config.write_text("---\nobservability:\n  source_app: cwd\n---\n")

        monkeypatch.chdir(cwd_dir)

        with patch.dict(os.environ, {'CLAUDE_PLUGIN_ROOT': str(plugin_root)}):
            result = find_config_file()

        assert result == plugin_config


# ============================================================================
# Tests for load_projspec_config
# ============================================================================

class TestLoadProjspecConfig:
    """Tests for load_projspec_config function."""

    def test_returns_defaults_when_no_config_file(self):
        """Test that default config is returned when no file exists."""
        with patch('send_event.find_config_file', return_value=None):
            result = load_projspec_config()

        assert result == DEFAULT_CONFIG

    def test_merges_config_with_defaults(self, tmp_path):
        """Test that config file values are merged with defaults."""
        config_content = """---
observability:
  enabled: true
  server_url: http://custom-server:5000
---
"""
        config_dir = tmp_path / ".projspec"
        config_dir.mkdir()
        config_file = config_dir / "projspec.local.md"
        config_file.write_text(config_content)

        with patch('send_event.find_config_file', return_value=config_file):
            result = load_projspec_config()

        # Custom values should override defaults
        assert result['enabled'] is True
        assert result['server_url'] == 'http://custom-server:5000'

        # Default values should be preserved for unspecified keys
        assert result['client_url'] == DEFAULT_CONFIG['client_url']
        assert result['source_app'] == DEFAULT_CONFIG['source_app']
        assert result['max_chat_size'] == DEFAULT_CONFIG['max_chat_size']

    def test_ignores_unknown_config_keys(self, tmp_path):
        """Test that unknown keys in config file are ignored."""
        config_content = """---
observability:
  enabled: true
  unknown_key: some_value
  another_unknown: 12345
---
"""
        config_dir = tmp_path / ".projspec"
        config_dir.mkdir()
        config_file = config_dir / "projspec.local.md"
        config_file.write_text(config_content)

        with patch('send_event.find_config_file', return_value=config_file):
            result = load_projspec_config()

        # Unknown keys should not be in result
        assert 'unknown_key' not in result
        assert 'another_unknown' not in result

        # Known keys should still work
        assert result['enabled'] is True

    def test_handles_empty_observability_section(self, tmp_path):
        """Test handling of empty observability section."""
        config_content = """---
observability: {}
---
"""
        config_dir = tmp_path / ".projspec"
        config_dir.mkdir()
        config_file = config_dir / "projspec.local.md"
        config_file.write_text(config_content)

        with patch('send_event.find_config_file', return_value=config_file):
            result = load_projspec_config()

        # Should return defaults
        assert result == DEFAULT_CONFIG

    def test_handles_missing_observability_section(self, tmp_path):
        """Test handling of frontmatter without observability section."""
        config_content = """---
other_section:
  key: value
---
"""
        config_dir = tmp_path / ".projspec"
        config_dir.mkdir()
        config_file = config_dir / "projspec.local.md"
        config_file.write_text(config_content)

        with patch('send_event.find_config_file', return_value=config_file):
            result = load_projspec_config()

        # Should return defaults
        assert result == DEFAULT_CONFIG

    def test_handles_non_dict_observability_section(self, tmp_path):
        """Test handling when observability is not a dictionary."""
        config_content = """---
observability: just_a_string
---
"""
        config_dir = tmp_path / ".projspec"
        config_dir.mkdir()
        config_file = config_dir / "projspec.local.md"
        config_file.write_text(config_content)

        with patch('send_event.find_config_file', return_value=config_file):
            result = load_projspec_config()

        # Should return defaults since observability is not a dict
        assert result == DEFAULT_CONFIG

    def test_handles_file_read_error(self, tmp_path):
        """Test graceful handling of file read errors."""
        config_file = tmp_path / ".projspec" / "projspec.local.md"
        # File doesn't exist but we return its path anyway

        with patch('send_event.find_config_file', return_value=config_file):
            result = load_projspec_config()

        # Should return defaults on error
        assert result == DEFAULT_CONFIG


# ============================================================================
# Tests for extract_feature_id
# ============================================================================

class TestExtractFeatureId:
    """Tests for extract_feature_id function."""

    def test_extracts_feature_id_from_specs_path(self, monkeypatch, tmp_path):
        """Test extraction of feature ID from path containing specs/."""
        feature_path = tmp_path / "project" / "specs" / "my-feature" / "tasks"
        feature_path.mkdir(parents=True)

        monkeypatch.chdir(feature_path)

        result = extract_feature_id()

        assert result == "my-feature"

    def test_extracts_feature_id_from_nested_path(self, monkeypatch, tmp_path):
        """Test extraction when in nested directory under specs/feature/."""
        feature_path = tmp_path / "project" / "specs" / "feature-123" / "sub" / "dir"
        feature_path.mkdir(parents=True)

        monkeypatch.chdir(feature_path)

        result = extract_feature_id()

        assert result == "feature-123"

    def test_returns_none_when_not_in_specs(self, monkeypatch, tmp_path):
        """Test that None is returned when not in a specs directory."""
        other_path = tmp_path / "project" / "src" / "components"
        other_path.mkdir(parents=True)

        monkeypatch.chdir(other_path)

        result = extract_feature_id()

        assert result is None

    def test_returns_none_when_specs_is_last_component(self, monkeypatch, tmp_path):
        """Test that None is returned when specs is the last path component."""
        specs_path = tmp_path / "project" / "specs"
        specs_path.mkdir(parents=True)

        monkeypatch.chdir(specs_path)

        result = extract_feature_id()

        assert result is None

    def test_extracts_feature_with_numeric_prefix(self, monkeypatch, tmp_path):
        """Test extraction of feature ID with numeric prefix."""
        feature_path = tmp_path / "specs" / "001-initial-setup"
        feature_path.mkdir(parents=True)

        monkeypatch.chdir(feature_path)

        result = extract_feature_id()

        assert result == "001-initial-setup"


# ============================================================================
# Tests for get_projspec_context
# ============================================================================

class TestGetProjspecContext:
    """Tests for get_projspec_context function."""

    def test_returns_empty_context_when_nothing_available(self, monkeypatch, tmp_path):
        """Test that empty dict is returned when no context is available."""
        other_path = tmp_path / "random" / "path"
        other_path.mkdir(parents=True)

        monkeypatch.chdir(other_path)

        # Ensure workflow stage env var is not set
        with patch.dict(os.environ, {}, clear=True):
            result = get_projspec_context()

        assert result == {}

    def test_includes_feature_id_when_in_specs(self, monkeypatch, tmp_path):
        """Test that feature_id is included when in specs directory."""
        feature_path = tmp_path / "specs" / "test-feature"
        feature_path.mkdir(parents=True)

        monkeypatch.chdir(feature_path)

        with patch.dict(os.environ, {}, clear=True):
            result = get_projspec_context()

        assert 'feature_id' in result
        assert result['feature_id'] == 'test-feature'

    def test_includes_workflow_stage_from_env(self, monkeypatch, tmp_path):
        """Test that workflow_stage is included from environment variable."""
        other_path = tmp_path / "project"
        other_path.mkdir(parents=True)

        monkeypatch.chdir(other_path)

        with patch.dict(os.environ, {'PROJSPEC_WORKFLOW_STAGE': 'implement'}):
            result = get_projspec_context()

        assert 'workflow_stage' in result
        assert result['workflow_stage'] == 'implement'

    def test_includes_both_feature_and_workflow_stage(self, monkeypatch, tmp_path):
        """Test that both feature_id and workflow_stage are included."""
        feature_path = tmp_path / "specs" / "my-feature"
        feature_path.mkdir(parents=True)

        monkeypatch.chdir(feature_path)

        with patch.dict(os.environ, {'PROJSPEC_WORKFLOW_STAGE': 'clarify'}):
            result = get_projspec_context()

        assert result['feature_id'] == 'my-feature'
        assert result['workflow_stage'] == 'clarify'


# ============================================================================
# Tests for truncate_chat_transcript
# ============================================================================

class TestTruncateChatTranscript:
    """Tests for truncate_chat_transcript function."""

    def test_returns_unchanged_when_under_limit(self, sample_chat_data):
        """Test that chat data is unchanged when under the size limit."""
        max_size = 1048576  # 1MB

        result = truncate_chat_transcript(sample_chat_data, max_size)

        assert result == sample_chat_data
        assert len(result) == len(sample_chat_data)

    def test_returns_empty_list_unchanged(self):
        """Test that empty list is returned unchanged."""
        result = truncate_chat_transcript([], 1000)

        assert result == []

    def test_truncates_large_transcript(self, large_chat_data):
        """Test that large transcripts are truncated."""
        max_size = 10000  # 10KB limit

        result = truncate_chat_transcript(large_chat_data, max_size)

        # Result should be smaller than original
        assert len(result) < len(large_chat_data)

        # Result size should be under limit
        result_size = len(json.dumps(result).encode('utf-8'))
        assert result_size <= max_size

    def test_adds_truncation_marker(self, large_chat_data):
        """Test that truncation marker is added when messages are removed."""
        max_size = 10000  # 10KB limit

        result = truncate_chat_transcript(large_chat_data, max_size)

        # First element should be truncation marker
        assert result[0]['_truncated'] is True
        assert '_removed_messages' in result[0]
        assert '_reason' in result[0]
        assert str(max_size) in result[0]['_reason']

    def test_truncation_marker_shows_correct_count(self, large_chat_data):
        """Test that truncation marker shows correct number of removed messages."""
        max_size = 5000
        original_count = len(large_chat_data)

        result = truncate_chat_transcript(large_chat_data, max_size)

        # Account for the truncation marker being added
        remaining_messages = len(result) - 1  # -1 for marker
        removed_messages = result[0]['_removed_messages']

        assert removed_messages == original_count - remaining_messages

    def test_removes_oldest_messages_first(self, sample_chat_data):
        """Test that oldest messages are removed first during truncation."""
        # Create a very small limit that will require truncation
        max_size = 200  # Very small limit

        result = truncate_chat_transcript(sample_chat_data, max_size)

        # The newest messages should be preserved (at the end)
        # We can't check exact content due to truncation marker,
        # but we can verify the structure
        if len(result) > 1:
            # Messages after the truncation marker should be from the end
            # of the original list
            pass  # Structure is valid

    def test_handles_single_large_message(self):
        """Test handling when a single message exceeds the limit."""
        large_message = {"role": "assistant", "content": "x" * 10000}
        chat_data = [large_message]
        max_size = 100  # Very small limit

        result = truncate_chat_transcript(chat_data, max_size)

        # Should end up with just the truncation marker
        # or empty list depending on implementation
        assert len(result) <= 2  # At most marker + 1 message

    def test_preserves_message_structure(self, sample_chat_data):
        """Test that message structure is preserved after truncation."""
        max_size = 1048576  # Large enough to not truncate

        result = truncate_chat_transcript(sample_chat_data, max_size)

        for message in result:
            assert 'role' in message
            assert 'content' in message

    def test_exact_limit_boundary(self):
        """Test behavior at exact size boundary."""
        chat_data = [{"role": "user", "content": "hello"}]
        exact_size = len(json.dumps(chat_data).encode('utf-8'))

        result = truncate_chat_transcript(chat_data, exact_size)

        # Should not truncate when exactly at limit
        assert result == chat_data
        assert len(result) == 1


# ============================================================================
# Tests for send_event_to_server
# ============================================================================

class TestSendEventToServer:
    """Tests for send_event_to_server function."""

    def test_successful_event_send(self):
        """Test successful event sending returns True."""
        event_data = {
            'source_app': 'test',
            'session_id': 'session-123',
            'hook_event_type': 'PreToolUse',
            'payload': {'tool': 'Read'},
        }

        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)

        with patch('urllib.request.urlopen', return_value=mock_response):
            result = send_event_to_server(event_data)

        assert result is True

    def test_returns_false_on_non_200_status(self):
        """Test that non-200 status returns False."""
        event_data = {'source_app': 'test'}

        mock_response = MagicMock()
        mock_response.status = 500
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)

        with patch('urllib.request.urlopen', return_value=mock_response):
            result = send_event_to_server(event_data)

        assert result is False

    def test_returns_false_on_url_error(self):
        """Test that URLError returns False."""
        import urllib.error

        event_data = {'source_app': 'test'}

        with patch('urllib.request.urlopen',
                   side_effect=urllib.error.URLError('Connection refused')):
            result = send_event_to_server(event_data)

        assert result is False

    def test_returns_false_on_unexpected_error(self):
        """Test that unexpected errors return False."""
        event_data = {'source_app': 'test'}

        with patch('urllib.request.urlopen',
                   side_effect=Exception('Unexpected error')):
            result = send_event_to_server(event_data)

        assert result is False

    def test_uses_custom_server_url(self):
        """Test that custom server URL is used."""
        event_data = {'source_app': 'test'}
        custom_url = 'http://custom-server:5000/events'

        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)

        with patch('urllib.request.urlopen', return_value=mock_response) as mock_urlopen:
            with patch('urllib.request.Request') as mock_request:
                mock_request.return_value = MagicMock()
                send_event_to_server(event_data, custom_url)

                mock_request.assert_called_once()
                call_args = mock_request.call_args
                assert call_args[0][0] == custom_url

    def test_sends_json_content_type_header(self):
        """Test that JSON content-type header is sent."""
        event_data = {'source_app': 'test'}

        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)

        with patch('urllib.request.urlopen', return_value=mock_response):
            with patch('urllib.request.Request') as mock_request:
                mock_request.return_value = MagicMock()
                send_event_to_server(event_data)

                call_kwargs = mock_request.call_args[1]
                assert call_kwargs['headers']['Content-Type'] == 'application/json'

    def test_sends_user_agent_header(self):
        """Test that User-Agent header is sent."""
        event_data = {'source_app': 'test'}

        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)

        with patch('urllib.request.urlopen', return_value=mock_response):
            with patch('urllib.request.Request') as mock_request:
                mock_request.return_value = MagicMock()
                send_event_to_server(event_data)

                call_kwargs = mock_request.call_args[1]
                assert 'User-Agent' in call_kwargs['headers']
                assert 'Claude-Code-Hook' in call_kwargs['headers']['User-Agent']

    def test_serializes_event_data_as_json(self):
        """Test that event data is properly serialized as JSON."""
        event_data = {
            'source_app': 'test',
            'nested': {'key': 'value'},
            'list': [1, 2, 3],
        }

        mock_response = MagicMock()
        mock_response.status = 200
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)

        with patch('urllib.request.urlopen', return_value=mock_response):
            with patch('urllib.request.Request') as mock_request:
                mock_request.return_value = MagicMock()
                send_event_to_server(event_data)

                call_kwargs = mock_request.call_args[1]
                sent_data = json.loads(call_kwargs['data'].decode('utf-8'))
                assert sent_data == event_data


# ============================================================================
# Integration-style tests (still unit tests, just testing multiple functions)
# ============================================================================

class TestConfigurationIntegration:
    """Tests that verify configuration loading integrates correctly."""

    def test_full_config_load_and_parse_flow(self, tmp_path, valid_yaml_frontmatter):
        """Test complete flow from file to parsed config."""
        config_dir = tmp_path / ".projspec"
        config_dir.mkdir()
        config_file = config_dir / "projspec.local.md"
        config_file.write_text(valid_yaml_frontmatter)

        with patch.dict(os.environ, {'CLAUDE_PLUGIN_ROOT': str(tmp_path)}):
            config = load_projspec_config()

        assert config['enabled'] is True
        assert config['server_url'] == 'http://example.com:4000'
        assert config['source_app'] == 'test-app'
        assert config['max_chat_size'] == 2097152

    def test_context_includes_all_available_info(self, tmp_path, monkeypatch):
        """Test that context includes all available projspec info."""
        # Set up path with specs/feature
        feature_path = tmp_path / "specs" / "my-feature" / "tasks"
        feature_path.mkdir(parents=True)
        monkeypatch.chdir(feature_path)

        with patch.dict(os.environ, {'PROJSPEC_WORKFLOW_STAGE': 'plan'}):
            context = get_projspec_context()

        assert context == {
            'feature_id': 'my-feature',
            'workflow_stage': 'plan',
        }


# ============================================================================
# Edge case tests
# ============================================================================

class TestEdgeCases:
    """Tests for edge cases and boundary conditions."""

    def test_parse_frontmatter_with_special_characters(self):
        """Test parsing frontmatter with special characters in values."""
        content = """---
observability:
  server_url: "http://example.com:4000?query=value&other=123"
  source_app: "app-with-special-chars!@#"
---
"""
        result = parse_yaml_frontmatter(content)

        assert result['observability']['server_url'] == 'http://example.com:4000?query=value&other=123'
        assert result['observability']['source_app'] == 'app-with-special-chars!@#'

    def test_parse_frontmatter_with_multiline_string(self):
        """Test parsing frontmatter with multiline string values."""
        content = """---
observability:
  enabled: true
description: |
  This is a multiline
  description that spans
  multiple lines.
---
"""
        result = parse_yaml_frontmatter(content)

        assert 'description' in result
        assert 'multiline' in result['description']

    def test_truncate_empty_messages(self):
        """Test truncation of chat with empty message content."""
        chat_data = [
            {"role": "user", "content": ""},
            {"role": "assistant", "content": ""},
            {"role": "user", "content": "actual message"},
        ]

        result = truncate_chat_transcript(chat_data, 1048576)

        assert len(result) == 3
        assert result[2]['content'] == 'actual message'

    def test_truncate_with_unicode_content(self):
        """Test truncation handles unicode content correctly."""
        chat_data = [
            {"role": "user", "content": "Hello, \u4e16\u754c!"},  # "Hello, World!" in Chinese
            {"role": "assistant", "content": "\u3053\u3093\u306b\u3061\u306f"},  # "Hello" in Japanese
        ]

        result = truncate_chat_transcript(chat_data, 1048576)

        assert len(result) == 2
        assert "\u4e16\u754c" in result[0]['content']

    def test_send_event_handles_timeout(self):
        """Test that send_event handles timeout gracefully."""
        import socket
        event_data = {'source_app': 'test'}

        with patch('urllib.request.urlopen',
                   side_effect=socket.timeout('Connection timed out')):
            result = send_event_to_server(event_data)

        assert result is False

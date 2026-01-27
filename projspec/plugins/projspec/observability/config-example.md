# Observability Configuration Template

Copy this file to your project's `.projspec/projspec.local.md` to enable observability.

> **Note**: The `.projspec/projspec.local.md` file should be added to `.gitignore` as it may contain environment-specific settings.

---

## Quick Start

Copy the YAML frontmatter below to `.projspec/projspec.local.md` in your project root.

---

## Configuration Options

```yaml
---
observability:
  # Enable or disable observability (default: false)
  enabled: false

  # Langfuse server URL for sending traces
  # Default: http://localhost:4000
  server_url: http://localhost:4000

  # Langfuse client URL for viewing traces in browser
  # Default: http://localhost:3000
  client_url: http://localhost:3000

  # Source application identifier for filtering in Langfuse
  # Default: projspec
  source_app: projspec

  # Include AI-generated summaries of conversation events
  # Adds processing overhead but improves trace readability
  # Default: false
  summarize_events: false

  # Include full chat history in session traces
  # Warning: Can significantly increase trace size
  # Default: false
  include_chat: false

  # Maximum chat size to include (in bytes)
  # Only applies when include_chat is true
  # Default: 1048576 (1MB)
  max_chat_size: 1048576

  # Number of days to retain traces in local cache
  # Default: 7
  retention_days: 7
---
```

---

## Common Configuration Scenarios

### Minimal Configuration (Recommended Start)

For getting started with basic observability:

```yaml
---
observability:
  enabled: true
---
```

Uses all defaults. Traces are sent to `http://localhost:4000`.

---

### Development Configuration

For local development with full debugging:

```yaml
---
observability:
  enabled: true
  server_url: http://localhost:4000
  client_url: http://localhost:3000
  summarize_events: true
  include_chat: true
---
```

---

### Production Configuration

For production use with cloud-hosted Langfuse:

```yaml
---
observability:
  enabled: true
  server_url: https://cloud.langfuse.com
  client_url: https://cloud.langfuse.com
  source_app: myproject-prod
  summarize_events: false
  include_chat: false
  retention_days: 30
---
```

> **Important**: Authentication for cloud Langfuse is handled via environment variables:
> - `LANGFUSE_PUBLIC_KEY`
> - `LANGFUSE_SECRET_KEY`
>
> Do not include credentials in this file.

---

### Team/Shared Development

For team environments with a shared Langfuse instance:

```yaml
---
observability:
  enabled: true
  server_url: http://langfuse.internal.company.com:4000
  client_url: http://langfuse.internal.company.com:3000
  source_app: myproject-dev
  summarize_events: true
---
```

---

## Environment Variables

The following environment variables are used for Langfuse authentication:

| Variable | Description |
|----------|-------------|
| `LANGFUSE_PUBLIC_KEY` | Public key for Langfuse API |
| `LANGFUSE_SECRET_KEY` | Secret key for Langfuse API |
| `LANGFUSE_HOST` | Alternative to `server_url` in config |

Environment variables take precedence over configuration file settings.

---

## Gitignore Entry

Add the following to your `.gitignore`:

```
# projspec local configuration
.projspec/projspec.local.md
```

---

## Verifying Configuration

After setting up your configuration, you can verify it works by:

1. Starting a new Claude Code session in your project
2. Looking for observability hooks loading in the session output
3. Checking your Langfuse dashboard for incoming traces

If traces are not appearing, check:
- The Langfuse server is running and accessible
- Authentication credentials are set (for cloud Langfuse)
- `enabled` is set to `true`

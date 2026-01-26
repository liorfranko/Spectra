# Skill: Explore GitHub Repository Structure

**Learned**: 2026-01-26
**Context**: Analyzing spec-kit repository for reimplementation

## Pattern

Use the Task tool with Explore agent to comprehensively analyze a GitHub repository's architecture when planning a reimplementation or understanding a codebase.

### Approach

1. **Identify key aspects to explore**:
   - Directory structure and organization
   - Commands/skills/plugins available
   - Templates and configuration files
   - Scripts and utilities
   - Build/package configuration

2. **Formulate exploration prompt**:
   ```
   Explore the [repo] repository at [URL] to understand:
   1. Overall directory structure
   2. [Specific aspect 1]
   3. [Specific aspect 2]
   ...
   Focus on [goal] so we can [purpose].
   ```

3. **Use web search and fetch**: The Explore agent can use WebSearch and WebFetch to examine public repositories

4. **Extract actionable information**:
   - File trees
   - Configuration schemas
   - Command structures
   - Dependency lists

### Example

```markdown
Explore the original spec-kit repository at https://github.com/github/spec-kit to understand:
1. The overall directory structure and organization
2. The commands/skills available (slash commands)
3. The templates used for specs, plans, tasks
4. The scripts and bash utilities
5. How agents are organized
6. The plugin.json configuration

Focus on understanding the architecture so we can create a clean reimplementation.
```

### Output Structure

The Explore agent should return:
1. **Directory Structure**: ASCII tree of key directories
2. **Component Breakdown**: Tables of commands, templates, scripts
3. **Configuration Examples**: JSON/YAML schemas
4. **Architectural Insights**: Key patterns and design decisions
5. **Sources**: Links to documentation and references

## When to Apply

- Before reimplementing or forking a project
- When onboarding to a new codebase
- When comparing implementations across similar tools
- When documenting architecture for planning

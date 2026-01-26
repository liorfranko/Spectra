"""
Data models for ProjSpec CLI.

This package contains Pydantic models for:
- Project configuration
- Feature/spec state management
"""

from projspec_cli.models.config import (
    ClaudeConfig,
    FeaturesConfig,
    GitConfig,
    NumberingConfig,
    ProjectConfig,
    ProjectMetadata,
)
from projspec_cli.models.feature import (
    FeaturePhase,
    FeatureState,
    TaskInfo,
    TaskPriority,
    TaskStatus,
    WorktreeStatus,
)

__all__ = [
    # Config models
    "ClaudeConfig",
    "FeaturesConfig",
    "GitConfig",
    "NumberingConfig",
    "ProjectConfig",
    "ProjectMetadata",
    # Feature models
    "FeaturePhase",
    "FeatureState",
    "TaskInfo",
    "TaskPriority",
    "TaskStatus",
    "WorktreeStatus",
]

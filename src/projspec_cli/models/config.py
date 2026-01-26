"""
Project configuration model.

Defines the Pydantic model for projspec.yaml configuration,
including project metadata, paths, and settings.
"""

from datetime import datetime
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel, Field, field_validator


class NumberingConfig(BaseModel):
    """Configuration for feature numbering."""

    digits: int = Field(
        default=3,
        ge=1,
        le=5,
        description="Number of digits for feature numbering (e.g., 3 = 001, 002, ...)",
    )
    start: int = Field(
        default=1,
        ge=0,
        description="Starting number for feature numbering",
    )

    @field_validator("digits")
    @classmethod
    def validate_digits(cls, v: int) -> int:
        """Validate that digits is between 1 and 5."""
        if not 1 <= v <= 5:
            raise ValueError("digits must be between 1 and 5")
        return v


class ProjectMetadata(BaseModel):
    """Project metadata section of the configuration."""

    name: str = Field(
        ...,
        min_length=1,
        description="Project name (required, non-empty)",
    )
    version: str = Field(
        default="0.1.0",
        description="ProjSpec version used",
    )
    created: datetime = Field(
        default_factory=datetime.now,
        description="ISO 8601 timestamp of project creation",
    )

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate that name is non-empty."""
        if not v or not v.strip():
            raise ValueError("project name is required and cannot be empty")
        return v.strip()


class FeaturesConfig(BaseModel):
    """Feature settings section of the configuration."""

    directory: str = Field(
        default="specs",
        description="Directory for feature specifications",
    )
    numbering: NumberingConfig = Field(
        default_factory=NumberingConfig,
        description="Feature numbering configuration",
    )


class GitConfig(BaseModel):
    """Git integration section of the configuration."""

    main_branch: str = Field(
        default="main",
        description="Main branch name",
    )
    worktree_dir: str = Field(
        default="worktrees",
        description="Directory where worktrees are created",
    )


class ClaudeConfig(BaseModel):
    """Claude Code integration section of the configuration."""

    context_file: str = Field(
        default="CLAUDE.md",
        description="Path to the Claude context file",
    )
    auto_update_context: bool = Field(
        default=True,
        description="Whether to automatically update the context file",
    )


class ProjectConfig(BaseModel):
    """
    Main project configuration model.

    Represents the complete projspec.yaml configuration file.
    """

    project: ProjectMetadata = Field(
        ...,
        description="Project metadata section",
    )
    features: FeaturesConfig = Field(
        default_factory=FeaturesConfig,
        description="Feature settings section",
    )
    git: GitConfig = Field(
        default_factory=GitConfig,
        description="Git integration section",
    )
    claude: ClaudeConfig = Field(
        default_factory=ClaudeConfig,
        description="Claude Code integration section",
    )

    @classmethod
    def load_from_file(cls, path: Path) -> "ProjectConfig":
        """
        Load project configuration from a YAML file.

        Args:
            path: Path to the projspec.yaml file

        Returns:
            ProjectConfig instance

        Raises:
            FileNotFoundError: If the file does not exist
            ValueError: If the YAML is invalid or missing required fields
        """
        if not path.exists():
            raise FileNotFoundError(f"Configuration file not found: {path}")

        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)

        if data is None:
            raise ValueError(f"Configuration file is empty: {path}")

        return cls.model_validate(data)

    def save_to_file(self, path: Path) -> None:
        """
        Save project configuration to a YAML file.

        Args:
            path: Path to save the projspec.yaml file
        """
        # Ensure parent directory exists
        path.parent.mkdir(parents=True, exist_ok=True)

        # Convert to dict with datetime serialization
        data = self._to_yaml_dict()

        with path.open("w", encoding="utf-8") as f:
            yaml.dump(
                data,
                f,
                default_flow_style=False,
                allow_unicode=True,
                sort_keys=False,
            )

    def _to_yaml_dict(self) -> dict[str, Any]:
        """
        Convert the model to a dictionary suitable for YAML serialization.

        Handles datetime serialization to ISO 8601 format.
        """
        data = self.model_dump()

        # Convert datetime to ISO 8601 string
        if "project" in data and "created" in data["project"]:
            created = data["project"]["created"]
            if isinstance(created, datetime):
                data["project"]["created"] = created.isoformat()

        return data

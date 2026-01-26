"""
Feature and specification state model.

Defines models for tracking feature specifications, their states,
and associated worktree information.
"""

import re
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel, Field, computed_field, field_validator, model_validator


class FeaturePhase(str, Enum):
    """Feature lifecycle phases."""

    NEW = "new"
    SPEC = "spec"
    PLAN = "plan"
    TASKS = "tasks"
    IMPLEMENT = "implement"
    REVIEW = "review"
    COMPLETE = "complete"

    @classmethod
    def ordered_phases(cls) -> list["FeaturePhase"]:
        """Return phases in their natural progression order."""
        return [
            cls.NEW,
            cls.SPEC,
            cls.PLAN,
            cls.TASKS,
            cls.IMPLEMENT,
            cls.REVIEW,
            cls.COMPLETE,
        ]

    def can_transition_to(self, target: "FeaturePhase") -> bool:
        """Check if transition to target phase is valid (forward only)."""
        ordered = self.ordered_phases()
        current_idx = ordered.index(self)
        target_idx = ordered.index(target)
        # Allow transition to next phase or same phase
        return target_idx == current_idx + 1 or target_idx == current_idx


class WorktreeStatus(str, Enum):
    """Worktree status options."""

    ACTIVE = "active"
    ARCHIVED = "archived"
    PRUNED = "pruned"


class TaskStatus(str, Enum):
    """Task status options."""

    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    SKIPPED = "skipped"


class TaskPriority(str, Enum):
    """Task priority levels."""

    P1 = "P1"
    P2 = "P2"
    P3 = "P3"


class TaskInfo(BaseModel):
    """Model representing a task within a feature."""

    id: str = Field(
        ...,
        description="Task ID (e.g., 'T001', 'T002')",
        pattern=r"^T\d{3}$",
    )
    name: str = Field(
        ...,
        min_length=1,
        description="Brief task name",
    )
    description: str = Field(
        default="",
        description="Detailed task description",
    )
    status: TaskStatus = Field(
        default=TaskStatus.PENDING,
        description="Current task status",
    )
    priority: TaskPriority = Field(
        default=TaskPriority.P2,
        description="Task priority level",
    )
    depends_on: list[str] = Field(
        default_factory=list,
        description="List of task IDs this task depends on",
    )
    context_files: list[str] = Field(
        default_factory=list,
        description="Relevant source files for this task",
    )
    summary: str | None = Field(
        default=None,
        description="Completion summary (3-5 bullets)",
    )
    started: datetime | None = Field(
        default=None,
        description="When work began on this task",
    )
    completed: datetime | None = Field(
        default=None,
        description="When task was completed or skipped",
    )

    @field_validator("id")
    @classmethod
    def validate_task_id(cls, v: str) -> str:
        """Validate task ID format (T followed by 3 digits)."""
        if not re.match(r"^T\d{3}$", v):
            raise ValueError("Task ID must match pattern T###  (e.g., T001)")
        return v

    @field_validator("depends_on")
    @classmethod
    def validate_depends_on(cls, v: list[str]) -> list[str]:
        """Validate that all dependency IDs match the task ID pattern."""
        for dep_id in v:
            if not re.match(r"^T\d{3}$", dep_id):
                raise ValueError(
                    f"Dependency ID '{dep_id}' must match pattern T### (e.g., T001)"
                )
        return v


class FeatureState(BaseModel):
    """
    Model representing the complete state of a feature.

    Tracks feature identification, lifecycle phase, git integration,
    and associated tasks.
    """

    # Feature identification
    id: str = Field(
        ...,
        description="Feature ID (e.g., '001', '002')",
    )
    name: str = Field(
        ...,
        min_length=1,
        description="Feature name as slug (lowercase, hyphens)",
    )
    description: str = Field(
        default="",
        description="Original feature description",
    )

    # Lifecycle
    phase: FeaturePhase = Field(
        default=FeaturePhase.NEW,
        description="Current feature phase",
    )
    created: datetime = Field(
        default_factory=datetime.now,
        description="ISO 8601 timestamp of feature creation",
    )
    updated: datetime = Field(
        default_factory=datetime.now,
        description="Last modification time",
    )

    # Git integration (worktree-based)
    branch: str = Field(
        default="",
        description="Branch name (defaults to full_name)",
    )
    worktree_path: str = Field(
        default="",
        description="Relative path to worktree from repo root",
    )
    worktree_status: WorktreeStatus = Field(
        default=WorktreeStatus.ACTIVE,
        description="Current worktree status",
    )

    # Tasks (when phase >= tasks)
    tasks: list[TaskInfo] = Field(
        default_factory=list,
        description="List of tasks for this feature",
    )

    @field_validator("id")
    @classmethod
    def validate_id(cls, v: str) -> str:
        """Validate feature ID format (3 digits by default)."""
        if not re.match(r"^\d{3}$", v):
            raise ValueError("Feature ID must match pattern ### (e.g., 001)")
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate feature name format (lowercase letters, numbers, hyphens)."""
        if not re.match(r"^[a-z0-9-]+$", v):
            raise ValueError(
                "Feature name must only contain lowercase letters, numbers, and hyphens"
            )
        return v

    @computed_field
    @property
    def full_name(self) -> str:
        """Compute full feature name as id-name."""
        return f"{self.id}-{self.name}"

    @model_validator(mode="after")
    def set_defaults_from_id_name(self) -> "FeatureState":
        """Set default values for branch and worktree_path based on id and name."""
        if not self.branch:
            self.branch = self.full_name
        if not self.worktree_path:
            self.worktree_path = f"worktrees/{self.full_name}"
        return self

    @model_validator(mode="after")
    def validate_task_dependencies(self) -> "FeatureState":
        """
        Validate that tasks with in_progress status have all dependencies completed.

        A task can only be in_progress if all tasks it depends_on are completed.
        """
        # Build a map of task IDs to their status
        task_status_map: dict[str, TaskStatus] = {
            task.id: task.status for task in self.tasks
        }

        for task in self.tasks:
            if task.status == TaskStatus.IN_PROGRESS:
                for dep_id in task.depends_on:
                    if dep_id in task_status_map:
                        dep_status = task_status_map[dep_id]
                        if dep_status != TaskStatus.COMPLETED:
                            raise ValueError(
                                f"Task {task.id} cannot be in_progress: "
                                f"dependency {dep_id} is not completed (status: {dep_status.value})"
                            )
                    # If dependency not found in tasks list, we allow it
                    # (might be referencing external task)

        return self

    def get_task_by_id(self, task_id: str) -> TaskInfo | None:
        """Get a task by its ID."""
        for task in self.tasks:
            if task.id == task_id:
                return task
        return None

    def get_available_tasks(self) -> list[TaskInfo]:
        """
        Get tasks that are available to start.

        A task is available if:
        - Its status is 'pending'
        - All its dependencies are 'completed'
        """
        completed_ids = {
            task.id for task in self.tasks if task.status == TaskStatus.COMPLETED
        }

        available = []
        for task in self.tasks:
            # Task is available if pending and all dependencies are completed
            if task.status == TaskStatus.PENDING and all(
                dep_id in completed_ids for dep_id in task.depends_on
            ):
                available.append(task)

        return available

    @classmethod
    def load_from_file(cls, path: Path) -> "FeatureState":
        """
        Load feature state from a YAML file.

        Args:
            path: Path to the feature state YAML file

        Returns:
            FeatureState instance

        Raises:
            FileNotFoundError: If the file does not exist
            ValueError: If the YAML is invalid or missing required fields
        """
        if not path.exists():
            raise FileNotFoundError(f"Feature state file not found: {path}")

        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)

        if data is None:
            raise ValueError(f"Feature state file is empty: {path}")

        return cls.model_validate(data)

    def save_to_file(self, path: Path) -> None:
        """
        Save feature state to a YAML file.

        Args:
            path: Path to save the feature state YAML file
        """
        # Ensure parent directory exists
        path.parent.mkdir(parents=True, exist_ok=True)

        # Update the 'updated' timestamp
        self.updated = datetime.now()

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

        Handles datetime and enum serialization.
        """
        # Use mode="json" to get JSON-serializable output (enums as strings)
        data = self.model_dump(mode="json", exclude={"full_name"})

        return data

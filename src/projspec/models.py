"""Pydantic models for ProjSpec state management."""

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class TaskStatus(str, Enum):
    """Status of a task in the workflow."""

    pending = "pending"
    in_progress = "in_progress"
    completed = "completed"
    skipped = "skipped"


class TaskState(BaseModel):
    """Represents an atomic unit of implementation work within a spec.

    A task is the smallest trackable unit of work in a ProjSpec workflow.
    Tasks can depend on other tasks and track their completion status.
    """

    id: str = Field(..., description="Unique task identifier (e.g., 'task-001')")
    name: str = Field(..., description="Human-readable task name")
    description: str = Field(default="", description="Detailed task description")
    status: TaskStatus = Field(
        default=TaskStatus.pending,
        description="Current status of the task",
    )
    depends_on: list[str] = Field(
        default_factory=list,
        description="List of task IDs that must complete first",
    )
    context_files: list[str] = Field(
        default_factory=list,
        description="Glob patterns for relevant source files",
    )
    summary: Optional[str] = Field(
        default=None,
        description="3-5 bullet summary after completion",
    )


class SpecPhase(str, Enum):
    """Phase of a spec in the workflow.

    Phases transition in order: new -> spec -> plan -> tasks -> implement -> review
    """

    new = "new"
    spec = "spec"
    plan = "plan"
    tasks = "tasks"
    implement = "implement"
    review = "review"


class SpecState(BaseModel):
    """Represents a feature being developed through the ProjSpec workflow.

    A SpecState tracks a feature from initial specification through implementation
    and review, maintaining state about the current phase and associated tasks.
    """

    spec_id: str = Field(
        ...,
        description="8-character hex ID",
        pattern=r"^[a-f0-9]{8}$",
    )
    name: str = Field(
        ...,
        description="Kebab-case spec name",
        pattern=r"^[a-z0-9-]+$",
    )
    phase: SpecPhase = Field(
        default=SpecPhase.new,
        description="Current workflow phase",
    )
    created_at: datetime = Field(
        ...,
        description="ISO 8601 timestamp of spec creation",
    )
    branch: str = Field(
        ...,
        description="Git branch name (spec/{id}-{name})",
        pattern=r"^spec/[a-f0-9]{8}-[a-z0-9-]+$",
    )
    worktree_path: str = Field(
        ...,
        description="Relative path to worktree",
        pattern=r"^worktrees/spec-[a-f0-9]{8}-[a-z0-9-]+$",
    )
    tasks: list[TaskState] = Field(
        default_factory=list,
        description="Tasks for implementation phase",
    )


class ProjectConfig(BaseModel):
    """Project identity configuration."""

    name: Optional[str] = Field(
        default=None,
        description="Project display name (defaults to cwd name)",
    )
    description: str = Field(
        default="",
        description="Project description",
    )


class WorktreesConfig(BaseModel):
    """Worktree directory configuration."""

    base_path: str = Field(
        default="./worktrees",
        description="Directory for worktrees",
    )


class ContextConfig(BaseModel):
    """Context file configuration."""

    always_include: list[str] = Field(
        default_factory=lambda: ["CLAUDE.md"],
        description="Files to always include in context",
    )


class Config(BaseModel):
    """Global project configuration.

    Represents the projspec.yaml configuration file structure.
    """

    version: str = Field(
        ...,
        description="Configuration schema version",
        pattern=r"^[0-9]+\.[0-9]+$",
    )
    project: Optional[ProjectConfig] = Field(
        default=None,
        description="Project identity settings",
    )
    worktrees: Optional[WorktreesConfig] = Field(
        default=None,
        description="Worktree configuration",
    )
    context: Optional[ContextConfig] = Field(
        default=None,
        description="Context file configuration",
    )


class WorkflowDefinition(BaseModel):
    """Definition of workflow phases and configuration.

    Contains the workflow name and ordered list of phases that define
    the sequence of steps in the development workflow.
    """

    name: str = Field(
        default="default",
        description="Workflow identifier",
    )
    phases: list[str] = Field(
        default_factory=lambda: ["spec", "plan", "tasks", "implement", "review"],
        description="Ordered list of phase names",
    )


class Workflow(BaseModel):
    """Wrapper for workflow definition.

    Defines the sequence of phases for the project.
    """

    workflow: WorkflowDefinition = Field(
        ...,
        description="Workflow definition with name and phases",
    )

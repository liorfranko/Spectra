"""
Status display service.

Handles the logic for displaying project and feature status, including:
- Current worktree and branch information
- Feature specification states
- Progress indicators using Rich
- Task progress tracking
"""

from __future__ import annotations

import contextlib
import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field

from projspec_cli.models.config import ProjectConfig
from projspec_cli.models.feature import (
    FeaturePhase,
    FeatureState,
    TaskInfo,
    TaskStatus,
    WorktreeStatus,
)
from projspec_cli.utils.git import (
    get_current_branch,
    get_worktree_info,
    is_worktree,
)
from projspec_cli.utils.paths import (
    FEATURE_DIR_PATTERN,
    get_config_path,
    get_feature_dir,
    get_project_root,
    list_features,
)


class TaskProgress(BaseModel):
    """Model representing task progress for a feature."""

    total: int = Field(default=0, description="Total number of tasks")
    pending: int = Field(default=0, description="Number of pending tasks")
    in_progress: int = Field(default=0, description="Number of in-progress tasks")
    completed: int = Field(default=0, description="Number of completed tasks")
    skipped: int = Field(default=0, description="Number of skipped tasks")

    @property
    def percentage(self) -> float:
        """Calculate completion percentage (completed + skipped / total)."""
        if self.total == 0:
            return 0.0
        return ((self.completed + self.skipped) / self.total) * 100

    @property
    def is_complete(self) -> bool:
        """Check if all tasks are completed or skipped."""
        return self.total > 0 and (self.completed + self.skipped) == self.total


class FeatureStatus(BaseModel):
    """Model representing the status of a single feature."""

    id: str = Field(..., description="Feature ID (e.g., '001')")
    name: str = Field(..., description="Feature name slug")
    full_name: str = Field(..., description="Full feature name (id-name)")
    phase: FeaturePhase = Field(
        default=FeaturePhase.NEW, description="Current feature phase"
    )
    worktree_status: WorktreeStatus = Field(
        default=WorktreeStatus.ACTIVE, description="Worktree status"
    )
    branch: str = Field(default="", description="Associated branch name")
    description: str = Field(default="", description="Feature description")
    created: datetime | None = Field(default=None, description="Creation timestamp")
    updated: datetime | None = Field(default=None, description="Last update timestamp")
    task_progress: TaskProgress = Field(
        default_factory=TaskProgress, description="Task progress information"
    )
    has_spec: bool = Field(default=False, description="Whether spec.md exists")
    has_plan: bool = Field(default=False, description="Whether plan.md exists")
    has_tasks: bool = Field(default=False, description="Whether tasks.md exists")
    has_state: bool = Field(default=False, description="Whether state.yaml exists")
    next_available_task: str | None = Field(
        default=None, description="ID of next available task"
    )


class WorktreeInfo(BaseModel):
    """Model representing worktree information."""

    path: str = Field(..., description="Absolute path to worktree")
    branch: str | None = Field(default=None, description="Branch name")
    is_main: bool = Field(default=False, description="Whether this is the main repo")
    is_feature_branch: bool = Field(
        default=False, description="Whether branch is a feature branch"
    )
    feature_id: str | None = Field(
        default=None, description="Feature ID if feature branch"
    )


class ProjectStatus(BaseModel):
    """Model representing the overall project status."""

    project_name: str = Field(..., description="Project name from config")
    project_root: str = Field(..., description="Path to project root")
    current_branch: str | None = Field(default=None, description="Current git branch")
    is_worktree: bool = Field(default=False, description="Whether in a worktree")
    current_worktree: WorktreeInfo | None = Field(
        default=None, description="Current worktree info if in worktree"
    )
    features: list[FeatureStatus] = Field(
        default_factory=list, description="List of all features"
    )
    total_features: int = Field(default=0, description="Total number of features")
    features_by_phase: dict[str, int] = Field(
        default_factory=dict, description="Count of features by phase"
    )
    total_tasks: int = Field(default=0, description="Total tasks across all features")
    completed_tasks: int = Field(
        default=0, description="Completed tasks across all features"
    )


@dataclass
class StatusResult:
    """Result of a status query operation."""

    success: bool
    message: str
    project_status: ProjectStatus | None = None
    feature_status: FeatureStatus | None = None


def _parse_tasks_from_markdown(tasks_path: Path) -> list[TaskInfo]:
    """
    Parse tasks from a tasks.md file.

    This is a simple parser that extracts task information from markdown.
    Expected format:
    ## T001: Task Name
    **Status**: pending|in_progress|completed|skipped
    **Priority**: P1|P2|P3
    ...

    Args:
        tasks_path: Path to tasks.md file

    Returns:
        List of TaskInfo objects parsed from the file
    """
    if not tasks_path.exists():
        return []

    try:
        content = tasks_path.read_text(encoding="utf-8")
    except OSError:
        return []

    tasks: list[TaskInfo] = []
    current_task: dict[str, Any] = {}

    # Pattern for task header: ## T001: Task Name or ## T001 - Task Name
    task_header_pattern = re.compile(r"^##\s+(T\d{3})[\s:\-]+(.+)$")
    # Pattern for status: **Status**: value or Status: value
    status_pattern = re.compile(r"\*{0,2}Status\*{0,2}:\s*(\w+)", re.IGNORECASE)
    # Pattern for priority: **Priority**: value or Priority: value
    priority_pattern = re.compile(r"\*{0,2}Priority\*{0,2}:\s*(P[123])", re.IGNORECASE)
    # Pattern for depends_on: **Depends on**: T001, T002 or Depends on: T001
    depends_pattern = re.compile(
        r"\*{0,2}Depends?\s*on\*{0,2}:\s*(T\d{3}(?:\s*,\s*T\d{3})*)", re.IGNORECASE
    )
    # Pattern for checkbox-style tasks: - [ ] T001: Task Name or - [x] T001: Task Name
    checkbox_pattern = re.compile(r"^-\s*\[([ xX])\]\s*(T\d{3})[\s:\-]+(.+)$")

    lines = content.split("\n")
    for line in lines:
        # Check for task header
        header_match = task_header_pattern.match(line.strip())
        if header_match:
            # Save previous task if any
            if current_task and "id" in current_task:
                with contextlib.suppress(Exception):
                    tasks.append(TaskInfo(**current_task))
            current_task = {
                "id": header_match.group(1),
                "name": header_match.group(2).strip(),
                "status": TaskStatus.PENDING,
            }
            continue

        # Check for checkbox-style tasks
        checkbox_match = checkbox_pattern.match(line.strip())
        if checkbox_match:
            # Save previous task if any
            if current_task and "id" in current_task:
                with contextlib.suppress(Exception):
                    tasks.append(TaskInfo(**current_task))
            is_checked = checkbox_match.group(1).lower() == "x"
            current_task = {
                "id": checkbox_match.group(2),
                "name": checkbox_match.group(3).strip(),
                "status": TaskStatus.COMPLETED if is_checked else TaskStatus.PENDING,
            }
            continue

        # Parse status
        status_match = status_pattern.search(line)
        if status_match and current_task:
            status_value = status_match.group(1).lower()
            with contextlib.suppress(ValueError):
                current_task["status"] = TaskStatus(status_value)

        # Parse priority
        priority_match = priority_pattern.search(line)
        if priority_match and current_task:
            current_task["priority"] = priority_match.group(1).upper()

        # Parse dependencies
        depends_match = depends_pattern.search(line)
        if depends_match and current_task:
            deps = [d.strip() for d in depends_match.group(1).split(",")]
            current_task["depends_on"] = deps

    # Don't forget the last task
    if current_task and "id" in current_task:
        with contextlib.suppress(Exception):
            tasks.append(TaskInfo(**current_task))

    return tasks


def _calculate_task_progress(tasks: list[TaskInfo]) -> TaskProgress:
    """
    Calculate task progress from a list of tasks.

    Args:
        tasks: List of TaskInfo objects

    Returns:
        TaskProgress with counts by status
    """
    progress = TaskProgress(total=len(tasks))

    for task in tasks:
        if task.status == TaskStatus.PENDING:
            progress.pending += 1
        elif task.status == TaskStatus.IN_PROGRESS:
            progress.in_progress += 1
        elif task.status == TaskStatus.COMPLETED:
            progress.completed += 1
        elif task.status == TaskStatus.SKIPPED:
            progress.skipped += 1

    return progress


def _get_next_available_task(tasks: list[TaskInfo]) -> str | None:
    """
    Get the next available task that can be started.

    A task is available if:
    - Its status is 'pending'
    - All its dependencies are 'completed'

    Args:
        tasks: List of TaskInfo objects

    Returns:
        Task ID of the next available task, or None if no tasks available
    """
    completed_ids = {task.id for task in tasks if task.status == TaskStatus.COMPLETED}

    for task in tasks:
        if task.status == TaskStatus.PENDING and all(
            dep_id in completed_ids for dep_id in task.depends_on
        ):
            return task.id

    return None


def get_feature_status(
    feature_id: str, path: Path | None = None
) -> FeatureStatus | None:
    """
    Get the status of a specific feature.

    Args:
        feature_id: Feature ID (e.g., "001" or "001-user-auth")
        path: Starting path for search (defaults to current directory)

    Returns:
        FeatureStatus object, or None if feature not found
    """
    feature_dir = get_feature_dir(feature_id, path)
    if feature_dir is None:
        return None

    # Extract feature ID and name from directory name
    dir_name = feature_dir.name
    match = FEATURE_DIR_PATTERN.match(dir_name)
    if not match:
        return None

    feature_num = match.group(1)
    feature_name = dir_name[4:]  # Everything after "NNN-"

    # Check for various files
    spec_path = feature_dir / "spec.md"
    plan_path = feature_dir / "plan.md"
    tasks_path = feature_dir / "tasks.md"
    state_path = feature_dir / "state.yaml"

    has_spec = spec_path.exists()
    has_plan = plan_path.exists()
    has_tasks = tasks_path.exists()
    has_state = state_path.exists()

    # Initialize default values
    phase = FeaturePhase.NEW
    worktree_status = WorktreeStatus.ACTIVE
    branch = dir_name
    description = ""
    created = None
    updated = None
    tasks: list[TaskInfo] = []

    # Try to load state from state.yaml
    if has_state:
        try:
            feature_state = FeatureState.load_from_file(state_path)
            phase = feature_state.phase
            worktree_status = feature_state.worktree_status
            branch = feature_state.branch
            description = feature_state.description
            created = feature_state.created
            updated = feature_state.updated
            tasks = feature_state.tasks
        except Exception:
            pass  # Use defaults if state file is invalid

    # If no tasks from state.yaml, try to parse from tasks.md
    if not tasks and has_tasks:
        tasks = _parse_tasks_from_markdown(tasks_path)

    # Calculate task progress
    task_progress = _calculate_task_progress(tasks)

    # Get next available task
    next_task = _get_next_available_task(tasks)

    # Infer phase from available files if not set
    if phase == FeaturePhase.NEW:
        if has_tasks and task_progress.total > 0:
            if task_progress.is_complete:
                phase = FeaturePhase.COMPLETE
            elif task_progress.in_progress > 0 or task_progress.completed > 0:
                phase = FeaturePhase.IMPLEMENT
            else:
                phase = FeaturePhase.TASKS
        elif has_plan:
            phase = FeaturePhase.PLAN
        elif has_spec:
            phase = FeaturePhase.SPEC

    return FeatureStatus(
        id=feature_num,
        name=feature_name,
        full_name=dir_name,
        phase=phase,
        worktree_status=worktree_status,
        branch=branch,
        description=description,
        created=created,
        updated=updated,
        task_progress=task_progress,
        has_spec=has_spec,
        has_plan=has_plan,
        has_tasks=has_tasks,
        has_state=has_state,
        next_available_task=next_task,
    )


def get_project_status(path: Path | None = None) -> StatusResult:
    """
    Get the status of the entire project.

    This includes:
    - Project metadata from config
    - Current git/worktree information
    - Status of all features
    - Aggregate task progress

    Args:
        path: Starting path for search (defaults to current directory)

    Returns:
        StatusResult with ProjectStatus if successful
    """
    cwd = path or Path.cwd()

    # Find project root
    project_root = get_project_root(cwd)
    if project_root is None:
        return StatusResult(
            success=False,
            message="Not in a ProjSpec project. Run 'projspec init' first.",
        )

    # Load project config
    config_path = get_config_path(cwd)
    if config_path is None:
        return StatusResult(
            success=False,
            message="Project config not found. Project may be corrupted.",
        )

    try:
        config = ProjectConfig.load_from_file(config_path)
        project_name = config.project.name
    except Exception as e:
        return StatusResult(
            success=False,
            message=f"Failed to load project config: {e}",
        )

    # Get git information
    current_branch = get_current_branch(cwd)
    in_worktree = is_worktree(cwd)
    current_worktree_info = None

    if in_worktree:
        wt_info = get_worktree_info(cwd)
        if wt_info:
            feature_id = None
            if wt_info.get("is_feature_branch") and wt_info.get("branch"):
                feature_id = wt_info["branch"][:3]
            current_worktree_info = WorktreeInfo(
                path=wt_info.get("path", str(cwd)),
                branch=wt_info.get("branch"),
                is_main=False,
                is_feature_branch=wt_info.get("is_feature_branch", False),
                feature_id=feature_id,
            )

    # Get all features
    feature_names = list_features(cwd)
    features: list[FeatureStatus] = []

    total_tasks = 0
    completed_tasks = 0
    features_by_phase: dict[str, int] = {}

    for feature_name in feature_names:
        status = get_feature_status(feature_name, cwd)
        if status:
            features.append(status)
            total_tasks += status.task_progress.total
            completed_tasks += (
                status.task_progress.completed + status.task_progress.skipped
            )

            # Count by phase
            phase_name = status.phase.value
            features_by_phase[phase_name] = features_by_phase.get(phase_name, 0) + 1

    project_status = ProjectStatus(
        project_name=project_name,
        project_root=str(project_root),
        current_branch=current_branch,
        is_worktree=in_worktree,
        current_worktree=current_worktree_info,
        features=features,
        total_features=len(features),
        features_by_phase=features_by_phase,
        total_tasks=total_tasks,
        completed_tasks=completed_tasks,
    )

    return StatusResult(
        success=True,
        message=f"Project '{project_name}' status retrieved successfully.",
        project_status=project_status,
    )


def format_status_table(status: ProjectStatus) -> list[list[str]]:
    """
    Format project status as table rows for Rich table display.

    Returns a list of rows, where each row is a list of string values:
    [Feature ID, Name, Phase, Tasks Progress, Branch, Next Task]

    Args:
        status: ProjectStatus object to format

    Returns:
        List of table rows
    """
    rows: list[list[str]] = []

    for feature in status.features:
        # Format task progress
        if feature.task_progress.total > 0:
            progress = (
                f"{feature.task_progress.completed}/{feature.task_progress.total} "
                f"({feature.task_progress.percentage:.0f}%)"
            )
            if feature.task_progress.in_progress > 0:
                progress += f" [{feature.task_progress.in_progress} in progress]"
        else:
            progress = "-"

        # Format next task
        next_task = feature.next_available_task or "-"

        # Format phase with emoji indicators
        phase_display = feature.phase.value
        if feature.phase == FeaturePhase.COMPLETE:
            phase_display = f"[green]{phase_display}[/green]"
        elif feature.phase == FeaturePhase.IMPLEMENT:
            phase_display = f"[yellow]{phase_display}[/yellow]"
        elif feature.phase == FeaturePhase.NEW:
            phase_display = f"[dim]{phase_display}[/dim]"

        rows.append(
            [
                feature.id,
                feature.name,
                phase_display,
                progress,
                feature.branch,
                next_task,
            ]
        )

    return rows


def format_status_json(status: ProjectStatus) -> str:
    """
    Format project status as JSON string.

    Args:
        status: ProjectStatus object to format

    Returns:
        JSON string representation of the status
    """
    # Use Pydantic's model_dump with mode="json" for proper serialization
    data = status.model_dump(mode="json")
    return json.dumps(data, indent=2)


def format_feature_status_json(status: FeatureStatus) -> str:
    """
    Format a single feature status as JSON string.

    Args:
        status: FeatureStatus object to format

    Returns:
        JSON string representation of the feature status
    """
    data = status.model_dump(mode="json")
    return json.dumps(data, indent=2)


def get_status_summary(status: ProjectStatus) -> dict[str, Any]:
    """
    Get a summary of the project status suitable for display.

    Args:
        status: ProjectStatus object

    Returns:
        Dictionary with summary information:
        - project_name: Project name
        - total_features: Total number of features
        - phases: Dict of phase counts
        - task_completion: Overall task completion percentage
        - current_context: Information about current branch/worktree
    """
    task_completion = 0.0
    if status.total_tasks > 0:
        task_completion = (status.completed_tasks / status.total_tasks) * 100

    current_context = {
        "branch": status.current_branch,
        "is_worktree": status.is_worktree,
    }
    if status.current_worktree:
        current_context["worktree_path"] = status.current_worktree.path
        current_context["feature_id"] = status.current_worktree.feature_id

    return {
        "project_name": status.project_name,
        "total_features": status.total_features,
        "phases": status.features_by_phase,
        "total_tasks": status.total_tasks,
        "completed_tasks": status.completed_tasks,
        "task_completion": task_completion,
        "current_context": current_context,
    }


# Legacy function for backwards compatibility
def display_status() -> None:
    """
    Display the current project and feature status.

    This is a legacy function that prints status to stdout.
    Consider using get_project_status() and Rich for better formatting.
    """
    result = get_project_status()

    if not result.success:
        print(f"Error: {result.message}")
        return

    if result.project_status is None:
        print("No project status available.")
        return

    status = result.project_status
    summary = get_status_summary(status)

    print(f"\nProject: {summary['project_name']}")
    print(f"Features: {summary['total_features']}")
    print(f"Task Completion: {summary['task_completion']:.1f}%")
    print("\nPhases:")
    for phase, count in summary["phases"].items():
        print(f"  {phase}: {count}")

    if summary["current_context"]["is_worktree"]:
        print(
            f"\nCurrently in worktree: {summary['current_context'].get('branch', 'unknown')}"
        )
    elif summary["current_context"]["branch"]:
        print(f"\nCurrent branch: {summary['current_context']['branch']}")

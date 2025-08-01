"""Pydantic models for Task Dispatcher API."""

from pydantic import Field

from core.model_context import TaskContext


class TaskRequest(TaskContext):
    """Incoming task including optional session id."""

    session_id: str | None = Field(default=None)
    mode: str = Field(default="single")
    task_value: float | None = Field(default=None)
    max_tokens: int | None = Field(default=None)
    priority: int | None = Field(default=None)
    deadline: str | None = Field(default=None)
    required_skills: list[str] | None = Field(default=None)
    enforce_certification: bool = Field(default=False)
    require_endorsement: bool = Field(default=False)

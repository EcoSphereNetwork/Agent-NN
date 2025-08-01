from __future__ import annotations

from typing import Dict, Set

from .roles import AgentRole, _expand_roles, resolve_roles

_ROLE_ACTIONS: Dict[AgentRole, Set[str]] = {
    AgentRole.WRITER: {"submit_task", "write_output"},
    AgentRole.RETRIEVER: {"retrieve_memory", "view_context"},
    AgentRole.CRITIC: {"vote"},
    AgentRole.ANALYST: {"view_context", "submit_task"},
    AgentRole.REVIEWER: {"vote", "view_context"},
    AgentRole.COORDINATOR: {
        "submit_task",
        "view_context",
        "write_output",
        "vote",
        "retrieve_memory",
        "modify_contract",
    },
}


def is_authorized(agent_id: str, role: str, action: str, resource: str) -> bool:
    """Return ``True`` if the agent may perform ``action`` on ``resource``."""
    allowed_roles = resolve_roles(agent_id)
    if allowed_roles and role not in allowed_roles:
        return False
    actions = set()
    for r in _expand_roles([role]):
        try:
            role_enum = AgentRole(r)
        except ValueError:
            continue
        actions.update(_ROLE_ACTIONS.get(role_enum, set()))
    return action in actions

from __future__ import annotations

import json
import os
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Dict, List

from .privacy import AccessLevel

CONTRACT_DIR = Path(os.getenv("CONTRACT_DIR", "contracts"))


@dataclass
class AgentContract:
    """Governance contract for an agent."""

    agent: str
    allowed_roles: List[str]
    max_tokens: int
    trust_level_required: float
    constraints: Dict[str, Any]
    temp_roles: List[str] | None = None
    max_access_level: AccessLevel = AccessLevel.INTERNAL
    require_signature: bool = False

    @classmethod
    def load(cls, agent: str) -> "AgentContract":
        CONTRACT_DIR.mkdir(parents=True, exist_ok=True)
        path = CONTRACT_DIR / f"{agent}.json"
        if path.exists():
            with open(path, encoding="utf-8") as fh:
                data = json.load(fh)
            defaults = asdict(
                cls(
                    agent=agent,
                    allowed_roles=[],
                    max_tokens=0,
                    trust_level_required=0.0,
                    constraints={},
                    temp_roles=None,
                    max_access_level=AccessLevel.INTERNAL,
                    require_signature=False,
                )
            )
            defaults.update(data)
            return cls(**defaults)
        return cls(
            agent=agent,
            allowed_roles=[],
            max_tokens=0,
            trust_level_required=0.0,
            constraints={},
            temp_roles=None,
            max_access_level=AccessLevel.INTERNAL,
            require_signature=False,
        )

    def save(self) -> None:
        CONTRACT_DIR.mkdir(parents=True, exist_ok=True)
        path = CONTRACT_DIR / f"{self.agent}.json"
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(asdict(self), fh, indent=2)

"""Typing utilities."""
from pathlib import Path
from typing import Literal, Optional, TypeAlias

PathStr: TypeAlias = Path | str
Scope: TypeAlias = Literal["full", "lite"]
SCOPES = ["full", "lite"]


def coerce_to_Path(path: Optional[PathStr]) -> Path:
    """Return a Path from a given path or string."""
    if isinstance(path, str):
        path = Path(path.strip("\"'"))
    elif path is None:
        path = Path().absolute()
    assert isinstance(path, Path)
    return path


__all__ = ["coerce_to_Path", "PathStr"]

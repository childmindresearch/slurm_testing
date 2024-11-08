"""Typing utilities."""
from pathlib import Path
from typing import Optional

PATH_OR_STR = Path | str


def coerce_to_Path(path: Optional[PATH_OR_STR]) -> Path:
    """Return a Path from a given path or string."""
    if isinstance(path, str):
        path = Path(path.strip("\"'"))
    elif path is None:
        path = Path().absolute()
    assert isinstance(path, Path)
    return path


__all__ = ["coerce_to_Path", "PATH_OR_STR"]

"""Utilities for C-PAC Slurm testing."""
from ._typing import coerce_to_Path, PathStr
from .utils import unlink

__all__ = ["coerce_to_Path", "PathStr", "unlink"]

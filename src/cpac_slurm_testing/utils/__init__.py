"""Utilities for C-PAC Slurm testing."""
from ._typing import coerce_to_Path, PathStr, Scope, SCOPES
from .utils import ExistingPath, unlink

__all__ = ["coerce_to_Path", "ExistingPath", "PathStr", "Scope", "SCOPES", "unlink"]

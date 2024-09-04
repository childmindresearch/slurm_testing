"""Utilities for C-PAC Slurm testing."""
from ._typing import coerce_to_Path, PATH_OR_STR
from .utils import unlink

__all__ = ["coerce_to_Path", "PATH_OR_STR", "unlink"]

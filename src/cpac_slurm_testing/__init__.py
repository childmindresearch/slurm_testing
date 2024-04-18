"""Automatic management of C-PAC regression tests via SLURM."""
from importlib.metadata import version

__version__ = version(__name__)

__all__ = ["__version__"]

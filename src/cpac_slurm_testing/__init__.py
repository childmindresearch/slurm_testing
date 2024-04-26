#!/usr/bin/env python3
"""Automatic management of C-PAC regression tests via SLURM."""
from importlib.metadata import PackageNotFoundError, version
from importlib.resources import as_file, files
from pathlib import Path
import subprocess
from typing import Optional


def get_git_version(project_version=str) -> str:
    """Get version from git."""
    # memoized on disk
    try:
        with as_file(files("cpac_slurm_testing")) as repo:
            version_file: Optional[Path] = repo / "version"
            assert version_file is not None
            if version_file.exists():
                with open(version_file, "r", encoding="utf8") as _f:
                    return _f.read()
    except (ModuleNotFoundError, PackageNotFoundError):
        version_file = None

    try:
        git_version: Optional[str] = (
            subprocess.check_output(["git", "describe", "--always"]).strip().decode()
        )
    except subprocess.CalledProcessError:
        git_version = None

    if git_version:
        project_version = f"{project_version.strip()}@{git_version.strip()}"

    if version_file:
        # memoize on disk
        with open(version_file, "w", encoding="utf-8") as _f:
            _f.write(project_version)
    return project_version


def get_version_from_toml(toml: Path) -> str:
    """Get version from given TOML file."""
    with toml.open("r", encoding="utf8") as _f:
        for line in _f.readlines():
            if line.startswith("version ") or line.startswith("version="):
                return line[7:].lstrip(" =")
    return "unknown.dev"


def get_version() -> str:
    """Return the current version of cpac_slurm_testing."""
    try:
        _version = version(__name__)
    except PackageNotFoundError:
        _version = get_version_from_toml(
            Path(__file__).parent.parent.parent / "pyproject.toml"
        )
    if ".dev" not in _version:
        return _version

    return get_git_version(_version)


__version__ = get_version()

__all__ = ["__version__"]

if __name__ == "__main__":
    print(get_version())  # noqa: T201

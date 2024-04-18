#!/usr/bin/env python3
"""Automatic management of C-PAC regression tests via SLURM."""
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path
import subprocess


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

    version_file = Path("version")
    if version_file.exists():
        with open(version_file, "r", encoding="utf8") as _f:
            return _f.read()

    try:
        git_version = (
            subprocess.check_output(["git", "describe", "--always"]).strip().decode()
        )
        _version = f"{_version}@{git_version}"
        with open(version_file, "w", encoding="utf-8") as _f:
            _f.write(_version)
    except subprocess.CalledProcessError:
        pass

    return _version


__version__ = get_version()

__all__ = ["__version__"]

if __name__ == "__main__":
    print(get_version())  # noqa: T201

#!/usr/bin/env python3
"""Update local fork's ``repository`` URL."""
from pathlib import Path
import re

from git import Repo
from git.exc import GitCommandError


def get_git_remote_origin(repo_dir: Path) -> str:
    """Get Git remote origin."""
    try:
        configured_url = Repo(repo_dir).remotes.origin.url
        _prefix, suffix = configured_url.split("github.com")
        return f"https://github.com/{suffix[1:-4]}"
    except AttributeError as e:
        if "origin" in str(e):
            raise GitCommandError(["git", "remote", "get-url", "origin"]) from e
        raise e


def get_repo_dir() -> Path:
    """Get path to repository directory."""
    return Path(__file__).parents[2]


def main() -> None:
    """Replace ``repository`` in ``pyproject.toml`` with forked repo."""
    repo_dir = get_repo_dir()
    forked_repo_url = get_git_remote_origin(repo_dir)
    pyproject = repo_dir / "pyproject.toml"
    repo_pattern = re.compile(r'^repository = ".*"$')

    lines: list[str] = []
    changed = False
    with pyproject.open("r", encoding="utf-8") as _pyproject:
        for line in _pyproject.readlines():
            if repo_pattern.match(line):
                newline = f'repository = "{forked_repo_url}"\n'
                if newline != line:
                    changed = True
                    lines.append(newline)
            else:
                lines.append(line)
    if changed:
        with pyproject.open("w", encoding="utf-8") as _pyproject:
            _pyproject.write("".join(lines))


if __name__ == "__main__":
    main()

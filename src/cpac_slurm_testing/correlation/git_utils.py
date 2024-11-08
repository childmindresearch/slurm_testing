"""Git and GitHub utilities for repo management."""
import os
from pathlib import Path
from time import sleep
from typing import Any, Callable, Optional
from warnings import warn

from git.exc import GitCommandError


def get_github_token() -> str:
    """Get GitHub personal access token (PAT)."""
    contents: str = ""
    token: Optional[str] = None
    token_file: Optional[str] = os.environ.get("TOKEN_FILE", None)
    if token_file:
        with Path(token_file).open("r", encoding="utf-8") as _token_file:
            contents = _token_file.read()
    for key in ["GITHUB_TOKEN", "GH_TOKEN"]:
        if key in contents:
            return contents.split(key, 1)[1]
        token = os.environ.get(key, None)
        if token:
            return token
    msg = "Could not determine PAT for GitHub access."
    raise LookupError(msg)


def await_git_lock(
    fxn: Callable,
    args: Optional[list[Any]] = None,
    kwargs: Optional[dict[str, Any]] = None,
) -> Any:
    """Retry operation if we hit a lock error."""
    if not args:
        args = []
    if not kwargs:
        kwargs = {}
    try:
        return fxn(*args, **kwargs)
    except GitCommandError as git_command_error:
        if "lock" in str(git_command_error):
            warn(f"{git_command_error}\nRetrying in 5 seconds")
            sleep(5)
            return await_git_lock(fxn, args, kwargs)
        raise git_command_error


try:
    GITHUB_TOKEN: Optional[str] = get_github_token()
except LookupError as lookup_error:
    warn(str(lookup_error))
    GITHUB_TOKEN = None

"""Git and GitHub utilities for repo management."""
import os
from pathlib import Path
from typing import Optional


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


GITHUB_TOKEN: str = get_github_token()

"""Git remote info."""
from dataclasses import dataclass


@dataclass
class GitRemoteInfo:
    """Info for remote git repository."""

    owner: str
    repo: str
    sha: str
    token: str

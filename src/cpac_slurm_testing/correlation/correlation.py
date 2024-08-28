"""Correlation run logs."""
import os
from pathlib import Path

from dulwich import porcelain
from dulwich.repo import Repo
from git import Repo as GitRepo


def init_repo(correlations_dir: Path, branch_name: str, github_token: str) -> GitRepo:
    """Create and push a respository for a correlation run's logs."""
    repo: Repo | GitRepo
    remote = f"{os.environ['OWNER']}/regtest-runlogs"
    repo = porcelain.init(correlations_dir)
    porcelain.branch_create(repo, branch_name, force=True)
    porcelain.remote_add(
        repo,
        "origin",
        f"https://{os.environ['USER']}:{github_token}@github.com/{remote}.git",
    )
    porcelain.add()
    porcelain.commit()
    repo = GitRepo(correlations_dir)
    repo.remotes.origin.push(branch_name)
    return repo

"""Correlation run logs."""
import os
from pathlib import Path

from dulwich import porcelain
from dulwich.repo import Repo
from git import Repo as GitRepo


def init_repo(
    correlations_dir: Path | str, branch_name: str, github_token: str
) -> GitRepo:
    """Create and push a respository for a correlation run's logs."""
    repo: Repo | GitRepo
    remote = f"{os.environ['OWNER']}/regtest-runlogs"
    try:
        repo = porcelain.init(correlations_dir)
    except FileExistsError:
        repo = porcelain.open_repo(correlations_dir)
    _orig_path = Path(".").absolute()
    os.chdir(correlations_dir)
    porcelain.add()
    porcelain.commit(message=":memo: Document correlations")
    porcelain.branch_create(repo, branch_name, force=True)
    try:
        porcelain.remote_add(
            repo,
            "origin",
            f"https://{os.environ['USER']}:{github_token}@github.com/{remote}.git",
        )
    except porcelain.RemoteExists:
        pass
    repo = GitRepo(correlations_dir)
    repo.remotes.origin.push(branch_name)
    os.chdir(_orig_path)
    return repo

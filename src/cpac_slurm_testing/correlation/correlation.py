"""Correlation run logs."""
from logging import Logger
import os
from pathlib import Path
from typing import cast

from dulwich import porcelain
from dulwich.repo import Repo
from git import Repo as GitRepo
from cpac_correlations import cpac_correlations, CpacCorrelationsNamespace

from cpac_slurm_testing.status._global import get_logger

LOGGER: Logger = get_logger(name=__name__)


def correlate(namespace: CpacCorrelationsNamespace) -> None:
    """Generate a JSON file from which to graph correlations."""
    cpac_correlations(namespace)


def init_branch(
    correlations_dir: str | Path, branch_name: str, owner: str, github_token: str
) -> GitRepo:
    """Create and push a branch for a correlation run's logs."""
    repo: Repo | GitRepo
    remote: str = f"{owner}/regtest-runlogs"
    try:
        repo = porcelain.init(str(correlations_dir))
    except FileExistsError:
        repo = cast(Repo, porcelain.open_repo(correlations_dir))
    _orig_path: Path = Path(".").absolute()
    os.chdir(correlations_dir)
    porcelain.add()
    porcelain.commit(message=":memo: Document correlations")
    porcelain.branch_create(repo, branch_name, force=True)
    try:
        porcelain.remote_add(
            repo,
            "origin",
            f"https://{owner}:{github_token}@github.com/{remote}.git",
        )
    except porcelain.RemoteExists:
        pass
    repo = GitRepo(correlations_dir)
    repo.remotes.origin.push(f"{branch_name}:{branch_name}")
    os.chdir(_orig_path)
    return repo

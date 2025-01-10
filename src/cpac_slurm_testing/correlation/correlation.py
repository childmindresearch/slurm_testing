"""Correlation run logs."""
from logging import Logger
import os
from pathlib import Path
from shutil import copy2
import subprocess

from git import Repo
from cpac_correlations import CpacCorrelationsNamespace

from cpac_slurm_testing.correlation.git_utils import await_git_lock
from cpac_slurm_testing.status._global import get_logger, SBATCH_START

LOGGER: Logger = get_logger(name=__name__)


def correlate(namespace: CpacCorrelationsNamespace) -> int:
    """Generate a JSON file from which to graph correlations.

    Returns
    -------
    job_id : int
        SLURM job ID for correlation job.
    """
    command: list[str] = [
        *SBATCH_START,
        "--job-name",
        "_".join([namespace.branch, namespace.data_source]),
        "--parsable",
        "cpac_correlations",
        *namespace.cli_args,
    ]
    return int(
        subprocess.run(command, capture_output=True, check=False)
        .stdout.decode()
        .split(" ")[0]
    )


def _copy_plot(plot_dir: Path) -> None:
    """Copy plots from single site-pipeline-specific directory."""
    destination: Path = plot_dir.parent / "correlations"
    prefix: str = plot_dir.name[13:].split("_", 1)[-1]
    for file_path in plot_dir.iterdir():
        if file_path.is_file():
            copy2(file_path, destination / f"{prefix}_{file_path.name}")


def copy_plots(plot_dirs: list[Path]) -> None:
    """Copy plots from site-pipeline-specific directories to single directory.

    For reporting.
    """
    for plot_dir in plot_dirs:
        _copy_plot(plot_dir)


def init_branch(
    correlations_dir: str | Path, branch_name: str, owner: str, github_token: str
) -> Repo:
    """Create and push a branch for a correlation run's logs."""
    repo: Repo
    remote: str = f"{owner}/regtest-runlogs"
    repo = (
        Repo(correlations_dir)
        if os.path.exists(correlations_dir)
        else Repo.init(str(correlations_dir))
    )
    _orig_path: Path = Path(".").absolute()
    os.chdir(correlations_dir)
    plot_dirs: list[Path] = [
        corr_dir
        for corr_dir in Path(correlations_dir).parent.iterdir()
        if corr_dir.name.startswith("correlations_")
    ]
    copy_plots(plot_dirs)
    await_git_lock(repo.git.add, kwargs={"A": True})
    await_git_lock(repo.index.commit, [":memo: Document correlations"])
    if branch_name not in repo.heads:
        await_git_lock(repo.create_head, [branch_name])
    await_git_lock(repo.git.checkout, [branch_name])
    if "origin" not in repo.remotes:
        await_git_lock(
            repo.create_remote, ["origin", f"https://github.com/{remote}.git"]
        )
    os.chdir(_orig_path)
    return repo

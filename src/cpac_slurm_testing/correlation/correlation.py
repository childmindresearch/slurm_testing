"""Correlation run logs."""
from logging import Logger
import os
from pathlib import Path
from shutil import copy2
import subprocess
from typing import cast

from dulwich import porcelain
from dulwich.repo import Repo
from cpac_correlations import CpacCorrelationsNamespace

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
    try:
        repo = porcelain.init(str(correlations_dir))
    except FileExistsError:
        repo = cast(Repo, porcelain.open_repo(correlations_dir))
    _orig_path: Path = Path(".").absolute()
    os.chdir(correlations_dir)
    plot_dirs: list[Path] = [
        corr_dir
        for corr_dir in Path(correlations_dir).parent.iterdir()
        if corr_dir.name.startswith("correlations_")
    ]
    copy_plots(plot_dirs)
    porcelain.add()
    porcelain.commit(message=":memo: Document correlations")
    porcelain.branch_create(repo, branch_name, force=True)
    porcelain.checkout_branch(repo, branch_name, force=True)
    try:
        porcelain.remote_add(
            repo,
            "origin",
            f"https://{owner}:{github_token}@github.com/{remote}.git",
        )
    except porcelain.RemoteExists:
        pass
    os.chdir(_orig_path)
    return repo

"""Launch a C-PAC regression test workflow."""
from dataclasses import asdict, dataclass, KW_ONLY
from importlib.resources import as_file, files
from logging import Logger
import os
from pathlib import Path
import subprocess

from cpac_slurm_testing.git_remote import GitRemoteInfo
from cpac_slurm_testing.status import TestingPaths, TotalStatus
from cpac_slurm_testing.status._global import get_logger, SBATCH_START
from cpac_slurm_testing.utils import PathStr

LOGGER: Logger = get_logger(name=__name__)


@dataclass
class LaunchParameters:
    """Parameters for launching a regression test."""

    testing_paths: TestingPaths
    comparison_path: PathStr = ""
    dashboard_repo: str = ""
    home_dir: PathStr = ""
    image: str = ""
    owner: str = ""
    path_extra: str = ""
    repo: str = ""
    sha: str = ""
    slurm_testing_branch: str = ""
    slurm_testing_repo: str = ""
    token_file: PathStr = ""
    _: KW_ONLY
    dry_run: bool = False

    def __post_init__(self) -> None:
        """Coerce Path typing and check for env variables."""
        self.comparison_path = Path(self.comparison_path)
        self.home_dir = Path(self.home_dir)
        self.log_dir = self.testing_paths.log_dir
        if "/" in self.repo:
            self.repo = self.repo.split("/", 1)[-1]
        self.token_file = Path(self.token_file)
        self.wd = self.testing_paths.wd
        _git_defaults = {"owner": "FCP-INDI", "repo": "C-PAC"}
        for attr in ["owner", "repo", "sha"]:
            if not getattr(self, attr):
                try:
                    setattr(
                        self, attr, os.environ.get(attr.upper(), _git_defaults[attr])
                    )
                except (AttributeError, KeyError, LookupError):
                    msg = "SHA is required."
                    raise LookupError(msg)

    @staticmethod
    def keys(except_for: list[str] = []) -> list[str]:
        """Return list of parameters.

        Parameters
        ----------
        List of keys to exclude
        """
        return [
            key
            for key in LaunchParameters.__dataclass_fields__.keys()
            if key not in except_for
        ]

    @property
    def as_environment_variables(self) -> dict[str, str]:
        """Return a dictionary of environment variable keys and values."""
        return {
            key.upper(): str(value.wd) if key == "testing_paths" else str(value)
            for key, value in asdict(self).items()
            if key != "dry_run"
        }

    @property
    def as_slurm_export(self) -> str:
        """Return as environment variable ``--export`` argument for sbatch."""
        return f'--export={",".join(["=".join(item) for item in self.as_environment_variables.items() if item[0]])}'


def launch(parameters: LaunchParameters) -> None:
    """Launch a regression test."""
    with as_file(files("cpac_slurm_testing")) as repo:
        assert isinstance(parameters.home_dir, Path)
        slurm_env = parameters.as_slurm_export
        build: list[str] = [
            *SBATCH_START[:-1],
            slurm_env,
            f"--output={parameters.testing_paths.log_dir}/build.out.log",
            f"--error={parameters.testing_paths.log_dir}/build.err.log",
            "--parsable",
            str(repo / "regression_run_scripts/build_image.sh"),
            "--working_dir",
            f"{parameters.home_dir / 'lite' / parameters.sha}",
            "--image",
            f"{parameters.image}",
        ]
        cmd: list[str] = [
            *SBATCH_START,
            "-t",
            "00:00:20",
            slurm_env,
            f"--output={parameters.testing_paths.log_dir}/launch.out.log",
            f"--error={parameters.testing_paths.log_dir}/launch.err.log",
            str(repo / "regression_run_scripts/regtest_lite.sh"),
        ]
    if parameters.dry_run:
        cmd = [*cmd, "--dry-run"]
    with open(parameters.token_file, "r", encoding="utf8") as _token_file:
        github_token: str = _token_file.read().strip()
        if "GITHUB_TOKEN=" in github_token:
            github_token = github_token.split("GITHUB_TOKEN=", 1)[1]
    git_remote = GitRemoteInfo(
        owner=parameters.owner,
        repo=parameters.repo,
        sha=parameters.sha,
        token=github_token,
    )
    status = TotalStatus(
        testing_paths=parameters.testing_paths,
        home_dir=parameters.home_dir,
        image=parameters.sha,
        dry_run=parameters.dry_run,
        git_remote=git_remote,
    )
    LOGGER.info(status)
    if not parameters.dry_run:
        build_job: str = (
            subprocess.run(args=build, check=False, capture_output=True)
            .stdout.decode()
            .strip()
        )
        cmd = [cmd[0], f"--dependency=afterok:{build_job}", *cmd[1:]]
        subprocess.run(cmd, check=False)
    LOGGER.info(build)
    LOGGER.info(cmd)


launch.__doc__ = __doc__

__all__ = ["launch"]

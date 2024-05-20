"""Launch a C-PAC regression test workflow."""
from dataclasses import asdict, dataclass, KW_ONLY
from importlib.resources import as_file, files
from logging import basicConfig, getLogger, INFO
from pathlib import Path
import subprocess

from cpac_slurm_testing.status import TotalStatus
from cpac_slurm_testing.status._global import LOG_FORMAT
from cpac_slurm_testing.utils.typing import PATH_OR_STR

LOGGER = getLogger(name=__name__)
basicConfig(format=LOG_FORMAT, level=INFO)


@dataclass
class LaunchParameters:
    """Parameters for launching a regression test."""

    comparison_path: PATH_OR_STR = ""
    dashboard_repo: str = ""
    home_dir: PATH_OR_STR = ""
    image: str = ""
    owner: str = ""
    path_extra: str = ""
    repo: str = ""
    sha: str = ""
    slurm_testing_branch: str = ""
    slurm_testing_repo: str = ""
    token_file: PATH_OR_STR = ""
    _: KW_ONLY
    dry_run: bool = False

    def __post_init__(self) -> None:
        """Coerce Path typing."""
        self.comparison_path: Path = Path(self.comparison_path)
        self.home_dir: Path = Path(self.home_dir)
        self.log_dir: Path = self.home_dir / "logs" / self.sha
        if "/" in self.repo:
            self.repo = self.repo.split("/", 1)[-1]
        self.token_file: Path = Path(self.token_file)
        self.wd: Path = self.home_dir / "lite" / self.sha

    @staticmethod
    def keys() -> list[str]:
        """Return list of parameters."""
        return list(LaunchParameters.__dataclass_fields__.keys())

    @property
    def as_environment_variables(self) -> dict[str, str]:
        """Return a dictionary of environment variable keys and values."""
        return {
            key.upper(): str(value)
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
            "sbatch",
            slurm_env,
            "--parsable",
            str(repo / "regression_run_scripts/build_image.sh"),
            f"--working_dir '{parameters.home_dir / 'lite' / parameters.sha}'",
            f"--image '{parameters.image}'",
        ]
        cmd: list[str] = [
            "sbatch",
            slurm_env,
            f"--output={parameters.log_dir}/out.log",
            f"--error={parameters.log_dir}/error.log",
            str(repo / "regression_run_scripts/regtest_lite.sh"),
        ]
    if parameters.dry_run:
        cmd = [*cmd, "--dry-run"]
    status = TotalStatus(path=parameters.wd / "status.🥒", image=parameters.sha)
    status.write()
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

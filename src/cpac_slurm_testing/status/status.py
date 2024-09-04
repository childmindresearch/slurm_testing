#!/usr/bin/env python
# -*- coding: utf-8 -*-
# SBATCH -N 1
# SBATCH -p RM-shared
# SBATCH -t 00:05:00
# SBATCH --ntasks-per-node=4
"""Consolidate job statistics into a single GitHub status.

Requires the following environment variables:
- OWNER: The owner of the repository.
- REPO: The repository.
- SHA: The commit SHA.

Also optionally accepts the following environment variables (or these can be passed as commandline arguments):
- _CPAC_STATUS_DATA_SOURCE: The data source.
- _CPAC_STATUS_PRECONFIG: The preconfig.
- _CPAC_STATUS_SUBJECT: The subject.
- _CPAC_STATUS_STATE: The status of the run. Defaults to "pending".
"""
from dataclasses import dataclass
from datetime import datetime
from fcntl import flock, LOCK_EX, LOCK_UN
from fractions import Fraction
from importlib.resources import files
from logging import basicConfig, getLogger, INFO, Logger
import os
from pathlib import Path
import pickle
from random import choice, randint
import subprocess
from tempfile import NamedTemporaryFile
from typing import Callable, cast, Iterable, Literal, Optional, overload, Union

from github import Github
from github.Commit import Commit
from github.Repository import Repository
from cpac_correlations import CpacCorrelationsNamespace
from cpac_regression_dashboard.utils.parse_yaml import cpac_yaml

from cpac_slurm_testing.correlation.correlation import correlate, init_repo
from cpac_slurm_testing.git_remote import GitRemoteInfo
from cpac_slurm_testing.status._global import (
    _COMMAND_TYPES,
    _JOB_STATE,
    _STATE,
    JOB_STATES,
    LOG_FORMAT,
    SBATCH_START,
    TEMPLATES,
)
from cpac_slurm_testing.utils import coerce_to_Path, unlink

LOGGER: Logger = getLogger(name=__name__)
basicConfig(format=LOG_FORMAT, level=INFO)


def _set_intermediate_directory(
    directory: Path | str, intermediate: str, mkdir: bool = True
) -> Path:
    """Set directory between user and image.

    Examples
    --------
    >>> str(_set_intermediate_directory('/home/user/full/image', 'lite', False))
    '/home/user/lite/image'
    >>> str(_set_intermediate_directory('/home/user/full/image', 'logs', False))
    '/home/user/logs/image'
    """
    _parts: list[str] = str(directory).split("/")
    path = Path("/".join([*_parts[:-2], intermediate, _parts[-1]]))
    if mkdir and not path.exists():
        os.makedirs(str(path), exist_ok=True)
    return path


def _set_working_directory(wd: Optional[Path | str] = None) -> tuple[Path, Path]:
    """Set working directory.

    Priority order:
    1. `wd` if `wd` is given.
    2. `$REGTEST_LOG_DIR` if such environment variable is defined.
    3. Do nothing.

    Returns
    -------
    wd
        working directory

    _logpath
        log directory
    """
    filename: str = "status.log"
    _logger: Callable
    _log_msg: list[str]
    if wd is None:
        wd = coerce_to_Path(os.environ.get("REGTEST_LOG_DIR"))
    if not wd:
        _logger = LOGGER.warning
        _log_msg = ["`wd` was not provided and `$REGTEST_LOG_DIR` is not set."]
    if wd:
        wd = _set_intermediate_directory(coerce_to_Path(wd).absolute(), "lite")
    else:
        from datetime import datetime
        from time import localtime, strftime

        wd = (
            Path.cwd().absolute()
            / "lite"
            / "".join(
                [
                    datetime.now().strftime("%Y%m%d%H%M%S.%f%Z"),
                    strftime("%Z", localtime()),
                ]
            )
        )
        for parent in reversed(wd.parents):
            parent.mkdir(mode=0o777, exist_ok=True)
        wd.mkdir(mode=0o777, exist_ok=True)
    os.chdir(str(wd))
    _logger = LOGGER.info
    _log_msg = ["Set working directory to %s", str(wd)]
    _logpath: Path = _set_intermediate_directory(wd, "logs")
    filename = f"{_logpath}/{filename}"
    basicConfig(
        filename=filename,
        encoding="utf8",
        force=True,
        format=LOG_FORMAT,
        level=INFO,
    )
    _logger(*_log_msg)  # log info or warning as appropriate
    return Path(wd), Path(_logpath)


class TestingPaths:
    """Working and logging path management."""

    def __init__(self, wd: Optional[Path | str] = None) -> None:
        """Initialize TestingPaths."""
        self._log_dir: Path
        self._wd: Path
        self._wd, self._log_dir = _set_working_directory(wd)

    @property
    def log_dir(self) -> Path:
        """Return log directory."""
        return self._log_dir

    @property
    def wd(self) -> Path:
        """Return working directory."""
        return self._wd

    def __iter__(self) -> Iterable[Path]:
        """Return an iterator of working and logging directories."""
        yield self.wd
        yield self.log_dir

    def __len__(self) -> int:
        """Return the number of testing paths."""
        _attrs = 0
        for _attr in ["wd", "log_dir"]:
            if hasattr(self, _attr):
                _attrs += 1
        return _attrs

    def __repr__(self) -> str:
        """Return reproducible TestingPaths."""
        return f"TestingPaths(Path('{self.wd}'))"

    def __str__(self) -> str:
        """Return a string representation of TestingPaths."""
        _parts: list[str] = str(self.log_dir).rsplit("/logs/", 1)
        return "/l(ite|ogs)/".join(_parts)


def indented_lines(lines: str) -> str:
    """Return a multiline string with each line indented one tab."""
    _lines: list[str] = lines.split("\n")
    return "\n".join([_lines[0], *[f"\t{line}" for line in _lines[1:]]]).rstrip()


class SlurmJobStatus:
    """Store a SLURM job status."""

    def __init__(self, scontrol_output: str, dry_run: bool = False) -> None:
        """Convert the scontrol_output into individual values."""
        self._scontrol_dict: dict[str, Optional[str]] = {
            key: (value if value != "(null)" else None)
            for item in scontrol_output.split()
            for key, value in [
                (
                    item.split("=", maxsplit=1)
                    if not item.endswith("=")
                    else [item[:-1], "(null)"]
                )
            ]
        }
        self.dry_run: bool = dry_run

    @overload
    def get(
        self, key: Literal["JobState"], default: _JOB_STATE = "PENDING"
    ) -> _JOB_STATE:
        ...

    @overload
    def get(self, key: str, default: Optional[str] = None) -> Optional[str]:
        ...

    def get(self, key, default=None) -> Optional[str]:
        """Return the value for key if key is in the SLURM job status, else default."""
        try:
            return getattr(self, key)
        except (AttributeError, KeyError):
            return default

    @property
    def job_state(self) -> _JOB_STATE:
        """Return JobState from SLURM."""
        if self.dry_run:
            return choice(list(JOB_STATES.keys()))
        return self["JobState"]

    @overload
    def __getitem__(self, item: Literal["JobState"]) -> _JOB_STATE:
        ...

    @overload
    def __getitem__(self, item: str) -> Optional[str]:
        ...

    def __getitem__(self, item) -> Optional[str]:
        """Return an item from the scontrol output."""
        return self._scontrol_dict.get(item)

    def __eq__(self, other) -> bool:
        """Return True if SLURM job status dictionaries are equal, else False."""
        if not isinstance(other, SlurmJobStatus):
            return False
        return self._scontrol_dict == other._scontrol_dict

    def __repr__(self) -> str:
        """Return reproducible string represntation of SLURM job status."""
        _str: str = " ".join(
            [
                "=".join([key, (value if value else "(null)")])
                for key, value in self._scontrol_dict.items()
            ]
        )
        return f"SlurmJobStatus('{_str}', dry_run={self.dry_run})"

    def __str__(self) -> str:
        """Return string representation of SLURM job status."""
        return f"{self.get('JobId')} ({self.get('Command')}): {self.get('JobState')}"


@dataclass
class RunStatus:
    """Store the status of a run for the GitHub Check."""

    testing_paths: TestingPaths
    """Paths for working and log directories."""
    data_source: str
    """Directory name (just final level), e.g. "HNU_1"."""
    preconfig: str
    """Preconfiguration to test."""
    subject: str
    """Subject ID."""
    _total: "TotalStatus"
    """TotalStatus that includes this RunStatus."""
    status: _STATE = "pending"
    """Success/failure/pending status of this run."""
    job_id: Optional[int] = None
    """Scheduler job ID."""
    _slurm_job_status: Optional[SlurmJobStatus] = None
    """Schedulre job status."""
    _command_file: Optional[Path] = None
    """Temporary file holding SLURM command."""

    def check_slurm(self) -> None:
        """Check SLURM job status."""
        if self.dry_run:
            if self.job_id:
                self._slurm_job_status = SlurmJobStatus(
                    f"JobId={self.job_id}", dry_run=self.dry_run
                )
        else:
            try:
                self._slurm_job_status = SlurmJobStatus(
                    subprocess.run(
                        ["scontrol", "show", "job", str(self.job_id)],
                        capture_output=True,
                        check=True,
                    ).stdout.decode(),
                    dry_run=self.dry_run,
                )
            except subprocess.CalledProcessError:
                self.status = "error"
        if self.status != "error" and self._slurm_job_status:
            self.status = JOB_STATES[self._slurm_job_status.job_state]

    def __post_init__(self) -> None:
        """Set some determinable attributes after initializing."""
        self.pdsd: str = f"{self.preconfig}-{self.data_source}-{self.subject}"
        """preconfig-data_source-subject"""
        self.wd: Path = self.testing_paths.wd / f"slurm-{self.pdsd}"
        """working directory"""
        self.log_dir: Path = self.testing_paths.log_dir / f"slurm-{self.pdsd}"
        """log directory"""
        self._total += self

    def command(self, command_type: str) -> str:
        """Return a command string for a given command_type."""
        assert self._total is not None
        if not self.log_dir.exists():
            self.log_dir.mkdir(mode=0o777, exist_ok=True)
        return TEMPLATES[command_type].format(
            datapath=self.total.home_dir / f"DATA/reg_5mm_pack/data/{self.data_source}",
            regdatapath=self.total.home_dir / "DATA/reg_5mm_pack",
            home_dir=self.total.home_dir,
            log_dir=self.log_dir,
            image=self.total.image("path"),
            image_name=self.total.image("name"),
            output=self.out("lite") / self.preconfig / self.data_source,
            pdsd=self.pdsd,
            pipeline=self.preconfig,
            pipeline_configs=str(
                files("cpac_slurm_testing.pipeline_configs").joinpath("")
            ),
            subject=self.subject,
        )

    @property
    def dry_run(self) -> bool:
        """Is this a dry run?"""  # noqa: D400
        return self._total.dry_run

    @dry_run.setter
    def dry_run(self, dry_run) -> None:
        """Make this a dry run?"""  # noqa: D400
        self._total.dry_run = dry_run

    @property
    def key(self) -> tuple[str, str, str]:
        """Return a unique key for each preconfig × data_source × subject."""  # noqa: RUF002
        return self.data_source, self.preconfig, self.subject

    def launch(self, command_type: _COMMAND_TYPES) -> None:
        """Launch a SLURM job and set its job ID."""
        _command_types: list[str] = eval(
            str(_COMMAND_TYPES).replace(
                str(
                    _COMMAND_TYPES.__origin__  # type: ignore[attr-defined]
                ),
                "",
            )
        )
        if command_type not in _command_types:
            msg: str = f"{command_type} not in {_command_types}"
            raise KeyError(msg)
        with NamedTemporaryFile(mode="w", encoding="utf8", delete=False) as _f:
            self._command_file = Path(_f.name)
            _f.write(self.command(command_type))
            _f.close()
            with open(_f.name, "r", encoding="utf8") as _command_file:
                LOGGER.info(
                    "%s:\n\n\t%s", _f.name, indented_lines(_command_file.read())
                )
            command: list[str] = [
                *SBATCH_START,
                f"--output={self.log_dir}/launch.out.log",
                f"--error={self.log_dir}/launch.err.log",
                "--job-name",
                self.subject.split("sub-", 1)[-1],
                "--parsable",
                _f.name,
            ]
            if self.dry_run:
                LOGGER.info("Dry run.")
                self.job_id = randint(1, 99999999)
            else:
                self.job_id = int(
                    subprocess.run(command, capture_output=True, check=False)
                    .stdout.decode()
                    .split(" ")[0]
                )
            LOGGER.info("%s = %s", self.job_id, " ".join(command))

    def out(self, lite_or_full: Literal["full", "lite"]) -> Path:
        """Return the path to the output directory."""
        return self.total.out(lite_or_full)

    @property
    def job_status(self) -> str:
        """Return the job's status per the SLURM job status."""
        if self.status == "pending":
            self.check_slurm()
        return self.status

    @property
    def total(self) -> "TotalStatus":
        """Return TotalStatus that contains this RunStatus."""
        assert self._total is not None
        return self._total

    @total.setter
    def total(self, total_status: "TotalStatus") -> None:
        """Set the TotalStatus that contains this RunStats."""
        assert isinstance(total_status, TotalStatus)
        self._total = total_status

    def __repr__(self) -> str:
        """Return reproducible string representation of the status."""
        return (
            f"RunStatus({self.data_source}, {self.preconfig}, {self.subject}, "
            f"status={self.status}, _total={self.total})"
        )

    def __str__(self) -> str:
        """Return the string representation of the status."""
        return (
            f"{self.preconfig} × {self.data_source}: "  # noqa: RUF001
            f"{self.subject} = {self.status}"
        )


@dataclass
class TotalStatus:
    """Store the total status of all runs for the GitHub Check."""

    @property
    def failure(self) -> Fraction:
        """Return the fraction of runs that are failures."""
        return self.fraction("failure") + self.fraction("error")

    @property
    def failures(self) -> Fraction:  # noqa: D102
        return self.failure

    failures.__doc__ = failure.__doc__

    @property
    def success(self) -> Fraction:
        """Return the fraction of runs that are successful."""
        return self.fraction("success")

    @property
    def successes(self) -> Fraction:  # noqa: D102
        return self.success

    successes.__doc__ = success.__doc__

    def __init__(  # noqa: PLR0913
        self,
        testing_paths: Path | str | TestingPaths,
        runs: Optional[list[RunStatus]] = None,
        home_dir: Optional[Path | str] = None,
        image: Optional[str] = None,
        dry_run: bool = False,
        git_remote: Optional[GitRemoteInfo] = None,
    ) -> None:
        if isinstance(testing_paths, str):
            testing_paths = Path(testing_paths)
        if isinstance(testing_paths, Path):
            testing_paths = TestingPaths(testing_paths)
        if not isinstance(testing_paths, TestingPaths):
            msg: str = f"{testing_paths} is not an instance of {TestingPaths}"
            raise TypeError(msg)
        self.testing_paths: TestingPaths = testing_paths
        self.dry_run: bool = dry_run
        """Skip actually running commands?"""
        path: Path = testing_paths.wd / "status.🥒"
        if self.dry_run:
            path = Path(f"{path.name}.dry")
        self.path: Path = path
        """Path to status data on disk."""
        if git_remote:  # We're initializing a new TotalStatus, not loading existing one
            self._image: str = image if image is not None else ""
            """Name of image."""
            self.owner: str = git_remote.owner
            """Owner of repository on GitHub."""
            self.repo: str = git_remote.repo
            """Repository name on GitHub."""
            self.sha: str = git_remote.sha
            """SHA of the commit we're testing here."""
            self.github_token: str = git_remote.token
            """GitHub PAT."""
            self.home_dir: Path = coerce_to_Path(home_dir)
            """Home directory."""
        self.runs: dict[tuple[str, str, str], RunStatus] = {}
        """Dictionary like `{(datasource, preconfig, subject): run}` of runs with individual statuses."""
        self.load()
        initial_state: _STATE | Literal["idle"] = self.status
        if runs:
            self.runs.update({run.key: run for run in runs})
        for run in self.runs.values():
            run.total = self
        self.log()
        if self.image():
            self.write()
        if initial_state == "idle":
            if self.status != "idle" and not self.dry_run:
                self.push()
        elif self.status != "pending" and not self.dry_run:
            self.push()
            self.clean_up()
            self.correlate()
        else:
            self.check_again_later(time="now+30minutes")

    def clean_up(self) -> None:
        """Remove temporary files and image file."""
        for run in self.runs.values():
            if run._command_file:
                unlink(run._command_file)  # remove launch script
        unlink(self.image("path"))  # remove Apptainer image
        unlink(self.path)  # remove launch pickle

    @property
    def datasources(self) -> list[str]:
        """Return a list of all unique datasources in a TotalStatus."""
        return list({datasource for datasource, _, _ in self.runs.keys()})

    @property
    def preconfigs(self) -> list[str]:
        """Return a list of all unique preconfigs in a TotalStatus."""
        return list({preconfig for _, preconfig, _ in self.runs.keys()})

    @property
    def subjects(self) -> list[str]:
        """Return a list of all unique subjects in a TotalStatus."""
        return list({subject for _, _, subject in self.runs.keys()})

    @overload
    def image(self, name_or_path: Literal["name"] = "name") -> str:
        ...

    @overload
    def image(self, name_or_path: Literal["path"]) -> Path:
        ...

    def image(self, name_or_path: Literal["name", "path"] = "name") -> Path | str:
        """Return the image name or path."""
        if name_or_path == "name":
            return self._image
        return Path.cwd() / f"{self._image}.sif"

    def out(self, lite_or_full: Literal["full", "lite"]) -> Path:
        """Return the path to the output directory."""
        return self.home_dir / lite_or_full / self.image("name")

    def check_again_later(self, time: str) -> None:
        """Wait, then check the status again.

        Parameters
        ----------
        time : str
           A ``time`` for SLURM. See https://slurm.schedmd.com/sbatch.html#OPT_begin
        """
        timestamp: str = datetime.now().strftime("%F-%H-%M-%S.%f")
        cmd = [
            *SBATCH_START[:-1],
            "-t",
            "00:00:10",
            f"--output={self.testing_paths.log_dir}/check_{timestamp}.out.log",
            f"--error={self.testing_paths.log_dir}/check_{timestamp}.err.log",
            f"--begin={time}",
            "cpac-slurm-status",
            "check-all",
            f'--wd="{Path.cwd()}"',
        ]
        if self.dry_run:
            cmd = [*cmd, "--dry-run"]
        LOGGER.info(" ".join(cmd))
        subprocess.run(cmd, check=False)

    def correlate(self, n_cpus: int = 4) -> None:
        """Launch correlation process."""
        this_pipeline: Path = self.out("lite")
        latest_ref: Path = this_pipeline.parent / self.latest
        correlations_dir: str = str(this_pipeline.parent / "correlations")
        branch: str = cast(str, self.image("name"))
        for data_source in self.datasources:
            for preconfig in self.preconfigs:
                pipelines: tuple[str, str] = cast(
                    tuple[str, str],
                    tuple(
                        str(pipeline / preconfig / data_source)
                        for pipeline in [this_pipeline, latest_ref]
                    ),
                )
                run_name: str = f"{branch}_{data_source}_{preconfig}"
                if self.dry_run:
                    LOGGER.info(
                        ", ".join(
                            [
                                f"cpac_yaml(pipeline1='{pipelines[0]}'",
                                f"pipeline2='{pipelines[1]}'",
                                f"correlations_dir='{correlations_dir}'",
                                f"run_name='{run_name}'",
                                f"n_cpus='{n_cpus}'",
                                f"branch='{branch}'",
                                f"data_source='{data_source}')",
                            ]
                        )
                    )
                else:
                    regression_correlation_yaml: Path = cpac_yaml(
                        pipeline1=pipelines[0],
                        pipeline2=pipelines[1],
                        correlations_dir=correlations_dir,
                        run_name=run_name,
                        n_cpus=n_cpus,
                        branch=branch,
                        data_source=data_source,
                    )
                    correlate(
                        correlations_dir,
                        CpacCorrelationsNamespace(
                            branch=branch,
                            data_source=data_source,
                            input_yaml=str(regression_correlation_yaml),
                        ),
                    )
        init_repo(
            correlations_dir=correlations_dir,
            branch_name=f"{self.repo}_{branch}",
            owner=self.owner,
            github_token=self.github_token,
        )

    @property
    def _denominator(self) -> int:
        """Return the number of runs."""
        return len(self.runs.values())

    @property
    def description(self) -> str:
        """Return the description of the status."""
        fractions: list[int] = [
            int(fraction * self._denominator)
            for fraction in [self.success, self.failure, self.pending]
        ]
        return (
            f"{fractions[0]} successful, {fractions[1]} failed, {fractions[2]} pending"
        )

    def fraction(self, status: _STATE) -> Fraction:
        """Return the fraction of runs that are successful."""
        try:
            return Fraction(
                sum(run.job_status == status for run in self.runs.values()),
                self._denominator,
            )
        except ZeroDivisionError:
            msg = "No runs have been logged as started."
            raise ProcessLookupError(msg)

    @property
    def github_repo(self) -> Repository:
        """Get a Github.repo for C-PAC."""
        if not hasattr(self, "_github_repo"):
            github_client: Github = Github(self.github_token)
            self._github_repo: Repository = github_client.get_repo(
                f"{self.owner}/{self.repo}"
            )
        return self._github_repo

    @property
    def latest(self) -> str:
        """Return the latest C-PAC ref."""
        return self.github_repo.get_latest_release().tag_name

    def load(self) -> "TotalStatus":
        """Load status from disk, replacing current status.

        If no status on disk (at ``self.path``), keep current status.
        """
        if self.path.exists():
            with self.path.open("rb") as _f:
                status: "TotalStatus" = pickle.load(_f)
                for attr in [
                    "dry_run",
                    "github_token",
                    "home_dir",
                    "_image",
                    "owner",
                    "path",
                    "repo",
                    "sha",
                    "testing_paths",
                ]:
                    setattr(self, attr, getattr(status, attr))
                if self.runs:
                    for run in self.runs.values():
                        status += run
                self.runs = status.runs
        return self

    def log(self) -> None:
        """Log current total status."""
        LOGGER.info("%s", indented_lines(str(self)))

    @property
    def pending(self) -> Fraction:
        """Return the fraction of runs that are pending."""
        return self.fraction("pending")

    def push(self) -> None:
        """Push the status to GitHub."""
        repo: Repository = self.github_repo
        commit: Commit = repo.get_commit(sha=self.sha)
        target_url: str = (
            f"https://github.com/{self.owner}/regtest-runlogs/tree"
            f"/{self.repo}_{self.sha}/launch"
        )
        commit.create_status(
            state=self.status,
            target_url=target_url,
            description=self.description,
            context="lite regression test",
        )

    @property
    def status(self) -> Union[_STATE, Literal["idle"]]:
        """Return the status."""
        if len(self) == 0:
            return "idle"
        if self.pending:
            return "pending"
        if self.success > self.failure:
            return "success"
        return "failure"

    def write(self) -> None:
        """Write current status to disk."""
        with self.path.open("wb") as _f:
            flock(_f.fileno(), LOCK_EX)  # Lock the file
            pickle.dump(self, _f)  # Write the file
            flock(_f.fileno(), LOCK_UN)  # Unlock the file

    def __getitem__(self, item: tuple[str, str, str]) -> RunStatus:
        """Get a run by `(data_source, pipeline, subject)`."""
        return self.runs[item]

    def __len__(self):
        """Return the number of runs included in this status."""
        return len(self.runs)

    def __add__(self, other: RunStatus) -> "TotalStatus":
        """Add a run to the total status."""
        runs: dict[tuple[str, str, str], RunStatus] = self.runs.copy()
        runs.update({other.key: other})
        return TotalStatus(
            testing_paths=self.testing_paths,
            runs=list(runs.values()),
            image=self._image,
            dry_run=self.dry_run,
        )

    def __iadd__(self, other: RunStatus) -> "TotalStatus":
        """Add a run to the total status."""
        self.runs.update({other.key: other})
        self.write()
        return self

    def __repr__(self) -> str:
        """Return reproducible string for TotalStatus."""
        image_info = (f", image='{self.image('name')}'") if self._image else ""
        return (
            f"TotalStatus(testing_paths={self.testing_paths!r}, runs={self.runs}"
            f"{image_info}, dry_run={self.dry_run})"
        )

    def __str__(self) -> str:
        """Return string representation of TotalStatus."""
        image_info: list[str] = [f"{self.image('name')}"] if self._image else []
        return "\n".join(
            [
                *image_info,
                *[
                    f"{key} ({value.job_id}): {value.status}"
                    for key, value in self.runs.items()
                ],
            ]
        )

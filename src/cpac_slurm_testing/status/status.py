#!/usr/bin/env python
# -*- coding: utf-8 -*-
# SBATCH -N 1
# SBATCH -p RM-shared
# SBATCH -t 00:05:00
# SBATCH --ntasks-per-node=4
"""Consolidate job statistics into a single GitHub status.

Requires the following environment variables:
- GITHUB_TOKEN: A GitHub token with access to the repository.
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
from fcntl import flock, LOCK_EX, LOCK_UN
from fractions import Fraction
from importlib.resources import files
from logging import basicConfig, getLogger, INFO
import os
from pathlib import Path
import pickle
from random import choice, randint
import subprocess
from tempfile import NamedTemporaryFile
from typing import Iterable, Literal, Optional, overload, Union

from github import Github
from cpac_regression_dashboard.utils.parse_yaml import cpac_yaml

from cpac_slurm_testing.status._global import (
    _COMMAND_TYPES,
    _JOB_STATE,
    _STATE,
    JOB_STATES,
    LOG_FORMAT,
    TEMPLATES,
)

LOGGER = getLogger(name=__name__)
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
    _parts = str(directory).split("/")
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
    filename = "status.log"
    if wd is None:
        wd = os.environ.get("REGTEST_LOG_DIR")
    if not wd:
        _log = (
            LOGGER.warning,
            ["`wd` was not provided and `$REGTEST_LOG_DIR` is not set."],
        )
    if wd:
        wd = _set_intermediate_directory(Path(wd).absolute(), "lite")
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
    _log = LOGGER.info, ["Set working directory to %s", str(wd)]
    _logpath = _set_intermediate_directory(wd, "logs")
    filename = f"{_logpath}/{filename}"
    basicConfig(
        filename=filename,
        encoding="utf8",
        force=True,
        format=LOG_FORMAT,
        level=INFO,
    )
    _log[0](*_log[1])  # log info or warning as appropriate
    return Path(wd), Path(_logpath)


class TestingPaths:
    """Working and logging path management."""

    def __init__(self, wd: Optional[Path] = None) -> None:
        """Initialize TestingPaths."""
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
        _parts = str(self.log_dir).rsplit("/logs/", 1)
        return "/l(ite|ogs)/".join(_parts)


def get_latest() -> str:
    """Get the latest C-PAC ref."""
    return ""  # TODO


def indented_lines(lines: str) -> str:
    """Return a multiline string with each line indented one tab."""
    _lines = lines.split("\n")
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
        self.dry_run = dry_run

    @overload
    def get(
        self, key: Literal["JobState"], default: _JOB_STATE = "PENDING"
    ) -> _JOB_STATE:
        ...

    @overload
    def get(self, key: str, default: Optional[str] = None) -> Optional[str]:
        ...

    def get(self, key, default):
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

    def __getitem__(self, item):
        """Return an item from the scontrol output."""
        return self._scontrol_dict.get(item)

    def __eq__(self, other) -> bool:
        """Return True if SLURM job status dictionaries are equal, else False."""
        if not isinstance(other, SlurmJobStatus):
            return False
        return self._scontrol_dict == other._scontrol_dict

    def __repr__(self) -> str:
        """Return reproducible string represntation of SLURM job status."""
        _str = " ".join(
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
    data_source: str
    preconfig: str
    subject: str
    status: _STATE = "pending"
    job_id: Optional[int] = None
    _slurm_job_status: Optional[SlurmJobStatus] = None
    _total: Optional["TotalStatus"] = None
    dry_run: bool = False

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
        self.pdsd = f"{self.preconfig}-{self.data_source}-{self.subject}"
        """preconfig-data_source-subject"""
        self.wd = self.testing_paths.wd / f"slurm-{self.pdsd}"
        """working directory"""
        self.log_dir = self.testing_paths.log_dir / f"slurm-{self.pdsd}"
        """log directory"""

    def command(self, command_type: str) -> str:
        """Return a command string for a given command_type."""
        assert self._total is not None
        return TEMPLATES[command_type].format(
            datapath=self.total.home_dir / f"DATA/reg_5mm_pack/data/{self.data_source}",
            home_dir=self.total.home_dir,
            log_dir=self.log_dir,
            image=self.total.image("path"),
            image_name=self.total.image("name"),
            output=self.out("lite") / self.data_source,
            pdsd=self.pdsd,
            pipeline=self.preconfig,
            pipeline_configs=str(
                files("cpac_slurm_testing.pipeline_configs").joinpath("")
            ),
            subject=self.subject,
        )

    @property
    def key(self) -> tuple[str, str, str]:
        """Return a unique key for each preconfig × data_source × subject."""  # noqa: RUF002
        return self.data_source, self.preconfig, self.subject

    def launch(self, command_type: _COMMAND_TYPES) -> None:
        """Launch a SLURM job and set its job ID."""
        _command_types = eval(
            str(_COMMAND_TYPES).replace(
                str(
                    _COMMAND_TYPES.__origin__  # type: ignore[attr-defined]
                ),
                "",
            )
        )
        if command_type not in _command_types:
            msg = f"{command_type} not in {_command_types}"
            raise KeyError(msg)
        with NamedTemporaryFile(mode="w", encoding="utf8", delete=False) as _f:
            _f.write(self.command(command_type))
            _f.close()
            with open(_f.name, "r", encoding="utf8") as _command_file:
                LOGGER.info(
                    "%s:\n\n\t%s", _f.name, indented_lines(_command_file.read())
                )
            command = ["sbatch", "--parsable", _f.name]
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
            f"{self.status}, _total={self.total}, dry_run={self.dry_run})"
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
    ) -> None:
        if isinstance(testing_paths, str):
            testing_paths = Path(testing_paths)
        if isinstance(testing_paths, Path):
            testing_paths = TestingPaths(testing_paths)
        if not isinstance(testing_paths, TestingPaths):
            msg = f"{testing_paths} is not an instance of {TestingPaths}"
            raise TypeError(msg)
        self.testing_paths = testing_paths
        self.dry_run: bool = dry_run
        """Skip actually running commands?"""
        path = testing_paths.wd / "status.🥒"
        if self.dry_run:
            path = Path(f"{path.name}.dry")
        self.path = path
        """Path to status data on disk."""
        self._image: str = image if image is not None else ""
        """Name of image."""
        self.runs: dict[tuple[str, str, str], RunStatus] = {}
        """Dictionary of runs with individual statuses."""
        self.load()
        initial_state = self.status
        if home_dir:
            self.home_dir = Path(home_dir)
        if runs:
            self.runs.update({run.key: run for run in runs})
        for run in self.runs.values():
            run.total = self
            run.launch("lite_run")
        self.log()
        if self.image():
            self.write()
        if initial_state == "idle":
            if self.status != "idle" and not self.dry_run:
                self.push()
        elif self.status != "pending" and not self.dry_run:
            self.push()
            self.correlate()
        else:
            self.check_again_later(time="now+30minutes")

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
        cmd = [
            "sbatch",
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
        this_pipeline = self.out("lite")
        latest_ref = this_pipeline.parent / get_latest()
        for data_source in self.runs:
            if self.dry_run:
                LOGGER.info(
                    ", ".join(
                        [
                            f"cpac_yaml(pipeline1={this_pipeline})",
                            "pipeline2={latest_ref}",
                            f"correlations_dir={this_pipeline.parent / 'correlations'}",
                            f"run_name={os.environ['SHA']}",
                            f"n_cpus={n_cpus}",
                            f"branch={os.environ['SHA']}",
                            f"data_source={data_source})",
                        ]
                    )
                )
            else:
                cpac_yaml(
                    pipeline1=str(this_pipeline),
                    pipeline2=str(latest_ref),
                    correlations_dir=str(this_pipeline.parent / "correlations"),
                    run_name=os.environ["SHA"],
                    n_cpus=n_cpus,
                    branch=os.environ["SHA"],
                    data_source=data_source,
                )
        pass  # TODO

    @property
    def _denominator(self) -> int:
        """Return the number of runs."""
        return len(self.runs.values())

    @property
    def description(self) -> str:
        """Return the description of the status."""
        return (
            f"{self.success} successful, {self.failures} failed, {self.pending} pending"
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

    def load(self) -> "TotalStatus":
        """Load status from disk, replacing current status.

        If no status on disk (at ``self.path``), keep current status.
        """
        if self.path.exists():
            with self.path.open("rb") as _f:
                status: "TotalStatus" = pickle.load(_f)
                self.home_dir = status.home_dir
                if self.runs:
                    for run in self.runs.values():
                        status += run
                self.runs = status.runs
                self._image = status._image
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
        github_client = Github(os.environ["GITHUB_TOKEN"])
        repo = github_client.get_repo(f"{os.environ['OWNER']}/{os.environ['REPO']}")
        commit = repo.get_commit(sha=os.environ["SHA"])
        target_url = (
            f"https://github.com/{os.environ['OWNER']}/regtest-runlogs/tree"
            f"/{os.environ['REPO']}_{os.environ['SHA']}/launch"
        )
        commit.create_status(
            status=self.status,
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
        runs = self.runs.copy()
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
        return self

    def __repr__(self) -> str:
        """Return reproducible string for TotalStatus."""
        image_info = (f", image='{self.image('name')}'") if self._image else ""
        return (
            f"TotalStatus(testing_paths={self.testing_paths!r}, runs={self.runs}"
            f"{image_info}, dry_run={self.dry_run}"
        )

    def __str__(self) -> str:
        """Return string representation of TotalStatus."""
        image_info = [f"{self.image('name')}"] if self._image else []
        return "\n".join(
            [
                *image_info,
                *[
                    f"{key} ({value.job_id}): {value.status}"
                    for key, value in self.runs.items()
                ],
            ]
        )

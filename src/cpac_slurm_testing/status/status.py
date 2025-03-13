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
from argparse import Namespace
from dataclasses import dataclass
from datetime import datetime
from fcntl import flock, LOCK_EX, LOCK_UN
from fractions import Fraction
from importlib.resources import files
from logging import Logger
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

from cpac_slurm_testing.correlation.correlation import correlate, init_branch
from cpac_slurm_testing.git_remote import GitRemoteInfo
from cpac_slurm_testing.status._global import (
    _State,
    get_logger,
    JOB_STATES,
    JobState,
    SBATCH_START,
    TEMPLATES,
)
from cpac_slurm_testing.utils import coerce_to_Path, ExistingPath, unlink
from cpac_slurm_testing.utils._typing import Scope
from cpac_slurm_testing.utils.datapaths import datapaths

LOGGER: Logger = get_logger(name=__name__)


@dataclass
class CpacImage:
    """Consistently access C-PAC image name and path."""

    name: str
    home_dir: Path

    def __bool__(self) -> bool:
        """Is the C-PAC image defined?"""  # noqa: D400
        return bool(self.name)

    def __str__(self) -> str:
        """Return string representation of C-PAC image."""
        return self.name

    @property
    def path(self) -> Path:
        """Path to image."""
        if self:
            image_dir = ExistingPath(
                self.home_dir / "automatic_tests" / "images" / self.name
            )
            return image_dir / f"{self.name}.sif"
        msg = "C-PAC image not defined."
        raise FileNotFoundError(msg)


def _set_working_directory(
    scope: Scope, wd: Optional[Path | str] = None
) -> tuple[Path, Path]:
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
        LOGGER: Logger = get_logger(name=__name__)
        _logger = LOGGER.warning
        _log_msg = ["`wd` was not provided and `$REGTEST_LOG_DIR` is not set."]
    if wd:
        wd = coerce_to_Path(wd).absolute()
    else:
        from datetime import datetime
        from time import localtime, strftime

        wd = (
            Path.cwd().absolute()
            / scope
            / "".join(
                [
                    datetime.now().strftime("%Y%m%d%H%M%S.%f%Z"),
                    strftime("%Z", localtime()),
                ]
            )
        )
    wd = ExistingPath(wd)
    os.chdir(str(wd))
    _log_msg = ["Set working directory to %s", str(wd)]
    _logpath = ExistingPath(wd / "logs")
    LOGGER = get_logger(name=__name__, filename=f"{_logpath}/{filename}", force=True)
    _logger = LOGGER.info
    _logger(*_log_msg)  # log info or warning as appropriate
    return wd, _logpath


class TestingPaths:
    """Working and logging path management."""

    def __init__(self, scope: Scope = "lite", wd: Optional[Path | str] = None) -> None:
        """Initialize TestingPaths."""
        self._log_dir: Path
        self._wd: Path
        self._wd, self._log_dir = _set_working_directory(scope, wd)
        self.scope = scope

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
        return f"TestingPaths('{self.scope}', Path('{self.wd}'))"

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
    def get(self, key: Literal["JobState"], default: JobState = "PENDING") -> JobState:
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
    def job_state(self) -> JobState:
        """Return JobState from SLURM."""
        if self.dry_run:
            return choice(list(JOB_STATES.keys()))
        return self["JobState"]

    @overload
    def __getitem__(self, item: Literal["JobState"]) -> JobState:
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
    status: _State = "pending"
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
            job_state = self._slurm_job_status.job_state
            try:
                self.status = JOB_STATES[job_state]
            except KeyError:
                LOGGER.error("Unknown job state '%s'", job_state)

    def __post_init__(self) -> None:
        """Set some determinable attributes after initializing."""
        self.pdsd: str = f"{self.preconfig}-{self.data_source}-{self.subject}"
        """preconfig-data_source-subject"""
        self.wd: Path = self.testing_paths.wd / f"slurm-{self.pdsd}"
        """working directory"""
        self.log_dir: Path = self.testing_paths.log_dir / f"slurm-{self.pdsd}"
        """log directory"""
        self._total += self

    def command(self, scope: Scope = "lite") -> str:
        """Return a command string for a given scope."""
        assert self._total is not None
        if not self.log_dir.exists():
            self.log_dir.mkdir(mode=0o777, exist_ok=True)
        return TEMPLATES[scope].format(
            datapath=getattr(datapaths[scope](self.total.home_dir), self.data_source),
            regdatapath=datapaths[scope](self.total.home_dir).regdatapath,
            home_dir=self.total.home_dir,
            log_dir=self.log_dir,
            image=self.total.image.path,
            image_name=self.total.image.name,
            output=ExistingPath(self.out() / self.preconfig / self.data_source),
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

    def launch(self, scope: Scope) -> None:
        """Launch a SLURM job and set its job ID."""
        with NamedTemporaryFile(mode="w", encoding="utf8", delete=False) as _f:
            self._command_file = Path(_f.name)
            _f.write(self.command(scope))
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

    def out(self) -> Path:
        """Return the path to the output directory."""
        return self.total.out()

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

    def _cpac_image(self, name: str) -> CpacImage:
        """Create a C-PAC Image."""
        if name:
            return CpacImage(name, self.home_dir)
        return CpacImage(name, Path())

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

    def __init__(  # noqa: PLR0913,PLR0915
        self,
        testing_paths: Path | str | TestingPaths,
        scope: Scope = "lite",
        runs: Optional[list[RunStatus]] = None,
        home_dir: Optional[Path | str] = None,
        image: Optional[str] = None,
        dry_run: bool = False,
        git_remote: Optional[GitRemoteInfo] = None,
    ) -> None:
        if isinstance(testing_paths, str):
            testing_paths = Path(testing_paths)
        if isinstance(testing_paths, Path):
            testing_paths = TestingPaths(scope=scope, wd=testing_paths)
        if not isinstance(testing_paths, TestingPaths):
            msg: str = f"{testing_paths} is not an instance of {TestingPaths}"
            raise TypeError(msg)
        self.scope: Scope = scope
        self.testing_paths: TestingPaths = testing_paths
        self.dry_run: bool = dry_run
        """Skip actually running commands?"""
        path: Path = testing_paths.wd / "status.🥒"
        if self.dry_run:
            path = Path(f"{path.name}.dry")
        self.path: Path = path
        """Path to status data on disk."""
        self.image: CpacImage = self._cpac_image("")
        """C-PAC image."""

        if git_remote:  # We're initializing a new TotalStatus, not loading existing one
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
            self.image = (
                self._cpac_image(image) if image is not None else self._cpac_image("")
            )
            """C-PAC image."""
        self.runs: dict[tuple[str, str, str], RunStatus] = {}
        """Dictionary like `{(datasource, preconfig, subject): run}` of runs with individual statuses."""
        self.load()
        initial_state: _State | Literal["idle"] = self.status
        if runs:
            self.check_all()
            self.runs.update({run.key: run for run in runs})
        for run in self.runs.values():
            run.total = self
        self.log()
        if self.image:
            self.write()
        if initial_state == "idle":
            if self.status != "idle" and not self.dry_run:
                self.push()
        elif self.status != "pending" and not self.dry_run:
            self.push()
            self.clean_up()
            os.environ.setdefault(
                "PLAYWRIGHT_BROWSERS_PATH", str(self.home_dir / ".playwright_browsers")
            )
            self.correlate()
        else:
            self.check_again_later(
                time=f"now+{30 * self.pending * self._denominator}minutes"
            )

    def clean_up(self) -> None:
        """Remove temporary files and image file."""
        for run in self.runs.values():
            if run._command_file:
                unlink(run._command_file)  # remove launch script
        unlink(self.image.path)  # remove Apptainer image
        # unlink(self.path)  # remove launch pickle

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

    def out(self) -> Path:
        """Return the path to the output directory."""
        return ExistingPath(self.home_dir / self.scope / self.image.name)

    def check(self: "TotalStatus", args: Namespace) -> None:
        """Check a run's status."""
        self[
            (
                args.data_source,
                args.preconfig,
                args.subject,
            )
        ].job_status
        LOGGER.info(self)

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
            self.scope,
            "check-all",
            f'--wd="{Path.cwd()}"',
        ]
        if self.dry_run:
            cmd = [*cmd, "--dry-run"]
        LOGGER.info(" ".join(cmd))
        subprocess.run(cmd, check=False)

    def check_all(self: "TotalStatus") -> None:
        """Check all runs' statuses."""
        for run in self.runs.values():
            run.job_status
        LOGGER.info(self)

    def correlate(self, n_cpus: int = 4) -> None:
        """Launch correlation process."""
        this_pipeline: Path = self.out()
        latest_ref: Path = this_pipeline.parent / self.latest
        correlations_dir: Path | str = this_pipeline / "correlations"
        assert isinstance(correlations_dir, Path)
        if not correlations_dir.exists():
            correlations_dir.mkdir(mode=0o777, exist_ok=True)
        correlations_dir = str(correlations_dir)
        branch: str = self.image.name
        correlation_slurm_jobs: list[int] = []
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
                    try:
                        regression_correlation_yaml: Path = cpac_yaml(
                            pipeline1=pipelines[0],
                            pipeline2=pipelines[1],
                            correlations_dir=correlations_dir,
                            run_name=run_name,
                            n_cpus=n_cpus,
                            branch=branch,
                            data_source=data_source,
                        )
                    except AssertionError:
                        continue
                    correlation_slurm_jobs.append(
                        correlate(
                            CpacCorrelationsNamespace(
                                branch=branch,
                                data_source=data_source,
                                input_yaml=str(regression_correlation_yaml),
                            ),
                        )
                    )
        branch_name: str = f"{self.repo}_{branch}"
        init_branch(
            correlations_dir=correlations_dir,
            branch_name=branch_name,
            owner=self.owner,
            github_token=self.github_token,
        )
        push_command: list[str] = [
            *SBATCH_START[:-1],
            f"--dependency=afterany:{':'.join(str(job_id) for job_id in correlation_slurm_jobs)}",
            f"--export=GITHUB_TOKEN={self.github_token}",
            "cpac-slurm-push-branch",
            f"--correlations_dir={correlations_dir}",
            f"--branch_name={branch_name}",
        ]
        subprocess.run(
            push_command, check=False
        )  # push to GitHub on completion of all correlations

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

    def fraction(self, status: _State) -> Fraction:
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
                    "image",
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
            context=f"{self.scope} regression test",
        )

    @property
    def status(self) -> Union[_State, Literal["idle"]]:
        """Return the status."""
        if len(self) == 0:
            return "idle"
        if self.pending:
            return "pending"
        if self.success > self.failure:
            return "success"
        return "failure"

    def update(self: "TotalStatus", args: Namespace) -> None:
        """Update a run in a TotalStatus."""
        run = RunStatus(
            testing_paths=self.testing_paths,
            data_source=args.data_source,
            preconfig=args.preconfig,
            subject=args.subject,
            status=getattr(args, "status", "pending"),
            _total=self,
        )
        run.launch(args.scope)
        self += run

    def write(self) -> None:
        """Write current status to disk."""
        with self.path.open("wb") as _f:
            try:
                flock(_f.fileno(), LOCK_EX)  # Lock the file
                pickle.dump(self, _f)  # Write the file
            finally:
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
            scope=self.scope,
            runs=list(runs.values()),
            image=self.image.name,
            dry_run=self.dry_run,
        )

    def __iadd__(self, other: RunStatus) -> "TotalStatus":
        """Add a run to the total status."""
        self.runs.update({other.key: other})
        self.write()
        return self

    def __repr__(self) -> str:
        """Return reproducible string for TotalStatus."""
        image_info = (f", image='{self.image.name}'") if self.image else ""
        return (
            f"TotalStatus(testing_paths={self.testing_paths!r}, scope={self.scope}, runs={self.runs}"
            f"{image_info}, dry_run={self.dry_run})"
        )

    def __str__(self) -> str:
        """Return string representation of TotalStatus."""
        image_info: list[str] = [f"{self.image.name}"] if self.image else []
        return "\n".join(
            [
                *image_info,
                *[
                    f"{key} ({value.job_id}): {value.status}"
                    for key, value in self.runs.items()
                ],
            ]
        )

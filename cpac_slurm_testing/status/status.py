#!/usr/bin/env python
# -*- coding: utf-8 -*-
# SBATCH -N 1
# SBATCH -p RM-shared
# SBATCH -t 00:05:00
# SBATCH --ntasks-per-node=4
"""Consolidate job statistics into a single GitHub status.

Requires the following environment variables:
- GITHUB_TOKEN: A GitHub token with access to the repository.
- HOME_DIR: Path to the home directory that contains the .apptainer directory for caching
- OWNER: The owner of the repository.
- REPO: The repository.
- SHA: The commit SHA.

Also optionally accepts the following environment variables (or these can be passed as commandline arguments):
- _CPAC_STATUS_DATA_SOURCE: The data source.
- _CPAC_STATUS_PRECONFIG: The preconfig.
- _CPAC_STATUS_SUBJECT: The subject.
- _CPAC_STATUS_STATE: The status of the run. Defaults to "pending".
"""
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
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
from typing import Literal, Optional, overload, Union

from github import Github

from cpac_slurm_testing.status import _global
from cpac_slurm_testing.status._global import (
    _COMMAND_TYPES,
    _JOB_STATE,
    _STATE,
    HOME_DIR,
    JOB_STATES,
    LOG_FORMAT,
    PATHSTR,
    TEMPLATES,
)

LOGGER = getLogger(name=__name__)
basicConfig(format=LOG_FORMAT, level=INFO)


def indented_lines(lines: str) -> str:
    """Return a multiline string with each line indented one tab."""
    _lines = lines.split("\n")
    return "\n".join([_lines[0], *[f"\t{line}" for line in _lines[1:]]]).rstrip()


class SlurmJobStatus:
    """Store a SLURM job status."""

    def __init__(self, scontrol_output: str):
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
        if _global.DRY_RUN:
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
        return f"SlurmJobStatus('{_str}')"

    def __str__(self) -> str:
        """Return string representation of SLURM job status."""
        return f"{self.get('JobId')} ({self.get('Command')}): {self.get('JobState')}"


@dataclass
class RunStatus:
    """Store the status of a run for the GitHub Check."""

    data_source: str
    preconfig: str
    subject: str
    status: _STATE = "pending"
    image: str = "image"
    image_name: str = "image_name"
    job_id: Optional[int] = None
    _slurm_job_status: Optional[SlurmJobStatus] = None

    def check_slurm(self) -> None:
        """Check SLURM job status."""
        if _global.DRY_RUN:
            if self.job_id:
                self._slurm_job_status = SlurmJobStatus(f"JobId={self.job_id}")
        else:
            try:
                self._slurm_job_status = SlurmJobStatus(
                    subprocess.run(
                        ["scontrol", "show", "job", str(self.job_id)],
                        capture_output=True,
                        check=True,
                    ).stdout.decode()
                )
            except subprocess.CalledProcessError:
                self.status = "error"
        if self.status != "error" and self._slurm_job_status:
            self.status = JOB_STATES[self._slurm_job_status.job_state]

    def command(self, command_type: str) -> str:
        """Return a command string for a given command_type."""
        pdsd = f"{self.preconfig}-{self.data_source}-{self.subject}"
        wd = Path.cwd() / f"slurm-{pdsd}"
        LOGGER.info("mkdir %s", wd)
        wd.mkdir(parents=True, exist_ok=True)
        return TEMPLATES[command_type].format(
            datapath=HOME_DIR / f"DATA/reg_5mm_pack/data/{self.data_source}",
            home_dir=HOME_DIR,
            image=self.image,
            image_name=self.image_name,
            output=self.out("lite") / self.data_source,
            pdsd=pdsd,
            pipeline=self.preconfig,
            pipeline_configs=str(
                files("cpac_slurm_testing.pipeline_configs").joinpath("")
            ),
            subject=self.subject,
            wd=Path.cwd(),
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
            LOGGER.info(" ".join(command))
            if _global.DRY_RUN:
                LOGGER.info("Dry run.")
                self.job_id = randint(1, 99999999)
            else:
                self.job_id = int(
                    subprocess.run(command, capture_output=True, check=False)
                    .stdout.decode()
                    .split(" ")[0]
                )

    def out(self, lite_or_full: Literal["full", "lite"]) -> Path:
        """Return the path to the output directory."""
        return HOME_DIR / lite_or_full / self.image_name

    @property
    def job_status(self) -> str:
        """Return the job's status per the SLURM job status."""
        if self.status == "pending":
            self.check_slurm()
        return self.status

    def __repr__(self) -> str:
        """Return reproducible string representation of the status."""
        return (
            f"RunStatus({self.data_source}, {self.preconfig}, {self.subject}, "
            f"{self.status})"
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

    def __init__(
        self,
        runs: Optional[list[RunStatus]] = None,
        path: Path = Path.cwd() / "status.🥒",
    ) -> None:
        if _global.DRY_RUN:
            path = Path(f"{path.name}.dry")
        self.path = Path(path)
        """Path to status data on disk."""
        _runs = {} if runs is None else {run.key: run for run in runs}
        for run in _runs.values():
            run.launch("lite_run")
        self.runs: dict[tuple[str, str, str], RunStatus] = {}
        """Dictionary of runs with individual statuses."""
        self.load()
        initial_state = self.status
        self.runs.update(_runs)
        self.log()
        self.write()
        if initial_state == "idle":
            if self.status != "idle" and not _global.DRY_RUN:
                self.push()

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
            with self.path.open("rb") as _pickle:
                self.__dict__.update(pickle.load(_pickle).__dict__)
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
        """Return the status of the status."""
        if len(self) == 0:
            return "idle"
        if self.pending:
            return "pending"
        if self.success > self.failure:
            return "success"
        return "failure"

    def write(self) -> None:
        """Write current status to disk."""
        with self.path.open("wb") as _pickle:
            flock(_pickle.fileno(), LOCK_EX)  # Lock the file
            pickle.dump(self, _pickle)  # Write the pickle
            flock(_pickle.fileno(), LOCK_UN)  # Unlock the file

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
        return TotalStatus(runs=list(runs.values()), path=self.path)

    def __iadd__(self, other: RunStatus) -> "TotalStatus":
        """Add a run to the total status."""
        self.runs.update({other.key: other})
        return self

    def __repr__(self):
        """Return reproducible string for TotalStatus."""
        return f"TotalStatus({self.runs}, path='{self.path}')"

    def __str__(self):
        """Return string representation of TotalStatus."""
        return "\n".join([f"{key}: {value.status}" for key, value in self.runs.items()])


def set_working_directory(wd: Optional[PATHSTR] = None) -> None:
    """Set working directory.

    Priority order:
    1. `wd` if `wd` is given.
    2. `$REGTEST_LOG_DIR` if such environment variable is defined.
    3. Do nothing.
    """
    if wd is None:
        wd = os.environ.get("REGTEST_LOG_DIR")
    if not wd:
        _log = (
            LOGGER.warning,
            ["`wd` was not provided and `$REGTEST_LOG_DIR` is not set."],
        )
    if wd:
        wd = str(wd)
        os.chdir(wd)
        _log = LOGGER.info, ["Set working directory to %s", wd]
    basicConfig(
        filename="status.log",
        encoding="utf8",
        force=True,
        format=LOG_FORMAT,
        level=INFO,
    )
    _log[0](*_log[1])  # log info or warning as appropriate


def _env_varname(arg: str) -> str:
    """Return an environment argument name given a CLI argument name."""
    return f"_CPAC_STATUS_{arg.upper().replace('-', '_')}"


class NamespaceWithEnvFallback(Namespace):
    """Namespace, but with additional ``_env_fallback`` method."""

    def __init__(self, original: Namespace):
        self.__dict__.update(original.__dict__)

    def _env_fallback(self: Namespace, arg: str) -> str:
        """Get an argument value from ENV if not passed as an argument."""
        try:
            value = getattr(self, arg)
        except AttributeError:
            value = None
        if value is None:
            env_var = _env_varname(arg)
            try:
                return os.environ[env_var]
            except LookupError:
                msg = (
                    f"'{arg}' was not provided. Either set '--{arg}' in the run command"
                    f" or ${env_var} in the environment."
                )
                raise LookupError(msg)
        return value


def _parser_arg_helpstring(arg: str) -> str:
    """Return a string describing the optional environment variable."""
    return f"falls back on ${_env_varname(arg)} if this option is not set"

    # if (
    #     status.status != "pending"
    # ):  # Remove the pickle if the status is no longer pending
    #     status_pickle.unlink(missing_ok=True)


def _parser() -> tuple[ArgumentParser, dict[str, ArgumentParser]]:
    """Create a parser to parse commandline args."""
    parser = ArgumentParser(
        prog="status", description=__doc__, formatter_class=RawDescriptionHelpFormatter
    )
    base_parser = ArgumentParser(add_help=False)
    base_parser.add_argument(
        "--working_directory",
        "--workdir",
        "--wd",
        dest="wd",
        help="specify working directory. falls back on $REGTEST_LOG_DIR if not "
        "provided, and uses the actual current working directory if that environment "
        "variable is not set",
    )
    base_parser.add_argument(
        "--dry-run", action="store_true", help="If set, jobs will not be run."
    )
    update_parser = ArgumentParser(add_help=False)
    for arg in ["data-source", "preconfig", "subject"]:
        argstrings = list({f"--{argstr}" for argstr in [arg, arg.replace("-", "_")]})
        update_parser.add_argument(*argstrings, help=_parser_arg_helpstring(arg))
    subparsers = parser.add_subparsers(dest="command")
    for command, description in {
        "add": "add a run in a pending status",
        "check": "check a run's status in SLURM",
        "finalize": "finalize a run (success, failure or error)",
    }.items():
        subparsers.add_parser(
            command,
            description=description,
            help=description,
            parents=[base_parser, update_parser],
        )
    subparsers.choices["add"].set_defaults(status="pending")
    subparsers.choices["finalize"].add_argument(
        "--status",
        choices=["success", "failure", "error"],
        help=_parser_arg_helpstring("status"),
    )

    return parser, subparsers.choices


def main() -> None:
    """Run the script from the commandline."""
    set_working_directory()
    # Parse the arguments
    parser, _subparsers = _parser()
    args = parser.parse_args()
    args = NamespaceWithEnvFallback(args)
    if args.dry_run:
        _global.DRY_RUN = True
    # Update the status
    if args.command in ["add", "finalize"]:
        TotalStatus(
            [
                RunStatus(
                    args.data_source,
                    args.preconfig,
                    args.subject,
                    getattr(args, "status"),
                )
            ]
        )
    elif args.command == "check":
        status = TotalStatus()
        status[
            (
                args.data_source,
                args.preconfig,
                args.subject,
            )
        ].job_status
        LOGGER.info(status)


if __name__ == "__main__":
    main()

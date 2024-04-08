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
- _CPAC_STATUS_STATE: The state of the run. Defaults to "pending".
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
from typing import Literal, Optional, Union

from github import Github

HOME_DIR = Path(os.environ.get("HOME_DIR", os.path.expanduser("~")))
LOG_FORMAT = "%(asctime)s: %(levelname)s: %(pathname)s: %(funcName)s: %(message)s"
LOGGER = getLogger(name=__name__)
PATHSTR = Union[Path, str]
_STATE = Literal["error", "failure", "pending", "success"]
TEMPLATES = {
    key: files("cpac_slurm_testing.templates").joinpath(f"{key}.ftxt").read_text()
    for key in ["lite_run"]
}
basicConfig(format=LOG_FORMAT, level=INFO)


@dataclass
class RunStatus:
    """A dataclass for storing the status of a run for the GitHub Check."""

    data_source: str
    preconfig: str
    subject: str
    state: _STATE = "pending"
    image: str = "image"
    image_name: str = "image_name"

    def command(self, command_type: str) -> str:
        """Return a command string for a given command_type."""
        return TEMPLATES[command_type].format(
            datapath=HOME_DIR / f"DATA/reg_5mm_pack/data/{self.data_source}",
            home_dir=HOME_DIR,
            image=self.image,
            image_name=self.image_name,
            output=self.out("lite") / self.data_source,
            pdsd=f"{self.preconfig}-{self.data_source}-{self.subject}",
            pipeline={self.preconfig},
            pipeline_configs=str(files("pipeline_configs").joinpath("")),
            subject={self.subject},
            wd=Path.cwd(),
        )

    def out(self, lite_or_full: Literal["full", "lite"]) -> Path:
        """Return the path to the output directory."""
        return HOME_DIR / lite_or_full / self.image_name

    @property
    def key(self) -> tuple[str, str, str]:
        """Return a unique key for each preconfig × data_source × subject."""  # noqa: RUF002
        return self.data_source, self.preconfig, self.subject

    def __repr__(self) -> str:
        """Return reproducible string representation of the status."""
        return (
            f"RunStatus({self.data_source}, {self.preconfig}, {self.subject}, "
            f"{self.state})"
        )

    def __str__(self) -> str:
        """Return the string representation of the status."""
        return (
            f"{self.preconfig} × {self.data_source}: "  # noqa: RUF001
            f"{self.subject} = {self.state}"
        )


@dataclass
class TotalStatus:
    """Store the total status of all runs for the GitHub Check."""

    def __init__(
        self,
        runs: Optional[list[RunStatus]] = None,
        path: Path = Path.cwd() / "status.🥒",
    ) -> None:
        self.path = Path(path)
        """Path to status data on disk."""
        _runs = {} if runs is None else {run.key: run for run in runs}
        self.runs: dict[tuple[str, str, str], RunStatus] = {}
        """Dictionary of runs with individual statuses."""
        self.load()
        self.runs.update(_runs)

    def __add__(self, other: RunStatus) -> "TotalStatus":
        """Add a run to the total status."""
        return TotalStatus([other])

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

    @property
    def failure(self) -> Fraction:
        """Return the fraction of runs that are failures."""
        return self.fraction("failure") + self.fraction("error")

    @property
    def failures(self) -> Fraction:  # noqa: D102
        return self.failure

    failures.__doc__ = failure.__doc__

    def fraction(self, status: _STATE) -> Fraction:
        """Return the fraction of runs that are successful."""
        try:
            return Fraction(
                sum(run.state == status for run in self.runs.values()),
                self._denominator,
            )
        except ZeroDivisionError:
            msg = "No runs have been logged as started."
            raise ProcessLookupError(msg)

    def __iadd__(self, other: RunStatus) -> "TotalStatus":
        """Add a run to the total status."""
        self.runs.update({other.key: other})
        return self

    def load(self) -> "TotalStatus":
        """Load status from disk, replacing current status.

        If no status on disk (at ``self.path``), keep current status.
        """
        if self.path.exists():
            with self.path.open("rb") as _pickle:
                self.__dict__.update(pickle.load(_pickle).__dict__)
        return self

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
            state=self.state,
            target_url=target_url,
            description=self.description,
            context="lite regression test",
        )

    def __repr__(self):
        """Return reproducible string for TotalStatus."""
        return f"TotalStatus({self.runs}, path={self.path})"

    @property
    def state(self) -> _STATE:
        """Return the state of the status."""
        if self.pending:
            return "pending"
        if self.success > self.failure:
            return "success"
        return "failure"

    def __str__(self):
        """Return string representation of TotalStatus."""
        return "\n".join([f"{key}: {value.state}" for key, value in self.runs.items()])

    @property
    def success(self) -> Fraction:
        """Return the fraction of runs that are successful."""
        return self.fraction("success")

    @property
    def successes(self) -> Fraction:  # noqa: D102
        return self.success

    successes.__doc__ = success.__doc__

    def write(self) -> None:
        """Write current status to disk."""
        with self.path.open("wb") as _pickle:
            flock(_pickle.fileno(), LOCK_EX)  # Lock the file
            pickle.dump(self, _pickle)  # Write the pickle
            flock(_pickle.fileno(), LOCK_UN)  # Unlock the file


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


def _env_varname(arg: str) -> str:
    """Return an environment argument name given a CLI argument name."""
    return f"_CPAC_STATUS_{arg.upper().replace('-', '_')}"


def main() -> None:
    """Run the script from the commandline."""
    set_working_directory()
    # Parse the arguments
    parser, subparsers = _parser()
    args = parser.parse_args()
    args = NamespaceWithEnvFallback(args)
    # Set the state
    if args.command in ["add", "finalize"]:
        state: _STATE = (
            "pending" if args.command == "add" else args.env_fallback("state")
        )
        status = TotalStatus(
            [RunStatus(args.data_source, args.preconfig, args.subject, state)]
        )
        status.push()  # set GitHub Action status

    # if (
    #     status.state != "pending"
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
    update_parser = ArgumentParser(add_help=False)
    for arg in ["data-source", "preconfig", "subject"]:
        argstrings = list({f"--{argstr}" for argstr in [arg, arg.replace("-", "_")]})
        update_parser.add_argument(*argstrings, help=_parser_arg_helpstring(arg))
    subparsers = parser.add_subparsers(dest="command")
    for command, description in {
        "add": "add a run in a pending state",
        "finalize": "finalize a run (success, failure or error)",
    }.items():
        subparsers.add_parser(
            command,
            description=description,
            help=description,
            parents=[base_parser, update_parser],
        )
    subparsers.choices["finalize"].add_argument(
        "--state",
        choices=["success", "failure", "error"],
        help=_parser_arg_helpstring("state"),
    )

    return parser, subparsers.choices


def _parser_arg_helpstring(arg: str) -> str:
    """Return a string describing the optional environment variable."""
    return f"falls back on ${_env_varname(arg)} if this option is not set"


if __name__ == "__main__":
    main()

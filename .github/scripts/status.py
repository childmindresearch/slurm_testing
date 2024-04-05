#!/usr/bin/env python
# -*- coding: utf-8 -*-
# SBATCH -N 1
# SBATCH -p RM-shared
# SBATCH -t 00:05:00
# SBATCH --ntasks-per-node=4
"""Consolidate job statistics into a single GitHub status.

Requires the following environment variables:
- _CPAC_STATUS_DATA_SOURCE: The data source.
- _CPAC_STATUS_PRECONFIG: The preconfig.
- _CPAC_STATUS_SUBJECT: The subject.
- GITHUB_TOKEN: A GitHub token with access to the repository.
- OWNER: The owner of the repository.
- REPO: The repository.
- SHA: The commit SHA.

Also optionally accepts the following environment variables:
- _CPAC_STATUS_STATE: The state of the run. Defaults to "pending".
"""
from argparse import ArgumentParser, Namespace
from dataclasses import dataclass
from fcntl import flock, LOCK_EX, LOCK_UN
from fractions import Fraction
from logging import basicConfig, getLogger, INFO
import os
from pathlib import Path
import pickle
from typing import cast, Literal, Optional, Union

from github import Github

LOG_FORMAT = "%(asctime)s: %(levelname)s: %(pathname)s: %(funcName)s: %(message)s"
LOGGER = getLogger(name=__name__)
PATHSTR = Union[Path, str]
_STATE = Literal["error", "failure", "pending", "success"]
VALID_STATES = ["error", "failure", "pending", "success"]
basicConfig(format=LOG_FORMAT, level=INFO)


@dataclass
class RunStatus:
    """A dataclass for storing the status of a run for the GitHub Check."""

    data_source: str
    preconfig: str
    subject: str
    state: _STATE = "pending"

    def __str__(self) -> str:
        """Return the string representation of the status."""
        return f"{self.preconfig} × {self.data_source}: {self.subject}"


@dataclass
class TotalStatus:
    """Store the total status of all runs for the GitHub Check."""

    def __init__(
        self, runs: dict[str, RunStatus], path: Path = Path.cwd() / "status.🥒"
    ) -> None:
        self.path = path
        """Path to status data on disk."""
        self.runs = {}
        """Dictionary of runs with individual statuses."""
        self.load()
        self.runs.update(runs)

    def __add__(self, other: RunStatus) -> "TotalStatus":
        """Add a run to the total status."""
        return TotalStatus({**self.runs, str(other): other})

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
    def failures(self) -> Fraction:
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
            raise ProcessLookupError("No runs have been logged as started.")

    def __iadd__(self, other: RunStatus) -> "TotalStatus":
        """Add a run to the total status."""
        self.runs.update({str(other): other})
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
        commit.create_status(
            state=self.state,
            target_url=f"https://github.com/{os.environ['OWNER']}/regtest-runlogs/tree"
            f"/{os.environ['REPO']}_{os.environ['SHA']}/launch",
            description=self.description,
            context="lite regression test",
        )

    def __repr__(self):
        """Reproducible string for TotalStatus."""
        return f"TotalStatus({self.runs}, path={self.path})"

    @property
    def state(self) -> _STATE:
        """Return the state of the status."""
        if self.pending:
            return "pending"
        elif self.success > self.failure:
            return "success"
        return "failure"

    def __str__(self):
        """String representation of TotalStatus."""
        return "\n".join([f"{key}: {value.state}" for key, value in self.runs.items()])

    @property
    def success(self) -> Fraction:
        """Return the fraction of runs that are successful."""
        return self.fraction("success")

    @property
    def successes(self) -> Fraction:
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
    """Namespace, but with additional ``_env_fallback`` method"""

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
    # args.env_fallback = _env_fallback
    # if args.command in ["add", "finalize"]:
    #     state = "pending" if args.command == "add" else args.env_fallback("state")

    # if "state" in _args_dict:
    #     state: _STATE = _validate_state(_args_dict.pop("state"))
    #     args = RunStatus(**_args_dict, state=state)
    # else:
    #     args = RunStatus(**_args_dict, state="pending")
    # del _args_dict

    # status += RunStatus(args.data_source, args.preconfig, args.subject, args.state)

    # status.push()

    # if (
    #     status.state != "pending"
    # ):  # Remove the pickle if the status is no longer pending
    #     status_pickle.unlink(missing_ok=True)


def _parser() -> tuple[ArgumentParser, dict[str, ArgumentParser]]:
    """Create a parser to parse commandline args."""
    parser = ArgumentParser(prog="status")
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
    """return a string describing the optional environment variable"""
    return f"falls back on ${_env_varname(arg)} if this option is not set"


def _validate_state(state: str) -> _STATE:
    """Validate the state."""
    assert state in VALID_STATES
    return cast(_STATE, state)


if __name__ == "__main__":
    main()

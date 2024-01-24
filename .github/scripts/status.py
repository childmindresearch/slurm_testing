#!/usr/bin/env python
# -*- coding: utf-8 -*-
# SBATCH -N 1
# SBATCH -p RM-shared
# SBATCH -t 00:05:00
# SBATCH --ntasks-per-node=4
"""Consolidate job statistics into a single GitHub status.

Requires the following environment variables:
- _C-PAC-STATUS_DATA_SOURCE: The data source.
- _C-PAC-STATUS_PRECONFIG: The preconfig.
- _C-PAC-STATUS_SUBJECT: The subject.
- GITHUB_TOKEN: A GitHub token with access to the repository.
- OWNER: The owner of the repository.
- REPO: The repository.
- SHA: The commit SHA.

Also optionally accepts the following environment variables:
- _C-PAC-STATUS_STATE: The state of the run. Defaults to "pending".
"""
from dataclasses import dataclass
from fcntl import flock, LOCK_EX, LOCK_UN
from fractions import Fraction
import os
from pathlib import Path
import pickle
import sys
from typing import cast, Literal

from github import Github

_STATE = Literal["error", "failure", "pending", "success"]
VALID_STATES = ["error", "failure", "pending", "success"]


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
    """A dataclass for storing the total status of all runs for the GitHub Check."""

    runs: dict[str, RunStatus]

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

    @property
    def state(self) -> _STATE:
        """Return the state of the status."""
        if self.pending:
            return "pending"
        elif self.success > self.failure:
            return "success"
        return "failure"

    @property
    def success(self) -> Fraction:
        """Return the fraction of runs that are successful."""
        return self.fraction("success")

    @property
    def successes(self) -> Fraction:
        return self.success

    successes.__doc__ = success.__doc__


def main() -> None:
    """Run the script from the commandline."""
    # Parse the arguments
    _args_dict: dict[str, str] = cast(
        dict[str, str],
        {
            var: os.environ.get(f"_C-PAC-STATUS_{var.upper()}")
            for var in ["data_source", "preconfig", "subject", "state"]
            if var is not None
        },
    )
    if "state" in _args_dict:
        state: _STATE = _validate_state(_args_dict.pop("state"))
        args = RunStatus(**_args_dict, state=state)
    else:
        args = RunStatus(**_args_dict, state="pending")
    del _args_dict

    status_pickle = Path.cwd() / "status.🥒"
    if status_pickle.exists():
        with status_pickle.open("rb") as _:
            status = pickle.load(_)
    else:
        status = TotalStatus({})

    status += RunStatus(args.data_source, args.preconfig, args.subject, args.state)

    with open(status_pickle, "wb") as _:
        flock(_.fileno(), LOCK_EX)  # Lock the file
        pickle.dump(status, _)  # Write the pickle
        flock(_.fileno(), LOCK_UN)  # Unlock the file

    status.push()

    if (
        status.state != "pending"
    ):  # Remove the pickle if the status is no longer pending
        status_pickle.unlink(missing_ok=True)


def _validate_state(state: str) -> _STATE:
    """Validate the state."""
    assert state in VALID_STATES
    return cast(_STATE, state)


if __name__ == "__main__":
    if sys.argv[1] in ["-h", "--help", "help", "usage"]:
        print(__doc__)
    else:
        main()

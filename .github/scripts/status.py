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
"""
import argparse
from dataclasses import dataclass
from fcntl import flock, LOCK_EX, LOCK_UN
from fractions import Fraction
import os
from pathlib import Path
import pickle
from typing import Literal

from github import Github

_STATE = Literal["error", "failure", "pending", "success"]
_VALID_STATES = ("error", "failure", "pending", "success")


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
            target_url=f"https://github.com/${os.environ['OWNER']}/regtest-runlogs/tree"
            f"/${os.environ['REPO']}_${os.environ['SHA']}/launch",
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


def _create_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    # Create the parser
    parser = argparse.ArgumentParser()
    parser.add_argument("data_source", default=None, help="Specify the data source.")
    parser.add_argument("preconfig", default=None, help="Specify the preconfig.")
    parser.add_argument("subject", default=None, help="Specify the subject.")
    parser.add_argument(
        "state", choices=_VALID_STATES, default="pending", help="Specify the state."
    )
    return parser


def main() -> None:
    """Run the script from the commandline."""
    # Parse the arguments
    args = _create_parser().parse_args()
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


if __name__ == "__main__":
    main()

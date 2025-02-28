#!/usr/bin/env python3
"""
Run a full regression test.

Currently this script relies on a C-PAC image being available from a lite run.
"""
from copy import copy
from trace import Trace
from types import SimpleNamespace

from cpac_slurm_testing.git_remote import GitRemoteInfo
from cpac_slurm_testing.status.cli import SlurmTestingNamespace
from cpac_slurm_testing.status.status import TotalStatus
from cpac_slurm_testing.utils.datapaths import (
    datapaths,
    list_site_subjects,
    RawDataNotFound,
    SITES,
)

_TRACER = Trace(trace=True)


def add(ns: SlurmTestingNamespace, git_remote: GitRemoteInfo) -> None:
    """Add a full run to the SLURM queue."""
    for site in SITES:
        try:
            for subject in list_site_subjects(
                getattr(datapaths[ns.scope](ns.home_dir), site)
            ):
                for preconfig in ns.preconfigs.split(" "):
                    _ns = copy(ns)
                    _ns.data_source = site
                    _ns.preconfig = preconfig
                    _ns.subject = subject
                    status = TotalStatus(
                        image=ns.sha,
                        home_dir=ns.home_dir,
                        testing_paths=ns.testing_paths,
                        scope=ns.scope,
                        dry_run=ns.dry_run,
                        git_remote=git_remote,
                    )
                    status.update(_ns)
                    del _ns
        except RawDataNotFound:
            continue


def main() -> None:
    """Run a full regression test."""
    namespace = SlurmTestingNamespace(
        SimpleNamespace(
            command="add",
            scope="full",
            **{
                _: None
                for _ in [
                    "data_source",
                    "home_dir",
                    "image_name",
                    "out",
                    "preconfigs",
                    "sha",
                    "token_file",
                    "wd",
                ]
            },
        )
    )
    with open(namespace.token_file, "r", encoding="utf8") as _token_file:
        github_token: str = _token_file.read().strip()
        if "GITHUB_TOKEN=" in github_token:
            github_token = github_token.split("GITHUB_TOKEN=", 1)[1]
    git_remote = GitRemoteInfo(
        owner="FCP-INDI",
        repo="C-PAC",
        sha=namespace.sha,
        token=github_token,
    )
    add(namespace, git_remote)


if __name__ == "__main__":
    main()

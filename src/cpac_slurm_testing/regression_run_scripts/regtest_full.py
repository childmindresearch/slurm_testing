#!/usr/bin/env python3
"""
Run a full regression test.

Currently this script relies on a C-PAC image being available from a lite run.
"""
from copy import copy
from types import SimpleNamespace

from cpac_slurm_testing.status.cli import SlurmTestingNamespace
from cpac_slurm_testing.status.status import TotalStatus
from cpac_slurm_testing.utils.datapaths import datapaths, list_site_subjects, SITES


def add(ns: SlurmTestingNamespace) -> None:
    """Add a full run to the SLURM queue."""
    for site in SITES:
        try:
            for subject in list_site_subjects(
                getattr(datapaths[ns.scope](ns.home_dir), site.lower())
            ):
                for preconfig in ns.preconfigs:
                    _ns = copy(ns)
                    _ns.data_source = site
                    _ns.preconfig = preconfig
                    _ns.subject = subject
                    status = TotalStatus(
                        testing_paths=ns.testing_paths, dry_run=ns.dry_run
                    )
                    status.update(_ns)
                    del _ns
        except AttributeError:
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
                    "wd",
                ]
            },
        )
    )
    add(namespace)


if __name__ == "__main__":
    main()

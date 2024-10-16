#!/usr/bin/env python
# -*- coding: utf-8 -*-
# SBATCH -N 1
# SBATCH -p RM-shared
# SBATCH -t 00:05:00
# SBATCH --ntasks=1
"""Push run logs to GitHub."""
from argparse import ArgumentParser, Namespace
from pathlib import Path

from git import Repo as GitRepo


def push_branch(correlations_dir: Path, branch_name: str) -> None:
    """Create and push a branch for a correlation run's logs."""
    repo = GitRepo(correlations_dir)
    repo.remotes.origin.push(f"{branch_name}:{branch_name}")


def main() -> None:
    """CLI for :py:func:`push_branch`."""
    parser = ArgumentParser()
    for arg in ["correlations_dir", "branch_name"]:
        parser.add_argument(f"--{arg}")
    args: Namespace = parser.parse_args()
    push_branch(Path(args.correlations_dir), args.branch_name)


if __name__ == "__main__":
    main()

#!/usr/bin/env python
# -*- coding: utf-8 -*-
# SBATCH -N 1
# SBATCH -p RM-shared
# SBATCH -t 00:05:00
# SBATCH --ntasks=1
"""Push run logs to GitHub."""
from argparse import ArgumentParser, Namespace
from importlib.metadata import metadata
from importlib.metadata._adapters import Message as PackageMetadata
from importlib.resources import files
import os
from pathlib import Path
from re import fullmatch
import stat
from tempfile import NamedTemporaryFile
from typing import cast, Optional

from git import Repo
from git.exc import GitCommandError
from git.refs.remote import RemoteReference
from github import Github
from github.Repository import Repository
import requests

from cpac_slurm_testing.correlation.git_utils import GITHUB_TOKEN


def push_branch(correlations_dir: Path, branch_name: str) -> tuple[Repo, str]:
    """Create and push a branch for a correlation run's logs."""
    repo = Repo(correlations_dir)
    with NamedTemporaryFile(delete=False, mode="w") as askpass_script:
        askpass_script.write(f"#!/bin/sh\necho {GITHUB_TOKEN}")
        askpass_script.flush()
        os.chmod(askpass_script.name, stat.S_IREAD | stat.S_IEXEC)

    try:
        with repo.git.custom_environment(GIT_ASKPASS=askpass_script.name):
            repo.remotes.origin.push(f"{branch_name}:{branch_name}")
    finally:
        os.remove(askpass_script.name)
        return repo, branch_name[-40:]


def push_comment(repository: Repo, sha: str) -> None:
    """Create and push comment via GitHub Actions."""
    github_client: Github = Github(GITHUB_TOKEN)
    name_owner_slash_repo: str = ""
    try:
        package_metadata = cast(PackageMetadata, metadata("cpac_slurm_testing"))
        name_owner_slash_repo = (
            package_metadata.get("Project-URL", "")
            .split("Repository, ", 1)[1]
            .split("github.com", 1)[1][1:]
        )
    except (IndexError, KeyError):
        try:
            name_owner_slash_repo = Repo(
                list(Path(str(files("cpac_slurm_testing"))).parents)[1]
            ).remotes.origin.url.split("github.com", 1)[1][1:-4]
        except (GitCommandError, IndexError, KeyError):
            name_owner_slash_repo = "childmindresearch/slurm_testing"
    finally:
        assert bool(fullmatch(r"[^/]+/[^/]+", name_owner_slash_repo))

    github_repo: Repository = github_client.get_repo(name_owner_slash_repo)
    workflow_dispatch_url: str = (
        f"https://api.github.com/repos/{name_owner_slash_repo}/actions/workflows/"
        "post_comment.yaml/dispatches"
    )
    headers: dict[str, str] = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
    }
    testing_branch: str
    try:
        _tracking_branch: Optional[RemoteReference] = repository.refs[
            0
        ].tracking_branch()
        if _tracking_branch:
            testing_branch = _tracking_branch.name.split(
                f"{_tracking_branch.remote_name}/", 1
            )[1]
        else:
            testing_branch = repository.refs[0].name
    except (AttributeError, IndexError):
        testing_branch = github_repo.default_branch  # fall back to default branch
    data: dict[str, dict[str, str] | str] = {
        "ref": testing_branch,
        "inputs": {"SHA": sha},
    }
    requests.post(workflow_dispatch_url, json=data, headers=headers)


def main() -> None:
    """CLI for :py:func:`push_branch`."""
    parser = ArgumentParser()
    for arg in ["correlations_dir", "branch_name", "repository"]:
        parser.add_argument(f"--{arg}")
    args: Namespace = parser.parse_args()
    push_comment(*push_branch(Path(args.correlations_dir), args.branch_name))


if __name__ == "__main__":
    main()

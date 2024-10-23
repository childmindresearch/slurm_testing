#!/usr/bin/env python
# -*- coding: utf-8 -*-
# SBATCH -N 1
# SBATCH -p RM-shared
# SBATCH -t 00:05:00
# SBATCH --ntasks=1
"""Push run logs to GitHub."""
from argparse import ArgumentParser, Namespace
import os
from pathlib import Path
from typing import Optional

from git import Repo
from git.refs.remote import RemoteReference
from github import Github
from github.Repository import Repository
import requests


def push_branch(correlations_dir: Path, branch_name: str) -> tuple[Repo, str]:
    """Create and push a branch for a correlation run's logs."""
    repo = Repo(correlations_dir)
    repo.remotes.origin.push(f"{branch_name}:{branch_name}")
    return repo, branch_name[-40:]


def push_comment(repository: Repo, sha: str) -> None:
    """Create and push comment via GitHub Actions."""
    try:
        github_token: str = repository.remotes.origin.url.split(":", 2)[2].split(
            "@", 1
        )[0]
    except IndexError:
        try:
            github_token = os.environ.get("GITHUB_TOKEN", os.environ["GH_TOKEN"])
        except KeyError:
            msg = "Could not determine PAT for GitHub access."
            raise LookupError(msg)
    github_client: Github = Github(github_token)
    name_owner_slash_repo: str = repository.remotes.origin.url.split("github.com", 1)[
        1
    ][1:-4]
    github_repo: Repository = github_client.get_repo(name_owner_slash_repo)
    workflow_dispatch_url: str = (
        f"https://api.github.com/repos/{name_owner_slash_repo}/actions/workflows/"
        "post_comment.yaml/dispatches"
    )
    headers: dict[str, str] = {
        "Authorization": f"Bearer {github_token}",
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

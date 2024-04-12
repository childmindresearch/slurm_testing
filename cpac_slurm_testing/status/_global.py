"""Global values for status checking."""
from importlib.resources import files
import os
from pathlib import Path
from typing import Literal, Union

_COMMAND_TYPES = Literal["lite_run"]
DRY_RUN = False
"""Skip actually running commands?"""
HOME_DIR = Path(os.environ.get("HOME_DIR", os.path.expanduser("~")))
_JOB_STATE = Literal[
    "COMPLETED",
    "COMPLETING",
    "FAILED",
    "PENDING",
    "PREEMPTED",
    "RUNNING",
    "SUSPENDED",
    "STOPPED",
]
_STATE = Literal["error", "failure", "pending", "success"]
JOB_STATES: dict[_JOB_STATE, _STATE] = {
    "COMPLETED": "success",
    "COMPLETING": "pending",
    "FAILED": "failure",
    "PENDING": "pending",
    "PREEMPTED": "error",
    "RUNNING": "pending",
    "SUSPENDED": "pending",
}
LOG_FORMAT = "%(asctime)s: %(levelname)s: %(pathname)s: %(funcName)s:\n\t%(message)s\n"
PATHSTR = Union[Path, str]
TEMPLATES = {
    key: files("cpac_slurm_testing.templates").joinpath(f"{key}.ftxt").read_text()
    for key in ["lite_run"]
}

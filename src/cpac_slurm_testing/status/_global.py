"""Global values for status checking."""
from importlib.resources import files
import logging
import os
from pathlib import Path
from typing import Literal, Optional

_COMMAND_TYPES = Literal["lite_run"]
HOME_DIR = Path(os.environ.get("HOME_DIR", os.path.expanduser("~")))
_JOB_STATE = Literal[
    "COMPLETED",
    "COMPLETING",
    "FAILED",
    "OUT_OF_MEMORY",
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
    "OUT_OF_MEMORY": "error",
    "PENDING": "pending",
    "PREEMPTED": "error",
    "RUNNING": "pending",
    "SUSPENDED": "pending",
}
LOG_FORMAT = "%(asctime)s: %(levelname)s: %(pathname)s: %(funcName)s:\n\t%(message)s\n"
TEMPLATES = {
    key: files("cpac_slurm_testing.templates").joinpath(f"{key}.ftxt").read_text()
    for key in ["lite_run"]
}
SBATCH_START: list[str] = ["sbatch", "-p", "RM-shared", "--ntasks-per-node=4"]
StrPath = str | Path


def logger_set_handlers(  # noqa: PLR0913
    logger: logging.Logger,
    encoding: str = "utf8",
    filename: Optional[StrPath] = None,
    force: bool = False,
    fmt: str = LOG_FORMAT,
    level: int | str = logging.INFO,
) -> logging.Logger:
    """Set handlers on a :py:class:`~logging.Logger`."""
    if force:
        for handler in list(logger.handlers):
            logger.removeHandler(handler)
    if not logger.handlers:
        if filename:
            handler = logging.FileHandler(filename=filename, encoding=encoding)
        else:
            handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter(fmt))
        logger.setLevel(level)
        logger.addHandler(handler)
    return logger


def get_logger(  # noqa: PLR0913
    name: Optional[str],
    encoding: str = "utf8",
    filename: Optional[StrPath] = None,
    force: bool = False,
    fmt: str = LOG_FORMAT,
    level: int | str = logging.INFO,
) -> logging.Logger:
    """Get a :py:class:`~logging.Logger` by name or the root Logger."""
    return logger_set_handlers(
        logging.getLogger(name=name),
        encoding=encoding,
        filename=filename,
        force=force,
        fmt=fmt,
        level=level,
    )

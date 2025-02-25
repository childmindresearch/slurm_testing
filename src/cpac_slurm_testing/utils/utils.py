"""General utilities."""
from shutil import rmtree
from typing import Literal

from cpac_slurm_testing.utils._typing import coerce_to_Path, PathStr


def unlink(path: PathStr, error: Literal["ignore", "raise"] = "ignore") -> None:
    """Remove a path."""
    path = coerce_to_Path(path)
    unlink_method: str
    if path.is_dir():
        unlink_method = "rmdir"
        if any(path.iterdir()):
            rmtree(path, ignore_errors=error == "ignore")
            return
    else:
        unlink_method = "unlink"
    try:
        getattr(path, unlink_method)()
    except FileNotFoundError as file_not_found_error:
        if error == "raise":
            raise file_not_found_error
    return

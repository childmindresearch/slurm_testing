"""General utilities."""
from pathlib import Path
from shutil import rmtree
from typing import Literal

from cpac_slurm_testing.utils._typing import coerce_to_Path, PathStr


class ExistingPath(Path):
    """A Path that definitely exists."""

    def __new__(cls, *args, **kwargs) -> "ExistingPath":
        """Construct a Path."""
        return super().__new__(cls, *args, **kwargs)

    def __init__(self, /, *args, **kwargs) -> None:
        """Initialize an ExistingPath."""
        super().__init__(*args, **kwargs)
        if not self.exists():
            for parent in reversed(self.parents):
                parent.mkdir(mode=0o777, exist_ok=True)
            self.mkdir(mode=0o777, exist_ok=True)
        assert self.exists()


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

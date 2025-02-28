"""General utilities."""
import os
from pathlib import Path, PosixPath, WindowsPath
from shutil import rmtree
from typing import cast, Literal

from cpac_slurm_testing.utils._typing import coerce_to_Path, PathStr


class ExistingPath(Path):
    """A Path that definitely exists."""

    def __new__(cls, *args, **kwargs) -> "ExistingPath":
        """Construct an ExistingPath."""
        if cls is Path:
            cls = cast(
                type[ExistingPath], WindowsPath if os.name == "nt" else PosixPath
            )
        instance = cast(ExistingPath, object.__new__(cls))
        if not instance.exists():
            for parent in reversed(instance.parents):
                parent.mkdir(mode=0o777, exist_ok=True)
            instance.mkdir(mode=0o777, exist_ok=True)
        assert instance.exists()
        return instance


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

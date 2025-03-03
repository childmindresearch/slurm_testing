"""General utilities."""
from pathlib import Path
from shutil import rmtree
from typing import cast, Literal

from cpac_slurm_testing.utils._typing import coerce_to_Path, PathStr


class ExistingPath(Path):
    """A Path that definitely exists."""

    def __new__(cls, *args, **kwargs) -> "ExistingPath":
        """Construct an ExistingPath."""
        instance = cast(ExistingPath, Path(*args, **kwargs))
        if not instance.exists():
            for parent in reversed(instance.parents):
                ExistingPath._try_to_mk(parent)
            ExistingPath._try_to_mk(instance)
        assert instance.exists()
        return instance

    @staticmethod
    def _try_to_mk(path: Path) -> None:
        """Try to make paths, but don't fail unless path doeesn't exist in the end."""
        if path.exists():
            return
        try:
            path.mkdir(mode=0o777, exist_ok=True)
        except Exception as e:
            if not path.exists():
                raise e


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

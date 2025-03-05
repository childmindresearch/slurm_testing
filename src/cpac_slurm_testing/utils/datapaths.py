"""Datapaths."""
from dataclasses import dataclass
from pathlib import Path
from typing import Literal, Optional, overload, TypeAlias, TypedDict

from cpac_slurm_testing.utils._typing import Scope

SITES = ["CBIC", "HNU_1", "KKI", "oxford", "RBC", "SI"]
GetRawData: TypeAlias = Path | Scope | Literal["raw"]


class RawDataNotFound(FileNotFoundError):
    """Raw data path not defined for this scope."""


@dataclass
class RawData:
    """Raw data for regression tests."""

    root: Path
    cbic: Path
    hnu_1: Path
    kki: Path
    oxford: Path
    rbc: Path
    rodent: Path
    si: Path

    @property
    def regdatapath(self) -> Path:
        """Return path for binding regdata."""
        return getattr(self, "_regdatapath", self.root)

    @property
    def scope(self):
        """Get the testing scope of the RawData."""
        return self.__class__.__name__.split("Data", 1)[0].lower()

    @overload
    def __getattr__(  # type: ignore  # pyright: ignore[reportOverlappingOverload]
        self, name: Literal["scope"], default: Optional[GetRawData] = None
    ) -> Scope | Literal["raw"]:
        ...

    @overload
    def __getattr__(self, name: str, default: Optional[GetRawData] = None) -> Path:
        ...

    def __getattr__(
        self, name: str, default: Optional[GetRawData] = None
    ) -> GetRawData:
        """Get a Path or raise an exception."""
        if name in ["root", "scope"] or name.startswith("_"):
            return object.__getattribute__(self, name)
        name = name.lower()
        if name in self.__dict__:
            return object.__getattribute__(self, name)
        if default:
            return default
        msg = f"{name} not defined for {self.scope} data."
        raise RawDataNotFound(msg)


class FullData(RawData):
    """Full raw data."""

    def __init__(self, home_dir: Optional[Path]) -> None:
        """Initialize full raw data.

        Parameters
        ----------
        home_dir
            unused parameter, in place to match signature for lite data.
        """
        self.root = Path("/ocean/projects/med220004p/shared/data_raw/CPAC-Regression")
        self.cbic = self.root / "HBN/MRI/Site-CBIC"
        self.hnu_1 = self.root / "CORR/RawDataBIDS/HNU_1"
        self.kki = self.root / "ADHD200/RawDataBIDS/KKI"
        self.oxford = self.root / "nhp/oxford"
        self.rodent = self.root / "rodent"
        self.si = self.root / "HBN/MRI/Site-SI"


class LiteData(RawData):
    """Lite raw data."""

    def __init__(self, home_dir: Path) -> None:
        """Initialize lite raw data."""
        self._regdatapath = home_dir / "DATA/reg_5mm_pack"
        self.root = self.regdatapath / "data"
        for site in SITES:
            setattr(
                self,
                site.lower(),
                self.root / (f"Site-{site}" if site in ["CBIC", "SI"] else site),
            )


class DataPaths(TypedDict):
    """Typed dict to hold datapaths."""

    full: type[FullData]
    lite: type[LiteData]


datapaths: DataPaths = {"full": FullData, "lite": LiteData}


def list_site_subjects(site_dir: Path) -> list[str]:
    """List subjects in a site directory."""
    return [path.name for path in site_dir.iterdir() if path.name.startswith("sub-")]

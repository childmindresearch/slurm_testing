"""Datapaths."""
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

SITES = ["CBIC", "HNU_1", "KKI", "oxford", "RBC", "SI"]


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
        self.root = home_dir / "DATA/reg_5mm_pack/data"
        for site in SITES:
            setattr(
                self,
                site.lower(),
                self.root / (f"Site-{site}" if site in ["CBIC", "SI"] else site),
            )


datapaths = {"full": FullData, "lite": LiteData}


def list_site_subjects(site_dir: Path) -> list[str]:
    """List subjects in a site directory."""
    return [path.name for path in site_dir.iterdir() if path.name.startswith("sub-")]

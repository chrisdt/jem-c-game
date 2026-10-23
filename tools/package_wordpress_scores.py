"""Create the small installable WordPress plugin, excluding all game/private data."""
from pathlib import Path
import argparse
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FILES = ("sunny-scout-scores.php", "score-rules.php", "readme.txt")


def package(destination: Path) -> Path:
    source = ROOT / "wordpress/sunny-scout-scores"
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
        for name in FILES:
            path = source / name
            if path.is_symlink() or not path.is_file():
                raise ValueError(f"Expected plugin source: {name}")
            archive.write(path, "sunny-scout-scores/" + name)
    with zipfile.ZipFile(destination) as archive:
        assert archive.namelist() == ["sunny-scout-scores/" + name for name in FILES]
        for name in FILES:
            assert archive.read("sunny-scout-scores/" + name) == (source / name).read_bytes()
    print(f"Installable plugin: {destination} ({destination.stat().st_size:,} bytes)")
    print("SHA-256: " + hashlib.sha256(destination.read_bytes()).hexdigest())
    return destination


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "build/sunny-scout-scores.zip")
    package(parser.parse_args().output)

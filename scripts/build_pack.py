#!/usr/bin/env python3
"""Create a deterministic, installable ZIP from the repository-root pack."""
from __future__ import annotations

import argparse
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo
from sky_atlas import ensure_atlas
from license_audit import check as check_licenses

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "dist" / "NotVisuals_26.3_v8_candidate_3_AuroraSky.zip"


def pack_files() -> list[Path]:
    required = [ROOT / "pack.mcmeta", ROOT / "pack.png"]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        raise SystemExit(f"Missing required pack file(s): {', '.join(missing)}")
    notices = [ROOT / name for name in (
        "LICENSE", "LICENSE-CODE", "LICENSE-ASSETS.md",
        "LICENSING.md", "THIRD_PARTY_LICENSES.md", "TRADEMARKS.md",
        "docs/RIGHTS_STATUS.json",
    )]
    missing_notices = [p.name for p in notices if not p.is_file()]
    if missing_notices:
        raise SystemExit("Missing license notices: " + ", ".join(missing_notices))
    files = required + notices + [p for p in (ROOT / "assets").rglob("*") if p.is_file()]
    if not (ROOT / "assets").is_dir() or len(files) == len(required):
        raise SystemExit("Missing assets/ content")
    return sorted(files, key=lambda p: p.relative_to(ROOT).as_posix())


def build(output: Path, *, release: bool = False) -> None:
    check_licenses(release=release)
    ensure_atlas()
    files = pack_files()
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w") as archive:
        for path in files:
            rel = path.relative_to(ROOT).as_posix()
            meta = ZipInfo(rel, (1980, 1, 1, 0, 0, 0))
            meta.compress_type = ZIP_DEFLATED
            meta.external_attr = 0o644 << 16
            archive.writestr(meta, path.read_bytes(), compresslevel=9)
    print(f"Built {output} ({len(files)} files, {output.stat().st_size} bytes)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--release", action="store_true",
                        help="Reject release while third-party rights remain unresolved")
    args = parser.parse_args()
    build(args.output.resolve(), release=args.release)

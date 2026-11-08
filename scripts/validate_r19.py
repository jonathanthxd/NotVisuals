#!/usr/bin/env python3
"""Validate the exact, user-provided R19 source snapshot. Not an in-game test."""
from pathlib import Path
import hashlib
import json

from sky_atlas import ensure_atlas

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "src" / "pack"
MANIFEST = ROOT / "docs" / "R19_SOURCE_MANIFEST.json"
EXPECTED_ARCHIVE = "5ff3880673ea5d2facdf2d577b7b80129a1b3e01562a40776ffe5e8808b1fd8f"
MIT_NOTICES = ("LICENSES/ANIMATED_ORE_MIT.txt", "LICENSES/WATER_LILIES_MIT.txt", "LICENSES/R18_ATTRIBUTION.md")

def verify():
    if not MANIFEST.is_file():
        raise SystemExit("R19 has not been imported: missing docs/R19_SOURCE_MANIFEST.json")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 1 or manifest.get("archive_sha256") != EXPECTED_ARCHIVE:
        raise ValueError("R19 source archive fingerprint does not match the supplied ZIP")
    ensure_atlas()
    records = manifest["files"]
    if len(records) != 724:
        raise ValueError("Expected 724 files in the original R19 source ZIP")
    for name, desc in records.items():
        if name == "LEEME_R19.md":
            file = ROOT / "docs/R19_RELEASE_NOTES.md"
        elif name.startswith("LICENSES/"):
            file = ROOT / name
        else:
            file = PACK / name
        if not file.is_file():
            raise ValueError(f"Missing original R19 source: {name}")
        if file.stat().st_size != desc["size"] or hashlib.sha256(file.read_bytes()).hexdigest() != desc["sha256"]:
            raise ValueError(f"R19 source does not match original uploaded ZIP: {name}")
    for name in MIT_NOTICES:
        if not (ROOT / name).is_file():
            raise ValueError(f"Missing MIT license/credit: {name}")
    if (ROOT / "pack.mcmeta").exists() or (ROOT / "assets").exists():
        raise ValueError("Repository source ZIP must not be directly installable")
    metadata = json.loads((PACK / "pack.mcmeta").read_text(encoding="utf-8"))
    if metadata["pack"].get("min_format") != [97, 1] or metadata["pack"].get("max_format") != [97, 1]:
        raise ValueError("Incorrect 26.3 resource pack format")
    shaders = [p for p in (PACK / "assets").rglob("*") if p.suffix in (".fsh", ".vsh", ".glsl")]
    if len(shaders) != 41:
        raise ValueError(f"Expected 41 shader files, found {len(shaders)}")
    pipeline = json.loads((PACK / "assets/minecraft/post_effect/end_of_frame.json").read_text(encoding="utf-8"))
    if len(pipeline["passes"]) != 41:
        raise ValueError("Expected 41 R19 postprocessing passes")
    for file in (PACK / "assets").rglob("*"):
        if file.is_file() and (file.suffix == ".json" or file.name.endswith(".mcmeta")):
            json.loads(file.read_text(encoding="utf-8"))
    print("PASS: exact R19 archive validated — 724 files, 41 shaders, 41 passes, MIT notices preserved")
    return (41, 41)

if __name__ == "__main__":
    verify()

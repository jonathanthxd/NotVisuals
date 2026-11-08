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
R20_MANIFEST = ROOT / "docs" / "R20_CHANGESET.json"
TEXT_EXTENSIONS = (".txt", ".json", ".md", ".mcmeta", ".fsh", ".vsh", ".glsl")


def exact_hash(data: bytes, specification: dict) -> bool:
    return len(data) == specification["size"] and hashlib.sha256(data).hexdigest() == specification["sha256"]


def baseline_match(data: bytes, name: str, specification: dict) -> bool:
    if exact_hash(data, specification):
        return True
    # Windows Git checkout can canonicalize source CRLF to LF. Accept ONLY
    # that reversible newline transformation, preserving historical R19 hashes.
    if name.endswith(TEXT_EXTENSIONS) and b"\r\n" not in data:
        return exact_hash(data.replace(b"\n", b"\r\n"), specification)
    return False


def r20_changes(manifest: dict) -> dict:
    if not R20_MANIFEST.is_file():
        return {}
    changes = json.loads(R20_MANIFEST.read_text(encoding="utf-8"))
    if changes.get("schema_version") != 1 or changes.get("baseline_archive_sha256") != EXPECTED_ARCHIVE:
        raise ValueError("R20 changeset not anchored to original R19 archive")
    overrides = changes.get("modified_files", {})
    if not isinstance(overrides, dict) or not overrides:
        raise ValueError("R20 changeset missing explicit modified-file hashes")
    for name, item in overrides.items():
        if name not in manifest["files"] or not name.endswith((".fsh", ".vsh", ".glsl")):
            raise ValueError("R20 may override only declared existing shader sources: " + name)
        if not isinstance(item, dict) or not isinstance(item.get("sha256"), str) or not isinstance(item.get("size"), int):
            raise ValueError("Invalid R20 override record: " + name)
    return overrides


def verify():
    if not MANIFEST.is_file():
        raise SystemExit("R19 has not been imported: missing docs/R19_SOURCE_MANIFEST.json")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 1 or manifest.get("archive_sha256") != EXPECTED_ARCHIVE:
        raise ValueError("R19 source archive fingerprint does not match the supplied ZIP")
    ensure_atlas()
    records = manifest["files"]
    overrides = r20_changes(manifest)
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
        data = file.read_bytes()
        if name in overrides:
            if not exact_hash(data, overrides[name]):
                raise ValueError(f"R20 modified source does not match declared checksum: {name}")
        elif not baseline_match(data, name, desc):
            raise ValueError(f"Unapproved change or missing content compared with R19: {name}")
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
            json.loads(file.read_text(encoding="utf-8-sig"))
    print("PASS: 724 original R19 source files verified" +
          (f" with {len(overrides)} declared R20 shader edits" if overrides else "") +
          " — 41 shaders, 41 passes, original MIT notices retained")
    return (41, 41)

if __name__ == "__main__":
    verify()

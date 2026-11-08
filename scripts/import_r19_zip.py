#!/usr/bin/env python3
"""Import the exact owner-provided R19 ZIP into src/pack. Does not publish or push."""
from __future__ import annotations
import argparse
import hashlib
import json
import shutil
import tempfile
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = "5ff3880673ea5d2facdf2d577b7b80129a1b3e01562a40776ffe5e8808b1fd8f"
SKY = "assets/minecraft/textures/environment/celestial/sun.png"
SKY_SHA = "06cd49d8d53e5855e90d657cb6aa65d1a9d08954374dce0158ef5f846e990c00"

def run(path: Path, apply: bool = False):
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != EXPECTED:
        raise SystemExit("Unexpected R19 ZIP hash: " + digest)
    with ZipFile(path) as archive:
        entries = [i for i in archive.infolist() if not i.is_dir()]
        if len(entries) != 724 or len(set(i.filename for i in entries)) != 724:
            raise ValueError("Expected 724 distinct R19 entries")
        hashes = {}
        for entry in entries:
            name = entry.filename
            if (name.startswith("/") or "\\" in name or ".." in name.split("/") or
                entry.file_size > 100_000_000 or not (
                    name.startswith(("assets/", "LICENSES/")) or
                    name in ("pack.mcmeta", "pack.png", "LEEME_R19.md"))):
                raise ValueError("Unsafe/unexpected ZIP entry: " + name)
            data = archive.read(name)
            hashes[name] = {"size": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        if hashes[SKY]["sha256"] != SKY_SHA:
            raise ValueError("Sky artwork hash does not match authorized source")
        if len(json.loads(archive.read("assets/minecraft/post_effect/end_of_frame.json"))["passes"]) != 41:
            raise ValueError("Unexpected R19 pipeline")
        if len([n for n in hashes if n.endswith((".fsh", ".vsh", ".glsl"))]) != 41:
            raise ValueError("Unexpected R19 shaders")
        for name in ("LICENSES/ANIMATED_ORE_MIT.txt", "LICENSES/WATER_LILIES_MIT.txt", "LICENSES/R18_ATTRIBUTION.md"):
            if name not in hashes:
                raise ValueError("Missing MIT notice: " + name)
        manifest = {"schema_version": 1, "origin": "User-provided R19 experimental ZIP",
                    "archive_sha256": digest, "archive_name": path.name,
                    "game_version": "Minecraft Java 26.3", "pack_format": [97, 1],
                    "content_files": 724, "post_effect_passes": 41, "shader_files": 41,
                    "sky_atlas": {"path": SKY, "sha256": SKY_SHA, "storage": "Git-tracked 15-part source atlas"},
                    "files": hashes}
        print("Verified original R19: 724 files, 41 passes, 41 shader files, 3 MIT notices")
        if not apply:
            print("No files changed. Re-run with --apply to import locally.")
            return
        (ROOT / "dist").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / "dist", prefix="r19-source-") as temporary:
            tmp = Path(temporary)
            for entry in entries:
                name = entry.filename
                if name == SKY:
                    continue  # Built reproducibly from source/aurora_sky/sun_atlas/part_*.b64.
                if name.startswith("assets/") or name in ("pack.mcmeta", "pack.png"):
                    dst = tmp / "src/pack" / name
                elif name.startswith("LICENSES/"):
                    dst = tmp / name
                else:
                    dst = tmp / "docs/R19_RELEASE_NOTES.md"
                dst.parent.mkdir(parents=True, exist_ok=True)
                dst.write_bytes(archive.read(name))
            (tmp / "docs/R19_SOURCE_MANIFEST.json").write_text(
                json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            old, backup = ROOT / "src/pack", ROOT / "dist/r19-previous-source"
            if backup.exists():
                raise SystemExit("Preserve or move existing backup first: " + str(backup))
            if old.exists():
                shutil.move(str(old), str(backup))
            try:
                shutil.move(str(tmp / "src/pack"), str(old))
                for name in ("LICENSES/ANIMATED_ORE_MIT.txt", "LICENSES/WATER_LILIES_MIT.txt", "LICENSES/R18_ATTRIBUTION.md"):
                    f = tmp / name
                    target = ROOT / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(f, target)
                for name in ("R19_RELEASE_NOTES.md", "R19_SOURCE_MANIFEST.json"):
                    shutil.copy2(tmp / "docs" / name, ROOT / "docs" / name)
                from validate_r19 import verify
                verify()
            except Exception:
                if old.exists():
                    shutil.rmtree(old)
                if backup.exists():
                    shutil.move(str(backup), str(old))
                raise
        print("R19 source ready. Review git status; commit and push separately.")
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip", type=Path)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    run(args.zip.resolve(), apply=args.apply)

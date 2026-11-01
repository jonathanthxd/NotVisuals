#!/usr/bin/env python3
"""Reconstruct the exact Aurora Sky PNG from Git-tracked, text-only chunks.

This staging representation permits reproducible builds even when a GitHub
connector cannot directly upload binary blobs. Once sun.png is tracked in Git,
it can be used directly. NEVER substitute a fully transparent 1x1 sun sprite:
the 3080x4064 atlas encodes the complete day/night sky and 4 marker pixels.
"""
from __future__ import annotations
import base64
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source" / "aurora_sky" / "sun_atlas"
TARGET = ROOT / "assets/minecraft/textures/environment/celestial/sun.png"
SHA256 = "06cd49d8d53e5855e90d657cb6aa65d1a9d08954374dce0158ef5f846e990c00"
PNG_SIZE = (3080, 4064)

def atlas_bytes(root: Path = ROOT) -> bytes:
    src = root / "source" / "aurora_sky" / "sun_atlas"
    parts = sorted(src.glob("part_*.b64"))
    if len(parts) != 15:
        raise ValueError(f"Aurora Sky: expected 15 source parts, found {len(parts)}")
    encoded = "".join(part.read_text(encoding="ascii").strip().replace("\n", "") for part in parts)
    data = base64.b64decode(encoded, validate=True)
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise ValueError("Aurora Sky atlas SHA256 mismatch")
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("Aurora Sky atlas is not a PNG")
    import struct
    width, height = struct.unpack(">II", data[16:24])
    if (width, height) != PNG_SIZE:
        raise ValueError(f"Unexpected Aurora Sky atlas dimensions: {width}x{height}")
    return data

def ensure_atlas(root: Path = ROOT) -> Path:
    target = root / "assets/minecraft/textures/environment/celestial/sun.png"
    if target.exists():
        if hashlib.sha256(target.read_bytes()).hexdigest() != SHA256:
            raise ValueError("Aurora Sky sun.png differs from the approved sky sheet")
        return target
    data = atlas_bytes(root)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    return target

if __name__ == "__main__":
    print(ensure_atlas())

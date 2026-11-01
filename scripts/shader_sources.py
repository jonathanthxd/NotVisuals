#!/usr/bin/env python3
"""Resolve shader includes and fetch pinned renderer contracts for developer tests."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INCLUDE = re.compile(r'^\s*#include\s+<([a-z0-9_.-]+):([a-z0-9_./-]+)>\s*$', re.MULTILINE)


def expand(source: str, vanilla: Path | None = None, *, root: Path = ROOT,
           stack: tuple[str, ...] = ()) -> str:
    def replace(match: re.Match) -> str:
        namespace, name = match.groups()
        if ".." in name.split("/"):
            raise ValueError(f"unsafe include: {name}")
        key = namespace + ":" + name
        if key in stack:
            raise ValueError(f"cyclic include: {key}")
        local = root / "assets" / namespace / "shaders/include" / name
        if local.is_file():
            path = local
        elif namespace == "minecraft" and vanilla is not None:
            path = vanilla / "shaders/include" / name
        else:
            raise ValueError(f"unresolved include: {key}")
        return expand(path.read_text(), vanilla, root=root, stack=stack + (key,))
    return INCLUDE.sub(replace, source)


def fetch_contract(destination: Path) -> None:
    manifest = json.loads((ROOT / "docs/V8_RENDERER_CONTRACT.json").read_text())
    for name, record in manifest["files"].items():
        if "sha256" not in record:
            continue
        target = destination / name
        data = target.read_bytes() if target.is_file() else b""
        if hashlib.sha256(data).hexdigest() != record["sha256"]:
            with urllib.request.urlopen(manifest["base_url"] + name, timeout=30) as response:
                data = response.read()
            if hashlib.sha256(data).hexdigest() != record["sha256"]:
                raise ValueError(f"checksum mismatch: {name}")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    print(f"Pinned 26.3 renderer contract verified in {destination}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fetch", type=Path)
    parser.add_argument("--expand", type=Path)
    parser.add_argument("--vanilla-root", type=Path)
    args = parser.parse_args()
    if args.fetch:
        fetch_contract(args.fetch)
    if args.expand:
        print(expand(args.expand.read_text(), args.vanilla_root))

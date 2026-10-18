#!/usr/bin/env python3
"""Static validator for the NotVisuals source tree and post-effect graphs."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POST_EFFECTS = [
    ROOT / "assets/minecraft/post_effect/end_of_frame.json",
    ROOT / "assets/notvisuals/post_effect/pixel_vivid.json",
    ROOT / "assets/notvisuals/post_effect/soft_glow.json",
]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def verify() -> None:
    meta = json.loads((ROOT / "pack.mcmeta").read_text(encoding="utf-8"))
    pack = meta["pack"]
    require(pack.get("min_format") == [97, 1], "unexpected min_format")
    require(pack.get("max_format") == [97, 1], "unexpected max_format")
    require((ROOT / "pack.png").read_bytes().startswith(b"\x89PNG\r\n\x1a\n"), "invalid pack.png")

    custom_shaders = {p.stem for p in (ROOT / "assets/notvisuals/shaders/post").glob("*.fsh")}
    require(len(custom_shaders) > 0, "no custom shaders")
    total = 0
    for effect in POST_EFFECTS:
        obj = json.loads(effect.read_text(encoding="utf-8"))
        targets = obj.get("targets", {})
        passes = obj.get("passes", [])
        require(isinstance(targets, dict) and isinstance(passes, list) and passes, f"malformed effect: {effect}")
        for index, item in enumerate(passes):
            frag = item.get("fragment_shader", "")
            if frag.startswith("notvisuals:post/"):
                name = frag.split("/", 1)[1]
                require(name in custom_shaders, f"missing shader {frag}")
            out = item.get("output", "")
            require(out == "minecraft:main" or out in targets, f"unknown output {out}: {effect}")
            for sample in item.get("inputs", []):
                name = sample.get("target", "")
                require(name == "minecraft:main" or name in targets, f"unknown input target {name}: {effect}")
        total += len(passes)

    for shader in (ROOT / "assets/notvisuals/shaders/post").glob("*.fsh"):
        source = shader.read_text(encoding="utf-8")
        text = re.sub(r"/\*.*?\*/|//[^\n]*", "", source, flags=re.DOTALL)
        require(text.count("{") == text.count("}"), f"unbalanced braces: {shader}")
        require("void main(" in text or "void main (" in text, f"missing main(): {shader}")

    print(f"PASS: {len(POST_EFFECTS)} post-effect definitions, {total} passes, {len(custom_shaders)} shader files")
    print("Note: this is static validation, not GLSL compilation or in-game testing.")


if __name__ == "__main__":
    verify()

#!/usr/bin/env python3
"""Validate NotVisuals graphs and source assets. Not a Minecraft runtime test."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCE_FORMAT = [97, 1]
BUILTIN_SHADERS = {"minecraft:post/blit", "minecraft:post/box_blur"}
CORE_OVERRIDES = {"sky.fsh", "clouds.fsh"}


def require(ok: bool, message: str) -> None:
    if not ok:
        raise ValueError(message)


def shader_path(root: Path, identifier: str, ext: str) -> Path:
    namespace, separator, name = identifier.partition(":")
    require(bool(separator) and bool(re.fullmatch(r"[a-z0-9_.-]+", namespace)), f"bad shader id: {identifier}")
    require(bool(re.fullmatch(r"[a-z0-9_./-]+", name)) and ".." not in name.split("/"),
            f"unsafe shader id: {identifier}")
    return root / "assets" / namespace / "shaders" / (name + "." + ext)


def verify(root: Path = ROOT, *, quiet: bool = False) -> tuple[int, int]:
    root = Path(root)
    meta = json.loads((root / "pack.mcmeta").read_text(encoding="utf-8"))
    pack = meta["pack"]
    require(pack.get("min_format") == RESOURCE_FORMAT, "unexpected min_format")
    require(pack.get("max_format") == RESOURCE_FORMAT, "unexpected max_format")
    require((root / "pack.png").read_bytes().startswith(b"\x89PNG\r\n\x1a\n"), "invalid pack.png")
    assets = root / "assets"
    require(assets.is_dir(), "missing assets")
    effects = sorted(assets.glob("*/post_effect/*.json"))
    require(bool(effects), "no post-effect definitions")
    require((assets / "minecraft/post_effect/end_of_frame.json").is_file(), "missing automatic effect")

    for p in assets.rglob("*.json"):
        json.loads(p.read_text(encoding="utf-8"))

    total = 0
    referenced: set[Path] = set()
    for path in effects:
        obj = json.loads(path.read_text(encoding="utf-8"))
        targets, passes = obj.get("targets"), obj.get("passes")
        require(isinstance(targets, dict) and isinstance(passes, list) and bool(passes),
                f"invalid targets/passes: {path}")
        for name, target in targets.items():
            require(bool(re.fullmatch(r"[a-z0-9_]+", name)) and isinstance(target, dict),
                    f"bad target {name}: {path}")
            if "persistent" in target:
                require(isinstance(target["persistent"], bool), f"bad persistence: {name}")
            for dim in ("width", "height"):
                if dim in target:
                    require(isinstance(target[dim], int) and target[dim] > 0, f"bad {dim}: {name}")

        written: set[str] = set()
        for index, item in enumerate(passes):
            tag = f"{path.relative_to(root)} pass {index}"
            require(isinstance(item, dict), f"invalid pass: {tag}")
            vert, frag = item.get("vertex_shader"), item.get("fragment_shader")
            require(vert == "minecraft:core/screenquad", f"unexpected vertex shader: {tag}")
            require(isinstance(frag, str), f"missing fragment shader: {tag}")
            if frag not in BUILTIN_SHADERS:
                fp = shader_path(root, frag, "fsh")
                require(fp.is_file(), f"missing fragment shader {frag}: {tag}")
                referenced.add(fp)
                source = fp.read_text(encoding="utf-8")
                # Custom includes may declare shared helpers, but samplers belong
                # to each entry point so the JSON interface is unambiguous.
            else:
                source = ""
            ins = item.get("inputs", [])
            require(isinstance(ins, list) and bool(ins), f"missing inputs: {tag}")
            names = set()
            out = item.get("output", "")
            require(out == "minecraft:main" or out in targets, f"unknown output {out}: {tag}")
            for sample in ins:
                target = sample.get("target", "")
                name = sample.get("sampler_name", "")
                require(isinstance(name, str) and bool(re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", name)),
                        f"bad sampler name: {tag}")
                require(name not in names, f"duplicate sampler {name}: {tag}")
                names.add(name)
                require(target == "minecraft:main" or target in targets, f"unknown input {target}: {tag}")
                require(target != out, f"read-write target hazard: {target}: {tag}")
                require(target == "minecraft:main" or target in written or targets[target].get("persistent", False),
                        f"read before write: {target}: {tag}")
                if sample.get("use_depth_buffer"):
                    require(target == "minecraft:main", f"unproven depth source: {tag}")
                    require(sample.get("bilinear") is False, f"filtered depth source: {tag}")
                if source:
                    pattern = r"\buniform\s+sampler\w*\s+" + re.escape(name + "Sampler") + r"\s*;"
                    require(bool(re.search(pattern, source)), f"missing sampler {name}Sampler in {frag}: {tag}")
            if source:
                declared = set(re.findall(r"\buniform\s+sampler\w*\s+(\w+)\s*;", source))
                require(declared == {name + "Sampler" for name in names},
                        f"unbound sampler in {frag}: {tag}")
            if out != "minecraft:main":
                written.add(out)
            total += 1

    for shader in assets.glob("*/shaders/**/*.fsh"):
        source = shader.read_text(encoding="utf-8")
        stripped = re.sub(r"/\*.*?\*/|//[^\n]*", "", source, flags=re.DOTALL)
        require(stripped.lstrip().startswith("#version 330"), f"invalid version: {shader}")
        require(stripped.count("{") == stripped.count("}"), f"unbalanced braces: {shader}")
        require(bool(re.search(r"\bvoid\s+main\s*\(", stripped)), f"missing main: {shader}")
        require("#moj_import" not in source, f"old shader import syntax: {shader}")
        if shader.parent.name == "post" and shader.parent.parent.parent.name != "minecraft":
            require(shader in referenced, f"orphan fragment shader: {shader}")
        if shader.parent.name == "core":
            require(shader.parent.parent.parent.name == "minecraft" and shader.name in CORE_OVERRIDES,
                    f"unreviewed core override: {shader}")
    core = assets / "minecraft/shaders/core"
    require({p.name for p in core.glob('*.fsh')} == CORE_OVERRIDES,
            "missing sky/cloud renderer entry point")

    # Resolve all pack includes, and require a recorded contract for Vanilla ones.
    contract = json.loads((ROOT / "docs/V8_RENDERER_CONTRACT.json").read_text())
    for shader in assets.glob("*/shaders/**/*"):
        if not shader.is_file() or shader.suffix not in {".fsh", ".vsh", ".glsl"}:
            continue
        for namespace, name in re.findall(r"#include\s+<([a-z0-9_.-]+):([^>]+)>", shader.read_text()):
            require(".." not in name.split("/") and not name.startswith("/"), f"unsafe include: {shader}")
            local = assets / namespace / "shaders/include" / name
            vanilla = contract["files"].get("shaders/include/" + name, {})
            require(local.is_file() or (namespace == "minecraft" and "sha256" in vanilla),
                    f"missing include {namespace}:{name}: {shader}")

    if not quiet:
        print(f"PASS: {len(effects)} post-effects, {total} passes, {len(referenced)} referenced custom fragment shaders")
        print("Validation is static; ShaderC, depth-buffer behavior and visual quality require Minecraft 26.3.")
    return len(effects), total


if __name__ == "__main__":
    verify()

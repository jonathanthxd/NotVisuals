#!/usr/bin/env python3
"""Compile the five R20 edited fragment shaders against pinned 26.3 includes.

glslangValidator is a generic GLSL check, not Minecraft's ShaderC/runtime.
"""
from __future__ import annotations
import argparse
import json
import subprocess
import tempfile
from pathlib import Path
from shader_sources import ROOT, expand

def compile_edited(vanilla: Path, compiler: str = "glslangValidator"):
    changes = json.loads((ROOT / "docs/R20_CHANGESET.json").read_text(encoding="utf-8"))
    items = changes["modified_files"]
    if len(items) != 5:
        raise ValueError("Unexpected R20 edited shader count")
    with tempfile.TemporaryDirectory() as t:
        temp = Path(t) / "r20.frag"
        for name in items:
            shader = ROOT / "src" / "pack" / name
            source = expand(shader.read_text(encoding="utf-8"), vanilla)
            temp.write_text(source, encoding="utf-8")
            result = subprocess.run((compiler, "-S", "frag", str(temp)),
                                    capture_output=True, text=True)
            if result.returncode:
                raise RuntimeError(f"GLSL compile failure: {name}\n{result.stdout}\n{result.stderr}")
            print("PASS GLSL", name)
    print("PASS: 5 R20 edited fragment stages compiled (not in-game ShaderC)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vanilla-root", type=Path, default=Path("/tmp/notvisuals-26.3"))
    parser.add_argument("--compiler", default="glslangValidator")
    args = parser.parse_args()
    compile_edited(args.vanilla_root, args.compiler)

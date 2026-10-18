#!/usr/bin/env python3
"""Regression tests for the static pack graph and deterministic distribution."""
from __future__ import annotations

import json
import shutil
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

from build_pack import build
from validate_pack import ROOT, verify


class PackTests(unittest.TestCase):
    def test_current_graph(self):
        effects, passes = verify(quiet=True)
        self.assertGreaterEqual(effects, 4)
        self.assertGreaterEqual(passes, 25)

    def test_reject_unknown_input_and_missing_shader(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp)
            shutil.copytree(ROOT / "assets", source / "assets")
            shutil.copy2(ROOT / "pack.mcmeta", source / "pack.mcmeta")
            shutil.copy2(ROOT / "pack.png", source / "pack.png")
            auto = source / "assets/minecraft/post_effect/end_of_frame.json"
            graph = json.loads(auto.read_text(encoding="utf-8"))
            graph["passes"][0]["inputs"][0]["target"] = "does_not_exist"
            auto.write_text(json.dumps(graph), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "unknown input"):
                verify(source, quiet=True)
            graph["passes"][0]["inputs"][0]["target"] = "minecraft:main"
            graph["passes"][0]["fragment_shader"] = "notvisuals:post/not_found"
            auto.write_text(json.dumps(graph), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "missing fragment shader"):
                verify(source, quiet=True)

    def test_reproducible_zip_and_root(self):
        with tempfile.TemporaryDirectory() as temp:
            one = Path(temp) / "a.zip"
            two = Path(temp) / "b.zip"
            build(one)
            build(two)
            self.assertEqual(one.read_bytes(), two.read_bytes())
            with ZipFile(one) as arc:
                names = set(arc.namelist())
                self.assertIn("pack.mcmeta", names)
                self.assertIn("pack.png", names)
                self.assertIn("assets/minecraft/post_effect/end_of_frame.json", names)
                self.assertNotIn("README.md", names)
                self.assertFalse(any(name.startswith("scripts/") for name in names))
                self.assertIsNone(arc.testzip())


if __name__ == "__main__":
    unittest.main()

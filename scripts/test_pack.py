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

    def test_clouds_are_not_classified_by_white_world_pixels(self):
        graph = json.loads((ROOT / 'assets/minecraft/post_effect/end_of_frame.json').read_text())
        self.assertFalse(any('cloud' in name for name in graph['targets']))
        self.assertFalse(any(s['fragment_shader'].endswith('/cloud_extract') for s in graph['passes']))
        self.assertTrue((ROOT / 'assets/minecraft/shaders/core/clouds.fsh').is_file())

    def test_depth_remains_optional_and_point_sampled(self):
        auto = json.loads((ROOT / 'assets/minecraft/post_effect/end_of_frame.json').read_text())
        self.assertFalse(any(i.get('use_depth_buffer') for s in auto['passes'] for i in s['inputs']))
        for name in ['depth_lab', 'depth_ink']:
            effect = json.loads((ROOT / f'assets/notvisuals/post_effect/{name}.json').read_text())
            depth = [i for s in effect['passes'] for i in s['inputs'] if i.get('use_depth_buffer')]
            self.assertEqual(len(depth), 1)
            self.assertEqual(depth[0]['target'], 'minecraft:main')
            self.assertIs(depth[0]['bilinear'], False)

    def test_reject_filtered_depth_unbound_sampler_and_missing_include(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp)
            shutil.copytree(ROOT / 'assets', source / 'assets')
            for name in ['pack.mcmeta', 'pack.png']:
                shutil.copy2(ROOT / name, source / name)
            path = source / 'assets/notvisuals/post_effect/depth_lab.json'
            original = path.read_text()
            graph = json.loads(original)
            graph['passes'][0]['inputs'][1]['bilinear'] = True
            path.write_text(json.dumps(graph))
            with self.assertRaisesRegex(ValueError, 'filtered depth'):
                verify(source, quiet=True)
            path.write_text(original)
            frag = source / 'assets/notvisuals/shaders/post/depth_lab.fsh'
            original_frag = frag.read_text()
            frag.write_text(original_frag + '\nuniform sampler2D MissingSampler;\n')
            with self.assertRaisesRegex(ValueError, 'unbound sampler'):
                verify(source, quiet=True)
            frag.write_text(original_frag.replace('notvisuals:depth_edges.glsl', 'notvisuals:missing.glsl'))
            with self.assertRaisesRegex(ValueError, 'missing include'):
                verify(source, quiet=True)

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

#!/usr/bin/env python3
"""R20 scoped regression checks. These are NOT Minecraft in-game acceptance."""
from __future__ import annotations

import hashlib
import json
import re
import unittest
from pathlib import Path

from validate_r19 import ROOT, PACK, MANIFEST, R20_MANIFEST, verify


class R20Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.change = json.loads(R20_MANIFEST.read_text(encoding="utf-8"))
        cls.baseline = json.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.shader_dir = PACK / "assets/notvisuals/shaders/post"

    def test_five_explicit_overrides_and_no_new_shaders(self):
        self.assertEqual(len(self.change["modified_files"]), 6)
        self.assertEqual(len([k for k in self.change["modified_files"] if k.endswith(".fsh")]), 5)
        meta = json.loads((PACK / "pack.mcmeta").read_text(encoding="utf-8"))
        self.assertEqual(meta["pack"]["min_format"], [97, 1])
        self.assertEqual(meta["pack"]["max_format"], [97, 1])
        description = meta["pack"]["description"]
        self.assertIsInstance(description, dict)
        segments = description["extra"]
        self.assertEqual("".join(segment["text"] for segment in segments), "✦ NotVisuals v8\\ndiscord.gg/tflives")
        self.assertEqual(segments[1]["color"], "#F3FAFF")
        self.assertEqual(segments[2]["color"], "#B79DFF")
        self.assertEqual(segments[-1]["color"], "#55D8F2")
        self.assertEqual(verify(), (41, 41))
        for name, entry in self.change["modified_files"].items():
            data = (PACK / name).read_bytes()
            self.assertEqual(len(data), entry["size"])
            self.assertEqual(hashlib.sha256(data).hexdigest(), entry["sha256"])

    def test_marker_class_palette_unchanged(self):
        marker_root = PACK / "assets/notvisuals/textures/block/radiance"
        source = self.baseline["files"]
        for cls in range(1, 54):
            name = f"assets/notvisuals/textures/block/radiance/marker_{cls:02d}.png"
            data = (PACK / name).read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(), source[name]["sha256"], name)
        seeds = (self.shader_dir / "radiance_seeds.fsh").read_text()
        cleaner = (self.shader_dir / "radiance_marker_clean.fsh").read_text()
        for shader in (seeds, cleaner):
            self.assertIn("return cls<=53 ? cls : 0;", shader)
            self.assertIn("abs(b.g-76.0)>2.0", shader)
            self.assertIn("float local=round((b.b-16.0)/9.0);", shader)

    def test_pink_cleanup_requires_nearby_exact_id(self):
        shader = (self.shader_dir / "radiance_marker_clean.fsh").read_text()
        self.assertIn("if(!marker && nvFringeCandidate(c.rgb))", shader)
        self.assertIn("if(nvTag(texture(InSampler,uv)))", shader)
        self.assertIn("for(int y=-2;y<=2", shader)
        self.assertIn("if(!marker){fragColor=c;return;}", shader)

    def test_temporal_stays_depth_and_hue_guarded(self):
        source = (self.shader_dir / "radiance_temporal.fsh").read_text()
        self.assertIn("depthConfidence*colorConfidence", source)
        self.assertIn("float matchedOld=clamp(oldLen,curLen*0.72,curLen*1.36);", source)
        self.assertIn("float response=0.58*confidence;", source)
        self.assertIn("stabilized=current*(stableEnergy/max(curLen,0.000001));", source)

    def test_outline_and_celestial_still_preserve_pipeline(self):
        ink = (self.shader_dir / "inkline.fsh").read_text()
        sun = (PACK / "assets/minecraft/shaders/core/position_tex.fsh").read_text()
        self.assertIn("silhouette *= deepShadowGuard;", ink)
        self.assertIn("SKY_SHOW_SUN && onSun", sun)
        self.assertIn("solarCore*0.29+solarRim*0.21+solarOuter*0.039", sun)
        self.assertIn("lunarCore*0.22+lunarRim*0.16+lunarOuter*0.044", sun)
        pipeline = "assets/minecraft/post_effect/end_of_frame.json"
        current = (PACK / pipeline).read_bytes()
        self.assertEqual(hashlib.sha256(current).hexdigest(), self.baseline["files"][pipeline]["sha256"])

    def test_unchanged_mit_and_credit_notices(self):
        for name in ("LICENSES/ANIMATED_ORE_MIT.txt", "LICENSES/WATER_LILIES_MIT.txt",
                     "LICENSES/R18_ATTRIBUTION.md", "CREDITS.md", "LICENSE-ASSETS.md"):
            self.assertTrue((ROOT / name).is_file(), name)
        credits = (ROOT / "CREDITS.md").read_text()
        self.assertIn("masteirdixy", credits)
        self.assertIn("CC BY-NC-SA", credits)
        self.assertIn("GPLv3", credits)


if __name__ == "__main__":
    unittest.main()

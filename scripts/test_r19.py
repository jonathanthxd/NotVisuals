#!/usr/bin/env python3
"""R19 parity and deterministic ZIP tests."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile
from validate_r19 import MANIFEST, verify
from license_audit import check as check_licenses
from build_pack import build

class R19Tests(unittest.TestCase):
    def test_original_source_parity(self):
        self.assertEqual(verify(), (41, 41))
        self.assertEqual(check_licenses(release=True), [])

    def test_deterministic_redistributable_zip(self):
        with tempfile.TemporaryDirectory() as temp:
            one, two = Path(temp) / "first.zip", Path(temp) / "second.zip"
            build(one, release=True)
            build(two, release=True)
            self.assertEqual(hashlib.sha256(one.read_bytes()).hexdigest(), hashlib.sha256(two.read_bytes()).hexdigest())
            with ZipFile(one) as archive:
                self.assertIsNone(archive.testzip())
                names = set(archive.namelist())
                for name in ("pack.mcmeta", "pack.png", "CREDITS.md", "LICENSE", "LICENSE-CODE",
                             "LICENSE-ASSETS.md", "THIRD_PARTY_LICENSES.md", "LICENSES/ANIMATED_ORE_MIT.txt",
                             "LICENSES/WATER_LILIES_MIT.txt", "LICENSES/R18_ATTRIBUTION.md"):
                    self.assertIn(name, names)
                self.assertNotIn("src/pack/pack.mcmeta", names)
                for path, spec in json.loads(MANIFEST.read_text(encoding="utf-8"))["files"].items():
                    if path.startswith("LICENSES/") or path == "LEEME_R19.md":
                        continue
                    self.assertEqual(hashlib.sha256(archive.read(path)).hexdigest(), spec["sha256"], path)

if __name__ == "__main__":
    unittest.main()

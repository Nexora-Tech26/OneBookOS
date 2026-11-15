#!/usr/bin/env python3
"""Lightweight source-contract checks; NOT GUI, boot, installer or hardware tests."""
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


class FoundationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(
            (ROOT / "architecture/components.json").read_text(encoding="utf-8")
        )

    def test_manifest(self):
        data = self.manifest
        self.assertEqual(data["schema_version"], 1)
        self.assertEqual(data["stage"], 1)
        self.assertEqual(data["base_os"], "Ubuntu 24.04 LTS (amd64)")
        self.assertEqual(len(data["current_baselines"]), 2)
        self.assertEqual(len(data["planned_modules"]), 6)
        self.assertIn("pending", data["compositor_decision"])
        self.assertIn("pending", data["toolkit_decision"])

    def test_existing_baselines(self):
        for baseline in self.manifest["current_baselines"]:
            for key in ("path", "builder", "ci"):
                target = ROOT / baseline[key]
                with self.subTest(target=str(target)):
                    self.assertTrue(target.exists(), str(target))

    def test_document_references(self):
        for key in ("design_reference", "roadmap", "quality_gate"):
            target = ROOT / self.manifest[key]
            with self.subTest(target=str(target)):
                self.assertTrue(target.is_file())
                self.assertGreater(target.stat().st_size, 100)

    def test_sixteen_stages(self):
        text = (ROOT / self.manifest["roadmap"]).read_text(encoding="utf-8")
        for stage in range(1, 17):
            self.assertIn(f"| {stage:02d} |", text)

    def test_design_constraints(self):
        design = (ROOT / self.manifest["design_reference"]).read_text(encoding="utf-8").lower()
        for phrase in ("black capsule", "centered start", "right taskbar",
                       "squircle", "ten interactive widgets"):
            self.assertIn(phrase, design)

    def test_existing_wallpaper_svg(self):
        root = ET.parse(ROOT / "branding/wallpaper.svg").getroot()
        self.assertTrue(root.tag.endswith("svg"))

    def test_architecture_docs_exist(self):
        for filename in ("docs/architecture/OVERVIEW.md",
                         "docs/architecture/DECISIONS.md",
                         "docs/architecture/DEPENDENCIES.md", "CONTRIBUTING.md"):
            self.assertTrue((ROOT / filename).is_file())


if __name__ == "__main__":
    unittest.main()

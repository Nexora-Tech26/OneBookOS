#!/usr/bin/env python3
"""Stage 4 source-of-truth, asset generation and visual-contract tests."""
from pathlib import Path
import json
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "ui-kit"
TOKENS = json.loads((KIT / "tokens.json").read_text(encoding="utf-8"))


def rgb(value):
    return tuple(int(value[i:i + 2], 16) / 255 for i in (1, 3, 5))


def luminance(value):
    def linear(s):
        return s / 12.92 if s <= 0.04045 else ((s + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(value)
    return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)


def contrast(a, b):
    x, y = sorted((luminance(a), luminance(b)), reverse=True)
    return (x + 0.05) / (y + 0.05)


class DesignTests(unittest.TestCase):
    def test_color_contrast(self):
        c = TOKENS["colors"]
        self.assertGreaterEqual(contrast(c["text_on_dark"], c["shell_surface"]), 7)
        self.assertGreaterEqual(contrast(c["app_text"], c["app_surface"]), 7)
        self.assertGreaterEqual(contrast(c["panel_text"], c["panel_light"]), 7)
        self.assertGreaterEqual(contrast(c["text_on_dark"], c["notch_black"]), 7)

    def test_original_icon_inventory(self):
        names = TOKENS["required_icons"]
        self.assertEqual(len(names), 18)
        self.assertEqual(len(names), len(set(names)))
        for name in names:
            source = KIT / "icons" / (name + ".svg")
            self.assertTrue(source.is_file(), source)
            image = ET.parse(source).getroot()
            self.assertEqual(image.attrib.get("viewBox"), "0 0 64 64")
            self.assertTrue(any(n.attrib.get("rx") == "19" for n in image.iter()))

    def test_generative_assets_and_png_resolution(self):
        if not shutil.which("rsvg-convert"):
            self.skipTest("rsvg-convert required (CI installs it before tests)")
        with tempfile.TemporaryDirectory() as root:
            subprocess.run([sys.executable, str(KIT / "build.py"), "--root", root],
                           check=True, capture_output=True, text=True)
            prefix = Path(root)
            shell = (prefix / "usr/share/onebookos/design/shell.css").read_text()
            gtk = (prefix / "usr/share/themes/OneBookUI/gtk-3.0/gtk.css").read_text()
            window = (prefix / "usr/share/themes/OneBookUI/openbox-3/themerc").read_text()
            self.assertIn(TOKENS["colors"]["accent_blue"], shell)
            self.assertIn(TOKENS["colors"]["app_header"], gtk)
            self.assertIn(TOKENS["colors"]["app_text"], window)
            self.assertNotIn("{{", shell + gtk + window)
            for cls in ("dock-shell", "start", "clock", "notch", "menu", "desktop-label"):
                self.assertIn("." + cls, shell)
            for name in TOKENS["required_icons"]:
                png = (prefix / "usr/share/onebookos/icons" / (name + ".png")).read_bytes()
                self.assertEqual(png[:8], b"\x89PNG\r\n\x1a\n")
                self.assertEqual(struct.unpack(">II", png[16:24]), (256, 256))

    def test_shell_uses_the_generated_theme_not_inline_css(self):
        script = (ROOT / "onebookui/overlay/usr/local/bin/onebook-shell").read_text()
        self.assertIn('Path("/usr/share/onebookos/design/shell.css")', script)
        self.assertIn("css.load_from_path(str(THEME_CSS))", script)
        self.assertNotIn('CSS = """', script)

    def test_builder_no_longer_sources_legacy_gnome_icons(self):
        builder = (ROOT / "onebookui/build/build-iso.sh").read_text()
        self.assertIn('ui-kit/build.py" --root "$FS"', builder)
        self.assertNotIn('for source in "$ROOT/overlay/usr/share/gnome-shell', builder)
        self.assertIn('test -s "$FS/usr/share/onebookos/design/shell.css"', builder)

    def test_wallpaper_and_window_buttons(self):
        wp = ET.parse(ROOT / "branding/wallpaper.svg").getroot()
        self.assertTrue(wp.tag.endswith("svg"))
        # Stage 7 retains the original Stage 4 accent in the Night variant,
        # while Aurora Lavender becomes the new default.
        self.assertIn("#FF9CEF", (ROOT / "branding/wallpaper-night.svg").read_text())
        self.assertIn("#A9B9EF", (ROOT / "branding/wallpaper.svg").read_text())
        directory = ROOT / "onebookui/overlay/usr/share/themes/OneBookUI/openbox-3"
        for kind in ("close", "iconify", "max", "max_toggled"):
            for status in ("active", "inactive"):
                ET.parse(directory / (kind + "-" + status + ".svg"))

    def test_stage4_iso_identification(self):
        script = (ROOT / "display-engine/build-stage4-iso.sh").read_text()
        self.assertIn("ONEBOOK_VERSION_ID=0.1.4-stage4", script)
        self.assertIn("SHA256SUMS-stage4", script)


if __name__ == "__main__":
    unittest.main()

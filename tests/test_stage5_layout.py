#!/usr/bin/env python3
"""Stage 5 geometry and HiDPI source contracts. No GUI is required."""
import importlib.util
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "onebookui/overlay/usr/local/lib/onebookos/layout.py"
spec = importlib.util.spec_from_file_location("onebook_layout", LIB)
layout = importlib.util.module_from_spec(spec)
spec.loader.exec_module(layout)


class LayoutTests(unittest.TestCase):
    def test_start_exactly_centered(self):
        for width in (320, 360, 480, 640, 768, 800, 900, 950, 1024, 1280, 1366, 1440, 1920, 2560, 2880):
            with self.subTest(width=width):
                p = layout.compute_layout(width)
                self.assertLessEqual(p["start_center_error"], 0.5)
                self.assertEqual(p["start_x"], (width - p["start_width"]) // 2)

    def test_bars_not_touching_start_or_clock(self):
        for width in (320, 480, 640, 800, 1366, 1920, 2560, 2880):
            with self.subTest(width=width):
                p = layout.compute_layout(width)
                self.assertEqual(p["clock_x"] + p["clock_width"] + p["clock_margin"], width)
                if p["show_left"]:
                    self.assertLess(p["left_x"] + p["segment_width"], p["start_x"])
                if p["show_right"]:
                    self.assertGreater(p["right_x"], p["start_x"] + p["start_width"])
                    self.assertLess(p["right_x"] + p["segment_width"], p["clock_x"])

    def test_responsive_toolbar(self):
        self.assertTrue(layout.compute_layout(1366)["show_second_icon"])
        self.assertFalse(layout.compute_layout(768)["show_second_icon"])
        self.assertFalse(layout.compute_layout(480)["show_right"])
        self.assertTrue(layout.compute_layout(1920)["show_right"])
        with self.assertRaises(ValueError):
            layout.compute_layout(200)

    def test_shell_uses_separate_wayland_surfaces(self):
        shell = (ROOT / "onebookui/overlay/usr/local/bin/onebook-shell").read_text()
        self.assertIn('self.start_win = layer_window(', shell)
        self.assertIn('self.left_dock = layer_window(', shell)
        self.assertIn('self.right_dock = layer_window(', shell)
        self.assertNotIn('self.dock = layer_window(', shell)
        self.assertIn("GtkLayerShell.Edge.LEFT, positions[\"left_x\"]", shell)
        self.assertIn("GtkLayerShell.Edge.RIGHT, positions[\"clock_margin\"]", shell)
        self.assertIn("self.refresh_layout", shell)
        self.assertIn("onebook-layout.json", shell)
        self.assertIn("get_allocated_width()", shell)

    def test_greetd_graphical_qa_checks_live_geometry(self):
        guest = (ROOT / "onebookui/overlay/usr/local/bin/onebook-gui-autologin-smoke").read_text()
        self.assertIn('onebook-layout.json', guest)
        self.assertIn('start_center_error', guest)
        self.assertIn('clock_x', guest)
        self.assertIn('show_right', guest)

    def test_hidpi_uses_logical_units_not_bitmap_scaling(self):
        source = (ROOT / "onebookui/overlay/usr/local/bin/onebook-shell").read_text()
        self.assertIn("monitor.get_geometry().width", source)
        self.assertNotIn("GDK_SCALE=", source)
        self.assertIn("Pixbuf.new_from_file_at_scale", source)

    def test_window_controls_and_body_are_readable(self):
        tok = json.loads((ROOT / "ui-kit/tokens.json").read_text())
        dims = tok["dimensions"]
        self.assertGreaterEqual(dims["titlebar_height_px"], 42)
        self.assertGreaterEqual(dims["window_control_px"], 28)
        self.assertGreaterEqual(dims["app_body_font_px"], 14)
        self.assertGreaterEqual(dims["app_control_height_px"], 38)
        gtk = (ROOT / "ui-kit/templates/gtk.css.in").read_text()
        self.assertIn("{{app_body_font_px}}px", gtk)
        self.assertIn("{{app_control_height_px}}px", gtk)
        theme = (ROOT / "ui-kit/templates/themerc.in").read_text()
        self.assertIn("{{window_control_px}}", theme)
        shell = (ROOT / "ui-kit/templates/shell.css.in").read_text()
        self.assertIn(".start-shell", shell)
        self.assertIn(".dock-shell", shell)

    def test_new_iso_identification(self):
        code = (ROOT / "display-engine/build-stage5-iso.sh").read_text()
        self.assertIn("ONEBOOK_VERSION_ID=0.1.5-stage5", code)
        self.assertIn("SHA256SUMS-stage5", code)
        self.assertIn("OneBookOS-0.1.5-Layout-DeveloperPreview-amd64.iso", code)


if __name__ == "__main__":
    unittest.main()

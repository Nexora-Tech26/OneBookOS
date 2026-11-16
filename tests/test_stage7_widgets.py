#!/usr/bin/env python3
"""Stage 7 source and design checks; QEMU validates real rendered pixels."""
import ast
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
WIDGETS = ROOT / "onebookui/overlay/usr/local/bin/onebook-widgets"
SRC = WIDGETS.read_text(encoding="utf-8")


class Stage7Tests(unittest.TestCase):
    def test_source_compiles_and_six_widget_types(self):
        tree = ast.parse(SRC)
        self.assertIn('TYPES = ("clock", "weather", "calendar", "battery", "media", "system")', SRC)
        functions = {n.name for n in tree.body if isinstance(n, ast.FunctionDef)}
        self.assertTrue({"default_layout", "load_config", "save_config",
                         "cpu_snapshot", "memory_used", "battery_status"} <= functions)
        classes = {n.name for n in tree.body if isinstance(n, ast.ClassDef)}
        self.assertTrue({"Widget", "WidgetsDesktop"} <= classes)

    def test_real_data_and_persistence(self):
        for phrase in ('/proc/stat', '/proc/meminfo', '/sys/class/power_supply',
                       'playerctl', 'api.open-meteo.com', 'timeout=5',
                       'urllib.request.urlopen', 'GLib.idle_add',
                       'os.replace(temporary, CONFIG)',
                       'Gtk.GestureDrag.new(grip)', 'Gtk.Calendar()',
                       'GtkLayerShell.Layer.BOTTOM', 'def reset_layout(',
                       'def cycle_size(', 'def change_wallpaper('):
            self.assertIn(phrase, SRC)

    def test_original_wallpaper_is_valid_vector(self):
        for name in ("wallpaper.svg", "wallpaper-night.svg"):
            root = ET.parse(ROOT / "branding" / name).getroot()
            self.assertEqual(root.tag, "{http://www.w3.org/2000/svg}svg")
        aurora = (ROOT / "branding/wallpaper.svg").read_text(encoding="utf-8")
        self.assertIn("#A9B9EF", aurora)
        self.assertIn("#F7BEEB", aurora)

    def test_builder_installs_both_wallpapers_and_widgets(self):
        build = (ROOT / "onebookui/build/build-iso.sh").read_text()
        for entry in ("wallpaper-night.png", "onebook-widgets",
                      "onebook-widgets-smoke.service", "widgets.css"):
            self.assertIn(entry, build)
        auto = (ROOT / "onebookui/overlay/etc/xdg/labwc/autostart").read_text()
        self.assertIn("/usr/local/bin/onebook-widgets", auto)

    def test_actual_qemu_widget_screenshot_contract(self):
        qemu = (ROOT / "onebookui/build/test-qemu.sh").read_text()
        for item in ('widgets)', 'widgets-manager)', 'ONEBOOK_WIDGETS_QEMU_OK',
                     'OneBookUI-stage7-widgets-qemu.png',
                     'OneBookUI-stage7-customize-qemu.png'):
            self.assertIn(item, qemu)
        smoke = (ROOT / "onebookui/overlay/usr/local/bin/onebook-widgets-smoke").read_text()
        self.assertIn('onebook-widgets-layout.json', smoke)
        self.assertIn('ONEBOOK_WIDGETS_QEMU_OK', smoke)

    def test_isolated_process_does_not_replace_notch(self):
        shell = (ROOT / "onebookui/overlay/usr/local/bin/onebook-shell").read_text()
        self.assertIn("def create_notch(self):", shell)
        self.assertIn("def create_dock(self):", shell)
        self.assertIn("onebook-shell-guardian", (
            ROOT / "onebookui/overlay/etc/xdg/labwc/autostart"
        ).read_text())


if __name__ == "__main__":
    unittest.main()

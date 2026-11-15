#!/usr/bin/env python3
"""Static configuration tests only, not compositor run-time tests."""
from pathlib import Path
import configparser
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "onebookui"


class DisplayEngineTests(unittest.TestCase):
    def test_candidates_are_installed_in_preview(self):
        pkgs = (BASE / "build/base-packages.txt").read_text().splitlines()
        self.assertIn("labwc", pkgs)
        self.assertIn("wayfire", pkgs)

    def test_wayfire_config(self):
        cfg = configparser.ConfigParser(interpolation=None)
        cfg.read(BASE / "overlay/etc/xdg/wayfire.ini")
        for required in ("autostart", "animate", "foreign-toplevel"):
            self.assertIn(required, cfg["core"]["plugins"].split())
        self.assertEqual(cfg["animate"]["open_animation"], "fade")
        self.assertEqual(cfg["autostart"]["autostart_wf_shell"], "false")
        self.assertIn("/usr/local/bin/onebook-shell", cfg["autostart"]["shell"])

    def test_default_grub_is_still_labwc(self):
        grub = (BASE / "build/grub.cfg").read_text()
        self.assertIn("set default=0", grub)
        self.assertLess(grub.index("OneBookUI Desktop (Live)"),
                        grub.index("Wayfire compositor evaluation"))
        self.assertIn("obos.compositor=wayfire", grub)

    def test_session_selector_and_boot_test(self):
        session = (BASE / "overlay/usr/local/bin/onebook-session").read_text()
        self.assertIn("wayfire --config /etc/xdg/wayfire.ini", session)
        self.assertIn("exec dbus-run-session -- labwc", session)
        qemu = (BASE / "build/test-qemu.sh").read_text()
        self.assertIn("COMPOSITOR_ARG", qemu)
        self.assertIn("OneBookUI-wayfire-graphical-qemu.png", qemu)

    def test_build_guards(self):
        builder = (BASE / "build/build-iso.sh").read_text()
        self.assertIn("/usr/bin/wayfire", builder)
        self.assertIn('test -s "$FS/etc/xdg/wayfire.ini"', builder)


if __name__ == "__main__":
    unittest.main()

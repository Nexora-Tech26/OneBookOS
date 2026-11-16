#!/usr/bin/env python3
"""Notch, real command wiring, app selection and corner-mismatch regression checks."""
from pathlib import Path
import ast
import configparser
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
O = ROOT / "onebookui/overlay"
SHELL = (O / "usr/local/bin/onebook-shell").read_text(encoding="utf-8")


class Stage6Tests(unittest.TestCase):
    def test_shell_ast_compiles(self):
        tree = ast.parse(SHELL)
        methods = next(node for node in tree.body if isinstance(node, ast.ClassDef) and node.name == "Desktop")
        names = [n.name for n in methods.body if isinstance(n, ast.FunctionDef)]
        for needed in ("create_notch", "refresh_notch_info", "open_notch", "close_notch",
                       "toggle_wifi", "toggle_bluetooth", "preview_notch_for_qa"):
            self.assertIn(needed, names)
        self.assertEqual(names.count("create_notch"), 1)

    def test_has_six_real_tab_pages_and_compact_notch(self):
        self.assertIn('closed.set_size_request(132, 24)', SHELL)
        self.assertIn("Gtk.StackSwitcher()", SHELL)
        self.assertIn("Gtk.StackTransitionType.SLIDE_LEFT_RIGHT", SHELL)
        for identifier in ("status", "media", "controls", "connections", "devices", "notifications"):
            self.assertIn('self.hub_pages.add_titled(', SHELL)
            self.assertRegex(SHELL, r'self\.hub_pages\.add_titled\([^\n]+, "'+identifier+'"')
        self.assertIn('GtkLayerShell.Edge.TOP', SHELL)
        self.assertIn("notify::visible-child-name", SHELL)
        self.assertIn("self.notch_pinned", SHELL)

    def test_controls_are_real(self):
        for command in ('["nmcli", "radio", "wifi"', '["bluetoothctl", "power",',
                        '["wpctl", "set-mute"', '["brightnessctl", "set"',
                        '["playerctl", "play-pause"]',
                        '["makoctl", "list"]', '["notify-send",',
                        '["xfce4-settings-manager"]'):
            self.assertIn(command, SHELL)
        self.assertIn("self.brightness.set_sensitive(False)", SHELL)
        self.assertIn("self.bt_toggle.set_sensitive(available)", SHELL)

    def test_standard_apps_and_notifications_in_package_manifest(self):
        packages = (ROOT / "onebookui/build/base-packages.txt").read_text().splitlines()
        for app in ("xfce4-settings", "xfce4-taskmanager", "pavucontrol", "blueman",
                    "galculator", "ristretto", "playerctl", "mako-notifier", "libnotify-bin"):
            self.assertIn(app, packages)
        for app in ("xfce4-settings-manager", "xfce4-taskmanager", "pavucontrol", "blueman-manager",
                    "galculator", "ristretto", "mako"):
            self.assertIn("/usr/bin/" + app, (ROOT / "onebookui/build/build-iso.sh").read_text())
        autostart = (O / "etc/xdg/labwc/autostart").read_text()
        self.assertIn("mako >", autostart)
        self.assertTrue((O / "etc/xdg/mako/config").is_file())
        self.assertIn('("settings", "Settings", ["xfce4-settings-manager"])', SHELL)

    def test_safe_rounded_corners_use_consistent_opaque_colors(self):
        rc = ET.parse(O / "etc/xdg/labwc/rc.xml").getroot()
        self.assertIn(rc.findtext("./theme/cornerRadius"), ("8", "10"))
        gtk = (ROOT / "ui-kit/templates/gtk.css.in").read_text()
        self.assertIn("decoration { background-color: {{app_surface}}", gtk)
        theme = (ROOT / "ui-kit/templates/themerc.in").read_text()
        self.assertIn("window.active.shadow.size: 0", theme)
        self.assertIn("window.inactive.shadow.size: 0", theme)

    def test_qemu_boots_expanded_notch_and_apps(self):
        test = (ROOT / "onebookui/build/test-qemu.sh").read_text()
        self.assertIn("obos.notch-test=1", test)
        self.assertIn("ONEBOOK_NOTCH_QEMU_OK", test)
        self.assertIn("OneBookUI-dynamic-notch-qemu.png", test)
        service = (O / "etc/systemd/system/onebook-notch-smoke.service").read_text()
        self.assertIn("ConditionKernelCommandLine=obos.notch-test=1", service)
        build = (ROOT / "onebookui/build/build-iso.sh").read_text()
        self.assertIn("onebook-notch-smoke.service", build)
        self.assertIn("onebook-notch-ready", SHELL)

    def test_new_iso_version(self):
        data = (ROOT / "display-engine/build-stage6-iso.sh").read_text()
        self.assertIn("ONEBOOK_VERSION_ID=0.1.6-stage6", data)
        self.assertIn("SHA256SUMS-stage6", data)
        self.assertIn("OneBookOS-0.1.6-DynamicNotch-DeveloperPreview-amd64.iso", data)


if __name__ == "__main__":
    unittest.main()

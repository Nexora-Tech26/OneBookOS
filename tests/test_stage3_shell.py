#!/usr/bin/env python3
"""Stage 3 static checks and supervisor subprocess test; no GPU assumed."""
import configparser
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OVERLAY = ROOT / "onebookui/overlay"
BIN = OVERLAY / "usr/local/bin"


class Stage3Tests(unittest.TestCase):
    def test_both_compositors_start_guardian(self):
        labwc = (OVERLAY / "etc/xdg/labwc/autostart").read_text()
        cfg = configparser.ConfigParser(interpolation=None)
        cfg.read(OVERLAY / "etc/xdg/wayfire.ini")
        self.assertIn("/usr/local/bin/onebook-shell-guardian", labwc)
        self.assertEqual(cfg["autostart"]["shell"], "/usr/local/bin/onebook-shell-guardian")
        self.assertIn("autostart", cfg["core"]["plugins"].split())

    def test_window_shortcuts(self):
        tree = ET.parse(OVERLAY / "etc/xdg/labwc/rc.xml")
        keys = {}
        for item in tree.getroot().findall("./keyboard/keybind"):
            keys[item.attrib["key"]] = [(a.attrib.get("name"), a.attrib.get("direction"))
                                         for a in item.findall("action")]
        self.assertIn(("Close", None), keys["A-F4"])
        self.assertIn(("ToggleMaximize", None), keys["W-Up"])
        self.assertIn(("Iconify", None), keys["W-Down"])
        self.assertIn(("SnapToEdge", "left"), keys["W-Left"])
        self.assertIn(("SnapToEdge", "right"), keys["W-Right"])

    def test_boot_and_recovery_configuration(self):
        qemu = (ROOT / "onebookui/build/test-qemu.sh").read_text()
        self.assertIn("obos.recovery-test=1", qemu)
        self.assertIn("ONEBOOK_SHELL_RECOVERY_OK", qemu)
        builder = (ROOT / "onebookui/build/build-iso.sh").read_text()
        self.assertIn("onebook-shell-recovery-smoke.service", builder)
        self.assertIn("onebook-shell-guardian", builder)
        self.assertTrue((BIN / "onebook-shell-recovery-smoke").is_file())

    def test_guardian_crash_loop_safe_mode(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            failing_shell = home / "failing-shell"
            failing_shell.write_text("#!/bin/sh\nexit 70\n", encoding="utf-8")
            failing_shell.chmod(0o700)
            environment = dict(os.environ, XDG_RUNTIME_DIR=str(home))
            ready = home / "onebook-shell-ready"
            ready.write_text("old and invalid\n", encoding="utf-8")
            process = subprocess.Popen([
                sys.executable, str(BIN / "onebook-shell-guardian"),
                "--shell", str(failing_shell), "--max-failures", "2",
                "--window", "8", "--retry-delay", "0.05", "--no-fallback"
            ], env=environment, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            try:
                deadline = time.monotonic() + 10
                while not (home / "onebook-shell-safe-mode").exists() and time.monotonic() < deadline:
                    time.sleep(0.1)
                self.assertTrue((home / "onebook-shell-safe-mode").exists())
                self.assertEqual((home / "onebook-shell-guardian-state").read_text().strip(), "safe-mode")
                self.assertFalse(ready.exists(), "A stale ready marker must not survive a crash")
                status = subprocess.run(
                    [sys.executable, str(BIN / "onebook-shell-recover"), "status"],
                    env=environment, check=True, capture_output=True, text=True)
                self.assertIn("Safe mode: enabled", status.stdout)
                subprocess.run([sys.executable, str(BIN / "onebook-shell-recover"), "resume"],
                               env=environment, check=True, capture_output=True)
                self.assertFalse((home / "onebook-shell-safe-mode").exists())
            finally:
                process.terminate()
                process.wait(timeout=5)

    def test_stage3_iso_version(self):
        script = (ROOT / "display-engine/build-stage3-iso.sh").read_text()
        self.assertIn("ONEBOOK_VERSION_ID=0.1.3-stage3", script)
        self.assertIn("SHA256SUMS-stage3", script)
        self.assertIn("OneBookOS-0.1.3-OneBookShell-DeveloperPreview-amd64.iso", script)


if __name__ == "__main__":
    unittest.main()

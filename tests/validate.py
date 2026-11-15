#!/usr/bin/env python3
"""Static validation for OBOS desktop executables and branding."""
import ast
import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
executables = sorted((root / "overlay/usr/local/bin").glob("obos-*"))
if not executables:
    raise SystemExit("No OBOS executables found")

for file in executables:
    source = file.read_text(encoding="utf-8")
    shebang = source.splitlines()[0] if source else ""
    if "python" in shebang:
        ast.parse(source, filename=str(file))
        print(f"Python OK: {file.relative_to(root)}")
    elif "bash" in shebang:
        subprocess.run(["bash", "-n", str(file)], check=True)
        print(f"Bash OK: {file.relative_to(root)}")
    else:
        raise SystemExit(f"Unknown executable interpreter: {file}")

extension_root = root / "overlay/usr/share/gnome-shell/extensions/onebookos@nexora.tech"
metadata = json.loads((extension_root / "metadata.json").read_text(encoding="utf-8"))
assert metadata["uuid"] == "onebookos@nexora.tech"
assert "46" in metadata["shell-version"]
assert (extension_root / "extension.js").is_file()
assert (extension_root / "stylesheet.css").is_file()
assert (extension_root / "icons/onebook.svg").is_file()
source = (extension_root / "extension.js").read_text(encoding="utf-8")
assert "_buildMenu()" in source, "Native Start menu is missing"
assert "_revertToGnome()" in source, "GNOME recovery fallback missing"
assert "Main.panel.show()" in source, "The stock GNOME panel cannot be restored"
assert "catch (error)" in source, "GNOME widget errors are not contained"
assert "Shell.BlurEffect" not in source, "Potentially unstable blur shader was reintroduced"
assert "Main.overview.showApps()" not in source, "Start must not use GNOME app grid"
# OneBookOS 0.2 intentionally disables the experimental compositor shader
# because a GNOME Shell crash takes down the entire desktop session.
# Require the stable translucent styling; do not demand the unsafe blur.
stylesheet = (extension_root / "stylesheet.css").read_text(encoding="utf-8")
assert "rgba(" in stylesheet, "Translucent desktop surfaces are missing"
assert "_blur(" in source, "Compatibility path for optional visual effects is missing"
for icon in ["onebook", "files", "settings", "terminal", "store", "calculator", "notes", "monitor", "photos", "controls", "power"]:
    ET.parse(extension_root / "icons" / f"{icon}.svg")
for file in sorted((root / "branding").glob("*.svg")):
    ET.parse(file)
    print(f"SVG OK: {file.relative_to(root)}")

print("OneBookOS static validation passed")

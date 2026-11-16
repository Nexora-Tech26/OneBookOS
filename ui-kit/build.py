#!/usr/bin/env python3
"""Generate OneBookUI GTK3, labwc and Wayland-shell assets from one token source.

Supports reproducible ISO builds. Does not overwrite development source files.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
VARIABLE = re.compile(r"\{\{([a-z][a-z0-9_]*)\}\}")
HEX_COLOR = re.compile(r"#[0-9A-Fa-f]{6}\Z")
TARGETS = {
    "shell.css.in": "usr/share/onebookos/design/shell.css",
    "gtk.css.in": "usr/share/themes/OneBookUI/gtk-3.0/gtk.css",
    "themerc.in": "usr/share/themes/OneBookUI/openbox-3/themerc",
}


def load_tokens():
    tokens = json.loads((HERE / "tokens.json").read_text(encoding="utf-8"))
    assert tokens["schema_version"] == 1
    colors = tokens["colors"]
    assert colors and all(HEX_COLOR.fullmatch(v) for v in colors.values())
    dimensions = tokens["dimensions"]
    assert all(isinstance(value, int) and value > 0 for value in dimensions.values())
    names = tokens["required_icons"]
    assert len(names) == len(set(names)) and len(names) >= 15
    assert all(re.fullmatch(r"[a-z][a-z0-9-]*", name) for name in names)
    return tokens


def render_templates(tokens, target_root):
    values = {**tokens["colors"], **tokens["dimensions"]}
    for name, target in TARGETS.items():
        template = (HERE / "templates" / name).read_text(encoding="utf-8")
        required = set(VARIABLE.findall(template))
        unknown = required - values.keys()
        if unknown:
            raise ValueError(f"{name} has undefined tokens: {sorted(unknown)}")
        content = VARIABLE.sub(lambda found: str(values[found.group(1)]), template)
        if "{{" in content or "}}" in content:
            raise ValueError(f"{name}: unresolved placeholder")
        output = target_root / target
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(content, encoding="utf-8")
        if not output.stat().st_size:
            raise ValueError(f"Empty generated asset: {name}")


def build_icons(tokens, target_root):
    directory = target_root / "usr/share/onebookos/icons"
    directory.mkdir(parents=True, exist_ok=True)
    expected = set(tokens["required_icons"])
    present = {p.stem for p in (HERE / "icons").glob("*.svg")}
    if present != expected:
        raise ValueError(f"Icon mismatch: missing={sorted(expected - present)}, extra={sorted(present - expected)}")
    for name in sorted(expected):
        source = HERE / "icons" / (name + ".svg")
        image = ET.parse(source).getroot()
        if not image.tag.endswith("svg") or image.get("viewBox") != "0 0 64 64":
            raise ValueError(f"{source}: SVG viewBox must be 0 0 64 64")
        for node in image.iter():
            if node.tag.rsplit("}", 1)[-1] in {"script", "image", "foreignObject"}:
                raise ValueError(f"{source}: external assets and executable SVG are prohibited")
        (directory / source.name).write_bytes(source.read_bytes())
        result = directory / (name + ".png")
        subprocess.run([
            "rsvg-convert", "-w", str(tokens["dimensions"]["icon_raster_px"]),
            "-h", str(tokens["dimensions"]["icon_raster_px"]),
            str(source), "-o", str(result),
        ], check=True, capture_output=True, text=True)
        if result.stat().st_size < 500:
            raise ValueError(f"Icon raster unexpectedly small: {name}")


def build(destination):
    tokens = load_tokens()
    render_templates(tokens, destination)
    build_icons(tokens, destination)
    return tokens


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, help="Root of target ISO rootfs")
    parser.add_argument("--check", action="store_true", help="Generate and validate in temporary directory")
    args = parser.parse_args()
    if args.check == bool(args.root):
        parser.error("Specify exactly one of --root or --check")
    if args.check:
        with tempfile.TemporaryDirectory() as temp:
            tokens = build(Path(temp))
            print(f"Validated OneBookUI 8: {len(tokens['required_icons'])} original vector icons")
    else:
        tokens = build(args.root.resolve())
        print(f"Generated OneBookUI GTK3/labwc/shell assets and {len(tokens['required_icons'])} icons")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import ast
from pathlib import Path
import xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
for file in (root/"overlay/usr/local/bin").glob("obos-*"):
 ast.parse(file.read_text(),filename=str(file))
for file in (root/"branding").glob("*.svg"):
 ET.parse(file)
print("Static tests passed")

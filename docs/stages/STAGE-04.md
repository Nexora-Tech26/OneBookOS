# Stage 04/16 — OneBookUI 8 Design System

**Prototype:** OneBookOS 0.1.4 — Design System Developer Preview (Ubuntu 24.04 LTS Live ISO, no installer).

## Implemented design elements
- One versioned token source: `ui-kit/tokens.json` (palette, radius, metrics, motion guidance).
- Shared generated shell CSS, GTK3 app theme and labwc server-decoration colors, produced by `ui-kit/build.py` at ISO build time.
- 18 original scalable squircle SVG icons (and 256x256 raster fallback for consumers). These are **independent artwork**, not Samsung/Apple proprietary icons.
- New dark indigo, blue, lavender and magenta wallpaper using SVG curves; rendered at 3840x2160 in the live ISO.
- Updated native window action vector glyphs for close, minimize, maximize/restore.
- Existing OneBook Shell now loads an external generated stylesheet; colors and common components are no longer copied as inline Python CSS.
- Existing layout, session recovery and compositor tests remain to prevent regressions.

## Scope and limitations
- The Stage 4 UI is still built from experimental GTK3/gtk-layer-shell. It is **not** yet a Qt/QML rewritten desktop.
- The full compact three-part taskbar and precise clock and Start positioning belong to Stage 5.
- The black Dynamic Notch tab system and full motion engine belong to Stages 6–7; current notch only retains existing baseline behavior.
- Existing third-party apps can retain their own icon branding and non-GTK themes. This stage does not promise universal application theming.
- GTK4/libadwaita and Qt apps will need separate integration work.
- Blur may be disabled for performance and session stability; do not claim compositor blur unless tested.

## Source check (no ISO)
```bash
python3 ui-kit/build.py --check
python3 -m unittest discover -s tests -p test_stage4_design.py -v
```

## Build (Ubuntu 24.04 amd64)
```bash
sudo bash onebookui/build/install-deps.sh
sudo bash display-engine/build-stage4-iso.sh
```

The GitHub workflow builds the ISO and runs labwc headless, graphical screenshot and shell-restart tests. A green CI is **not** proof the UI matches the approved mockup. Human review of the actual QEMU screenshot, window geometry and icon sharpness is required before marking visual acceptance.

**Safety:** Live ISO only; no hard-drive installer. Prefer QEMU. Wayfire remains optional and unverified until its independent test succeeds.

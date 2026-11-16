# Stage 07/17 — Wallpaper & Widgets

**Developer Preview:** OneBookOS 0.1.7 based on Ubuntu 24.04 LTS.

## Actual implementation

- Original 3840 × 2160 Aurora Lavender vector/raster wallpaper, inspired by soft
  One UI pastel blues/lavenders/pinks; optional previous darker Night wallpaper.
- GTK3 and gtk-layer-shell desktop widgets run in an independent Wayland process
  (not embedded into the Stage 6 Notch/Start process). A widget error must not
  crash the main shell.
- Six interactive cards with real sources: clock/date (system time), weather
  (Open-Meteo, configured Tczew location; explicit offline state), calendar
  (navigable GTK calendar), battery (Linux power_supply), media (MPRIS playerctl),
  and CPU/RAM (Linux procfs).
- Top-right **Widgets** button opens a manager to show/hide each card, switch
  wallpaper and reset the layout.
- Drag each card by its heading; click the resize control to cycle through small,
  medium and large widths; close a card to hide it and restore it in the manager.
- Positions, visibility, size and wallpaper choice persist across restarts in
  ~/.config/onebookos/widgets.json, written with an atomic replace.
- Cards default to two columns on wide monitors, one column on compact displays.
  The user can adjust placements. Values are never fabricated when hardware,
  media player or weather connection is absent.
- The wallpaper is drawn by swaybg, without a claimed blur compositor. The
  translucent cards use ordinary GTK alpha blending and CSS shadows.

## QA contract

- Static tests for widget boundaries, wallpaper SVG validity, runtime data
  sources and persistence.
- Stage 1–6 regression tests.
- Boot the real ISO in QEMU with a dedicated widgets smoke service, checking
  the running compositor, separate widget process and six-card layout JSON.
- Capture real QEMU graphics for the default desktop and for the visible
  customization panel. Legacy Notch and shell recovery QEMU regressions remain.
- No claim of hardware-accelerated blur, 60 FPS, device-battery data inside a
  VM, successful online weather in offline mode or final Galaxy Book support.

## Known follow-ups

- Existing Xfce/temporary Ubuntu applications sometimes fail after in-app clicks.
  Investigate and fix that separately; do not misrepresent it as solved.
- Advanced widget API, deep personalization, animated transitions and application
  integration remain part of Stages 8–10.
- This is a Live ISO developer preview, not a tested disk installer.

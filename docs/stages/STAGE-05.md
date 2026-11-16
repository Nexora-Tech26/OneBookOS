# OneBookOS — Stage 05/16: Start, taskbars, clock and readable windows

## Changed

- The bottom dock is no longer a single connected strip. Left taskbar, right taskbar, central Start and far-right clock use separate layer-shell surfaces.
- The Start surface has only a BOTTOM anchor, so Wayland centers it independently of running apps, pinned buttons and the clock.
- Left/right taskbar positions come from a pure logical-pixel geometry function; each surface gets its own dynamic LEFT margin.
- At logical display widths under 950 px, secondary icons are hidden. At very narrow widths the right bar is hidden to prevent collision with the right clock.
- The clock is independently anchored to BOTTOM+RIGHT, and its dimensions and font are larger.
- GTK3 app body font is 14 logical px, titlebar 44 px, native window control target 30 px, buttons min-height 38 px; field controls and list content are larger.
- Shell publishes a JSON layout report with runtime allocated widget sizes. The normal graphical QEMU test verifies center alignment, right edge anchoring and no overlap.
- Styling is generated from the Stage 4 token system; original SVG icons are retained.

## Guarantees and limits

- The coordinate calculations are tested against 320–2880 logical pixel widths; these are not equivalent to physical HiDPI rendering tests.
- A green QEMU test proves shell launch, programmatic window-size report and framebuffer capture on the tested virtual display, not pixel-perfect reference compliance.
- GTK3 apps use the common theme. Qt, GTK4/libadwaita and legacy XWayland apps can retain smaller controls; those need their own application integration and visual QA.
- Multi-monitor selection currently targets the compositor's primary monitor. True per-monitor taskbars and mixed-DPI testing are planned for hardware/integration stages.
- Stage 6 handles the full Dynamic Notch and Stage 7 introduces the broader animation engine.
- This is an experimental **Live ISO without installer**; don't install it over a drive containing personal data.

## Acceptance

- Source tests; runtime geometry report after the shell is visible.
- ISO build and SHA-256 validation.
- Labwc headless QEMU, graphical QEMU plus screenshot, recovery regression.
- Manual visual comparison and real HiDPI verification are still required prior to visual acceptance.

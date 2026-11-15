# OneBookOS Part 2 — compositor baseline
The compositor remains **Ubuntu 24.04 labwc 0.7.1** on Wayland/wlroots; it is **not** a new Rust/Smithay compositor. No proprietary compositor or real blur has been implemented.

## Functional compositor configuration
- Built-in labwc mouse behavior, focus, window moves/resizes, Alt+Tab and reverse cycling.
- Super+Left/Right window snapping, Super+Up maximize, four workspaces via Super+1..4.
- Super+Shift+1..4 moves windows between workspaces; media/Fn volume and brightness shortcuts.
- Native Wayland applications plus on-demand XWayland for legacy X11 software.
- `onebook-display --list` enumerates output connectors. Without arguments, the only automatic mode change is **an advertised** 1920×1080 in VMs, or 1.5 scaling for an eDP panel advertising 2880×1800. External monitors are not forced to inappropriate modes.
- Manual: `onebook-display --output eDP-1 --scale 1.5`; an unsupported `--mode` is rejected.

## CI acceptance
Graphical QEMU now opens real `foot`, `xterm` (XWayland), `thunar` and `mousepad` and fails unless their processes, XWayland and the OneBook shell stay alive. This is stricter than a process-only shell smoke check, but does **not** certify pixel quality or actual interaction.

## Not complete
GPU acceleration, blur, touch gestures, multi-monitor hotplug, high-DPI on Galaxy Book4 Pro, and consistent visual quality all remain unverified on physical hardware. The system is still an experimental Live ISO, not a safe OS replacement.

## Real screenshot QA

The QEMU `graphical` test now captures the virtual GPU framebuffer through QEMU's HMP `screendump`, checks that the image is at least 800×600 and not near-monochrome, and publishes `OneBookUI-graphical-qemu.png`. The `OneBookUI-Part2-compositor-QA` artifact contains screenshot and guest logs, even if the compositor test fails. This **does not** validate text sharpness, window aesthetics, GPU performance, touch or blur; the screenshot must be reviewed by a human. The ISO artifact is uploaded only after graphical and headless tests pass.

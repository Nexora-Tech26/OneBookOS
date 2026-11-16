# Stage 06/17 — Dynamic Notch and practical starter applications

**Build:** OneBookOS 0.1.6 DynamicNotch Developer Preview — experimental Live ISO.

## Dynamic Notch

- The closed top-center black capsule has no text. When hovered, it expands into one integrated GTK3 layer surface.
- Six tabs: Status, Media, Controls, Network, Devices and Alerts. Pin/unpin keeps the hub open. A compact 112×22 px closed capsule expands to a width-constrained panel. A responsive 6-column (3-column on narrow displays) tab grid prevents oversized panels; the active tab stays synchronized with the GTK stack.
- Real integrations: NetworkManager via nmcli (Wi-Fi), BlueZ via bluetoothctl (Bluetooth), PipeWire via wpctl (volume/mute), brightnessctl, playerctl for compatible MPRIS media, kernel battery data and Mako notifications.
- UI disables controls when backlight or Bluetooth hardware cannot be detected. It never generates fake values.
- Notch updates only its active tab every 5 seconds. The animation uses GTK Revealer and Stack; compositor-level blur is not claimed.
- An additional QEMU boot mode opens the expanded Notch to its Controls page, starts Mako and standard Settings/Task Manager/Sound windows, and captures the actual display framebuffer.

## Interim Ubuntu applications

Thunar Files, foot Terminal, Mousepad Notes, Xfce Settings Manager, Xfce Task Manager, Pavucontrol, Blueman, Galculator and Ristretto. Native OneBookOS replacements still belong to later stages. Some Xfce Settings panels are X11-specific and cannot change Wayland display configuration; a separate Display (Wayland) entry shows current monitors.

## Window corner correction

The older labwc compositor may show color artifacts around semi-transparent rounded SSD corners. This preview aligns opaque titlebar/corner colors and disables labwc shadow paint at corners, preserving a modest 8px top radius. True translucent blurred titlebars remain an explicit compositor-level feature to evaluate later.

## Verification and limits

- Unit tests and regression checks from stages 1–5.
- ISO/GRUB/SHA256.
- Mandatory labwc headless/normal graphical/expanded Notch/forced shell crash recovery QEMU checks.
- Real QEMU screenshots are not aesthetic approval and do not certify HiDPI, multi-monitor setups or hardware.
- Wayfire remains experimental and is not used for acceptance until its existing QEMU failure is resolved.
- No disk installer; do not install over valuable data.

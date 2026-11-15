# Dependency baseline — stage 1

This file describes existing repository dependencies. No new runtime dependencies are added in this stage.

| Subsystem | Current experimental Wayland preview |
| --- | --- |
| Operating system | Ubuntu 24.04 LTS amd64, systemd, Casper |
| Session and compositor | greetd, labwc, Wayland, XWayland |
| Shell toolkit | Python 3, GTK3, gtk-layer-shell |
| Graphics | Mesa, hardware acceleration depends on GPU and drivers |
| Sound | PipeWire, WirePlumber |
| Networking and Bluetooth | NetworkManager, BlueZ |
| Energy and brightness | UPower, brightnessctl where supported |
| Temporary default apps | Thunar, foot, Mousepad |
| Image pipeline | debootstrap, squashfs, xorriso, GRUB, QEMU |

The maintained package inventory is onebookui/build/base-packages.txt.

**Pending stage-2 decision:** compare labwc and another viable Wayland compositor, plus compatible shell toolkits. Qt6/QML, Rust and compositor-level animation systems are candidates, not implemented deliverables. Choose using measurements and integration tests rather than marketing claims.

# OneBookUI — native Wayland preview

This directory starts a separate **non-GNOME** OneBookOS Live ISO built on Ubuntu 24.04 LTS.

**Architecture:** Ubuntu Noble + labwc (wlroots-based Wayland compositor), greetd Live session login, custom GTK3/gtk-layer-shell OneBook shell, Casper, SquashFS, GRUB BIOS/UEFI. The application launcher enumerates real installed desktop files; network, volume and brightness are backed by real Linux services. It reuses original OneBookOS SVG assets from the older GNOME alpha, but does not install GNOME Shell.

**Important:** This is a native Wayland *preview*, not a completed OneBookOS distribution. labwc is an existing compositor rather than a bespoke Rust/Smithay OneBook compositor. GTK3 is an initial shell implementation, not the intended final Qt/QML UI Kit. Visual blur, comprehensive animations, touch adaptation, complete apps, authenticated installed-system login, installer, storage tools, Galaxy Book integration, full notch integration, secure updates and Release ISO are NOT complete or verified.

## Build on Ubuntu 24.04 amd64

```bash
sudo bash onebookui/build/install-deps.sh
sudo bash onebookui/build/build-iso.sh
bash onebookui/build/test-qemu.sh dist/OneBookOS-OneBookUI-0.3-preview-amd64.iso
```

GitHub Actions runs the same steps and publishes an artifact **only after successful build, ISO verification and QEMU smoke test**.

## QEMU test scope

The test boots the **actual Casper ISO** in QEMU. Its GRUB test entry sets `obos.test=1`, which activates the headless wlroots backend *inside the guest*. The check requires a running labwc compositor, a real Wayland socket, a native GTK layer-shell process and 35 seconds of process stability. It cannot prove graphics output on DRM hardware, interactive input, the disk installer, or visual quality. Real-device and interactive QEMU tests remain necessary before release.

## Source-of-truth work plan

The 12-part master prompt remains the roadmap, not a claim that every feature works. Keep this pipeline experimental until its smoke test and real UI inspection pass. The earlier GNOME ISO workflow is retained separately as a recovery baseline.

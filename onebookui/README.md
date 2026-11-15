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

The test extracts the kernel and initrd **from the built ISO** and passes `obos.test=1` explicitly to QEMU's direct-kernel boot, while mounting the actual ISO as its Casper live medium. This keeps the normal ISO's GRUB default interactive. The GRUB BIOS/UEFI boot catalog is verified separately with xorriso. The check requires a running labwc compositor, a real Wayland socket, a native GTK layer-shell process and 35 seconds of process stability. It cannot prove graphics output on DRM hardware, interactive input, the disk installer, or visual quality. Real-device and interactive QEMU tests remain necessary before release.

## Source-of-truth work plan

The 12-part master prompt remains the roadmap, not a claim that every feature works. Keep this pipeline experimental until its smoke test and real UI inspection pass. The earlier GNOME ISO workflow is retained separately as a recovery baseline.

## Headless QEMU session reliability

With `obos.test=1`, systemd skips greetd (which can compete with `getty@tty1` on the CI virtual console) and starts the **same** OneBook session launcher through `onebook-headless.service`, as user `obos` with its own `RuntimeDirectory`. The test verifies the actual `labwc` process, Wayland socket, custom `onebook-shell` process, shell ready file, and 25 seconds of sustained activity. A failed session prints the real compositor and shell logs to the QEMU serial console.

Normal Live boots still start greetd on VT7, and they have **not** been validated by the headless CI test. Real display output, interaction, and installed-system login need a separate graphical QEMU/hardware test.

## Normal Live boot: automatic graphical desktop

Normal ISO boot uses GRUB's first entry automatically. It runs the real graphical Wayland session from `greetd` on VT7 and its `[initial_session]` auto-login as the ephemeral Live user `obos`. **No username/password prompt is intended for Live mode**. The separate kernel option `obos.test=1` is strictly headless CI diagnostic mode and does not reflect the normal graphical user experience.

The GitHub pipeline includes an independent `graphical` QEMU mode (`obos.gui-test=1`) that **does not** bypass greetd. It verifies the real compositor, Wayland socket and OneBook Shell running for the auto-logged-in user with a QEMU virtual GPU. This tests process startup only; it is not a substitute for inspecting actual rendered pixels or testing on physical hardware. An installed OneBookOS will require secure account creation and must not retain this Live auto-login.

## Greetd Live user requirement (QEMU regression)

The user `greeter` is intentionally not installed in this minimal Live ISO. Greetd validates its `[default_session]` user even when `[initial_session]` is configured. An absent `greeter` user causes greetd to exit immediately with `start-limit-hit`, so neither the compositor nor the UI starts. Both greetd sessions therefore run `/usr/local/bin/onebook-session` as Casper's Live user `obos`. A static TOML check is part of CI and the `graphical` QEMU test must verify actual logged-in UI processes before publication. Installed systems must switch to real account management and authentication before release.

## Faster iteration and visual baseline

The CI uses a **package-only Ubuntu 24.04 base** archived at `.onebookui-cache/base-rootfs.tar.zst` and reused by GitHub Actions when `base-packages.txt` is unchanged. On cache hit, `debootstrap` and package installation are skipped; only current shell sources and assets are overlaid. SquashFS uses zstd compression and independent QEMU headless and graphical checks run in parallel. The initial cache-miss build remains slower; **5–8 minutes is a target, not a guaranteed runtime**.

The live wallpaper SVG is rasterized to 3840×2160 PNG for `swaybg`, icons are generated at 256×256 and downscaled with GdkPixbuf, and installed Wayland-native apps include foot terminal, Thunar file manager and Mousepad editor. Test both the dock and the desktop shortcuts in a real QEMU window: process-alive CI does not guarantee visual design quality or complete application behavior.

The Galaxy Book4 Pro needs **separate hardware testing** for Intel GPU acceleration, audio, Wi-Fi, touchscreen, brightness and HiDPI scaling. The ISO is a Live prototype and should not replace an existing Windows installation.

## OneBookUI Visual Polish Pass 1

Theme: custom `labwc`/Openbox `OneBookUI` titlebar with a 34-pixel flat header, no glossy gradients, a 12-pixel corner radius, and simple high-contrast scalable SVG window controls. The GTK layer-shell dock, desktop shortcuts, clock, menu and control center use smaller dimensions and eliminate button glow/raised 3D effects. The collapsed notch is a blank black capsule; labels appear **only when expanded**. Icons are rendered from SVG at requested widget sizes rather than enlarged from small PNGs.

`onebook-display` requests 1920×1080 only when the VM advertises that mode and retains the preferred physical display mode; a known 2880×1800 panel receives experimental 1.5x scaling. High-DPI fractional scaling, GTK headerbar consistency, animation quality and visual blur require further real-device QA and are not certified by automated process tests. This changes labwc server-side titlebars; GTK apps that draw their own client-side headerbars may still require per-application theming.

GTK3 applications now use a system-wide **OneBookUI** theme inheriting the Ubuntu Adwaita CSS resource, with flat titlebars, smaller action buttons and no raised bevels. The shell's Files launcher points to the working Thunar file manager; the experimental OneBook Files prototype remains installed but is not the default. GTK4/libadwaita apps may draw their own titlebars and are not fully covered by this GTK3 theme.

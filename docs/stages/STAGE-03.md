# Stage 03/16 — OneBook Shell and crash recovery

**Product:** OneBookOS 0.1.3 OneBook Shell Developer Preview (Live ISO, no installer).

## What this stage delivers

- Existing GTK3 Wayland shell is now supervised independently of labwc and Wayfire.
- Guardian restarts a crashed shell, clears stale readiness markers and enters recovery mode after 3 short failures.
- Separate `onebook-shell-recover` supports `status`, `safe` and `resume` for shell-only recovery.
- Labwc: Alt+F4 close, Super+Down minimize, Super+Up maximize/restore, Super+Left/Right snap, Alt+Tab switch windows.
- New QEMU recovery mode kills the real shell process and checks automatic restart (distinct PID, ready marker, compositor still alive).
- Live ISO uses Ubuntu 24.04 LTS; labwc is default, Wayfire remains experimental.

## Run on Ubuntu 24.04 amd64

```sh
sudo bash onebookui/build/install-deps.sh
sudo bash display-engine/build-stage3-iso.sh
bash onebookui/build/test-qemu.sh dist/OneBookOS-0.1.3-OneBookShell-DeveloperPreview-amd64.iso headless labwc
bash onebookui/build/test-qemu.sh dist/OneBookOS-0.1.3-OneBookShell-DeveloperPreview-amd64.iso graphical labwc
bash onebookui/build/test-qemu.sh dist/OneBookOS-0.1.3-OneBookShell-DeveloperPreview-amd64.iso recovery labwc
```

## Important limitations

Stage 3 is reliability and window/session functionality work, not a new visual mockup. The precise Start/taskbar/clock layout is stage 5; OneBook Design System is stage 4. Black notch tabs and richer animation are stages 6–7. Own core apps are stages 10–13. A disk installer is stage 14.

GitHub Actions success confirms tested VM paths only. It does not certify appearance, touchscreen, NVIDIA, AMD or Galaxy Book hardware. Never install this preview over real user data.

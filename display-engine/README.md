# Stage 02 — Display Engine Developer Preview

**Status:** Experimental comparison; no final compositor decision yet. This is not an installed operating system and contains NO installer.

## Candidates
- **labwc**: proven existing native Wayland preview; selected as the **default and fallback**. Minimal window effects.
- **Wayfire**: Ubuntu 24.04 package dependency simulation succeeded in GitHub Actions run 43765851523. It offers window animation plugins. Experimental alternative, requires real graphical/QEMU validation.
- **sway**: APT candidate verified as fallback research only; not packaged in the stage-2 ISO.

## Build and boot
On Ubuntu 24.04 amd64:
```bash
sudo bash onebookui/build/install-deps.sh
sudo bash display-engine/build-stage2-iso.sh
bash onebookui/build/test-qemu.sh dist/OneBookOS-0.1.2-DisplayEngine-DeveloperPreview-amd64.iso headless labwc
bash onebookui/build/test-qemu.sh dist/OneBookOS-0.1.2-DisplayEngine-DeveloperPreview-amd64.iso graphical labwc
bash onebookui/build/test-qemu.sh dist/OneBookOS-0.1.2-DisplayEngine-DeveloperPreview-amd64.iso graphical wayfire
```

GRUB entry 1 boots labwc (default). GRUB entry 2 boots experimental Wayfire. The alternate compositor is only selected using the explicit `obos.compositor=wayfire` kernel argument. No installer, partitioning or disk writes are part of stage 2.

## Acceptance evidence
- Source syntax and configuration tests.
- Ubuntu 24.04 dependency simulation.
- ISO checksum and boot-catalog inspection.
- Labwc headless + graphical QEMU boot, shell and app survival.
- Experimental Wayfire graphical QEMU boot (report success/failure, do not mask failure as success).
- Independent screenshots **from QEMU** to review before choosing final compositor.
- No verified FPS, blur or GPU-support claim from QEMU markers alone.

### Safety
Do not install this preview on a physical disk. Normal Live boot only. Revert to labwc in the GRUB menu if Wayfire fails; this is not a production recovery guarantee.

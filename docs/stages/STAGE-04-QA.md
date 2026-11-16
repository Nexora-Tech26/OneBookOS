# Stage 04 — QEMU QA after real ISO build

**Source commit under test:** `37274c12ea33328f501d90790b67e09e78ed4092`
**CI run:** https://github.com/Nexora-Tech26/OneBookOS/actions/runs/43862754547
**Image:** `OneBookOS-0.1.4-DesignSystem-DeveloperPreview-amd64.iso` in GitHub Actions artifact `OneBookOS-Stage04-Live-ISO`.

## Automated evidence

- PASS: original 18 SVGs and 256px PNG exports, theme token generation and accessibility text contrast checks.
- PASS: Ubuntu Live ISO build, GRUB catalog and SHA256.
- PASS: labwc headless and graphical QEMU smoke, actual framebuffer capture.
- PASS: crash and recovery test with compositor surviving the OneBook Shell restart.
- FAIL (optional): Wayfire graphical QEMU — **not verified**; its result is recorded as a warning, labwc remains default.

## Visual inspection of actual QEMU screenshot

Reviewed `OneBookUI-graphical-qemu.png` and `OneBookUI-shell-recovery-qemu.png` from `OneBookOS-Stage04-Visual-QA`.

**Visible improvements:** vibrant indigo/blue/magenta wallpaper, brighter lavender taskbar and corner clock, sharper original system icons, smaller colored action buttons in labwc window titlebars.

**Unresolved and not accepted as final:**

1. Bottom taskbar is still **one continuous middle strip**, not separated left/right segments with a standalone exact-center Start. Stage 5 must correct geometry and measure it at 1920×1080.
2. Clock is still **detached at the bottom-right** instead of integrated into the right taskbar. Rendering shows a **black/white rectangular artifact partially obscuring time/date** in captures. Stage 5 must fix clipping/overdraw and verify multiple captures.
3. Start menu itself is **not visible** in the graphical QEMU capture because test applications occupy the foreground. Before declaring layout approval, obtain an unobstructed running-UI screenshot of the expanded launcher and compare it to the accepted mockup.
4. Thunar, Mousepad, xterm and foot are transitional third-party apps. Styling them does not make them original OneBook apps; native apps are planned for stages 10–13.
5. Notch in this screenshot is only the small black collapsed capsule. Expanded tab content/animations and 10 widgets are still planned for later stages.

## Verdict

**Code and mandatory ISO/QEMU tests: PASS.**
**Final visual acceptance against approved OneBookUI 8 concept: OPEN, not passed.**

Keep PR as draft; do not merge this as a visually finished system. The next stage should address layout plus clock artifact, with a dedicated unobstructed screenshot test. This document-only QA note does not change ISO bytes.

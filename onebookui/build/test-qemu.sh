#!/usr/bin/env bash
# shellcheck disable=SC2317 # cleanup() is invoked indirectly by EXIT trap.
# Two real-QEMU boot checks from the built ISO:
#   headless: isolated wlroots compositor smoke test
#   graphical: the normal greetd automatic login + DRM Wayland desktop
set -Eeuo pipefail
ISO="${1:?Usage: test-qemu.sh path/to/iso [headless|graphical]}"
MODE="${2:-headless}"
COMPOSITOR="${3:-labwc}"
case "$COMPOSITOR" in
  labwc) COMPOSITOR_ARG='' ;;
  wayfire) COMPOSITOR_ARG='obos.compositor=wayfire' ;;
  *) echo "Unknown compositor: $COMPOSITOR" >&2; exit 2 ;;
esac
if [[ "$MODE" == headless && "$COMPOSITOR" == wayfire ]]; then
  echo 'Wayfire headless/pixman support is not asserted: test graphical mode instead.' >&2
  exit 2
fi
case "$MODE" in
  headless)
    TESTARG='obos.test=1'
    MARKER='ONEBOOK_WAYLAND_GUI_OK'
    VGA='std'
    ;;
  graphical)
    TESTARG='obos.gui-test=1'
    MARKER='ONEBOOK_GUI_AUTOLOGIN_OK'
    VGA='virtio'
    ;;
  *) echo "Unknown QEMU test mode: $MODE" >&2; exit 2 ;;
esac
for bin in qemu-system-x86_64 xorriso timeout grep realpath; do
  command -v "$bin" >/dev/null
done
test -s "$ISO"
ISO="$(realpath "$ISO")"
TEMP="$(mktemp -d)"
LOG="$TEMP/serial.log"
cleanup() {
  if [[ -n "${PID:-}" ]]; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP"
}
trap cleanup EXIT
xorriso -osirrox on -indev "$ISO" \
  -extract /casper/vmlinuz "$TEMP/vmlinuz" \
  -extract /casper/initrd "$TEMP/initrd" >/dev/null 2>&1
test -s "$TEMP/vmlinuz" && test -s "$TEMP/initrd"
BOOTARGS="boot=casper live-media-path=/casper username=obos hostname=onebookos $TESTARG $COMPOSITOR_ARG console=tty0 console=ttyS0,115200n8 ---"
echo "[QEMU] Testing $MODE $COMPOSITOR boot from ISO ($TESTARG; VGA=$VGA)"
timeout --signal=TERM 420s qemu-system-x86_64 \
  -m 4096 -smp 2 -accel tcg -display none -vga "$VGA" -no-reboot \
  -kernel "$TEMP/vmlinuz" -initrd "$TEMP/initrd" -append "$BOOTARGS" \
  -cdrom "$ISO" -boot d -serial "file:$LOG" -qmp "unix:$TEMP/monitor.sock,server=on,wait=off" \
  >"$TEMP/qemu.log" 2>&1 &
PID=$!
PASS=0
for _ in $(seq 1 400); do
  # Getty may leave its login prompt on the same serial line as the marker.
  if grep -Fq "$MARKER" "$LOG" 2>/dev/null; then
    PASS=1
    break
  fi
  if grep -Eiq 'ONEBOOK_WAYLAND_GUI_FAILED|ONEBOOK_GUI_AUTOLOGIN_FAILED|kernel panic|unable to mount root fs|unable to find a medium containing a live file system' "$LOG" 2>/dev/null; then
    echo 'Guest reported boot or GUI failure' >&2
    break
  fi
  if ! kill -0 "$PID" 2>/dev/null; then
    echo 'QEMU process exited unexpectedly' >&2
    break
  fi
  sleep 1
done
if [[ "$PASS" == 1 && "$MODE" == graphical ]]; then
  # Capture actual graphical pixels, not just a process marker. A blank/absent
  # image must be reported as a failed graphical build.
  if [[ "$COMPOSITOR" == labwc ]]; then
    SHOT="$(dirname "$ISO")/OneBookUI-graphical-qemu.png"
  else
    SHOT="$(dirname "$ISO")/OneBookUI-wayfire-graphical-qemu.png"
  fi
  python3 "$(dirname "$0")/qemu-screenshot.py" "$TEMP/monitor.sock" "$SHOT" || PASS=0
fi
if [[ "$PASS" == 1 ]]; then
  echo "PASS: $MODE $COMPOSITOR Wayland desktop boot and sustained shell activity in QEMU"
  exit 0
fi
echo "FAIL: $MODE $COMPOSITOR OneBookUI Wayland boot was not verified" >&2
echo '--- Last 220 lines of guest serial output ---' >&2
tail -220 "$LOG" >&2 || true
echo '--- QEMU diagnostics ---' >&2
tail -40 "$TEMP/qemu.log" >&2 || true
exit 1

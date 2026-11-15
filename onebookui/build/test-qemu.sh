#!/usr/bin/env bash
# shellcheck disable=SC2317 # cleanup() is invoked indirectly by EXIT trap.
# Verify Casper + the independent Wayland shell by booting the actual ISO's
# kernel and initrd with an explicit diagnostic flag. Normal GRUB default
# stays interactive for users and is NEVER changed to test/headless mode.
set -Eeuo pipefail
ISO="${1:?Usage: test-qemu.sh path/to/iso}"
for bin in qemu-system-x86_64 xorriso timeout grep; do
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
# These are extracted from the newly built, checksummed ISO. QEMU must boot
# with obos.test=1, unlike the earlier test which accidentally chose
# GRUB's default non-test entry and waited for a marker that could not exist.
xorriso -osirrox on -indev "$ISO" \
  -extract /casper/vmlinuz "$TEMP/vmlinuz" \
  -extract /casper/initrd "$TEMP/initrd" >/dev/null 2>&1
test -s "$TEMP/vmlinuz" && test -s "$TEMP/initrd"
BOOTARGS='boot=casper live-media-path=/casper username=obos hostname=onebookos obos.test=1 console=tty0 console=ttyS0,115200n8 ---'
echo "[QEMU] Booting ISO kernel with obos.test=1 (headless wlroots inside guest)"
timeout --signal=TERM 420s qemu-system-x86_64 \
  -m 4096 -smp 2 -accel tcg -display none -vga std -no-reboot \
  -kernel "$TEMP/vmlinuz" -initrd "$TEMP/initrd" -append "$BOOTARGS" \
  -cdrom "$ISO" -boot d -serial "file:$LOG" -monitor none \
  >"$TEMP/qemu.log" 2>&1 &
PID=$!
PASS=0
for _ in $(seq 1 400); do
  if grep -q '^ONEBOOK_WAYLAND_GUI_OK' "$LOG" 2>/dev/null; then
    PASS=1
    break
  fi
  if grep -Eiq 'ONEBOOK_WAYLAND_GUI_FAILED|kernel panic|unable to mount root fs|unable to find a medium containing a live file system' "$LOG" 2>/dev/null; then
    echo "Guest reported boot or GUI failure" >&2
    break
  fi
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "QEMU process exited unexpectedly" >&2
    break
  fi
  sleep 1
done
if [[ "$PASS" == 1 ]]; then
  echo 'PASS: guest booted Casper; labwc Wayland and OneBook shell stable in QEMU'
  exit 0
fi
echo "FAIL: independent OneBookUI Wayland compositor+shell were not verified" >&2
echo "--- Last 160 lines of guest serial output ---" >&2
tail -160 "$LOG" >&2 || true
echo "--- QEMU diagnostics ---" >&2
tail -40 "$TEMP/qemu.log" >&2 || true
exit 1

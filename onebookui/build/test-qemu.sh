#!/usr/bin/env bash
set -Eeuo pipefail
ISO="${1:?Usage: test-qemu.sh path/to/iso}"
command -v qemu-system-x86_64 >/dev/null
test -s "$ISO"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
timeout --signal=TERM 480s qemu-system-x86_64 \
 -m 4096 -smp 2 -accel tcg -display none -vga std -no-reboot \
 -cdrom "$ISO" -boot d -serial "file:$LOG" -monitor none \
 >/dev/null 2>&1 &
PID=$!
PASS=0
for _ in $(seq 1 460);do
 if grep -q '^ONEBOOK_WAYLAND_GUI_OK$' "$LOG";then PASS=1;break;fi
 if grep -Eiq 'ONEBOOK_WAYLAND_GUI_FAILED|kernel panic|unable to mount root fs|unable to find a medium containing a live file system' "$LOG";then
  tail -100 "$LOG" >&2;break
 fi
 if ! kill -0 "$PID" 2>/dev/null;then break;fi
 sleep 1
done
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
if test "$PASS" != 1;then echo "FAIL: Wayland compositor+shell not verified" >&2;tail -150 "$LOG" >&2;exit 1;fi
echo 'PASS: independent OneBookUI Wayland session stable in QEMU'

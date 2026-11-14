#!/usr/bin/env bash
set -Eeuo pipefail
ISO="${1:?Usage: smoke-test.sh /path/to/image.iso}"
command -v qemu-system-x86_64 >/dev/null
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
# The serial console comes from the GRUB kernel command line.
timeout --signal=TERM 260s qemu-system-x86_64 \
 -m 2048 -smp 2 -accel tcg -display none -no-reboot \
 -cdrom "$ISO" -boot d -serial "file:$LOG" -monitor none \
 >/dev/null 2>&1 &
PID=$!
SUCCESS=0
for _ in $(seq 1 240); do
 if grep -q 'OBOS_GUI_OK' "$LOG"; then SUCCESS=1;break;fi
 if grep -Eiq 'OBOS_GUI_FAILED|kernel panic|unable to mount root fs|unable to find a medium containing a live file system' "$LOG"; then
   echo "Boot failure detected:" >&2
   tail -100 "$LOG" >&2
   break
 fi
 if ! kill -0 "$PID" 2>/dev/null;then break;fi
 sleep 1
done
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
if [[ "$SUCCESS" != 1 ]];then
 echo "FAILED: graphical desktop marker not received. Last serial output:" >&2
 tail -100 "$LOG" >&2
 exit 1
fi
echo "SUCCESS: LightDM, XFCE, and OneBookOS shell started in the VM"

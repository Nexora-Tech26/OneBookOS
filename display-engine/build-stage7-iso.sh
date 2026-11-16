#!/usr/bin/env bash
# Stage 7 — wallpaper and independent live widgets.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test "$(id -u)" -eq 0 || { echo "Run with sudo/root" >&2; exit 1; }
export ONEBOOK_VERSION_ID=0.1.7-stage7
bash "$ROOT/onebookui/build/build-iso.sh"
OUT="$ROOT/dist"
ORIGINAL="$OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso"
TARGET="$OUT/OneBookOS-0.1.7-Wallpaper-Widgets-DeveloperPreview-amd64.iso"
test -s "$ORIGINAL"
mv "$ORIGINAL" "$TARGET"
(cd "$OUT" && sha256sum "$(basename "$TARGET")" > SHA256SUMS-stage7)
rm -f "$OUT/SHA256SUMS-onebookui"
echo "Stage 7 Live ISO built: $TARGET"

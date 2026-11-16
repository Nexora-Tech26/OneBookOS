#!/usr/bin/env bash
# Stage 6 — expanded Dynamic Notch + practical Ubuntu apps.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test "$(id -u)" -eq 0 || { echo "Run with sudo/root" >&2; exit 1; }
export ONEBOOK_VERSION_ID=0.1.6-stage6
bash "$ROOT/onebookui/build/build-iso.sh"
OUT="$ROOT/dist"
ORIGINAL="$OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso"
TARGET="$OUT/OneBookOS-0.1.6-DynamicNotch-DeveloperPreview-amd64.iso"
test -s "$ORIGINAL"
mv "$ORIGINAL" "$TARGET"
(cd "$OUT" && sha256sum "$(basename "$TARGET")" > SHA256SUMS-stage6)
rm -f "$OUT/SHA256SUMS-onebookui"
echo "Stage 6 Live ISO built: $TARGET"

#!/usr/bin/env bash
# Stage 4 Live ISO - OneBookUI 8 design assets generated at build time.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test "$(id -u)" -eq 0 || { echo "Requires sudo/root" >&2; exit 1; }
export ONEBOOK_VERSION_ID=0.1.4-stage4
bash "$ROOT/onebookui/build/build-iso.sh"
OUT="$ROOT/dist"
ORIGINAL="$OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso"
STAGE4="$OUT/OneBookOS-0.1.4-DesignSystem-DeveloperPreview-amd64.iso"
test -s "$ORIGINAL"
mv "$ORIGINAL" "$STAGE4"
(cd "$OUT" && sha256sum "$(basename "$STAGE4")" > SHA256SUMS-stage4)
rm -f "$OUT/SHA256SUMS-onebookui"
echo "Created experimental Stage 4 ISO: $STAGE4"

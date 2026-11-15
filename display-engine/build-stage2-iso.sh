#!/usr/bin/env bash
# Build current OneBookUI Live image with both compositor choices and stage-2 naming.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test "$(id -u)" -eq 0 || { echo "Run as root (sudo)" >&2; exit 1; }
export ONEBOOK_VERSION_ID=0.1.2-stage2
bash "$ROOT/onebookui/build/build-iso.sh"
OUT="$ROOT/dist"
ORIGINAL="$OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso"
STAGE2="$OUT/OneBookOS-0.1.2-DisplayEngine-DeveloperPreview-amd64.iso"
test -s "$ORIGINAL"
mv "$ORIGINAL" "$STAGE2"
(cd "$OUT" && sha256sum "$(basename "$STAGE2")" > SHA256SUMS-stage2)
rm -f "$OUT/SHA256SUMS-onebookui"
echo "Created experimental Stage 2 ISO: $STAGE2"

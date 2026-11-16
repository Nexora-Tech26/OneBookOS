#!/usr/bin/env bash
# Stage 3 Live ISO - two compositor options, OneBook Shell supervision.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test "$(id -u)" -eq 0 || { echo "Requires sudo/root" >&2; exit 1; }
export ONEBOOK_VERSION_ID=0.1.3-stage3
bash "$ROOT/onebookui/build/build-iso.sh"
OUT="$ROOT/dist"
OLD="$OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso"
NEW="$OUT/OneBookOS-0.1.3-OneBookShell-DeveloperPreview-amd64.iso"
test -s "$OLD"
mv "$OLD" "$NEW"
(cd "$OUT" && sha256sum "$(basename "$NEW")" > SHA256SUMS-stage3)
rm -f "$OUT/SHA256SUMS-onebookui"
echo "Created Stage 3 Live ISO: $NEW"

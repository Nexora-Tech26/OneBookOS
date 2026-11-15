#!/usr/bin/env bash
set -Eeuo pipefail
test "$(id -u)" -eq 0 || { echo "Needs sudo" >&2; exit 1; }
apt-get update
apt-get install -y --no-install-recommends debootstrap squashfs-tools grub-pc-bin grub-efi-amd64-bin grub-common grub2-common xorriso mtools dosfstools rsync qemu-system-x86 shellcheck

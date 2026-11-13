#!/usr/bin/env bash
set -Eeuo pipefail
[[ $(id -u) -eq 0 ]] || { echo "Run with sudo" >&2; exit 1; }
apt-get update
apt-get install -y debootstrap squashfs-tools grub-pc-bin grub-efi-amd64-bin grub-common grub2-common xorriso mtools dosfstools rsync shellcheck

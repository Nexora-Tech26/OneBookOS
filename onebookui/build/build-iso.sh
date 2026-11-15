#!/usr/bin/env bash
# OneBookUI experimental Live ISO — fast path reuses a verified package-only base.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$ROOT/.onebookui-build"
OUT="$ROOT/dist"
FS="$WORK/rootfs"
CD="$WORK/iso"
CACHE="$ROOT/.onebookui-cache/base-rootfs.tar.zst"
MOUNTS=()
cleanup() {
  for ((i=${#MOUNTS[@]}-1; i>=0; i--)); do
    if mountpoint -q "${MOUNTS[i]}"; then umount -lf "${MOUNTS[i]}" || true; fi
  done
}
trap cleanup EXIT
mount_chroot() {
  for d in dev proc sys; do
    mkdir -p "$FS/$d"
    mount --rbind "/$d" "$FS/$d"
    mount --make-rslave "$FS/$d"
    MOUNTS+=("$FS/$d")
  done
}
test "$(id -u)" -eq 0 && test "$(dpkg --print-architecture)" = amd64
for cmd in debootstrap mksquashfs grub-mkrescue xorriso rsync tar zstd rsvg-convert; do
  command -v "$cmd" >/dev/null
done
test -d /usr/lib/grub/x86_64-efi && test -d /usr/lib/grub/i386-pc
test ! -e "$WORK" || { echo "Remove stale $WORK" >&2; exit 1; }
mkdir -p "$FS" "$CD/casper" "$CD/boot/grub" "$OUT" "$(dirname "$CACHE")"
if test -s "$CACHE"; then
  echo '[OneBookUI] FAST BUILD: restoring cached Ubuntu 24.04 package base'
  tar --numeric-owner -I zstd -xf "$CACHE" -C "$FS"
else
  echo '[OneBookUI] COLD BUILD: preparing Ubuntu 24.04 package base for future builds'
  debootstrap --arch=amd64 --variant=minbase --components=main,restricted,universe,multiverse noble "$FS" http://archive.ubuntu.com/ubuntu
  cat > "$FS/etc/apt/sources.list" <<EOF
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF
fi
echo onebookos > "$FS/etc/hostname"
cp -L /etc/resolv.conf "$FS/etc/resolv.conf"
mount_chroot
if ! test -s "$CACHE"; then
  chroot "$FS" apt-get update
  mapfile -t packages < "$ROOT/onebookui/build/base-packages.txt"
  chroot "$FS" apt-get install -y --no-install-recommends "${packages[@]}"
  # Do not ship GNOME Shell, even if pulled transitively.
  if chroot "$FS" dpkg-query -W -f='${Status}' gnome-shell 2>/dev/null | grep -q 'install ok installed'; then
    echo '[OneBookUI] Purging unwanted GNOME Shell'
    chroot "$FS" apt-get purge -y gnome-shell gnome-shell-common
  fi
  chroot "$FS" apt-get clean
  rm -rf "$FS/var/lib/apt/lists/"* "$FS/var/cache/apt/archives/"*.deb
  cleanup
  MOUNTS=()
  # Never archive bind-mounted host /dev, /proc or /sys, nor transient state.
  tar --numeric-owner --exclude='./dev' --exclude='./proc' --exclude='./sys' --exclude='./run' --exclude='./tmp' \
    -I 'zstd -1 -T0' -cf "$CACHE" -C "$FS" .
  test -s "$CACHE"
  echo '[OneBookUI] Package-only cache saved; subsequent UI builds skip debootstrap and apt'
  mount_chroot
fi
test ! -e "$FS/usr/bin/gnome-shell" || { echo 'ERROR: GNOME Shell was found in rootfs' >&2; exit 1; }
for bin in /usr/bin/labwc /usr/bin/wayfire /usr/sbin/greetd /usr/bin/python3 /usr/bin/nmcli /usr/bin/foot /usr/bin/thunar /usr/bin/mousepad; do
  test -x "$FS$bin" || { echo "Missing required runtime component: $bin" >&2; exit 1; }
done
rsync -a "$ROOT/onebookui/overlay/" "$FS/"
test -s "$FS/usr/share/themes/OneBookUI/gtk-3.0/gtk.css"
test -s "$FS/etc/xdg/wayfire.ini"
test -s "$FS/usr/share/themes/OneBookUI/openbox-3/themerc"
mkdir -p "$FS/etc/xdg/autostart" "$FS/var/crash" "$FS/usr/share/backgrounds/onebookos" "$FS/usr/share/onebookos/icons"
test -x "$FS/usr/bin/glib-compile-schemas" || { echo 'GLib schemas compiler missing' >&2; exit 1; }
install -Dm644 "$ROOT/branding/wallpaper.svg" "$FS/usr/share/backgrounds/onebookos/wallpaper.svg"
# swaybg is reliably raster-backed; generate a high-resolution image from the source SVG.
rsvg-convert -w 3840 -h 2160 "$ROOT/branding/wallpaper.svg" -o "$FS/usr/share/backgrounds/onebookos/wallpaper.png"
test -s "$FS/usr/share/backgrounds/onebookos/wallpaper.png"
for source in "$ROOT/overlay/usr/share/gnome-shell/extensions/onebookos@nexora.tech/icons/"*.svg; do
  name="$(basename "$source" .svg)"
  install -m644 "$source" "$FS/usr/share/onebookos/icons/$name.svg"
  rsvg-convert -w 256 -h 256 "$source" -o "$FS/usr/share/onebookos/icons/$name.png"
done
for required in files terminal settings onebook; do
  test -s "$FS/usr/share/onebookos/icons/$required.png"
done
cat > "$FS/etc/casper.conf" <<EOF
export USERNAME="obos"
export USERFULLNAME="OneBookOS Live User"
export HOST="onebookos"
export BUILD_SYSTEM="Ubuntu"
export FLAVOUR="OneBookOS"
EOF
cat > "$FS/etc/os-release" <<EOF
PRETTY_NAME="OneBookOS OneBookUI Wayland Preview (Ubuntu 24.04)"
NAME="OneBookOS"
VERSION_ID="0.3-preview"
ID=ubuntu
ID_LIKE=debian
UBUNTU_CODENAME=noble
HOME_URL="https://github.com/Nexora-Tech26/OneBookOS"
EOF
chroot "$FS" locale-gen en_US.UTF-8 pl_PL.UTF-8
echo LANG=en_US.UTF-8 > "$FS/etc/default/locale"
chroot "$FS" systemctl set-default graphical.target
chroot "$FS" systemctl enable greetd NetworkManager onebook-headless.service onebook-gui-smoke.service onebook-gui-autologin-smoke.service
for app in onebook-shell onebook-files onebook-session onebook-gui-smoke onebook-gui-autologin-smoke onebook-display onebook-compositor-qa-apps; do
  chmod 755 "$FS/usr/local/bin/$app"
done
chroot "$FS" python3 -m py_compile /usr/local/bin/onebook-shell /usr/local/bin/onebook-files /usr/local/bin/onebook-display
test -f "$FS/usr/share/initramfs-tools/scripts/casper"
test -f "$FS/usr/share/wayland-sessions/onebookui.desktop"
KVER="$(find "$FS/lib/modules" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -1)"
test -n "$KVER"
chroot "$FS" update-initramfs -u -k "$KVER"
test -s "$FS/boot/initrd.img-$KVER"
chroot "$FS" apt-get clean
rm -f "$FS/etc/resolv.conf"
rm -rf "$FS/var/lib/apt/lists/"* "$FS/var/cache/apt/archives/"*.deb
cleanup
MOUNTS=()
cp "$FS/boot/vmlinuz-$KVER" "$CD/casper/vmlinuz"
cp "$FS/boot/initrd.img-$KVER" "$CD/casper/initrd"
chroot "$FS" dpkg-query -W --showformat='${Package} ${Version}\n' > "$CD/casper/filesystem.manifest"
du -sx --block-size=1 "$FS" | awk '{print $1}' > "$CD/casper/filesystem.size"
for d in dev proc sys run tmp; do
  mkdir -p "$FS/$d"
  if mountpoint -q "$FS/$d"; then echo "Mounted rootfs directory: $d" >&2; exit 1; fi
done
chmod 1777 "$FS/tmp"
# zstd substantially shortens UI iteration compared with multi-minute XZ compression.
mksquashfs "$FS" "$CD/casper/filesystem.squashfs" -comp zstd -Xcompression-level 6 -b 1M -noappend
cp "$ROOT/onebookui/build/grub.cfg" "$CD/boot/grub/grub.cfg"
echo 'Experimental Live ISO. Disk installer not implemented.' > "$CD/README.txt"
(cd "$CD" && find . -type f ! -name md5sum.txt -print0 | sort -z | xargs -0 md5sum) > "$CD/md5sum.txt"
grub-mkrescue -o "$OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso" "$CD" -- -volid ONEBOOKOS
(cd "$OUT" && sha256sum OneBookOS-OneBookUI-0.3-preview-amd64.iso > SHA256SUMS-onebookui)
echo "Built $OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso"

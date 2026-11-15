#!/usr/bin/env bash
# OneBookUI Wayland preview: experimental Live ISO, not a disk installer.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$ROOT/.onebookui-build"
OUT="$ROOT/dist"
FS="$WORK/rootfs"
CD="$WORK/iso"
MOUNTS=()
cleanup() {
 for ((i=${#MOUNTS[@]}-1;i>=0;i--)); do
  if mountpoint -q "${MOUNTS[i]}";then umount -lf "${MOUNTS[i]}" || true;fi
 done
}
trap cleanup EXIT
test "$(id -u)" -eq 0 && test "$(dpkg --print-architecture)" = amd64
for cmd in debootstrap mksquashfs grub-mkrescue xorriso rsync;do command -v "$cmd" >/dev/null;done
test -d /usr/lib/grub/x86_64-efi && test -d /usr/lib/grub/i386-pc
test ! -e "$WORK" || { echo "Remove stale $WORK" >&2;exit 1; }
mkdir -p "$FS" "$CD/casper" "$CD/boot/grub" "$OUT"
debootstrap --arch=amd64 --variant=minbase --components=main,restricted,universe,multiverse noble "$FS" http://archive.ubuntu.com/ubuntu
cat > "$FS/etc/apt/sources.list" <<EOF
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF
echo onebookos > "$FS/etc/hostname"
cp -L /etc/resolv.conf "$FS/etc/resolv.conf"
for d in dev proc sys;do
 mount --rbind "/$d" "$FS/$d"
 mount --make-rslave "$FS/$d"
 MOUNTS+=("$FS/$d")
done
chroot "$FS" apt-get update
chroot "$FS" apt-get install -y --no-install-recommends \
 ubuntu-minimal linux-generic linux-firmware casper initramfs-tools systemd-sysv \
 dbus-user-session dbus-x11 greetd labwc xwayland swaybg \
 python3 python3-gi gir1.2-gtk-3.0 gir1.2-gtklayershell-0.1 libglib2.0-bin \
 network-manager network-manager-gnome bluez pipewire pipewire-pulse wireplumber \
 upower brightnessctl alsa-utils procps psmisc \
 sudo locales ca-certificates curl xdg-utils \
 fonts-noto-core fonts-noto-color-emoji adwaita-icon-theme \
 mesa-utils libgl1-mesa-dri policykit-1 \
 udisks2 gvfs gvfs-backends xterm
# Ubuntu's package dependency resolver can bring in GNOME Shell, even for labwc.
# OneBookUI must never ship GNOME Shell as a desktop or fallback.
if chroot "$FS" dpkg-query -W -f='${Status}' gnome-shell 2>/dev/null | grep -q 'install ok installed'; then
  echo '[OneBookUI] Purging unwanted GNOME Shell from Live filesystem'
  chroot "$FS" apt-get purge -y gnome-shell gnome-shell-common
fi
test ! -e "$FS/usr/bin/gnome-shell" || { echo 'ERROR: GNOME Shell still installed; aborting' >&2; exit 1; }
for critical in /usr/bin/labwc /usr/sbin/greetd /usr/bin/python3 /usr/bin/nmcli; do
  test -x "$FS$critical" || { echo "Missing required runtime component: $critical" >&2; exit 1; }
done
rsync -a "$ROOT/onebookui/overlay/" "$FS/"
# Casper's legacy accessibility and crash hooks expect these standard paths.
mkdir -p "$FS/etc/xdg/autostart" "$FS/var/crash"
test -x "$FS/usr/bin/glib-compile-schemas" || { echo "GLib schema compiler missing" >&2; exit 1; }
install -Dm644 "$ROOT/branding/wallpaper.svg" "$FS/usr/share/backgrounds/onebookos/wallpaper.svg"
mkdir -p "$FS/usr/share/onebookos/icons"
cp "$ROOT/overlay/usr/share/gnome-shell/extensions/onebookos@nexora.tech/icons/"*.svg "$FS/usr/share/onebookos/icons/"
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
# The OneBookUI test must run as its own live-user Wayland session. Greetd is only used for non-test Live boots.
for app in onebook-shell onebook-files onebook-session onebook-gui-smoke onebook-gui-autologin-smoke;do chmod 755 "$FS/usr/local/bin/$app";done
chroot "$FS" python3 -m py_compile /usr/local/bin/onebook-shell /usr/local/bin/onebook-files
test -f "$FS/usr/share/initramfs-tools/scripts/casper"
test -f "$FS/usr/share/wayland-sessions/onebookui.desktop"
test -x "$FS/usr/bin/labwc"
test ! -e "$FS/usr/bin/gnome-shell"
KVER="$(find "$FS/lib/modules" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'|sort -V|tail -1)"
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
du -sx --block-size=1 "$FS"|awk '{print $1}' > "$CD/casper/filesystem.size"
for d in dev proc sys run tmp;do
 mkdir -p "$FS/$d"
 if mountpoint -q "$FS/$d";then echo "Mounted rootfs directory: $d" >&2;exit 1;fi
done
chmod 1777 "$FS/tmp"
mksquashfs "$FS" "$CD/casper/filesystem.squashfs" -comp xz -b 1M -noappend
cp "$ROOT/onebookui/build/grub.cfg" "$CD/boot/grub/grub.cfg"
echo 'Experimental Live ISO. Installer not implemented.' > "$CD/README.txt"
(cd "$CD" && find . -type f ! -name md5sum.txt -print0|sort -z|xargs -0 md5sum) > "$CD/md5sum.txt"
grub-mkrescue -o "$OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso" "$CD" -- -volid ONEBOOKOS
(cd "$OUT" && sha256sum OneBookOS-OneBookUI-0.3-preview-amd64.iso > SHA256SUMS-onebookui)
echo "Built $OUT/OneBookOS-OneBookUI-0.3-preview-amd64.iso"

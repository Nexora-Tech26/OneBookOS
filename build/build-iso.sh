#!/usr/bin/env bash
# OneBookOS Live Alpha: Ubuntu 24.04 LTS amd64, Casper + GRUB BIOS/UEFI
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${WORK:-$ROOT/.build}"
OUT="${OUT:-$ROOT/dist}"
FS="$WORK/rootfs"
CD="$WORK/iso"
MOUNTS=()
log(){ echo "[OBOS] $*"; }
cleanup(){
 for ((i=${#MOUNTS[@]}-1;i>=0;i--)); do
  if mountpoint -q "${MOUNTS[i]}"; then
   umount -lf "${MOUNTS[i]}" || true
  fi
 done
}
trap cleanup EXIT
[[ $(id -u) -eq 0 && $(dpkg --print-architecture) == amd64 ]] || { echo "Ubuntu amd64 root required" >&2; exit 1; }
for tool in debootstrap mksquashfs grub-mkrescue xorriso rsync; do command -v "$tool" >/dev/null || exit 1; done
test -d /usr/lib/grub/x86_64-efi
test -d /usr/lib/grub/i386-pc
test ! -e "$FS" || { echo "Clean .build before rebuilding" >&2; exit 1; }
mkdir -p "$FS" "$CD/casper" "$CD/boot/grub" "$OUT"
log "Bootstrap Ubuntu Noble"
debootstrap --arch=amd64 --variant=minbase --components=main,restricted,universe,multiverse noble "$FS" http://archive.ubuntu.com/ubuntu
cat > "$FS/etc/apt/sources.list" <<EOF
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF
printf 'onebookos\n' > "$FS/etc/hostname"
cp -L /etc/resolv.conf "$FS/etc/resolv.conf"
for d in dev proc sys; do
 mount --rbind "/$d" "$FS/$d"
 mount --make-rslave "$FS/$d"
 MOUNTS+=("$FS/$d")
done
log "Install kernel, Casper, GNOME 46 and system services"
chroot "$FS" apt-get update
chroot "$FS" apt-get install -y --no-install-recommends \
 ubuntu-minimal ubuntu-standard linux-generic casper initramfs-tools \
 systemd-sysv dbus-x11 gdm3 gnome-shell gnome-session ubuntu-session \
 gnome-control-center gnome-terminal nautilus gnome-text-editor gnome-calculator \
 gnome-system-monitor gnome-software gnome-settings-daemon \
 xserver-xorg-core xserver-xorg-input-all xserver-xorg-video-all \
 xinit xauth x11-xserver-utils x11-utils dconf-cli \
 network-manager network-manager-gnome bluez pipewire pipewire-pulse wireplumber pulseaudio-utils playerctl \
 alsa-utils pavucontrol udisks2 gvfs gvfs-backends \
 xdg-utils fonts-noto-core fonts-noto-color-emoji papirus-icon-theme \
 evince eog gnome-themes-extra adwaita-icon-theme-full \
 policykit-1-gnome sudo locales ca-certificates curl wget \
 pciutils usbutils lshw fwupd ubuntu-drivers-common mesa-utils \
 linux-firmware python3 python3-gi gir1.2-gtk-3.0 gir1.2-wnck-3.0 dmidecode
rsync -a "$ROOT/overlay/" "$FS/"
install -Dm644 "$ROOT/branding/wallpaper.svg" "$FS/usr/share/backgrounds/onebookos/wallpaper.svg"
cat > "$FS/etc/casper.conf" <<EOF
export USERNAME="obos"
export USERFULLNAME="OneBookOS Live User"
export HOST="onebookos"
export BUILD_SYSTEM="Ubuntu"
export FLAVOUR="OneBookOS"
EOF
cat > "$FS/etc/os-release" <<EOF
PRETTY_NAME="OneBookOS 0.2 GNOME Alpha (Ubuntu 24.04 LTS)"
NAME="OneBookOS"
VERSION_ID="0.2"
ID=ubuntu
ID_LIKE=debian
UBUNTU_CODENAME=noble
HOME_URL="https://github.com/Nexora-Tech26/OneBookOS"
EOF
chmod +x "$FS/usr/local/bin/obos-welcome" "$FS/usr/local/bin/obos-device-center" "$FS/usr/local/bin/obos-gui-smoke"
# Confirm the Casper scripts are present before making a boot image.
test -f "$FS/usr/share/initramfs-tools/scripts/casper" || { echo 'Missing casper initramfs hook' >&2; exit 1; }
chroot "$FS" locale-gen en_US.UTF-8 pl_PL.UTF-8
printf 'LANG=en_US.UTF-8\n' > "$FS/etc/default/locale"
# Boot directly into GNOME Shell through GDM; no XFCE or legacy overlay.
chroot "$FS" systemctl set-default graphical.target
chroot "$FS" systemctl enable gdm3 NetworkManager
chroot "$FS" systemctl enable obos-smoke.service obos-gui-smoke.service
chroot "$FS" dconf update
# Check critical runtime pieces before making a 1+ GB ISO.
for required in /usr/sbin/gdm3 /usr/bin/gnome-shell /usr/bin/gnome-session /usr/bin/Xorg /usr/bin/xauth; do
  test -x "$FS$required" || { echo "Missing GNOME binary: $required" >&2; exit 1; }
done
test -f "$FS/usr/share/gnome-shell/extensions/onebookos@nexora.tech/extension.js" || { echo "Missing GNOME shell extension" >&2; exit 1; }
test -f "$FS/usr/share/gnome-shell/extensions/onebookos@nexora.tech/metadata.json" || { echo "Missing extension metadata" >&2; exit 1; }
chroot "$FS" /usr/bin/python3 -m py_compile /usr/local/bin/obos-welcome /usr/local/bin/obos-device-center
KVER="$(find "$FS/lib/modules" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -1)"
test -n "$KVER"
chroot "$FS" update-initramfs -u -k "$KVER"
test -s "$FS/boot/initrd.img-$KVER" || { echo "Missing initramfs" >&2; exit 1; }
log "Prepare Casper filesystem"
chroot "$FS" apt-get clean
rm -f "$FS/etc/resolv.conf"
rm -rf "$FS/var/lib/apt/lists/"* "$FS/var/cache/apt/archives/"*.deb
cleanup
MOUNTS=()
cp "$FS/boot/vmlinuz-$KVER" "$CD/casper/vmlinuz"
cp "$FS/boot/initrd.img-$KVER" "$CD/casper/initrd"
# dpkg-query interprets the format variables; they are intentionally literal to Bash.
# shellcheck disable=SC2016
chroot "$FS" dpkg-query -W --showformat='${Package} ${Version}\n' > "$CD/casper/filesystem.manifest"
du -sx --block-size=1 "$FS" | awk '{print $1}' > "$CD/casper/filesystem.size"
# Casper needs these mountpoint directories to exist in the extracted root.
# Do not exclude the directories themselves from SquashFS: doing so causes
# /root/dev, /root/run, /root/proc and /root/sys mount failures at boot.
# All bind mounts were unmounted above before SquashFS is generated.
for directory in dev proc sys run tmp; do
  mkdir -p "$FS/$directory"
  if mountpoint -q "$FS/$directory"; then
    echo "Refusing to squash a mounted $FS/$directory" >&2
    exit 1
  fi
done
chmod 1777 "$FS/tmp"
mksquashfs "$FS" "$CD/casper/filesystem.squashfs" -comp xz -b 1M -noappend
cp "$ROOT/build/grub.cfg" "$CD/boot/grub/grub.cfg"
echo "OneBookOS 0.2 GNOME Alpha based on Ubuntu 24.04" > "$CD/README.txt"
(cd "$CD" && find . -type f ! -name md5sum.txt -print0 | sort -z | xargs -0 md5sum) > "$CD/md5sum.txt"
log "Build GRUB BIOS+UEFI ISO"
grub-mkrescue -o "$OUT/OneBookOS-0.2-gnome-live-amd64.iso" "$CD" -- -volid ONEBOOKOS
(cd "$OUT" && sha256sum OneBookOS-0.2-gnome-live-amd64.iso > SHA256SUMS)
log "ISO: $OUT/OneBookOS-0.2-gnome-live-amd64.iso"

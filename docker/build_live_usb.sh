#!/bin/bash
# Builds the USB Cold Storage live ISO (Debian 13 "trixie", amd64).
# All third-party downloads are pinned in versions.env and verified
# (GPG signature against a pinned fingerprint, or SHA-256) BEFORE they
# enter the image. Any verification failure aborts the build.
set -euo pipefail

cd /build
# shellcheck source=versions.env
source ./versions.env

WORK_DIR=/build/live
DL_DIR=/build/downloads
OUT_DIR=/output
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date +%s)}"

mkdir -p "$DL_DIR" "$OUT_DIR"
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME

die() { echo "ERROR: $*" >&2; exit 1; }

fetch() { # url dest
  curl -fsSL --retry 3 -o "$2" "$1" || die "download failed: $1"
}

import_key() { # keyfile expected-fingerprint
  local fpr
  gpg --batch --quiet --import "$1"
  fpr="$(gpg --batch --with-colons --fingerprint "$2" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')"
  [ "$fpr" = "$2" ] || die "key $1 does not contain fingerprint $2"
}

verify_sig() { # file sig expected-fingerprint
  local status
  status="$(gpg --batch --status-fd 1 --verify "$2" "$1" 2>/dev/null)" || die "bad signature on $1"
  grep -q "^\[GNUPG:\] VALIDSIG $3 " <<<"$status" \
    || grep -q "^\[GNUPG:\] VALIDSIG .* $3\$" <<<"$status" \
    || die "$1 is not signed by $3"
}

verify_sha256() { # file expected
  echo "$2  $1" | sha256sum -c --quiet - || die "sha256 mismatch for $1"
}

echo "==> Verifying signing keys"
import_key keys/electrum-ThomasV.asc "$ELECTRUM_KEY_FPR"
import_key keys/sparrow-craigraw.asc "$SPARROW_KEY_FPR"

echo "==> Electrum $ELECTRUM_VERSION"
ELECTRUM_FILE="electrum-${ELECTRUM_VERSION}-x86_64.AppImage"
fetch "https://download.electrum.org/${ELECTRUM_VERSION}/${ELECTRUM_FILE}" "$DL_DIR/$ELECTRUM_FILE"
fetch "https://download.electrum.org/${ELECTRUM_VERSION}/${ELECTRUM_FILE}.ThomasV.asc" "$DL_DIR/$ELECTRUM_FILE.asc"
verify_sig "$DL_DIR/$ELECTRUM_FILE" "$DL_DIR/$ELECTRUM_FILE.asc" "$ELECTRUM_KEY_FPR"

echo "==> Sparrow $SPARROW_VERSION"
SPARROW_FILE="sparrowwallet_${SPARROW_VERSION}-1_amd64.deb"
SPARROW_BASE="https://github.com/sparrowwallet/sparrow/releases/download/${SPARROW_VERSION}"
fetch "$SPARROW_BASE/$SPARROW_FILE" "$DL_DIR/$SPARROW_FILE"
fetch "$SPARROW_BASE/sparrow-${SPARROW_VERSION}-manifest.txt" "$DL_DIR/sparrow-manifest.txt"
fetch "$SPARROW_BASE/sparrow-${SPARROW_VERSION}-manifest.txt.asc" "$DL_DIR/sparrow-manifest.txt.asc"
verify_sig "$DL_DIR/sparrow-manifest.txt" "$DL_DIR/sparrow-manifest.txt.asc" "$SPARROW_KEY_FPR"
SPARROW_SHA="$(awk -v f="$SPARROW_FILE" '$2 == f || $2 == "*"f {print $1}' "$DL_DIR/sparrow-manifest.txt")"
[ -n "$SPARROW_SHA" ] || die "$SPARROW_FILE not listed in signed manifest"
verify_sha256 "$DL_DIR/$SPARROW_FILE" "$SPARROW_SHA"

echo "==> Seedtool (kreutix/seedtool@$SEEDTOOL_COMMIT)"
fetch "https://raw.githubusercontent.com/kreutix/seedtool/${SEEDTOOL_COMMIT}/dist/index.html" "$DL_DIR/seedtool.html"
verify_sha256 "$DL_DIR/seedtool.html" "$SEEDTOOL_SHA256"

echo "==> Configuring live-build"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

lb config \
  --mode debian \
  --distribution trixie \
  --architectures amd64 \
  --archive-areas "main" \
  --debian-installer none \
  --binary-images iso-hybrid \
  --bootloaders "syslinux,grub-efi" \
  --uefi-secure-boot enable \
  --security true \
  --updates true \
  --apt-recommends false \
  --firmware-binary false \
  --firmware-chroot false \
  --iso-application "USB Cold Storage" \
  --iso-publisher "KreutiX <info@kreutix.de>" \
  --iso-volume "USB_COLD_STORAGE" \
  --image-name "usb-cold-storage" \
  --bootappend-live "boot=live components quiet splash locales=de_DE.UTF-8 keyboard-layouts=de timezone=Europe/Berlin username=cold hostname=coldstorage ipv6.disable=1 init_on_free=1 page_alloc.shuffle=1"

cat > config/package-lists/desktop.list.chroot <<'EOF'
live-boot
live-config
live-config-systemd
systemd-sysv
locales
keyboard-configuration
console-setup
xorg
xserver-xorg-video-all
xserver-xorg-input-all
lightdm
lightdm-gtk-greeter
xfce4
xfce4-terminal
xfce4-screenshooter
thunar
mousepad
ristretto
adwaita-icon-theme
fonts-dejavu
dbus-x11
firefox-esr
firefox-esr-l10n-de
polkitd
udisks2
gvfs
fuse3
libfuse2t64
v4l-utils
qrencode
zbar-tools
EOF

# Verified third-party payload
mkdir -p config/packages.chroot \
         config/includes.chroot/opt/electrum \
         config/includes.chroot/opt/seedtool
cp "$DL_DIR/$SPARROW_FILE" config/packages.chroot/
install -m 0755 "$DL_DIR/$ELECTRUM_FILE" config/includes.chroot/opt/electrum/electrum.AppImage
install -m 0644 "$DL_DIR/seedtool.html" config/includes.chroot/opt/seedtool/index.html
cp -a /build/overlay/. config/includes.chroot/

mkdir -p config/hooks/live
cat > config/hooks/live/0900-air-gap.hook.chroot <<'EOF'
#!/bin/sh
# Air gap: remove every network/radio driver and network daemon from the image.
set -e
apt-get purge -y --auto-remove \
  network-manager wpasupplicant iwd bluez modemmanager avahi-daemon \
  openssh-client openssh-server isc-dhcp-client dhcpcd-base ifupdown \
  firmware-iwlwifi firmware-realtek firmware-atheros firmware-brcm80211 2>/dev/null || true
for kdir in /lib/modules/*; do
  [ -d "$kdir" ] || continue
  rm -rf "$kdir/kernel/drivers/net" \
         "$kdir/kernel/drivers/bluetooth" \
         "$kdir/kernel/drivers/nfc" \
         "$kdir/kernel/drivers/net/wwan" \
         "$kdir/kernel/net/wireless" \
         "$kdir/kernel/net/mac80211" \
         "$kdir/kernel/net/bluetooth" \
         "$kdir/kernel/net/nfc"
  depmod "$(basename "$kdir")"
done
systemctl mask systemd-networkd.service systemd-networkd.socket systemd-resolved.service \
  bluetooth.target 2>/dev/null || true
# Rebuild the initramfs so it does not carry the removed drivers either.
update-initramfs -u -k all
EOF

cat > config/hooks/live/0910-no-swap.hook.chroot <<'EOF'
#!/bin/sh
# Never page secrets to disk: no swap, no core dumps.
set -e
systemctl mask swap.target
echo "* hard core 0" > /etc/security/limits.d/90-nocore.conf
mkdir -p /etc/systemd/coredump.conf.d
printf '[Coredump]\nStorage=none\nProcessSizeMax=0\n' > /etc/systemd/coredump.conf.d/disable.conf
EOF
chmod +x config/hooks/live/*.hook.chroot

echo "==> Building image (this takes a while)"
lb build

ISO="$(ls "$WORK_DIR"/*.iso | head -n1)"
[ -f "$ISO" ] || die "no ISO produced"
NAME="usb-cold-storage-${IMAGE_VERSION}-amd64.iso"
mv "$ISO" "$OUT_DIR/$NAME"
cp "$WORK_DIR"/*.packages "$OUT_DIR/${NAME%.iso}.packages" 2>/dev/null || true
(cd "$OUT_DIR" && sha256sum "$NAME" > "$NAME.sha256")
echo "==> Done: $OUT_DIR/$NAME"
cat "$OUT_DIR/$NAME.sha256"

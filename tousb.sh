#!/bin/sh
# Write the newest ISO to a USB stick on macOS.
# usage: ./tousb.sh disk4   (see: diskutil list external)
set -e

DISK="${1#/dev/}"
DISK="${DISK#r}"
if [ -z "$DISK" ]; then
  echo "usage: ./tousb.sh <disk>   e.g. ./tousb.sh disk4"
  diskutil list external
  exit 1
fi

ISO="${ISO:-$(ls -t output/usb-cold-storage-*-amd64.iso 2>/dev/null | head -n1)}"
[ -f "$ISO" ] || { echo "no ISO found in output/"; exit 1; }

if [ -f "$ISO.sha256" ]; then
  (cd "$(dirname "$ISO")" && shasum -a 256 -c "$(basename "$ISO").sha256")
fi

if ! diskutil info "/dev/$DISK" | grep -Eq "Device Location: +External|Removable Media: +Removable"; then
  echo "/dev/$DISK is not an external/removable disk - refusing."
  exit 1
fi

diskutil info "/dev/$DISK" | grep -E "Device / Media Name|Disk Size"
printf "ALL DATA on /dev/%s will be overwritten. Type YES to continue: " "$DISK"
read -r answer
[ "$answer" = "YES" ] || exit 1

diskutil unmountDisk "/dev/$DISK"
sudo dd if="$ISO" of="/dev/r$DISK" bs=4m
sync
diskutil eject "/dev/$DISK"
echo "Done. Ignore macOS' 'disk not readable' dialog - that is expected."

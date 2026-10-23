#!/bin/sh
# Build the ISO into ./output (live-build needs a privileged container).
set -e
mkdir -p output
docker run --platform=linux/amd64 --rm --privileged \
  -e SOURCE_DATE_EPOCH="$(git log -1 --format=%ct 2>/dev/null || date +%s)" \
  -v "$(pwd)/output:/output" \
  usb-cold-storage-builder /build/build_live_usb.sh

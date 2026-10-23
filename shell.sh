#!/bin/sh
# Interactive shell in the builder for debugging.
docker run --platform=linux/amd64 --rm -it --privileged \
  -v "$(pwd)/output:/output" \
  usb-cold-storage-builder bash

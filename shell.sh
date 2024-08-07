#!/bin/sh

docker run --platform=linux/amd64 --rm -it --privileged \
  -v $(pwd)/output:/output \
  -v builder:/home/builder/live-build \
  usb-cold-storage-builder bash

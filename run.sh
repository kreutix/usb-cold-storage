#!/bin/sh

docker run --platform=linux/amd64 --rm -it --privileged -v $(pwd)/output:/output usb-cold-storage-builder /home/builder/build_live_usb.sh

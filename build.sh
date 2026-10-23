#!/bin/sh
# Build the (amd64) builder image. On Apple Silicon use an amd64-capable
# Docker runtime using qemu-user (not Rosetta), e.g.: colima start --vm-type vz
set -e
docker build --platform=linux/amd64 -t usb-cold-storage-builder ./docker/

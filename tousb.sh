#!/bin/sh

if [ -z "$1" ]; then
  echo "usage: ./tousb.sh <disk>"
  exit 1
fi

sudo dd if=output/live-image-amd64.hybrid.iso of=$1 bs=1M status=progress

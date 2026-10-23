# Build environment for the USB Cold Storage live image (Debian 13 "trixie")
FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    live-build \
    debootstrap \
    ca-certificates \
    curl \
    gnupg \
    gpgv \
    xorriso \
    squashfs-tools \
    mtools \
    dosfstools \
    grub-efi-amd64-bin \
    grub-pc-bin \
    syslinux \
    syslinux-common \
    syslinux-utils \
    isolinux \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY versions.env build_live_usb.sh /build/
COPY keys/ /build/keys/
COPY overlay/ /build/overlay/
RUN chmod +x /build/build_live_usb.sh

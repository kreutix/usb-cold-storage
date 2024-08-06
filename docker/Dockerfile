# Use an official Debian image as a parent image
FROM debian:bullseye

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install dependencies
RUN apt-get update && apt-get install -y \
    live-build \
    wget \
    sudo \
    python3-pip \
    software-properties-common \
    python3-pyqt5 \
    git \
    util-linux \
    syslinux \
    syslinux-common \
    isolinux \
    fdisk \
    parted \
    tzdata

# Configure timezone
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Add a non-root user
RUN useradd -m builder && echo "builder:password" | chpasswd && adduser builder sudo

# Copy the build script into the container
COPY build_live_usb.sh /home/builder/

# Make the script executable
RUN chmod +x /home/builder/build_live_usb.sh

# Switch to the non-root user
WORKDIR /home/builder

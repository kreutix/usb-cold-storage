# USB Cold Storage

This project aims to create a custom Debian live USB specifically designed for Bitcoin cold storage. It uses `live-build` to create the live USB image. Currently, the project is in its initial stages and is a work in progress.

## Project Status

**Work in Progress**: This project is in its initial stages. Contributions and feedback are welcome.

## Introduction

The USB Cold Storage project allows you to create a secure, offline environment for managing your Bitcoin. By using a custom Debian live USB, you can ensure that your Bitcoin wallet is only accessed in a controlled, offline setting, reducing the risk of online threats and hacks. This is particularly useful for long-term storage of your Bitcoin, also known as "cold storage."

## Prerequisites

- Docker & Git
- A USB stick for testing the live image

## Build Instructions

1. **Clone the Repository**:

    ```bash
    ❯ git clone https://github.com/kreutix/usb-cold-storage.git
    ❯ cd usb-cold-storage
    ```

2. **Build the Docker Image**:

    ```bash
    ❯ cat build.sh
    #!/bin/sh

    docker build --platform=linux/amd64 -t usb-cold-storage-builder .
    
    ❯ ./build.sh
    ```

3. **Run the Docker Container**:

    ```bash
    ❯ cat run.sh
    #!/bin/sh

    docker run --platform=linux/amd64 --rm -it --privileged -v $(pwd)/output:/output usb-cold-storage-builder /home/builder/build_live_usb.sh

    ❯ ./run.sh
    ```

4. **Write the ISO to a USB Stick (on MacOS)**:

    Identify your USB stick (e.g., `/dev/disk4`) and unmount it:

    ```bash
    ❯ diskutil list
    ❯ diskutil unmountDisk /dev/disk4
    ```

    Write the ISO to the USB stick using `dd` while showing a progress bar for copying:

    ```bash
    ❯ cat tousb.sh
    #!/bin/sh

    if [ -z "$1" ]; then
    echo "usage: ./tousb.sh <disk>"
    exit 1
    fi

    sudo dd if=output/usb-cold-storage.iso of=$1 bs=1M status=progress

    ❯ ./tousb.sh /dev/rdisk4
    ```

    Eject the USB stick:

    ```bash
    ❯ diskutil eject /dev/disk2
    ```

## Usage

1. **Boot from USB**: Insert the USB stick into your computer and boot from it. This usually involves pressing a key during startup (such as F12, Esc, or Del) to enter the boot menu and selecting the USB device.

2. **Offline Environment**: Once booted, you will be in a secure, offline environment running Debian with Xfce. Firefox will start automatically with a welcome page.

3. **Manage Bitcoin Wallet**: Use Electrum to manage your Bitcoin wallet securely in this offline environment.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

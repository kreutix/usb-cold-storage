# USB Cold Storage

A custom **Debian 13 "trixie"** live system (amd64) for air-gapped Bitcoin cold storage. It is meant for old x86 hardware that never goes online. It is built with `live-build` inside Docker and boots from a USB stick on both legacy BIOS and UEFI, including **Secure Boot**.

## What's inside

| Component | Version | How it is verified at build time |
|-----------|---------|----------------------------------|
| Debian | 13 "trixie" (+ security updates) | Signed Debian archive |
| Electrum | 4.8.2 (AppImage, starts with `--offline`) | GPG signature by ThomasV `6694D8DE…7F9470E6` |
| Sparrow Wallet | 2.5.5 (.deb, bundled JRE) | GPG-signed manifest by Craig Raw `D4D0D320…4C674B40` + SHA-256 |
| Seedtool | [kreutix/seedtool](https://github.com/kreutix/seedtool) @ `c330f0c` | Pinned SHA-256 |
| Desktop | Xfce, Firefox ESR (opens the seed tool locally) | Debian packages |

All versions, signing-key fingerprints and hashes are pinned in [`docker/versions.env`](docker/versions.env). The signing keys live in [`docker/keys/`](docker/keys/). If a key, signature or hash doesn't match, the build aborts.

## Air-gap hardening

- **No network at all:** every network, Wi-Fi, Bluetooth, NFC and WWAN kernel driver is deleted from the image, including the initramfs. The modules are also blocked via `modprobe.d`. NetworkManager, wpa_supplicant, BlueZ, ModemManager, Avahi, SSH and DHCP are not installed. No firmware packages are included. `ipv6.disable=1` is set.
- **Amnesic:** everything runs from RAM. There is no persistence, swap is masked and core dumps are disabled.
- **Memory hygiene:** `init_on_free=1` and `page_alloc.shuffle=1` are set.
- **Firefox:** enterprise policies disable updates, telemetry and accounts, and point a locked proxy at a dead port.
- **Webcam stays available** (v4l, zbar) so you can scan PSBT QR codes in Sparrow.
- German keyboard/locale, auto-login as user `cold`.

## Build

Prerequisites: Docker and Git. On Apple Silicon you need an amd64-capable runtime that runs amd64 binaries via **qemu-user**, e.g. [Colima](https://github.com/abiosoft/colima):

```bash
colima start --vm-type vz --cpu 6 --memory 12
```

Do **not** use Rosetta (`--vz-rosetta`) for this build. Rosetta needs `/proc` inside the chroot, and that isn't there yet when debootstrap first runs, so debootstrap fails with `chroot … /bin/true`. If Rosetta is already on, switch the handler inside the VM:
`colima ssh -- sudo sh -c 'echo 0 > /proc/sys/fs/binfmt_misc/rosetta; echo 1 > /proc/sys/fs/binfmt_misc/qemu-x86_64'`

```bash
git clone https://github.com/kreutix/usb-cold-storage.git
cd usb-cold-storage
./build.sh   # builder image (Debian trixie + live-build)
./run.sh     # builds output/usb-cold-storage-<version>-amd64.iso (+ .sha256, .packages)
```

`./shell.sh` opens a shell in the builder for debugging.

To update a wallet, change the version in `docker/versions.env` and rebuild. If the signing key has changed, also update the key in `docker/keys/` and its fingerprint, after checking it against the project's website.

## Write the ISO to a USB stick (macOS)

```bash
diskutil list external        # find the stick, e.g. disk4 - check the size!
./tousb.sh disk4              # verifies the checksum, refuses internal disks, asks for YES
```

Manual alternative:

```bash
diskutil unmountDisk /dev/disk4
sudo dd if=output/usb-cold-storage-2026.10-amd64.iso of=/dev/rdisk4 bs=4m
sync && diskutil eject /dev/disk4
```

When macOS then says the disk is not readable, choose **Ignore**. On Windows use Rufus (DD mode); otherwise use balenaEtcher.

## Usage

1. Boot the offline machine from the stick: open the boot menu (usually F12, F11, F8 or Esc) and pick the USB device. Old machines boot via BIOS, newer ones via UEFI. Secure Boot can stay on.
2. Xfce starts and opens Sparrow and the seed tool (Firefox, local file) automatically. Electrum is in the application menu and runs in offline mode.
3. Move PSBTs on and off the machine by QR code (webcam) or SD card/USB stick. The machine itself has no network.

Use a dedicated machine that never connects to the internet.

## Known limitations

- The build is not yet bit-for-bit reproducible (packages come from the live Debian mirror, not a pinned snapshot).
- GRUB can pick the wrong medium when several Debian live sticks are plugged in at the same time ([#1081041](https://bugs.debian.org/1081041)).

## License

MIT, see [LICENSE](LICENSE).

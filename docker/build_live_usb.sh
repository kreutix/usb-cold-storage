#!/bin/bash

# Set variables
DISTRO="bullseye" # Debian 11 (Bullseye)
IMAGE_NAME="usb-cold-storage"
WORK_DIR="/home/builder/live-build"

# Create a working directory
mkdir -p $WORK_DIR
cd $WORK_DIR

# Configure live-build
lb config \
    --distribution $DISTRO \
    --archive-areas "main contrib non-free" \
    --debian-installer false \
    --iso-publisher "Stefan Kreuter <info@kreutix.de>" \
    --iso-volume "USB Cold Storage" \
    --binary-images iso-hybrid \
    --bootappend-live "boot=live components"

# Add Firefox, Xfce, and dependencies for Electrum to the package list
mkdir -p config/package-lists
cat << EOF > config/package-lists/custom.list.chroot
firefox-esr
initramfs-tools
software-properties-common
python3-pyqt5
python3-cryptography
python3-setuptools
python3-pip
libsecp256k1-dev
xfce4
xfce4-goodies
xorg
lightdm
wget
EOF

# Create a hook to install Electrum
mkdir -p config/hooks/live
cat << 'EOF' > config/hooks/live/0500-install-electrum.hook.chroot
#!/bin/bash
# Download Electrum
cd /opt
wget https://download.electrum.org/4.5.5/electrum-4.5.5-x86_64.AppImage
chmod +x electrum-4.5.5-x86_64.AppImage
EOF

chmod +x config/hooks/live/0500-install-electrum.hook.chroot

# Create a hook to add index.html and configure autostart
cat << 'EOF' > config/hooks/live/0501-configure-autostart.hook.chroot
#!/bin/bash
# Create an index.html file
mkdir -p /opt/custom
cd /opt/custom
wget https://github.com/BitcoinQnA/seedtool/releases/download/2.1.0/index.html
EOL

# Create a desktop entry to auto-start Firefox with index.html
mkdir -p /etc/xdg/autostart

cat << 'EOL' > /etc/xdg/autostart/firefox.desktop
[Desktop Entry]
Type=Application
Exec=firefox-esr /opt/custom/index.html
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Firefox
Comment=Auto start Firefox with index.html
EOL

cat << 'EOL' > /etc/xdg/autostart/electrum.desktop
[Desktop Entry]
Type=Application
Exec=/opt/electrum-4.5.5-x86_64.AppImage
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Electrum
Comment=Auto start Electrum
EOL
EOF

chmod +x config/hooks/live/0501-configure-autostart.hook.chroot

# Build the live image using unshare to create a new namespace
lb build

# Move iso to output directory
mv $WORK_DIR/$IMAGE_NAME.iso /output/$IMAGE_NAME.iso

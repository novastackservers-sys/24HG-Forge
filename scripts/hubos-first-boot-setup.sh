#!/bin/bash
# HubOS First Boot Setup — Runs once as root on first boot
# Installs Flatpak apps, configures system, then disables itself

MARKER="/var/lib/hubos/.first-boot-done"

# Skip if already completed
if [ -f "${MARKER}" ]; then
    echo "HubOS first boot already completed, skipping."
    exit 0
fi

echo "=== HubOS First Boot Setup ==="
echo "Installing gaming essentials..."

# Ensure Flathub is configured
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install core gaming Flatpaks
echo "Installing Steam..."
flatpak install -y --noninteractive flathub com.valvesoftware.Steam

echo "Installing Lutris..."
flatpak install -y --noninteractive flathub net.lutris.Lutris

echo "Installing Heroic Games Launcher..."
flatpak install -y --noninteractive flathub com.heroicgameslauncher.hgl

echo "Installing ProtonUp-Qt..."
flatpak install -y --noninteractive flathub net.davidotek.pupgui2

echo "Installing Discord..."
flatpak install -y --noninteractive flathub com.discordapp.Discord

# Install MangoHud Flatpak extension for Steam
flatpak install -y --noninteractive flathub org.freedesktop.Platform.VulkanLayer.MangoHud

# Allow Steam to access MangoHud
flatpak override --user com.valvesoftware.Steam --env=MANGOHUD=1 2>/dev/null || true

# Set GRUB theme if available
if [ -d /usr/share/hubos/grub ]; then
    if [ -f /etc/default/grub ]; then
        # The grub config drop-in handles this
        grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
    fi
fi

# Mark completion
mkdir -p /var/lib/hubos
touch "${MARKER}"

echo "=== HubOS First Boot Setup Complete ==="

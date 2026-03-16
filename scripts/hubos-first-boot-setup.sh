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

echo "Installing OBS Studio..."
flatpak install -y --noninteractive flathub com.obsproject.Studio || true

# Install MangoHud Flatpak extension for Steam
flatpak install -y --noninteractive flathub org.freedesktop.Platform.VulkanLayer.MangoHud

# Allow Steam to access MangoHud and set gamemoderun
flatpak override --user com.valvesoftware.Steam --env=MANGOHUD=1 2>/dev/null || true
flatpak override --user com.valvesoftware.Steam --env=SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0 2>/dev/null || true

# Allow Lutris to access MangoHud
flatpak override --user net.lutris.Lutris --env=MANGOHUD=1 2>/dev/null || true

# Set GRUB theme if available
if [ -d /usr/share/hubos/grub ]; then
    if [ -f /etc/default/grub ]; then
        grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
    fi
fi

# Install Protontricks (for hubos-proton-fix auto-repair)
echo "Installing Protontricks..."
flatpak install -y --noninteractive flathub com.github.Matoking.protontricks || true

# Install latest Proton-GE automatically
echo "Installing latest Proton-GE..."
PROTON_GE_DIR="/var/lib/hubos/proton-ge"
mkdir -p "$PROTON_GE_DIR"
# Download latest GE-Proton release
GE_LATEST=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest 2>/dev/null | \
    grep "browser_download_url.*tar.gz" | head -1 | cut -d'"' -f4) || true
if [ -n "$GE_LATEST" ]; then
    GE_FILENAME=$(basename "$GE_LATEST")
    echo "Downloading $GE_FILENAME..."
    curl -sL "$GE_LATEST" -o "/tmp/$GE_FILENAME" 2>/dev/null || true
    if [ -f "/tmp/$GE_FILENAME" ]; then
        # Install for all users via Steam's compatibilitytools.d
        # Will be copied to user dir on first login
        mkdir -p "$PROTON_GE_DIR"
        tar -xzf "/tmp/$GE_FILENAME" -C "$PROTON_GE_DIR" 2>/dev/null || true
        rm -f "/tmp/$GE_FILENAME"
        echo "Proton-GE installed to $PROTON_GE_DIR"
    fi
else
    echo "Could not fetch Proton-GE (no internet?). Install later via ProtonUp-Qt."
fi

# Allow Discord to talk to other Flatpak sandboxes (Rich Presence)
flatpak override --user com.discordapp.Discord --filesystem=xdg-run/discord-ipc-0 2>/dev/null || true
flatpak override --user com.valvesoftware.Steam --filesystem=xdg-run/discord-ipc-0:ro 2>/dev/null || true

# Enable user services for first user
# (these are in /etc/skel/.config/systemd/user/ so they'll be active for new users)
echo "User services will auto-start on first login:"
echo "  - hubos-server-status (live server monitoring)"
echo "  - hubos-discord-fix (Rich Presence bridge)"
echo "  - hubos-backup.timer (weekly game save backup)"
echo "  - hubos-hub-bridge (Hub notifications, DMs, friend status)"
echo "  - hubos-game-timer (playtime tracking across all launchers)"
echo "  - hubos-proton-updater.timer (daily Proton-GE update check)"

# Enable Chromium desktop notifications for the Hub
mkdir -p /etc/skel/.config/chromium/Default
cat > /etc/skel/.config/chromium/Default/Preferences.hubos 2>/dev/null <<'CHROMEOF'
{
  "profile": {
    "content_settings": {
      "exceptions": {
        "notifications": {
          "https://hub.24hgaming.com,*": {"setting": 1}
        }
      }
    }
  }
}
CHROMEOF

# Mark completion
mkdir -p /var/lib/hubos
touch "${MARKER}"

echo "=== HubOS First Boot Setup Complete ==="

#!/usr/bin/env bash
set -euo pipefail

# Stage all 24HG Forge files into a single directory for a single COPY in the Containerfile
# This avoids the Docker 127-layer limit

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAGE="${SCRIPT_DIR}/.build-staging"

echo "Staging build files into ${STAGE}..."
rm -rf "${STAGE}"
mkdir -p "${STAGE}"/{bin,lib,desktop,etc,usr,branding,data,systemd-user,pipewire,libinput,conky,plasma-splash,skel-kwinrc.d,skel-kservices5,skel-desktop,installer}

# System files
cp -r system_files/etc/* "${STAGE}/etc/" 2>/dev/null || true
cp -r system_files/usr/* "${STAGE}/usr/" 2>/dev/null || true

# Branding
cp -r branding/* "${STAGE}/branding/"

# Hub app
cp hub-app/forge-hub "${STAGE}/bin/"
cp hub-app/forge-hub.desktop "${STAGE}/desktop/"
cp hub-app/forge-session.desktop "${STAGE}/desktop/"
cp hub-app/forge-tray "${STAGE}/bin/"
cp hub-app/forge-tray.desktop "${STAGE}/desktop/"
cp hub-app/forge-gamescope-session "${STAGE}/bin/"

# Desktop files from scripts
for f in scripts/*.desktop; do
    [ -f "$f" ] && cp "$f" "${STAGE}/desktop/"
done

# Lib scripts
for f in scripts/forge-first-boot-setup.sh scripts/configure-steam-servers.sh \
         scripts/forge-auto-update.sh scripts/forge-game-configs.sh \
         scripts/forge-obs-setup.sh scripts/gamemode-start.sh scripts/gamemode-end.sh \
         scripts/forge-update-guard-hook.sh; do
    [ -f "$f" ] && cp "$f" "${STAGE}/lib/$(basename "$f")"
done

# All bin scripts (everything in scripts/ that's not a .sh, .desktop, or helper)
for f in scripts/forge-*; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    # Skip files already handled as lib or desktop
    case "$base" in
        *.desktop|*.sh) continue ;;
    esac
    cp "$f" "${STAGE}/bin/${base}"
done
# (gamemode scripts already copied in lib section above)

# Systemd user services
cp -r system_files/etc/systemd/user/* "${STAGE}/systemd-user/" 2>/dev/null || true

# PipeWire
cp -r system_files/etc/pipewire/* "${STAGE}/pipewire/" 2>/dev/null || true

# libinput
cp -r system_files/etc/libinput/* "${STAGE}/libinput/" 2>/dev/null || true

# Data files
cp system_files/usr/share/forge/servers.json "${STAGE}/data/" 2>/dev/null || true
cp system_files/usr/share/forge/offline.html "${STAGE}/data/" 2>/dev/null || true

# Plasma splash
cp -r system_files/usr/share/plasma/look-and-feel/com.forge.splash/* "${STAGE}/plasma-splash/" 2>/dev/null || true

# Conky
cp -r system_files/etc/skel/.config/conky/* "${STAGE}/conky/" 2>/dev/null || true

# Skel config files
cp system_files/etc/skel/.config/plasmanotifyrc "${STAGE}/plasmanotifyrc" 2>/dev/null || true
cp system_files/etc/skel/.config/dolphinrc "${STAGE}/skel-dolphinrc" 2>/dev/null || true
cp system_files/etc/skel/.config/kwinrulesrc "${STAGE}/skel-kwinrulesrc" 2>/dev/null || true
cp system_files/etc/skel/.config/kscreenlockerrc "${STAGE}/skel-kscreenlockerrc" 2>/dev/null || true
cp -r system_files/etc/skel/.config/kwinrc.d/* "${STAGE}/skel-kwinrc.d/" 2>/dev/null || true
cp system_files/etc/skel/.local/share/user-places.xbel "${STAGE}/skel-user-places.xbel" 2>/dev/null || true
cp -r system_files/etc/skel/.local/share/kservices5/* "${STAGE}/skel-kservices5/" 2>/dev/null || true
cp -r system_files/etc/skel/Desktop/* "${STAGE}/skel-desktop/" 2>/dev/null || true

# Installer
cp -r installer/* "${STAGE}/installer/" 2>/dev/null || true

echo "Staging complete: $(find "${STAGE}" -type f | wc -l) files"

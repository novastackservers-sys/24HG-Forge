## HubOS — 24HG's Custom Gaming Distribution
## Based on Bazzite (Universal Blue) — Fedora Atomic
## https://24hgaming.com/os

ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite"
ARG BASE_TAG="stable"

FROM ${BASE_IMAGE}:${BASE_TAG}

# Build metadata
LABEL org.opencontainers.image.title="HubOS"
LABEL org.opencontainers.image.description="24HG Gaming Distribution — Boot into the 24 Hour Gaming ecosystem"
LABEL org.opencontainers.image.vendor="24 Hour Gaming"
LABEL org.opencontainers.image.url="https://24hgaming.com/os"
LABEL org.opencontainers.image.source="https://github.com/24hg/hubos"

# ============================================================
# Phase 1: System packages & gaming optimizations
# ============================================================

# Hub app, wizard, gaming tools, theming, diagnostics
RUN rpm-ostree install \
    chromium \
    libnotify \
    wmctrl \
    xdotool \
    python3-gobject \
    python3-dbus \
    gtk3 \
    zenity \
    gamemode \
    papirus-icon-theme \
    lm_sensors \
    pciutils \
    vulkan-tools \
    && rpm-ostree cleanup -m

# ============================================================
# Phase 2: Gaming kernel tweaks
# ============================================================

# Sysctl tuning for low-latency gaming
COPY system_files/etc/hubos-gaming-tweaks.conf /etc/sysctl.d/99-hubos-gaming.conf

# Gaming performance service (THP, I/O scheduler, CPU boost)
COPY system_files/etc/systemd/system/hubos-gaming-tweaks.service \
     /etc/systemd/system/hubos-gaming-tweaks.service
RUN systemctl enable hubos-gaming-tweaks.service

# ============================================================
# Phase 3: 24HG Branding
# ============================================================

# Plymouth boot splash
COPY system_files/usr/share/plymouth/themes/hubos/ /usr/share/plymouth/themes/hubos/
RUN plymouth-set-default-theme hubos 2>/dev/null || true

# GRUB theme
COPY branding/grub/ /usr/share/hubos/grub/
COPY system_files/etc/default-grub-config /etc/default/grub.d/50-hubos.cfg

# Wallpapers
COPY branding/wallpapers/ /usr/share/hubos/wallpapers/
COPY system_files/usr/share/gnome-background-properties/hubos-wallpapers.xml \
     /usr/share/gnome-background-properties/hubos-wallpapers.xml

# Icons and logos
COPY branding/icons/ /usr/share/icons/hubos/
COPY branding/icons/hubos-logo.svg /usr/share/pixmaps/hubos-logo.svg

# KDE Plasma theme, panel layout, colors
COPY system_files/etc/skel/.config/kdeglobals /etc/skel/.config/kdeglobals
COPY system_files/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc \
     /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc

# Konsole terminal theme
COPY system_files/etc/skel/.config/konsolerc /etc/skel/.config/konsolerc
COPY system_files/etc/skel/.local/share/konsole/ /etc/skel/.local/share/konsole/

# Neofetch-style system info
COPY scripts/hubos-neofetch /usr/bin/hubos-neofetch
RUN chmod +x /usr/bin/hubos-neofetch

# Shell customizations (aliases, env vars, greeting)
COPY system_files/etc/skel/.bashrc.d/hubos.sh /etc/skel/.bashrc.d/hubos.sh

# ============================================================
# Phase 4: Hub App (Electron + Chromium fallback)
# ============================================================

# Electron app (built separately, or use Chromium kiosk as fallback)
COPY hub-app/hubos-hub /usr/bin/hubos-hub
RUN chmod +x /usr/bin/hubos-hub

# Desktop entry and protocol handler
COPY hub-app/hubos-hub.desktop /usr/share/applications/hubos-hub.desktop

# Register 24hg:// protocol handler
RUN echo "[Desktop Entry]" > /usr/share/applications/hubos-protocol.desktop \
    && echo "Name=24HG Protocol Handler" >> /usr/share/applications/hubos-protocol.desktop \
    && echo "Exec=/usr/bin/hubos-hub %u" >> /usr/share/applications/hubos-protocol.desktop \
    && echo "Type=Application" >> /usr/share/applications/hubos-protocol.desktop \
    && echo "NoDisplay=true" >> /usr/share/applications/hubos-protocol.desktop \
    && echo "MimeType=x-scheme-handler/24hg;" >> /usr/share/applications/hubos-protocol.desktop

# Gamescope session (24HG Mode)
COPY hub-app/hubos-session.desktop /usr/share/wayland-sessions/hubos-session.desktop
COPY hub-app/hubos-gamescope-session /usr/bin/hubos-gamescope-session
RUN chmod +x /usr/bin/hubos-gamescope-session

# ============================================================
# Phase 5: First-Boot Experience
# ============================================================

# First-boot wizard (user-facing, per-user)
COPY scripts/hubos-first-boot /usr/bin/hubos-first-boot
COPY scripts/hubos-first-boot.desktop /usr/share/applications/hubos-first-boot.desktop
COPY system_files/etc/skel/.config/autostart/hubos-hub.desktop \
     /etc/skel/.config/autostart/hubos-hub.desktop
RUN chmod +x /usr/bin/hubos-first-boot \
    # Add first-boot wizard to autostart
    && cp /usr/share/applications/hubos-first-boot.desktop \
          /etc/skel/.config/autostart/hubos-first-boot.desktop

# First-boot system setup (root, installs Flatpaks)
COPY scripts/hubos-first-boot-setup.sh /usr/lib/hubos/first-boot-setup.sh
COPY system_files/etc/systemd/system/hubos-first-boot-setup.service \
     /etc/systemd/system/hubos-first-boot-setup.service
RUN chmod +x /usr/lib/hubos/first-boot-setup.sh \
    && systemctl enable hubos-first-boot-setup.service

# Steam server configurator
COPY scripts/configure-steam-servers.sh /usr/lib/hubos/configure-steam-servers.sh
RUN chmod +x /usr/lib/hubos/configure-steam-servers.sh

# ============================================================
# Phase 6: Auto-Update System
# ============================================================

COPY scripts/hubos-auto-update.sh /usr/lib/hubos/auto-update.sh
COPY system_files/etc/systemd/system/hubos-auto-update.service \
     /etc/systemd/system/hubos-auto-update.service
COPY system_files/etc/systemd/system/hubos-auto-update.timer \
     /etc/systemd/system/hubos-auto-update.timer
RUN chmod +x /usr/lib/hubos/auto-update.sh \
    && systemctl enable hubos-auto-update.timer

# ============================================================
# Phase 7: SDDM Login Theme
# ============================================================

COPY system_files/usr/share/sddm/themes/hubos/ /usr/share/sddm/themes/hubos/
COPY system_files/etc/sddm.conf.d/hubos.conf /etc/sddm.conf.d/hubos.conf

# ============================================================
# Phase 8: GameMode & MangoHud Configuration
# ============================================================

COPY system_files/etc/gamemode.ini /etc/gamemode.ini
COPY system_files/etc/skel/.config/MangoHud/MangoHud.conf \
     /etc/skel/.config/MangoHud/MangoHud.conf

# Flatpak overrides (Steam, Lutris env vars)
COPY system_files/etc/skel/.config/flatpak-overrides/ \
     /etc/skel/.config/flatpak-overrides/

# ============================================================
# Phase 9: Firewall & Networking
# ============================================================

COPY system_files/etc/firewalld/services/hubos-gaming.xml \
     /etc/firewalld/services/hubos-gaming.xml

# ============================================================
# Phase 10: CLI Tools
# ============================================================

# Diagnostics tool
COPY scripts/hubos-diag /usr/bin/hubos-diag
RUN chmod +x /usr/bin/hubos-diag

# Performance profile switcher
COPY scripts/hubos-performance /usr/bin/hubos-performance
RUN chmod +x /usr/bin/hubos-performance

# Game config deployer
COPY scripts/hubos-game-configs.sh /usr/lib/hubos/hubos-game-configs.sh
RUN chmod +x /usr/lib/hubos/hubos-game-configs.sh

# OBS setup script
COPY scripts/hubos-obs-setup.sh /usr/lib/hubos/hubos-obs-setup.sh
RUN chmod +x /usr/lib/hubos/hubos-obs-setup.sh

# TTY branding
COPY system_files/etc/issue /etc/issue

# ============================================================
# Phase 11: Calamares Installer Customization
# ============================================================

COPY installer/branding/ /usr/share/calamares/branding/hubos/
COPY installer/settings.conf /etc/calamares/settings.conf

# ============================================================
# Phase 12: OS Identity
# ============================================================

RUN sed -i 's/^NAME=.*/NAME="HubOS"/' /usr/lib/os-release \
    && sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="HubOS (24 Hour Gaming)"/' /usr/lib/os-release \
    && sed -i 's/^HOME_URL=.*/HOME_URL="https:\/\/24hgaming.com\/os"/' /usr/lib/os-release \
    && sed -i 's/^SUPPORT_URL=.*/SUPPORT_URL="https:\/\/discord.gg\/ymfEjH6EJN"/' /usr/lib/os-release \
    && sed -i 's/^BUG_REPORT_URL=.*/BUG_REPORT_URL="https:\/\/github.com\/24hg\/hubos\/issues"/' /usr/lib/os-release \
    && echo 'VARIANT="24HG Gaming"' >> /usr/lib/os-release \
    && echo 'VARIANT_ID=hubos' >> /usr/lib/os-release

# ============================================================
# Cleanup & Commit
# ============================================================

RUN rpm-ostree cleanup -m \
    && ostree container commit

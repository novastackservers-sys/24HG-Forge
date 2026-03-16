## HubOS — 24HG's Custom Gaming Distribution
## Based on Bazzite (Universal Blue) — Fedora Atomic
## https://24hgaming.com/os

ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite"
ARG BASE_TAG="stable"

FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL org.opencontainers.image.title="HubOS"
LABEL org.opencontainers.image.description="24HG Gaming Distribution — Boot into the 24 Hour Gaming ecosystem"
LABEL org.opencontainers.image.vendor="24 Hour Gaming"
LABEL org.opencontainers.image.url="https://24hgaming.com/os"
LABEL org.opencontainers.image.source="https://os.24hgaming.com"

# ── Copy ALL files first (single context layer) ──
COPY system_files/etc/ /tmp/hubos-build/etc/
COPY system_files/usr/ /tmp/hubos-build/usr/
COPY branding/ /tmp/hubos-build/branding/
COPY hub-app/hubos-hub /tmp/hubos-build/bin/hubos-hub
COPY hub-app/hubos-hub.desktop /tmp/hubos-build/desktop/hubos-hub.desktop
COPY hub-app/hubos-session.desktop /tmp/hubos-build/desktop/hubos-session.desktop
COPY hub-app/hubos-tray /tmp/hubos-build/bin/hubos-tray
COPY hub-app/hubos-tray.desktop /tmp/hubos-build/desktop/hubos-tray.desktop
COPY hub-app/hubos-gamescope-session /tmp/hubos-build/bin/hubos-gamescope-session
COPY scripts/hubos-first-boot /tmp/hubos-build/bin/hubos-first-boot
COPY scripts/hubos-first-boot.desktop /tmp/hubos-build/desktop/hubos-first-boot.desktop
COPY scripts/hubos-first-boot-setup.sh /tmp/hubos-build/lib/first-boot-setup.sh
COPY scripts/configure-steam-servers.sh /tmp/hubos-build/lib/configure-steam-servers.sh
COPY scripts/hubos-auto-update.sh /tmp/hubos-build/lib/auto-update.sh
COPY scripts/hubos-game-configs.sh /tmp/hubos-build/lib/hubos-game-configs.sh
COPY scripts/hubos-obs-setup.sh /tmp/hubos-build/lib/hubos-obs-setup.sh
COPY scripts/hubos-neofetch /tmp/hubos-build/bin/hubos-neofetch
COPY scripts/hubos-diag /tmp/hubos-build/bin/hubos-diag
COPY scripts/hubos-performance /tmp/hubos-build/bin/hubos-performance
COPY system_files/usr/share/hubos/servers.json /tmp/hubos-build/data/servers.json
COPY system_files/usr/share/hubos/offline.html /tmp/hubos-build/data/offline.html
COPY installer/ /tmp/hubos-build/installer/

# ── Single RUN: install packages, deploy files, configure, cleanup ──
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
    libappindicator-gtk3 \
    && rpm-ostree cleanup -m \
    \
    # ── Sysctl gaming tweaks ── \
    && cp /tmp/hubos-build/etc/hubos-gaming-tweaks.conf /etc/sysctl.d/99-hubos-gaming.conf \
    \
    # ── Systemd services ── \
    && cp /tmp/hubos-build/etc/systemd/system/hubos-gaming-tweaks.service /etc/systemd/system/ \
    && cp /tmp/hubos-build/etc/systemd/system/hubos-first-boot-setup.service /etc/systemd/system/ \
    && cp /tmp/hubos-build/etc/systemd/system/hubos-auto-update.service /etc/systemd/system/ \
    && cp /tmp/hubos-build/etc/systemd/system/hubos-auto-update.timer /etc/systemd/system/ \
    && systemctl enable hubos-gaming-tweaks.service \
    && systemctl enable hubos-first-boot-setup.service \
    && systemctl enable hubos-auto-update.timer \
    \
    # ── Plymouth boot splash ── \
    && cp -r /tmp/hubos-build/usr/share/plymouth/themes/hubos /usr/share/plymouth/themes/hubos \
    && (plymouth-set-default-theme hubos 2>/dev/null || true) \
    \
    # ── GRUB theme ── \
    && mkdir -p /usr/share/hubos/grub /etc/default/grub.d \
    && cp -r /tmp/hubos-build/branding/grub/* /usr/share/hubos/grub/ \
    && cp /tmp/hubos-build/etc/default-grub-config /etc/default/grub.d/50-hubos.cfg \
    \
    # ── Wallpapers ── \
    && mkdir -p /usr/share/hubos/wallpapers \
    && cp /tmp/hubos-build/branding/wallpapers/*.png /usr/share/hubos/wallpapers/ \
    && cp /tmp/hubos-build/usr/share/gnome-background-properties/hubos-wallpapers.xml \
          /usr/share/gnome-background-properties/hubos-wallpapers.xml \
    \
    # ── Icons ── \
    && mkdir -p /usr/share/icons/hubos \
    && cp -r /tmp/hubos-build/branding/icons/* /usr/share/icons/hubos/ \
    && cp /tmp/hubos-build/branding/icons/hubos-logo.svg /usr/share/pixmaps/hubos-logo.svg \
    \
    # ── KDE / Konsole / shell theming ── \
    && mkdir -p /etc/skel/.config/autostart /etc/skel/.config/MangoHud \
               /etc/skel/.config/flatpak-overrides /etc/skel/.local/share/konsole \
               /etc/skel/.bashrc.d \
    && cp /tmp/hubos-build/etc/skel/.config/kdeglobals /etc/skel/.config/ \
    && cp /tmp/hubos-build/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc /etc/skel/.config/ \
    && cp /tmp/hubos-build/etc/skel/.config/konsolerc /etc/skel/.config/ \
    && cp /tmp/hubos-build/etc/skel/.local/share/konsole/* /etc/skel/.local/share/konsole/ \
    && cp /tmp/hubos-build/etc/skel/.bashrc.d/hubos.sh /etc/skel/.bashrc.d/ \
    && cp /tmp/hubos-build/etc/skel/.config/MangoHud/MangoHud.conf /etc/skel/.config/MangoHud/ \
    && cp /tmp/hubos-build/etc/skel/.config/flatpak-overrides/* /etc/skel/.config/flatpak-overrides/ \
    \
    # ── SDDM login theme ── \
    && mkdir -p /usr/share/sddm/themes/hubos/icons /etc/sddm.conf.d \
    && cp -r /tmp/hubos-build/usr/share/sddm/themes/hubos/* /usr/share/sddm/themes/hubos/ \
    && cp /tmp/hubos-build/etc/sddm.conf.d/hubos.conf /etc/sddm.conf.d/ \
    \
    # ── GameMode config ── \
    && cp /tmp/hubos-build/etc/gamemode.ini /etc/gamemode.ini \
    \
    # ── Firewall (install service + activate in default zone) ── \
    && mkdir -p /etc/firewalld/services \
    && cp /tmp/hubos-build/etc/firewalld/services/hubos-gaming.xml /etc/firewalld/services/ \
    && mkdir -p /etc/firewalld/zones \
    && (firewall-offline-cmd --zone=FedoraWorkstation --add-service=hubos-gaming 2>/dev/null || true) \
    \
    # ── Hub app + session ── \
    && install -m 755 /tmp/hubos-build/bin/hubos-hub /usr/bin/hubos-hub \
    && install -m 755 /tmp/hubos-build/bin/hubos-tray /usr/bin/hubos-tray \
    && install -m 755 /tmp/hubos-build/bin/hubos-gamescope-session /usr/bin/hubos-gamescope-session \
    && cp /tmp/hubos-build/desktop/hubos-hub.desktop /usr/share/applications/ \
    && mkdir -p /usr/share/wayland-sessions \
    && cp /tmp/hubos-build/desktop/hubos-session.desktop /usr/share/wayland-sessions/ \
    && printf '[Desktop Entry]\nName=24HG Protocol Handler\nExec=/usr/bin/hubos-hub %%u\nType=Application\nNoDisplay=true\nMimeType=x-scheme-handler/24hg;\n' \
       > /usr/share/applications/hubos-protocol.desktop \
    \
    # ── HubOS data (server list, offline page) ── \
    && mkdir -p /usr/share/hubos \
    && cp /tmp/hubos-build/data/servers.json /usr/share/hubos/servers.json \
    && cp /tmp/hubos-build/data/offline.html /usr/share/hubos/offline.html \
    \
    # ── First-boot wizard + autostart ── \
    && install -m 755 /tmp/hubos-build/bin/hubos-first-boot /usr/bin/hubos-first-boot \
    && cp /tmp/hubos-build/desktop/hubos-first-boot.desktop /usr/share/applications/ \
    && cp /tmp/hubos-build/desktop/hubos-hub.desktop /etc/skel/.config/autostart/ \
    && cp /tmp/hubos-build/desktop/hubos-tray.desktop /etc/skel/.config/autostart/ \
    && cp /tmp/hubos-build/desktop/hubos-first-boot.desktop /etc/skel/.config/autostart/ \
    \
    # ── CLI tools ── \
    && install -m 755 /tmp/hubos-build/bin/hubos-neofetch /usr/bin/hubos-neofetch \
    && install -m 755 /tmp/hubos-build/bin/hubos-diag /usr/bin/hubos-diag \
    && install -m 755 /tmp/hubos-build/bin/hubos-performance /usr/bin/hubos-performance \
    \
    # ── Lib scripts ── \
    && mkdir -p /usr/lib/hubos \
    && install -m 755 /tmp/hubos-build/lib/first-boot-setup.sh /usr/lib/hubos/ \
    && install -m 755 /tmp/hubos-build/lib/configure-steam-servers.sh /usr/lib/hubos/ \
    && install -m 755 /tmp/hubos-build/lib/auto-update.sh /usr/lib/hubos/ \
    && install -m 755 /tmp/hubos-build/lib/hubos-game-configs.sh /usr/lib/hubos/ \
    && install -m 755 /tmp/hubos-build/lib/hubos-obs-setup.sh /usr/lib/hubos/ \
    \
    # ── Calamares installer ── \
    && mkdir -p /usr/share/calamares/branding/hubos /etc/calamares \
    && cp -r /tmp/hubos-build/installer/branding/* /usr/share/calamares/branding/hubos/ \
    && cp /tmp/hubos-build/installer/settings.conf /etc/calamares/settings.conf \
    \
    # ── TTY branding ── \
    && cp /tmp/hubos-build/etc/issue /etc/issue \
    \
    # ── OS identity ── \
    && sed -i 's/^NAME=.*/NAME="HubOS"/' /usr/lib/os-release \
    && sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="HubOS (24 Hour Gaming)"/' /usr/lib/os-release \
    && sed -i 's|^HOME_URL=.*|HOME_URL="https://24hgaming.com/os"|' /usr/lib/os-release \
    && sed -i 's|^SUPPORT_URL=.*|SUPPORT_URL="https://discord.gg/ymfEjH6EJN"|' /usr/lib/os-release \
    && sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://discord.gg/ymfEjH6EJN"|' /usr/lib/os-release \
    && echo 'VARIANT="24HG Gaming"' >> /usr/lib/os-release \
    && echo 'VARIANT_ID=hubos' >> /usr/lib/os-release \
    \
    # ── Cleanup build staging ── \
    && rm -rf /tmp/hubos-build \
    && ostree container commit

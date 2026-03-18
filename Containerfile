## 24HG Forge — 24HG's Custom Gaming Distribution
## Based on Bazzite (Universal Blue) — Fedora Atomic
## https://24hgaming.com/os

ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite"
ARG BASE_TAG="stable"

FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL org.opencontainers.image.title="24HG Forge"
LABEL org.opencontainers.image.description="24HG Gaming Distribution — Boot into the 24 Hour Gaming ecosystem"
LABEL org.opencontainers.image.vendor="24 Hour Gaming"
LABEL org.opencontainers.image.url="https://24hgaming.com/os"
LABEL org.opencontainers.image.source="https://os.24hgaming.com"

# ── Copy ALL files in a single layer (avoids Docker 127-layer limit) ──
# Run ./stage-build.sh first to prepare .build-staging/
COPY .build-staging/ /tmp/forge-build/

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
    conky \
    java-21-openjdk \
    && rpm-ostree cleanup -m \
    \
    # ── Sysctl gaming tweaks ── \
    && cp /tmp/forge-build/etc/forge-gaming-tweaks.conf /etc/sysctl.d/99-forge-gaming.conf \
    \
    # ── Systemd services ── \
    && cp /tmp/forge-build/etc/systemd/system/forge-gaming-tweaks.service /etc/systemd/system/ \
    && cp /tmp/forge-build/etc/systemd/system/forge-first-boot-setup.service /etc/systemd/system/ \
    && cp /tmp/forge-build/etc/systemd/system/forge-auto-update.service /etc/systemd/system/ \
    && cp /tmp/forge-build/etc/systemd/system/forge-auto-update.timer /etc/systemd/system/ \
    && systemctl enable forge-gaming-tweaks.service \
    && systemctl enable forge-first-boot-setup.service \
    && systemctl enable forge-auto-update.timer \
    \
    # ── Plymouth boot splash ── \
    && cp -r /tmp/forge-build/usr/share/plymouth/themes/forge /usr/share/plymouth/themes/forge \
    && (plymouth-set-default-theme forge 2>/dev/null || true) \
    \
    # ── GRUB theme ── \
    && mkdir -p /usr/share/forge/grub /etc/default/grub.d \
    && cp -r /tmp/forge-build/branding/grub/* /usr/share/forge/grub/ \
    && cp /tmp/forge-build/etc/default-grub-config /etc/default/grub.d/50-forge.cfg \
    \
    # ── Wallpapers ── \
    && mkdir -p /usr/share/forge/wallpapers \
    && cp /tmp/forge-build/branding/wallpapers/*.png /usr/share/forge/wallpapers/ \
    && mkdir -p /usr/share/gnome-background-properties \
    && cp /tmp/forge-build/usr/share/gnome-background-properties/forge-wallpapers.xml \
          /usr/share/gnome-background-properties/forge-wallpapers.xml \
    \
    # ── Icons ── \
    && mkdir -p /usr/share/icons/forge \
    && cp -r /tmp/forge-build/branding/icons/* /usr/share/icons/forge/ \
    && mkdir -p /usr/share/pixmaps \
    && cp /tmp/forge-build/branding/icons/forge-logo.svg /usr/share/pixmaps/forge-logo.svg \
    \
    # ── KDE / Konsole / shell theming ── \
    && mkdir -p /etc/skel/.config/autostart /etc/skel/.config/MangoHud \
               /etc/skel/.config/flatpak-overrides /etc/skel/.local/share/konsole \
               /etc/skel/.bashrc.d \
    && cp /tmp/forge-build/etc/skel/.config/kdeglobals /etc/skel/.config/ \
    && cp /tmp/forge-build/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc /etc/skel/.config/ \
    && cp /tmp/forge-build/etc/skel/.config/konsolerc /etc/skel/.config/ \
    && cp /tmp/forge-build/etc/skel/.local/share/konsole/* /etc/skel/.local/share/konsole/ \
    && cp /tmp/forge-build/etc/skel/.bashrc.d/forge.sh /etc/skel/.bashrc.d/ \
    && cp /tmp/forge-build/etc/skel/.config/MangoHud/MangoHud.conf /etc/skel/.config/MangoHud/ \
    && cp /tmp/forge-build/etc/skel/.config/flatpak-overrides/* /etc/skel/.config/flatpak-overrides/ \
    && mkdir -p /etc/skel/.config/kglobalshortcutsrc.d \
    && cp /tmp/forge-build/etc/skel/.config/kglobalshortcutsrc.d/forge.conf /etc/skel/.config/kglobalshortcutsrc.d/ \
    \
    # ── Conky desktop widget ── \
    && mkdir -p /etc/skel/.config/conky \
    && cp /tmp/forge-build/conky/forge.conf /etc/skel/.config/conky/ \
    && cp /tmp/forge-build/conky/forge-json.lua /etc/skel/.config/conky/ \
    && cp /tmp/forge-build/etc/skel/.config/autostart/forge-conky.desktop /etc/skel/.config/autostart/ \
    \
    # ── Notification config ── \
    && cp /tmp/forge-build/plasmanotifyrc /etc/skel/.config/plasmanotifyrc \
    \
    # ── Dolphin + KWin + Lock screen + Desktop shortcuts ── \
    && cp /tmp/forge-build/skel-dolphinrc /etc/skel/.config/dolphinrc \
    && cp /tmp/forge-build/skel-kwinrulesrc /etc/skel/.config/kwinrulesrc \
    && cp /tmp/forge-build/skel-kscreenlockerrc /etc/skel/.config/kscreenlockerrc \
    && mkdir -p /etc/skel/.config/kwinrc.d \
    && cp /tmp/forge-build/skel-kwinrc.d/* /etc/skel/.config/kwinrc.d/ \
    && mkdir -p /etc/skel/.local/share \
    && cp /tmp/forge-build/skel-user-places.xbel /etc/skel/.local/share/user-places.xbel \
    && mkdir -p /etc/skel/.local/share/kservices5/ServiceMenus \
    && cp -r /tmp/forge-build/skel-kservices5/* /etc/skel/.local/share/kservices5/ \
    && mkdir -p /etc/skel/Desktop \
    && cp /tmp/forge-build/skel-desktop/*.desktop /etc/skel/Desktop/ \
    \
    # ── Sound theme (uses freedesktop defaults) ── \
    \
    # ── KDE Plasma splash screen ── \
    && mkdir -p /usr/share/plasma/look-and-feel/com.forge.splash/contents/splash \
    && cp -r /tmp/forge-build/plasma-splash/* /usr/share/plasma/look-and-feel/com.forge.splash/ \
    \
    # ── SDDM login theme ── \
    && mkdir -p /usr/share/sddm/themes/forge/icons /etc/sddm.conf.d \
    && cp -r /tmp/forge-build/usr/share/sddm/themes/forge/* /usr/share/sddm/themes/forge/ \
    && cp /tmp/forge-build/etc/sddm.conf.d/forge.conf /etc/sddm.conf.d/ \
    \
    # ── GameMode config ── \
    && cp /tmp/forge-build/etc/gamemode.ini /etc/gamemode.ini \
    \
    # ── Firewall (install service + activate in default zone) ── \
    && mkdir -p /etc/firewalld/services \
    && cp /tmp/forge-build/etc/firewalld/services/forge-gaming.xml /etc/firewalld/services/ \
    && mkdir -p /etc/firewalld/zones \
    && (firewall-offline-cmd --zone=FedoraWorkstation --add-service=forge-gaming 2>/dev/null || true) \
    \
    # ── Hub app + session ── \
    && install -m 755 /tmp/forge-build/bin/forge-hub /usr/bin/forge-hub \
    && install -m 755 /tmp/forge-build/bin/forge-tray /usr/bin/forge-tray \
    && install -m 755 /tmp/forge-build/bin/forge-gamescope-session /usr/bin/forge-gamescope-session \
    && cp /tmp/forge-build/desktop/forge-hub.desktop /usr/share/applications/ \
    && mkdir -p /usr/share/wayland-sessions \
    && cp /tmp/forge-build/desktop/forge-session.desktop /usr/share/wayland-sessions/ \
    && printf '[Desktop Entry]\nName=24HG Protocol Handler\nExec=/usr/bin/forge-hub %%u\nType=Application\nNoDisplay=true\nMimeType=x-scheme-handler/24hg;\n' \
       > /usr/share/applications/forge-protocol.desktop \
    \
    # ── 24HG Forge data (server list, offline page) ── \
    && mkdir -p /usr/share/forge \
    && cp /tmp/forge-build/data/servers.json /usr/share/forge/servers.json \
    && cp /tmp/forge-build/data/offline.html /usr/share/forge/offline.html \
    \
    # ── First-boot wizard + autostart ── \
    && install -m 755 /tmp/forge-build/bin/forge-first-boot /usr/bin/forge-first-boot \
    && cp /tmp/forge-build/desktop/forge-first-boot.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-hub.desktop /etc/skel/.config/autostart/ \
    && cp /tmp/forge-build/desktop/forge-tray.desktop /etc/skel/.config/autostart/ \
    && cp /tmp/forge-build/desktop/forge-first-boot.desktop /etc/skel/.config/autostart/ \
    && cp /tmp/forge-build/desktop/forge-update-prompt.desktop /etc/skel/.config/autostart/ \
    \
    # ── CLI tools ── \
    && install -m 755 /tmp/forge-build/bin/forge-neofetch /usr/bin/forge-neofetch \
    && install -m 755 /tmp/forge-build/bin/forge-diag /usr/bin/forge-diag \
    && install -m 755 /tmp/forge-build/bin/forge-performance /usr/bin/forge-performance \
    && install -m 755 /tmp/forge-build/bin/forge-server-status /usr/bin/forge-server-status \
    && install -m 755 /tmp/forge-build/bin/forge-netguard /usr/bin/forge-netguard \
    && install -m 755 /tmp/forge-build/bin/forge-proton-fix /usr/bin/forge-proton-fix \
    && install -m 755 /tmp/forge-build/bin/forge-replay /usr/bin/forge-replay \
    && install -m 755 /tmp/forge-build/bin/forge-input /usr/bin/forge-input \
    && install -m 755 /tmp/forge-build/bin/forge-audio /usr/bin/forge-audio \
    && install -m 755 /tmp/forge-build/bin/forge-discord-fix /usr/bin/forge-discord-fix \
    && install -m 755 /tmp/forge-build/bin/forge-screenshot /usr/bin/forge-screenshot \
    && install -m 755 /tmp/forge-build/bin/forge-backup /usr/bin/forge-backup \
    && install -m 755 /tmp/forge-build/bin/forge-nightlight /usr/bin/forge-nightlight \
    && install -m 755 /tmp/forge-build/bin/forge-benchmark /usr/bin/forge-benchmark \
    && install -m 755 /tmp/forge-build/bin/forge-hub-bridge /usr/bin/forge-hub-bridge \
    && install -m 755 /tmp/forge-build/bin/forge-game-profiles /usr/bin/forge-game-profiles \
    && install -m 755 /tmp/forge-build/bin/forge-game-setup /usr/bin/forge-game-setup \
    && install -m 755 /tmp/forge-build/bin/forge-controller /usr/bin/forge-controller \
    && install -m 755 /tmp/forge-build/bin/forge-proton-updater /usr/bin/forge-proton-updater \
    && install -m 755 /tmp/forge-build/bin/forge-game-timer /usr/bin/forge-game-timer \
    && install -m 755 /tmp/forge-build/bin/forge-stream /usr/bin/forge-stream \
    && install -m 755 /tmp/forge-build/bin/forge-shader-cache /usr/bin/forge-shader-cache \
    && install -m 755 /tmp/forge-build/bin/forge-sounds /usr/bin/forge-sounds \
    && install -m 755 /tmp/forge-build/bin/forge-tips /usr/bin/forge-tips \
    && install -m 755 /tmp/forge-build/bin/forge-achievements /usr/bin/forge-achievements \
    && install -m 755 /tmp/forge-build/bin/forge-wallpaper /usr/bin/forge-wallpaper \
    && install -m 755 /tmp/forge-build/bin/forge-notify-style /usr/bin/forge-notify-style \
    && install -m 755 /tmp/forge-build/bin/forge-desktop-setup /usr/bin/forge-desktop-setup \
    && install -m 755 /tmp/forge-build/bin/forge-lock-info /usr/bin/forge-lock-info \
    && install -m 755 /tmp/forge-build/bin/forge-compat /usr/bin/forge-compat \
    && install -m 755 /tmp/forge-build/bin/forge-crash-fix /usr/bin/forge-crash-fix \
    && install -m 755 /tmp/forge-build/bin/forge-display /usr/bin/forge-display \
    && install -m 755 /tmp/forge-build/bin/forge-discord-screen /usr/bin/forge-discord-screen \
    && install -m 755 /tmp/forge-build/bin/forge-prefix /usr/bin/forge-prefix \
    && install -m 755 /tmp/forge-build/bin/forge-dualboot /usr/bin/forge-dualboot \
    && install -m 755 /tmp/forge-build/bin/forge-migrate /usr/bin/forge-migrate \
    && install -m 755 /tmp/forge-build/bin/forge-benchmark-compare /usr/bin/forge-benchmark-compare \
    && install -m 755 /tmp/forge-build/bin/forge-perks /usr/bin/forge-perks \
    && install -m 755 /tmp/forge-build/bin/forge-creator-kit /usr/bin/forge-creator-kit \
    && install -m 755 /tmp/forge-build/bin/forge-demo /usr/bin/forge-demo \
    && cp /tmp/forge-build/desktop/forge-demo.desktop /usr/share/applications/ \
    && install -m 755 /tmp/forge-build/bin/forge-smart-launch /usr/bin/forge-smart-launch \
    && install -m 755 /tmp/forge-build/bin/forge-session-summary /usr/bin/forge-session-summary \
    && install -m 755 /tmp/forge-build/bin/forge-crash-recovery /usr/bin/forge-crash-recovery \
    && install -m 755 /tmp/forge-build/bin/forge-download-mgr /usr/bin/forge-download-mgr \
    && install -m 755 /tmp/forge-build/bin/forge-games /usr/bin/forge-games \
    && install -m 755 /tmp/forge-build/bin/forge-thermal /usr/bin/forge-thermal \
    && install -m 755 /tmp/forge-build/bin/forge-anticheat-tracker /usr/bin/forge-anticheat-tracker \
    && install -m 755 /tmp/forge-build/bin/forge-mod-manager /usr/bin/forge-mod-manager \
    && cp /tmp/forge-build/desktop/forge-nxm-handler.desktop /usr/share/applications/ \
    && install -m 755 /tmp/forge-build/bin/forge-hdr /usr/bin/forge-hdr \
    && install -m 755 /tmp/forge-build/bin/forge-flatpak-fix /usr/bin/forge-flatpak-fix \
    && install -m 755 /tmp/forge-build/bin/forge-update-guard /usr/bin/forge-update-guard \
    && install -m 755 /tmp/forge-build/bin/forge-save-manager /usr/bin/forge-save-manager \
    && install -m 755 /tmp/forge-build/bin/forge-nvidia-wayland /usr/bin/forge-nvidia-wayland \
    && install -m 755 /tmp/forge-build/bin/forge-update-prompt /usr/bin/forge-update-prompt \
    \
    # ── Lib scripts ── \
    && mkdir -p /usr/lib/forge \
    && install -m 755 /tmp/forge-build/lib/forge-first-boot-setup.sh /usr/lib/forge/first-boot-setup.sh \
    && install -m 755 /tmp/forge-build/lib/configure-steam-servers.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/forge-auto-update.sh /usr/lib/forge/auto-update.sh \
    && install -m 755 /tmp/forge-build/lib/forge-game-configs.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/forge-obs-setup.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/gamemode-start.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/gamemode-end.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/forge-update-guard-hook.sh /usr/lib/forge/ \
    \
    # ── User systemd services ── \
    && mkdir -p /etc/skel/.config/systemd/user/default.target.wants \
    && cp /tmp/forge-build/systemd-user/forge-server-status.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-replay.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-discord-fix.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-backup.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-backup.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-hub-bridge.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-game-timer.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-proton-updater.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-proton-updater.timer /etc/skel/.config/systemd/user/ \
    && ln -sf ../forge-server-status.service /etc/skel/.config/systemd/user/default.target.wants/forge-server-status.service \
    && ln -sf ../forge-discord-fix.service /etc/skel/.config/systemd/user/default.target.wants/forge-discord-fix.service \
    && ln -sf ../forge-hub-bridge.service /etc/skel/.config/systemd/user/default.target.wants/forge-hub-bridge.service \
    && ln -sf ../forge-game-timer.service /etc/skel/.config/systemd/user/default.target.wants/forge-game-timer.service \
    && mkdir -p /etc/skel/.config/systemd/user/timers.target.wants \
    && ln -sf ../forge-backup.timer /etc/skel/.config/systemd/user/timers.target.wants/forge-backup.timer \
    && ln -sf ../forge-proton-updater.timer /etc/skel/.config/systemd/user/timers.target.wants/forge-proton-updater.timer \
    && cp /tmp/forge-build/systemd-user/forge-achievements.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-achievements.timer /etc/skel/.config/systemd/user/ \
    && ln -sf ../forge-achievements.timer /etc/skel/.config/systemd/user/timers.target.wants/forge-achievements.timer \
    && cp /tmp/forge-build/systemd-user/forge-perks-claim.service /etc/skel/.config/systemd/user/ \
    && ln -sf ../forge-perks-claim.service /etc/skel/.config/systemd/user/default.target.wants/forge-perks-claim.service \
    && cp /tmp/forge-build/systemd-user/forge-smart-launch.service /etc/skel/.config/systemd/user/ \
    && ln -sf ../forge-smart-launch.service /etc/skel/.config/systemd/user/default.target.wants/forge-smart-launch.service \
    && cp /tmp/forge-build/systemd-user/forge-anticheat-tracker.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-anticheat-tracker.timer /etc/skel/.config/systemd/user/ \
    && ln -sf ../forge-anticheat-tracker.timer /etc/skel/.config/systemd/user/timers.target.wants/forge-anticheat-tracker.timer \
    && cp /tmp/forge-build/systemd-user/forge-wallpaper.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-wallpaper.timer /etc/skel/.config/systemd/user/ \
    && ln -sf ../forge-wallpaper.timer /etc/skel/.config/systemd/user/timers.target.wants/forge-wallpaper.timer \
    \
    # ── PipeWire gaming config ── \
    && mkdir -p /etc/pipewire/pipewire.conf.d \
    && cp /tmp/forge-build/pipewire/pipewire.conf.d/99-forge-defaults.conf /etc/pipewire/pipewire.conf.d/ \
    \
    # ── libinput gaming quirks ── \
    && mkdir -p /etc/libinput \
    && cp /tmp/forge-build/libinput/local-overrides.quirks /etc/libinput/ \
    \
    # ── Calamares installer ── \
    && mkdir -p /usr/share/calamares/branding/forge /etc/calamares \
    && cp -r /tmp/forge-build/installer/branding/* /usr/share/calamares/branding/forge/ \
    && cp /tmp/forge-build/installer/settings.conf /etc/calamares/settings.conf \
    \
    # ── TTY branding ── \
    && cp /tmp/forge-build/etc/issue /etc/issue \
    \
    # ── OS identity ── \
    && sed -i 's/^NAME=.*/NAME="24HG Forge"/' /usr/lib/os-release \
    && sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="24HG Forge (24 Hour Gaming)"/' /usr/lib/os-release \
    && sed -i 's|^HOME_URL=.*|HOME_URL="https://24hgaming.com/os"|' /usr/lib/os-release \
    && sed -i 's|^SUPPORT_URL=.*|SUPPORT_URL="https://discord.gg/ymfEjH6EJN"|' /usr/lib/os-release \
    && sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://discord.gg/ymfEjH6EJN"|' /usr/lib/os-release \
    && echo 'VARIANT="24HG Gaming"' >> /usr/lib/os-release \
    && echo 'VARIANT_ID=forge' >> /usr/lib/os-release \
    \
    # ── Cleanup build staging ── \
    && rm -rf /tmp/forge-build \
    && ostree container commit

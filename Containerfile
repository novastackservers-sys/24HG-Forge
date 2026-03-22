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
    fastfetch \
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
    && cp /tmp/forge-build/etc/systemd/system/forge-heartbeat.service /etc/systemd/system/ \
    && cp /tmp/forge-build/etc/systemd/system/forge-heartbeat.timer /etc/systemd/system/ \
    && systemctl enable forge-gaming-tweaks.service \
    && systemctl enable forge-first-boot-setup.service \
    && systemctl enable forge-auto-update.timer \
    && systemctl enable forge-heartbeat.timer \
    && cp /tmp/forge-build/etc/systemd/system/forge-parental.service /etc/systemd/system/ \
    \
    # ── Plymouth boot splash (remove ALL upstream branding, install 24HG) ── \
    && rm -rf /usr/share/plymouth/themes/spinner/watermark.png 2>/dev/null || true \
    && rm -rf /usr/share/plymouth/themes/bgrt/* 2>/dev/null || true \
    && rm -f /usr/share/pixmaps/fedora-gdm-logo.png \
              /usr/share/pixmaps/fedora-logo.png \
              /usr/share/pixmaps/fedora-logo-small.png \
              /usr/share/pixmaps/system-logo-white.png 2>/dev/null || true \
    && cp -r /tmp/forge-build/usr/share/plymouth/themes/forge /usr/share/plymouth/themes/forge \
    \
    # Write Plymouth config directly (plymouth-set-default-theme fails in containers) \
    && mkdir -p /etc/plymouth \
    && printf '[Daemon]\nTheme=forge\nShowDelay=0\n' > /etc/plymouth/plymouthd.conf \
    \
    # Also override the spinner theme (fallback used by many initramfs configs) \
    && [ -d /usr/share/plymouth/themes/spinner ] \
    && cp /tmp/forge-build/usr/share/plymouth/themes/forge/logo.png /usr/share/plymouth/themes/spinner/watermark.png 2>/dev/null || true \
    \
    # Remove Bazzite/Fedora plymouth branding that could override ours \
    && rm -f /usr/share/plymouth/themes/spinner/bgrt-fallback.png 2>/dev/null || true \
    && for f in /usr/share/plymouth/themes/bazzite* /usr/share/plymouth/themes/fedora*; do \
         [ -d "$f" ] && rm -rf "$f"; \
       done 2>/dev/null || true \
    \
    # Ensure alternatives point to our theme \
    && if [ -d /etc/alternatives ]; then \
         ln -sf /usr/share/plymouth/themes/forge/forge.plymouth /etc/alternatives/default.plymouth 2>/dev/null || true; \
       fi \
    \
    # ── GRUB theme ── \
    && mkdir -p /usr/share/forge/grub /etc/default/grub.d \
    && cp -r /tmp/forge-build/branding/grub/* /usr/share/forge/grub/ \
    && cp /tmp/forge-build/etc/default-grub-config /etc/default/grub.d/50-forge.cfg \
    # Also write to /etc/default/grub directly as fallback \
    && if [ -f /etc/default/grub ]; then \
         sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="24HG Forge"/' /etc/default/grub; \
         grep -q 'GRUB_THEME' /etc/default/grub || echo 'GRUB_THEME="/usr/share/forge/grub/theme.txt"' >> /etc/default/grub; \
       fi \
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
    && cp /tmp/forge-build/branding/icons/forge-logo.svg /usr/share/pixmaps/system-logo-white.png 2>/dev/null || true \
    && cp /tmp/forge-build/branding/icons/forge-logo.svg /usr/share/pixmaps/fedora-logo.png 2>/dev/null || true \
    && cp /tmp/forge-build/branding/icons/forge-logo.svg /usr/share/pixmaps/fedora-gdm-logo.png 2>/dev/null || true \
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
    && mkdir -p /etc/bash_completion.d \
    && cp /tmp/forge-build/etc/bash_completion.d/forge-completions.bash /etc/bash_completion.d/ \
    && cp /tmp/forge-build/etc/skel/.config/MangoHud/MangoHud.conf /etc/skel/.config/MangoHud/ \
    && mkdir -p /etc/skel/.config/fastfetch \
    && cp /tmp/forge-build/etc/skel/.config/fastfetch/config.jsonc /etc/skel/.config/fastfetch/ \
    && cp /tmp/forge-build/etc/skel/.config/fastfetch/logo.txt /etc/skel/.config/fastfetch/ \
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
    && cp /tmp/forge-build/skel-spectaclerc /etc/skel/.config/spectaclerc \
    && cp /tmp/forge-build/skel-ksplashrc /etc/skel/.config/ksplashrc \
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
    # ── KDE Plasma Hub Widget (Plasmoid) ── \
    && mkdir -p /usr/share/plasma/plasmoids/com.24hg.hubwidget \
    && cp -r /tmp/forge-build/usr/share/plasma/plasmoids/com.24hg.hubwidget/* /usr/share/plasma/plasmoids/com.24hg.hubwidget/ \
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
    \
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
    # ── Wave 13: Killer features ── \
    && install -m 755 /tmp/forge-build/bin/forge-sunshine-setup /usr/bin/forge-sunshine-setup \
    && install -m 755 /tmp/forge-build/bin/forge-clip /usr/bin/forge-clip \
    && install -m 755 /tmp/forge-build/bin/forge-lan-party /usr/bin/forge-lan-party \
    && install -m 755 /tmp/forge-build/bin/forge-radio /usr/bin/forge-radio \
    && install -m 755 /tmp/forge-build/bin/forge-rig-score /usr/bin/forge-rig-score \
    && install -m 755 /tmp/forge-build/bin/forge-invite /usr/bin/forge-invite \
    && install -m 755 /tmp/forge-build/bin/forge-game-compat /usr/bin/forge-game-compat \
    && install -m 755 /tmp/forge-build/bin/forge-tournament /usr/bin/forge-tournament \
    && install -m 755 /tmp/forge-build/bin/forge-live-wallpaper /usr/bin/forge-live-wallpaper \
    && install -m 755 /tmp/forge-build/bin/forge-hw-optimizer /usr/bin/forge-hw-optimizer \
    && cp /tmp/forge-build/desktop/forge-clip.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-radio.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-sunshine-setup.desktop /usr/share/applications/ \
    \
    # ── Wave 14: Social + Intelligence ── \
    && install -m 755 /tmp/forge-build/bin/forge-overlay /usr/bin/forge-overlay \
    && install -m 755 /tmp/forge-build/bin/forge-cloud-saves /usr/bin/forge-cloud-saves \
    && install -m 755 /tmp/forge-build/bin/forge-launch /usr/bin/forge-launch \
    && install -m 755 /tmp/forge-build/bin/forge-ping-optimizer /usr/bin/forge-ping-optimizer \
    && install -m 755 /tmp/forge-build/bin/forge-rescue /usr/bin/forge-rescue \
    && install -m 755 /tmp/forge-build/bin/forge-gallery /usr/bin/forge-gallery \
    && install -m 755 /tmp/forge-build/bin/forge-mods /usr/bin/forge-mods \
    && cp /tmp/forge-build/desktop/forge-overlay.desktop /usr/share/applications/ \
    \
    # ── Wave 15: Infrastructure ── \
    && install -m 755 /tmp/forge-build/bin/forge-vpn /usr/bin/forge-vpn \
    && install -m 755 /tmp/forge-build/bin/forge-retro /usr/bin/forge-retro \
    && install -m 755 /tmp/forge-build/bin/forge-voice /usr/bin/forge-voice \
    && cp /tmp/forge-build/desktop/forge-vpn.desktop /usr/share/applications/ \
    \
    # ── Wave 16: Polish + Security ── \
    && install -m 755 /tmp/forge-build/bin/forge-settings /usr/bin/forge-settings \
    && install -m 755 /tmp/forge-build/bin/forge-notify /usr/bin/forge-notify \
    && install -m 755 /tmp/forge-build/bin/forge-tour /usr/bin/forge-tour \
    && install -m 755 /tmp/forge-build/bin/forge-digest /usr/bin/forge-digest \
    && install -m 755 /tmp/forge-build/bin/forge-feed /usr/bin/forge-feed \
    && install -m 755 /tmp/forge-build/bin/forge-themes /usr/bin/forge-themes \
    && install -m 755 /tmp/forge-build/bin/forge-firewall /usr/bin/forge-firewall \
    && install -m 755 /tmp/forge-build/bin/forge-crash-report /usr/bin/forge-crash-report \
    && install -m 755 /tmp/forge-build/bin/forge-mirror /usr/bin/forge-mirror \
    && cp /tmp/forge-build/desktop/forge-tour.desktop /usr/share/applications/ \
    \
    # ── Wave 17: Smart Gaming + Family + Hardware ── \
    && install -m 755 /tmp/forge-build/bin/forge-ai /usr/bin/forge-ai \
    && install -m 755 /tmp/forge-build/bin/forge-perflog /usr/bin/forge-perflog \
    && install -m 755 /tmp/forge-build/bin/forge-deals /usr/bin/forge-deals \
    && install -m 755 /tmp/forge-build/bin/forge-highlights /usr/bin/forge-highlights \
    && install -m 755 /tmp/forge-build/bin/forge-parental /usr/bin/forge-parental \
    && install -m 755 /tmp/forge-build/bin/forge-a11y /usr/bin/forge-a11y \
    && install -m 755 /tmp/forge-build/bin/forge-laptop /usr/bin/forge-laptop \
    && install -m 755 /tmp/forge-build/bin/forge-controllers /usr/bin/forge-controllers \
    && install -m 755 /tmp/forge-build/bin/forge-challenges /usr/bin/forge-challenges \
    && install -m 755 /tmp/forge-build/bin/forge-discord-rpc /usr/bin/forge-discord-rpc \
    && install -m 755 /tmp/forge-build/bin/forge-snapshot /usr/bin/forge-snapshot \
    && install -m 755 /tmp/forge-build/bin/forge-windows-import /usr/bin/forge-windows-import \
    \
    \
    # ── Wave 18: Server Hosting + Streaming + Hardware + QoL ── \
    && install -m 755 /tmp/forge-build/bin/forge-host /usr/bin/forge-host \
    && install -m 755 /tmp/forge-build/bin/forge-go-live /usr/bin/forge-go-live \
    && install -m 755 /tmp/forge-build/bin/forge-record /usr/bin/forge-record \
    && install -m 755 /tmp/forge-build/bin/forge-vr /usr/bin/forge-vr \
    && install -m 755 /tmp/forge-build/bin/forge-gamedrive /usr/bin/forge-gamedrive \
    && install -m 755 /tmp/forge-build/bin/forge-nas /usr/bin/forge-nas \
    && install -m 755 /tmp/forge-build/bin/forge-proton-pick /usr/bin/forge-proton-pick \
    && install -m 755 /tmp/forge-build/bin/forge-game-backup /usr/bin/forge-game-backup \
    && install -m 755 /tmp/forge-build/bin/forge-splitscreen /usr/bin/forge-splitscreen \
    && install -m 755 /tmp/forge-build/bin/forge-focus /usr/bin/forge-focus \
    && install -m 755 /tmp/forge-build/bin/forge-help /usr/bin/forge-help \
    \
    # ── Wave 19: Smart Gaming OS Features ── \
    && install -m 755 /tmp/forge-build/bin/forge-game-ready /usr/bin/forge-game-ready \
    && install -m 755 /tmp/forge-build/bin/forge-smart-updates /usr/bin/forge-smart-updates \
    && install -m 755 /tmp/forge-build/bin/forge-quick-resume /usr/bin/forge-quick-resume \
    && install -m 755 /tmp/forge-build/bin/forge-hw-scout /usr/bin/forge-hw-scout \
    && install -m 755 /tmp/forge-build/bin/forge-game-installer /usr/bin/forge-game-installer \
    && install -m 755 /tmp/forge-build/bin/forge-lan-mode /usr/bin/forge-lan-mode \
    && install -m 755 /tmp/forge-build/bin/forge-perf-profiles /usr/bin/forge-perf-profiles \
    && install -m 755 /tmp/forge-build/bin/forge-boot-select /usr/bin/forge-boot-select \
    && install -m 755 /tmp/forge-build/bin/forge-driver-mgr /usr/bin/forge-driver-mgr \
    && install -m 755 /tmp/forge-build/bin/forge-net-optimizer /usr/bin/forge-net-optimizer \
    && install -m 755 /tmp/forge-build/bin/forge-game-migrate /usr/bin/forge-game-migrate \
    && install -m 755 /tmp/forge-build/bin/forge-tray-dashboard /usr/bin/forge-tray-dashboard \
    && install -m 755 /tmp/forge-build/bin/forge-sandbox /usr/bin/forge-sandbox \
    && install -m 755 /tmp/forge-build/bin/forge-power-plan /usr/bin/forge-power-plan \
    && install -m 755 /tmp/forge-build/bin/forge-one-click-server /usr/bin/forge-one-click-server \
    \
    # ── Wave 20: Hardware Control + Polish ── \
    && install -m 755 /tmp/forge-build/bin/forge-peripherals /usr/bin/forge-peripherals \
    && install -m 755 /tmp/forge-build/bin/forge-input-lag /usr/bin/forge-input-lag \
    && install -m 755 /tmp/forge-build/bin/forge-audio-router /usr/bin/forge-audio-router \
    && install -m 755 /tmp/forge-build/bin/forge-cleaner /usr/bin/forge-cleaner \
    && install -m 755 /tmp/forge-build/bin/forge-dual-gpu /usr/bin/forge-dual-gpu \
    && install -m 755 /tmp/forge-build/bin/forge-mod-manager /usr/bin/forge-mod-manager \
    && install -m 755 /tmp/forge-build/bin/forge-custom-res /usr/bin/forge-custom-res \
    && install -m 755 /tmp/forge-build/bin/forge-boot-speed /usr/bin/forge-boot-speed \
    && cp /tmp/forge-build/desktop/forge-record.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-game-ready.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-smart-updates.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-quick-resume.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-hw-scout.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-game-installer.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-lan-mode.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-perf-profiles.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-boot-select.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-driver-mgr.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-net-optimizer.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-game-migrate.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-tray-dashboard.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-sandbox.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-power-plan.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-one-click-server.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-peripherals.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-input-lag.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-audio-router.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-cleaner.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-dual-gpu.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-mod-manager.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-custom-res.desktop /usr/share/applications/ \
    && cp /tmp/forge-build/desktop/forge-boot-speed.desktop /usr/share/applications/ \
    \
    # ── Lib scripts ── \
    && mkdir -p /usr/lib/forge \
    && install -m 755 /tmp/forge-build/lib/forge-first-boot-setup.sh /usr/lib/forge/first-boot-setup.sh \
    && install -m 755 /tmp/forge-build/lib/configure-steam-servers.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/forge-auto-update.sh /usr/lib/forge/auto-update.sh \
    && install -m 755 /tmp/forge-build/lib/forge-heartbeat.sh /usr/lib/forge/heartbeat.sh \
    && install -m 755 /tmp/forge-build/lib/forge-game-configs.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/forge-obs-setup.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/gamemode-start.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/gamemode-end.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/forge-update-guard-hook.sh /usr/lib/forge/ \
    && install -m 755 /tmp/forge-build/lib/forge-i18n.sh /usr/lib/forge/forge-i18n.sh \
    \
    # ── User systemd services ── \
    # ── User systemd services (installed but NOT auto-enabled) ── \
    # Services are available for users to enable via: systemctl --user enable <service> \
    # Only essential timers are auto-enabled to avoid overwhelming first login \
    && mkdir -p /etc/skel/.config/systemd/user/default.target.wants \
    && mkdir -p /etc/skel/.config/systemd/user/timers.target.wants \
    && cp /tmp/forge-build/systemd-user/forge-server-status.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-replay.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-discord-fix.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-backup.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-backup.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-hub-bridge.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-game-timer.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-proton-updater.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-proton-updater.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-achievements.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-achievements.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-perks-claim.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-smart-launch.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-anticheat-tracker.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-anticheat-tracker.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-wallpaper.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-wallpaper.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-live-wallpaper.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-notify.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-digest.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-digest.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-crash-report.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-deals.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-deals.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-challenges.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-challenges.timer /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-game-ready.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-smart-updates.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-hw-scout.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-perf-profiles.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-power-plan.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-tray-dashboard.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-quick-resume.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-peripherals.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-cleaner.service /etc/skel/.config/systemd/user/ \
    && cp /tmp/forge-build/systemd-user/forge-cleaner.timer /etc/skel/.config/systemd/user/ \
    \
    # ── Only auto-enable lightweight timers (no daemons at login) ── \
    && ln -sf ../forge-backup.timer /etc/skel/.config/systemd/user/timers.target.wants/forge-backup.timer \
    && ln -sf ../forge-cleaner.timer /etc/skel/.config/systemd/user/timers.target.wants/forge-cleaner.timer \
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
    && cp /tmp/forge-build/etc/motd /etc/motd \
    \
    # ── Avahi LAN party discovery service ── \
    && mkdir -p /etc/avahi/services \
    && cp /tmp/forge-build/etc/avahi/services/forge-lan.service /etc/avahi/services/ \
    \
    # ── Tournament overlay branding ── \
    && mkdir -p /usr/share/forge/overlays \
    && cp /tmp/forge-build/branding/overlays/* /usr/share/forge/overlays/ 2>/dev/null || true \
    \
    # ── Firefox homepage & bookmarks ── \
    && mkdir -p /usr/lib/firefox/distribution \
    && cp /tmp/forge-build/usr/lib/firefox/distribution/policies.json /usr/lib/firefox/distribution/ \
    \
    # ── Login / logout / notification sounds ── \
    && mkdir -p /usr/share/sounds/forge/stereo \
    && cp /tmp/forge-build/usr/share/sounds/forge/index.theme /usr/share/sounds/forge/ \
    && cp /tmp/forge-build/usr/share/sounds/forge/stereo/* /usr/share/sounds/forge/stereo/ \
    \
    # ── Gaming-optimized DNS (Cloudflare + Google) ── \
    && mkdir -p /etc/NetworkManager/conf.d \
    && cp /tmp/forge-build/etc/NetworkManager/conf.d/24hg-dns.conf /etc/NetworkManager/conf.d/ \
    \
    # ── Default hostname + vendor info ── \
    && cp /tmp/forge-build/etc/machine-info /etc/machine-info \
    && echo "forge-desktop" > /etc/hostname \
    && mkdir -p /usr/share/kcm-about \
    && cp /tmp/forge-build/usr/share/kcm-about/24hg-forge.json /usr/share/kcm-about/ \
    \
    # ── Default user avatar (SDDM + KDE) ── \
    && cp /tmp/forge-build/branding/icons/forge-logo-256.png /usr/share/sddm/faces/.default.face.icon \
    && mkdir -p /etc/skel/.face.d \
    && cp /tmp/forge-build/branding/icons/forge-logo-256.png /etc/skel/.face.icon \
    \
    # ── Cursor theme for SDDM fallback ── \
    && mkdir -p /usr/share/icons/default \
    && printf "[Icon Theme]\\nInherits=Bibata-Modern-Ice\\n" > /usr/share/icons/default/index.theme \
    \
    # ── KInfoCenter vendor logo ── \
    && mkdir -p /etc/xdg/discover \
    && cp /tmp/forge-build/etc/xdg/kcm-about-distrorc /etc/xdg/ \
    && cp /tmp/forge-build/etc/xdg/discover/featured.json /etc/xdg/discover/ \
    && cp /tmp/forge-build/branding/icons/forge-logo-256.png /usr/share/pixmaps/forge-logo-256.png \
    \
    # ── Anaconda installer branding ── \
    && mkdir -p /usr/share/anaconda/pixmaps /etc/anaconda/profile.d \
    && cp /tmp/forge-build/usr/share/anaconda/pixmaps/sidebar-logo.png /usr/share/anaconda/pixmaps/ \
    && cp /tmp/forge-build/usr/share/anaconda/pixmaps/sidebar-bg.png /usr/share/anaconda/pixmaps/ \
    && cp /tmp/forge-build/usr/share/anaconda/pixmaps/forge-anaconda.css /usr/share/anaconda/pixmaps/ \
    && cp /tmp/forge-build/usr/share/anaconda/pixmaps/anaconda-logo.svg /usr/share/anaconda/pixmaps/ 2>/dev/null || true \
    && cp /tmp/forge-build/usr/share/anaconda/pixmaps/anaconda-logo.png /usr/share/anaconda/pixmaps/ 2>/dev/null || true \
    && cp /tmp/forge-build/etc/anaconda/profile.d/forge.conf /etc/anaconda/profile.d/ \
    && mkdir -p /usr/share/anaconda/pixmaps/rnotes/en \
    && cp /tmp/forge-build/usr/share/anaconda/pixmaps/rnotes/en/*.png /usr/share/anaconda/pixmaps/rnotes/en/ \
    && mkdir -p /usr/share/icons/hicolor/scalable/apps /usr/share/icons/hicolor/48x48/apps \
    && cp /tmp/forge-build/branding/icons/forge-logo.svg /usr/share/icons/hicolor/scalable/apps/org.fedoraproject.AnacondaInstaller.svg 2>/dev/null || true \
    && cp /tmp/forge-build/branding/icons/forge-logo-48.png /usr/share/icons/hicolor/48x48/apps/org.fedoraproject.AnacondaInstaller.png 2>/dev/null || true \
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

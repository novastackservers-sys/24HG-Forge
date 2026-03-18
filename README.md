# 24HG Forge — 24HG's Custom Gaming Distribution

A custom Linux distribution built on [Bazzite](https://bazzite.gg/) (Universal Blue / Fedora Atomic) that boots straight into the [24 Hour Gaming](https://24hgaming.com) ecosystem.

## What is 24HG Forge?

24HG Forge is a turnkey gaming Linux distro centered around the 24HG community. Install it, boot it, and you're immediately connected to:

- **88+ game servers** (CS 1.6, CS2, TF2, Rust, FiveM, Quake, and more)
- **Community hub** with chat, forums, tournaments, and leaderboards
- **Voice chat** powered by LiveKit
- **Economy, clans, and factions**

All GPU drivers (NVIDIA, AMD, Intel) work out of the box. Steam, Lutris, and Heroic are auto-installed. System updates are atomic and safe.

## Two Boot Modes

- **24HG Mode** — Console-like experience via Gamescope. Boots into the Hub fullscreen.
- **Desktop Mode** — Full KDE Plasma desktop with the Hub pinned.

## Building

### Prerequisites

- `podman` (or Docker)
- For asset generation: `imagemagick`, `librsvg2-tools`

### Build OCI Image

```bash
# Desktop variant (AMD/Intel)
./scripts/build-local.sh desktop

# NVIDIA variant
./scripts/build-local.sh nvidia

# Steam Deck variant
./scripts/build-local.sh deck
```

### Generate Placeholder Assets

```bash
./scripts/generate-placeholder-assets.sh
```

### Build ISO

ISOs are built automatically by GitHub Actions on push to `main`. You can also build locally using [build-container-installer](https://github.com/JasonN3/build-container-installer).

## Installation

1. Download the ISO from the [Releases](https://git.raggi.is/admin/forge/releases) page
2. Flash to USB with [Ventoy](https://ventoy.net/), [Rufus](https://rufus.ie/), or `dd`
3. Boot from USB
4. Follow the Calamares installer
5. Reboot and enjoy!

## Updating

24HG Forge uses atomic updates. Your system is always safe:

```bash
# Check for updates
rpm-ostree upgrade --check

# Apply update
rpm-ostree upgrade

# Reboot to apply
systemctl reboot

# Rollback if needed
rpm-ostree rollback
```

## Architecture

```
Fedora Atomic (base OS, security, kernel)
  └─ Bazzite (gaming stack: NVIDIA, Proton, MangoHud, Gamescope, codecs)
      └─ 24HG Forge (24HG overlay)
          ├─ Hub App (Chromium kiosk → hub.24hgaming.com)
          ├─ Branding (wallpapers, icons, boot splash, GRUB theme)
          ├─ Gamescope session ("24HG Mode")
          ├─ First-boot setup (Steam, Lutris, Heroic auto-install)
          └─ First-boot wizard (account, GPU, preferences)
```

## Variants

| Variant | GPU Support | Use Case |
|---------|-------------|----------|
| `desktop` | AMD / Intel (open-source Mesa) | Most desktops and laptops |
| `nvidia` | NVIDIA (proprietary drivers) | NVIDIA GPU systems |
| `deck` | Steam Deck (AMD APU, handheld) | Steam Deck and handhelds |

## Links

- **Website:** https://24hgaming.com/os
- **Hub:** https://hub.24hgaming.com
- **Discord:** https://discord.gg/ymfEjH6EJN
- **Issues:** https://git.raggi.is/admin/forge/issues

## License

Custom code and branding: MIT License
Based on Bazzite (Apache 2.0) and Fedora (various open-source licenses)

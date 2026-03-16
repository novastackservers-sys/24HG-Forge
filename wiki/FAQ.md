# Frequently Asked Questions

## General

### What is HubOS?

HubOS is a custom Linux gaming distribution built on [Bazzite](https://bazzite.gg/) (Fedora Atomic) by [24 Hour Gaming](https://24hgaming.com). It provides a turnkey gaming experience with 53 purpose-built tools, direct connection to 88+ game servers, and deep community integration.

### Is HubOS free?

Yes. HubOS is completely free and open source under the MIT License (custom code) and inherits Bazzite's Apache 2.0 and Fedora's open-source licenses.

### Who makes HubOS?

HubOS is made by [24 Hour Gaming](https://24hgaming.com), a gaming community with 88+ game servers across Counter-Strike 2, Team Fortress 2, Counter-Strike 1.6, Rust, FiveM, and more.

### What makes HubOS different from other Linux gaming distros?

Three things:

1. **Community integration** -- HubOS connects directly to 24HG servers, hub, chat, tournaments, and leaderboards. No other distro has this.
2. **53 gaming tools** -- Every common Linux gaming pain point has a dedicated `hubos-*` tool. Proton issues, shader stutter, audio latency, controller setup, anti-cheat tracking -- all one command away.
3. **VIP perks** -- HubOS users get automatic benefits across all 24HG game servers.

### How is HubOS different from Bazzite?

HubOS is built on top of Bazzite. Everything in Bazzite is also in HubOS. On top of that, HubOS adds:

- 53 gaming utility tools (`hubos-*`)
- 24HG Hub app and community integration
- Custom branding (GRUB, Plymouth, SDDM, KDE splash, wallpapers, icons, sound theme)
- First-boot wizard tailored for gaming
- Server browser for 88+ game servers
- System tray integration with server status
- Per-game launch optimization daemon
- Anti-cheat status tracking with notifications
- Instant replay recording (like NVIDIA ShadowPlay)
- Game crash diagnosis and auto-fix tools
- VIP perks system

### Can I use HubOS without being part of 24HG?

Yes. HubOS works as a standalone gaming Linux distro. The 24HG integration is optional -- you do not need a 24HG account. All 53 tools work independently.

### What desktop environment does HubOS use?

KDE Plasma 6 (via Bazzite). HubOS also includes a "24HG Mode" that boots into a console-like fullscreen Gamescope session.

## Installation

### What are the system requirements?

Minimum: 64-bit CPU, 4 GB RAM, 30 GB storage, Vulkan-capable GPU. Recommended: 4+ core CPU, 16 GB RAM, 256 GB SSD, NVIDIA GTX 1060 / AMD RX 580 or better. See [Installation](Installation) for details.

### Can I dual-boot with Windows?

Yes. The Calamares installer supports installing alongside Windows. Shrink your Windows partition first using Windows Disk Management, then choose "Replace a partition" during HubOS installation. See the [Installation Guide](Installation#dual-boot-setup) for details.

### Does HubOS work on laptops?

Yes. Both AMD and Intel integrated graphics work out of the box. For NVIDIA laptops (Optimus), use the NVIDIA variant -- it includes the proprietary drivers and handles GPU switching.

### Does HubOS work on the Steam Deck?

Yes. Use the Deck variant. It includes Steam Deck-specific optimizations and handheld support from Bazzite.

### Can I install HubOS on a virtual machine?

Yes. QEMU/KVM with virt-manager works well for testing. See [Building from Source](Building#testing-in-a-vm) for details. Note that 3D performance in VMs is limited.

### How do I update HubOS?

HubOS uses atomic updates. Updates download in the background and apply on the next reboot:

```bash
rpm-ostree upgrade
systemctl reboot
```

Or use the HubOS tool:

```bash
hubos-update-guard check
hubos-update-guard apply
```

### Can I roll back an update?

Yes. Atomic updates mean the previous system image is always available:

```bash
rpm-ostree rollback
systemctl reboot
```

### Can I rebase from Bazzite to HubOS without reinstalling?

Yes:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/24hgaming/hubos:latest
systemctl reboot
```

### Can I install packages with dnf?

Not directly. HubOS uses Fedora Atomic, which means the base system is immutable. You have three options for additional software:

1. **Flatpak** (recommended): `flatpak install flathub <app>`
2. **rpm-ostree**: `rpm-ostree install <package>` (layered on top of the base image, persists across updates)
3. **Distrobox**: Run any Linux distro in a container with full access to your home directory

## Gaming

### Will my Steam games work?

Most of them. About 85% of Steam games work on Linux via Proton. Use `hubos-compat scan` to check your entire library, or `hubos-compat check <game>` for a specific game. See [Game Compatibility](Game-Compatibility) for details.

### What about anti-cheat games?

It depends on the anti-cheat and whether the developer has enabled Linux support. Games with EAC or BattlEye may work if the developer opted in (like Rust, Apex Legends, Elden Ring). Games with Vanguard (Valorant) or kernel-level anti-cheat do not work. Use `hubos-anticheat-tracker scan` to check your library.

### Do I need to configure Proton manually?

No. Steam automatically uses Proton for Windows games. HubOS also keeps Proton-GE updated automatically via `hubos-proton-updater`. For per-game tweaks, use `hubos-game-profiles`.

### How do I fix a game that won't launch?

```bash
hubos-proton-fix <appid>          # Diagnose Proton issues
hubos-crash-fix diagnose <appid>  # Diagnose crashes
hubos-proton-fix <appid> --fix    # Auto-fix common issues
```

See [Troubleshooting](Troubleshooting) for more.

### Can I use Lutris and Heroic?

Yes. Both are pre-installed on HubOS. Lutris handles non-Steam games, and Heroic handles Epic Games Store and GOG. The `hubos-games` tool shows games from all launchers in one unified library.

### How do I install mods?

HubOS registers as an NXM protocol handler. Click "Download with Mod Manager" on Nexus Mods, and HubOS handles the rest via `hubos-mod-manager`. For manual modding, use `hubos-prefix info <appid>` to find the game's Wine prefix.

### Why is my game stuttering on first launch?

Shader compilation. The GPU compiles shaders the first time you encounter new visuals. This goes away after the first session. To eliminate it, pre-build shaders:

```bash
hubos-shader-cache prebuild <appid>
```

### How do I enable HDR?

```bash
hubos-hdr setup
```

Requirements: KDE Plasma 6, Wayland session, HDR-capable monitor, AMD GPU (best support) or NVIDIA (improving).

### How do I record gameplay?

HubOS includes instant replay (like NVIDIA ShadowPlay):

```bash
hubos-replay start   # Start recording in the background
# Press F9 to save the last 2 minutes as a clip
```

For streaming:

```bash
hubos-stream setup   # Configure Twitch/YouTube/Kick
hubos-stream start   # Start streaming
```

### Can I use MangoHud?

Yes. MangoHud is pre-configured. Press F12 to toggle it. Edit `~/.config/MangoHud/MangoHud.conf` to customize.

## Hardware

### Does NVIDIA work?

Yes. Use the NVIDIA variant of HubOS, which includes proprietary NVIDIA drivers. If you experience Wayland issues, run `hubos-nvidia-wayland fix`.

### Does AMD work?

Yes. AMD GPUs use open-source Mesa drivers that are included in the kernel. They work out of the box with the Desktop variant.

### Does Intel Arc work?

Yes. Intel Arc GPUs use open-source Mesa drivers. Use the Desktop variant.

### My controller is not detected. What do I do?

```bash
hubos-controller list   # See what is detected
hubos-controller fix    # Fix common issues (udev rules, permissions)
```

Xbox controllers work out of the box. PlayStation and Nintendo controllers usually work but may need the fix command.

### How do I set up multiple monitors?

```bash
hubos-display status     # Show current display configuration
hubos-display gaming     # Optimize for gaming (disable compositing, etc.)
hubos-display save       # Save current layout as a profile
```

Or use KDE System Settings -> Display and Monitor.

## Community

### How do I connect to 24HG servers?

Open the Hub app (desktop icon or tray icon) and click any server. HubOS launches the right game automatically. Or from the terminal:

```bash
hubos-server-status   # See all servers and player counts
```

### How do I claim VIP perks?

```bash
hubos-perks claim
```

This links your 24HG account to your HubOS installation and activates benefits across all game servers.

### How do I report a bug?

1. Generate a diagnostic: `hubos-diag --paste`
2. Open an issue on [GitHub](https://github.com/24hgaming/hubos/issues) with the diagnostic link.
3. Or share it in the [Discord](https://discord.gg/ymfEjH6EJN) support channel.

### How do I contribute?

See the [Contributing](Contributing) guide. You can contribute code, documentation, bug reports, or help others in Discord.

## Technical

### What is Fedora Atomic?

Fedora Atomic (formerly Silverblue/Kinoite) is a variant of Fedora that uses an immutable base system managed by rpm-ostree. Updates are atomic (all-or-nothing), which means they cannot partially fail and leave your system broken. You can always roll back to the previous version.

### What is rpm-ostree?

rpm-ostree is the package manager for Fedora Atomic. It manages the base system image. Unlike traditional package managers (apt, dnf), it creates a new system image for each change, which means updates are atomic and reversible.

### Can I use dnf/apt?

No. The base system is managed by rpm-ostree. For additional software, use Flatpak, rpm-ostree overlay, or Distrobox. See the installation FAQ above.

### Where are config files stored?

- HubOS tool configs: `~/.config/hubos/`
- HubOS data: `~/.local/share/hubos/`
- HubOS cache: `~/.cache/hubos/`
- System configs: `/etc/` (managed by rpm-ostree)
- MangoHud: `~/.config/MangoHud/MangoHud.conf`
- Steam: `~/.var/app/com.valvesoftware.Steam/` (Flatpak) or `~/.local/share/Steam/` (native)

### How do automatic backups work?

The `hubos-backup` tool runs on a systemd timer. It backs up your game saves, HubOS configs, and important dotfiles. Check status:

```bash
hubos-backup status
```

### What ports does HubOS use?

HubOS does not run any servers by default. Outbound connections:

- Hub app: HTTPS (443) to `hub.24hgaming.com`
- Game connections: Various ports to game servers
- Steam: Various ports for Steam networking

The `hubos-netguard` tool monitors network connections from games:

```bash
hubos-netguard status
```

### Is HubOS secure?

HubOS inherits Fedora's security model:

- SELinux enabled
- Immutable base system (harder to compromise)
- Automatic security updates
- Firewall (firewalld) enabled with gaming ports
- Secure Boot compatible (with enrolled keys)

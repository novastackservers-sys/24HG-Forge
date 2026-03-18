# Tools Reference

Complete reference for all 24HG Forge tools. Every tool is installed to `/usr/bin/` and can be run from any terminal.

---

## Core System

### forge-neofetch

Custom system info display with 24HG branding. Shows OS, kernel, CPU, GPU, memory, disk, and desktop info in a styled terminal output.

```
Usage: forge-neofetch
```

No commands or options. Runs automatically when you open a terminal (configurable in `~/.bashrc.d/forge.sh`).

**Example output:**

```
    ██   ██ ██    ██ ██████   ██████  ███████
    ██   ██ ██    ██ ██   ██ ██    ██ ██
    ███████ ██    ██ ██████  ██    ██ ███████
    ██   ██ ██    ██ ██   ██ ██    ██      ██
    ██   ██  ██████  ██████   ██████  ███████

    OS:      24HG Forge (24 Hour Gaming)
    Kernel:  6.8.0-100-generic
    CPU:     AMD Ryzen 7 5800X (16 cores)
    GPU:     NVIDIA GeForce RTX 3070
    Memory:  12.4 GiB / 32.0 GiB (39%)
    Disk:    142G / 500G (28%)
    DE:      KDE Plasma 6.1
    Uptime:  3 hours, 42 minutes
```

---

### forge-diag

Collect comprehensive system diagnostics for support tickets. Gathers OS, hardware, GPU, audio, network, Steam, Proton, and log information.

```
Usage: forge-diag [--paste]
```

| Flag | Description |
|------|-------------|
| `--paste` | Upload report to termbin.com and return a shareable URL. Sensitive data (public IPs) is redacted. |

**Examples:**

```bash
forge-diag                # Print diagnostics to terminal
forge-diag --paste        # Upload and get URL like https://termbin.com/abc123
```

**Sections collected:** OS info, kernel, hardware (CPU, GPU, RAM), disk layout, display server, audio (PipeWire), network, Steam installation, Proton versions, recent journal errors, loaded kernel modules.

---

### forge-performance

Switch between performance profiles for different use cases. Controls CPU governor, GPU power mode, compositor, and GameMode.

```
Usage: forge-performance [gaming|balanced|powersave|status]
```

| Command | Description |
|---------|-------------|
| `gaming` | Maximum performance: CPU performance governor, GPU max power, compositor suspended, GameMode active |
| `balanced` | Default state: CPU balanced/schedutil, GPU auto, compositor enabled |
| `powersave` | Minimum power: CPU powersave governor, GPU low power, reduced refresh rate |
| `status` | Show current profile and all settings |

**Examples:**

```bash
forge-performance gaming     # Switch to gaming mode
forge-performance status     # Check current profile
forge-performance balanced   # Return to balanced mode
```

**Supports:** powerprofilesctl, direct sysfs, NVIDIA (nvidia-smi), AMD (dpm_force_performance_level), KDE KWin compositor.

---

### forge-update-guard

Safe system updates with rollback protection. Checks for known issues before applying updates.

```
Usage: forge-update-guard [check|apply|rollback|status|history]
```

| Command | Description |
|---------|-------------|
| `check` | Check for available updates and analyze safety |
| `apply` | Apply update only if safety checks pass |
| `rollback` | Roll back to the previous system image |
| `status` | Show current and previous image versions |
| `history` | Show update history |

**Examples:**

```bash
forge-update-guard check      # See what's new and if it's safe
forge-update-guard apply      # Update if safe
forge-update-guard rollback   # Undo last update
```

**Config:** Uses a pre-transaction hook at `/usr/lib/forge/forge-update-guard-hook.sh`.

---

## Server & Community

### forge-hub

The main 24HG Hub application. Opens hub.24hgaming.com in a Chromium kiosk window with protocol handler support.

```
Usage: forge-hub [url]
```

Launched via desktop icon, autostart, or `24hg://` protocol links. Connects to the community hub for servers, chat, forums, tournaments, and leaderboards.

---

### forge-tray

System tray icon for 24HG integration. Shows connection status, server counts, and provides quick actions.

```
Usage: forge-tray
```

Runs as an autostart service. Provides a tray icon with:
- Server status indicator (green = connected)
- Quick-launch menu for popular servers
- Claim perks shortcut
- Hub app launcher

---

### forge-hub-bridge

Background service that bridges 24HG Forge system events to the 24HG Hub. Syncs playtime, achievements, and system info.

```
Usage: forge-hub-bridge [daemon|status|sync]
```

| Command | Description |
|---------|-------------|
| `daemon` | Run as background service (managed by systemd) |
| `status` | Show bridge connection status |
| `sync` | Force sync data to hub |

**Systemd:** `forge-hub-bridge.service` (user, auto-enabled).

---

### forge-server-status

Show all 24HG game servers with real-time player counts and status.

```
Usage: forge-server-status
```

Queries the server list from `/usr/share/forge/servers.json` and checks each server's status via game query protocols. Shows player counts, map names, and ping.

**Systemd:** `forge-server-status.service` (user, auto-enabled) provides periodic updates.

---

## Gaming Performance

### forge-smart-launch

Intelligent per-game optimization daemon. Automatically detects game launches and applies optimal settings (CPU governor, GPU mode, compositor, env vars) per game.

```
Usage: forge-smart-launch [daemon|apply|config|status|rules|log] [appid]
```

| Command | Description |
|---------|-------------|
| `daemon` | Run background monitoring daemon |
| `apply <appid>` | Manually apply optimizations for a game |
| `config <appid>` | View/edit per-game configuration |
| `status` | Show current optimization state |
| `rules` | List all built-in game rules |
| `log` | Show recent launch history |

**Examples:**

```bash
forge-smart-launch status         # See what's currently optimized
forge-smart-launch rules          # View built-in rules for known games
forge-smart-launch config 730     # Edit CS2 optimization profile
```

**Systemd:** `forge-smart-launch.service` (user, auto-enabled). Runs as a daemon that monitors `/proc` for game processes.

**Config:** `~/.config/forge/smart-launch/`

---

### forge-game-profiles

Per-game launch profiles with Proton versions, environment variables, resolution, MangoHud configs, and launch arguments.

```
Usage: forge-game-profiles [create|edit|apply|list|delete|search|import|export|help] [options]
```

| Command | Description |
|---------|-------------|
| `create <appid>` | Create a new profile for a game (interactive) |
| `edit <appid>` | Edit an existing profile |
| `apply <appid>` | Apply a profile's settings |
| `list` | List all profiles |
| `delete <appid>` | Delete a profile |
| `search <query>` | Search profiles |
| `import <file>` | Import profiles from JSON |
| `export` | Export all profiles as JSON |

**Examples:**

```bash
forge-game-profiles create 1245620   # Create Elden Ring profile
forge-game-profiles list             # List all profiles
forge-game-profiles edit 730         # Edit CS2 profile
```

**Config:** `~/.config/forge/game-profiles/<appid>.json`

---

### forge-shader-cache

Manage shader caches to eliminate first-launch stuttering. Supports Steam (Flatpak and native), DXVK, Mesa, NVIDIA, and AMD caches.

```
Usage: forge-shader-cache [status|clean|size|prebuild|export|import|optimize]
```

| Command | Description |
|---------|-------------|
| `status` | Show shader cache health and sizes |
| `clean` | Clean corrupted or stale cache entries |
| `size` | Show total cache size breakdown |
| `prebuild <appid>` | Pre-build shaders for a game (reduces first-launch stutter) |
| `export <appid>` | Export shader cache for sharing |
| `import <file>` | Import a shared shader cache |
| `optimize` | Optimize all caches (defrag, prune) |

**Examples:**

```bash
forge-shader-cache status           # Check cache health
forge-shader-cache prebuild 730     # Pre-build CS2 shaders
forge-shader-cache size             # See how much space caches use
forge-shader-cache clean            # Clean stale entries
```

**Cache locations:** `~/.cache/mesa_shader_cache/`, `~/.cache/nvidia/GLCache/`, Steam shader caches.

---

## Game Management

### forge-games

Unified game library across all launchers. Shows all installed games from Steam, Lutris, Heroic, and native sources in one place.

```
Usage: forge-games [list|search|launch|info|recent|stats|refresh] [args]
```

| Command | Description |
|---------|-------------|
| `list` | Show all installed games across all launchers |
| `search <query>` | Fuzzy search across all games |
| `launch <name\|id>` | Launch a game from any launcher |
| `info <name\|id>` | Detailed info about a game |
| `recent` | Show recently played games |
| `stats` | Library statistics |
| `refresh` | Force rescan all launchers |

**Examples:**

```bash
forge-games list                     # All games, all launchers
forge-games search "cyberpunk"       # Find a game
forge-games launch "Counter-Strike 2"  # Launch from any launcher
forge-games stats                    # Library breakdown
```

---

### forge-compat

Game compatibility checker. Queries ProtonDB, Steam, and anti-cheat databases.

```
Usage: forge-compat [check|search|scan|report|status] [appid|name]
```

| Command | Description |
|---------|-------------|
| `check <appid\|name>` | Check a specific game's Linux compatibility |
| `search <name>` | Search Steam store for a game |
| `scan` | Scan all installed Steam games |
| `report` | Generate full compatibility report |
| `status` | Show system readiness for gaming |

**Examples:**

```bash
forge-compat check 730               # Check CS2
forge-compat check "Elden Ring"      # Check by name
forge-compat scan                    # Check entire library
forge-compat status                  # System readiness
```

---

### forge-anticheat-tracker

Track anti-cheat compatibility for your Steam library. Notifies you when games enable Linux support.

```
Usage: forge-anticheat-tracker [scan|watch|status|check|updates|database] [game]
```

| Command | Description |
|---------|-------------|
| `scan` | Scan Steam library and check anti-cheat status |
| `watch` | Background check for status changes (for systemd timer) |
| `status` | Show current tracking status |
| `check <game>` | Check a specific game by name or AppID |
| `updates` | Show recent anti-cheat status changes |
| `database` | Show/manage the anti-cheat database |

**Examples:**

```bash
forge-anticheat-tracker scan          # Full library scan
forge-anticheat-tracker check "PUBG"  # Check a specific game
forge-anticheat-tracker updates       # Recent changes
```

**Systemd:** `forge-anticheat-tracker.timer` (user, daily). Sends desktop notifications when status changes.

**Data:** `~/.local/share/forge/anticheat/`

---

### forge-game-timer

Track playtime across all game launchers. Monitors Steam, Lutris, Heroic, native games, and GameMode sessions.

```
Usage: forge-game-timer [start|stop|status|stats|report|export|daemon|help] [game]
```

| Command | Description |
|---------|-------------|
| `start <game>` | Manually start tracking a session |
| `stop [game]` | Stop tracking (most recent if no game specified) |
| `status` | Show currently tracked sessions |
| `stats [game]` | Playtime statistics (top 10 or specific game) |
| `report [period]` | Weekly/monthly/all-time breakdown |
| `export` | Export all data as JSON |
| `daemon` | Auto-detect sessions by polling /proc |

**Examples:**

```bash
forge-game-timer status               # What's running now
forge-game-timer stats                # Top 10 by playtime
forge-game-timer report weekly        # This week's breakdown
```

**Systemd:** `forge-game-timer.service` (user, auto-enabled).

**Data:** `~/.local/share/forge/game-timer.json`

---

## Proton & Wine

### forge-proton-fix

Diagnose and fix Proton/Wine game issues. Checks Vulkan, Proton versions, game logs, and common failure modes.

```
Usage: forge-proton-fix [appid|game-name] [--fix]
```

| Flag | Description |
|------|-------------|
| `--fix` | Attempt automatic fixes for detected issues |

**Examples:**

```bash
forge-proton-fix 730                 # Diagnose CS2
forge-proton-fix "Elden Ring" --fix  # Diagnose and auto-fix
forge-proton-fix 252490              # Diagnose Rust
```

**Checks:** Vulkan drivers, Proton versions, crash logs, missing dependencies (vcredist, .NET, DirectX), anti-cheat status, Wine prefix health.

**Known game fixes:** CS2 (`-vulkan -high`), TF2 (`-novid -nojoy`), Rust (`-window-mode exclusive -force-vulkan`), and more.

---

### forge-proton-updater

Automatically keep Proton-GE up to date. Manages GloriousEggroll's Proton-GE custom builds.

```
Usage: forge-proton-updater [check|update|list|set-default|cleanup|auto] [options]
```

| Command | Description |
|---------|-------------|
| `check` | Check if a newer Proton-GE version is available |
| `update` | Download and install the latest Proton-GE |
| `list` | List installed Proton-GE versions |
| `set-default` | Set the default Proton-GE version in Steam |
| `cleanup` | Remove old versions (keeps 2 most recent) |
| `auto` | Check and update silently (for systemd timer) |

**Examples:**

```bash
forge-proton-updater check           # Is there an update?
forge-proton-updater update          # Install latest
forge-proton-updater list            # See all installed versions
forge-proton-updater cleanup         # Remove old versions
```

**Systemd:** `forge-proton-updater.timer` (user, weekly check).

**Install path:** `~/.local/share/Steam/compatibilitytools.d/` (Flatpak or native Steam).

---

### forge-prefix

Wine/Proton prefix manager. Manages prefixes for Steam games -- list, inspect, health-check, backup, restore, install dependencies, and reset.

```
Usage: forge-prefix [list|info|health|install-deps|backup|restore|cleanup|reset] [options]
```

| Command | Description |
|---------|-------------|
| `list` | List all prefixes sorted by size |
| `info <appid>` | Detailed prefix information |
| `health <appid>` | Health-check a prefix |
| `install-deps <appid> [deps]` | Install dependencies via protontricks |
| `backup <appid> [--saves-only]` | Backup a prefix (tar+zstd) |
| `restore <appid> [backup]` | Restore from backup |
| `cleanup` | Find and remove orphaned prefixes |
| `reset <appid>` | Nuclear reset (backs up saves first) |

| Flag | Description |
|------|-------------|
| `--gui` | Use zenity dialogs instead of terminal |
| `--saves-only` | Only backup save data (with `backup` command) |

**Dependency presets:** `vcredist`, `dotnet35`, `dotnet40`, `dotnet45`, `dotnet48`, `d3dcompiler`, `xact`.

**Examples:**

```bash
forge-prefix list                     # See all prefixes and sizes
forge-prefix info 730                 # CS2 prefix details
forge-prefix health 1245620           # Health-check Elden Ring prefix
forge-prefix install-deps 12345 vcredist  # Install VC++ redistributables
forge-prefix backup 730               # Backup CS2 prefix
forge-prefix reset 12345              # Nuclear reset (backs up saves)
```

**Backup path:** `~/.local/share/forge/prefix-backups/`

---

### forge-crash-fix

Game crash diagnosis and auto-fix tool. Analyzes Steam/Proton crash logs, system journals, and common failure modes.

```
Usage: forge-crash-fix [diagnose|fix|log|report|watch] [appid|name] [options]
```

| Command | Description |
|---------|-------------|
| `diagnose <appid\|name>` | Analyze why a game crashed |
| `fix <appid\|name>` | Auto-fix common crash issues |
| `log <appid\|name>` | Show recent crash logs, filtered and formatted |
| `report` | Generate full crash report for sharing |
| `watch` | Monitor for crashes in real-time and auto-diagnose |

| Flag | Description |
|------|-------------|
| `--gui` | Use zenity dialogs |
| `--verbose` | Extra detail |
| `--no-color` | Disable colored output |

**Examples:**

```bash
forge-crash-fix diagnose 1245620      # Why did Elden Ring crash?
forge-crash-fix fix 730               # Auto-fix CS2 crash issues
forge-crash-fix log 252490            # Show Rust crash logs
forge-crash-fix report                # Full report for support
forge-crash-fix watch                 # Monitor all games
```

---

## Display & Graphics

### forge-display

Multi-monitor and display settings manager. Handles gaming/desktop modes, VRR, profiles, and per-monitor settings. Auto-detects Wayland vs X11.

```
Usage: forge-display [status|list|gaming|desktop|save|load|vrr|resolution] [options]
```

| Command | Description |
|---------|-------------|
| `status` | Show current display configuration |
| `list` | List all connected monitors |
| `gaming` | Gaming mode (disable compositing, preferred refresh) |
| `desktop` | Desktop mode (enable compositing, auto settings) |
| `save <name>` | Save current layout as a named profile |
| `load <name>` | Load a saved profile |
| `vrr` | Toggle Variable Refresh Rate (FreeSync/G-Sync) |
| `resolution <WxH>` | Set resolution |

**Examples:**

```bash
forge-display status                  # Current config
forge-display gaming                  # Optimize for gaming
forge-display save "triple-monitor"   # Save layout
forge-display load "triple-monitor"   # Restore layout
forge-display vrr                     # Toggle VRR
```

**Profiles:** `~/.config/forge/display-profiles/`

---

### forge-hdr

HDR gaming configuration wizard. Handles hardware detection, KDE Plasma 6 config, gamescope integration, and per-game HDR profiles.

```
Usage: forge-hdr [setup|status|enable|disable|game|calibrate|test] [options]
```

| Command | Description |
|---------|-------------|
| `setup` | Run the full HDR setup wizard |
| `status` | Show HDR hardware and software status |
| `enable` | Enable HDR system-wide |
| `disable` | Disable HDR |
| `game <appid>` | Apply HDR profile for a specific game |
| `calibrate` | HDR brightness calibration |
| `test` | Display HDR test pattern |

**Examples:**

```bash
forge-hdr setup                       # Full setup wizard
forge-hdr status                      # Check HDR support
forge-hdr game 1091500                # HDR for Cyberpunk 2077
```

**Config:** `~/.config/forge/hdr/`

---

### forge-nvidia-wayland

Auto-detect and fix all NVIDIA + Wayland gaming issues. The most comprehensive NVIDIA Wayland fix tool for Linux.

```
Usage: forge-nvidia-wayland [fix|status|diagnose|optimize|env|flicker-fix|sync|driver-check]
```

| Command | Description |
|---------|-------------|
| `fix` | Auto-detect and fix all known issues |
| `status` | Show NVIDIA Wayland status and health score |
| `diagnose` | Detailed diagnosis of all potential issues |
| `optimize` | Apply gaming-specific NVIDIA optimizations |
| `env` | Show/manage NVIDIA environment variables |
| `flicker-fix` | Fix screen flickering specifically |
| `sync` | Fix frame sync issues |
| `driver-check` | Check driver version and compatibility |

**Examples:**

```bash
forge-nvidia-wayland fix              # Fix everything
forge-nvidia-wayland status           # Health check
forge-nvidia-wayland flicker-fix      # Just fix flickering
forge-nvidia-wayland driver-check     # Check driver
```

**Config:** `~/.config/environment.d/nvidia-gaming.conf`

---

## Audio

### forge-audio

PipeWire audio optimizer. Configures low-latency gaming audio, noise cancellation, and device switching.

```
Usage: forge-audio [gaming|desktop|devices|switch|noise-cancel|status] [name]
```

| Command | Description |
|---------|-------------|
| `gaming` | Low-latency audio profile (lower buffer, disable processing) |
| `desktop` | Default audio profile (standard latency, full processing) |
| `devices` | List all audio input and output devices |
| `switch <name>` | Switch default output to named device |
| `noise-cancel` | Toggle noise cancellation on microphone |
| `status` | Show current audio configuration |

**Examples:**

```bash
forge-audio status                    # Current config
forge-audio gaming                    # Low-latency mode
forge-audio devices                   # List all devices
forge-audio switch "Headphones"       # Switch output
forge-audio noise-cancel              # Toggle noise cancel
```

**Config:** `/etc/pipewire/pipewire.conf.d/99-forge-defaults.conf` (system), managed per-profile.

---

## Input

### forge-input

Input latency optimizer for mice and keyboards. Configures acceleration profiles and polling rates for competitive gaming.

```
Usage: forge-input [gaming|desktop|status]
```

| Command | Description |
|---------|-------------|
| `gaming` | Flat acceleration (no mouse accel), max polling, optimized debounce |
| `desktop` | Adaptive acceleration, default settings |
| `status` | Show current input configuration |

**Examples:**

```bash
forge-input gaming                    # Flat mouse accel, max polling
forge-input status                    # Current settings
forge-input desktop                   # Restore defaults
```

**Applies to:** xinput (X11), KDE kcminputrc (Wayland), libinput settings.

---

### forge-controller

Gamepad manager. Detects, calibrates, profiles, remaps, and troubleshoots controllers. Supports Xbox, PlayStation, Nintendo, 8BitDo, and generic HID.

```
Usage: forge-controller [list|test|calibrate|profile|map|fix|status] [device]
```

| Command | Description |
|---------|-------------|
| `list` | List all detected controllers |
| `test` | Interactive controller input test |
| `calibrate [device]` | Calibrate a controller |
| `profile <name>` | Switch to a saved controller profile |
| `map [device]` | Remap buttons |
| `fix` | Fix common issues (udev rules, permissions, Steam detection) |
| `status` | Show controller status |

**Examples:**

```bash
forge-controller list                 # See all controllers
forge-controller test                 # Test button input
forge-controller fix                  # Fix detection issues
forge-controller calibrate            # Calibrate joysticks
```

**Profiles:** `~/.config/forge/controller/`

---

## Recording & Streaming

### forge-replay

Instant replay recording (like NVIDIA ShadowPlay). Uses gpu-screen-recorder for zero-overhead hardware-accelerated recording. Saves the last N minutes when you press F9.

```
Usage: forge-replay [start|stop|save|status|config]
```

| Command | Description |
|---------|-------------|
| `start` | Start recording the replay buffer |
| `stop` | Stop recording |
| `save` | Save the current buffer as a clip (F9 shortcut) |
| `status` | Show recording status |
| `config` | Edit replay settings (duration, quality, FPS) |

**Examples:**

```bash
forge-replay start                    # Start recording
forge-replay save                     # Save last 2 minutes
forge-replay status                   # Check if recording
forge-replay config                   # Change settings
```

**Defaults:** 120 seconds buffer, 60 FPS, very_high quality, auto-detect encoder (NVENC/VAAPI).

**Clips saved to:** `~/Videos/24HG Forge Clips/`

**Config:** `~/.config/forge/replay.conf`

**Systemd:** `forge-replay.service` (user, manual start).

---

### forge-stream

One-command streaming setup and control. Supports Twitch, YouTube, Kick, and custom RTMP targets. Uses OBS when available, falls back to FFmpeg.

```
Usage: forge-stream [setup|start|stop|status|config|obs-scenes]
```

| Command | Description |
|---------|-------------|
| `setup` | Interactive streaming setup wizard |
| `start` | Start streaming |
| `stop` | Stop streaming |
| `status` | Show stream status |
| `config` | Edit stream settings |
| `obs-scenes` | Install 24HG Forge-optimized OBS scene templates |

**Examples:**

```bash
forge-stream setup                    # Configure Twitch/YouTube/Kick
forge-stream start                    # Go live
forge-stream stop                     # Stop streaming
```

**Config:** `~/.config/forge/stream.conf`

---

### forge-creator-kit

Content creation utilities. Scene templates, overlay setup, and encoding profiles for streamers and content creators.

```
Usage: forge-creator-kit [setup|templates|overlays|encode|help]
```

| Command | Description |
|---------|-------------|
| `setup` | Initial creator kit setup |
| `templates` | Install/manage OBS scene templates |
| `overlays` | Manage stream overlays |
| `encode` | Batch encode recordings with optimized settings |

---

### forge-screenshot

Screenshot tool with 24HG Forge branding and automatic saving. Supports full screen, area selection, and active window capture.

```
Usage: forge-screenshot [full|area|window]
```

| Command | Description |
|---------|-------------|
| `full` | Capture entire screen (Print shortcut) |
| `area` | Select area to capture (Shift+Print shortcut) |
| `window` | Capture active window (Meta+Print shortcut) |

**Saves to:** `~/Pictures/24HG Forge Screenshots/`

---

## Network

### forge-netguard

Network monitoring for gaming. Tracks connections made by games, detects anomalies, and provides latency diagnostics.

```
Usage: forge-netguard [status|monitor|latency|firewall|help]
```

| Command | Description |
|---------|-------------|
| `status` | Show current network status and active game connections |
| `monitor` | Live monitoring of game network traffic |
| `latency` | Test latency to game servers |
| `firewall` | Manage gaming firewall rules |

**Examples:**

```bash
forge-netguard status                 # Current connections
forge-netguard latency                # Ping game servers
```

---

### forge-download-mgr

Download manager for game-related downloads. Manages bandwidth allocation and scheduling.

```
Usage: forge-download-mgr [status|limit|schedule|queue|help]
```

| Command | Description |
|---------|-------------|
| `status` | Show active downloads and bandwidth usage |
| `limit <speed>` | Set bandwidth limit (e.g., `50M` for 50 Mbps) |
| `schedule` | Configure download scheduling (e.g., overnight) |
| `queue` | View/manage download queue |

---

## System Maintenance

### forge-backup

Automated game save and config backup. Backs up saves, 24HG Forge configs, and important dotfiles.

```
Usage: forge-backup [now|status|restore|list|config|help]
```

| Command | Description |
|---------|-------------|
| `now` | Run backup immediately |
| `status` | Show backup status and next scheduled run |
| `restore [backup]` | Restore from a backup |
| `list` | List available backups |
| `config` | Edit backup settings (paths, schedule, retention) |

**Systemd:** `forge-backup.timer` (user, daily).

---

### forge-save-manager

Find, backup, and restore game save files across all launchers and prefix locations.

```
Usage: forge-save-manager [find|list|backup|restore|sync|help] [appid|name]
```

| Command | Description |
|---------|-------------|
| `find <appid\|name>` | Find save file locations for a game |
| `list` | List all detected save locations |
| `backup <appid>` | Backup saves for a specific game |
| `restore <appid>` | Restore saves from backup |
| `sync` | Sync saves with cloud storage |

**Examples:**

```bash
forge-save-manager find 1245620       # Find Elden Ring saves
forge-save-manager list               # All save locations
forge-save-manager backup 730         # Backup CS2 saves
```

---

### forge-flatpak-fix

Fix Flatpak filesystem permissions for Steam, Lutris, and other gaming apps.

```
Usage: forge-flatpak-fix
```

No subcommands. Reconfigures Flatpak overrides so gaming apps can access game drives, external storage, and shared directories.

---

### forge-dualboot

Dual-boot management tool. Detects other operating systems and manages GRUB bootloader.

```
Usage: forge-dualboot [status|repair|timeout] [value]
```

| Command | Description |
|---------|-------------|
| `status` | Show detected operating systems |
| `repair` | Fix bootloader issues |
| `timeout <seconds>` | Set GRUB menu timeout |

---

## Migration & Setup

### forge-migrate

Migrate settings and data from Windows or another Linux distro to 24HG Forge.

```
Usage: forge-migrate [scan|import|status|help]
```

| Command | Description |
|---------|-------------|
| `scan` | Scan for importable data (Windows partitions, other Linux installs) |
| `import` | Import settings, saves, and configurations |
| `status` | Show migration status |

---

### forge-discord-fix

Fix Discord integration on 24HG Forge. Configures PipeWire, XDG portals, and Flatpak permissions.

```
Usage: forge-discord-fix
```

Runs automatically as a systemd service (`forge-discord-fix.service`). Ensures Discord can access audio, screen share, and system notifications.

---

### forge-discord-screen

Fix Discord screen sharing specifically. Configures PipeWire screen capture portal for Wayland.

```
Usage: forge-discord-screen
```

---

### forge-first-boot

First boot wizard for new 24HG Forge installations. Guides users through GPU detection, display setup, account connection, and preferences.

```
Usage: forge-first-boot
```

Launched automatically via autostart desktop entry on the first login. Can be re-run manually.

---

## Personalization

### forge-wallpaper

Wallpaper manager with rotation support. Manages 24HG Forge-branded wallpapers and custom wallpaper collections.

```
Usage: forge-wallpaper [set|random|rotate|list|add|help]
```

| Command | Description |
|---------|-------------|
| `set <file>` | Set a specific wallpaper |
| `random` | Set a random wallpaper from the collection |
| `rotate` | Enable wallpaper rotation |
| `list` | List available wallpapers |
| `add <file>` | Add a wallpaper to the collection |

**Systemd:** `forge-wallpaper.timer` (user, for rotation).

---

### forge-sounds

Sound theme manager. Switches between 24HG Forge sound themes for system events.

```
Usage: forge-sounds [list|set|preview|mute|help]
```

| Command | Description |
|---------|-------------|
| `list` | List available sound themes |
| `set <theme>` | Set the active sound theme |
| `preview` | Preview the current sound theme |
| `mute` | Mute/unmute system sounds |

---

### forge-achievements

Community achievement tracker. Tracks gaming milestones and syncs with the 24HG Hub.

```
Usage: forge-achievements [list|check|sync|help]
```

| Command | Description |
|---------|-------------|
| `list` | List all achievements and progress |
| `check` | Check for newly earned achievements |
| `sync` | Sync achievements with 24HG Hub |

**Systemd:** `forge-achievements.timer` (user, periodic check).

---

### forge-tips

Display gaming tips and 24HG Forge feature highlights. Shows helpful tips in notifications.

```
Usage: forge-tips [show|random|list|disable|help]
```

| Command | Description |
|---------|-------------|
| `show` | Show the tip of the day |
| `random` | Show a random tip |
| `list` | List all tips |
| `disable` | Disable tip notifications |

---

### forge-notify-style

Notification style manager. Configures how desktop notifications appear during gaming.

```
Usage: forge-notify-style [gaming|minimal|full|custom|status|help]
```

| Command | Description |
|---------|-------------|
| `gaming` | Minimal notifications during games (only critical alerts) |
| `minimal` | Reduced notification frequency |
| `full` | All notifications enabled |
| `custom` | Custom notification rules |
| `status` | Show current notification style |

---

### forge-desktop-setup

Desktop layout and widget configuration. Manages KDE Plasma panel layout, widgets, and desktop shortcuts.

```
Usage: forge-desktop-setup [default|gaming|minimal|reset|help]
```

| Command | Description |
|---------|-------------|
| `default` | Apply 24HG Forge default desktop layout |
| `gaming` | Gaming-focused layout (minimal panels, quick-launch) |
| `minimal` | Clean minimal layout |
| `reset` | Reset to factory defaults |

---

## Adoption & Community

### forge-perks

Manage VIP perks for 24HG Forge users on 24HG game servers.

```
Usage: forge-perks [claim|status|list|help]
```

| Command | Description |
|---------|-------------|
| `claim` | Link your 24HG account and claim perks |
| `status` | Show current perk status |
| `list` | List all available perks |

**Systemd:** `forge-perks-claim.service` (user, auto-start to check claim status).

---

### forge-benchmark

System benchmark tool. Tests GPU, CPU, and storage performance with gaming-relevant workloads.

```
Usage: forge-benchmark [run|gpu|cpu|storage|results|help]
```

| Command | Description |
|---------|-------------|
| `run` | Run full benchmark suite |
| `gpu` | GPU-only benchmark |
| `cpu` | CPU-only benchmark |
| `storage` | Storage speed test |
| `results` | Show previous benchmark results |

---

### forge-benchmark-compare

Compare benchmark results with other 24HG Forge users and community averages.

```
Usage: forge-benchmark-compare [latest|upload|compare|leaderboard|help]
```

| Command | Description |
|---------|-------------|
| `latest` | Show your latest benchmark results |
| `upload` | Upload results to 24HG leaderboard |
| `compare` | Compare with community averages |
| `leaderboard` | View the benchmark leaderboard |

---

### forge-demo

Interactive 24HG Forge feature demo. Showcases all major tools and features for new users.

```
Usage: forge-demo
```

Launched from the desktop (`forge-demo.desktop`) or terminal. Walks through each tool category with examples and explanations.

---

### forge-mod-manager

Game mod manager. Handles Nexus Mods NXM protocol links and mod installation for Proton/Wine games.

```
Usage: forge-mod-manager [install|list|enable|disable|update|help] [appid]
```

| Command | Description |
|---------|-------------|
| `install <nxm-url\|file>` | Install a mod from NXM link or file |
| `list <appid>` | List installed mods for a game |
| `enable <mod>` | Enable a disabled mod |
| `disable <mod>` | Disable a mod without removing |
| `update` | Check for mod updates |

Registered as NXM protocol handler (`forge-nxm-handler.desktop`). Click "Download with Mod Manager" on Nexus Mods and 24HG Forge handles the rest.

---

## Additional Tools

### forge-crash-recovery

General system crash recovery. Restores from black screen, frozen desktop, or boot failures.

```
Usage: forge-crash-recovery
```

Can be run from a TTY (Ctrl+Alt+F2) if the desktop is unresponsive.

---

### forge-thermal

System thermal monitoring. Shows CPU and GPU temperatures, fan speeds, and throttling status.

```
Usage: forge-thermal
```

Uses `lm_sensors` and GPU-specific tools to display thermal data.

---

### forge-session-summary

Show a summary of the current or last gaming session. Playtime, games played, performance stats.

```
Usage: forge-session-summary
```

---

### forge-lock-info

Customizes the lock screen with gaming-related info (server status, next event, tips).

```
Usage: forge-lock-info
```

---

### forge-nightlight

Toggle night light (blue light filter) for late-night gaming sessions.

```
Usage: forge-nightlight [toggle|on|off|status]
```

| Command | Description |
|---------|-------------|
| `toggle` | Toggle night light on/off (Meta+N shortcut) |
| `on` | Enable night light |
| `off` | Disable night light |
| `status` | Show current state |

---

## Configuration File Locations

All 24HG Forge tools follow the XDG Base Directory specification:

| Type | Path | Example |
|------|------|---------|
| Config | `~/.config/forge/<tool>/` | `~/.config/forge/replay.conf` |
| Data | `~/.local/share/forge/<tool>/` | `~/.local/share/forge/game-timer.json` |
| Cache | `~/.cache/forge/<tool>/` | `~/.cache/forge/anticheat/` |
| Logs | `~/.local/share/forge/logs/` | `~/.local/share/forge/logs/nvidia-wayland-*.log` |
| System | `/usr/share/forge/` | `/usr/share/forge/servers.json` |
| Lib | `/usr/lib/forge/` | `/usr/lib/forge/gamemode-start.sh` |

## Systemd Services Summary

### System Services (root)

| Service | Description |
|---------|-------------|
| `forge-gaming-tweaks.service` | Sysctl gaming optimizations (boot) |
| `forge-first-boot-setup.service` | First-boot system configuration (one-shot) |
| `forge-auto-update.timer` | Automatic system update checks |

### User Services

| Service | Description | Auto-Enabled |
|---------|-------------|-------------|
| `forge-server-status.service` | Server status monitoring | Yes |
| `forge-hub-bridge.service` | Hub data sync | Yes |
| `forge-discord-fix.service` | Discord integration fix | Yes |
| `forge-game-timer.service` | Playtime tracking daemon | Yes |
| `forge-smart-launch.service` | Per-game optimization daemon | Yes |
| `forge-perks-claim.service` | VIP perks checker | Yes |
| `forge-replay.service` | Instant replay recording | Manual |
| `forge-backup.timer` | Automatic backups | Yes (daily) |
| `forge-proton-updater.timer` | Proton-GE update check | Yes (weekly) |
| `forge-achievements.timer` | Achievement check | Yes |
| `forge-anticheat-tracker.timer` | Anti-cheat status check | Yes (daily) |
| `forge-wallpaper.timer` | Wallpaper rotation | Yes |

# Game Compatibility

HubOS runs on Linux, which means most games run through a compatibility layer called **Proton** (Valve's fork of Wine). This page explains how game compatibility works and what tools HubOS provides to check and improve it.

## How Proton Works

Proton translates Windows API calls to Linux equivalents in real-time. It is maintained by Valve and integrated into Steam. When you click "Play" on a Windows game in Steam, Proton handles everything automatically.

```
Game (Windows .exe)
  → Proton (Wine + DXVK + VKD3D + FAudio + ...)
    → Linux kernel + GPU drivers
      → Your hardware
```

Key components:

- **Wine** -- Translates Windows system calls to Linux (files, registry, etc.)
- **DXVK** -- Translates DirectX 9/10/11 to Vulkan
- **VKD3D-Proton** -- Translates DirectX 12 to Vulkan
- **FAudio** -- Translates XAudio2 to FAudio
- **Proton-GE** -- Community build by GloriousEggroll with extra patches and codec support

## Compatibility at a Glance

As of 2026, the vast majority of Steam games work on Linux:

| Category | Estimate |
|----------|----------|
| Native Linux games | ~15% of Steam library |
| Works perfectly via Proton | ~70% of Steam library |
| Works with tweaks | ~10% of Steam library |
| Does not work (anti-cheat) | ~5% of Steam library |

The main reason a game does not work is **anti-cheat software** that blocks Linux. This is changing rapidly as more developers enable Linux support.

## Checking Your Games

### hubos-compat

The compatibility checker queries ProtonDB, Steam, and anti-cheat databases:

```bash
# Check a specific game by Steam AppID
hubos-compat check 730              # CS2

# Check a game by name
hubos-compat check "Elden Ring"

# Search for a game
hubos-compat search "Cyberpunk"

# Scan all your installed Steam games
hubos-compat scan

# Full compatibility report
hubos-compat report

# Check system readiness
hubos-compat status
```

The `scan` command checks every game in your Steam library and produces a summary like:

```
  Platinum:  142 games (works perfectly)
  Gold:       38 games (works with minor tweaks)
  Silver:     12 games (works with significant tweaks)
  Bronze:      4 games (runs, but with issues)
  Borked:      6 games (does not work)
  Native:     23 games (native Linux version)
  Unknown:     8 games (no reports yet)
```

### hubos-anticheat-tracker

Tracks anti-cheat status for your library and notifies you when games enable Linux support:

```bash
# Scan your library for anti-cheat status
hubos-anticheat-tracker scan

# Check a specific game
hubos-anticheat-tracker check "PUBG"

# Show recent status changes (games that added/removed Linux support)
hubos-anticheat-tracker updates

# Show the anti-cheat database
hubos-anticheat-tracker database
```

The tracker runs as a background timer (`hubos-anticheat-tracker.timer`) and sends a desktop notification whenever a game in your library changes anti-cheat status. For example, if Fortnite enables EAC on Linux, you will get a notification the same day.

## Anti-Cheat Status

The biggest compatibility barrier is anti-cheat software. Here is the current status of major anti-cheat systems:

### Easy Anti-Cheat (EAC)

EAC has an official Linux/Proton mode. Developers must opt in.

| Status | Games |
|--------|-------|
| Works on Linux | Rust, Apex Legends, Dead by Daylight, Elden Ring, Fall Guys, Halo MCC |
| Developer has not enabled | Fortnite, The Finals, Hunt: Showdown |

### BattlEye

BattlEye has an official Linux/Proton mode. Developers must opt in.

| Status | Games |
|--------|-------|
| Works on Linux | DayZ, ARK: Survival Evolved, Arma 3 (with workaround) |
| Developer has not enabled | PUBG, Rainbow Six Siege, Destiny 2, Escape from Tarkov |

### Vanguard (Riot Games)

Riot Vanguard requires a kernel-level driver that does not exist on Linux. Valorant does not work.

### Other Anti-Cheat

| System | Linux Status |
|--------|-------------|
| nProtect GameGuard | Does not work |
| XIGNCODE3 | Does not work |
| mhyprot2 (Genshin Impact) | Works (no kernel anti-cheat on Linux) |

## Common Issues and Fixes by Game

### Counter-Strike 2

CS2 runs natively on Linux. No Proton needed.

Common issues:
- **Stuttering on first launch:** Shader compilation. Run `hubos-shader-cache prebuild 730` or just play through it -- it resolves after the first session.
- **Low FPS compared to Windows:** Try launch options: `-vulkan -high`

### Rust

Rust uses EAC with Linux support enabled. Works via Proton.

```bash
# Recommended launch options
hubos-proton-fix 252490  # Auto-diagnoses and suggests fixes

# Manual launch options
# -window-mode exclusive -force-vulkan
```

### Elden Ring

Works well via Proton. Use Proton-GE for best results:

```bash
hubos-proton-updater update          # Install latest Proton-GE
hubos-game-profiles create 1245620   # Create a profile for Elden Ring
```

### Cyberpunk 2077

Works with Proton. HDR support via `hubos-hdr`:

```bash
hubos-hdr setup          # Configure HDR system-wide
hubos-hdr game 1091500   # Apply HDR profile for Cyberpunk
```

### Games That Need Proton-GE

Some games work better with Proton-GE (community build) than Valve's Proton:

```bash
# Install/update Proton-GE automatically
hubos-proton-updater update

# It's installed to Steam's compatibility tools directory
# Then in Steam: Right-click game → Properties → Compatibility → Force specific Proton → GE-Proton
```

Games that commonly need Proton-GE:
- Games with MP4/H.264 video cutscenes (GE includes media codecs)
- Older games with specific Wine patches
- Games with launcher issues

## ProtonDB

[ProtonDB](https://www.protondb.com/) is a community database where Linux gamers report how well games work. HubOS tools query ProtonDB automatically, but you can also check it manually:

1. Go to [protondb.com](https://www.protondb.com/).
2. Search for your game.
3. Read reports from other Linux users.
4. Look for the recommended Proton version and launch options.

### Rating Scale

| Rating | Meaning |
|--------|---------|
| Platinum | Works perfectly out of the box |
| Gold | Works after tweaks (launch options, Proton version) |
| Silver | Works but with minor issues (graphical glitches, audio pops) |
| Bronze | Runs but major issues (crashes, missing features) |
| Borked | Does not work at all |

## Using hubos-proton-fix

When a game does not work, start here:

```bash
# Diagnose the issue
hubos-proton-fix 12345

# Diagnose and auto-fix
hubos-proton-fix 12345 --fix
```

The tool checks:
- Vulkan driver status
- Proton version compatibility
- Game log files for known error patterns
- Missing dependencies (vcredist, .NET, DirectX)
- Anti-cheat status
- Wine prefix health

Common fixes it applies:
- Installing Visual C++ redistributables into the prefix
- Installing .NET Framework
- Setting correct Proton version
- Fixing Wine prefix corruption
- Adding launch options

## Using hubos-crash-fix

For games that launch but crash:

```bash
# Diagnose why a game crashed
hubos-crash-fix diagnose 12345

# Auto-fix common crash causes
hubos-crash-fix fix 12345

# Show crash logs
hubos-crash-fix log 12345

# Generate a crash report for sharing
hubos-crash-fix report

# Watch for crashes in real time
hubos-crash-fix watch
```

## Non-Steam Games

### Lutris

Lutris manages non-Steam games (Epic, GOG, standalone). It is pre-installed on HubOS.

```bash
# Launch Lutris
flatpak run net.lutris.Lutris
```

### Heroic Game Launcher

Heroic manages Epic Games Store and GOG libraries. Pre-installed on HubOS.

```bash
# Launch Heroic
flatpak run com.heroicgameslauncher.hgl
```

### hubos-games

The unified game library tool finds games across all launchers:

```bash
hubos-games list        # All installed games from all launchers
hubos-games search rust  # Search across all launchers
hubos-games launch "Rust"  # Launch from any launcher
```

## Tips for Best Compatibility

1. **Use the latest Proton.** Newer versions fix more games. HubOS auto-updates Proton-GE via `hubos-proton-updater`.
2. **Check ProtonDB before buying.** If a game is rated Borked, it probably will not work.
3. **Use per-game profiles.** `hubos-game-profiles` lets you set Proton version, env vars, and launch options per game.
4. **Pre-build shaders.** `hubos-shader-cache prebuild <appid>` eliminates first-launch stuttering.
5. **Enable GameMode.** It is automatic on HubOS via `hubos-smart-launch`, but verify with `gamemoded -s`.
6. **Report your results.** Submit reports to ProtonDB to help the community.

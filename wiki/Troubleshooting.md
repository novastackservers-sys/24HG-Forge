# Troubleshooting

Common problems and their solutions. For each issue, the relevant HubOS tool is listed.

## Game Won't Launch

**Symptoms:** Clicking Play in Steam does nothing, or the game starts and immediately closes.

**Diagnose:**

```bash
# Check the game's compatibility and logs
hubos-proton-fix <appid>

# Check crash logs
hubos-crash-fix diagnose <appid>

# Check if the game has anti-cheat that blocks Linux
hubos-anticheat-tracker check <appid>
```

**Common fixes:**

```bash
# Auto-fix Proton issues
hubos-proton-fix <appid> --fix

# Try a different Proton version
hubos-proton-updater update   # Install latest Proton-GE
# Then in Steam: Game → Properties → Compatibility → Force GE-Proton

# Reset the Wine prefix (nuclear option -- backs up saves first)
hubos-prefix reset <appid>

# Install missing dependencies
hubos-prefix install-deps <appid> vcredist
hubos-prefix install-deps <appid> dotnet48
```

## Black Screen on Boot

**Symptoms:** After GRUB, the screen goes black or shows only a cursor.

**Diagnose:**

This is almost always an NVIDIA driver issue.

**Fixes:**

1. At the GRUB menu, press `e` to edit the boot entry.
2. Find the line starting with `linux` and add `nomodeset` at the end.
3. Press `Ctrl+X` to boot with this temporary fix.
4. Once booted, run:

```bash
hubos-nvidia-wayland fix       # Auto-detect and fix all NVIDIA+Wayland issues
hubos-nvidia-wayland diagnose  # Show detailed diagnostics
```

If you are not using NVIDIA:

```bash
hubos-crash-recovery            # General crash recovery tool
hubos-diag --paste              # Generate diagnostic report
```

## Screen Flickering (NVIDIA)

**Symptoms:** Screen flickers, especially on Wayland with NVIDIA GPU.

```bash
hubos-nvidia-wayland flicker-fix   # Apply all known flicker fixes
hubos-nvidia-wayland status        # Check current NVIDIA Wayland state
```

This tool applies:
- Correct KWin compositor settings for NVIDIA
- NVIDIA-specific environment variables
- Modprobe configuration for the NVIDIA kernel module
- KDE flicker workarounds

## No Sound

**Symptoms:** Games or system produce no audio output.

```bash
# Check audio status
hubos-audio status

# List all audio devices
hubos-audio devices

# Switch output device
hubos-audio switch "Your Device Name"

# Reset to low-latency gaming config
hubos-audio gaming

# Reset to desktop defaults
hubos-audio desktop
```

If audio devices are not detected at all:

```bash
# Check PipeWire status
systemctl --user status pipewire pipewire-pulse wireplumber

# Restart audio stack
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## Controller Not Detected

**Symptoms:** Gamepad is plugged in but games do not see it.

```bash
# List detected controllers
hubos-controller list

# Test controller input
hubos-controller test

# Fix common issues (udev rules, permissions)
hubos-controller fix

# Calibrate a controller
hubos-controller calibrate
```

**Specific controllers:**

- **Xbox controllers:** Work out of the box (USB and Bluetooth).
- **PlayStation (DualSense/DualShock):** Work out of the box. If not, try `hubos-controller fix`.
- **Nintendo Switch Pro:** Works via Bluetooth. May need `hubos-controller fix` for Steam detection.
- **8BitDo:** Set to XInput mode (hold Start+X while turning on) for best compatibility.
- **Generic USB gamepads:** Usually work, but may need `hubos-controller calibrate` for correct mappings.

## Discord Screen Share Broken

**Symptoms:** Discord screen share shows a black screen or does not show the game.

```bash
# Apply the fix (configures XDG portal and PipeWire for Discord)
hubos-discord-screen

# Verify Discord integration
hubos-discord-fix
```

The fix works because Discord Flatpak needs PipeWire screen capture portal access. HubOS configures this automatically, but if Discord was installed after HubOS first boot, you may need to run the fix manually.

**For Wayland specifically:**

Discord on Wayland requires the XDG Desktop Portal. HubOS configures this, but if screen share still shows black:

1. Make sure you are sharing a specific window (not "Your Screen").
2. Or use `hubos-discord-screen` which sets up window/screen capture properly.

## Flatpak Apps Can't See Drives

**Symptoms:** Steam, Lutris, or other Flatpak apps cannot access your game drives or external storage.

```bash
hubos-flatpak-fix
```

This reconfigures Flatpak filesystem permissions. HubOS ships with overrides for Steam and Lutris in `~/.config/flatpak-overrides/`, but if you added new drives after installation, run the fix again.

**Manual override for a specific app:**

```bash
flatpak override --user --filesystem=/path/to/your/drive com.valvesoftware.Steam
```

## NVIDIA Wayland Issues (General)

NVIDIA + Wayland is the most common source of issues on Linux in 2025-2026. HubOS has a dedicated tool:

```bash
# Run the full diagnostic and auto-fix suite
hubos-nvidia-wayland fix

# Check current status (driver version, Wayland state, environment)
hubos-nvidia-wayland status

# Detailed diagnosis
hubos-nvidia-wayland diagnose

# Optimize for gaming
hubos-nvidia-wayland optimize

# Check environment variables
hubos-nvidia-wayland env

# Fix frame sync issues
hubos-nvidia-wayland sync

# Check driver version and compatibility
hubos-nvidia-wayland driver-check
```

## Update Broke Gaming

**Symptoms:** Games stopped working or system is unstable after an update.

```bash
# Roll back to the previous system image
hubos-update-guard rollback

# Or use rpm-ostree directly
rpm-ostree rollback
systemctl reboot
```

To prevent this in the future:

```bash
# Enable update safety checks
hubos-update-guard check   # Shows what changed and any known issues
hubos-update-guard apply   # Only applies if safe
```

The update guard checks for:
- Known broken packages
- Driver compatibility
- Game-breaking regressions reported by the community

## Game Stuttering

**Symptoms:** Game runs but stutters or has frame drops, especially in the first few minutes.

### Shader Compilation Stutter

The most common cause. First-launch stuttering is caused by shader compilation.

```bash
# Check shader cache status
hubos-shader-cache status

# Pre-build shaders for a game (reduces first-launch stutter)
hubos-shader-cache prebuild <appid>

# Clean and rebuild corrupted caches
hubos-shader-cache clean
hubos-shader-cache optimize
```

### Performance Profile

```bash
# Switch to gaming mode (max CPU/GPU performance)
hubos-performance gaming

# Check current profile
hubos-performance status
```

### Smart Launch

Verify that the smart launch daemon is applying per-game optimizations:

```bash
hubos-smart-launch status
hubos-smart-launch rules   # List built-in game rules
```

## HDR Not Working

**Symptoms:** HDR toggle in KDE does nothing, or HDR games look washed out.

```bash
# Run HDR setup wizard
hubos-hdr setup

# Check HDR hardware support
hubos-hdr status

# Apply per-game HDR profile
hubos-hdr game <appid>
```

Requirements for HDR:
- KDE Plasma 6+ (included in HubOS)
- HDR-capable monitor
- AMD GPU (best support), NVIDIA (improving), Intel (experimental)
- Wayland session (HDR does not work on X11)

## Can't Find Save Games

**Symptoms:** You want to backup or transfer saves but do not know where they are.

```bash
# Find save locations for a game
hubos-save-manager find <appid or name>

# List all detected save locations
hubos-save-manager list

# Backup saves for a specific game
hubos-save-manager backup <appid>

# Restore saves
hubos-save-manager restore <appid>
```

Save locations vary by game:
- **Steam Cloud saves:** `~/.local/share/Steam/userdata/<userid>/<appid>/`
- **Wine prefix saves:** `~/.local/share/Steam/steamapps/compatdata/<appid>/pfx/drive_c/users/steamuser/...`
- **Native Linux saves:** `~/.local/share/<game>/` or `~/.config/<game>/`

## Modding Issues

**Symptoms:** Mods do not load, game crashes with mods, or you cannot install mods.

```bash
# Open the mod manager for a game
hubos-mod-manager <appid>

# Install a mod from Nexus Mods (nxm:// link handler)
# Just click "Mod Manager Download" on Nexus Mods -- HubOS handles the rest
```

HubOS registers as an NXM protocol handler, so clicking "Download with Mod Manager" on Nexus Mods will route to `hubos-mod-manager`.

For Proton/Wine games, mods go into the Wine prefix:
```bash
# Find the prefix for a game
hubos-prefix info <appid>
```

## System Overheating

**Symptoms:** System throttles or shuts down during gaming.

```bash
# Check thermal status
hubos-thermal

# Switch to balanced profile (less aggressive GPU/CPU)
hubos-performance balanced
```

## Generating a Support Report

If none of the above fixes your issue, generate a diagnostic report:

```bash
# Full system diagnostic
hubos-diag

# Upload to termbin for sharing (redacts sensitive info)
hubos-diag --paste
```

Share the resulting URL in the [24HG Discord](https://discord.gg/ymfEjH6EJN) support channel.

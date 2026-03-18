# 24HG Forge Wiki

Welcome to the 24HG Forge documentation. 24HG Forge is a custom Linux gaming distribution built on [Bazzite](https://bazzite.gg/) (Fedora Atomic) by [24 Hour Gaming](https://24hgaming.com).

## Quick Links

- [Getting Started](Getting-Started) -- Download, install, and start gaming in 15 minutes
- [Installation Guide](Installation) -- Detailed walkthrough for every step
- [All Tools Reference](Tools-Reference) -- Complete documentation of all 53 tools
- [Game Compatibility](Game-Compatibility) -- Check if your game works on Linux
- [Troubleshooting](Troubleshooting) -- Common problems and their solutions
- [Keyboard Shortcuts](Keyboard-Shortcuts) -- Every hotkey at your fingertips
- [FAQ](FAQ) -- Answers to the 25+ most common questions
- [Building from Source](Building) -- Build your own 24HG Forge image
- [Contributing](Contributing) -- Help make 24HG Forge better

## What is 24HG Forge?

24HG Forge is a gaming-focused Linux distribution that integrates directly with the 24 Hour Gaming community. It includes **53 purpose-built gaming tools**, connects to **88+ game servers**, and provides a console-like gaming experience on desktop Linux.

### Key Features

- **Zero-config gaming** -- GPU drivers (NVIDIA, AMD, Intel) work out of the box. Steam, Lutris, and Heroic are auto-installed on first boot.
- **Two boot modes** -- Desktop Mode (full KDE Plasma desktop) or 24HG Mode (console-like fullscreen via Gamescope).
- **Atomic updates** -- System updates are safe and reversible. If something breaks, roll back in seconds with `rpm-ostree rollback`.
- **53 gaming tools** -- Every common gaming pain point on Linux has a dedicated fix tool. Proton issues, shader stuttering, audio latency, display configuration, controller setup -- all one command away.
- **Community integration** -- Built-in Hub app connects to 24HG servers, chat, forums, tournaments, and leaderboards.
- **VIP perks** -- 24HG Forge users automatically receive benefits across all 24HG game servers.

### Architecture

```
Fedora Atomic (base OS, security, kernel)
  └─ Bazzite (gaming stack: NVIDIA, Proton, MangoHud, Gamescope, codecs)
      └─ 24HG Forge (24HG overlay)
          ├─ Hub App (Chromium kiosk → hub.24hgaming.com)
          ├─ 53 Gaming Tools (forge-*)
          ├─ Branding (wallpapers, icons, boot splash, GRUB, SDDM, Plymouth)
          ├─ Gamescope session ("24HG Mode")
          ├─ First-boot setup (Steam, Lutris, Heroic auto-install)
          ├─ First-boot wizard (account, GPU, preferences)
          └─ Gaming tweaks (sysctl, PipeWire, libinput, GameMode)
```

### Variants

| Variant | GPU Support | Use Case |
|---------|-------------|----------|
| `desktop` | AMD / Intel (open-source Mesa) | Most desktops and laptops |
| `nvidia` | NVIDIA (proprietary drivers) | NVIDIA GPU systems |
| `deck` | Steam Deck (AMD APU, handheld) | Steam Deck and handhelds |

### Connected Servers

24HG Forge ships with a built-in server list connecting to 88+ game servers across:

- Counter-Strike 2 (8 servers)
- Team Fortress 2 (15 servers)
- Counter-Strike 1.6 (16 servers)
- CS: Condition Zero (5 servers)
- Counter-Strike: Source (3 servers)
- Rust (2 servers)
- FiveM / GTA V (1 server)
- Day of Defeat: Source, Left 4 Dead 1 & 2, No More Room in Hell, Insurgency, Quake Live

## Support

- **Discord:** https://discord.gg/ymfEjH6EJN
- **Hub:** https://hub.24hgaming.com
- **Website:** https://24hgaming.com/os
- **Issues:** https://git.raggi.is/24hg/forge/issues

## License

Custom code and branding: MIT License.
Based on Bazzite (Apache 2.0) and Fedora (various open-source licenses).

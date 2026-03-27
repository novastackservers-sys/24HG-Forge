# Getting Started with 24HG

This guide gets you from zero to gaming in about 15 minutes.

## Step 1: Download the ISO

Go to [os.24hgaming.com/download.html](https://os.24hgaming.com/download.html) and pick the variant that matches your GPU:

| Your GPU | Download |
|----------|----------|
| AMD or Intel | 24HG Desktop |
| NVIDIA | 24HG NVIDIA |
| Steam Deck | 24HG Deck |

Not sure which GPU you have? On Windows, press `Win+R`, type `dxdiag`, and look under the Display tab.

The ISO is approximately 4-5 GB. While it downloads, grab a USB drive (8 GB minimum).

## Step 2: Create a Bootable USB

### Option A: Ventoy (Recommended)

1. Download [Ventoy](https://ventoy.net/) and install it to your USB drive.
2. Copy the 24HG ISO file onto the Ventoy USB drive.
3. Boot from the USB and select 24HG from the Ventoy menu.

Ventoy is great because you can keep multiple ISOs on the same drive.

### Option B: Rufus (Windows)

1. Download [Rufus](https://rufus.ie/).
2. Select your USB drive, select the 24HG ISO.
3. Use GPT partition scheme and DD image mode if prompted.
4. Click Start and wait.

### Option C: dd (Linux/macOS)

```bash
# Find your USB device (CAREFUL -- wrong device = data loss)
lsblk

# Write the ISO (replace sdX with your USB device)
sudo dd if=24hg-desktop.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## Step 3: Boot from USB

1. Restart your computer.
2. Press the boot menu key during startup (usually F12, F2, F11, or Del -- depends on your motherboard).
3. Select your USB drive from the boot menu.
4. The 24HG installer will start.

If you do not see the USB in the boot menu, you may need to disable Secure Boot in your BIOS settings. See the [Installation Guide](Installation) for details.

## Step 4: Install 24HG

The Calamares installer walks you through the process:

1. Select your language and timezone.
2. Choose your disk and partitioning (use "Erase disk" for the simplest setup, or "Replace a partition" for dual-boot).
3. Create your user account.
4. Review and confirm.
5. Wait for installation to complete (5-10 minutes).
6. Remove the USB drive and reboot.

## Step 5: First Boot Experience

When 24HG boots for the first time, the **First Boot Wizard** launches automatically:

1. **GPU Detection** -- 24HG detects your graphics card and confirms drivers are loaded.
2. **Display Setup** -- Choose your preferred resolution and refresh rate.
3. **24HG Account** -- Log into your 24HG account or create one. This connects you to the community hub.
4. **Steam Setup** -- Steam (Flatpak) is auto-installed. Sign into your Steam account.
5. **Game Launchers** -- Lutris and Heroic Game Launcher are set up for non-Steam games.
6. **Preferences** -- Choose your desktop wallpaper, notification style, and sound theme.

After the wizard completes, you will see the KDE Plasma desktop with the 24HG Hub app already running in the system tray.

## Step 6: Claim Your VIP Perks

24HG users get automatic perks across all 24HG game servers. To claim them:

```bash
24hg-perks claim
```

Or click the tray icon and select "Claim Perks." This links your 24HG account to your 24HG installation and activates benefits like bonus XP, cosmetics, and priority queue on all 88+ game servers.

## Step 7: Connect to 24HG Servers

### From the Hub App

Click the **24HG Hub** icon on your desktop or taskbar. The hub shows all online servers with player counts. Click any server to connect -- 24HG automatically launches the right game.

### From the Terminal

```bash
# See all online servers with player counts
24hg-server-status

# Browse your installed game library
24hg-games list

# Launch a specific game
24hg-games launch "Counter-Strike 2"
```

## 10 Essential Commands

These are the commands you will use most often:

| Command | What It Does |
|---------|--------------|
| `24hg-neofetch` | Show system info with 24HG branding |
| `24hg-server-status` | Show all 24HG servers and player counts |
| `24hg-games list` | List all your installed games |
| `24hg-performance gaming` | Switch to maximum performance mode |
| `24hg-proton-fix <game>` | Diagnose and fix Proton/Wine issues |
| `24hg-replay start` | Start instant replay recording |
| `24hg-shader-cache status` | Check shader cache health |
| `24hg-audio gaming` | Switch to low-latency gaming audio |
| `24hg-backup now` | Backup your game saves and configs |
| `24hg-diag --paste` | Generate a support diagnostic and get a shareable link |

## What Next?

- **Customize your desktop:** `24hg-wallpaper`, `24hg-sounds`, `24hg-notify-style`
- **Optimize for your hardware:** `24hg-performance gaming`, `24hg-nvidia-wayland fix`
- **Fix game issues:** `24hg-crash-fix diagnose <appid>`, `24hg-proton-fix <appid>`
- **Join the community:** Open the Hub app or visit [hub.24hgaming.com](https://hub.24hgaming.com)
- **Read the full docs:** [Tools Reference](Tools-Reference) covers all 53 tools in detail

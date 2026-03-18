# Installation Guide

A complete guide to installing 24HG Forge, from system requirements to post-install configuration.

## System Requirements

### Minimum

| Component | Requirement |
|-----------|-------------|
| CPU | 64-bit x86_64 processor (AMD or Intel) |
| RAM | 4 GB |
| Storage | 30 GB free space |
| GPU | Any GPU with Vulkan support (2015 or newer) |
| USB | 8 GB USB drive for installation |
| Internet | Required for first-boot setup |

### Recommended

| Component | Recommendation |
|-----------|---------------|
| CPU | 4+ cores, 3.0 GHz or higher |
| RAM | 16 GB or more |
| Storage | 256 GB SSD or larger |
| GPU | NVIDIA GTX 1060 / AMD RX 580 or better |

### Supported GPUs

- **NVIDIA:** GTX 900 series and newer (proprietary drivers included in NVIDIA variant)
- **AMD:** GCN 1.0 and newer (open-source Mesa drivers, works out of the box)
- **Intel:** HD 500 series and newer (open-source Mesa drivers)

## Downloading 24HG Forge

Visit [os.24hgaming.com/download.html](https://os.24hgaming.com/download.html) to download the ISO.

### Which Variant?

| Variant | File | When to Use |
|---------|------|-------------|
| Desktop | `forge-desktop-latest.iso` | AMD or Intel GPU |
| NVIDIA | `forge-nvidia-latest.iso` | NVIDIA GPU |
| Deck | `forge-deck-latest.iso` | Steam Deck or handheld PCs |

If you have both an Intel iGPU and an NVIDIA dGPU (common in laptops), use the **NVIDIA** variant.

### Verifying the Download

Each ISO comes with a SHA256 checksum file. Verify it to ensure your download is not corrupted:

```bash
# Linux
sha256sum -c forge-desktop-latest.iso.sha256

# macOS
shasum -a 256 -c forge-desktop-latest.iso.sha256

# Windows (PowerShell)
Get-FileHash forge-desktop-latest.iso -Algorithm SHA256
```

## Creating the USB Installer

### Method 1: Ventoy (Recommended)

[Ventoy](https://ventoy.net/) turns your USB drive into a multi-boot device. You can put multiple ISOs on the same drive.

1. Download Ventoy from [ventoy.net](https://ventoy.net/en/download.html).
2. Install Ventoy onto your USB drive (this formats the drive).
3. Copy the 24HG Forge ISO file onto the USB drive's data partition.
4. Boot from the USB drive and select 24HG Forge from the Ventoy menu.

### Method 2: Rufus (Windows)

1. Download [Rufus](https://rufus.ie/).
2. Insert your USB drive and open Rufus.
3. Select the 24HG Forge ISO under "Boot selection."
4. Set partition scheme to **GPT**.
5. If prompted for write mode, choose **DD Image**.
6. Click **Start** and wait for completion.

### Method 3: dd (Linux / macOS)

```bash
# Identify your USB device -- BE CAREFUL to use the right one
lsblk  # Linux
diskutil list  # macOS

# Unmount the USB drive
sudo umount /dev/sdX*  # Linux
diskutil unmountDisk /dev/diskN  # macOS

# Write the ISO
sudo dd if=forge-desktop-latest.iso of=/dev/sdX bs=4M status=progress oflag=sync  # Linux
sudo dd if=forge-desktop-latest.iso of=/dev/rdiskN bs=4m  # macOS
```

Replace `/dev/sdX` or `/dev/diskN` with your actual USB device. **Using the wrong device will destroy data.**

### Method 4: Fedora Media Writer

Fedora Media Writer works well since 24HG Forge is Fedora-based:

1. Install from [getfedora.org/en/workstation/download/](https://getfedora.org/en/workstation/download/) or your package manager.
2. Choose "Custom Image" and select the 24HG Forge ISO.
3. Select your USB drive and write.

## BIOS/UEFI Settings

Before booting from USB, you may need to adjust these settings in your BIOS/UEFI:

### Accessing BIOS

Press the BIOS key during startup. Common keys by manufacturer:

| Manufacturer | Key |
|-------------|-----|
| ASUS | F2 or Del |
| MSI | Del |
| Gigabyte | Del or F2 |
| ASRock | F2 or Del |
| Dell | F2 |
| HP | F10 or Esc |
| Lenovo | F1 or F2 |
| Acer | F2 or Del |

### Required Settings

- **Secure Boot:** Disable it. Bazzite (and therefore 24HG Forge) supports Secure Boot with enrolled keys, but disabling it avoids complications during installation. You can re-enable it after install if desired.
- **Boot Mode:** Set to **UEFI** (not Legacy/CSM). 24HG Forge requires UEFI boot.
- **Boot Order:** Set USB drive as the first boot device, or use the one-time boot menu (usually F12).

### NVIDIA-Specific

If you have an NVIDIA GPU and dual graphics (e.g., laptop with Intel + NVIDIA):

- Ensure the NVIDIA GPU is not disabled in BIOS.
- If there is a "Graphics Mode" setting, set it to "Discrete" or "Switchable" (not "Integrated only").

## Installation Steps

24HG Forge uses the **Calamares** installer, which provides a graphical step-by-step process.

### 1. Welcome Screen

Select your language. 24HG Forge supports all languages that Fedora supports.

### 2. Location

Select your timezone and locale. This sets your system clock and number/date formats.

### 3. Keyboard

Choose your keyboard layout. You can test it in the text field provided.

### 4. Partitioning

This is the most important step. You have several options:

#### Option A: Erase Disk (Simplest)

Select "Erase disk" to use the entire drive for 24HG Forge. This **deletes everything** on the selected drive.

- Select the target drive from the dropdown.
- Optionally enable disk encryption (LUKS). Recommended for laptops.
- Click Next.

#### Option B: Replace a Partition (Dual-Boot)

If you want to keep Windows (or another OS) alongside 24HG Forge:

1. Before installing, shrink your existing partition in Windows using Disk Management (right-click Start -> Disk Management -> right-click your partition -> Shrink Volume). Leave at least 50 GB of unallocated space.
2. In Calamares, select "Replace a partition."
3. Choose the unallocated space.
4. 24HG Forge will install there without touching your other partitions.

#### Option C: Manual Partitioning (Advanced)

For full control:

| Mount Point | Type | Minimum Size | Notes |
|-------------|------|-------------|-------|
| `/boot/efi` | EFI System Partition (FAT32) | 512 MB | Required for UEFI boot |
| `/boot` | ext4 | 1 GB | Kernel and initramfs |
| `/` | btrfs (recommended) or ext4 | 25 GB | Root filesystem |
| `/home` | btrfs or ext4 | Remaining space | User data, games, saves |
| swap | swap or zram | 2-8 GB | Optional, zram is default |

Btrfs is recommended because rpm-ostree snapshots work better with it, and it supports transparent compression.

### 5. Users

Create your user account:

- **Full name:** Your display name
- **Username:** Lowercase, no spaces (this is your login name)
- **Password:** Choose a strong password
- **Auto-login:** Optional -- check this for a console-like boot experience

### 6. Summary

Review all choices. This is your last chance to change anything before installation begins.

### 7. Install

Click "Install" and wait. Installation typically takes 5-10 minutes on an SSD, 10-20 on a hard drive. The installer copies the OS image and configures the bootloader.

### 8. Finish

Remove the USB drive and reboot.

## First Boot Wizard

On the first boot after installation, 24HG Forge runs the First Boot Wizard automatically. This one-time setup:

1. **Detects your GPU** and confirms drivers are working.
2. **Sets up display** -- resolution, refresh rate, and scaling.
3. **Installs game launchers** -- Steam (Flatpak), Lutris, and Heroic Game Launcher.
4. **Connects to 24HG** -- Log into or create your 24HG account.
5. **Claims VIP perks** -- Links your 24HG Forge installation for server benefits.
6. **Configures preferences** -- Wallpaper, sound theme, notification style.

The wizard takes about 2-3 minutes. After it finishes, you are ready to game.

## Post-Install Checklist

After the first boot wizard, verify these items:

- [ ] **GPU drivers working:** Run `forge-diag` and check the GPU section.
- [ ] **Steam installed:** Open Steam from the taskbar or run `flatpak run com.valvesoftware.Steam`.
- [ ] **Sound working:** Run `forge-audio status` to check audio devices.
- [ ] **Network connected:** Check the system tray for network status.
- [ ] **Hub connected:** The 24HG Hub tray icon should show a green indicator.
- [ ] **Instant replay:** Run `forge-replay start` to enable replay recording.
- [ ] **Performance mode:** Run `forge-performance status` to check your current profile.
- [ ] **Backups configured:** Run `forge-backup status` to verify automatic backup timer.

## Dual-Boot Setup

### Windows + 24HG Forge

If you installed alongside Windows, GRUB (the bootloader) will auto-detect Windows and show it in the boot menu. Select the OS you want at each boot.

If Windows does not appear in the boot menu:

```bash
# Regenerate GRUB configuration
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### Time Sync Issue

Windows and Linux disagree on how to store the hardware clock. Fix this on the Linux side:

```bash
sudo timedatectl set-local-rtc 1
```

Or fix it on the Windows side (recommended) by running in an Administrator Command Prompt:

```
reg add HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t REG_DWORD /d 1
```

### Managing Dual-Boot

24HG Forge includes a dedicated dual-boot management tool:

```bash
forge-dualboot status    # Show detected operating systems
forge-dualboot repair    # Fix bootloader issues
forge-dualboot timeout   # Set GRUB timeout
```

## Rebasing from Bazzite or Fedora

If you already run Bazzite or Fedora Atomic, you can rebase to 24HG Forge without reinstalling:

```bash
# From Bazzite (Desktop/AMD/Intel)
rpm-ostree rebase ostree-unverified-registry:git.raggi.is/24hg/forge:latest

# From Bazzite (NVIDIA)
rpm-ostree rebase ostree-unverified-registry:git.raggi.is/24hg/forge-nvidia:latest

# Reboot to apply
systemctl reboot
```

After rebooting, 24HG Forge branding and tools will be active. Run `forge-first-boot` to trigger the setup wizard.

### Rolling Back

If you want to go back to your previous image:

```bash
rpm-ostree rollback
systemctl reboot
```

## Updating 24HG Forge

24HG Forge updates are atomic and safe. The system checks for updates automatically (daily timer), but you can update manually:

```bash
# Check if an update is available
rpm-ostree upgrade --check

# Apply the update (downloads in background, applied on next boot)
rpm-ostree upgrade

# Reboot to switch to the new image
systemctl reboot
```

Or use the 24HG Forge update tool with safety checks:

```bash
forge-update-guard check     # Check for updates with safety analysis
forge-update-guard apply     # Apply update if safe
forge-update-guard rollback  # Roll back to previous version
```

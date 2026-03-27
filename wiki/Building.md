# Building 24HG from Source

24HG is built as an OCI container image layered on top of Bazzite. The ISO is generated from that image. This guide covers building both locally and via CI/CD.

## Prerequisites

### Required

- **podman** (or Docker) -- for building the OCI image
- **git** -- to clone the repository
- **8 GB+ RAM** -- the build process needs memory for rpm-ostree operations
- **20 GB+ free disk space** -- for the image layers and ISO output

### Optional

- **imagemagick** and **librsvg2-tools** -- for regenerating placeholder assets
- **qemu** or **virt-manager** -- for testing the ISO in a VM

### Installing on Fedora

```bash
sudo dnf install podman git qemu-kvm virt-manager
```

### Installing on Ubuntu/Debian

```bash
sudo apt install podman git qemu-kvm virt-manager
```

## Clone the Repository

```bash
git clone https://git.raggi.is/24hg/24hg.git
cd 24hg
```

## Project Structure

```
24hg-os/
├── Containerfile          # The main build file (like Dockerfile)
├── build-iso.sh           # ISO generation script
├── scripts/               # All 53 24hg-* tools + lib scripts
│   ├── 24hg-neofetch
│   ├── 24hg-diag
│   ├── 24hg-performance
│   ├── 24hg-smart-launch
│   ├── ... (50 more tools)
│   ├── 24hg-first-boot-setup.sh
│   ├── 24hg-auto-update.sh
│   ├── gamemode-start.sh
│   ├── gamemode-end.sh
│   └── build-local.sh     # Local build helper
├── hub-app/               # Hub application and tray icon
│   ├── 24hg-hub           # Main Hub app (Chromium kiosk launcher)
│   ├── 24hg-tray           # System tray integration
│   ├── 24hg-gamescope-session  # 24HG Mode session
│   └── *.desktop            # Desktop entries
├── branding/              # Visual assets
│   ├── wallpapers/         # Desktop wallpapers
│   ├── icons/              # Icon set
│   └── grub/               # GRUB bootloader theme
├── installer/             # Calamares installer config
│   ├── branding/           # Installer branding
│   └── settings.conf       # Calamares settings
├── system_files/          # System configuration overlays
│   ├── etc/
│   │   ├── systemd/        # Systemd services and timers
│   │   ├── skel/           # Default user config
│   │   ├── pipewire/       # Audio configuration
│   │   ├── libinput/       # Input device quirks
│   │   ├── sddm.conf.d/   # Login screen config
│   │   ├── gamemode.ini    # GameMode config
│   │   └── firewalld/      # Firewall rules for gaming
│   └── usr/
│       └── share/
│           ├── 24hg/       # Server list, offline page
│           ├── plymouth/    # Boot splash
│           ├── sddm/       # Login theme
│           ├── plasma/      # KDE splash screen
│           └── sounds/      # Sound theme
├── landing-page/          # os.24hgaming.com website
├── wiki/                  # This documentation
├── README.md
└── LICENSE
```

## Building the OCI Image

### Using the Build Script

The simplest way:

```bash
# Desktop variant (AMD/Intel)
./scripts/build-local.sh desktop

# NVIDIA variant
./scripts/build-local.sh nvidia

# Steam Deck variant
./scripts/build-local.sh deck
```

### Manual Build with Podman

```bash
# Desktop variant
podman build \
  --build-arg BASE_IMAGE=ghcr.io/ublue-os/bazzite \
  --build-arg BASE_TAG=stable \
  -t 24hg:latest \
  .

# NVIDIA variant
podman build \
  --build-arg BASE_IMAGE=ghcr.io/ublue-os/bazzite-nvidia \
  --build-arg BASE_TAG=stable \
  -t 24hg-nvidia:latest \
  .
```

### What the Build Does

The Containerfile (single-stage build):

1. **Starts from Bazzite** (`ghcr.io/ublue-os/bazzite:stable`)
2. **Copies all files** into a temporary build directory
3. **Installs packages** via rpm-ostree: chromium, zenity, gamemode, conky, papirus icons, vulkan tools, etc.
4. **Deploys system files**: sysctl tweaks, systemd services, Plymouth/GRUB/SDDM themes, wallpapers, icons
5. **Installs all 53 tools** to `/usr/bin/24hg-*`
6. **Installs lib scripts** to `/usr/lib/24hg/`
7. **Configures user defaults** via `/etc/skel/` (KDE settings, MangoHud, autostart, Flatpak overrides)
8. **Sets OS identity** in `/usr/lib/os-release`
9. **Commits the ostree layer**

The entire build is a single `RUN` command to minimize layers.

## Building the ISO

### Using build-container-installer

```bash
./build-iso.sh
```

This uses [build-container-installer](https://github.com/JasonN3/build-container-installer) to generate a bootable ISO from the OCI image. The output goes to `iso-output/`.

### Manual ISO Build

```bash
# Pull the build-container-installer image
podman pull ghcr.io/jasonn3/build-container-installer:latest

# Generate the ISO
podman run --rm --privileged \
  -v ./iso-output:/build-container-installer/build \
  -e IMAGE_REPO=localhost \
  -e IMAGE_NAME=24hg \
  -e IMAGE_TAG=latest \
  -e VARIANT=Kinoite \
  ghcr.io/jasonn3/build-container-installer:latest
```

## Testing in a VM

### QEMU (Command Line)

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -smp 4 \
  -cdrom iso-output/24hg-desktop-latest.iso \
  -drive file=24hg-test.qcow2,format=qcow2,if=virtio \
  -boot d \
  -vga qxl \
  -display gtk
```

Create the test disk first:

```bash
qemu-img create -f qcow2 24hg-test.qcow2 50G
```

### virt-manager (GUI)

1. Open virt-manager.
2. Create a new VM.
3. Choose "Local install media" and select the 24HG ISO.
4. Set OS to "Fedora 40" (or newest available).
5. Assign at least 4 GB RAM and 4 CPUs.
6. Create a 50 GB disk.
7. Boot and test.

### Testing Tips

- **GPU passthrough** is not needed for basic testing. QXL or VirtIO-GPU work for verifying the boot process, installer, and tools.
- **To test NVIDIA:** You need actual NVIDIA hardware or GPU passthrough.
- **Network:** Default NAT networking works. The Hub app and server status tools will work in a VM with internet access.

## CI/CD with GitHub Actions

24HG uses GitHub Actions for automated builds. The workflow:

1. Push to `main` triggers a build.
2. The OCI image is built and pushed to `git.raggi.is/24hg/24hg`.
3. The ISO is built from the pushed image.
4. The ISO is attached to a GitHub Release.

### Workflow Overview

```yaml
# Simplified -- see .github/workflows/ for the actual config
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build OCI image
        run: podman build -t git.raggi.is/24hg/24hg:latest .
      - name: Push to GHCR
        run: podman push git.raggi.is/24hg/24hg:latest
      - name: Build ISO
        run: ./build-iso.sh
      - name: Upload ISO
        uses: actions/upload-artifact@v4
        with:
          name: 24hg-iso
          path: iso-output/*.iso
```

## Creating a Custom Variant

You can fork 24HG and create your own variant:

### 1. Fork the Repository

Fork on GitHub, then clone your fork.

### 2. Modify the Containerfile

Add packages, change branding, or add your own tools:

```dockerfile
# Add after the existing rpm-ostree install
RUN rpm-ostree install your-package-here \
    && rpm-ostree cleanup -m

# Add your own tool
COPY my-custom-tool /usr/bin/my-custom-tool
```

### 3. Replace Branding

- Wallpapers: `branding/wallpapers/`
- Icons: `branding/icons/`
- GRUB theme: `branding/grub/`
- Plymouth splash: `system_files/usr/share/plymouth/themes/24hg/`
- SDDM login: `system_files/usr/share/sddm/themes/24hg/`
- Sound theme: `system_files/usr/share/sounds/24hg/`

### 4. Edit OS Identity

In the Containerfile, change the `sed` commands that modify `/usr/lib/os-release`:

```bash
sed -i 's/^NAME=.*/NAME="YourOS"/' /usr/lib/os-release
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="YourOS (Your Community)"/' /usr/lib/os-release
```

### 5. Build and Test

```bash
./scripts/build-local.sh desktop
./build-iso.sh
# Test in a VM
```

### 6. Publish

Push to your own container registry:

```bash
podman tag 24hg:latest ghcr.io/yourusername/youros:latest
podman push ghcr.io/yourusername/youros:latest
```

Users can then rebase to your custom variant:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/yourusername/youros:latest
```

## Generating Placeholder Assets

If you need to regenerate the placeholder branding assets (logos, wallpapers):

```bash
./scripts/generate-placeholder-assets.sh
```

This requires `imagemagick` and `librsvg2-tools`.

## Troubleshooting Builds

### "rpm-ostree install failed"

A package name changed or is unavailable. Check package names against Fedora's repositories:

```bash
podman run --rm -it quay.io/fedora/fedora:latest dnf search <package>
```

### "ostree container commit failed"

Usually a disk space issue. Ensure you have at least 20 GB free.

### ISO build hangs

The ISO build process is resource-intensive. Ensure you have enough RAM (8 GB recommended) and patience (can take 15-30 minutes).

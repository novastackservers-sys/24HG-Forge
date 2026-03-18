#!/bin/bash
# 24HG Forge Asset Generator — MUST run before building the OCI image
# Creates all required PNG assets from the SVG logo
#
# Prerequisites: ImageMagick (convert/magick), librsvg2-tools (rsvg-convert)
#   Fedora:  sudo dnf install ImageMagick librsvg2-tools
#   Ubuntu:  sudo apt install imagemagick librsvg2-bin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="${SCRIPT_DIR}/.."

# Check dependencies
for cmd in rsvg-convert convert; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: '$cmd' not found. Install ImageMagick and librsvg2-tools."
        exit 1
    fi
done

SVG="${ROOT}/branding/icons/forge-logo.svg"
if [ ! -f "$SVG" ]; then
    echo "ERROR: Logo SVG not found at ${SVG}"
    exit 1
fi

echo "=== 24HG Forge Asset Generator ==="
echo ""

# ─── 1. Logo PNGs (all sizes) ───
echo "[1/8] Generating logo PNGs..."
ICON_DIR="${ROOT}/branding/icons"
for size in 16 24 32 48 64 128 256 512; do
    rsvg-convert -w "$size" -h "$size" "$SVG" -o "${ICON_DIR}/forge-logo-${size}.png"
done
echo "  Created 8 icon sizes"

# ─── 2. Electron app icons ───
echo "[2/8] Generating Electron app icons..."
ELECTRON_ICONS="${ROOT}/hub-app/assets/icons"
mkdir -p "$ELECTRON_ICONS"
for size in 16 24 32 48 64 128 256 512; do
    cp "${ICON_DIR}/forge-logo-${size}.png" "${ELECTRON_ICONS}/${size}x${size}.png"
done
echo "  Copied to hub-app/assets/icons/"

# ─── 3. Plymouth boot splash ───
echo "[3/8] Generating Plymouth assets..."
PLYMOUTH_DIR="${ROOT}/system_files/usr/share/plymouth/themes/forge"
mkdir -p "$PLYMOUTH_DIR"
cp "${ICON_DIR}/forge-logo-128.png" "${PLYMOUTH_DIR}/logo.png"

# Progress bar background (400x8, dark rounded rect)
convert -size 400x8 xc:none \
    -fill "#1a1a2e" -draw "roundrectangle 0,0 399,7 4,4" \
    PNG32:"${PLYMOUTH_DIR}/progress-bar-bg.png"

# Progress bar fill (396x4, blue rounded rect)
convert -size 396x4 xc:none \
    -fill "#58a6ff" -draw "roundrectangle 0,0 395,3 2,2" \
    PNG32:"${PLYMOUTH_DIR}/progress-bar.png"
echo "  Created logo.png, progress-bar-bg.png, progress-bar.png"

# ─── 4. GRUB theme ───
echo "[4/8] Generating GRUB assets..."
GRUB_DIR="${ROOT}/branding/grub"
mkdir -p "$GRUB_DIR"

# Background (1920x1080 dark gradient)
convert -size 1920x1080 \
    xc:"#050510" \
    -fill "#0a0a14" -draw "rectangle 0,0 1920,540" \
    -blur 0x20 \
    "${GRUB_DIR}/background.png"

# Logo for GRUB (128px)
cp "${ICON_DIR}/forge-logo-128.png" "${GRUB_DIR}/logo.png"

# Menu selection highlight (800x32, subtle blue)
convert -size 800x32 xc:none \
    -fill "#58a6ff20" -draw "roundrectangle 0,0 799,31 4,4" \
    PNG32:"${GRUB_DIR}/select_c.png"

# Scrollbar thumb
convert -size 6x30 xc:none \
    -fill "#58a6ff60" -draw "roundrectangle 0,0 5,29 3,3" \
    PNG32:"${GRUB_DIR}/scrollbar_thumb_c.png"
echo "  Created background.png, logo.png, select_c.png, scrollbar_thumb_c.png"

# ─── 5. SDDM login theme ───
echo "[5/8] Generating SDDM assets..."
SDDM_DIR="${ROOT}/system_files/usr/share/sddm/themes/forge"
mkdir -p "$SDDM_DIR"
cp "${ICON_DIR}/forge-logo-128.png" "${SDDM_DIR}/logo.png"

# Preview thumbnail (400x300)
convert -size 400x300 xc:"#0a0a14" \
    \( "${ICON_DIR}/forge-logo-64.png" -gravity center \) -composite \
    -fill "#ffffff" -font "DejaVu-Sans-Bold" -pointsize 18 \
    -gravity south -annotate +0+40 "24HG Forge" \
    "${SDDM_DIR}/preview.png"
echo "  Created logo.png, preview.png"

# ─── 6. Calamares installer ───
echo "[6/8] Generating installer assets..."
INSTALLER_DIR="${ROOT}/installer/branding"
mkdir -p "$INSTALLER_DIR"
cp "${ICON_DIR}/forge-logo-256.png" "${INSTALLER_DIR}/logo.png"

# Welcome image (wider, with text)
convert -size 600x400 xc:"#0a0a14" \
    \( "${ICON_DIR}/forge-logo-256.png" -gravity center \) -composite \
    -fill "#58a6ff" -font "DejaVu-Sans-Bold" -pointsize 24 \
    -gravity south -annotate +0+30 "24 HOUR GAMING" \
    "${INSTALLER_DIR}/welcome.png"
echo "  Created logo.png, welcome.png"

# ─── 7. Wallpapers ───
echo "[7/8] Generating placeholder wallpapers..."
WALL_DIR="${ROOT}/branding/wallpapers"
mkdir -p "$WALL_DIR"

# Dark — deep blue gradient with centered dim logo
convert -size 3840x2160 \
    xc:"#060610" \
    -fill "#0c0c1a" -draw "rectangle 0,0 3840,1080" \
    -blur 0x40 \
    \( "${ICON_DIR}/forge-logo-512.png" -channel A -evaluate Multiply 0.08 +channel \
       -gravity center \) -composite \
    "${WALL_DIR}/forge-dark.png"

# Neon — dark with blue accent glow
convert -size 3840x2160 \
    xc:"#060610" \
    \( -size 3840x2160 xc:none \
       -fill "#58a6ff08" -draw "circle 1920,1080 1920,300" \) -composite \
    \( "${ICON_DIR}/forge-logo-512.png" -channel A -evaluate Multiply 0.06 +channel \
       -gravity center \) -composite \
    "${WALL_DIR}/forge-neon.png"

# Minimal — nearly black with very subtle texture
convert -size 3840x2160 \
    xc:"#08080f" \
    -seed 42 +noise Gaussian \
    -channel RGB -evaluate Multiply 0.02 +channel \
    -blur 0x1 \
    "${WALL_DIR}/forge-minimal.png"

# Circuit — dark with subtle grid pattern
CIRCUIT_DRAWS=""
for i in $(seq 0 120 3840); do CIRCUIT_DRAWS="$CIRCUIT_DRAWS line $i,0 $i,2160"; done
for i in $(seq 0 120 2160); do CIRCUIT_DRAWS="$CIRCUIT_DRAWS line 0,$i 3840,$i"; done
convert -size 3840x2160 xc:"#060610" \
    -fill none -stroke "#141428" -strokewidth 1 \
    -draw "$CIRCUIT_DRAWS" \
    \( "${ICON_DIR}/forge-logo-512.png" -channel A -evaluate Multiply 0.05 +channel \
       -gravity center \) -composite \
    "${WALL_DIR}/forge-circuit.png"

echo "  Created 4 wallpapers (3840x2160)"

# ─── 8. Pixmap for system use ───
echo "[8/8] Installing system pixmap..."
cp "${ICON_DIR}/forge-logo-256.png" "${ROOT}/branding/icons/forge-logo.png"

echo ""
echo "============================================"
echo "  All assets generated successfully!"
echo "  Total: ~25 PNG files"
echo "============================================"
echo ""
echo "You can now build the OCI image:"
echo "  ./scripts/build-local.sh desktop"

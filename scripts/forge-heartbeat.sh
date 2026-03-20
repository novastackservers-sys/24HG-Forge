#!/bin/bash
# 24HG Forge Heartbeat — Reports system info to the Forge Control Room
# Runs on boot and periodically via systemd timer.

set -euo pipefail

LOG_TAG="forge-heartbeat"
API_URL="https://os.24hgaming.com/api/heartbeat"
VERSION_FILE="/usr/share/forge/version"

log() {
    logger -t "$LOG_TAG" "$1"
}

# ── Machine ID (persistent, unique per install) ──
MACHINE_ID=""
if [ -f /etc/machine-id ]; then
    MACHINE_ID=$(cat /etc/machine-id)
elif [ -f /var/lib/dbus/machine-id ]; then
    MACHINE_ID=$(cat /var/lib/dbus/machine-id)
fi

if [ -z "$MACHINE_ID" ]; then
    log "No machine-id found, skipping heartbeat"
    exit 0
fi

# ── Version ──
VERSION="unknown"
if [ -f "$VERSION_FILE" ]; then
    VERSION=$(cat "$VERSION_FILE" 2>/dev/null | head -1)
fi
# Fallback: check os-release
if [ "$VERSION" = "unknown" ] && grep -q "FORGE_VERSION" /usr/lib/os-release 2>/dev/null; then
    VERSION=$(grep "FORGE_VERSION" /usr/lib/os-release | cut -d= -f2 | tr -d '"')
fi

# ── GPU ──
GPU="unknown"
if command -v lspci &>/dev/null; then
    # Get the primary VGA/3D controller
    GPU_LINE=$(lspci -nn 2>/dev/null | grep -iE 'VGA|3D|Display' | head -1 | sed 's/.*: //' | sed 's/ \[.*//') || true
    if [ -n "$GPU_LINE" ]; then
        GPU="$GPU_LINE"
    fi
fi

# ── CPU ──
CPU="unknown"
if [ -f /proc/cpuinfo ]; then
    CPU=$(grep "model name" /proc/cpuinfo | head -1 | sed 's/.*: //' | sed 's/  */ /g')
fi

# ── RAM (GB) ──
RAM_GB=0
if [ -f /proc/meminfo ]; then
    RAM_KB=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
    RAM_GB=$(( (RAM_KB + 524288) / 1048576 ))  # Round to nearest GB
fi

# ── Display (resolution@refresh from primary monitor) ──
DISPLAY_INFO="unknown"
# Try wayland first (KDE)
if command -v kscreen-doctor &>/dev/null; then
    # kscreen-doctor needs a user session, try for logged-in user
    for uid in $(loginctl list-users --no-legend 2>/dev/null | awk '{print $1}'); do
        USER_NAME=$(id -un "$uid" 2>/dev/null) || continue
        RUNTIME_DIR="/run/user/$uid"
        if [ -d "$RUNTIME_DIR" ]; then
            KS_OUT=$(sudo -u "$USER_NAME" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=${RUNTIME_DIR}/bus" \
                XDG_RUNTIME_DIR="$RUNTIME_DIR" \
                kscreen-doctor --outputs 2>/dev/null) || true
            if [ -n "$KS_OUT" ]; then
                # Parse: "Modes: ... *1920x1080@143.98..."
                MODE=$(echo "$KS_OUT" | grep -oP '\*\d+x\d+@[\d.]+' | head -1 | tr -d '*')
                if [ -n "$MODE" ]; then
                    # Clean up refresh rate: 143.98 → 144
                    RES=$(echo "$MODE" | cut -d@ -f1)
                    HZ=$(echo "$MODE" | cut -d@ -f2 | awk '{printf "%d", $1+0.5}')
                    DISPLAY_INFO="${RES}@${HZ}Hz"
                    break
                fi
            fi
        fi
    done
fi
# Fallback: xrandr
if [ "$DISPLAY_INFO" = "unknown" ] && command -v xrandr &>/dev/null; then
    for uid in $(loginctl list-users --no-legend 2>/dev/null | awk '{print $1}'); do
        USER_NAME=$(id -un "$uid" 2>/dev/null) || continue
        RUNTIME_DIR="/run/user/$uid"
        if [ -d "$RUNTIME_DIR" ]; then
            XRANDR_OUT=$(sudo -u "$USER_NAME" \
                DISPLAY=:0 \
                XAUTHORITY="/home/${USER_NAME}/.Xauthority" \
                xrandr --current 2>/dev/null) || true
            MODE=$(echo "$XRANDR_OUT" | grep '\*' | head -1 | awk '{print $1}')
            HZ=$(echo "$XRANDR_OUT" | grep '\*' | head -1 | grep -oP '[\d.]+\*' | tr -d '*' | awk '{printf "%d", $1+0.5}')
            if [ -n "$MODE" ] && [ -n "$HZ" ]; then
                DISPLAY_INFO="${MODE}@${HZ}Hz"
                break
            fi
        fi
    done
fi

# ── Send heartbeat ──
PAYLOAD=$(jq -n \
    --arg mid "$MACHINE_ID" \
    --arg ver "$VERSION" \
    --arg gpu "$GPU" \
    --arg cpu "$CPU" \
    --argjson ram "$RAM_GB" \
    --arg dsp "$DISPLAY_INFO" \
    '{machine_id: $mid, version: $ver, gpu: $gpu, cpu: $cpu, ram_gb: $ram, display: $dsp}'
)

RESPONSE=$(curl -s --max-time 15 -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" 2>/dev/null) || true

if echo "$RESPONSE" | grep -q '"ok":true'; then
    log "Heartbeat sent: v${VERSION}, ${GPU}, ${RAM_GB}GB RAM"
else
    log "Heartbeat failed: ${RESPONSE:-no response}"
fi

#!/bin/bash
# 24HG Auto-Update — Checks for and stages OS updates
# Runs daily via systemd timer. Does NOT reboot automatically.

set -euo pipefail

LOG_TAG="24hg-update"

log() {
    logger -t "$LOG_TAG" "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ── Skip if on battery with low charge ──
if [ -f /sys/class/power_supply/BAT0/status ]; then
    BATTERY_STATUS=$(cat /sys/class/power_supply/BAT0/status)
    if [ "$BATTERY_STATUS" = "Discharging" ]; then
        CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "100")
        if [ "$CAPACITY" -lt 50 ]; then
            log "Skipping update: on battery at ${CAPACITY}%"
            exit 0
        fi
    fi
fi

# ── Skip if a game is running (don't eat bandwidth mid-session) ──
GAME_PROCESSES="(wine|proton|gamescope|steam_app_|reaper|Source|UE4|UnrealEngine|cs2|csgo|hl2|tf_linux|rust|FiveM)"
if pgrep -f "$GAME_PROCESSES" &>/dev/null; then
    log "Skipping update: game session detected"
    exit 0
fi

# ── Skip if GameMode is active (user is gaming) ──
if command -v gamemoded &>/dev/null && gamemoded -s 2>/dev/null | grep -q "active"; then
    log "Skipping update: GameMode is active"
    exit 0
fi

# Check for updates
log "Checking for 24HG updates..."

UPDATE_CHECK=$(rpm-ostree upgrade --check 2>&1) || true

if echo "$UPDATE_CHECK" | grep -q "No updates available"; then
    log "System is up to date."
    exit 0
fi

# Stage the update (downloads but doesn't apply until reboot)
log "Update available, staging..."
if rpm-ostree upgrade 2>&1; then
    log "Update staged successfully. Will apply on next reboot."

    # Notify the user via desktop notification
    for uid in $(loginctl list-users --no-legend 2>/dev/null | awk '{print $1}'); do
        USER_NAME=$(id -un "$uid" 2>/dev/null) || continue
        RUNTIME_DIR="/run/user/$uid"
        if [ -d "$RUNTIME_DIR" ]; then
            sudo -u "$USER_NAME" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=${RUNTIME_DIR}/bus" \
                notify-send \
                    --app-name="24HG" \
                    --icon=24hg-logo \
                    "System Update Ready" \
                    "A 24HG update has been downloaded. Reboot to apply." \
                    2>/dev/null || true
        fi
    done
else
    log "Update staging failed."
    exit 1
fi

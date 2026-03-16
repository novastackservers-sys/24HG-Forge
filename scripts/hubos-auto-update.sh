#!/bin/bash
# HubOS Auto-Update — Checks for and stages OS updates
# Runs daily via systemd timer. Does NOT reboot automatically.

set -euo pipefail

LOG_TAG="hubos-update"

log() {
    logger -t "$LOG_TAG" "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if we're on battery (skip update if so)
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

# Check for updates
log "Checking for HubOS updates..."

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
    # Find active user sessions
    for uid in $(loginctl list-users --no-legend | awk '{print $1}'); do
        USER_NAME=$(id -un "$uid" 2>/dev/null) || continue
        RUNTIME_DIR="/run/user/$uid"
        if [ -d "$RUNTIME_DIR" ]; then
            sudo -u "$USER_NAME" \
                DBUS_SESSION_BUS_ADDRESS="unix:path=${RUNTIME_DIR}/bus" \
                notify-send \
                    --app-name="HubOS" \
                    --icon=hubos-logo \
                    "System Update Ready" \
                    "A HubOS update has been downloaded. Reboot to apply." \
                    2>/dev/null || true
        fi
    done
else
    log "Update staging failed."
    exit 1
fi

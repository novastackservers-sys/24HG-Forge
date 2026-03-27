#!/usr/bin/env bash
set -euo pipefail
# 24HG Update Guard Hook — Called by 24hg-auto-update before applying updates
#
# This hook runs pre-update checks in non-interactive (auto) mode,
# takes a snapshot of the gaming stack, and schedules a post-update
# health check to run after the next reboot.

GUARD="/usr/bin/24hg-update-guard"

# Fallback to local path if not installed system-wide
if [[ ! -x "$GUARD" ]]; then
    GUARD="$(dirname "$(readlink -f "$0")")/24hg-update-guard"
fi

if [[ ! -x "$GUARD" ]]; then
    echo "[update-guard-hook] 24hg-update-guard not found — skipping pre-update checks"
    exit 0
fi

# Run pre-update in auto mode (non-interactive)
echo "[update-guard-hook] Running pre-update checks..."
"$GUARD" pre-update --auto

# Schedule post-update health check to run after reboot
# Uses a transient systemd service that runs once on next boot
UNIT_NAME="24hg-update-guard-postboot"

if command -v systemd-run &>/dev/null; then
    echo "[update-guard-hook] Scheduling post-update health check for next boot..."

    # Create a oneshot service that runs after graphical.target
    mkdir -p "${HOME}/.config/systemd/user"
    cat > "${HOME}/.config/systemd/user/${UNIT_NAME}.service" <<EOF
[Unit]
Description=24HG Update Guard — Post-Update Health Check
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=${GUARD} post-update
ExecStartPost=/bin/rm -f %h/.config/systemd/user/${UNIT_NAME}.service
RemainAfterExit=no

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable "${UNIT_NAME}.service" 2>/dev/null || true

    echo "[update-guard-hook] Post-update check will run automatically after reboot."
else
    echo "[update-guard-hook] systemd-run not available — run '24hg-update-guard post-update' manually after reboot."
fi

echo "[update-guard-hook] Pre-update checks complete."

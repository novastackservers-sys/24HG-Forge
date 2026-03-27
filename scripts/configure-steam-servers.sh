#!/bin/bash
# Configure Steam with 24HG community servers in favorites
# Reads from centralized server list at /usr/share/24hg/servers.json
# Run this after Steam is installed (typically via first-boot Flatpak)

STEAM_DIR="${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam"
CONFIG_DIR="${STEAM_DIR}/config"
SERVERS_JSON="/usr/share/24hg/servers.json"

echo "Configuring 24HG servers in Steam favorites..."

# ── Wait for Steam to be installed (max 5 minutes) ──
MAX_WAIT=300
WAITED=0
while [ ! -d "${STEAM_DIR}" ] && [ "$WAITED" -lt "$MAX_WAIT" ]; do
    # Check if Steam Flatpak is installed but never launched
    if flatpak list 2>/dev/null | grep -q "com.valvesoftware.Steam"; then
        echo "Steam is installed but hasn't been launched yet."
        echo "Server favorites will be configured on next run."
        exit 0
    fi
    sleep 10
    WAITED=$((WAITED + 10))
done

if [ ! -d "${CONFIG_DIR}" ]; then
    # Config dir doesn't exist — Steam hasn't been launched yet
    # Create the config dir so favorites are ready when Steam starts
    mkdir -p "${CONFIG_DIR}" 2>/dev/null || {
        echo "Steam config directory not available. Will configure on next login."
        exit 0
    }
fi

# ── Read servers from centralized JSON ──
if [ ! -f "$SERVERS_JSON" ]; then
    echo "Server list not found at $SERVERS_JSON"
    exit 1
fi

# Build serverbrowser_hist.vdf from JSON using Python
python3 -c "
import json, sys

with open('$SERVERS_JSON') as f:
    data = json.load(f)

labels = data.get('game_labels', {})
servers = data.get('servers', [])

# Only include Steam-compatible games
steam_games = {'rust', 'cs2', 'tf2', 'cs16', 'cscz', 'css', 'dods', 'l4d', 'l4d2', 'nmrih', 'insurgency'}

lines = ['\"Filters\"', '{', '\t\"Favorites\"', '\t{']
idx = 0
for s in servers:
    if s['game'] not in steam_games:
        continue
    game_label = labels.get(s['game'], s['game'].upper())
    name = f\"24HG {game_label} - {s['name']}\"
    lines.append(f'\t\t\"{idx}\"')
    lines.append('\t\t{')
    lines.append(f'\t\t\t\"address\"\t\t\"{s[\"ip\"]}\"')
    lines.append(f'\t\t\t\"port\"\t\t\"{s[\"port\"]}\"')
    lines.append(f'\t\t\t\"name\"\t\t\"{name}\"')
    lines.append('\t\t}')
    idx += 1

lines.append('\t}')
lines.append('}')
print('\n'.join(lines))
" > "${CONFIG_DIR}/serverbrowser_hist.vdf" 2>/dev/null

COUNT=$(python3 -c "
import json
with open('$SERVERS_JSON') as f:
    data = json.load(f)
steam_games = {'rust', 'cs2', 'tf2', 'cs16', 'cscz', 'css', 'dods', 'l4d', 'l4d2', 'nmrih', 'insurgency'}
print(sum(1 for s in data['servers'] if s['game'] in steam_games))
" 2>/dev/null || echo "?")

echo "Added ${COUNT} servers to Steam favorites."
echo "Restart Steam to see them in the server browser."

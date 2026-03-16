# HubOS shell customizations
# Sourced by .bashrc on Fedora (via /etc/skel/.bashrc.d/ pattern)

# Show HubOS system info + tip of the day on first terminal open (once per session)
if [ -z "$HUBOS_GREETED" ] && [ -x /usr/bin/hubos-neofetch ]; then
    /usr/bin/hubos-neofetch
    [ -x /usr/bin/hubos-tips ] && /usr/bin/hubos-tips daily 2>/dev/null
    export HUBOS_GREETED=1
fi

# 24HG Quick aliases
alias hub='xdg-open https://hub.24hgaming.com'
alias servers='xdg-open https://hub.24hgaming.com/servers'
alias hubos-update='rpm-ostree upgrade && echo "Reboot to apply: systemctl reboot"'
alias hubos-rollback='rpm-ostree rollback && echo "Reboot to apply: systemctl reboot"'

# Server quick-connect using centralized server list
24hg-connect() {
    local SERVERS_JSON="/usr/share/hubos/servers.json"
    if [ -z "${1:-}" ]; then
        echo "Usage: 24hg-connect <game> [server-name]"
        echo ""
        if [ -f "$SERVERS_JSON" ]; then
            python3 -c "
import json
with open('$SERVERS_JSON') as f:
    data = json.load(f)
labels = data.get('game_labels', {})
games = {}
for s in data['servers']:
    games.setdefault(s['game'], []).append(s)
for game, srvs in sorted(games.items()):
    print(f'  {game:12s} ({labels.get(game, game)}) - {len(srvs)} servers')
" 2>/dev/null
        fi
        return
    fi

    local game="$1"
    local name="${2:-}"

    if [ -f "$SERVERS_JSON" ]; then
        local addr
        addr=$(python3 -c "
import json, sys
with open('$SERVERS_JSON') as f:
    data = json.load(f)
game = '$game'
name = '$name'.lower()
for s in data['servers']:
    if s['game'] == game:
        if not name or name in s['name'].lower():
            print(f\"{s['ip']}:{s['port']}\")
            sys.exit(0)
print('')
" 2>/dev/null)

        if [ -n "$addr" ]; then
            echo "Connecting to 24HG $game server at $addr..."
            xdg-open "steam://connect/$addr"
        else
            echo "No server found for game '$game'${name:+ matching '$name'}"
        fi
    else
        echo "Server list not found"
    fi
}

# Shortcut aliases using centralized connect
connect-rust()    { 24hg-connect rust "${1:-}"; }
connect-cs2()     { 24hg-connect cs2 "${1:-}"; }
connect-tf2()     { 24hg-connect tf2 "${1:-}"; }
connect-cs16()    { 24hg-connect cs16 "${1:-}"; }
connect-css()     { 24hg-connect css "${1:-}"; }

# Gaming environment
export MANGOHUD_CONFIG="position=top-left,fps,gpu_stats,cpu_stats,ram,vram,frame_timing,toggle_hud=F12"
export DXVK_LOG_LEVEL=none
export PROTON_ENABLE_NVAPI=1
export PROTON_HIDE_NVIDIA_GPU=0
export SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0

# HubOS tool aliases
alias gamemode='hubos-performance gaming'
alias replay-save='hubos-replay save'
alias replay-start='hubos-replay start'
alias netguard='hubos-netguard'
alias proton-fix='hubos-proton-fix'
alias audio='hubos-audio'
alias screenshot='hubos-screenshot'
alias backup='hubos-backup'
alias nightlight='hubos-nightlight'
alias benchmark='hubos-benchmark'

# Server status shortcut
alias status='hubos-server-status --once'

# Hub bridge aliases
alias hub-login='hubos-hub-bridge login'
alias hub-logout='hubos-hub-bridge logout'
alias hub-status='hubos-hub-bridge status'

# Wave 5 tool aliases
alias game-profiles='hubos-game-profiles'
alias controller='hubos-controller'
alias proton-update='hubos-proton-updater update'
alias playtime='hubos-game-timer stats'
alias stream='hubos-stream'
alias shaders='hubos-shader-cache'

# Wave 6 feel aliases
alias tips='hubos-tips'
alias achievements='hubos-achievements list'
alias wallpaper='hubos-wallpaper'
alias sounds='hubos-sounds'

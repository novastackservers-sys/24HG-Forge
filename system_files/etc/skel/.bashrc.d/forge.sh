# 24HG Forge shell customizations
# Sourced by .bashrc on Fedora (via /etc/skel/.bashrc.d/ pattern)

# Show 24HG Forge system info + tip of the day on first terminal open (once per session)
if [ -z "$24HG_FORGE_GREETED" ] && [ -x /usr/bin/forge-neofetch ]; then
    /usr/bin/forge-neofetch
    [ -x /usr/bin/forge-tips ] && /usr/bin/forge-tips daily 2>/dev/null
    export 24HG_FORGE_GREETED=1
fi

# 24HG Quick aliases
alias hub='xdg-open https://hub.24hgaming.com'
alias servers='xdg-open https://hub.24hgaming.com/servers'
alias forge-update='rpm-ostree upgrade && echo "Reboot to apply: systemctl reboot"'
alias forge-rollback='rpm-ostree rollback && echo "Reboot to apply: systemctl reboot"'

# Server quick-connect using centralized server list
24hg-connect() {
    local SERVERS_JSON="/usr/share/forge/servers.json"
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

# 24HG Forge tool aliases
alias gamemode='forge-performance gaming'
alias replay-save='forge-replay save'
alias replay-start='forge-replay start'
alias netguard='forge-netguard'
alias proton-fix='forge-proton-fix'
alias audio='forge-audio'
alias screenshot='forge-screenshot'
alias backup='forge-backup'
alias nightlight='forge-nightlight'
alias benchmark='forge-benchmark'

# Server status shortcut
alias status='forge-server-status --once'

# Hub bridge aliases
alias hub-login='forge-hub-bridge login'
alias hub-logout='forge-hub-bridge logout'
alias hub-status='forge-hub-bridge status'

# Wave 5 tool aliases
alias game-profiles='forge-game-profiles'
alias controller='forge-controller'
alias proton-update='forge-proton-updater update'
alias playtime='forge-game-timer stats'
alias stream='forge-stream'
alias shaders='forge-shader-cache'

# Wave 6 feel aliases
alias tips='forge-tips'
alias achievements='forge-achievements list'
alias wallpaper='forge-wallpaper'
alias sounds='forge-sounds'

# Wave 8 troubleshooting aliases
alias compat='forge-compat'
alias crash-fix='forge-crash-fix'
alias display='forge-display'
alias discord-share='forge-discord-screen'
alias prefix='forge-prefix'
alias dualboot='forge-dualboot'

# Wave 9 adoption aliases
alias migrate='forge-migrate'
alias bench-compare='forge-benchmark-compare'
alias perks='forge-perks'
alias creator='forge-creator-kit'
alias demo='forge-demo'

# Wave 10 smart gaming aliases
alias games='forge-games list'
alias game-search='forge-games search'
alias thermal='forge-thermal status'
alias downloads='forge-download-mgr status'
alias session='forge-session-summary last'

# Wave 11 gap-filler aliases
alias anticheat='forge-anticheat-tracker scan'
alias mods='forge-mod-manager'
alias hdr='forge-hdr status'
alias flatpak-fix='forge-flatpak-fix scan'
alias update-guard='forge-update-guard status'
alias saves='forge-save-manager list'
alias nvidia-fix='forge-nvidia-wayland fix'

# Wave 12 game setup aliases
alias game-setup='forge-game-setup'
alias setup-gtav='forge-game-setup gtav'
alias setup-hogwarts='forge-game-setup hogwarts'
alias setup-starfield='forge-game-setup starfield'
alias setup-forza='forge-game-setup forza'
alias setup-warframe='forge-game-setup warframe'
alias setup-minecraft='forge-game-setup minecraft'

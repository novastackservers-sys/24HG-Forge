# 24HG Forge shell customizations
# Sourced by .bashrc on Fedora (via /etc/skel/.bashrc.d/ pattern)

# Show 24HG Forge system info + tip of the day on first terminal open (once per session)
if [ -z "$_24HG_FORGE_GREETED" ] && [ -x /usr/bin/forge-neofetch ]; then
    /usr/bin/forge-neofetch
    [ -x /usr/bin/forge-tips ] && /usr/bin/forge-tips daily 2>/dev/null
    export _24HG_FORGE_GREETED=1
fi

# Fastfetch / neofetch aliases
alias fastfetch='fastfetch --config ~/.config/fastfetch/config.jsonc'
alias neofetch='forge-neofetch'

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

# Wave 13 killer features aliases
alias sunshine='forge-sunshine-setup'
alias clip='forge-clip capture'
alias clip-start='forge-clip start'
alias clip-stop='forge-clip stop'
alias clip-share='forge-clip share'
alias lan='forge-lan-party scan'
alias lan-announce='forge-lan-party announce --daemon'
alias radio='forge-radio play'
alias radio-stop='forge-radio stop'
alias radio-next='forge-radio next'
alias rig-score='forge-rig-score run'
alias leaderboard='forge-rig-score leaderboard'
alias invite='forge-invite create'
alias game-compat='forge-game-compat check'
alias compat-report='forge-game-compat report'
alias tournament='forge-tournament list'
alias live-wallpaper='forge-live-wallpaper start'
alias hw-tune='forge-hw-optimizer tune'

# Wave 14 social + intelligence aliases
alias overlay='forge-overlay start'
alias cloud-saves='forge-cloud-saves sync'
alias save-sync='forge-cloud-saves watch'
alias achievements='forge-achievements list'
alias badges='forge-achievements progress'
alias launch='forge-launch play'
alias ping-test='forge-ping-optimizer test'
alias ping-fix='forge-ping-optimizer optimize'
alias rescue='forge-rescue scan'
alias fix='forge-rescue fix'
alias gallery='forge-gallery list'
alias share-screenshot='forge-gallery share'
alias mods='forge-mods list'

# Wave 15 infrastructure aliases
alias vpn='forge-vpn join'
alias vpn-leave='forge-vpn leave'
alias vpn-peers='forge-vpn peers'
alias retro='forge-retro list'
alias retro-setup='forge-retro setup'
alias retro-play='forge-retro play'
alias voice='forge-voice join'
alias voice-leave='forge-voice leave'
alias ptt='forge-voice ptt-bind'

# Wave 16 polish + security aliases
alias settings='forge-settings'
alias notify='forge-notify send'
alias tour='forge-tour'
alias digest='forge-digest generate'
alias feed='forge-feed'
alias themes='forge-themes list'
alias theme-apply='forge-themes apply'
alias firewall='forge-firewall status'
alias crash-report='forge-crash-report scan'
alias mirrors='forge-mirror list'

# Wave 17 smart gaming + family + hardware aliases
alias ai='forge-ai'
alias ask='forge-ai fix'
alias perflog='forge-perflog live'
alias perf-start='forge-perflog start'
alias perf-stop='forge-perflog stop'
alias deals='forge-deals check'
alias wishlist='forge-deals wishlist'
alias highlights='forge-highlights scan'
alias parental='forge-parental status'
alias a11y='forge-a11y status'
alias colorblind='forge-a11y colorblind'
alias laptop='forge-laptop status'
alias laptop-gaming='forge-laptop gaming'
alias laptop-battery='forge-laptop battery'
alias controllers='forge-controllers list'
alias challenges='forge-challenges list'
alias discord-rpc='forge-discord-rpc start'
alias snapshot='forge-snapshot create'
alias snapshots='forge-snapshot list'
alias win-import='forge-windows-import scan'

# Wave 18 server hosting + streaming + hardware aliases
alias host='forge-host list'
alias host-start='forge-host start'
alias host-stop='forge-host stop'
alias go-live='forge-go-live'
alias record='forge-record start'
alias record-stop='forge-record stop'
alias vr='forge-vr status'
alias vr-start='forge-vr start'
alias gamedrive='forge-gamedrive list'
alias nas='forge-nas scan'
alias proton-pick='forge-proton-pick check'
alias game-backup='forge-game-backup list'
alias splitscreen='forge-splitscreen start'
alias focus='forge-focus on'
alias focus-off='forge-focus off'

# Help
alias help='forge-help'

# Wave 19 smart gaming OS aliases
alias game-ready='forge-game-ready scan'
alias game-ready-watch='forge-game-ready watch'
alias smart-update='forge-smart-updates status'
alias update-now='forge-smart-updates apply'
alias update-rollback='forge-smart-updates rollback'
alias quick-resume='forge-quick-resume save'
alias resume='forge-quick-resume restore'
alias hw-scout='forge-hw-scout status'
alias hw-monitor='forge-hw-scout monitor'
alias hw-report='forge-hw-scout report'
alias game-install='forge-game-installer search'
alias game-list='forge-game-installer list'
alias lan-mode='forge-lan-mode start'
alias lan-stop='forge-lan-mode stop'
alias lan-peers='forge-lan-mode peers'
alias perf-profile='forge-perf-profiles list'
alias perf-apply='forge-perf-profiles apply'
alias desktop-mode='forge-boot-select desktop'
alias game-mode='forge-boot-select gamemode'
alias drivers='forge-driver-mgr status'
alias driver-health='forge-driver-mgr health'
alias net-optimize='forge-net-optimizer optimize'
alias net-ping='forge-net-optimizer ping'
alias net-dns='forge-net-optimizer dns test'
alias migrate-games='forge-game-migrate scan'
alias tray='forge-tray-dashboard'
alias sandbox='forge-sandbox run'
alias power='forge-power-plan status'
alias power-battery='forge-power-plan battery'
alias power-perf='forge-power-plan performance'
alias host-game='forge-one-click-server start'
alias host-list='forge-one-click-server list'
alias host-status='forge-one-click-server status'
alias host-invite='forge-one-click-server invite'

# Wave 20 hardware control + polish aliases
alias peripherals='forge-peripherals list'
alias mouse='forge-peripherals mouse'
alias rgb='forge-peripherals rgb'
alias macros='forge-peripherals macro list'
alias input-lag='forge-input-lag status'
alias low-latency='forge-input-lag optimize'
alias audio-route='forge-audio-router status'
alias audio-devices='forge-audio-router devices'
alias clean='forge-cleaner scan'
alias clean-now='forge-cleaner clean'
alias dual-gpu='forge-dual-gpu status'
alias dgpu='forge-dual-gpu run'
alias mod='forge-mod-manager list'
alias mod-install='forge-mod-manager install'
alias custom-res='forge-custom-res list'
alias stretched='forge-custom-res stretched'
alias boot-speed='forge-boot-speed analyze'
alias boot-optimize='forge-boot-speed optimize'

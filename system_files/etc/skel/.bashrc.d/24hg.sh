# 24HG shell customizations
# Sourced by .bashrc on 24HG (via /etc/skel/.bashrc.d/ pattern)

# Show 24HG system info + tip of the day on first terminal open (once per session)
if [ -z "$_24HG_GREETED" ] && [ -x /usr/bin/24hg-neofetch ]; then
    /usr/bin/24hg-neofetch
    [ -x /usr/bin/24hg-tips ] && /usr/bin/24hg-tips daily 2>/dev/null
    export _24HG_GREETED=1
fi

# Fastfetch / neofetch aliases
alias fastfetch='fastfetch --config ~/.config/fastfetch/config.jsonc'
alias neofetch='24hg-neofetch'

# 24HG Quick aliases
alias hub='xdg-open https://hub.24hgaming.com'
alias servers='xdg-open https://hub.24hgaming.com/servers'
alias 24hg-update='rpm-ostree upgrade && echo "Reboot to apply: systemctl reboot"'
alias 24hg-rollback='rpm-ostree rollback && echo "Reboot to apply: systemctl reboot"'

# Server quick-connect using centralized server list
24hg-connect() {
    local SERVERS_JSON="/usr/share/24hg/servers.json"
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

# 24HG tool aliases
alias gamemode='24hg-performance gaming'
alias replay-save='24hg-replay save'
alias replay-start='24hg-replay start'
alias netguard='24hg-netguard'
alias proton-fix='24hg-proton-fix'
alias audio='24hg-audio'
alias screenshot='24hg-screenshot'
alias backup='24hg-backup'
alias nightlight='24hg-nightlight'
alias benchmark='24hg-benchmark'

# Server status shortcut
alias status='24hg-server-status --once'

# Hub bridge aliases
alias hub-login='24hg-hub-bridge login'
alias hub-logout='24hg-hub-bridge logout'
alias hub-status='24hg-hub-bridge status'

# Wave 5 tool aliases
alias game-profiles='24hg-game-profiles'
alias controller='24hg-controller'
alias proton-update='24hg-proton-updater update'
alias playtime='24hg-game-timer stats'
alias stream='24hg-stream'
alias shaders='24hg-shader-cache'

# Wave 6 feel aliases
alias tips='24hg-tips'
alias wallpaper='24hg-wallpaper'
alias sounds='24hg-sounds'

# Wave 8 troubleshooting aliases
alias compat='24hg-compat'
alias crash-fix='24hg-crash-fix'
alias display='24hg-display'
alias discord-share='24hg-discord-screen'
alias prefix='24hg-prefix'
alias dualboot='24hg-dualboot'

# Wave 9 adoption aliases
alias migrate='24hg-migrate'
alias bench-compare='24hg-benchmark-compare'
alias perks='24hg-perks'
alias creator='24hg-creator-kit'
alias demo='24hg-demo'

# Wave 10 smart gaming aliases
alias games='24hg-games list'
alias game-search='24hg-games search'
alias thermal='24hg-thermal status'
alias downloads='24hg-download-mgr status'
alias session='24hg-session-summary last'

# Wave 11 gap-filler aliases
alias anticheat='24hg-anticheat-tracker scan'
alias hdr='24hg-hdr status'
alias flatpak-fix='24hg-flatpak-fix scan'
alias update-guard='24hg-update-guard status'
alias saves='24hg-save-manager list'
alias nvidia-fix='24hg-nvidia-wayland fix'

# Wave 12 game setup aliases
alias game-setup='24hg-game-setup'
alias setup-gtav='24hg-game-setup gtav'
alias setup-hogwarts='24hg-game-setup hogwarts'
alias setup-starfield='24hg-game-setup starfield'
alias setup-forza='24hg-game-setup forza'
alias setup-warframe='24hg-game-setup warframe'
alias setup-minecraft='24hg-game-setup minecraft'

# Wave 13 killer features aliases
alias sunshine='24hg-sunshine-setup'
alias clip='24hg-clip capture'
alias clip-start='24hg-clip start'
alias clip-stop='24hg-clip stop'
alias clip-share='24hg-clip share'
alias lan='24hg-lan-party scan'
alias lan-announce='24hg-lan-party announce --daemon'
alias radio='24hg-radio play'
alias radio-stop='24hg-radio stop'
alias radio-next='24hg-radio next'
alias rig-score='24hg-rig-score run'
alias leaderboard='24hg-rig-score leaderboard'
alias invite='24hg-invite create'
alias game-compat='24hg-game-compat check'
alias compat-report='24hg-game-compat report'
alias tournament='24hg-tournament list'
alias live-wallpaper='24hg-live-wallpaper start'
alias hw-tune='24hg-hw-optimizer tune'

# Wave 14 social + intelligence aliases
alias overlay='24hg-overlay start'
alias cloud-saves='24hg-cloud-saves sync'
alias save-sync='24hg-cloud-saves watch'
alias achievements='24hg-achievements list'
alias badges='24hg-achievements progress'
alias launch='24hg-launch play'
alias ping-test='24hg-ping-optimizer test'
alias ping-fix='24hg-ping-optimizer optimize'
alias rescue='24hg-rescue scan'
alias fix='24hg-rescue fix'
alias gallery='24hg-gallery list'
alias share-screenshot='24hg-gallery share'
alias mods='24hg-mods list'

# Wave 15 infrastructure aliases
alias vpn='24hg-vpn join'
alias vpn-leave='24hg-vpn leave'
alias vpn-peers='24hg-vpn peers'
alias retro='24hg-retro list'
alias retro-setup='24hg-retro setup'
alias retro-play='24hg-retro play'
alias voice='24hg-voice join'
alias voice-leave='24hg-voice leave'
alias ptt='24hg-voice ptt-bind'

# Wave 16 polish + security aliases
alias settings='24hg-settings'
alias notify='24hg-notify send'
alias tour='24hg-tour'
alias digest='24hg-digest generate'
alias feed='24hg-feed'
alias themes='24hg-themes list'
alias theme-apply='24hg-themes apply'
alias firewall='24hg-firewall status'
alias crash-report='24hg-crash-report scan'
alias mirrors='24hg-mirror list'

# Wave 17 smart gaming + family + hardware aliases
alias ai='24hg-ai'
alias ask='24hg-ai fix'
alias perflog='24hg-perflog live'
alias perf-start='24hg-perflog start'
alias perf-stop='24hg-perflog stop'
alias deals='24hg-deals check'
alias wishlist='24hg-deals wishlist'
alias highlights='24hg-highlights scan'
alias parental='24hg-parental status'
alias a11y='24hg-a11y status'
alias colorblind='24hg-a11y colorblind'
alias laptop='24hg-laptop status'
alias laptop-gaming='24hg-laptop gaming'
alias laptop-battery='24hg-laptop battery'
alias controllers='24hg-controllers list'
alias challenges='24hg-challenges list'
alias discord-rpc='24hg-discord-rpc start'
alias snapshot='24hg-snapshot create'
alias snapshots='24hg-snapshot list'
alias win-import='24hg-windows-import scan'

# Wave 18 server hosting + streaming + hardware aliases
alias host='24hg-host list'
alias host-start='24hg-host start'
alias host-stop='24hg-host stop'
alias go-live='24hg-go-live'
alias record='24hg-record start'
alias record-stop='24hg-record stop'
alias vr='24hg-vr status'
alias vr-start='24hg-vr start'
alias gamedrive='24hg-gamedrive list'
alias nas='24hg-nas scan'
alias proton-pick='24hg-proton-pick check'
alias game-backup='24hg-game-backup list'
alias splitscreen='24hg-splitscreen start'
alias focus='24hg-focus on'
alias focus-off='24hg-focus off'

# Help
alias help='24hg-help'

# Wave 19 smart gaming OS aliases
alias game-ready='24hg-game-ready scan'
alias game-ready-watch='24hg-game-ready watch'
alias smart-update='24hg-smart-updates status'
alias update-now='24hg-smart-updates apply'
alias update-rollback='24hg-smart-updates rollback'
alias quick-resume='24hg-quick-resume save'
alias resume='24hg-quick-resume restore'
alias hw-scout='24hg-hw-scout status'
alias hw-monitor='24hg-hw-scout monitor'
alias hw-report='24hg-hw-scout report'
alias game-install='24hg-game-installer search'
alias game-list='24hg-game-installer list'
alias lan-mode='24hg-lan-mode start'
alias lan-stop='24hg-lan-mode stop'
alias lan-peers='24hg-lan-mode peers'
alias perf-profile='24hg-perf-profiles list'
alias perf-apply='24hg-perf-profiles apply'
alias desktop-mode='24hg-boot-select desktop'
alias game-mode='24hg-boot-select gamemode'
alias drivers='24hg-driver-mgr status'
alias driver-health='24hg-driver-mgr health'
alias net-optimize='24hg-net-optimizer optimize'
alias net-ping='24hg-net-optimizer ping'
alias net-dns='24hg-net-optimizer dns test'
alias migrate-games='24hg-game-migrate scan'
alias tray='24hg-tray-dashboard'
alias sandbox='24hg-sandbox run'
alias power='24hg-power-plan status'
alias power-battery='24hg-power-plan battery'
alias power-perf='24hg-power-plan performance'
alias host-game='24hg-one-click-server start'
alias host-list='24hg-one-click-server list'
alias host-status='24hg-one-click-server status'
alias host-invite='24hg-one-click-server invite'

# Wave 20 hardware control + polish aliases
alias peripherals='24hg-peripherals list'
alias mouse='24hg-peripherals mouse'
alias rgb='24hg-peripherals rgb'
alias macros='24hg-peripherals macro list'
alias input-lag='24hg-input-lag status'
alias low-latency='24hg-input-lag optimize'
alias audio-route='24hg-audio-router status'
alias audio-devices='24hg-audio-router devices'
alias clean='24hg-cleaner scan'
alias clean-now='24hg-cleaner clean'
alias dual-gpu='24hg-dual-gpu status'
alias dgpu='24hg-dual-gpu run'
alias mod='24hg-mod-manager list'
alias mod-install='24hg-mod-manager install'
alias custom-res='24hg-custom-res list'
alias stretched='24hg-custom-res stretched'
alias boot-speed='24hg-boot-speed analyze'
alias boot-optimize='24hg-boot-speed optimize'

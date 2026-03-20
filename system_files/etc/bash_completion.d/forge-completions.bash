# 24HG Forge — Bash Tab Completions
# Provides tab completion for all forge-* commands and their subcommands.
# Sourced automatically by bash-completion from /etc/bash_completion.d/

# ---------------------------------------------------------------------------
# All forge-* commands (for prefix completion)
# ---------------------------------------------------------------------------
_FORGE_ALL_COMMANDS="
forge-a11y
forge-achievements
forge-ai
forge-anticheat-tracker
forge-audio
forge-audio-router
forge-backup
forge-benchmark
forge-benchmark-compare
forge-boot-select
forge-boot-speed
forge-challenges
forge-cleaner
forge-clip
forge-cloud-saves
forge-compat
forge-controller
forge-controllers
forge-crash-fix
forge-crash-report
forge-creator-kit
forge-custom-res
forge-deals
forge-demo
forge-digest
forge-discord-rpc
forge-discord-screen
forge-display
forge-download-mgr
forge-driver-mgr
forge-dualboot
forge-dual-gpu
forge-feed
forge-firewall
forge-flatpak-fix
forge-focus
forge-gallery
forge-game-backup
forge-game-compat
forge-gamedrive
forge-game-installer
forge-game-migrate
forge-game-profiles
forge-game-ready
forge-games
forge-game-setup
forge-game-timer
forge-go-live
forge-hdr
forge-help
forge-highlights
forge-host
forge-hub-bridge
forge-hw-optimizer
forge-hw-scout
forge-input-lag
forge-invite
forge-lan-mode
forge-lan-party
forge-laptop
forge-launch
forge-live-wallpaper
forge-migrate
forge-mirror
forge-mod-manager
forge-mods
forge-nas
forge-neofetch
forge-netguard
forge-net-optimizer
forge-nightlight
forge-notify
forge-nvidia-wayland
forge-one-click-server
forge-overlay
forge-parental
forge-perflog
forge-performance
forge-perf-profiles
forge-peripherals
forge-perks
forge-ping-optimizer
forge-power-plan
forge-prefix
forge-proton-fix
forge-proton-pick
forge-proton-updater
forge-quick-resume
forge-radio
forge-record
forge-replay
forge-rescue
forge-retro
forge-rig-score
forge-rollback
forge-sandbox
forge-save-manager
forge-screenshot
forge-server-status
forge-session-summary
forge-settings
forge-shader-cache
forge-smart-updates
forge-snapshot
forge-sounds
forge-splitscreen
forge-stream
forge-sunshine-setup
forge-themes
forge-thermal
forge-tips
forge-tour
forge-tournament
forge-tray-dashboard
forge-update
forge-update-guard
forge-voice
forge-vpn
forge-vr
forge-wallpaper
forge-windows-import
"

# ---------------------------------------------------------------------------
# Subcommand completions for major tools
# ---------------------------------------------------------------------------

# Wave 19 — Smart Gaming OS
complete -W "scan optimize status list reset watch"                          forge-game-ready
complete -W "check apply schedule defer status rollback"                     forge-smart-updates
complete -W "save restore list delete"                                       forge-quick-resume
complete -W "scan report monitor alerts history status"                      forge-hw-scout
complete -W "install search list update remove"                              forge-game-installer
complete -W "start stop status discover chat vote peers"                     forge-lan-mode
complete -W "list apply create edit delete auto"                             forge-perf-profiles
complete -W "desktop game gamemode toggle status"                            forge-boot-select
complete -W "status update rollback switch health"                           forge-driver-mgr
complete -W "scan optimize test reset status ping dns"                       forge-net-optimizer
complete -W "scan migrate verify list"                                       forge-game-migrate
complete -W "run list allow deny status"                                     forge-sandbox
complete -W "gaming balanced powersave battery performance auto status"      forge-power-plan
complete -W "start stop list status logs invite"                             forge-one-click-server

# Wave 20 — Hardware Control + Polish
complete -W "scan configure profiles rgb dpi macro list mouse"              forge-peripherals
complete -W "test optimize report reset status"                             forge-input-lag
complete -W "list route reset profiles save load devices status"            forge-audio-router
complete -W "scan clean schedule whitelist"                                  forge-cleaner
complete -W "status switch auto force-dgpu force-igpu run"                  forge-dual-gpu
complete -W "install remove list update enable disable"                      forge-mod-manager
complete -W "create list remove apply reset stretched"                       forge-custom-res
complete -W "analyze optimize report reset"                                  forge-boot-speed

# Core tools
complete -W "getting-started commands gaming servers streaming hardware community updates troubleshooting about" forge-help
complete -W "status boost normal info"                                       forge-performance
complete -W "start stop status config"                                       forge-stream
complete -W "create restore list schedule"                                   forge-backup
complete -W "start stop clip status save"                                    forge-replay
complete -W "run compare history export"                                     forge-benchmark
complete -W "full quick gpu network audio"                                   forge-diag
complete -W "sync list restore delete status watch"                          forge-cloud-saves
complete -W "start stop list status"                                         forge-host
complete -W "show reset export import"                                       forge-settings
complete -W "list apply preview reset"                                       forge-themes
complete -W "set random slideshow list"                                      forge-wallpaper
complete -W "take area window delay"                                         forge-screenshot
complete -W "capture save list upload delete start stop share"              forge-clip
complete -W "show hide toggle config start"                                  forge-overlay
complete -W "run compare share history leaderboard"                          forge-rig-score

# Wave 5 tools
complete -W "list apply create delete"                                       forge-game-profiles
complete -W "scan configure test calibrate list"                             forge-controller
complete -W "update check list rollback"                                     forge-proton-updater
complete -W "stats today weekly reset"                                       forge-game-timer

# Wave 8 troubleshooting tools
complete -W "check scan fix report"                                          forge-compat
complete -W "scan fix report"                                                forge-crash-fix
complete -W "status configure reset"                                         forge-display
complete -W "start stop status"                                              forge-discord-screen
complete -W "scan fix list create delete"                                    forge-prefix
complete -W "detect setup grub status"                                       forge-dualboot

# Wave 9 adoption tools
complete -W "scan import status"                                             forge-migrate
complete -W "run compare export"                                             forge-benchmark-compare
complete -W "list redeem status"                                             forge-perks
complete -W "create export publish"                                          forge-creator-kit
complete -W "start stop reset"                                               forge-demo

# Wave 10 smart gaming tools
complete -W "list search info launch"                                        forge-games
complete -W "status monitor alerts history"                                  forge-thermal
complete -W "status queue pause resume cancel"                               forge-download-mgr
complete -W "last today weekly"                                              forge-session-summary

# Wave 11 gap-filler tools
complete -W "scan fix status"                                                forge-anticheat-tracker
complete -W "status enable disable calibrate"                                forge-hdr
complete -W "scan fix list"                                                  forge-flatpak-fix
complete -W "status enable disable schedule"                                 forge-update-guard
complete -W "list backup restore delete sync"                                forge-save-manager
complete -W "fix status check"                                               forge-nvidia-wayland

# Wave 12 game setup
complete -W "gtav hogwarts starfield forza warframe minecraft list"          forge-game-setup

# Wave 13 killer features
complete -W "setup start stop status"                                        forge-sunshine-setup
complete -W "scan announce status peers"                                     forge-lan-party
complete -W "play stop next list stations"                                   forge-radio
complete -W "create list join delete"                                        forge-invite
complete -W "check report list"                                              forge-game-compat
complete -W "list join create"                                               forge-tournament
complete -W "start stop list set"                                            forge-live-wallpaper
complete -W "tune scan report reset"                                         forge-hw-optimizer

# Wave 14 social + intelligence tools
complete -W "list progress unlock"                                           forge-achievements
complete -W "play list recent favorites"                                     forge-launch
complete -W "test optimize report reset"                                     forge-ping-optimizer
complete -W "scan fix report"                                                forge-rescue
complete -W "list share upload delete"                                       forge-gallery
complete -W "list install remove update search"                              forge-mods

# Wave 15 infrastructure tools
complete -W "join leave peers status"                                        forge-vpn
complete -W "list setup play scan import"                                    forge-retro
complete -W "join leave ptt-bind status"                                     forge-voice

# Wave 16 polish + security tools
complete -W "send list clear config"                                         forge-notify
complete -W "start skip reset"                                               forge-tour
complete -W "generate list read"                                             forge-digest
complete -W "list read subscribe"                                            forge-feed
complete -W "status enable disable rules"                                    forge-firewall
complete -W "scan report upload"                                             forge-crash-report
complete -W "list set speed test"                                            forge-mirror

# Wave 17 smart gaming + family + hardware
complete -W "fix explain optimize"                                           forge-ai
complete -W "live start stop report"                                         forge-perflog
complete -W "check wishlist alerts"                                          forge-deals
complete -W "scan recent highlights"                                         forge-highlights
complete -W "status enable disable rules"                                    forge-parental
complete -W "status colorblind magnify contrast"                             forge-a11y
complete -W "status gaming battery balanced"                                 forge-laptop
complete -W "list configure calibrate profiles"                              forge-controllers
complete -W "list join create progress"                                      forge-challenges
complete -W "start stop status"                                              forge-discord-rpc
complete -W "create list restore delete"                                     forge-snapshot
complete -W "scan import verify status"                                      forge-windows-import

# Wave 18 server hosting + streaming + hardware
complete -W "start stop status setup"                                        forge-go-live
complete -W "start stop status"                                              forge-record
complete -W "status start stop setup"                                        forge-vr
complete -W "list mount add eject"                                           forge-gamedrive
complete -W "scan mount status"                                              forge-nas
complete -W "check recommend list"                                           forge-proton-pick
complete -W "list create restore schedule"                                   forge-game-backup
complete -W "start stop status"                                              forge-splitscreen
complete -W "on off status timer"                                            forge-focus

# Simpler tools (no subcommands or single-purpose)
complete -W "status on off auto"                                             forge-nightlight
complete -W "scan optimize clear status"                                     forge-shader-cache
complete -W "daily random list"                                              forge-tips
complete -W "play stop list volume"                                          forge-sounds
complete -W "login logout status sync"                                       forge-hub-bridge
complete -W "--once --watch --json"                                          forge-server-status
complete -W "status scan report"                                             forge-audio
complete -W "status check fix"                                               forge-netguard
complete -W "scan fix list"                                                  forge-proton-fix

# ---------------------------------------------------------------------------
# Master forge- prefix completion (typing "forge-<TAB>" lists all commands)
# ---------------------------------------------------------------------------
_forge_master_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ "$cur" == forge-* ]]; then
        COMPREPLY=($(compgen -W "${_FORGE_ALL_COMMANDS}" -- "${cur}"))
    fi
}

# Bind to the empty command so "forge-<TAB>" works at the prompt
# This hooks into bash's default command completion
complete -D -F _forge_master_complete 2>/dev/null

# Also register a completion function that activates when the user types
# "forge" and presses TAB (handles "forge-" prefix via command_not_found)
_forge_command_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(compgen -W "${_FORGE_ALL_COMMANDS}" -- "${cur}"))
}

# If bash-completion is available, hook into its command-not-found handler
# so that "forge-<TAB>" works even for commands not yet on PATH
if declare -F _command_offset &>/dev/null 2>&1; then
    complete -o default -F _forge_command_complete forge-
fi
